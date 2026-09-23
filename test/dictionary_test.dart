import 'package:flutter_test/flutter_test.dart';
import 'package:images_to_book/core/dictionary/dictionary_service.dart';

void main() {
  group('DictionaryService', () {
    final dict = DictionaryService.instance;

    test('Normaliza palabras con puntuación y mayúsculas', () {
      expect(DictionaryService.normalize('Cat,'), 'cat');
      expect(DictionaryService.normalize('"Learning."'), 'learning');
      expect(DictionaryService.normalize('  Tree! '), 'tree');
      expect(DictionaryService.normalize('¿amigo?'), 'amigo');
    });

    test('Obtiene definición directa de palabras comunes', () async {
      final cat = await dict.lookup('cat');
      expect(cat.word, 'cat');
      expect(cat.meaning, contains('Gato'));
      expect(cat.partOfSpeech, 'sustantivo');

      final play = await dict.lookup('play');
      expect(play.meaning, contains('Jugar'));

      final tree = await dict.lookup('tree');
      expect(tree.meaning, contains('Árbol'));
    });

    test('Resuelve formas flexionadas como plurales y gerundios', () async {
      final cats = await dict.lookup('cats');
      expect(cats.meaning, contains('Gato'));

      final playing = await dict.lookup('playing');
      expect(playing.meaning, contains('Jugar'));

      final trees = await dict.lookup('trees');
      expect(trees.meaning, contains('Árbol'));
    });

    test('Provee fallback didáctico seguro para palabras desconocidas en modo offline', () async {
      final unknown = await dict.lookup('xylophone123');
      expect(unknown.meaning, contains('Palabra en en-US'));
      expect(unknown.displayWord, 'Xylophone123');
    });

    test('Obtiene definición en español para palabras de cuentos y lecturas', () async {
      final bosque = await dict.lookup('bosque', homeLocale: 'es-MX', learningLocale: 'es-MX');
      expect(bosque.word, 'bosque');
      expect(bosque.meaning, contains('árboles'));
      expect(bosque.partOfSpeech, 'sustantivo');

      final habia = await dict.lookup('había', homeLocale: 'es-MX', learningLocale: 'es-MX');
      expect(habia.meaning, contains('haber'));

      final escuela = await dict.lookup('escuela', homeLocale: 'es-MX', learningLocale: 'es-MX');
      expect(escuela.meaning, contains('estudiar'));
    });

    test('Resuelve plurales, diminutivos y acentos en español', () async {
      final arboles = await dict.lookup('árboles', homeLocale: 'es-MX', learningLocale: 'es-MX');
      expect(arboles.word, 'árboles');
      expect(arboles.meaning, contains('tronco'));

      final gatitos = await dict.lookup('gatitos', homeLocale: 'es-MX', learningLocale: 'es-MX');
      expect(gatitos.word, 'gatitos');
      expect(gatitos.meaning, contains('maúlla'));

      final flores = await dict.lookup('flores', homeLocale: 'es-MX', learningLocale: 'es-MX');
      expect(flores.word, 'flores');
      expect(flores.meaning, contains('plantas'));

      final arbolSinTilde = await dict.lookup('arbol', homeLocale: 'es-MX', learningLocale: 'es-MX');
      expect(arbolSinTilde.word, 'arbol');
      expect(arbolSinTilde.meaning, contains('tronco'));
    });
  });
}
