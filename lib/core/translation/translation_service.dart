import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Servicio de traducción didáctico bilingüe para palabras y frases escolares.
///
/// Implementa una arquitectura en capas:
/// 1. Caché en memoria ultra-rápida.
/// 2. Diccionario local bilingüe sin conexión (Español <-> Inglés) para vocabulario infantil y escolar.
/// 3. Servicio en línea primario (Google Translate GTX público) con respuesta instantánea.
/// 4. Servicio en línea secundario (MyMemory REST API) como respaldo de alta fidelidad.
class TranslationService {
  TranslationService._();
  static final TranslationService instance = TranslationService._();

  final Map<String, String> _cache = {};

  /// Normaliza códigos de idioma completos (ej. 'es-MX', 'en-US') al código ISO 639-1 básico ('es', 'en').
  static String normalizeLanguageCode(String locale) {
    final lower = locale.trim().toLowerCase();
    if (lower.startsWith('es')) return 'es';
    if (lower.startsWith('en')) return 'en';
    if (lower.startsWith('fr')) return 'fr';
    if (lower.startsWith('de')) return 'de';
    if (lower.startsWith('pt')) return 'pt';
    if (lower.startsWith('it')) return 'it';
    final parts = lower.split(RegExp(r'[-_]'));
    return parts.first;
  }

  /// Devuelve el nombre amigable de un idioma a partir de su código.
  static String getLanguageName(String locale) {
    final code = normalizeLanguageCode(locale);
    return switch (code) {
      'es' => 'Español',
      'en' => 'Inglés',
      'fr' => 'Francés',
      'de' => 'Alemán',
      'pt' => 'Portugués',
      'it' => 'Italiano',
      _ => locale,
    };
  }

  /// Resuelve el idioma de destino predeterminado para traducción bilingüe.
  /// Si ambos idiomas son iguales (ej. es -> es), traduce automáticamente al idioma
  /// complementario (en) para fomentar el aprendizaje bilingüe.
  static String resolveTargetLanguage({
    required String fromLocale,
    required String toLocale,
  }) {
    final from = normalizeLanguageCode(fromLocale);
    var to = normalizeLanguageCode(toLocale);
    if (from == to) {
      to = (from == 'es') ? 'en' : 'es';
    }
    return to;
  }

  /// Traduce una palabra o texto corto entre dos idiomas.
  ///
  /// Si ambos idiomas son iguales (ej. es -> es), traduce automáticamente al idioma
  /// complementario (en) para fomentar el aprendizaje bilingüe.
  Future<String?> translateWord(
    String rawWord, {
    required String fromLocale,
    required String toLocale,
  }) async {
    final text = rawWord.trim().replaceAll(RegExp(r'^[^\p{L}\p{N}]+|[^\p{L}\p{N}]+$', unicode: true), '');
    if (text.isEmpty) return null;

    final from = normalizeLanguageCode(fromLocale);
    final to = resolveTargetLanguage(fromLocale: fromLocale, toLocale: toLocale);

    final cacheKey = '$from|$to|${text.toLowerCase()}';
    if (_cache.containsKey(cacheKey)) {
      return _cache[cacheKey];
    }

    // 1. Consulta en diccionario local sin conexión
    final localMatch = _lookupLocalDictionary(text.toLowerCase(), from: from, to: to);
    if (localMatch != null) {
      final formatted = _matchCase(text, localMatch);
      _cache[cacheKey] = formatted;
      return formatted;
    }

    // 2. Consulta en línea: Google Translate GTX API
    try {
      final uri = Uri.parse(
        'https://translate.googleapis.com/translate_a/single?client=gtx&sl=$from&tl=$to&dt=t&q=${Uri.encodeComponent(text)}',
      );
      final response = await http.get(uri).timeout(const Duration(milliseconds: 1800));
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded is List && decoded.isNotEmpty && decoded[0] is List) {
          final firstBlock = decoded[0] as List;
          if (firstBlock.isNotEmpty && firstBlock[0] is List) {
            final translated = firstBlock[0][0] as String?;
            if (translated != null && translated.trim().isNotEmpty) {
              final result = translated.trim();
              _cache[cacheKey] = result;
              return result;
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Google GTX Translate offline/timeout: $e');
    }

    // 3. Consulta en línea de respaldo: MyMemory API
    try {
      final uri = Uri.parse(
        'https://api.mymemory.translated.net/get?q=${Uri.encodeComponent(text)}&langpair=$from|$to',
      );
      final response = await http.get(uri).timeout(const Duration(milliseconds: 2000));
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic>) {
          final responseData = decoded['responseData'] as Map<String, dynamic>?;
          final translated = responseData?['translatedText'] as String?;
          if (translated != null && translated.trim().isNotEmpty && !translated.contains('MYMEMORY WARNING')) {
            final result = translated.trim();
            _cache[cacheKey] = result;
            return result;
          }
        }
      }
    } catch (e) {
      debugPrint('MyMemory Translate offline/timeout: $e');
    }

    return null;
  }

  /// Mantiene la mayúscula inicial si el texto original la tenía.
  String _matchCase(String source, String translation) {
    if (source.isEmpty || translation.isEmpty) return translation;
    if (source[0] == source[0].toUpperCase()) {
      return translation[0].toUpperCase() + translation.substring(1);
    }
    return translation;
  }

  String? _lookupLocalDictionary(String word, {required String from, required String to}) {
    if (from == 'en' && to == 'es') {
      return _enToEs[word] ?? _resolveEnglishInflection(word);
    }
    if (from == 'es' && to == 'en') {
      return _esToEn[word] ?? _resolveSpanishInflection(word);
    }
    return null;
  }

  String? _resolveEnglishInflection(String word) {
    if (word.endsWith('s') && word.length > 2) {
      final singular = word.substring(0, word.length - 1);
      if (_enToEs.containsKey(singular)) return _enToEs[singular];
    }
    if (word.endsWith('es') && word.length > 3) {
      final stem = word.substring(0, word.length - 2);
      if (_enToEs.containsKey(stem)) return _enToEs[stem];
    }
    if (word.endsWith('ing') && word.length > 4) {
      final stem = word.substring(0, word.length - 3);
      if (_enToEs.containsKey(stem)) return _enToEs[stem];
      if (_enToEs.containsKey('${stem}e')) return _enToEs['${stem}e'];
    }
    if (word.endsWith('ed') && word.length > 3) {
      final stem = word.substring(0, word.length - 2);
      if (_enToEs.containsKey(stem)) return _enToEs[stem];
      if (_enToEs.containsKey(word.substring(0, word.length - 1))) {
        return _enToEs[word.substring(0, word.length - 1)];
      }
    }
    return null;
  }

  String? _resolveSpanishInflection(String word) {
    if (word.endsWith('es') && word.length > 3) {
      final stem = word.substring(0, word.length - 2);
      if (_esToEn.containsKey(stem)) return _esToEn[stem];
    }
    if (word.endsWith('s') && word.length > 2) {
      final singular = word.substring(0, word.length - 1);
      if (_esToEn.containsKey(singular)) return _esToEn[singular];
    }
    if (word.endsWith('itos') || word.endsWith('itas')) {
      final stem = word.substring(0, word.length - 4);
      if (_esToEn.containsKey('${stem}o')) return _esToEn['${stem}o'];
      if (_esToEn.containsKey('${stem}a')) return _esToEn['${stem}a'];
    }
    if (word.endsWith('ito') || word.endsWith('ita')) {
      final stem = word.substring(0, word.length - 3);
      if (_esToEn.containsKey('${stem}o')) return _esToEn['${stem}o'];
      if (_esToEn.containsKey('${stem}a')) return _esToEn['${stem}a'];
    }
    return null;
  }

  // ===========================================================================
  // DICCIONARIOS LOCALES EDUCATIVOS SIN CONEXIÓN (INGLÉS -> ESPAÑOL)
  // ===========================================================================
  static const Map<String, String> _enToEs = {
    // Animales
    'cat': 'gato',
    'dog': 'perro',
    'bird': 'pájaro',
    'fish': 'pez',
    'lion': 'león',
    'tiger': 'tigre',
    'bear': 'oso',
    'rabbit': 'conejo',
    'frog': 'rana',
    'duck': 'pato',
    'horse': 'caballo',
    'cow': 'vaca',
    'pig': 'cerdo',
    'sheep': 'oveja',
    'wolf': 'lobo',
    'fox': 'zorro',
    'mouse': 'ratón',
    'elephant': 'elefante',
    'giraffe': 'jirafa',
    'monkey': 'mono',
    'butterfly': 'mariposa',
    'bee': 'abeja',

    // Naturaleza
    'tree': 'árbol',
    'flower': 'flor',
    'forest': 'bosque',
    'woods': 'bosque',
    'sun': 'sol',
    'moon': 'luna',
    'star': 'estrella',
    'sky': 'cielo',
    'water': 'agua',
    'river': 'río',
    'sea': 'mar',
    'ocean': 'océano',
    'mountain': 'montaña',
    'rain': 'lluvia',
    'wind': 'viento',
    'cloud': 'nube',
    'grass': 'hierba',
    'leaf': 'hoja',
    'fire': 'fuego',
    'earth': 'tierra',
    'stone': 'piedra',
    'rock': 'roca',

    // Escuela y lectura
    'book': 'libro',
    'story': 'cuento / historia',
    'page': 'página',
    'read': 'leer',
    'reading': 'lectura',
    'write': 'escribir',
    'draw': 'dibujar',
    'word': 'palabra',
    'letter': 'letra',
    'number': 'número',
    'school': 'escuela',
    'teacher': 'maestro / profesora',
    'student': 'estudiante / alumno',
    'pencil': 'lápiz',
    'pen': 'bolígrafo',
    'desk': 'escritorio',
    'learn': 'aprender',
    'learning': 'aprendizaje',
    'question': 'pregunta',
    'answer': 'respuesta',

    // Familia y personas
    'family': 'familia',
    'mother': 'madre',
    'mom': 'mamá',
    'father': 'padre',
    'dad': 'papá',
    'parents': 'padres',
    'brother': 'hermano',
    'sister': 'hermana',
    'baby': 'bebé',
    'friend': 'amigo / amiga',
    'friends': 'amigos',
    'boy': 'niño',
    'girl': 'niña',
    'child': 'niño / niña',
    'children': 'niños',
    'grandma': 'abuela',
    'grandpa': 'abuelo',
    'grandmother': 'abuela',
    'grandfather': 'abuelo',

    // Casa y objetos
    'house': 'casa',
    'home': 'hogar',
    'room': 'habitación / cuarto',
    'door': 'puerta',
    'window': 'ventana',
    'table': 'mesa',
    'chair': 'silla',
    'bed': 'cama',
    'toy': 'juguete',
    'toys': 'juguetes',
    'ball': 'pelota',
    'box': 'caja',
    'clock': 'reloj',
    'food': 'comida',
    'apple': 'manzana',
    'bread': 'pan',
    'milk': 'leche',

    // Colores
    'color': 'color',
    'red': 'rojo',
    'blue': 'azul',
    'green': 'verde',
    'yellow': 'amarillo',
    'orange': 'naranja',
    'purple': 'morado',
    'white': 'blanco',
    'black': 'negro',
    'pink': 'rosa',
    'brown': 'café / marrón',

    // Acciones y verbos
    'play': 'jugar',
    'playing': 'jugando',
    'run': 'correr',
    'running': 'corriendo',
    'walk': 'caminar',
    'walking': 'caminando',
    'jump': 'saltar',
    'jumping': 'saltando',
    'fly': 'volar',
    'swim': 'nadar',
    'sing': 'cantar',
    'sleep': 'dormir',
    'eat': 'comer',
    'see': 'ver',
    'look': 'mirar',
    'hear': 'oír / escuchar',
    'listen': 'escuchar',
    'speak': 'hablar',
    'talk': 'conversar / hablar',
    'laugh': 'reír',
    'smile': 'sonreír',
    'help': 'ayudar',
    'like': 'gustar',
    'love': 'amar / querer',

    // Adjetivos
    'big': 'grande',
    'small': 'pequeño',
    'little': 'pequeño',
    'good': 'bueno',
    'bad': 'malo',
    'happy': 'feliz',
    'sad': 'triste',
    'fast': 'rápido',
    'slow': 'lento',
    'beautiful': 'hermoso / bello',
    'pretty': 'lindo / bonito',
    'magic': 'mágico',
    'magical': 'mágico',
    'new': 'nuevo',
    'old': 'viejo / antiguo',
    'clean': 'limpio',
    'bright': 'brillante',

    // Conectores y palabras frecuentes
    'once': 'una vez',
    'upon': 'sobre',
    'time': 'tiempo / vez',
    'day': 'día',
    'night': 'noche',
    'morning': 'mañana',
    'today': 'hoy',
    'tomorrow': 'mañana',
    'yesterday': 'ayer',
    'always': 'siempre',
    'never': 'nunca',
    'yes': 'sí',
    'no': 'no',
    'and': 'y',
    'or': 'o',
    'but': 'pero',
    'with': 'con',
    'for': 'para',
    'in': 'en',
    'on': 'sobre / en',
    'at': 'en',
    'the': 'el / la / los / las',
    'a': 'un / una',
    'an': 'un / una',
  };

  // ===========================================================================
  // DICCIONARIOS LOCALES EDUCATIVOS SIN CONEXIÓN (ESPAÑOL -> INGLÉS)
  // ===========================================================================
  static final Map<String, String> _esToEn = {
    // Invertir automáticamente _enToEs para consistencia total
    for (final entry in _enToEs.entries)
      entry.value.split(RegExp(r'[/,;]')).first.trim().toLowerCase(): entry.key,

    // Términos y variaciones adicionales en español
    'árbol': 'tree',
    'árboles': 'trees',
    'bosque': 'forest',
    'bosques': 'forests',
    'flor': 'flower',
    'flores': 'flowers',
    'gato': 'cat',
    'gata': 'cat',
    'gatos': 'cats',
    'gatito': 'kitten',
    'gatitos': 'kittens',
    'perro': 'dog',
    'perros': 'dogs',
    'perrito': 'puppy',
    'pájaro': 'bird',
    'pájaros': 'birds',
    'ave': 'bird',
    'sol': 'sun',
    'luna': 'moon',
    'estrella': 'star',
    'estrellas': 'stars',
    'cielo': 'sky',
    'agua': 'water',
    'río': 'river',
    'mar': 'sea',
    'montaña': 'mountain',
    'casa': 'house',
    'casita': 'cottage',
    'escuela': 'school',
    'libro': 'book',
    'libros': 'books',
    'cuento': 'story',
    'cuentos': 'stories',
    'lectura': 'reading',
    'página': 'page',
    'páginas': 'pages',
    'palabra': 'word',
    'palabras': 'words',
    'maestro': 'teacher',
    'maestra': 'teacher',
    'amigo': 'friend',
    'amiga': 'friend',
    'amigos': 'friends',
    'niño': 'boy / child',
    'niña': 'girl',
    'niños': 'children',
    'familia': 'family',
    'mamá': 'mom',
    'papá': 'dad',
    'madre': 'mother',
    'padre': 'father',
    'hermano': 'brother',
    'hermana': 'sister',
    'había': 'there was',
    'vez': 'time / once',
    'uno': 'one',
    'una': 'a / one',
    'el': 'the',
    'la': 'the',
    'los': 'the',
    'las': 'the',
    'grande': 'big',
    'pequeño': 'small',
    'pequeña': 'small',
    'bonito': 'pretty',
    'bonita': 'pretty',
    'hermoso': 'beautiful',
    'hermosa': 'beautiful',
    'feliz': 'happy',
    'mágico': 'magical',
    'mágica': 'magical',
    'jugar': 'play',
    'correr': 'run',
    'caminar': 'walk',
    'cantar': 'sing',
    'leer': 'read',
    'escribir': 'write',
    'aprender': 'learn',
    'escuchar': 'listen',
  };
}
