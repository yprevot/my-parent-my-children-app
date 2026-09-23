import 'dart:convert';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:images_to_book/core/export/book_export_import_service.dart';
import 'package:images_to_book/core/storage/app_database.dart';

void main() {
  late AppDatabase db;
  final service = BookExportImportService.instance;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  group('BookExportImportService', () {
    test('Falla al exportar un libro inexistente o sin párrafos procesados', () async {
      expect(
        () => service.exportBookJson(database: db, bookId: 'non_existent'),
        throwsA(isA<EmptyReadingModeException>()),
      );

      final now = DateTime.now();
      const emptyBookId = 'empty_book_1';
      await db.into(db.books).insert(
            BooksCompanion.insert(
              id: emptyBookId,
              title: 'Libro Vacío',
              createdAt: now,
              updatedAt: now,
            ),
          );

      expect(
        () => service.exportBookJson(database: db, bookId: emptyBookId),
        throwsA(isA<EmptyReadingModeException>()),
      );
    });

    test('Exporta libro con párrafos y páginas aprobadas al formato JSON estructurado', () async {
      final now = DateTime.now();
      const bookId = 'book_export_test';

      await db.into(db.books).insert(
            BooksCompanion.insert(
              id: bookId,
              title: 'El Principito',
              homeLocale: const Value('es-MX'),
              learningLocale: const Value('es-MX'),
              speechRate: const Value(0.5),
              createdAt: now,
              updatedAt: now,
            ),
          );

      await db.into(db.pages).insert(
            PagesCompanion.insert(
              id: 'page_1',
              bookId: bookId,
              orderKey: 0,
              status: const Value('approved'),
              createdAt: now,
            ),
          );

      await db.into(db.paragraphs).insert(
            ParagraphsCompanion.insert(
              id: 'p_1',
              bookId: bookId,
              pageId: 'page_1',
              orderKey: 0,
              content: 'Pido perdón a los niños por haber dedicado este libro a una persona grande.',
            ),
          );

      await db.into(db.paragraphs).insert(
            ParagraphsCompanion.insert(
              id: 'p_2',
              bookId: bookId,
              pageId: 'page_1',
              orderKey: 1,
              content: 'Tengo una seria razón para ello: esta persona grande es el mejor amigo que tengo en el mundo.',
            ),
          );

      final jsonStr = await service.exportBookJson(database: db, bookId: bookId);
      expect(jsonStr, isNotEmpty);

      final decoded = jsonDecode(jsonStr) as Map<String, dynamic>;
      expect(decoded['format'], 'myschool_reading_mode');
      expect(decoded['version'], 1);
      expect(decoded['generator'], 'MySchoolMyParents Online');

      final bookMeta = decoded['book'] as Map<String, dynamic>;
      expect(bookMeta['title'], 'El Principito');
      expect(bookMeta['learningLocale'], 'es-MX');
      expect(bookMeta['homeLocale'], 'es-MX');
      expect(bookMeta['totalParagraphs'], 2);
      expect(bookMeta['totalPages'], 1);

      final paragraphs = decoded['paragraphs'] as List;
      expect(paragraphs.length, 2);
      expect(paragraphs.first['content'], contains('Pido perdón'));
      expect(paragraphs.last['content'], contains('mejor amigo'));
    });

    test('Importa libro desde JSON y lo deja listo en Modo Lectura en la BD', () async {
      const sampleExport = '''
{
  "format": "myschool_reading_mode",
  "version": 1,
  "generator": "MySchoolMyParents Online",
  "book": {
    "title": "Don Quijote para Niños",
    "learningLocale": "es-ES",
    "homeLocale": "es-MX",
    "speechRate": 0.48
  },
  "pages": [
    {
      "id": "page_orig_1",
      "orderKey": 0
    }
  ],
  "paragraphs": [
    {
      "pageId": "page_orig_1",
      "orderKey": 0,
      "content": "En un lugar de la Mancha, de cuyo nombre no quiero acordarme..."
    },
    {
      "pageId": "page_orig_1",
      "orderKey": 1,
      "content": "No ha mucho tiempo que vivía un hidalgo de los de lanza en astillero."
    }
  ]
}
''';

      final importedBook = await service.importBookFromJson(
        database: db,
        jsonContent: sampleExport,
      );

      expect(importedBook.title, 'Don Quijote para Niños');
      expect(importedBook.learningLocale, 'es-ES');
      expect(importedBook.homeLocale, 'es-MX');

      // Verificar que los párrafos se guardaron y están aprobados
      final paragraphs = await db.getBookParagraphs(importedBook.id);
      expect(paragraphs.length, 2);
      expect(paragraphs[0].content, contains('En un lugar de la Mancha'));
      expect(paragraphs[1].content, contains('hidalgo'));
      expect(paragraphs[0].orderKey, 0);
      expect(paragraphs[1].orderKey, 1);

      // Verificar que las páginas fueron creadas y aprobadas
      final pages = await db.getApprovedPages(importedBook.id);
      expect(pages.length, 1);
      expect(pages.first.status, 'approved');
      expect(paragraphs[0].pageId, pages.first.id);
    });

    test('Soporta importación resiliente de listas de párrafos y textos planos', () async {
      const flatJson = '''
{
  "title": "Fábula de la Liebre",
  "learningLocale": "es-MX",
  "paragraphs": [
    "Había una vez una liebre muy vanidosa.",
    "Una tortuga la retó a una carrera."
  ]
}
''';

      final book = await service.importBookFromJson(
        database: db,
        jsonContent: flatJson,
      );

      expect(book.title, 'Fábula de la Liebre');
      final paragraphs = await db.getBookParagraphs(book.id);
      expect(paragraphs.length, 2);
      expect(paragraphs.first.content, 'Había una vez una liebre muy vanidosa.');
      expect(paragraphs.last.content, 'Una tortuga la retó a una carrera.');

      final pages = await db.getApprovedPages(book.id);
      expect(pages.length, 1);
      expect(pages.first.status, 'approved');
    });

    test('Rechaza JSON inválido o sin párrafos con error explicativo', () async {
      expect(
        () => service.importBookFromJson(
          database: db,
          jsonContent: 'esto no es un json',
        ),
        throwsA(isA<InvalidReadingModeFormatException>()),
      );

      expect(
        () => service.importBookFromJson(
          database: db,
          jsonContent: '{"title": "Libro sin texto", "paragraphs": []}',
        ),
        throwsA(isA<InvalidReadingModeFormatException>()),
      );
    });
  });
}
