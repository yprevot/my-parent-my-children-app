import 'dart:io';
import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

part 'app_database.g.dart';

class Books extends Table {
  TextColumn get id => text()();
  TextColumn get title => text()();
  TextColumn get learningLocale =>
      text().withDefault(const Constant('en-US'))();
  TextColumn get homeLocale => text().withDefault(const Constant('es-MX'))();
  TextColumn get voiceId => text().nullable()();
  RealColumn get speechRate => real().withDefault(const Constant(0.45))();
  IntColumn get lastParagraph => integer().withDefault(const Constant(0))();
  IntColumn get lastOffset => integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  IntColumn get contentRevision => integer().withDefault(const Constant(0))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class Pages extends Table {
  TextColumn get id => text()();
  TextColumn get bookId => text()();
  IntColumn get orderKey => integer()();
  TextColumn get originalPath => text().nullable()();
  TextColumn get derivedPath => text().nullable()();
  TextColumn get status => text().withDefault(const Constant('pending'))();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class Paragraphs extends Table {
  TextColumn get id => text()();
  TextColumn get bookId => text()();
  TextColumn get pageId => text()();
  IntColumn get orderKey => integer()();
  TextColumn get content => text()();
  TextColumn get localeOverride => text().nullable()();
  IntColumn get textRevision => integer().withDefault(const Constant(1))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class ImportJobs extends Table {
  TextColumn get id => text()();
  TextColumn get bookId => text()();
  TextColumn get pageId => text()();
  TextColumn get imagePath => text().nullable()();
  TextColumn get state => text().withDefault(const Constant('queued'))();
  IntColumn get attempts => integer().withDefault(const Constant(0))();
  TextColumn get errorCode => text().nullable()();
  DateTimeColumn get updatedAt => dateTime()();
  @override
  Set<Column<Object>> get primaryKey => {id};
}

class PageDrafts extends Table {
  TextColumn get id => text()();
  TextColumn get bookId => text()();
  TextColumn get pageId => text()();
  TextColumn get jobId => text()();
  TextColumn get rawText => text()();
  TextColumn get paragraphsJson => text()();
  IntColumn get revision => integer().withDefault(const Constant(1))();
  DateTimeColumn get updatedAt => dateTime()();
  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DriftDatabase(tables: [Books, Pages, Paragraphs, ImportJobs, PageDrafts])
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  @override
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) => m.createAll(),
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        await m.createTable(importJobs);
        await m.createTable(pageDrafts);
      }
      if (from < 3) {
        await m.addColumn(books, books.voiceId);
        await m.addColumn(books, books.speechRate);
        await m.addColumn(books, books.lastParagraph);
        await m.addColumn(books, books.lastOffset);
      }
    },
  );

  Stream<List<Book>> watchBooks() =>
      (select(books)..orderBy([(b) => OrderingTerm.desc(b.updatedAt)])).watch();

  Future<Book?> findBook(String id) =>
      (select(books)..where((b) => b.id.equals(id))).getSingleOrNull();

  Future<void> updateReadingPreferences(
    String bookId, {
    String? voiceId,
    double? speechRate,
  }) async {
    await (update(books)..where((book) => book.id.equals(bookId))).write(
      BooksCompanion(
        voiceId: voiceId == null ? const Value.absent() : Value(voiceId),
        speechRate: speechRate == null
            ? const Value.absent()
            : Value(speechRate),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> updateBookLanguages(
    String bookId, {
    required String homeLocale,
    required String learningLocale,
  }) async {
    await (update(books)..where((book) => book.id.equals(bookId))).write(
      BooksCompanion(
        homeLocale: Value(homeLocale),
        learningLocale: Value(learningLocale),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> saveReadingPosition(
    String bookId,
    int paragraph,
    int offset,
  ) async {
    await (update(books)..where((book) => book.id.equals(bookId))).write(
      BooksCompanion(
        lastParagraph: Value(paragraph),
        lastOffset: Value(offset),
      ),
    );
  }

  Stream<List<Paragraph>> watchParagraphs(String bookId) =>
      (select(paragraphs)
            ..where((p) => p.bookId.equals(bookId))
            ..orderBy([(p) => OrderingTerm.asc(p.orderKey)]))
          .watch();

  Stream<List<Page>> watchPages(String bookId) =>
      (select(pages)
            ..where((page) => page.bookId.equals(bookId))
            ..orderBy([(page) => OrderingTerm.asc(page.orderKey)]))
          .watch();

  Future<List<ImportJob>> queuedJobs(String bookId) =>
      (select(importJobs)
            ..where(
              (job) =>
                  job.bookId.equals(bookId) &
                  (job.state.equals('queued') | job.state.equals('processing')),
            )
            ..orderBy([(job) => OrderingTerm.asc(job.updatedAt)]))
          .get();

  Stream<List<ImportJob>> watchJobs(String bookId) =>
      (select(importJobs)
            ..where((job) => job.bookId.equals(bookId))
            ..orderBy([(job) => OrderingTerm.desc(job.updatedAt)]))
          .watch();

  Future<void> recoverInterruptedJobs(String bookId) async {
    await (update(importJobs)..where(
          (job) => job.bookId.equals(bookId) & job.state.equals('processing'),
        ))
        .write(
          ImportJobsCompanion(
            state: const Value('queued'),
            updatedAt: Value(DateTime.now()),
          ),
        );
  }

  Future<ImportJob?> findJob(String id) =>
      (select(importJobs)..where((job) => job.id.equals(id))).getSingleOrNull();

  Stream<List<PageDraft>> watchDrafts(String bookId) =>
      (select(pageDrafts)
            ..where((draft) => draft.bookId.equals(bookId))
            ..orderBy([(draft) => OrderingTerm.asc(draft.updatedAt)]))
          .watch();

  Future<int> nextPageOrder(String bookId) async {
    final rows = await (select(
      pages,
    )..where((p) => p.bookId.equals(bookId))).get();
    return rows.isEmpty
        ? 0
        : rows.map((row) => row.orderKey).reduce((a, b) => a > b ? a : b) + 1;
  }

  Future<int> nextParagraphOrder(String bookId) async {
    final rows = await (select(
      paragraphs,
    )..where((p) => p.bookId.equals(bookId))).get();
    return rows.isEmpty
        ? 0
        : rows.map((row) => row.orderKey).reduce((a, b) => a > b ? a : b) + 1;
  }

  Future<void> addPageWithParagraphs({
    required String bookId,
    required String pageId,
    required String? imagePath,
    required List<String> texts,
  }) async {
    final jobId = '${pageId}_job';
    await createQueuedPage(
      bookId: bookId,
      pageId: pageId,
      jobId: jobId,
      imagePath: imagePath,
    );
    await saveDraft(
      bookId: bookId,
      pageId: pageId,
      jobId: jobId,
      rawText: texts.join('\n'),
      paragraphs: texts,
    );
  }

  Future<void> startJob(String jobId) async {
    final job = await (select(
      importJobs,
    )..where((row) => row.id.equals(jobId))).getSingleOrNull();
    if (job == null) return;
    await (update(importJobs)..where((row) => row.id.equals(jobId))).write(
      ImportJobsCompanion(
        state: const Value('processing'),
        attempts: Value(job.attempts + 1),
        errorCode: const Value(null),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> failJob(
    ImportJob job, {
    required bool willRetry,
    required String errorCode,
  }) async {
    final state = willRetry ? 'queued' : 'failed';
    await (update(importJobs)..where((row) => row.id.equals(job.id))).write(
      ImportJobsCompanion(
        state: Value(state),
        errorCode: Value(errorCode),
        updatedAt: Value(DateTime.now()),
      ),
    );
    if (!willRetry) {
      await (update(pages)..where((row) => row.id.equals(job.pageId))).write(
        const PagesCompanion(status: Value('error')),
      );
    }
  }

  Future<void> createQueuedPage({
    required String bookId,
    required String pageId,
    required String jobId,
    required String? imagePath,
  }) async {
    final now = DateTime.now();
    await transaction(() async {
      final pageOrder = await nextPageOrder(bookId);
      await into(pages).insert(
        PagesCompanion.insert(
          id: pageId,
          bookId: bookId,
          orderKey: pageOrder,
          originalPath: Value(imagePath),
          createdAt: now,
        ),
      );
      await into(importJobs).insert(
        ImportJobsCompanion.insert(
          id: jobId,
          bookId: bookId,
          pageId: pageId,
          imagePath: Value(imagePath),
          updatedAt: now,
        ),
      );
    });
  }

  Future<void> markJob(String jobId, String state, {String? errorCode}) async {
    await (update(importJobs)..where((job) => job.id.equals(jobId))).write(
      ImportJobsCompanion(
        state: Value(state),
        errorCode: Value(errorCode),
        updatedAt: Value(DateTime.now()),
        attempts: const Value.absent(),
      ),
    );
  }

  Future<void> saveDraft({
    required String bookId,
    required String pageId,
    required String jobId,
    required String rawText,
    required List<String> paragraphs,
  }) async {
    final now = DateTime.now();
    await transaction(() async {
      await markJob(jobId, 'review');
      await into(pageDrafts).insert(
        PageDraftsCompanion.insert(
          id: '${pageId}_draft',
          bookId: bookId,
          pageId: pageId,
          jobId: jobId,
          rawText: rawText,
          paragraphsJson: jsonEncode(paragraphs),
          updatedAt: now,
        ),
        mode: InsertMode.insertOrReplace,
      );
      await (update(pages)..where((page) => page.id.equals(pageId))).write(
        const PagesCompanion(status: Value('review')),
      );
    });
  }

  Future<void> queueReprocess(Page page) async {
    final now = DateTime.now();
    final jobId = '${page.id}_reprocess_${now.microsecondsSinceEpoch}';
    await into(importJobs).insert(
      ImportJobsCompanion.insert(
        id: jobId,
        bookId: page.bookId,
        pageId: page.id,
        imagePath: Value(page.originalPath),
        updatedAt: now,
      ),
    );
    await (update(pages)..where((row) => row.id.equals(page.id))).write(
      const PagesCompanion(status: Value('reprocessing')),
    );
  }

  Future<void> approveDraft(
    PageDraft draft,
    List<String> editedParagraphs,
  ) async {
    final now = DateTime.now();
    await transaction(() async {
      final existing = await (select(
        paragraphs,
      )..where((p) => p.pageId.equals(draft.pageId))).get();
      var order = existing.isEmpty
          ? await nextParagraphOrder(draft.bookId)
          : existing.map((row) => row.orderKey).reduce((a, b) => a < b ? a : b);
      await (delete(
        paragraphs,
      )..where((p) => p.pageId.equals(draft.pageId))).go();
      for (final value in editedParagraphs.where(
        (value) => value.trim().isNotEmpty,
      )) {
        await into(paragraphs).insert(
          ParagraphsCompanion.insert(
            id: '${draft.pageId}_$order',
            bookId: draft.bookId,
            pageId: draft.pageId,
            orderKey: order++,
            content: value.trim(),
          ),
          mode: InsertMode.insertOrReplace,
        );
      }
      await markJob(draft.jobId, 'approved');
      await (update(pages)..where((page) => page.id.equals(draft.pageId)))
          .write(const PagesCompanion(status: Value('approved')));
      await (delete(pageDrafts)..where((d) => d.id.equals(draft.id))).go();
      await (update(
        books,
      )..where((book) => book.id.equals(draft.bookId))).write(
        BooksCompanion(
          updatedAt: Value(now),
          contentRevision: const Value.absent(),
        ),
      );
      // Re-normalizar los orderKey de todos los párrafos del libro para
      // garantizar orden secuencial estricto sin solapamientos entre páginas.
      final allPages = await (select(pages)
            ..where((page) => page.bookId.equals(draft.bookId))
            ..orderBy([(page) => OrderingTerm.asc(page.orderKey)]))
          .get();
      var paragraphOrder = 0;
      for (final page in allPages) {
        final pageParagraphs = await (select(paragraphs)
              ..where((p) => p.pageId.equals(page.id))
              ..orderBy([(p) => OrderingTerm.asc(p.orderKey)]))
            .get();
        for (final paragraph in pageParagraphs) {
          await (update(paragraphs)..where((row) => row.id.equals(paragraph.id)))
              .write(ParagraphsCompanion(orderKey: Value(paragraphOrder++)));
        }
      }
    });
  }

  Future<void> retryJob(PageDraft draft) async {
    await markJob(draft.jobId, 'queued');
    await (delete(pageDrafts)..where((row) => row.id.equals(draft.id))).go();
    await (update(pages)..where((row) => row.id.equals(draft.pageId))).write(
      const PagesCompanion(status: Value('pending')),
    );
  }

  Future<void> reorderPages(String bookId, int oldIndex, int newIndex) async {
    final rows =
        await (select(pages)
              ..where((page) => page.bookId.equals(bookId))
              ..orderBy([(page) => OrderingTerm.asc(page.orderKey)]))
            .get();
    if (oldIndex < 0 || oldIndex >= rows.length) return;
    if (newIndex < 0 || newIndex >= rows.length || oldIndex == newIndex) return;
    final moved = rows.removeAt(oldIndex);
    final reordered = [...rows]..insert(newIndex, moved);
    await transaction(() async {
      for (var i = 0; i < reordered.length; i++) {
        await (update(pages)..where((page) => page.id.equals(reordered[i].id)))
            .write(PagesCompanion(orderKey: Value(i)));
      }
      final pageParagraphs = <String, List<Paragraph>>{};
      for (final page in reordered) {
        pageParagraphs[page.id] =
            await (select(paragraphs)
                  ..where((paragraph) => paragraph.pageId.equals(page.id))
                  ..orderBy([
                    (paragraph) => OrderingTerm.asc(paragraph.orderKey),
                  ]))
                .get();
      }
      var paragraphOrder = 0;
      for (final page in reordered) {
        for (final paragraph
            in pageParagraphs[page.id] ?? const <Paragraph>[]) {
          await (update(paragraphs)
                ..where((row) => row.id.equals(paragraph.id)))
              .write(ParagraphsCompanion(orderKey: Value(paragraphOrder++)));
        }
      }
      await (update(books)..where((book) => book.id.equals(bookId))).write(
        BooksCompanion(updatedAt: Value(DateTime.now())),
      );
    });
  }

  Future<void> updateBookTitle(String id, String title) async {
    await (update(books)..where((book) => book.id.equals(id))).write(
      BooksCompanion(
        title: Value(title.trim()),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  /// Replaces the paragraphs of an already-approved page with [edited] text,
  /// re-normalises all paragraph orderKeys across the book, and bumps the
  /// book's [updatedAt] timestamp.
  Future<void> updatePageParagraphs({
    required String bookId,
    required String pageId,
    required List<String> edited,
  }) async {
    final now = DateTime.now();
    await transaction(() async {
      // 1. Preserve the lowest existing orderKey so the page keeps its slot.
      final existing =
          await (select(paragraphs)..where((p) => p.pageId.equals(pageId)))
              .get();
      var order = existing.isEmpty
          ? await nextParagraphOrder(bookId)
          : existing.map((row) => row.orderKey).reduce((a, b) => a < b ? a : b);

      // 2. Remove old paragraphs for this page.
      await (delete(paragraphs)..where((p) => p.pageId.equals(pageId))).go();

      // 3. Insert the edited paragraphs.
      for (final value in edited.where((v) => v.trim().isNotEmpty)) {
        await into(paragraphs).insert(
          ParagraphsCompanion.insert(
            id: '${pageId}_$order',
            bookId: bookId,
            pageId: pageId,
            orderKey: order++,
            content: value.trim(),
          ),
          mode: InsertMode.insertOrReplace,
        );
      }

      // 4. Re-normalise orderKeys across the entire book.
      final allPages = await (select(pages)
            ..where((page) => page.bookId.equals(bookId))
            ..orderBy([(page) => OrderingTerm.asc(page.orderKey)]))
          .get();
      var paragraphOrder = 0;
      for (final page in allPages) {
        final pageParagraphs = await (select(paragraphs)
              ..where((p) => p.pageId.equals(page.id))
              ..orderBy([(p) => OrderingTerm.asc(p.orderKey)]))
            .get();
        for (final paragraph in pageParagraphs) {
          await (update(paragraphs)
                ..where((row) => row.id.equals(paragraph.id)))
              .write(ParagraphsCompanion(orderKey: Value(paragraphOrder++)));
        }
      }

      // 5. Bump book timestamp.
      await (update(books)..where((book) => book.id.equals(bookId))).write(
        BooksCompanion(updatedAt: Value(now)),
      );
    });
  }

  Future<void> deletePage(String pageId) async {
    final page = await (select(pages)..where((p) => p.id.equals(pageId))).getSingleOrNull();
    if (page == null) return;
    final bookId = page.bookId;
    final originalPath = page.originalPath;
    final derivedPath = page.derivedPath;
    await transaction(() async {
      await (delete(paragraphs)..where((p) => p.pageId.equals(pageId))).go();
      await (delete(pageDrafts)..where((d) => d.pageId.equals(pageId))).go();
      await (delete(importJobs)..where((j) => j.pageId.equals(pageId))).go();
      await (delete(pages)..where((p) => p.id.equals(pageId))).go();

      final remainingPages = await (select(pages)
            ..where((p) => p.bookId.equals(bookId))
            ..orderBy([(p) => OrderingTerm.asc(p.orderKey)]))
          .get();
      var pageOrder = 0;
      var paragraphOrder = 0;
      for (final p in remainingPages) {
        await (update(pages)..where((row) => row.id.equals(p.id)))
            .write(PagesCompanion(orderKey: Value(pageOrder++)));
        final pList = await (select(paragraphs)
              ..where((row) => row.pageId.equals(p.id))
              ..orderBy([(row) => OrderingTerm.asc(row.orderKey)]))
            .get();
        for (final para in pList) {
          await (update(paragraphs)..where((row) => row.id.equals(para.id)))
              .write(ParagraphsCompanion(orderKey: Value(paragraphOrder++)));
        }
      }
      await (update(books)..where((b) => b.id.equals(bookId))).write(
        BooksCompanion(updatedAt: Value(DateTime.now())),
      );
    });
    _deleteFileIfExists(originalPath);
    _deleteFileIfExists(derivedPath);
  }

  Future<void> deleteBook(String id) async {
    final bookPages = await (select(pages)..where((p) => p.bookId.equals(id))).get();
    final filePaths = <String?>[
      for (final p in bookPages) ...[p.originalPath, p.derivedPath],
    ];
    final jobs = await (select(importJobs)..where((j) => j.bookId.equals(id))).get();
    for (final j in jobs) {
      filePaths.add(j.imagePath);
    }
    await transaction(() async {
      await (delete(pageDrafts)..where((d) => d.bookId.equals(id))).go();
      await (delete(importJobs)..where((j) => j.bookId.equals(id))).go();
      await (delete(paragraphs)..where((p) => p.bookId.equals(id))).go();
      await (delete(pages)..where((p) => p.bookId.equals(id))).go();
      await (delete(books)..where((b) => b.id.equals(id))).go();
    });
    for (final path in filePaths) {
      _deleteFileIfExists(path);
    }
  }

  Future<List<Page>> getApprovedPages(String bookId) =>
      (select(pages)
            ..where((p) => p.bookId.equals(bookId) & p.status.equals('approved'))
            ..orderBy([(p) => OrderingTerm.asc(p.orderKey)]))
          .get();

  Future<List<Paragraph>> getBookParagraphs(String bookId) =>
      (select(paragraphs)
            ..where((p) => p.bookId.equals(bookId))
            ..orderBy([(p) => OrderingTerm.asc(p.orderKey)]))
          .get();

  Future<Book> importProcessedBook({
    required String title,
    required String homeLocale,
    required String learningLocale,
    double speechRate = 0.45,
    String? voiceId,
    required List<ImportedPageData> pagesData,
  }) async {
    final now = DateTime.now();
    final bookId = 'imported_${now.microsecondsSinceEpoch}';
    return await transaction(() async {
      await into(books).insert(
        BooksCompanion.insert(
          id: bookId,
          title: title,
          homeLocale: Value(homeLocale),
          learningLocale: Value(learningLocale),
          voiceId: Value(voiceId),
          speechRate: Value(speechRate),
          createdAt: now,
          updatedAt: now,
        ),
      );
      var globalParagraphOrder = 0;
      for (final pageData in pagesData) {
        final pageId = '${bookId}_p${pageData.orderKey}';
        await into(pages).insert(
          PagesCompanion.insert(
            id: pageId,
            bookId: bookId,
            orderKey: pageData.orderKey,
            derivedPath: Value(pageData.imagePath),
            originalPath: Value(pageData.imagePath),
            status: const Value('approved'),
            createdAt: now,
          ),
        );
        for (final para in pageData.paragraphs) {
          await into(paragraphs).insert(
            ParagraphsCompanion.insert(
              id: '${pageId}_$globalParagraphOrder',
              bookId: bookId,
              pageId: pageId,
              orderKey: globalParagraphOrder++,
              content: para.content,
              localeOverride: Value(para.localeOverride),
            ),
          );
        }
      }
      return (await (select(books)..where((b) => b.id.equals(bookId))).getSingle());
    });
  }

  void _deleteFileIfExists(String? path) {
    if (path != null && path.isNotEmpty) {
      try {
        final file = File(path);
        if (file.existsSync()) {
          file.deleteSync();
        }
      } catch (_) {}
    }
  }
}

class ImportedPageData {
  final int orderKey;
  final String? originalId;
  final String? imagePath;
  final List<ImportedParagraphData> paragraphs;

  const ImportedPageData({
    required this.orderKey,
    this.originalId,
    this.imagePath,
    required this.paragraphs,
  });
}

class ImportedParagraphData {
  final String content;
  final String? localeOverride;

  const ImportedParagraphData({
    required this.content,
    this.localeOverride,
  });
}

Future<AppDatabase> openAppDatabase() async {
  final directory = await getApplicationSupportDirectory();
  final file = File(p.join(directory.path, 'images_to_book.sqlite'));
  return AppDatabase(NativeDatabase.createInBackground(file));
}
