import 'dart:convert';
import 'package:http/http.dart' as http;

import '../translation/translation_service.dart';

/// Representa la definición y significado didáctico de una palabra.
class WordDefinition {
  const WordDefinition({
    required this.word,
    required this.displayWord,
    required this.partOfSpeech,
    required this.meaning,
    this.example,
    this.translation,
    this.translationLocale,
  });

  final String word;
  final String displayWord;
  final String partOfSpeech;
  final String meaning;
  final String? example;
  final String? translation;
  final String? translationLocale;

  WordDefinition copyWith({
    String? word,
    String? displayWord,
    String? partOfSpeech,
    String? meaning,
    String? example,
    String? translation,
    String? translationLocale,
  }) {
    return WordDefinition(
      word: word ?? this.word,
      displayWord: displayWord ?? this.displayWord,
      partOfSpeech: partOfSpeech ?? this.partOfSpeech,
      meaning: meaning ?? this.meaning,
      example: example ?? this.example,
      translation: translation ?? this.translation,
      translationLocale: translationLocale ?? this.translationLocale,
    );
  }

  Map<String, dynamic> toJson() => {
    'word': word,
    'displayWord': displayWord,
    'partOfSpeech': partOfSpeech,
    'meaning': meaning,
    if (example != null) 'example': example,
    if (translation != null) 'translation': translation,
    if (translationLocale != null) 'translationLocale': translationLocale,
  };

  factory WordDefinition.fromJson(Map<String, dynamic> json) => WordDefinition(
    word: json['word'] as String,
    displayWord: json['displayWord'] as String? ?? json['word'] as String,
    partOfSpeech: json['partOfSpeech'] as String? ?? 'palabra',
    meaning: json['meaning'] as String,
    example: json['example'] as String?,
    translation: json['translation'] as String?,
    translationLocale: json['translationLocale'] as String?,
  );
}

/// Servicio de diccionario local bilingüe y educativo para niños y familias.
///
/// Diseñado para operar 100% sin conexión para el vocabulario común de libros escolares
/// y cuentos infantiles en español e inglés, con enriquecimiento dinámico en línea.
class DictionaryService {
  DictionaryService._();
  static final DictionaryService instance = DictionaryService._();

  final Map<String, WordDefinition> _cache = {};

  /// Normaliza una palabra para búsqueda: minúsculas, sin puntuación exterior.
  static String normalize(String raw) {
    var cleaned = raw.trim().toLowerCase();
    cleaned = cleaned.replaceAll(RegExp(r'^[^\p{L}\p{N}]+|[^\p{L}\p{N}]+$', unicode: true), '');
    return cleaned;
  }

  /// Busca el significado de una palabra y enriquece con traducción bilingüe.
  Future<WordDefinition> lookup(
    String rawWord, {
    String homeLocale = 'es-MX',
    String learningLocale = 'en-US',
  }) async {
    final norm = normalize(rawWord);
    if (norm.isEmpty) {
      return WordDefinition(
        word: rawWord,
        displayWord: rawWord,
        partOfSpeech: '',
        meaning: 'Sin definición disponible.',
      );
    }

    final cacheKey = '$norm|$learningLocale|$homeLocale';
    if (_cache.containsKey(cacheKey)) {
      return _cache[cacheKey]!;
    }

    WordDefinition? result;

    // 1. Búsqueda directa o lematizada en español
    var match = _resolveSpanish(norm);

    // 2. Si no hubo coincidencia y el contexto es inglés o palabra inglesa, lematización en inglés
    match ??= _resolveEnglish(norm);

    if (match != null) {
      result = WordDefinition(
        word: norm,
        displayWord: _capitalize(rawWord.trim().replaceAll(RegExp(r'[^\p{L}\p{N}]+$', unicode: true), '')),
        partOfSpeech: match.partOfSpeech,
        meaning: match.meaning,
        example: match.example,
      );
    }

    // 3. Intento de consulta en línea si no hubo coincidencia local
    // 3a. Para español (Wikipedia REST Summary API en español)
    if (result == null && (learningLocale.startsWith('es') || homeLocale.startsWith('es'))) {
      try {
        final uri = Uri.parse('https://es.wikipedia.org/api/rest_v1/page/summary/${Uri.encodeComponent(norm)}');
        final response = await http.get(uri).timeout(const Duration(milliseconds: 1800));
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          if (data is Map<String, dynamic>) {
            final desc = data['description'] as String?;
            final extract = data['extract'] as String?;
            String? meaningText;
            if (desc != null && desc.trim().isNotEmpty && !desc.toLowerCase().contains('desambiguación')) {
              meaningText = _capitalize(desc.trim());
              if (!meaningText.endsWith('.')) meaningText = '$meaningText.';
            } else if (extract != null && extract.trim().isNotEmpty) {
              final firstSentence = extract.split(RegExp(r'\.\s+')).first.trim();
              if (firstSentence.isNotEmpty) {
                meaningText = firstSentence.endsWith('.') ? firstSentence : '$firstSentence.';
              }
            }
            if (meaningText != null) {
              result = WordDefinition(
                word: norm,
                displayWord: _capitalize(norm),
                partOfSpeech: 'significado',
                meaning: meaningText,
              );
            }
          }
        }
      } catch (_) {}
    }

    // 3b. Para inglés (Free Dictionary API)
    if (result == null && learningLocale.startsWith('en')) {
      try {
        final uri = Uri.parse('https://api.dictionaryapi.dev/api/v2/entries/en/${Uri.encodeComponent(norm)}');
        final response = await http.get(uri).timeout(const Duration(milliseconds: 1800));
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          if (data is List && data.isNotEmpty) {
            final entry = data.first as Map<String, dynamic>;
            final meanings = entry['meanings'] as List?;
            if (meanings != null && meanings.isNotEmpty) {
              final firstMeaning = meanings.first as Map<String, dynamic>;
              final part = firstMeaning['partOfSpeech'] as String? ?? 'palabra';
              final defs = firstMeaning['definitions'] as List?;
              if (defs != null && defs.isNotEmpty) {
                final defText = (defs.first as Map<String, dynamic>)['definition'] as String? ?? '';
                final exText = (defs.first as Map<String, dynamic>)['example'] as String?;
                result = WordDefinition(
                  word: norm,
                  displayWord: _capitalize(norm),
                  partOfSpeech: part,
                  meaning: defText,
                  example: exText,
                );
              }
            }
          }
        }
      } catch (_) {}
    }

    // 4. Fallback didáctico inteligente y descriptivo
    var finalDef = result ??
        (learningLocale.startsWith('en')
            ? WordDefinition(
                word: norm,
                displayWord: _capitalize(norm),
                partOfSpeech: 'palabra',
                meaning:
                    'Palabra en $learningLocale. Pulsa «Volver a escuchar» para oír su pronunciación con el narrador.',
              )
            : _generateSpanishFallback(norm));

    // 5. Enriquecimiento con traducción bilingüe
    final targetLang = TranslationService.resolveTargetLanguage(
      fromLocale: learningLocale,
      toLocale: homeLocale,
    );
    try {
      final translation = await TranslationService.instance.translateWord(
        norm,
        fromLocale: learningLocale,
        toLocale: homeLocale,
      );
      if (translation != null && translation.trim().isNotEmpty) {
        finalDef = finalDef.copyWith(
          translation: translation.trim(),
          translationLocale: targetLang,
        );
      }
    } catch (_) {}

    _cache[cacheKey] = finalDef;
    return finalDef;
  }

  static WordDefinition? _resolveSpanish(String norm) {
    var match = _localDefinitions[norm];
    if (match != null) return match;

    // Normalización de tildes: árbol -> arbol, corazón -> corazon
    final unaccented = _stripAccents(norm);
    match = _accentFallback[unaccented] != null ? _localDefinitions[_accentFallback[unaccented]!] : null;
    if (match != null) return match;

    // Plurales: -ces -> -z (luces -> luz, peces -> pez, voces -> voz, lápices -> lápiz)
    if (norm.endsWith('ces') && norm.length > 3) {
      final singular = '${norm.substring(0, norm.length - 3)}z';
      match = _localDefinitions[singular];
      if (match != null) return match;
    }

    // Plurales: -es (árboles -> árbol, flores -> flor, colores -> color)
    if (norm.endsWith('es') && norm.length > 3) {
      final stem = norm.substring(0, norm.length - 2);
      match = _localDefinitions[stem] ?? (_accentFallback[stem] != null ? _localDefinitions[_accentFallback[stem]!] : null);
      if (match != null) return match;
    }

    // Plurales: -s (casas -> casa, perros -> perro, libros -> libro)
    if (norm.endsWith('s') && norm.length > 2) {
      final singular = norm.substring(0, norm.length - 1);
      match = _localDefinitions[singular] ?? (_accentFallback[singular] != null ? _localDefinitions[_accentFallback[singular]!] : null);
      if (match != null) return match;
    }

    // Diminutivos comunes: -ito, -ita, -itos, -itas
    if (norm.endsWith('itos') || norm.endsWith('itas')) {
      final stem = norm.substring(0, norm.length - 4);
      match = _localDefinitions['${stem}o'] ?? _localDefinitions['${stem}a'] ?? _localDefinitions[stem];
      if (match != null) return match;
    }
    if (norm.endsWith('ito') || norm.endsWith('ita')) {
      final stem = norm.substring(0, norm.length - 3);
      match = _localDefinitions['${stem}o'] ?? _localDefinitions['${stem}a'] ?? _localDefinitions[stem];
      if (match != null) return match;
    }

    // Femeninos: -a -> -o (pequeña -> pequeño, amiga -> amigo, gata -> gato)
    if (norm.endsWith('a') && norm.length > 2) {
      final masc = '${norm.substring(0, norm.length - 1)}o';
      match = _localDefinitions[masc];
      if (match != null) return match;
    }

    // Formas verbales comunes
    if (norm.endsWith('aron') || norm.endsWith('aban') || norm.endsWith('ando')) {
      final stem = norm.substring(0, norm.length - 4);
      match = _localDefinitions['${stem}ar'];
      if (match != null) return match;
    }
    if (norm.endsWith('aba')) {
      final stem = norm.substring(0, norm.length - 3);
      match = _localDefinitions['${stem}ar'];
      if (match != null) return match;
    }
    if (norm.endsWith('ieron') || norm.endsWith('iendo')) {
      final stem = norm.substring(0, norm.length - 5);
      match = _localDefinitions['${stem}er'] ?? _localDefinitions['${stem}ir'];
      if (match != null) return match;
    }
    if (norm.endsWith('ia') || norm.endsWith('ía') || norm.endsWith('ian') || norm.endsWith('ían')) {
      final stem = norm.replaceAll(RegExp(r'(ia|ía|ian|ían)$'), '');
      match = _localDefinitions['${stem}er'] ?? _localDefinitions['${stem}ir'] ?? _localDefinitions['${stem}ar'];
      if (match != null) return match;
    }

    return null;
  }

  static WordDefinition? _resolveEnglish(String norm) {
    var match = _localDefinitions[norm];
    if (match != null) return match;

    if (norm.endsWith('ies') && norm.length > 3) {
      final singular = '${norm.substring(0, norm.length - 3)}y';
      match = _localDefinitions[singular];
    } else if (norm.endsWith('es') && norm.length > 3) {
      match = _localDefinitions[norm.substring(0, norm.length - 2)] ??
          _localDefinitions[norm.substring(0, norm.length - 1)];
    } else if (norm.endsWith('s') && norm.length > 2) {
      match = _localDefinitions[norm.substring(0, norm.length - 1)];
    }

    if (match == null && norm.endsWith('ing') && norm.length > 4) {
      match = _localDefinitions[norm.substring(0, norm.length - 3)] ??
          _localDefinitions['${norm.substring(0, norm.length - 3)}e'];
    }

    if (match == null && norm.endsWith('ed') && norm.length > 3) {
      match = _localDefinitions[norm.substring(0, norm.length - 2)] ??
          _localDefinitions[norm.substring(0, norm.length - 1)];
    }

    return match;
  }

  static WordDefinition _generateSpanishFallback(String norm) {
    final cap = _capitalize(norm);
    if (norm.endsWith('mente')) {
      return WordDefinition(
        word: norm,
        displayWord: cap,
        partOfSpeech: 'adverbio',
        meaning: 'Expresa el modo, manera o forma en que se realiza una acción.',
      );
    }
    if (norm.endsWith('ción') || norm.endsWith('cion') || norm.endsWith('sión') || norm.endsWith('sion')) {
      return WordDefinition(
        word: norm,
        displayWord: cap,
        partOfSpeech: 'sustantivo',
        meaning: 'Indica la acción, proceso o resultado de una actividad.',
      );
    }
    if (norm.endsWith('dor') || norm.endsWith('dora')) {
      return WordDefinition(
        word: norm,
        displayWord: cap,
        partOfSpeech: 'sustantivo',
        meaning: 'Persona, objeto o elemento que ejecuta una función determinada.',
      );
    }
    if (norm.endsWith('oso') || norm.endsWith('osa')) {
      return WordDefinition(
        word: norm,
        displayWord: cap,
        partOfSpeech: 'adjetivo',
        meaning: 'Adjetivo que describe a alguien o algo que posee esa cualidad en abundancia.',
      );
    }
    if (norm.endsWith('ble')) {
      return WordDefinition(
        word: norm,
        displayWord: cap,
        partOfSpeech: 'adjetivo',
        meaning: 'Adjetivo que indica que algo se puede realizar o que tiene esa posibilidad.',
      );
    }
    if (norm.endsWith('ar') || norm.endsWith('er') || norm.endsWith('ir')) {
      return WordDefinition(
        word: norm,
        displayWord: cap,
        partOfSpeech: 'verbo',
        meaning: 'Verbo que describe una acción, estado o proceso en la historia.',
      );
    }
    return WordDefinition(
      word: norm,
      displayWord: cap,
      partOfSpeech: 'palabra',
      meaning: 'Término destacado en la lectura. Observa cómo acompaña la oración y pulsa «Volver a escuchar» para oír su sonido.',
    );
  }

  static String _stripAccents(String s) {
    return s
        .replaceAll('á', 'a')
        .replaceAll('é', 'e')
        .replaceAll('í', 'i')
        .replaceAll('ó', 'o')
        .replaceAll('ú', 'u')
        .replaceAll('ü', 'u');
  }

  static String _capitalize(String s) {
    if (s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1);
  }

  static const Map<String, String> _accentFallback = {
    'arbol': 'árbol',
    'pajaro': 'pájaro',
    'cancion': 'canción',
    'leccion': 'lección',
    'oracion': 'oración',
    'mama': 'mamá',
    'papa': 'papá',
    'corazon': 'corazón',
    'habia': 'había',
    'dia': 'día',
    'tio': 'tío',
    'tia': 'tía',
    'jardin': 'jardín',
    'raton': 'ratón',
    'leon': 'león',
    'bebe': 'bebé',
    'magico': 'mágico',
    'musica': 'música',
    'lapiz': 'lápiz',
    'rapido': 'rápido',
    'despues': 'después',
    'tambien': 'también',
  };

  /// Base de datos local didáctica y bilingüe para lecturas infantiles y escolares.
  static const Map<String, WordDefinition> _localDefinitions = {
    // ========================================================
    // --- ESPAÑOL: CONECTORES Y PALABRAS DE CUENTOS ---
    // ========================================================
    'había': WordDefinition(
      word: 'había',
      displayWord: 'Había',
      partOfSpeech: 'verbo',
      meaning: 'Forma del verbo haber. Indica la existencia o presencia de algo en el pasado, muy común al comenzar historias.',
      example: 'Había una vez un pequeño bosque lleno de flores.',
    ),
    'haber': WordDefinition(
      word: 'haber',
      displayWord: 'Haber',
      partOfSpeech: 'verbo',
      meaning: 'Verbo que expresa existencia de personas o cosas, o sirve como auxiliar para otros verbos.',
    ),
    'vez': WordDefinition(
      word: 'vez',
      displayWord: 'Vez',
      partOfSpeech: 'sustantivo',
      meaning: 'Momento u ocasión determinada en el tiempo en que ocurre algo.',
      example: 'Había una vez un lindo cuento.',
    ),
    'uno': WordDefinition(
      word: 'uno',
      displayWord: 'Uno',
      partOfSpeech: 'artículo / número',
      meaning: 'Indica una sola persona, animal o cosa.',
    ),
    'una': WordDefinition(
      word: 'una',
      displayWord: 'Una',
      partOfSpeech: 'artículo',
      meaning: 'Acompaña a un sustantivo femenino para indicar un solo elemento.',
      example: 'Una hermosa mañana de sol.',
    ),
    'el': WordDefinition(
      word: 'el',
      displayWord: 'El',
      partOfSpeech: 'artículo',
      meaning: 'Acompaña a un sustantivo masculino para indicar que ya es conocido en la lectura.',
    ),
    'la': WordDefinition(
      word: 'la',
      displayWord: 'La',
      partOfSpeech: 'artículo',
      meaning: 'Acompaña a un sustantivo femenino para identificarlo con claridad.',
    ),
    'los': WordDefinition(
      word: 'los',
      displayWord: 'Los',
      partOfSpeech: 'artículo',
      meaning: 'Indica varios elementos masculinos conocidos.',
    ),
    'las': WordDefinition(
      word: 'las',
      displayWord: 'Las',
      partOfSpeech: 'artículo',
      meaning: 'Indica varios elementos femeninos conocidos.',
    ),
    'este': WordDefinition(
      word: 'este',
      displayWord: 'Este',
      partOfSpeech: 'demostrativo',
      meaning: 'Señala a una persona, animal o cosa que está cerca de quien habla o lee.',
    ),
    'esta': WordDefinition(
      word: 'esta',
      displayWord: 'Esta',
      partOfSpeech: 'demostrativo',
      meaning: 'Señala un elemento femenino que está cercano en el espacio o en el tiempo.',
    ),
    'todo': WordDefinition(
      word: 'todo',
      displayWord: 'Todo',
      partOfSpeech: 'adjetivo / pronombre',
      meaning: 'Indica la totalidad completa sin que falte ninguna parte.',
    ),
    'todos': WordDefinition(
      word: 'todos',
      displayWord: 'Todos',
      partOfSpeech: 'adjetivo / pronombre',
      meaning: 'La totalidad de personas, seres o cosas que integran un grupo.',
      example: 'Todos los niños salieron a jugar juntos.',
    ),
    'mucho': WordDefinition(
      word: 'mucho',
      displayWord: 'Mucho',
      partOfSpeech: 'adjetivo / adverbio',
      meaning: 'En gran cantidad, abundancia o intensidad.',
    ),
    'poco': WordDefinition(
      word: 'poco',
      displayWord: 'Poco',
      partOfSpeech: 'adjetivo / adverbio',
      meaning: 'En escasa cantidad o pequeña porción.',
    ),
    'muy': WordDefinition(
      word: 'muy',
      displayWord: 'Muy',
      partOfSpeech: 'adverbio',
      meaning: 'Aumenta la intensidad o cualidad de la palabra que acompaña.',
      example: 'El niño estaba muy feliz.',
    ),
    'más': WordDefinition(
      word: 'más',
      displayWord: 'Más',
      partOfSpeech: 'adverbio',
      meaning: 'Indica una cantidad o grado superior en comparación con otro.',
    ),
    'menos': WordDefinition(
      word: 'menos',
      displayWord: 'Menos',
      partOfSpeech: 'adverbio',
      meaning: 'Indica una cantidad o grado inferior.',
    ),
    'bien': WordDefinition(
      word: 'bien',
      displayWord: 'Bien',
      partOfSpeech: 'adverbio',
      meaning: 'De manera correcta, agradable, satisfactoria o adecuada.',
    ),
    'mal': WordDefinition(
      word: 'mal',
      displayWord: 'Mal',
      partOfSpeech: 'adverbio',
      meaning: 'De manera contraria a lo bueno, adecuado o conveniente.',
    ),
    'siempre': WordDefinition(
      word: 'siempre',
      displayWord: 'Siempre',
      partOfSpeech: 'adverbio',
      meaning: 'En todo momento, sin interrupción o en todas las ocasiones.',
      example: 'Los amigos siempre se ayudan.',
    ),
    'nunca': WordDefinition(
      word: 'nunca',
      displayWord: 'Nunca',
      partOfSpeech: 'adverbio',
      meaning: 'En ningún momento o en ninguna ocasión.',
    ),
    'después': WordDefinition(
      word: 'después',
      displayWord: 'Después',
      partOfSpeech: 'adverbio',
      meaning: 'En un momento posterior en el tiempo o a continuación de algo.',
      example: 'Después de leer, fuimos al parque.',
    ),
    'antes': WordDefinition(
      word: 'antes',
      displayWord: 'Antes',
      partOfSpeech: 'adverbio',
      meaning: 'En un tiempo previo o que precede a otro suceso.',
    ),
    'ahora': WordDefinition(
      word: 'ahora',
      displayWord: 'Ahora',
      partOfSpeech: 'adverbio',
      meaning: 'En el tiempo presente o en este preciso instante.',
    ),
    'entonces': WordDefinition(
      word: 'entonces',
      displayWord: 'Entonces',
      partOfSpeech: 'adverbio / conector',
      meaning: 'En aquel tiempo o como consecuencia de lo que ocurrió.',
    ),
    'mientras': WordDefinition(
      word: 'mientras',
      displayWord: 'Mientras',
      partOfSpeech: 'conector',
      meaning: 'Durante el tiempo en que transcurre otra acción simultánea.',
    ),
    'cuando': WordDefinition(
      word: 'cuando',
      displayWord: 'Cuando',
      partOfSpeech: 'conector',
      meaning: 'Indica el momento u ocasión en que sucede algo.',
    ),
    'donde': WordDefinition(
      word: 'donde',
      displayWord: 'Donde',
      partOfSpeech: 'adverbio',
      meaning: 'Indica el lugar o sitio en el que ocurre una acción.',
    ),
    'porque': WordDefinition(
      word: 'porque',
      displayWord: 'Porque',
      partOfSpeech: 'conector',
      meaning: 'Explica la causa, motivo o razón por la cual pasa algo.',
      example: 'Sonreía porque estaba alegre.',
    ),
    'juntos': WordDefinition(
      word: 'juntos',
      displayWord: 'Juntos',
      partOfSpeech: 'adjetivo / adverbio',
      meaning: 'Unidos en compañía de otros compartiendo una actividad.',
      example: 'Leyeron el cuento juntos en familia.',
    ),
    'solo': WordDefinition(
      word: 'solo',
      displayWord: 'Solo',
      partOfSpeech: 'adjetivo',
      meaning: 'Sin compañía de otra persona o elemento.',
    ),

    // ========================================================
    // --- ESPAÑOL: FAMILIA Y PERSONAS ---
    // ========================================================
    'niño': WordDefinition(
      word: 'niño',
      displayWord: 'Niño',
      partOfSpeech: 'sustantivo',
      meaning: 'Persona de corta edad que está en la etapa de la niñez, jugando, aprendiendo y creciendo.',
      example: 'El niño descubrió un libro mágico.',
    ),
    'niña': WordDefinition(
      word: 'niña',
      displayWord: 'Niña',
      partOfSpeech: 'sustantivo',
      meaning: 'Persona femenina de corta edad en su etapa de infancia.',
      example: 'La niña sonreía con emoción.',
    ),
    'bebé': WordDefinition(
      word: 'bebé',
      displayWord: 'Bebé',
      partOfSpeech: 'sustantivo',
      meaning: 'Niño muy pequeño recién nacido que recibe el cuidado amoroso de su familia.',
    ),
    'papá': WordDefinition(
      word: 'papá',
      displayWord: 'Papá',
      partOfSpeech: 'sustantivo',
      meaning: 'Padre. Hombre que cuida, guía y ama profundamente a sus hijos.',
      example: 'Papá lee un cuento antes de dormir.',
    ),
    'padre': WordDefinition(
      word: 'padre',
      displayWord: 'Padre',
      partOfSpeech: 'sustantivo',
      meaning: 'Varón que ha engendrado o adoptado a un hijo y forma un pilar en la familia.',
    ),
    'padres': WordDefinition(
      word: 'padres',
      displayWord: 'Padres',
      partOfSpeech: 'sustantivo',
      meaning: 'El papá y la mamá juntos; responsables de cuidar, educar y apoyar a sus hijos.',
      example: 'Mis padres me acompañan en la escuela.',
    ),
    'mamá': WordDefinition(
      word: 'mamá',
      displayWord: 'Mamá',
      partOfSpeech: 'sustantivo',
      meaning: 'Madre. Mujer que cuida, educa y protege a sus hijos con amor incondicional.',
      example: 'Mamá me ayuda a practicar la lectura.',
    ),
    'madre': WordDefinition(
      word: 'madre',
      displayWord: 'Madre',
      partOfSpeech: 'sustantivo',
      meaning: 'Mujer que ha tenido o adoptado un hijo y le brinda cariño y cuidados.',
    ),
    'hijo': WordDefinition(
      word: 'hijo',
      displayWord: 'Hijo',
      partOfSpeech: 'sustantivo',
      meaning: 'Persona respecto de su padre y de su madre.',
    ),
    'hija': WordDefinition(
      word: 'hija',
      displayWord: 'Hija',
      partOfSpeech: 'sustantivo',
      meaning: 'Persona femenina respecto de sus padres.',
    ),
    'hermano': WordDefinition(
      word: 'hermano',
      displayWord: 'Hermano',
      partOfSpeech: 'sustantivo',
      meaning: 'Persona que tiene los mismos padres que otra y comparte el crecimiento familiar.',
    ),
    'hermana': WordDefinition(
      word: 'hermana',
      displayWord: 'Hermana',
      partOfSpeech: 'sustantivo',
      meaning: 'Persona femenina que tiene los mismos padres que otra.',
    ),
    'abuelo': WordDefinition(
      word: 'abuelo',
      displayWord: 'Abuelo',
      partOfSpeech: 'sustantivo',
      meaning: 'Padre del padre o de la madre de una persona, lleno de historias y sabiduría.',
    ),
    'abuela': WordDefinition(
      word: 'abuela',
      displayWord: 'Abuela',
      partOfSpeech: 'sustantivo',
      meaning: 'Madre del padre o de la madre de una persona, llena de cariño y ternura.',
    ),
    'amigo': WordDefinition(
      word: 'amigo',
      displayWord: 'Amigo',
      partOfSpeech: 'sustantivo',
      meaning: 'Persona con quien se tiene una relación especial de afecto, confianza, respeto y juegos.',
      example: 'Mi mejor amigo comparte sus lápices conmigo.',
    ),
    'amiga': WordDefinition(
      word: 'amiga',
      displayWord: 'Amiga',
      partOfSpeech: 'sustantivo',
      meaning: 'Compañera con quien se comparte cariño, juegos y aventuras.',
    ),
    'familia': WordDefinition(
      word: 'familia',
      displayWord: 'Familia',
      partOfSpeech: 'sustantivo',
      meaning: 'Grupo de personas unidas por el amor y parentesco que conviven, se ayudan y aprenden juntas.',
    ),
    'maestro': WordDefinition(
      word: 'maestro',
      displayWord: 'Maestro',
      partOfSpeech: 'sustantivo',
      meaning: 'Persona dedicada a enseñar, educar y guiar a los niños en su camino de aprendizaje.',
    ),
    'maestra': WordDefinition(
      word: 'maestra',
      displayWord: 'Maestra',
      partOfSpeech: 'sustantivo',
      meaning: 'Profesora que enseña con paciencia y entusiasmo en la escuela.',
    ),
    'profesor': WordDefinition(
      word: 'profesor',
      displayWord: 'Profesor',
      partOfSpeech: 'sustantivo',
      meaning: 'Persona que tiene por oficio enseñar una materia o arte.',
    ),
    'profesora': WordDefinition(
      word: 'profesora',
      displayWord: 'Profesora',
      partOfSpeech: 'sustantivo',
      meaning: 'Persona femenina que se dedica a la enseñanza profesional.',
    ),
    'estudiante': WordDefinition(
      word: 'estudiante',
      displayWord: 'Estudiante',
      partOfSpeech: 'sustantivo',
      meaning: 'Persona que asiste a clases y dedica tiempo a aprender y explorar nuevos saberes.',
    ),

    // ========================================================
    // --- ESPAÑOL: ESCUELA Y LIBROS ---
    // ========================================================
    'escuela': WordDefinition(
      word: 'escuela',
      displayWord: 'Escuela',
      partOfSpeech: 'sustantivo',
      meaning: 'Institución y edificio donde los niños y jóvenes van a estudiar, aprender, convivir y jugar.',
      example: 'Cada día voy contento a la escuela.',
    ),
    'colegio': WordDefinition(
      word: 'colegio',
      displayWord: 'Colegio',
      partOfSpeech: 'sustantivo',
      meaning: 'Centro escolar donde se imparte enseñanza a los alumnos.',
    ),
    'libro': WordDefinition(
      word: 'libro',
      displayWord: 'Libro',
      partOfSpeech: 'sustantivo',
      meaning: 'Conjunto de páginas encuadernadas que contienen textos, cuentos e imágenes para leer y aprender.',
      example: 'Este libro nos cuenta una historia maravillosa.',
    ),
    'libros': WordDefinition(
      word: 'libros',
      displayWord: 'Libros',
      partOfSpeech: 'sustantivo',
      meaning: 'Varios volúmenes de lectura y aprendizaje que abren mundos a la imaginación.',
    ),
    'página': WordDefinition(
      word: 'página',
      displayWord: 'Página',
      partOfSpeech: 'sustantivo',
      meaning: 'Cada una de las dos caras de una hoja de papel en un libro o cuaderno.',
    ),
    'páginas': WordDefinition(
      word: 'páginas',
      displayWord: 'Páginas',
      partOfSpeech: 'sustantivo',
      meaning: 'Hojas que forman el cuerpo de un libro donde se lee la historia.',
    ),
    'cuento': WordDefinition(
      word: 'cuento',
      displayWord: 'Cuento',
      partOfSpeech: 'sustantivo',
      meaning: 'Relato o narración corta de hechos reales o fantásticos, con personajes interesantes.',
      example: 'El cuento del dragón bondadoso.',
    ),
    'historia': WordDefinition(
      word: 'historia',
      displayWord: 'Historia',
      partOfSpeech: 'sustantivo',
      meaning: 'Narración de sucesos que ocurrieron en el tiempo o relato de ficción estructurado.',
    ),
    'palabra': WordDefinition(
      word: 'palabra',
      displayWord: 'Palabra',
      partOfSpeech: 'sustantivo',
      meaning: 'Sonido o conjunto de letras que expresa una idea y forma el lenguaje.',
    ),
    'letra': WordDefinition(
      word: 'letra',
      displayWord: 'Letra',
      partOfSpeech: 'sustantivo',
      meaning: 'Cada uno de los signos gráficos que componen el alfabeto para escribir palabras.',
    ),
    'oración': WordDefinition(
      word: 'oración',
      displayWord: 'Oración',
      partOfSpeech: 'sustantivo',
      meaning: 'Conjunto de palabras con sentido completo que comunica un mensaje o pensamiento.',
    ),
    'párrafo': WordDefinition(
      word: 'párrafo',
      displayWord: 'Párrafo',
      partOfSpeech: 'sustantivo',
      meaning: 'Sección de un texto formada por una o más oraciones que expresan una idea central.',
    ),
    'lápiz': WordDefinition(
      word: 'lápiz',
      displayWord: 'Lápiz',
      partOfSpeech: 'sustantivo',
      meaning: 'Instrumento de madera con mina de grafito que se utiliza para escribir y dibujar.',
    ),
    'cuaderno': WordDefinition(
      word: 'cuaderno',
      displayWord: 'Cuaderno',
      partOfSpeech: 'sustantivo',
      meaning: 'Conjunto de hojas de papel unidas donde los estudiantes escriben sus notas y ejercicios.',
    ),
    'clase': WordDefinition(
      word: 'clase',
      displayWord: 'Clase',
      partOfSpeech: 'sustantivo',
      meaning: 'Sesión de enseñanza en la que el profesor y los alumnos trabajan sobre un tema.',
    ),
    'tarea': WordDefinition(
      word: 'tarea',
      displayWord: 'Tarea',
      partOfSpeech: 'sustantivo',
      meaning: 'Actividad o ejercicio que se realiza en casa para repasar lo aprendido en la escuela.',
    ),
    'lectura': WordDefinition(
      word: 'lectura',
      displayWord: 'Lectura',
      partOfSpeech: 'sustantivo',
      meaning: 'Acción de leer e interpretar textos para comprender historias e ideas nuevas.',
    ),

    // ========================================================
    // --- ESPAÑOL: NATURALEZA Y ANIMALES ---
    // ========================================================
    'árbol': WordDefinition(
      word: 'árbol',
      displayWord: 'Árbol',
      partOfSpeech: 'sustantivo',
      meaning: 'Planta de gran tamaño con tronco de madera, ramas fuertes y muchas hojas verdes que da sombra.',
      example: 'El pajarito construyó su nido en el árbol.',
    ),
    'bosque': WordDefinition(
      word: 'bosque',
      displayWord: 'Bosque',
      partOfSpeech: 'sustantivo',
      meaning: 'Lugar grande de la naturaleza poblado de muchos árboles, arbustos, flores y animales silvestres.',
      example: 'Caminaron por los senderos del bosque verde.',
    ),
    'flor': WordDefinition(
      word: 'flor',
      displayWord: 'Flor',
      partOfSpeech: 'sustantivo',
      meaning: 'Parte colorida y perfumada de las plantas que alegra los campos y jardines.',
      example: 'La abeja visitó una flor amarilla.',
    ),
    'flores': WordDefinition(
      word: 'flores',
      displayWord: 'Flores',
      partOfSpeech: 'sustantivo',
      meaning: 'Conjunto de brotes coloridos de las plantas que adornan la naturaleza.',
    ),
    'planta': WordDefinition(
      word: 'planta',
      displayWord: 'Planta',
      partOfSpeech: 'sustantivo',
      meaning: 'Ser vivo vegetal que crece en la tierra con raíces, tallo y hojas gracias al agua y al sol.',
    ),
    'sol': WordDefinition(
      word: 'sol',
      displayWord: 'Sol',
      partOfSpeech: 'sustantivo',
      meaning: 'Gran estrella brillante en el cielo que nos da luz, calor y energía durante el día.',
      example: 'El sol brillante calentaba la mañana.',
    ),
    'luna': WordDefinition(
      word: 'luna',
      displayWord: 'Luna',
      partOfSpeech: 'sustantivo',
      meaning: 'Astro que acompaña a la Tierra en la noche y refleja suavemente la luz del sol.',
      example: 'La luna llena iluminaba el camino.',
    ),
    'estrella': WordDefinition(
      word: 'estrella',
      displayWord: 'Estrella',
      partOfSpeech: 'sustantivo',
      meaning: 'Astro luminoso en el cielo nocturno que brilla con su propia luz como un diamante.',
    ),
    'estrellas': WordDefinition(
      word: 'estrellas',
      displayWord: 'Estrellas',
      partOfSpeech: 'sustantivo',
      meaning: 'Muchos puntos luminosos en el cielo de la noche que forman constelaciones.',
    ),
    'cielo': WordDefinition(
      word: 'cielo',
      displayWord: 'Cielo',
      partOfSpeech: 'sustantivo',
      meaning: 'Espacio azul visible sobre nuestras cabezas donde vuelan las aves y se ven las nubes.',
    ),
    'nube': WordDefinition(
      word: 'nube',
      displayWord: 'Nube',
      partOfSpeech: 'sustantivo',
      meaning: 'Masa blanca o gris que flota en el cielo compuesta de gotas de agua.',
    ),
    'nubes': WordDefinition(
      word: 'nubes',
      displayWord: 'Nubes',
      partOfSpeech: 'sustantivo',
      meaning: 'Formaciones en el cielo que a veces anuncian lluvia refrescante.',
    ),
    'lluvia': WordDefinition(
      word: 'lluvia',
      displayWord: 'Lluvia',
      partOfSpeech: 'sustantivo',
      meaning: 'Gotas de agua que caen del cielo para regar la tierra y alimentar los ríos.',
    ),
    'viento': WordDefinition(
      word: 'viento',
      displayWord: 'Viento',
      partOfSpeech: 'sustantivo',
      meaning: 'Corriente de aire en movimiento que refresca y mece las hojas de los árboles.',
    ),
    'agua': WordDefinition(
      word: 'agua',
      displayWord: 'Agua',
      partOfSpeech: 'sustantivo',
      meaning: 'Líquido transparente y vital para la vida de todos los animales, plantas y personas.',
    ),
    'río': WordDefinition(
      word: 'río',
      displayWord: 'Río',
      partOfSpeech: 'sustantivo',
      meaning: 'Corriente continua de agua dulce que viaja hacia un lago o el mar.',
    ),
    'mar': WordDefinition(
      word: 'mar',
      displayWord: 'Mar',
      partOfSpeech: 'sustantivo',
      meaning: 'Gran extensión de agua salada donde habitan peces, ballenas y delfines.',
    ),
    'montaña': WordDefinition(
      word: 'montaña',
      displayWord: 'Montaña',
      partOfSpeech: 'sustantivo',
      meaning: 'Gran elevación natural del terreno de altura imponente que toca el cielo.',
    ),
    'tierra': WordDefinition(
      word: 'tierra',
      displayWord: 'Tierra',
      partOfSpeech: 'sustantivo',
      meaning: 'Suelo donde pisamos y sembramos plantas, o el planeta donde vivimos.',
    ),
    'campo': WordDefinition(
      word: 'campo',
      displayWord: 'Campo',
      partOfSpeech: 'sustantivo',
      meaning: 'Terreno amplio al aire libre rodeado de naturaleza, cultivos y animales.',
    ),
    'jardín': WordDefinition(
      word: 'jardín',
      displayWord: 'Jardín',
      partOfSpeech: 'sustantivo',
      meaning: 'Espacio cuidado con flores, plantas y pasto para disfrutar al aire libre.',
    ),
    'gato': WordDefinition(
      word: 'gato',
      displayWord: 'Gato',
      partOfSpeech: 'sustantivo',
      meaning: 'Animal doméstico ágil, curioso y suave que maúlla y ronronea cuando está contento.',
      example: 'El gato duerme bajo el sol.',
    ),
    'perro': WordDefinition(
      word: 'perro',
      displayWord: 'Perro',
      partOfSpeech: 'sustantivo',
      meaning: 'Animal doméstico muy leal, cariñoso y protector de cuatro patas que mueve la cola al saludar.',
      example: 'El perro corretea alegre en el patio.',
    ),
    'pájaro': WordDefinition(
      word: 'pájaro',
      displayWord: 'Pájaro',
      partOfSpeech: 'sustantivo',
      meaning: 'Animal con alas, plumas y pico que canta con alegría y vuela por el aire.',
    ),
    'ave': WordDefinition(
      word: 'ave',
      displayWord: 'Ave',
      partOfSpeech: 'sustantivo',
      meaning: 'Animal vertebrado con alas y plumas capaz de volar por el cielo.',
    ),
    'pez': WordDefinition(
      word: 'pez',
      displayWord: 'Pez',
      partOfSpeech: 'sustantivo',
      meaning: 'Animal que vive en el agua y nada usando sus aletas y cola.',
    ),
    'peces': WordDefinition(
      word: 'peces',
      displayWord: 'Peces',
      partOfSpeech: 'sustantivo',
      meaning: 'Varios animales acuáticos nadando en el río o el mar.',
    ),
    'caballo': WordDefinition(
      word: 'caballo',
      displayWord: 'Caballo',
      partOfSpeech: 'sustantivo',
      meaning: 'Animal grande, fuerte y veloz con crin y cola larga que ayuda en el campo.',
    ),
    'conejo': WordDefinition(
      word: 'conejo',
      displayWord: 'Conejo',
      partOfSpeech: 'sustantivo',
      meaning: 'Animal pequeño y rápido con orejas largas y cola de pompón al que le gustan las zanahorias.',
    ),
    'mariposa': WordDefinition(
      word: 'mariposa',
      displayWord: 'Mariposa',
      partOfSpeech: 'sustantivo',
      meaning: 'Insecto volador con alas grandes de hermosos colores que revolotea entre las flores.',
    ),
    'león': WordDefinition(
      word: 'león',
      displayWord: 'León',
      partOfSpeech: 'sustantivo',
      meaning: 'Gran felino de la sabana con majestuosa melena, conocido como el rey de los animales.',
    ),
    'oso': WordDefinition(
      word: 'oso',
      displayWord: 'Oso',
      partOfSpeech: 'sustantivo',
      meaning: 'Mamífero grande y fuerte con pelaje grueso que vive en bosques y montañas.',
    ),

    // ========================================================
    // --- ESPAÑOL: HOGAR Y CIUDAD ---
    // ========================================================
    'casa': WordDefinition(
      word: 'casa',
      displayWord: 'Casa',
      partOfSpeech: 'sustantivo',
      meaning: 'Lugar donde vive una familia, con paredes, techo y habitaciones para descansar y compartir.',
      example: 'Nuestra casa es un hogar lleno de amor.',
    ),
    'hogar': WordDefinition(
      word: 'hogar',
      displayWord: 'Hogar',
      partOfSpeech: 'sustantivo',
      meaning: 'Lugar donde una persona o familia habita con calidez, seguridad y cariño.',
    ),
    'puerta': WordDefinition(
      word: 'puerta',
      displayWord: 'Puerta',
      partOfSpeech: 'sustantivo',
      meaning: 'Abertura con un panel móvil que permite entrar o salir de una casa o habitación.',
    ),
    'ventana': WordDefinition(
      word: 'ventana',
      displayWord: 'Ventana',
      partOfSpeech: 'sustantivo',
      meaning: 'Abertura en la pared con cristal para dejar entrar la luz del sol y el aire fresco.',
    ),
    'cama': WordDefinition(
      word: 'cama',
      displayWord: 'Cama',
      partOfSpeech: 'sustantivo',
      meaning: 'Mueble con colchón, sábanas y almohada donde nos acostamos para dormir y soñar.',
    ),
    'mesa': WordDefinition(
      word: 'mesa',
      displayWord: 'Mesa',
      partOfSpeech: 'sustantivo',
      meaning: 'Mueble con una superficie plana sostenida por patas para comer, dibujar o estudiar.',
    ),
    'silla': WordDefinition(
      word: 'silla',
      displayWord: 'Silla',
      partOfSpeech: 'sustantivo',
      meaning: 'Mueble con asiento y respaldo diseñado para sentarse cómodamente.',
    ),
    'comida': WordDefinition(
      word: 'comida',
      displayWord: 'Comida',
      partOfSpeech: 'sustantivo',
      meaning: 'Alimento nutritivo que comemos para crecer fuertes y tener energía todo el día.',
    ),
    'pan': WordDefinition(
      word: 'pan',
      displayWord: 'Pan',
      partOfSpeech: 'sustantivo',
      meaning: 'Alimento básico y delicioso horneado a base de harina, agua y levadura.',
    ),
    'leche': WordDefinition(
      word: 'leche',
      displayWord: 'Leche',
      partOfSpeech: 'sustantivo',
      meaning: 'Bebida blanca, nutritiva y rica en calcio que ayuda a tener huesos fuertes.',
    ),
    'manzana': WordDefinition(
      word: 'manzana',
      displayWord: 'Manzana',
      partOfSpeech: 'sustantivo',
      meaning: 'Fruta redonda de color rojo, verde o amarillo, dulce, jugosa y crujiente.',
    ),
    'juguete': WordDefinition(
      word: 'juguete',
      displayWord: 'Juguete',
      partOfSpeech: 'sustantivo',
      meaning: 'Objeto con el que los niños juegan para divertirse e inventar historias.',
    ),
    'pelota': WordDefinition(
      word: 'pelota',
      displayWord: 'Pelota',
      partOfSpeech: 'sustantivo',
      meaning: 'Objeto redondo y elástico que rebota y se usa en muchos juegos divertidos.',
    ),
    'camino': WordDefinition(
      word: 'camino',
      displayWord: 'Camino',
      partOfSpeech: 'sustantivo',
      meaning: 'Vía o sendero por donde se camina o viaja de un lugar a otro.',
    ),
    'calle': WordDefinition(
      word: 'calle',
      displayWord: 'Calle',
      partOfSpeech: 'sustantivo',
      meaning: 'Vía en un pueblo o ciudad flanqueada por casas y aceras para transitar.',
    ),
    'ciudad': WordDefinition(
      word: 'ciudad',
      displayWord: 'Ciudad',
      partOfSpeech: 'sustantivo',
      meaning: 'Población grande con muchas casas, edificios, calles, parques y tiendas.',
    ),
    'pueblo': WordDefinition(
      word: 'pueblo',
      displayWord: 'Pueblo',
      partOfSpeech: 'sustantivo',
      meaning: 'Comunidad o población pequeña con vida tranquila y vecinal.',
    ),

    // ========================================================
    // --- ESPAÑOL: VERBOS Y ACCIONES ---
    // ========================================================
    'jugar': WordDefinition(
      word: 'jugar',
      displayWord: 'Jugar',
      partOfSpeech: 'verbo',
      meaning: 'Hacer una actividad divertida por entretenimiento o juego con amigos o juguetes.',
      example: 'A los niños les encanta jugar en el recreo.',
    ),
    'aprender': WordDefinition(
      word: 'aprender',
      displayWord: 'Aprender',
      partOfSpeech: 'verbo',
      meaning: 'Adquirir nuevos conocimientos, destrezas o habilidades mediante el estudio y la práctica.',
      example: 'Leyendo aprendemos cosas fascinantes.',
    ),
    'leer': WordDefinition(
      word: 'leer',
      displayWord: 'Leer',
      partOfSpeech: 'verbo',
      meaning: 'Comprender e interpretar las palabras escritas para descubrir una historia.',
      example: 'Me gusta leer antes de ir a dormir.',
    ),
    'escribir': WordDefinition(
      word: 'escribir',
      displayWord: 'Escribir',
      partOfSpeech: 'verbo',
      meaning: 'Trazar letras y signos en el papel para comunicar pensamientos o mensajes.',
    ),
    'cantar': WordDefinition(
      word: 'cantar',
      displayWord: 'Cantar',
      partOfSpeech: 'verbo',
      meaning: 'Emitir sonidos melodiosos con la voz formando canciones agradables.',
    ),
    'bailar': WordDefinition(
      word: 'bailar',
      displayWord: 'Bailar',
      partOfSpeech: 'verbo',
      meaning: 'Mover el cuerpo al ritmo de la música con alegría.',
    ),
    'reír': WordDefinition(
      word: 'reír',
      displayWord: 'Reír',
      partOfSpeech: 'verbo',
      meaning: 'Manifestar alegría con sonidos y gestos risueños en el rostro.',
    ),
    'sonreír': WordDefinition(
      word: 'sonreír',
      displayWord: 'Sonreír',
      partOfSpeech: 'verbo',
      meaning: 'Hacer una sonrisa amable que demuestra felicidad y cariño hacia los demás.',
    ),
    'correr': WordDefinition(
      word: 'correr',
      displayWord: 'Correr',
      partOfSpeech: 'verbo',
      meaning: 'Avanzar a gran velocidad dando zancadas rápidas con los pies.',
    ),
    'caminar': WordDefinition(
      word: 'caminar',
      displayWord: 'Caminar',
      partOfSpeech: 'verbo',
      meaning: 'Avanzar dando pasos con tranquilidad disfrutando del paseo.',
    ),
    'saltar': WordDefinition(
      word: 'saltar',
      displayWord: 'Saltar',
      partOfSpeech: 'verbo',
      meaning: 'Elevarse del suelo con un impulso ágil de las piernas.',
    ),
    'volar': WordDefinition(
      word: 'volar',
      displayWord: 'Volar',
      partOfSpeech: 'verbo',
      meaning: 'Desplazarse libremente por el aire usando las alas.',
    ),
    'nadar': WordDefinition(
      word: 'nadar',
      displayWord: 'Nadar',
      partOfSpeech: 'verbo',
      meaning: 'Avanzar en el agua usando los brazos y las piernas.',
    ),
    'hablar': WordDefinition(
      word: 'hablar',
      displayWord: 'Hablar',
      partOfSpeech: 'verbo',
      meaning: 'Comunicarse con otros pronunciando palabras con la voz.',
    ),
    'escuchar': WordDefinition(
      word: 'escuchar',
      displayWord: 'Escuchar',
      partOfSpeech: 'verbo',
      meaning: 'Prestar atención con los oídos a lo que se oye o a lo que nos dicen.',
    ),
    'mirar': WordDefinition(
      word: 'mirar',
      displayWord: 'Mirar',
      partOfSpeech: 'verbo',
      meaning: 'Dirigir la vista hacia algo para observarlo con atención.',
    ),
    'ver': WordDefinition(
      word: 'ver',
      displayWord: 'Ver',
      partOfSpeech: 'verbo',
      meaning: 'Percibir por medio de los ojos las figuras y colores del entorno.',
    ),
    'buscar': WordDefinition(
      word: 'buscar',
      displayWord: 'Buscar',
      partOfSpeech: 'verbo',
      meaning: 'Hacer acciones para encontrar a una persona o cosa que queremos ver.',
    ),
    'encontrar': WordDefinition(
      word: 'encontrar',
      displayWord: 'Encontrar',
      partOfSpeech: 'verbo',
      meaning: 'Dar con lo que se estaba buscando o descubrir algo sorprendente.',
    ),
    'ayudar': WordDefinition(
      word: 'ayudar',
      displayWord: 'Ayudar',
      partOfSpeech: 'verbo',
      meaning: 'Prestar apoyo y colaboración a alguien para facilitarle una tarea.',
      example: 'Nos gusta ayudar a mamá en casa.',
    ),
    'querer': WordDefinition(
      word: 'querer',
      displayWord: 'Querer',
      partOfSpeech: 'verbo',
      meaning: 'Tener cariño, aprecio o desear algo bueno con ilusión.',
    ),
    'amar': WordDefinition(
      word: 'amar',
      displayWord: 'Amar',
      partOfSpeech: 'verbo',
      meaning: 'Sentir un amor y cariño muy profundo hacia la familia y los amigos.',
    ),
    'compartir': WordDefinition(
      word: 'compartir',
      displayWord: 'Compartir',
      partOfSpeech: 'verbo',
      meaning: 'Repartir o disfrutar juntos de un juguete, alimento o momento feliz.',
    ),
    'soñar': WordDefinition(
      word: 'soñar',
      displayWord: 'Soñar',
      partOfSpeech: 'verbo',
      meaning: 'Imaginar historias hermosas mientras se duerme o desear algo con esperanza.',
    ),
    'dormir': WordDefinition(
      word: 'dormir',
      displayWord: 'Dormir',
      partOfSpeech: 'verbo',
      meaning: 'Descansar plácidamente con los ojos cerrados para recargar energía.',
    ),
    'despertar': WordDefinition(
      word: 'despertar',
      displayWord: 'Despertar',
      partOfSpeech: 'verbo',
      meaning: 'Salir del sueño y abrir los ojos al iniciar un nuevo día.',
    ),
    'comer': WordDefinition(
      word: 'comer',
      displayWord: 'Comer',
      partOfSpeech: 'verbo',
      meaning: 'Masticar y tragar alimentos saludables para nutrir el cuerpo.',
    ),
    'vivir': WordDefinition(
      word: 'vivir',
      displayWord: 'Vivir',
      partOfSpeech: 'verbo',
      meaning: 'Tener vida, habitar un lugar y disfrutar de las experiencias del día.',
    ),
    'ser': WordDefinition(
      word: 'ser',
      displayWord: 'Ser',
      partOfSpeech: 'verbo',
      meaning: 'Verbo que define la esencia, identidad y cualidades de algo o alguien.',
    ),
    'estar': WordDefinition(
      word: 'estar',
      displayWord: 'Estar',
      partOfSpeech: 'verbo',
      meaning: 'Indica la ubicación, estado de ánimo o condición en un momento dado.',
    ),
    'tener': WordDefinition(
      word: 'tener',
      displayWord: 'Tener',
      partOfSpeech: 'verbo',
      meaning: 'Poseer algo o sentir una emoción como alegría, calma o curiosidad.',
    ),
    'hacer': WordDefinition(
      word: 'hacer',
      displayWord: 'Hacer',
      partOfSpeech: 'verbo',
      meaning: 'Realizar, construir, dibujar o llevar a cabo una actividad.',
    ),
    'ir': WordDefinition(
      word: 'ir',
      displayWord: 'Ir',
      partOfSpeech: 'verbo',
      meaning: 'Moverse o viajar de un lugar hacia otro.',
    ),
    'venir': WordDefinition(
      word: 'venir',
      displayWord: 'Venir',
      partOfSpeech: 'verbo',
      meaning: 'Avanzar o trasladarse hacia donde nos encontramos.',
    ),
    'decir': WordDefinition(
      word: 'decir',
      displayWord: 'Decir',
      partOfSpeech: 'verbo',
      meaning: 'Expresar ideas o palabras con la voz.',
    ),

    // ========================================================
    // --- ESPAÑOL: CUALIDADES Y ADJETIVOS ---
    // ========================================================
    'feliz': WordDefinition(
      word: 'feliz',
      displayWord: 'Feliz',
      partOfSpeech: 'adjetivo',
      meaning: 'Que siente mucha alegría, contento y satisfacción en su corazón.',
      example: 'El niño estaba muy feliz con su libro nuevo.',
    ),
    'alegre': WordDefinition(
      word: 'alegre',
      displayWord: 'Alegre',
      partOfSpeech: 'adjetivo',
      meaning: 'Lleno de entusiasmo, risas y buen humor.',
    ),
    'contento': WordDefinition(
      word: 'contento',
      displayWord: 'Contento',
      partOfSpeech: 'adjetivo',
      meaning: 'Que se siente satisfecho y tranquilo con lo que tiene o vive.',
    ),
    'triste': WordDefinition(
      word: 'triste',
      displayWord: 'Triste',
      partOfSpeech: 'adjetivo',
      meaning: 'Que siente pena o desánimo y necesita comprensión y un abrazo amigo.',
    ),
    'bueno': WordDefinition(
      word: 'bueno',
      displayWord: 'Bueno',
      partOfSpeech: 'adjetivo',
      meaning: 'Que tiene bondad en su corazón, actúa de forma correcta y ayuda a los demás.',
    ),
    'grande': WordDefinition(
      word: 'grande',
      displayWord: 'Grande',
      partOfSpeech: 'adjetivo',
      meaning: 'De tamaño considerable o superior al promedio.',
    ),
    'pequeño': WordDefinition(
      word: 'pequeño',
      displayWord: 'Pequeño',
      partOfSpeech: 'adjetivo',
      meaning: 'De tamaño reducido o de corta edad; chiquito y tierno.',
    ),
    'lindo': WordDefinition(
      word: 'lindo',
      displayWord: 'Lindo',
      partOfSpeech: 'adjetivo',
      meaning: 'Hermoso, agradable y bonito a la vista o de trato tierno.',
    ),
    'hermoso': WordDefinition(
      word: 'hermoso',
      displayWord: 'Hermoso',
      partOfSpeech: 'adjetivo',
      meaning: 'Que tiene gran belleza y despierta admiración y deleite.',
    ),
    'bonito': WordDefinition(
      word: 'bonito',
      displayWord: 'Bonito',
      partOfSpeech: 'adjetivo',
      meaning: 'Agradable y gracioso a la vista.',
    ),
    'fuerte': WordDefinition(
      word: 'fuerte',
      displayWord: 'Fuerte',
      partOfSpeech: 'adjetivo',
      meaning: 'Que tiene vigor, energía, resistencia y gran capacidad para salir adelante.',
    ),
    'rápido': WordDefinition(
      word: 'rápido',
      displayWord: 'Rápido',
      partOfSpeech: 'adjetivo / adverbio',
      meaning: 'Que se mueve velozmente o sucede en muy poco tiempo.',
    ),
    'lento': WordDefinition(
      word: 'lento',
      displayWord: 'Lento',
      partOfSpeech: 'adjetivo',
      meaning: 'Que se mueve despacio o toma su tiempo con calma.',
    ),
    'mágico': WordDefinition(
      word: 'mágico',
      displayWord: 'Mágico',
      partOfSpeech: 'adjetivo',
      meaning: 'Que tiene poderes fantásticos, misteriosos o maravillosos como en los cuentos de hadas.',
      example: 'El libro mágico abrió una puerta secreta.',
    ),
    'brillante': WordDefinition(
      word: 'brillante',
      displayWord: 'Brillante',
      partOfSpeech: 'adjetivo',
      meaning: 'Que emite mucha luz resplandeciente o destaca por su gran inteligencia.',
    ),
    'nuevo': WordDefinition(
      word: 'nuevo',
      displayWord: 'Nuevo',
      partOfSpeech: 'adjetivo',
      meaning: 'Que se ha estrenado recientemente o que no se conocía antes.',
    ),
    'dulce': WordDefinition(
      word: 'dulce',
      displayWord: 'Dulce',
      partOfSpeech: 'adjetivo',
      meaning: 'De sabor azucarado y agradable, o de carácter cariñoso y suave.',
    ),
    'suave': WordDefinition(
      word: 'suave',
      displayWord: 'Suave',
      partOfSpeech: 'adjetivo',
      meaning: 'Agradable y delicado al tocarlo, sin asperezas, como el pelaje de un conejo.',
    ),
    'rojo': WordDefinition(
      word: 'rojo',
      displayWord: 'Rojo',
      partOfSpeech: 'adjetivo / color',
      meaning: 'Color cálido y llamativo como el de las fresas, manzanas o el corazón.',
    ),
    'azul': WordDefinition(
      word: 'azul',
      displayWord: 'Azul',
      partOfSpeech: 'adjetivo / color',
      meaning: 'Color sereno como el del cielo despejado o las aguas profundas del mar.',
    ),
    'verde': WordDefinition(
      word: 'verde',
      displayWord: 'Verde',
      partOfSpeech: 'adjetivo / color',
      meaning: 'Color natural y fresco como el de las hojas de los árboles y los valles.',
    ),
    'amarillo': WordDefinition(
      word: 'amarillo',
      displayWord: 'Amarillo',
      partOfSpeech: 'adjetivo / color',
      meaning: 'Color luminoso y alegre como los rayos del sol o los girasoles.',
    ),
    'blanco': WordDefinition(
      word: 'blanco',
      displayWord: 'Blanco',
      partOfSpeech: 'adjetivo / color',
      meaning: 'Color claro y limpio como la nieve, las nubes o la leche.',
    ),
    'negro': WordDefinition(
      word: 'negro',
      displayWord: 'Negro',
      partOfSpeech: 'adjetivo / color',
      meaning: 'Color oscuro como la noche estrellada.',
    ),

    // ========================================================
    // --- INGLÉS: VOCABULARIO EDUCATIVO (BILINGÜE) ---
    // ========================================================
    'cat': WordDefinition(
      word: 'cat',
      displayWord: 'Cat',
      partOfSpeech: 'sustantivo',
      meaning: 'Gato. Animal doméstico pequeño, curioso y ágil con bigotes y cola, al que le encanta jugar y ronronear.',
      example: 'The cat likes to play.',
    ),
    'dog': WordDefinition(
      word: 'dog',
      displayWord: 'Dog',
      partOfSpeech: 'sustantivo',
      meaning: 'Perro. Animal fiel y cariñoso de cuatro patas, conocido como el mejor amigo de las personas.',
      example: 'The dog wags its tail.',
    ),
    'tree': WordDefinition(
      word: 'tree',
      displayWord: 'Tree',
      partOfSpeech: 'sustantivo',
      meaning: 'Árbol. Planta grande y fuerte con un tronco leñoso, ramas y muchas hojas verdes que dan sombra.',
      example: 'The magic tree is tall.',
    ),
    'bird': WordDefinition(
      word: 'bird',
      displayWord: 'Bird',
      partOfSpeech: 'sustantivo',
      meaning: 'Pájaro o ave. Animal con plumas y alas que canta alegremente y vuela en el cielo.',
    ),
    'fish': WordDefinition(
      word: 'fish',
      displayWord: 'Fish',
      partOfSpeech: 'sustantivo',
      meaning: 'Pez. Animal acuático que nada libremente en ríos, lagos y mares usando sus aletas.',
    ),
    'sun': WordDefinition(
      word: 'sun',
      displayWord: 'Sun',
      partOfSpeech: 'sustantivo',
      meaning: 'Sol. Gran estrella brillante y cálida que alumbra nuestro día y da energía a las plantas.',
    ),
    'water': WordDefinition(
      word: 'water',
      displayWord: 'Water',
      partOfSpeech: 'sustantivo',
      meaning: 'Agua. Líquido transparente y refrescante esencial para beber, jugar y para toda la naturaleza.',
    ),
    'flower': WordDefinition(
      word: 'flower',
      displayWord: 'Flower',
      partOfSpeech: 'sustantivo',
      meaning: 'Flor. Parte colorida y hermosa de las plantas que llena de vida los jardines.',
    ),
    'moon': WordDefinition(
      word: 'moon',
      displayWord: 'Moon',
      partOfSpeech: 'sustantivo',
      meaning: 'Luna. Astro brillante en el cielo nocturno que nos acompaña cuando descansamos.',
    ),
    'star': WordDefinition(
      word: 'star',
      displayWord: 'Star',
      partOfSpeech: 'sustantivo',
      meaning: 'Estrella. Pequeña luz brillante en el cielo nocturno que parece titilar.',
    ),
    'rain': WordDefinition(
      word: 'rain',
      displayWord: 'Rain',
      partOfSpeech: 'sustantivo',
      meaning: 'Lluvia. Gotitas de agua fresca que caen de las nubes para ayudar a crecer a las plantas.',
    ),
    'forest': WordDefinition(
      word: 'forest',
      displayWord: 'Forest',
      partOfSpeech: 'sustantivo',
      meaning: 'Bosque. Gran extensión llena de árboles y caminos donde viven muchos animales.',
    ),
    'book': WordDefinition(
      word: 'book',
      displayWord: 'Book',
      partOfSpeech: 'sustantivo',
      meaning: 'Libro. Conjunto de páginas con historias, letras y dibujos para descubrir el mundo.',
    ),
    'school': WordDefinition(
      word: 'school',
      displayWord: 'School',
      partOfSpeech: 'sustantivo',
      meaning: 'Escuela. Lugar especial donde aprendemos con maestros y amigos.',
    ),
    'teacher': WordDefinition(
      word: 'teacher',
      displayWord: 'Teacher',
      partOfSpeech: 'sustantivo',
      meaning: 'Maestro o maestra. Persona amable que nos guía y enseña cosas nuevas con paciencia.',
    ),
    'friend': WordDefinition(
      word: 'friend',
      displayWord: 'Friend',
      partOfSpeech: 'sustantivo',
      meaning: 'Amigo o amiga. Compañero con quien compartimos risas, juegos y confianza.',
    ),
    'house': WordDefinition(
      word: 'house',
      displayWord: 'House',
      partOfSpeech: 'sustantivo',
      meaning: 'Casa. Hogar donde vivimos protegidos y contentos con nuestra familia.',
    ),
    'home': WordDefinition(
      word: 'home',
      displayWord: 'Home',
      partOfSpeech: 'sustantivo',
      meaning: 'Hogar. Lugar lleno de cariño donde compartimos con quienes más queremos.',
    ),
    'family': WordDefinition(
      word: 'family',
      displayWord: 'Family',
      partOfSpeech: 'sustantivo',
      meaning: 'Familia. Las personas que nos cuidan, apoyan y aman todos los días.',
    ),
    'mother': WordDefinition(
      word: 'mother',
      displayWord: 'Mother',
      partOfSpeech: 'sustantivo',
      meaning: 'Madre o mamá. Quien nos brinda amor, abrazos y cuidado constante.',
    ),
    'father': WordDefinition(
      word: 'father',
      displayWord: 'Father',
      partOfSpeech: 'sustantivo',
      meaning: 'Padre o papá. Quien nos acompaña con cariño y protección.',
    ),
    'play': WordDefinition(
      word: 'play',
      displayWord: 'Play',
      partOfSpeech: 'verbo',
      meaning: 'Jugar. Divertirse haciendo juegos, deportes o inventando aventuras.',
      example: 'We play with our friends.',
    ),
    'learn': WordDefinition(
      word: 'learn',
      displayWord: 'Learn',
      partOfSpeech: 'verbo',
      meaning: 'Aprender. Descubrir ideas y habilidades nuevas que nos hacen crecer.',
    ),
    'read': WordDefinition(
      word: 'read',
      displayWord: 'Read',
      partOfSpeech: 'verbo',
      meaning: 'Leer. Recorrer con los ojos las palabras escritas para imaginar una historia.',
    ),
    'write': WordDefinition(
      word: 'write',
      displayWord: 'Write',
      partOfSpeech: 'verbo',
      meaning: 'Escribir. Trazar letras y palabras para expresar lo que pensamos y sentimos.',
    ),
    'sing': WordDefinition(
      word: 'sing',
      displayWord: 'Sing',
      partOfSpeech: 'verbo',
      meaning: 'Cantar. Entonar canciones bonitas con nuestra voz.',
    ),
    'dance': WordDefinition(
      word: 'dance',
      displayWord: 'Dance',
      partOfSpeech: 'verbo',
      meaning: 'Bailar. Mover el cuerpo al compás de la música con ritmo y alegría.',
    ),
    'happy': WordDefinition(
      word: 'happy',
      displayWord: 'Happy',
      partOfSpeech: 'adjetivo',
      meaning: 'Feliz o alegre. Sentimiento de dicha, sonrisa y bienestar en el corazón.',
    ),
    'good': WordDefinition(
      word: 'good',
      displayWord: 'Good',
      partOfSpeech: 'adjetivo',
      meaning: 'Bueno o bien. Que hace el bien, agrada y ayuda a los demás.',
    ),
    'big': WordDefinition(
      word: 'big',
      displayWord: 'Big',
      partOfSpeech: 'adjetivo',
      meaning: 'Grande. De tamaño mayor o de gran importancia.',
    ),
    'little': WordDefinition(
      word: 'little',
      displayWord: 'Little',
      partOfSpeech: 'adjetivo',
      meaning: 'Pequeño o chiquito. De tamaño tierno y reducido.',
    ),
  };
}
