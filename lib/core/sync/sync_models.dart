import 'dart:convert';

/// Estado de la sincronización en segundo plano o manual.
enum SyncStatus {
  idle,
  syncing,
  success,
  offline,
  error,
}

/// Información del estado actual de la sincronización.
class SyncProgress {
  const SyncProgress({
    required this.status,
    this.message,
    this.lastSyncTime,
    this.pendingCount = 0,
  });

  final SyncStatus status;
  final String? message;
  final DateTime? lastSyncTime;
  final int pendingCount;

  bool get isSyncing => status == SyncStatus.syncing;
}

/// DTO de un párrafo para el backend.
class SyncParagraphDto {
  const SyncParagraphDto({
    required this.id,
    required this.orderKey,
    required this.content,
    this.localeOverride,
    this.textRevision = 1,
  });

  final String id;
  final int orderKey;
  final String content;
  final String? localeOverride;
  final int textRevision;

  Map<String, dynamic> toJson() => {
    'id': id,
    'orderKey': orderKey,
    'content': content,
    'localeOverride': localeOverride,
    'textRevision': textRevision,
  };

  factory SyncParagraphDto.fromJson(Map<String, dynamic> json) => SyncParagraphDto(
    id: json['id'] as String,
    orderKey: json['orderKey'] as int,
    content: json['content'] as String,
    localeOverride: json['localeOverride'] as String?,
    textRevision: (json['textRevision'] as int?) ?? 1,
  );
}

/// DTO de una página para el backend.
class SyncPageDto {
  const SyncPageDto({
    required this.id,
    required this.orderKey,
    required this.status,
    required this.paragraphs,
    this.createdAt,
  });

  final String id;
  final int orderKey;
  final String status;
  final List<SyncParagraphDto> paragraphs;
  final DateTime? createdAt;

  Map<String, dynamic> toJson() => {
    'id': id,
    'orderKey': orderKey,
    'status': status,
    'paragraphs': paragraphs.map((p) => p.toJson()).toList(),
    'createdAt': createdAt?.toIso8601String(),
  };

  factory SyncPageDto.fromJson(Map<String, dynamic> json) => SyncPageDto(
    id: json['id'] as String,
    orderKey: json['orderKey'] as int,
    status: json['status'] as String? ?? 'ready',
    paragraphs: ((json['paragraphs'] as List<dynamic>?) ?? const <dynamic>[])
        .map((item) => SyncParagraphDto.fromJson(Map<String, dynamic>.from(item as Map)))
        .toList(),
    createdAt: json['createdAt'] != null
        ? DateTime.tryParse(json['createdAt'] as String)
        : null,
  );
}

/// DTO de un libro completo para sincronización con la API en la nube.
class SyncBookDto {
  const SyncBookDto({
    required this.id,
    required this.title,
    required this.homeLocale,
    required this.learningLocale,
    this.voiceId,
    this.speechRate = 0.45,
    this.lastParagraph = 0,
    this.lastOffset = 0,
    required this.createdAt,
    required this.updatedAt,
    this.contentRevision = 0,
    this.pages = const [],
    this.isDeleted = false,
  });

  final String id;
  final String title;
  final String homeLocale;
  final String learningLocale;
  final String? voiceId;
  final double speechRate;
  final int lastParagraph;
  final int lastOffset;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int contentRevision;
  final List<SyncPageDto> pages;
  final bool isDeleted;

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'homeLocale': homeLocale,
    'learningLocale': learningLocale,
    'voiceId': voiceId,
    'speechRate': speechRate,
    'lastParagraph': lastParagraph,
    'lastOffset': lastOffset,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    'contentRevision': contentRevision,
    'pages': pages.map((p) => p.toJson()).toList(),
    'isDeleted': isDeleted,
  };

  factory SyncBookDto.fromJson(Map<String, dynamic> json) => SyncBookDto(
    id: json['id'] as String,
    title: json['title'] as String,
    homeLocale: (json['homeLocale'] as String?) ?? 'es-MX',
    learningLocale: (json['learningLocale'] as String?) ?? 'en-US',
    voiceId: json['voiceId'] as String?,
    speechRate: ((json['speechRate'] as num?) ?? 0.45).toDouble(),
    lastParagraph: (json['lastParagraph'] as int?) ?? 0,
    lastOffset: (json['lastOffset'] as int?) ?? 0,
    createdAt: DateTime.parse(json['createdAt'] as String),
    updatedAt: DateTime.parse(json['updatedAt'] as String),
    contentRevision: (json['contentRevision'] as int?) ?? 0,
    pages: ((json['pages'] as List<dynamic>?) ?? const <dynamic>[])
        .map((item) => SyncPageDto.fromJson(Map<String, dynamic>.from(item as Map)))
        .toList(),
    isDeleted: (json['isDeleted'] as bool?) ?? false,
  );
}

/// Solicitud de subida (push) al backend.
class SyncPushRequest {
  const SyncPushRequest({
    required this.books,
    this.deletedBookIds = const [],
  });

  final List<SyncBookDto> books;
  final List<String> deletedBookIds;

  Map<String, dynamic> toJson() => {
    'books': books.map((b) => b.toJson()).toList(),
    'deletedBookIds': deletedBookIds,
  };

  String toJsonString() => jsonEncode(toJson());

  factory SyncPushRequest.fromJson(Map<String, dynamic> json) => SyncPushRequest(
    books: ((json['books'] as List<dynamic>?) ?? const <dynamic>[])
        .map((item) => SyncBookDto.fromJson(Map<String, dynamic>.from(item as Map)))
        .toList(),
    deletedBookIds: ((json['deletedBookIds'] as List<dynamic>?) ?? const <dynamic>[])
        .map((e) => e.toString())
        .toList(),
  );
}

/// Respuesta de subida (push) devuelta por el backend.
class SyncPushResponse {
  const SyncPushResponse({
    required this.success,
    this.syncedBookIds = const [],
    this.conflicts = const [],
    this.serverTime,
  });

  final bool success;
  final List<String> syncedBookIds;
  final List<SyncBookDto> conflicts;
  final DateTime? serverTime;

  factory SyncPushResponse.fromJson(Map<String, dynamic> json) => SyncPushResponse(
    success: (json['success'] as bool?) ?? true,
    syncedBookIds: ((json['syncedBookIds'] as List<dynamic>?) ?? const <dynamic>[])
        .map((e) => e.toString())
        .toList(),
    conflicts: ((json['conflicts'] as List<dynamic>?) ?? const <dynamic>[])
        .map((item) => SyncBookDto.fromJson(Map<String, dynamic>.from(item as Map)))
        .toList(),
    serverTime: json['serverTime'] != null
        ? DateTime.tryParse(json['serverTime'] as String)
        : null,
  );
}

/// Respuesta de descarga (pull) desde el backend.
class SyncPullResponse {
  const SyncPullResponse({
    required this.books,
    this.deletedBookIds = const [],
    required this.serverTime,
  });

  final List<SyncBookDto> books;
  final List<String> deletedBookIds;
  final DateTime serverTime;

  factory SyncPullResponse.fromJson(Map<String, dynamic> json) => SyncPullResponse(
    books: ((json['books'] as List<dynamic>?) ?? const <dynamic>[])
        .map((item) => SyncBookDto.fromJson(Map<String, dynamic>.from(item as Map)))
        .toList(),
    deletedBookIds: ((json['deletedBookIds'] as List<dynamic>?) ?? const <dynamic>[])
        .map((e) => e.toString())
        .toList(),
    serverTime: DateTime.tryParse(json['serverTime'] as String? ?? '') ?? DateTime.now(),
  );
}

/// Resultado de una sincronización ejecutada por el SyncEngine.
class SyncResult {
  const SyncResult({
    required this.success,
    this.pushedCount = 0,
    this.pulledCount = 0,
    this.deletedCount = 0,
    this.errorMessage,
    this.isGuest = false,
  });

  factory SyncResult.guest() => const SyncResult(
    success: true,
    isGuest: true,
    errorMessage: 'Modo local activo. Conecta una cuenta para respaldar en la nube.',
  );

  factory SyncResult.failure(String message) => SyncResult(
    success: false,
    errorMessage: message,
  );

  final bool success;
  final int pushedCount;
  final int pulledCount;
  final int deletedCount;
  final String? errorMessage;
  final bool isGuest;
}
