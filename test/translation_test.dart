import 'package:flutter_test/flutter_test.dart';
import 'package:images_to_book/core/dictionary/dictionary_service.dart';
import 'package:images_to_book/core/translation/translation_service.dart';

void main() {
  group('TranslationService', () {
    final translation = TranslationService.instance;

    test('Normaliza códigos de idioma correctamente', () {
      expect(TranslationService.normalizeLanguageCode('es-MX'), 'es');
      expect(TranslationService.normalizeLanguageCode('en-US'), 'en');
      expect(TranslationService.normalizeLanguageCode('es_ES'), 'es');
      expect(TranslationService.normalizeLanguageCode('FR-CA'), 'fr');
      expect(TranslationService.normalizeLanguageCode('de'), 'de');
    });

    test('Obtiene nombres de idioma amigables', () {
      expect(TranslationService.getLanguageName('es'), 'Español');
      expect(TranslationService.getLanguageName('en-US'), 'Inglés');
      expect(TranslationService.getLanguageName('fr'), 'Francés');
      expect(TranslationService.getLanguageName('de'), 'Alemán');
    });

    test('Resuelve idioma complementario cuando origen y destino coinciden', () {
      expect(
        TranslationService.resolveTargetLanguage(fromLocale: 'es-MX', toLocale: 'es-MX'),
        'en',
      );
      expect(
        TranslationService.resolveTargetLanguage(fromLocale: 'en-US', toLocale: 'en-US'),
        'es',
      );
      expect(
        TranslationService.resolveTargetLanguage(fromLocale: 'en-US', toLocale: 'es-MX'),
        'es',
      );
    });

    test('Traduce palabras en modo offline inglés -> español', () async {
      final cat = await translation.translateWord('cat', fromLocale: 'en', toLocale: 'es');
      expect(cat, isNotNull);
      expect(cat!.toLowerCase(), 'gato');

      final tree = await translation.translateWord('tree', fromLocale: 'en', toLocale: 'es');
      expect(tree, isNotNull);
      expect(tree!.toLowerCase(), 'árbol');

      final school = await translation.translateWord('School', fromLocale: 'en', toLocale: 'es');
      expect(school, isNotNull);
      expect(school!.toLowerCase(), 'escuela');

      final forest = await translation.translateWord('forest', fromLocale: 'en', toLocale: 'es');
      expect(forest, isNotNull);
      expect(forest!.toLowerCase(), 'bosque');
    });

    test('Traduce formas flexionadas en inglés en modo offline', () async {
      final cats = await translation.translateWord('cats', fromLocale: 'en', toLocale: 'es');
      expect(cats, isNotNull);
      expect(cats!.toLowerCase(), anyOf('gatos', 'gato'));
    });

    test('Traduce palabras en modo offline español -> inglés', () async {
      final bosque = await translation.translateWord('bosque', fromLocale: 'es', toLocale: 'en');
      expect(bosque, isNotNull);
      expect(bosque!.toLowerCase(), 'forest');

      final casa = await translation.translateWord('casa', fromLocale: 'es', toLocale: 'en');
      expect(casa, isNotNull);
      expect(casa!.toLowerCase(), 'house');

      final escuela = await translation.translateWord('escuela', fromLocale: 'es', toLocale: 'en');
      expect(escuela, isNotNull);
      expect(escuela!.toLowerCase(), 'school');

      final arbol = await translation.translateWord('árbol', fromLocale: 'es', toLocale: 'en');
      expect(arbol, isNotNull);
      expect(arbol!.toLowerCase(), 'tree');
    });

    test('Traduce diminutivos y plurales en español en modo offline', () async {
      final gatitos = await translation.translateWord('gatitos', fromLocale: 'es', toLocale: 'en');
      expect(gatitos, isNotNull);
      expect(gatitos!.toLowerCase(), 'kittens');

      final flores = await translation.translateWord('flores', fromLocale: 'es', toLocale: 'en');
      expect(flores, isNotNull);
      expect(flores!.toLowerCase(), 'flowers');
    });
  });

  group('DictionaryService Translation Integration', () {
    final dict = DictionaryService.instance;

    test('Enriquece definición en inglés con traducción al español', () async {
      final def = await dict.lookup('cat', learningLocale: 'en-US', homeLocale: 'es-MX');
      expect(def.word, 'cat');
      expect(def.meaning, isNotEmpty);
      expect(def.translation, isNotNull);
      expect(def.translation!.toLowerCase(), 'gato');
      expect(def.translationLocale, 'es');
    });

    test('Enriquece definición en español con traducción al inglés', () async {
      final def = await dict.lookup('bosque', learningLocale: 'es-MX', homeLocale: 'es-MX');
      expect(def.word, 'bosque');
      expect(def.meaning, isNotEmpty);
      expect(def.translation, isNotNull);
      expect(def.translation!.toLowerCase(), 'forest');
      expect(def.translationLocale, 'en');
    });

    test('Serializa y deserializa WordDefinition preservando campos de traducción', () {
      const original = WordDefinition(
        word: 'sun',
        displayWord: 'Sun',
        partOfSpeech: 'sustantivo',
        meaning: 'Estrella luminosa que da luz y calor a la Tierra.',
        example: 'The sun shines brightly.',
        translation: 'Sol',
        translationLocale: 'es',
      );

      final json = original.toJson();
      expect(json['translation'], 'Sol');
      expect(json['translationLocale'], 'es');

      final restored = WordDefinition.fromJson(json);
      expect(restored.word, original.word);
      expect(restored.displayWord, original.displayWord);
      expect(restored.translation, 'Sol');
      expect(restored.translationLocale, 'es');
      expect(restored.example, original.example);
    });
  });
}
