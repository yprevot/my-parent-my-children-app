import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:images_to_book/core/storage/app_database.dart';

void main() {
  late AppDatabase database;
  setUp(() => database = AppDatabase(NativeDatabase.memory()));
  tearDown(() => database.close());

  test('un libro conserva páginas y párrafos en una transacción', () async {
    final now = DateTime.now();
    await database
        .into(database.books)
        .insert(
          BooksCompanion.insert(
            id: 'book-a',
            title: 'Lecturas',
            createdAt: now,
            updatedAt: now,
          ),
        );
    await database.addPageWithParagraphs(
      bookId: 'book-a',
      pageId: 'page-a',
      imagePath: '/private/page.png',
      texts: const ['The cat is small.', 'It likes to play.'],
    );
    final draft = (await database.watchDrafts('book-a').first).single;
    await database.approveDraft(draft, const [
      'The cat is small.',
      'It likes to play.',
    ]);
    final paragraphs = await database.watchParagraphs('book-a').first;
    expect(paragraphs.map((paragraph) => paragraph.content), [
      'The cat is small.',
      'It likes to play.',
    ]);
    expect((await database.findBook('book-a'))?.title, 'Lecturas');
  });

  test('borrar un libro no afecta otro libro', () async {
    final now = DateTime.now();
    for (final id in ['book-a', 'book-b']) {
      await database
          .into(database.books)
          .insert(
            BooksCompanion.insert(
              id: id,
              title: id,
              createdAt: now,
              updatedAt: now,
            ),
          );
    }
    await database.addPageWithParagraphs(
      bookId: 'book-a',
      pageId: 'page-a',
      imagePath: null,
      texts: const ['A'],
    );
    await database.addPageWithParagraphs(
      bookId: 'book-b',
      pageId: 'page-b',
      imagePath: null,
      texts: const ['B'],
    );
    await database.approveDraft(
      (await database.watchDrafts('book-a').first).single,
      const ['A'],
    );
    await database.approveDraft(
      (await database.watchDrafts('book-b').first).single,
      const ['B'],
    );
    await database.deleteBook('book-a');
    expect(await database.findBook('book-a'), isNull);
    expect(
      (await database.watchParagraphs('book-b').first).single.content,
      'B',
    );
  });

  test('OCR queda en revisión y solo aparece en el libro al aprobar', () async {
    final now = DateTime.now();
    await database
        .into(database.books)
        .insert(
          BooksCompanion.insert(
            id: 'book-review',
            title: 'Review',
            createdAt: now,
            updatedAt: now,
          ),
        );
    await database.addPageWithParagraphs(
      bookId: 'book-review',
      pageId: 'page-review',
      imagePath: '/page.png',
      texts: const ['Draft paragraph'],
    );
    expect(await database.watchParagraphs('book-review').first, isEmpty);
    final draft = (await database.watchDrafts('book-review').first).single;
    expect(draft.rawText, 'Draft paragraph');
    await database.approveDraft(draft, const ['Corrected paragraph']);
    expect(
      (await database.watchParagraphs('book-review').first).single.content,
      'Corrected paragraph',
    );
    expect(await database.watchDrafts('book-review').first, isEmpty);
  });

  test(
    'la cola recupera trabajos, cuenta intentos y conserva el error final',
    () async {
      final now = DateTime.now();
      await database
          .into(database.books)
          .insert(
            BooksCompanion.insert(
              id: 'book-queue',
              title: 'Queue',
              createdAt: now,
              updatedAt: now,
            ),
          );
      await database.createQueuedPage(
        bookId: 'book-queue',
        pageId: 'page-queue',
        jobId: 'job-queue',
        imagePath: '/page.png',
      );
      await database.startJob('job-queue');
      expect((await database.findJob('job-queue'))?.attempts, 1);
      await database.recoverInterruptedJobs('book-queue');
      expect((await database.findJob('job-queue'))?.state, 'queued');
      final job = (await database.findJob('job-queue'))!;
      await database.failJob(job, willRetry: false, errorCode: 'ocr_failed');
      expect((await database.findJob('job-queue'))?.state, 'failed');
      expect(
        (await database.watchPages('book-queue').first).single.status,
        'error',
      );
    },
  );

  test(
    'reprocesar conserva el texto anterior hasta aprobar el nuevo borrador',
    () async {
      final now = DateTime.now();
      await database
          .into(database.books)
          .insert(
            BooksCompanion.insert(
              id: 'book-reprocess',
              title: 'Reprocess',
              createdAt: now,
              updatedAt: now,
            ),
          );
      await database.addPageWithParagraphs(
        bookId: 'book-reprocess',
        pageId: 'page-reprocess',
        imagePath: '/page.png',
        texts: const ['Old text'],
      );
      await database.approveDraft(
        (await database.watchDrafts('book-reprocess').first).single,
        const ['Old text'],
      );
      final page = (await database.watchPages('book-reprocess').first).single;
      await database.queueReprocess(page);
      final job = (await database.queuedJobs('book-reprocess')).single;
      await database.saveDraft(
        bookId: page.bookId,
        pageId: page.id,
        jobId: job.id,
        rawText: 'New text',
        paragraphs: const ['New text'],
      );
      expect(
        (await database.watchParagraphs('book-reprocess').first).single.content,
        'Old text',
      );
      await database.approveDraft(
        (await database.watchDrafts('book-reprocess').first).single,
        const ['New text'],
      );
      expect(
        (await database.watchParagraphs('book-reprocess').first).single.content,
        'New text',
      );
    },
  );

  test('reordenar páginas reordena también sus párrafos', () async {
    final now = DateTime.now();
    await database
        .into(database.books)
        .insert(
          BooksCompanion.insert(
            id: 'book-order',
            title: 'Order',
            createdAt: now,
            updatedAt: now,
          ),
        );
    await database.addPageWithParagraphs(
      bookId: 'book-order',
      pageId: 'page-a',
      imagePath: null,
      texts: const ['A'],
    );
    await database.approveDraft(
      (await database.watchDrafts('book-order').first).single,
      const ['A'],
    );
    await database.addPageWithParagraphs(
      bookId: 'book-order',
      pageId: 'page-b',
      imagePath: null,
      texts: const ['B'],
    );
    await database.approveDraft(
      (await database.watchDrafts('book-order').first).single,
      const ['B'],
    );
    await database.reorderPages('book-order', 1, 0);
    expect(
      (await database.watchPages('book-order').first).map((page) => page.id),
      ['page-b', 'page-a'],
    );
    expect(
      (await database.watchParagraphs('book-order').first).map(
        (paragraph) => paragraph.content,
      ),
      ['B', 'A'],
    );
  });

  test(
    'lote de 50 páginas conserva orden, aislamiento y tiempo de persistencia',
    () async {
      final now = DateTime.now();
      for (final id in ['book-batch', 'book-other']) {
        await database
            .into(database.books)
            .insert(
              BooksCompanion.insert(
                id: id,
                title: id,
                createdAt: now,
                updatedAt: now,
              ),
            );
      }
      final stopwatch = Stopwatch()..start();
      for (var i = 0; i < 50; i++) {
        final pageId = 'batch-page-$i';
        await database.addPageWithParagraphs(
          bookId: 'book-batch',
          pageId: pageId,
          imagePath: '/batch/$i.png',
          texts: ['Page $i paragraph'],
        );
        await database.approveDraft(
          (await database.watchDrafts('book-batch').first).single,
          ['Page $i paragraph'],
        );
      }
      stopwatch.stop();
      final paragraphs = await database.watchParagraphs('book-batch').first;
      expect(paragraphs, hasLength(50));
      expect(paragraphs.first.content, 'Page 0 paragraph');
      expect(paragraphs.last.content, 'Page 49 paragraph');
      expect(await database.watchParagraphs('book-other').first, isEmpty);
      expect(stopwatch.elapsed, lessThan(const Duration(seconds: 5)));
    },
  );
}
