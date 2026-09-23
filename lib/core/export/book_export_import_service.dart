import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../storage/app_database.dart';

const String kReadingModeFormatIdentifier = 'myschool_reading_mode';
const int kReadingModeCurrentVersion = 1;

class EmptyReadingModeException implements Exception {
  final String message;
  const EmptyReadingModeException(this.message);

  @override
  String toString() => message;
}

class InvalidReadingModeFormatException implements Exception {
  final String message;
  const InvalidReadingModeFormatException(this.message);

  @override
  String toString() => message;
}

class BookExportResult {
  final bool success;
  final String? filePath;
  final String fileName;
  final int totalParagraphs;
  final int totalPages;
  final String? errorMessage;

  const BookExportResult({
    required this.success,
    this.filePath,
    required this.fileName,
    required this.totalParagraphs,
    required this.totalPages,
    this.errorMessage,
  });
}

class BookImportResult {
  final bool success;
  final Book? book;
  final int totalParagraphs;
  final int totalPages;
  final String? errorMessage;

  const BookImportResult({
    required this.success,
    this.book,
    this.totalParagraphs = 0,
    this.totalPages = 0,
    this.errorMessage,
  });
}

class BookExportImportService {
  BookExportImportService._();
  static final BookExportImportService instance = BookExportImportService._();

  /// Exporta el libro y sus párrafos procesados de Modo Lectura a una cadena JSON estructurada.
  Future<String> exportBookJson({
    required AppDatabase database,
    required String bookId,
  }) async {
    final book = await database.findBook(bookId);
    if (book == null) {
      throw const EmptyReadingModeException('El libro especificado no existe.');
    }

    final paragraphs = await database.getBookParagraphs(bookId);
    if (paragraphs.isEmpty) {
      throw const EmptyReadingModeException(
        'El libro aún no contiene párrafos procesados en Modo Lectura para exportar. '
        'Asegúrate de haber aprobado al menos una página o importado texto.',
      );
    }

    final pages = await database.getApprovedPages(bookId);

    // Mapeo y serialización de páginas con imagen embebida opcional (en Base64)
    final exportedPages = <Map<String, dynamic>>[];
    for (final page in pages) {
      String? imageBase64;
      final imagePath = page.derivedPath ?? page.originalPath;
      if (imagePath != null && imagePath.isNotEmpty) {
        try {
          final file = File(imagePath);
          if (await file.exists()) {
            final length = await file.length();
            // Límite de 2.5 MB por imagen para mantener el JSON ágil
            if (length <= 2500000) {
              final bytes = await file.readAsBytes();
              imageBase64 = base64Encode(bytes);
            }
          }
        } catch (_) {}
      }

      exportedPages.add({
        'id': page.id,
        'orderKey': page.orderKey,
        'image': ?imageBase64,
      });
    }

    final totalWords = paragraphs.fold<int>(
      0,
      (sum, p) => sum + p.content.trim().split(RegExp(r'\s+')).length,
    );

    final payload = {
      'format': kReadingModeFormatIdentifier,
      'version': kReadingModeCurrentVersion,
      'exportedAt': DateTime.now().toUtc().toIso8601String(),
      'generator': 'MySchoolMyParents Online',
      'book': {
        'title': book.title,
        'learningLocale': book.learningLocale,
        'homeLocale': book.homeLocale,
        'speechRate': book.speechRate,
        'voiceId': book.voiceId,
        'totalWords': totalWords,
        'totalParagraphs': paragraphs.length,
        'totalPages': exportedPages.isNotEmpty ? exportedPages.length : 1,
      },
      'pages': exportedPages,
      'paragraphs': [
        for (final p in paragraphs)
          {
            'pageId': p.pageId,
            'orderKey': p.orderKey,
            'content': p.content,
            'localeOverride': ?p.localeOverride,
          },
      ],
    };

    return const JsonEncoder.withIndent('  ').convert(payload);
  }

  /// Exporta el libro y lo guarda en el sistema de archivos del usuario.
  Future<BookExportResult> exportBookToFile({
    required AppDatabase database,
    required String bookId,
    String? preferredDirectory,
  }) async {
    try {
      final book = await database.findBook(bookId);
      if (book == null) {
        return const BookExportResult(
          success: false,
          fileName: '',
          totalParagraphs: 0,
          totalPages: 0,
          errorMessage: 'El libro no existe.',
        );
      }

      final jsonContent = await exportBookJson(
        database: database,
        bookId: bookId,
      );

      final sanitizedTitle = book.title
          .trim()
          .toLowerCase()
          .replaceAll(RegExp(r'[^\w\sá-úñÁ-ÚÑ]+'), '')
          .replaceAll(RegExp(r'\s+'), '_');

      final safeName = sanitizedTitle.isEmpty ? 'libro' : sanitizedTitle;
      final fileName = '${safeName}_lectura.msmp.json';
      final bytes = Uint8List.fromList(utf8.encode(jsonContent));

      String? targetPath;

      // 1. Intento con FilePicker.saveFile si la plataforma lo soporta
      try {
        final uri = await FilePicker.saveFile(
          dialogTitle: 'Exportar libro en Modo Lectura',
          fileName: fileName,
          bytes: bytes,
        );
        if (uri != null) {
          targetPath = uri.toFilePath();
        }
      } catch (e) {
        debugPrint('FilePicker.saveFile no soportado o falló: $e');
      }

      // 2. Respaldo directo en directorio de documentos / descargas de la app
      if (targetPath == null || targetPath.isEmpty) {
        final dir = preferredDirectory != null
            ? Directory(preferredDirectory)
            : await _getExportDirectory();

        if (!await dir.exists()) {
          await dir.create(recursive: true);
        }

        final file = File(p.join(dir.path, fileName));
        await file.writeAsBytes(bytes, flush: true);
        targetPath = file.path;
      }

      final paragraphs = await database.getBookParagraphs(bookId);
      final pages = await database.getApprovedPages(bookId);

      return BookExportResult(
        success: true,
        filePath: targetPath,
        fileName: fileName,
        totalParagraphs: paragraphs.length,
        totalPages: pages.isNotEmpty ? pages.length : 1,
      );
    } on EmptyReadingModeException catch (e) {
      return BookExportResult(
        success: false,
        fileName: '',
        totalParagraphs: 0,
        totalPages: 0,
        errorMessage: e.message,
      );
    } catch (e) {
      return BookExportResult(
        success: false,
        fileName: '',
        totalParagraphs: 0,
        totalPages: 0,
        errorMessage: 'Error al exportar libro: $e',
      );
    }
  }

  /// Parsea e importa un libro desde una cadena JSON a la base de datos local.
  Future<Book> importBookFromJson({
    required AppDatabase database,
    required String jsonContent,
    String? titleOverride,
  }) async {
    final dynamic decoded;
    try {
      decoded = jsonDecode(jsonContent);
    } catch (e) {
      throw const InvalidReadingModeFormatException(
        'El archivo no contiene un JSON válido.',
      );
    }

    if (decoded is! Map<String, dynamic>) {
      throw const InvalidReadingModeFormatException(
        'El archivo JSON no tiene la estructura de objeto esperada.',
      );
    }

    // Extracción de datos del libro
    final bookData = decoded['book'] as Map<String, dynamic>? ?? decoded;
    final title = (titleOverride ?? bookData['title'] as String? ?? 'Libro Importado').trim();
    final learningLocale = (bookData['learningLocale'] as String? ?? 'en-US').trim();
    final homeLocale = (bookData['homeLocale'] as String? ?? 'es-MX').trim();
    final speechRate = (bookData['speechRate'] as num?)?.toDouble() ?? 0.45;
    final voiceId = bookData['voiceId'] as String?;

    // Extracción de párrafos con tolerancia a diferentes variantes de formato
    final rawParagraphs = decoded['paragraphs'];
    final parsedParagraphs = <({String? pageId, int orderKey, String content, String? localeOverride})>[];

    if (rawParagraphs is List) {
      for (var i = 0; i < rawParagraphs.length; i++) {
        final item = rawParagraphs[i];
        if (item is String) {
          if (item.trim().isNotEmpty) {
            parsedParagraphs.add((
              pageId: null,
              orderKey: i,
              content: item.trim(),
              localeOverride: null,
            ));
          }
        } else if (item is Map) {
          final text = (item['content'] ?? item['text'] ?? '').toString().trim();
          if (text.isNotEmpty) {
            parsedParagraphs.add((
              pageId: item['pageId']?.toString(),
              orderKey: (item['orderKey'] as num?)?.toInt() ?? i,
              content: text,
              localeOverride: item['localeOverride']?.toString(),
            ));
          }
        }
      }
    } else if (decoded['content'] is String || decoded['text'] is String) {
      // Compatibilidad con texto plano embebido
      final plain = (decoded['content'] ?? decoded['text'] ?? '').toString();
      final lines = plain.split(RegExp(r'\n+'));
      for (var i = 0; i < lines.length; i++) {
        final line = lines[i].trim();
        if (line.isNotEmpty) {
          parsedParagraphs.add((
            pageId: null,
            orderKey: i,
            content: line,
            localeOverride: null,
          ));
        }
      }
    }

    if (parsedParagraphs.isEmpty) {
      throw const InvalidReadingModeFormatException(
        'El archivo no contiene párrafos legibles para el Modo Lectura.',
      );
    }

    // Directorio para guardar imágenes importadas
    Directory? imageDir;
    try {
      final docDir = await getApplicationDocumentsDirectory();
      imageDir = Directory(p.join(docDir.path, 'imported_reading_images'));
      if (!await imageDir.exists()) {
        await imageDir.create(recursive: true);
      }
    } catch (_) {}

    // Extracción y mapeo de páginas
    final rawPages = decoded['pages'];
    final pagesData = <ImportedPageData>[];

    if (rawPages is List && rawPages.isNotEmpty) {
      for (var i = 0; i < rawPages.length; i++) {
        final pageItem = rawPages[i];
        if (pageItem is Map) {
          final pageId = pageItem['id']?.toString() ?? 'page_$i';
          final orderKey = (pageItem['orderKey'] as num?)?.toInt() ?? i;
          final imageBase64 = pageItem['image'] as String?;

          String? localImagePath;
          if (imageBase64 != null && imageBase64.isNotEmpty && imageDir != null) {
            try {
              final rawBytes = base64Decode(imageBase64);
              final imgFile = File(
                p.join(imageDir.path, 'imported_${DateTime.now().microsecondsSinceEpoch}_$i.jpg'),
              );
              await imgFile.writeAsBytes(rawBytes, flush: true);
              localImagePath = imgFile.path;
            } catch (_) {}
          }

          // Filtrar párrafos pertenecientes a esta página
          final pageParas = parsedParagraphs
              .where((p) => p.pageId == pageId)
              .map(
                (p) => ImportedParagraphData(
                  content: p.content,
                  localeOverride: p.localeOverride,
                ),
              )
              .toList();

          pagesData.add(
            ImportedPageData(
              orderKey: orderKey,
              originalId: pageId,
              imagePath: localImagePath,
              paragraphs: pageParas,
            ),
          );
        }
      }
    }

    // Si los párrafos no tenían pageId o no coincidían con páginas, agruparlos
    final unassigned = parsedParagraphs.where((p) {
      if (p.pageId == null) return true;
      return !pagesData.any((page) => page.originalId == p.pageId);
    }).toList();

    if (unassigned.isNotEmpty || pagesData.isEmpty) {
      if (pagesData.isEmpty) {
        pagesData.add(
          ImportedPageData(
            orderKey: 0,
            originalId: 'default_page',
            imagePath: null,
            paragraphs: unassigned
                .map((p) => ImportedParagraphData(content: p.content, localeOverride: p.localeOverride))
                .toList(),
          ),
        );
      } else {
        // Añadir los no asignados a la primera página
        pagesData.first.paragraphs.addAll(
          unassigned.map(
            (p) => ImportedParagraphData(content: p.content, localeOverride: p.localeOverride),
          ),
        );
      }
    }

    // Persistir atómicamente en la base de datos
    return await database.importProcessedBook(
      title: title,
      homeLocale: homeLocale,
      learningLocale: learningLocale,
      speechRate: speechRate,
      voiceId: voiceId,
      pagesData: pagesData,
    );
  }

  /// Abre el selector de archivos del dispositivo, lee el archivo seleccionado e importa el libro.
  Future<BookImportResult> importBookFromFile({
    required AppDatabase database,
    String? titleOverride,
  }) async {
    try {
      final picked = await FilePicker.pickFiles(
        dialogTitle: 'Seleccionar libro en Modo Lectura',
        type: FileType.custom,
        allowedExtensions: ['json', 'msmp'],
      );

      if (picked.isEmpty) {
        return const BookImportResult(
          success: false,
          errorMessage: 'No se seleccionó ningún archivo.',
        );
      }

      final file = picked.first;
      final jsonContent = await file.xFile.readAsString();

      final book = await importBookFromJson(
        database: database,
        jsonContent: jsonContent,
        titleOverride: titleOverride,
      );

      final paragraphs = await database.getBookParagraphs(book.id);
      final pages = await database.getApprovedPages(book.id);

      return BookImportResult(
        success: true,
        book: book,
        totalParagraphs: paragraphs.length,
        totalPages: pages.isNotEmpty ? pages.length : 1,
      );
    } on InvalidReadingModeFormatException catch (e) {
      return BookImportResult(
        success: false,
        errorMessage: e.message,
      );
    } catch (e) {
      return BookImportResult(
        success: false,
        errorMessage: 'Error al importar libro: $e',
      );
    }
  }

  Future<Directory> _getExportDirectory() async {
    try {
      final downloads = await getDownloadsDirectory();
      if (downloads != null) return downloads;
    } catch (_) {}

    try {
      final docs = await getApplicationDocumentsDirectory();
      return Directory(p.join(docs.path, 'LibrosExportados'));
    } catch (_) {
      return Directory.current;
    }
  }
}
