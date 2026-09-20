import 'package:characters/characters.dart';

/// Offsets UTF-16, iguales a los usados por TextSelection de Flutter.
class TextRangeSlice {
  const TextRangeSlice(this.start, this.end);
  final int start;
  final int end;
  String extract(String text) => text.substring(start, end);
}

final _words = RegExp(
  r"[\p{L}\p{N}]+(?:['’\-‐‑][\p{L}\p{N}]+)*",
  unicode: true,
);

TextRangeSlice? wordAt(String text, int offset) {
  if (offset < 0 || offset >= text.length) return null;
  for (final match in _words.allMatches(text)) {
    if (match.start <= offset && offset < match.end) {
      return TextRangeSlice(match.start, match.end);
    }
  }
  return null;
}

/// Divide sin perder caracteres ni cortar grafemas. No reescribe el libro.
List<TextRangeSlice> splitForSpeech(String text, {int limit = 500}) {
  if (limit < 2) throw ArgumentError.value(limit, 'limit');
  final result = <TextRangeSlice>[];
  var start = 0;
  while (start < text.length) {
    var end = start;
    var wordBoundary = start;
    for (final character in text.substring(start).characters) {
      if (end + character.length - start > limit) break;
      end += character.length;
      if (RegExp(r'\s').hasMatch(character)) wordBoundary = end;
    }
    if (end == start) {
      throw StateError('Un grafema supera el límite del motor.');
    }
    if (end < text.length && wordBoundary > start) end = wordBoundary;
    result.add(TextRangeSlice(start, end));
    start = end;
  }
  return result;
}
