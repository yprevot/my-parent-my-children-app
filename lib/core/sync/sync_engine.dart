import 'dart:async';

import 'package:drift/drift.dart';

import '../storage/app_database.dart' as db;
import '../../features/auth/auth_service.dart';
import 'sync_api_client.dart';
import 'sync_models.dart';

/// Motor de sincronización en segundo plano y bajo demanda.
///
/// Mantiene la primacía del almacenamiento local (SQLite/Drift).
/// Si no hay conexión o el usuario usa la app en modo local/invitado,
/// las operaciones locales continúan funcionando de forma 100% transparente.
class SyncEngine {
  SyncEngine({
    required this.database,
    required this.authService,
    required this.apiClient,
  }) {
    _authSubscription = authService.userChanges.listen((user) {
      if (user == null || user.isGuest) {
        _updateProgress(const SyncProgress(status: SyncStatus.idle));
      }
    });
  }

  final db.AppDatabase database;
  final AuthService authService;
  final SyncApiClient apiClient;
  late final StreamSubscription<AuthUser?> _authSubscription;

  final _progressController = StreamController<SyncProgress>.broadcast();
  SyncProgress _currentProgress = const SyncProgress(status: SyncStatus.idle);
  DateTime? _lastSyncTime;
  final Set<String> _deletedBookTombstones = {};

  Stream<SyncProgress> get progressStream => _progressController.stream;
  SyncProgress get currentProgress => _currentProgress;
  DateTime? get lastSyncTime => _lastSyncTime;

  void _updateProgress(SyncProgress progress) {
    _currentProgress = progress;
    _progressController.add(progress);
  }

  /// Registra un libro eliminado localmente para propagar el borrado al servidor
  /// en la próxima sincronización.
  void recordDeletedBook(String bookId) {
    _deletedBookTombstones.add(bookId);
  }

  /// Ejecuta la sincronización bidireccional (Push de cambios locales y Pull de remotos).
  Future<SyncResult> synchronize() async {
    final user = authService.currentUser;
    if (user == null || user.isGuest) {
      _updateProgress(
        const SyncProgress(
          status: SyncStatus.idle,
          message: 'Modo local activo.',
        ),
      );
      return SyncResult.guest();
    }

    final token = await authService.getIdToken();
    if (token == null || token.isEmpty) {
      _updateProgress(
        const SyncProgress(
          status: SyncStatus.error,
          message: 'No se pudo obtener el token de sesión.',
        ),
      );
      return SyncResult.failure('Sesión no autorizada.');
    }

    _updateProgress(
      SyncProgress(
        status: SyncStatus.syncing,
        message: 'Sincronizando libros…',
        lastSyncTime: _lastSyncTime,
      ),
    );

    try {
      // 1. Exportar libros locales a DTOs
      final localBooks = await database.select(database.books).get();
      final syncBooks = <SyncBookDto>[];

      for (final book in localBooks) {
        final pages = await (database.select(database.pages)
              ..where((p) => p.bookId.equals(book.id))
              ..orderBy([(p) => OrderingTerm.asc(p.orderKey)]))
            .get();

        final pageDtos = <SyncPageDto>[];
        for (final page in pages) {
          final paragraphs = await (database.select(database.paragraphs)
                ..where((p) => p.pageId.equals(page.id))
                ..orderBy([(p) => OrderingTerm.asc(p.orderKey)]))
              .get();

          pageDtos.add(
            SyncPageDto(
              id: page.id,
              orderKey: page.orderKey,
              status: page.status,
              createdAt: page.createdAt,
              paragraphs: paragraphs
                  .map(
                    (para) => SyncParagraphDto(
                      id: para.id,
                      orderKey: para.orderKey,
                      content: para.content,
                      localeOverride: para.localeOverride,
                      textRevision: para.textRevision,
                    ),
                  )
                  .toList(),
            ),
          );
        }

        syncBooks.add(
          SyncBookDto(
            id: book.id,
            title: book.title,
            homeLocale: book.homeLocale,
            learningLocale: book.learningLocale,
            voiceId: book.voiceId,
            speechRate: book.speechRate,
            lastParagraph: book.lastParagraph,
            lastOffset: book.lastOffset,
            createdAt: book.createdAt,
            updatedAt: book.updatedAt,
            contentRevision: book.contentRevision,
            pages: pageDtos,
          ),
        );
      }

      // 2. Push cambios locales y eliminaciones al backend
      final pushRequest = SyncPushRequest(
        books: syncBooks,
        deletedBookIds: _deletedBookTombstones.toList(),
      );

      final pushResponse = await apiClient.pushSync(
        pushRequest,
        authToken: token,
      );
      _deletedBookTombstones.clear();

      // 3. Pull cambios remotos posteriores a _lastSyncTime
      final pullResponse = await apiClient.pullSync(
        lastSyncTime: _lastSyncTime,
        authToken: token,
      );

      var pulledCount = 0;
      var deletedCount = 0;

      // 4. Aplicar eliminaciones remotas localmente
      for (final deletedId in pullResponse.deletedBookIds) {
        final existing = await database.findBook(deletedId);
        if (existing != null) {
          await database.deleteBook(deletedId);
          deletedCount++;
        }
      }

      // 5. Aplicar libros remotos localmente
      for (final remoteBook in pullResponse.books) {
        final existing = await database.findBook(remoteBook.id);
        if (existing == null) {
          // Libro nuevo del servidor -> insertar en BD local
          await database.transaction(() async {
            await database.into(database.books).insert(
                  db.BooksCompanion.insert(
                    id: remoteBook.id,
                    title: remoteBook.title,
                    homeLocale: Value(remoteBook.homeLocale),
                    learningLocale: Value(remoteBook.learningLocale),
                    voiceId: Value(remoteBook.voiceId),
                    speechRate: Value(remoteBook.speechRate),
                    lastParagraph: Value(remoteBook.lastParagraph),
                    lastOffset: Value(remoteBook.lastOffset),
                    createdAt: remoteBook.createdAt,
                    updatedAt: remoteBook.updatedAt,
                    contentRevision: Value(remoteBook.contentRevision),
                  ),
                );

            for (final page in remoteBook.pages) {
              await database.into(database.pages).insert(
                    db.PagesCompanion.insert(
                      id: page.id,
                      bookId: remoteBook.id,
                      orderKey: page.orderKey,
                      status: Value(page.status),
                      createdAt: page.createdAt ?? DateTime.now(),
                    ),
                  );

              for (final para in page.paragraphs) {
                await database.into(database.paragraphs).insert(
                      db.ParagraphsCompanion.insert(
                        id: para.id,
                        bookId: remoteBook.id,
                        pageId: page.id,
                        orderKey: para.orderKey,
                        content: para.content,
                        localeOverride: Value(para.localeOverride),
                        textRevision: Value(para.textRevision),
                      ),
                    );
              }
            }
          });
          pulledCount++;
        } else {
          // Si el libro remoto es más reciente, actualizar la versión local
          if (remoteBook.contentRevision > existing.contentRevision ||
              remoteBook.updatedAt.isAfter(existing.updatedAt)) {
            await database.transaction(() async {
              await (database.update(database.books)
                    ..where((b) => b.id.equals(remoteBook.id)))
                  .write(
                db.BooksCompanion(
                  title: Value(remoteBook.title),
                  homeLocale: Value(remoteBook.homeLocale),
                  learningLocale: Value(remoteBook.learningLocale),
                  voiceId: Value(remoteBook.voiceId),
                  speechRate: Value(remoteBook.speechRate),
                  lastParagraph: Value(remoteBook.lastParagraph),
                  lastOffset: Value(remoteBook.lastOffset),
                  updatedAt: Value(remoteBook.updatedAt),
                  contentRevision: Value(remoteBook.contentRevision),
                ),
              );

              // Actualizar páginas y párrafos
              await (database.delete(database.paragraphs)
                    ..where((p) => p.bookId.equals(remoteBook.id)))
                  .go();
              await (database.delete(database.pages)
                    ..where((p) => p.bookId.equals(remoteBook.id)))
                  .go();

              for (final page in remoteBook.pages) {
                await database.into(database.pages).insert(
                      db.PagesCompanion.insert(
                        id: page.id,
                        bookId: remoteBook.id,
                        orderKey: page.orderKey,
                        status: Value(page.status),
                        createdAt: page.createdAt ?? DateTime.now(),
                      ),
                    );

                for (final para in page.paragraphs) {
                  await database.into(database.paragraphs).insert(
                        db.ParagraphsCompanion.insert(
                          id: para.id,
                          bookId: remoteBook.id,
                          pageId: page.id,
                          orderKey: para.orderKey,
                          content: para.content,
                          localeOverride: Value(para.localeOverride),
                          textRevision: Value(para.textRevision),
                        ),
                      );
                }
              }
            });
            pulledCount++;
          }
        }
      }

      _lastSyncTime = DateTime.now();
      _updateProgress(
        SyncProgress(
          status: SyncStatus.success,
          message: 'Sincronizado correctamente.',
          lastSyncTime: _lastSyncTime,
        ),
      );

      return SyncResult(
        success: true,
        pushedCount: pushResponse.syncedBookIds.length,
        pulledCount: pulledCount,
        deletedCount: deletedCount,
      );
    } on SyncApiException catch (e) {
      final status = e.statusCode == 0 ? SyncStatus.offline : SyncStatus.error;
      _updateProgress(
        SyncProgress(
          status: status,
          message: e.message,
          lastSyncTime: _lastSyncTime,
        ),
      );
      return SyncResult.failure(e.message);
    } catch (e) {
      _updateProgress(
        SyncProgress(
          status: SyncStatus.error,
          message: 'Error inesperado al sincronizar.',
          lastSyncTime: _lastSyncTime,
        ),
      );
      return SyncResult.failure(e.toString());
    }
  }

  void dispose() {
    _authSubscription.cancel();
    _progressController.close();
  }
}
