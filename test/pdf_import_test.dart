import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:images_to_book/spike/ocr_probe.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('online.myschoolmyparents/ocr');

  test('OcrProbeResult modela correctamente el resultado de página PDF', () {
    const result = OcrProbeResult(
      '/path/doc.pdf',
      'Párrafo uno\n\nPárrafo dos',
      ['Párrafo uno', 'Párrafo dos'],
      Duration(milliseconds: 150),
      imagePath: '/path/captures/page_0.png',
      engine: 'pdfkit-direct',
    );

    expect(result.path, '/path/doc.pdf');
    expect(result.rawText, contains('Párrafo uno'));
    expect(result.paragraphs.length, 2);
    expect(result.imagePath, '/path/captures/page_0.png');
    expect(result.engine, 'pdfkit-direct');
  });

  test('OcrProbe getPdfPageCount invoca el canal nativo y devuelve el conteo', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall call) async {
      if (call.method == 'getPdfPageCount') {
        expect(call.arguments['path'], '/path/sample.pdf');
        return 5;
      }
      return null;
    });

    final probe = OcrProbe();
    final count = await probe.getPdfPageCount('/path/sample.pdf');
    expect(count, 5);
  });

  test('OcrProbe processPdfPage invoca el canal nativo y parsea párrafos y ruta de imagen', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall call) async {
      if (call.method == 'processPdfPage') {
        expect(call.arguments['path'], '/path/sample.pdf');
        expect(call.arguments['page'], 2);
        expect(call.arguments['targetPath'], '/target/page_2.png');
        return {
          'rawText': 'Texto del PDF en página 3',
          'paragraphs': ['Texto del PDF en página 3'],
          'imagePath': '/target/page_2.png',
          'engine': 'mlkit-latin-16.0.1',
        };
      }
      return null;
    });

    final probe = OcrProbe();
    final result = await probe.processPdfPage(
      path: '/path/sample.pdf',
      page: 2,
      targetPath: '/target/page_2.png',
    );

    expect(result.rawText, 'Texto del PDF en página 3');
    expect(result.paragraphs, ['Texto del PDF en página 3']);
    expect(result.imagePath, '/target/page_2.png');
    expect(result.engine, 'mlkit-latin-16.0.1');
  });
}
