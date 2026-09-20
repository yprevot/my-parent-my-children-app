import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

class OcrProbeResult {
  const OcrProbeResult(this.path, this.rawText, this.paragraphs, this.elapsed);
  final String path;
  final String rawText;
  final List<String> paragraphs;
  final Duration elapsed;
}

/// Integración nativa real; el repositorio editorial se construye tras G0.
class OcrProbe {
  static const _channel = MethodChannel('images_to_book/ocr');

  Future<String> persist(String source) async {
    final directory = await getApplicationSupportDirectory();
    final captures = Directory('${directory.path}/a00-captures');
    await captures.create(recursive: true);
    final extension = source
        .split('.')
        .last
        .replaceAll(RegExp(r'[^a-zA-Z0-9]'), '');
    final target =
        '${captures.path}/${DateTime.now().microsecondsSinceEpoch}.$extension';
    await File(source).copy('$target.part');
    await File('$target.part').rename(target);
    return target;
  }

  Future<OcrProbeResult> recognize(String path) async {
    final stopwatch = Stopwatch()..start();
    final result = await _channel.invokeMapMethod<String, dynamic>('recognize', {'path': path});
    stopwatch.stop();
    if (result == null) throw StateError('El OCR no devolvió un resultado.');
    return OcrProbeResult(path, result['rawText'] as String,
      List<String>.from(result['paragraphs'] as List), stopwatch.elapsed);
  }

  Future<OcrProbeResult> sample() async {
    final data = await rootBundle.load('test_assets/learning_page.png');
    final temporary = await getTemporaryDirectory();
    final file = File('${temporary.path}/a00-learning-page.png');
    await file.writeAsBytes(
      data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
    );
    return recognize(await persist(file.path));
  }

  Future<void> close() async {}
}
