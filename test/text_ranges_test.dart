import 'package:characters/characters.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:images_to_book/spike/text_ranges.dart';

void main() {
  test('Palabras y contracciones se identifican por offset UTF-16', () {
    const text = "😀 don't don’t mother-in-law the the niño.";
    for (final word in ["don't", 'don’t', 'mother-in-law', 'niño']) {
      final offset = text.indexOf(word);
      expect(wordAt(text, offset + 1)?.extract(text), word);
    }
    final second = text.lastIndexOf('the');
    expect(wordAt(text, second)?.start, second);
    expect(wordAt(text, 0), isNull);
    expect(wordAt(text, -1), isNull);
    expect(wordAt(text, text.length), isNull);
    expect(wordAt(text, text.length - 1), isNull);
  });
  test('Segmentos preservan texto, espacios, grafemas y límite', () {
    final text = List.filled(100, '¡Niño! 👩🏽‍🏫 a\u0301 the cat.\n').join();
    final chunks = splitForSpeech(text, limit: 31);
    expect(chunks.map((r) => r.extract(text)).join(), text);
    final boundaries = <int>{0};
    var position = 0;
    for (final char in text.characters) {
      position += char.length;
      boundaries.add(position);
    }
    for (final chunk in chunks) {
      expect(chunk.end - chunk.start, lessThanOrEqualTo(31));
      expect(
        boundaries.contains(chunk.start) && boundaries.contains(chunk.end),
        isTrue,
      );
    }
  });
  test('Texto vacío y límites no válidos', () {
    expect(splitForSpeech(''), isEmpty);
    expect(() => splitForSpeech('a', limit: 0), throwsArgumentError);
    expect(() => splitForSpeech('👩🏽‍🏫', limit: 2), throwsStateError);
  });
}
