import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:images_to_book/spike/ocr_probe.dart';
import 'package:images_to_book/spike/speech_probe.dart';
import 'package:images_to_book/spike/text_ranges.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('OCR nativo y TTS real: texto completo, párrafo y palabra', (
    tester,
  ) async {
    final ocr = OcrProbe();
    final speech = SpeechProbe();
    try {
      final result = await ocr.sample();
      final normalized = result.rawText.replaceAll(RegExp(r'\s+'), ' ').trim();
      expect(
        normalized,
        'The cat is small. It likes to play. We read a book together. Learning is an adventure.',
      );
      expect(result.paragraphs, hasLength(2));
      expect(await File(result.path).exists(), isTrue);
      await speech.initialize();
      expect(
        speech.voice,
        isNotNull,
        reason:
            'Hace falta instalar una voz inglesa local en este dispositivo.',
      );
      await speech.play(result.paragraphs).timeout(const Duration(seconds: 45));
      expect(speech.state, ProbePlayback.completed);
      await speech
          .play([result.paragraphs.last])
          .timeout(const Duration(seconds: 30));
      expect(speech.state, ProbePlayback.completed);
      final range = wordAt(
        result.paragraphs.first,
        result.paragraphs.first.indexOf('cat'),
      )!;
      await speech
          .play([range.extract(result.paragraphs.first)])
          .timeout(const Duration(seconds: 15));
      expect(speech.state, ProbePlayback.completed);
      // Solo registra datos del fixture propio, nunca texto de fotos familiares.
      // ignore: avoid_print
      print(
        'A00_NATIVE platform=${Platform.operatingSystem} ocr_ms=${result.elapsed.inMilliseconds} paragraphs=${result.paragraphs.length} voice=${speech.voice!.id} network=${speech.voice!.requiresNetwork} progress=${speech.progressEvents} scopes=3',
      );
    } finally {
      await speech.stop();
      speech.dispose();
      await ocr.close();
    }
  });
}
