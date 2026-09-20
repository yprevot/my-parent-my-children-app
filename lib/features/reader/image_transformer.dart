import 'dart:io';

import 'package:image/image.dart' as img;

class ImageTransformOptions {
  const ImageTransformOptions({this.quarterTurns = 0, this.cropFactor = 1});

  final int quarterTurns;
  final double cropFactor;
}

/// Normaliza una foto antes del OCR. El recorte se mantiene centrado para que
/// el adulto pueda quitar bordes o fondos sin alterar el texto principal.
Future<String> transformImage(
  String source,
  ImageTransformOptions options,
) async {
  if (options.quarterTurns == 0 && options.cropFactor >= .999) return source;
  final bytes = await File(source).readAsBytes();
  final decoded = img.decodeImage(bytes);
  if (decoded == null) {
    throw StateError('No se pudo leer la imagen para ajustarla.');
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
    output = img.copyRotate(output, angle: options.quarterTurns > 0 ? 90 : -90);
  }
  final target = '$source.adjusted.png';
  await File(target).writeAsBytes(img.encodePng(output));
  return target;
}
