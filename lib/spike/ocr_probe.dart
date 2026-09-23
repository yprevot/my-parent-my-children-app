import 'dart:io';

import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

class OcrProbeResult {
  const OcrProbeResult(
    this.path,
    this.rawText,
    this.paragraphs,
    this.elapsed, {
    this.imagePath,
    this.engine,
  });
  final String path;
  final String rawText;
  final List<String> paragraphs;
  final Duration elapsed;
  final String? imagePath;
  final String? engine;
}

/// Integración nativa real; el repositorio editorial se construye tras G0.
class OcrProbe {
  static const _channel = MethodChannel('online.myschoolmyparents/ocr');

  Future<String> persist(String source) async {
    final directory = await getApplicationSupportDirectory();
    final captures = Directory('${directory.path}/a00-captures');
    await captures.create(recursive: true);
    var extension = source
        .split('.')
        .last
        .replaceAll(RegExp(r'[^a-zA-Z0-9]'), '')
        .toLowerCase();
    if (extension.isEmpty || extension.length > 5) {
      extension = 'jpg';
    }
    final target =
        '${captures.path}/${DateTime.now().microsecondsSinceEpoch}.$extension';
    try {
      final xFile = XFile(source);
      final bytes = await xFile.readAsBytes();
      final targetFile = File(target);
      await targetFile.writeAsBytes(bytes, flush: true);
    } catch (_) {
      final file = File(source);
      await file.copy(target);
    }
    return target;
  }

  Future<OcrProbeResult> recognize(String path) async {
    final file = File(path);
    if (!await file.exists() || await file.length() == 0) {
      throw StateError('El archivo para OCR no existe o está vacío: $path');
    }
    final stopwatch = Stopwatch()..start();
    final result = await _channel.invokeMapMethod<String, dynamic>('recognize', {'path': path});
    stopwatch.stop();
    if (result == null) throw StateError('El OCR no devolvió un resultado.');
    return OcrProbeResult(path, result['rawText'] as String,
      List<String>.from(result['paragraphs'] as List), stopwatch.elapsed);
  }

  Future<int> getPdfPageCount(String path) async {
    final result = await _channel.invokeMethod<int>('getPdfPageCount', {'path': path});
    if (result == null || result <= 0) {
      throw StateError('No se pudo determinar el número de páginas del PDF.');
    }
    return result;
  }

  Future<OcrProbeResult> processPdfPage({
    required String path,
    required int page,
    String? targetPath,
  }) async {
    final stopwatch = Stopwatch()..start();
    final result = await _channel.invokeMapMethod<String, dynamic>(
      'processPdfPage',
      {
        'path': path,
        'page': page,
        'targetPath': ?targetPath,
      },
    );
    stopwatch.stop();
    if (result == null) {
      throw StateError('No se pudo procesar la página $page del PDF.');
    }
    final rawText = (result['rawText'] as String?) ?? '';
    final paragraphsList = result['paragraphs'] is List
        ? List<String>.from(result['paragraphs'] as List)
        : <String>[];
    final imagePath = result['imagePath'] as String? ?? targetPath;
    final engine = result['engine'] as String?;
    return OcrProbeResult(
      path,
      rawText,
      paragraphsList,
      stopwatch.elapsed,
      imagePath: imagePath,
      engine: engine,
    );
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
