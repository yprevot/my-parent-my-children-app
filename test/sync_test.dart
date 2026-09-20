import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:images_to_book/core/storage/app_database.dart';
import 'package:images_to_book/core/sync/sync_api_client.dart';
import 'package:images_to_book/core/sync/sync_engine.dart';
import 'package:images_to_book/core/sync/sync_models.dart';
import 'package:images_to_book/features/auth/auth_service.dart';

void main() {
  late AppDatabase database;
  late FakeInternetAuthService authService;
  late MockSyncApiClient apiClient;
  late SyncEngine syncEngine;

  setUp(() async {
    database = AppDatabase(NativeDatabase.memory());
    authService = FakeInternetAuthService();
    apiClient = MockSyncApiClient();
    syncEngine = SyncEngine(
      database: database,
      authService: authService,
      apiClient: apiClient,
    );
  });

  tearDown(() async {
    syncEngine.dispose();
    await database.close();
  });

  group('Sync Models Serialization', () {
    test('SyncBookDto serializa y deserializa en JSON preservando jerarquía', () {
      final now = DateTime.now();
      final original = SyncBookDto(
        id: 'book-test-1',
        title: 'Story Book',
        homeLocale: 'es-MX',
        learningLocale: 'en-US',
        voiceId: 'en-us-x-sfg',
        speechRate: 0.5,
        lastParagraph: 2,
        lastOffset: 15,
        createdAt: now,
        updatedAt: now,
        contentRevision: 3,
        pages: [
          SyncPageDto(
            id: 'page-test-1',
            orderKey: 0,
            status: 'ready',
            paragraphs: const [
              SyncParagraphDto(
                id: 'para-1',
                orderKey: 0,
                content: 'Once upon a time.',
                textRevision: 1,
              ),
              SyncParagraphDto(
                id: 'para-2',
                orderKey: 1,
                content: 'There was a small cat.',
                textRevision: 2,
              ),
            ],
          ),
        ],
      );

      final json = original.toJson();
      final deserialized = SyncBookDto.fromJson(json);

      expect(deserialized.id, original.id);
      expect(deserialized.title, original.title);
      expect(deserialized.voiceId, original.voiceId);
      expect(deserialized.speechRate, original.speechRate);
      expect(deserialized.pages, hasLength(1));
      expect(deserialized.pages.first.paragraphs, hasLength(2));
      expect(
        deserialized.pages.first.paragraphs.last.content,
        'There was a small cat.',
      );
    });

    test('SyncPushRequest serializa DTOs y lista de eliminaciones', () {
      final now = DateTime.now();
      final request = SyncPushRequest(
        books: [
          SyncBookDto(
            id: 'b1',
            title: 'Book 1',
            homeLocale: 'es-MX',
            learningLocale: 'en-US',
            createdAt: now,
            updatedAt: now,
          ),
        ],
        deletedBookIds: const ['b_deleted_1', 'b_deleted_2'],
      );

      final json = request.toJson();
      final parsed = SyncPushRequest.fromJson(json);

      expect(parsed.books, hasLength(1));
      expect(parsed.deletedBookIds, ['b_deleted_1', 'b_deleted_2']);
    });
  });

  group('SyncEngine Operation & Integration', () {
    test('en modo invitado / local no realiza llamadas al servidor', () async {
      await authService.signInLocally();

      final result = await syncEngine.synchronize();

      expect(result.success, isTrue);
      expect(result.isGuest, isTrue);
      expect(apiClient.pushCalls, 0);
      expect(apiClient.pullCalls, 0);
    });

    test('usuario autenticado sube (push) libros locales al servidor', () async {
      await authService.signInWithGoogle();

      final now = DateTime.now();
      await database.into(database.books).insert(
            BooksCompanion.insert(
              id: 'local-book-1',
              title: 'Local Book',
              createdAt: now,
              updatedAt: now,
            ),
          );
      await database.addPageWithParagraphs(
        bookId: 'local-book-1',
        pageId: 'local-p1',
        imagePath: null,
        texts: const ['Hello world.'],
      );

      final result = await syncEngine.synchronize();

      expect(result.success, isTrue);
      expect(result.pushedCount, 1);
      expect(apiClient.remoteBooks.containsKey('local-book-1'), isTrue);
      expect(apiClient.remoteBooks['local-book-1']?.title, 'Local Book');
      expect(syncEngine.lastSyncTime, isNotNull);
    });

    test('descarga (pull) libros remotos y los guarda en SQLite local', () async {
      await authService.signInWithGoogle();

      final now = DateTime.now();
      apiClient.remoteBooks['remote-b1'] = SyncBookDto(
        id: 'remote-b1',
        title: 'Remote Book From Tablet',
        homeLocale: 'es-MX',
        learningLocale: 'en-US',
        createdAt: now,
        updatedAt: now,
        pages: [
          SyncPageDto(
            id: 'remote-page-1',
            orderKey: 0,
            status: 'ready',
            paragraphs: const [
              SyncParagraphDto(
                id: 'remote-para-1',
                orderKey: 0,
                content: 'Paragraph from cloud.',
              ),
            ],
          ),
        ],
      );

      final result = await syncEngine.synchronize();

      expect(result.success, isTrue);
      expect(result.pulledCount, 1);

      final localBook = await database.findBook('remote-b1');
      expect(localBook, isNotNull);
      expect(localBook?.title, 'Remote Book From Tablet');

      final paragraphs = await database.watchParagraphs('remote-b1').first;
      expect(paragraphs, hasLength(1));
      expect(paragraphs.single.content, 'Paragraph from cloud.');
    });

    test('resolución de conflictos: libro remoto más reciente actualiza local', () async {
      await authService.signInWithGoogle();

      final past = DateTime.now().subtract(const Duration(hours: 2));
      final recent = DateTime.now();

      // Libro local antiguo
      await database.into(database.books).insert(
            BooksCompanion.insert(
              id: 'conflict-b1',
              title: 'Local Old Title',
              createdAt: past,
              updatedAt: past,
              contentRevision: const Value(1),
            ),
          );

      // Servidor tiene una versión más reciente
      apiClient.remoteBooks['conflict-b1'] = SyncBookDto(
        id: 'conflict-b1',
        title: 'Remote Newer Title',
        homeLocale: 'es-MX',
        learningLocale: 'en-US',
        createdAt: past,
        updatedAt: recent,
        contentRevision: 2,
      );

      final result = await syncEngine.synchronize();

      expect(result.success, isTrue);
      final updated = await database.findBook('conflict-b1');
      expect(updated?.title, 'Remote Newer Title');
      expect(updated?.contentRevision, 2);
    });

    test('propaga eliminación local al servidor como tombstone', () async {
      await authService.signInWithGoogle();

      final now = DateTime.now();
      apiClient.remoteBooks['to-delete'] = SyncBookDto(
        id: 'to-delete',
        title: 'Will be deleted',
        homeLocale: 'es-MX',
        learningLocale: 'en-US',
        createdAt: now,
        updatedAt: now,
      );

      // Registrar eliminación en el motor de sincronización
      syncEngine.recordDeletedBook('to-delete');

      final result = await syncEngine.synchronize();

      expect(result.success, isTrue);
      expect(apiClient.remoteBooks.containsKey('to-delete'), isFalse);
      expect(apiClient.remoteDeletedBookIds.contains('to-delete'), isTrue);
    });

    test('resiliencia sin conexión: no bloquea ni destruye la BD local', () async {
      await authService.signInWithGoogle();
      apiClient.simulateOffline = true;

      final now = DateTime.now();
      await database.into(database.books).insert(
            BooksCompanion.insert(
              id: 'local-safe',
              title: 'Safe Book',
              createdAt: now,
              updatedAt: now,
            ),
          );

      final result = await syncEngine.synchronize();

      expect(result.success, isFalse);
      expect(syncEngine.currentProgress.status, SyncStatus.offline);

      // Los datos locales permanecen íntegros
      final book = await database.findBook('local-safe');
      expect(book, isNotNull);
      expect(book?.title, 'Safe Book');
    });

    test('vincular cuenta Google desde modo invitado habilita sincronización', () async {
      // 1. Usuario inicia en modo local offline
      await authService.signInLocally();
      expect(authService.currentUser?.isGuest, isTrue);

      final now = DateTime.now();
      await database.into(database.books).insert(
            BooksCompanion.insert(
              id: 'offline-created-book',
              title: 'Offline Created Book',
              createdAt: now,
              updatedAt: now,
            ),
          );

      // 2. Decide vincular su cuenta de Google
      final linkedUser = await authService.linkWithGoogle();
      expect(linkedUser.isGoogle, isTrue);
      expect(linkedUser.isGuest, isFalse);

      // 3. Sincronización se ejecuta con éxito
      final result = await syncEngine.synchronize();
      expect(result.success, isTrue);
      expect(apiClient.remoteBooks.containsKey('offline-created-book'), isTrue);
    });
  });
}
