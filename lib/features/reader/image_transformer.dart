import 'dart:io';
import 'dart:isolate';

import 'package:image/image.dart' as img;

class ImageTransformOptions {
  const ImageTransformOptions({this.quarterTurns = 0, this.cropFactor = 1});

  final int quarterTurns;
  final double cropFactor;
}

/// Normaliza una foto antes del OCR en un Isolate secundario para no congelar
/// la interfaz. Guarda como JPEG optimizado para reducir uso de RAM y disco.
Future<String> transformImage(
  String source,
  ImageTransformOptions options,
) async {
  if (options.quarterTurns == 0 && options.cropFactor >= .999) return source;
  final file = File(source);
  if (!await file.exists() || await file.length() == 0) return source;
  final bytes = await file.readAsBytes();
  final target = '$source.adjusted.jpg';

  try {
    final processedBytes = await Isolate.run(() {
      final decoded = img.decodeImage(bytes);
      if (decoded == null) {
        return null;
      }
      var output = decoded;
      if (options.cropFactor < .999) {
        final width = (decoded.width * options.cropFactor).round();
        final height = (decoded.height * options.cropFactor).round();
        output = img.copyCrop(
          decoded,
          x: ((decoded.width - width) / 2).round(),
          y: ((decoded.height - height) / 2).round(),
          width: width,
          height: height,
        );
      }
      for (var i = 0; i < options.quarterTurns.abs(); i++) {
        output = img.copyRotate(
          output,
          angle: options.quarterTurns > 0 ? 90 : -90,
        );
      }
      return img.encodeJpg(output, quality: 85);
    });

    if (processedBytes != null) {
      await File(target).writeAsBytes(processedBytes, flush: true);
      return target;
    }
  } catch (_) {
    // Fallback to source on decode / memory exception
    return source;
  }
  return source;
}
