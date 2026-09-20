import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import 'sync_models.dart';

/// Excepción en operaciones de red con la API de sincronización.
class SyncApiException implements Exception {
  const SyncApiException(this.statusCode, this.message);
  final int statusCode;
  final String message;

  @override
  String toString() => 'SyncApiException($statusCode): $message';
}

/// Contrato del cliente de la API de backend para sincronización.
abstract class SyncApiClient {
  /// Sube los cambios locales al backend (libros nuevos, actualizados o eliminados).
  Future<SyncPushResponse> pushSync(
    SyncPushRequest request, {
    required String authToken,
  });

  /// Descarga los cambios del backend posteriores a [lastSyncTime].
  Future<SyncPullResponse> pullSync({
    DateTime? lastSyncTime,
    required String authToken,
  });

  /// Solicita el borrado de todos los datos del usuario en el backend (privacidad).
  Future<void> deleteUserData({required String authToken});

  /// Verifica si el servicio backend se encuentra disponible.
  Future<bool> checkHealth();
}

/// Implementación HTTP real para la API backend de MySchoolMyParents Online.
class HttpSyncApiClient implements SyncApiClient {
  HttpSyncApiClient({
    String? baseUrl,
    http.Client? client,
  })  : baseUrl = baseUrl ?? 'https://myschoolmyparents.online/api/v1',
        _client = client ?? http.Client();

  final String baseUrl;
  final http.Client _client;

  Map<String, String> _headers(String authToken) => {
    HttpHeaders.authorizationHeader: 'Bearer $authToken',
    HttpHeaders.contentTypeHeader: 'application/json; charset=utf-8',
    HttpHeaders.acceptHeader: 'application/json',
  };

  @override
  Future<SyncPushResponse> pushSync(
    SyncPushRequest request, {
    required String authToken,
  }) async {
    final url = Uri.parse('$baseUrl/sync/push');
    try {
      final response = await _client.post(
        url,
        headers: _headers(authToken),
        body: request.toJsonString(),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final decoded = jsonDecode(response.body) as Map<String, dynamic>;
        return SyncPushResponse.fromJson(decoded);
      } else if (response.statusCode == 401) {
        throw const SyncApiException(401, 'Sesión expirada o no autorizada.');
      } else {
        throw SyncApiException(
          response.statusCode,
          'Error del servidor al sincronizar: ${response.statusCode}',
        );
      }
    } on SocketException catch (_) {
      throw const SyncApiException(0, 'Sin conexión con el servidor.');
    }
  }

  @override
  Future<SyncPullResponse> pullSync({
    DateTime? lastSyncTime,
    required String authToken,
  }) async {
    final query = lastSyncTime != null
        ? '?since=${Uri.encodeComponent(lastSyncTime.toIso8601String())}'
        : '';
    final url = Uri.parse('$baseUrl/sync/pull$query');
    try {
      final response = await _client.get(
        url,
        headers: _headers(authToken),
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body) as Map<String, dynamic>;
        return SyncPullResponse.fromJson(decoded);
      } else if (response.statusCode == 401) {
        throw const SyncApiException(401, 'Sesión expirada o no autorizada.');
      } else {
        throw SyncApiException(
          response.statusCode,
          'Error al obtener cambios remotos: ${response.statusCode}',
        );
      }
    } on SocketException catch (_) {
      throw const SyncApiException(0, 'Sin conexión con el servidor.');
    }
  }

  @override
  Future<void> deleteUserData({required String authToken}) async {
    final url = Uri.parse('$baseUrl/user/data');
    final response = await _client.delete(
      url,
      headers: _headers(authToken),
    );
    if (response.statusCode != 200 && response.statusCode != 204) {
      throw SyncApiException(
        response.statusCode,
        'No se pudo eliminar la información en el servidor.',
      );
    }
  }

  @override
  Future<bool> checkHealth() async {
    try {
      final url = Uri.parse('$baseUrl/health');
      final response = await _client.get(url).timeout(const Duration(seconds: 4));
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  void close() {
    _client.close();
  }
}

/// Implementación simulada en memoria para pruebas automáticas y validación offline.
class MockSyncApiClient implements SyncApiClient {
  MockSyncApiClient();

  final Map<String, SyncBookDto> remoteBooks = {};
  final List<String> remoteDeletedBookIds = [];
  bool simulateOffline = false;
  bool simulateUnauthorized = false;
  int pushCalls = 0;
  int pullCalls = 0;

  @override
  Future<SyncPushResponse> pushSync(
    SyncPushRequest request, {
    required String authToken,
  }) async {
    if (simulateOffline) {
      throw const SyncApiException(0, 'Sin conexión.');
    }
    if (simulateUnauthorized || authToken.isEmpty) {
      throw const SyncApiException(401, 'No autorizado.');
    }

    pushCalls++;
    final syncedIds = <String>[];
    for (final book in request.books) {
      final existingRemote = remoteBooks[book.id];
      if (existingRemote != null &&
          (existingRemote.contentRevision > book.contentRevision ||
              existingRemote.updatedAt.isAfter(book.updatedAt))) {
        // La versión del servidor es más reciente: no sobrescribir
        continue;
      }
      remoteBooks[book.id] = book;
      syncedIds.add(book.id);
    }
    for (final deletedId in request.deletedBookIds) {
      remoteBooks.remove(deletedId);
      remoteDeletedBookIds.add(deletedId);
    }

    return SyncPushResponse(
      success: true,
      syncedBookIds: syncedIds,
      serverTime: DateTime.now(),
    );
  }

  @override
  Future<SyncPullResponse> pullSync({
    DateTime? lastSyncTime,
    required String authToken,
  }) async {
    if (simulateOffline) {
      throw const SyncApiException(0, 'Sin conexión.');
    }
    if (simulateUnauthorized || authToken.isEmpty) {
      throw const SyncApiException(401, 'No autorizado.');
    }

    pullCalls++;
    final results = remoteBooks.values.where((b) {
      if (lastSyncTime == null) return true;
      return b.updatedAt.isAfter(lastSyncTime);
    }).toList();

    return SyncPullResponse(
      books: results,
      deletedBookIds: remoteDeletedBookIds,
      serverTime: DateTime.now(),
    );
  }

  @override
  Future<void> deleteUserData({required String authToken}) async {
    remoteBooks.clear();
    remoteDeletedBookIds.clear();
  }

  @override
  Future<bool> checkHealth() async => !simulateOffline;
}
