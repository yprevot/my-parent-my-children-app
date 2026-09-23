import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:images_to_book/core/storage/app_database.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  test('updateBookLanguages persiste y actualiza idiomas correctamente en la base de datos', () async {
    final now = DateTime.now();
    const bookId = 'book_lang_test_1';
    await db.into(db.books).insert(
          BooksCompanion.insert(
            id: bookId,
            title: 'Libro bilingüe',
            homeLocale: const Value('es-MX'),
            learningLocale: const Value('en-US'),
            createdAt: now,
            updatedAt: now,
          ),
        );

    var book = await db.findBook(bookId);
    expect(book, isNotNull);
    expect(book!.homeLocale, 'es-MX');
    expect(book.learningLocale, 'en-US');

    // Cambiamos idioma de lectura a español y lengua nativa a inglés
    await db.updateBookLanguages(
      bookId,
      homeLocale: 'en-US',
      learningLocale: 'es-MX',
    );

    book = await db.findBook(bookId);
    expect(book, isNotNull);
    expect(book!.homeLocale, 'en-US');
    expect(book.learningLocale, 'es-MX');

    // Cambiamos a inglés de Reino Unido
    await db.updateBookLanguages(
      bookId,
      homeLocale: 'es-ES',
      learningLocale: 'en-GB',
    );

    book = await db.findBook(bookId);
    expect(book, isNotNull);
    expect(book!.homeLocale, 'es-ES');
    expect(book.learningLocale, 'en-GB');
  });

  test('updateReadingPreferences actualiza velocidad de voz y selección de voz', () async {
    final now = DateTime.now();
    const bookId = 'book_voice_test';
    await db.into(db.books).insert(
          BooksCompanion.insert(
            id: bookId,
            title: 'Libro con voz configurada',
            homeLocale: const Value('es-MX'),
            learningLocale: const Value('en-US'),
            createdAt: now,
            updatedAt: now,
          ),
        );

    await db.updateReadingPreferences(
      bookId,
      speechRate: 0.65,
      voiceId: 'com.google.android.tts:en-us-x-sfg#female_1',
    );

    final book = await db.findBook(bookId);
    expect(book, isNotNull);
    expect(book!.speechRate, closeTo(0.65, 0.001));
    expect(book.voiceId, 'com.google.android.tts:en-us-x-sfg#female_1');
  });
}
