// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $BooksTable extends Books with TableInfo<$BooksTable, Book> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BooksTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _learningLocaleMeta = const VerificationMeta(
    'learningLocale',
  );
  @override
  late final GeneratedColumn<String> learningLocale = GeneratedColumn<String>(
    'learning_locale',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('en-US'),
  );
  static const VerificationMeta _homeLocaleMeta = const VerificationMeta(
    'homeLocale',
  );
  @override
  late final GeneratedColumn<String> homeLocale = GeneratedColumn<String>(
    'home_locale',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('es-MX'),
  );
  static const VerificationMeta _voiceIdMeta = const VerificationMeta(
    'voiceId',
  );
  @override
  late final GeneratedColumn<String> voiceId = GeneratedColumn<String>(
    'voice_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _speechRateMeta = const VerificationMeta(
    'speechRate',
  );
  @override
  late final GeneratedColumn<double> speechRate = GeneratedColumn<double>(
    'speech_rate',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0.45),
  );
  static const VerificationMeta _lastParagraphMeta = const VerificationMeta(
    'lastParagraph',
  );
  @override
  late final GeneratedColumn<int> lastParagraph = GeneratedColumn<int>(
    'last_paragraph',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _lastOffsetMeta = const VerificationMeta(
    'lastOffset',
  );
  @override
  late final GeneratedColumn<int> lastOffset = GeneratedColumn<int>(
    'last_offset',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _contentRevisionMeta = const VerificationMeta(
    'contentRevision',
  );
  @override
  late final GeneratedColumn<int> contentRevision = GeneratedColumn<int>(
    'content_revision',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    title,
    learningLocale,
    homeLocale,
    voiceId,
    speechRate,
    lastParagraph,
    lastOffset,
    createdAt,
    updatedAt,
    contentRevision,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'books';
  @override
  VerificationContext validateIntegrity(
    Insertable<Book> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('learning_locale')) {
      context.handle(
        _learningLocaleMeta,
        learningLocale.isAcceptableOrUnknown(
          data['learning_locale']!,
          _learningLocaleMeta,
        ),
      );
    }
    if (data.containsKey('home_locale')) {
      context.handle(
        _homeLocaleMeta,
        homeLocale.isAcceptableOrUnknown(data['home_locale']!, _homeLocaleMeta),
      );
    }
    if (data.containsKey('voice_id')) {
      context.handle(
        _voiceIdMeta,
        voiceId.isAcceptableOrUnknown(data['voice_id']!, _voiceIdMeta),
      );
    }
    if (data.containsKey('speech_rate')) {
      context.handle(
        _speechRateMeta,
        speechRate.isAcceptableOrUnknown(data['speech_rate']!, _speechRateMeta),
      );
    }
    if (data.containsKey('last_paragraph')) {
      context.handle(
        _lastParagraphMeta,
        lastParagraph.isAcceptableOrUnknown(
          data['last_paragraph']!,
          _lastParagraphMeta,
        ),
      );
    }
    if (data.containsKey('last_offset')) {
      context.handle(
        _lastOffsetMeta,
        lastOffset.isAcceptableOrUnknown(data['last_offset']!, _lastOffsetMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('content_revision')) {
      context.handle(
        _contentRevisionMeta,
        contentRevision.isAcceptableOrUnknown(
          data['content_revision']!,
          _contentRevisionMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Book map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Book(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      learningLocale: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}learning_locale'],
      )!,
      homeLocale: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}home_locale'],
      )!,
      voiceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}voice_id'],
      ),
      speechRate: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}speech_rate'],
      )!,
      lastParagraph: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}last_paragraph'],
      )!,
      lastOffset: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}last_offset'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      contentRevision: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}content_revision'],
      )!,
    );
  }

  @override
  $BooksTable createAlias(String alias) {
    return $BooksTable(attachedDatabase, alias);
  }
}

class Book extends DataClass implements Insertable<Book> {
  final String id;
  final String title;
  final String learningLocale;
  final String homeLocale;
  final String? voiceId;
  final double speechRate;
  final int lastParagraph;
  final int lastOffset;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int contentRevision;
  const Book({
    required this.id,
    required this.title,
    required this.learningLocale,
    required this.homeLocale,
    this.voiceId,
    required this.speechRate,
    required this.lastParagraph,
    required this.lastOffset,
    required this.createdAt,
    required this.updatedAt,
    required this.contentRevision,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['title'] = Variable<String>(title);
    map['learning_locale'] = Variable<String>(learningLocale);
    map['home_locale'] = Variable<String>(homeLocale);
    if (!nullToAbsent || voiceId != null) {
      map['voice_id'] = Variable<String>(voiceId);
    }
    map['speech_rate'] = Variable<double>(speechRate);
    map['last_paragraph'] = Variable<int>(lastParagraph);
    map['last_offset'] = Variable<int>(lastOffset);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    map['content_revision'] = Variable<int>(contentRevision);
    return map;
  }

  BooksCompanion toCompanion(bool nullToAbsent) {
    return BooksCompanion(
      id: Value(id),
      title: Value(title),
      learningLocale: Value(learningLocale),
      homeLocale: Value(homeLocale),
      voiceId: voiceId == null && nullToAbsent
          ? const Value.absent()
          : Value(voiceId),
      speechRate: Value(speechRate),
      lastParagraph: Value(lastParagraph),
      lastOffset: Value(lastOffset),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      contentRevision: Value(contentRevision),
    );
  }

  factory Book.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Book(
      id: serializer.fromJson<String>(json['id']),
      title: serializer.fromJson<String>(json['title']),
      learningLocale: serializer.fromJson<String>(json['learningLocale']),
      homeLocale: serializer.fromJson<String>(json['homeLocale']),
      voiceId: serializer.fromJson<String?>(json['voiceId']),
      speechRate: serializer.fromJson<double>(json['speechRate']),
      lastParagraph: serializer.fromJson<int>(json['lastParagraph']),
      lastOffset: serializer.fromJson<int>(json['lastOffset']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      contentRevision: serializer.fromJson<int>(json['contentRevision']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'title': serializer.toJson<String>(title),
      'learningLocale': serializer.toJson<String>(learningLocale),
      'homeLocale': serializer.toJson<String>(homeLocale),
      'voiceId': serializer.toJson<String?>(voiceId),
      'speechRate': serializer.toJson<double>(speechRate),
      'lastParagraph': serializer.toJson<int>(lastParagraph),
      'lastOffset': serializer.toJson<int>(lastOffset),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'contentRevision': serializer.toJson<int>(contentRevision),
    };
  }

  Book copyWith({
    String? id,
    String? title,
    String? learningLocale,
    String? homeLocale,
    Value<String?> voiceId = const Value.absent(),
    double? speechRate,
    int? lastParagraph,
    int? lastOffset,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? contentRevision,
  }) => Book(
    id: id ?? this.id,
    title: title ?? this.title,
    learningLocale: learningLocale ?? this.learningLocale,
    homeLocale: homeLocale ?? this.homeLocale,
    voiceId: voiceId.present ? voiceId.value : this.voiceId,
    speechRate: speechRate ?? this.speechRate,
    lastParagraph: lastParagraph ?? this.lastParagraph,
    lastOffset: lastOffset ?? this.lastOffset,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    contentRevision: contentRevision ?? this.contentRevision,
  );
  Book copyWithCompanion(BooksCompanion data) {
    return Book(
      id: data.id.present ? data.id.value : this.id,
      title: data.title.present ? data.title.value : this.title,
      learningLocale: data.learningLocale.present
          ? data.learningLocale.value
          : this.learningLocale,
      homeLocale: data.homeLocale.present
          ? data.homeLocale.value
          : this.homeLocale,
      voiceId: data.voiceId.present ? data.voiceId.value : this.voiceId,
      speechRate: data.speechRate.present
          ? data.speechRate.value
          : this.speechRate,
      lastParagraph: data.lastParagraph.present
          ? data.lastParagraph.value
          : this.lastParagraph,
      lastOffset: data.lastOffset.present
          ? data.lastOffset.value
          : this.lastOffset,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      contentRevision: data.contentRevision.present
          ? data.contentRevision.value
          : this.contentRevision,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Book(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('learningLocale: $learningLocale, ')
          ..write('homeLocale: $homeLocale, ')
          ..write('voiceId: $voiceId, ')
          ..write('speechRate: $speechRate, ')
          ..write('lastParagraph: $lastParagraph, ')
          ..write('lastOffset: $lastOffset, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('contentRevision: $contentRevision')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    title,
    learningLocale,
    homeLocale,
    voiceId,
    speechRate,
    lastParagraph,
    lastOffset,
    createdAt,
    updatedAt,
    contentRevision,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Book &&
          other.id == this.id &&
          other.title == this.title &&
          other.learningLocale == this.learningLocale &&
          other.homeLocale == this.homeLocale &&
          other.voiceId == this.voiceId &&
          other.speechRate == this.speechRate &&
          other.lastParagraph == this.lastParagraph &&
          other.lastOffset == this.lastOffset &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.contentRevision == this.contentRevision);
}

class BooksCompanion extends UpdateCompanion<Book> {
  final Value<String> id;
  final Value<String> title;
  final Value<String> learningLocale;
  final Value<String> homeLocale;
  final Value<String?> voiceId;
  final Value<double> speechRate;
  final Value<int> lastParagraph;
  final Value<int> lastOffset;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> contentRevision;
  final Value<int> rowid;
  const BooksCompanion({
    this.id = const Value.absent(),
    this.title = const Value.absent(),
    this.learningLocale = const Value.absent(),
    this.homeLocale = const Value.absent(),
    this.voiceId = const Value.absent(),
    this.speechRate = const Value.absent(),
    this.lastParagraph = const Value.absent(),
    this.lastOffset = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.contentRevision = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  BooksCompanion.insert({
    required String id,
    required String title,
    this.learningLocale = const Value.absent(),
    this.homeLocale = const Value.absent(),
    this.voiceId = const Value.absent(),
    this.speechRate = const Value.absent(),
    this.lastParagraph = const Value.absent(),
    this.lastOffset = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.contentRevision = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       title = Value(title),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<Book> custom({
    Expression<String>? id,
    Expression<String>? title,
    Expression<String>? learningLocale,
    Expression<String>? homeLocale,
    Expression<String>? voiceId,
    Expression<double>? speechRate,
    Expression<int>? lastParagraph,
    Expression<int>? lastOffset,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? contentRevision,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (title != null) 'title': title,
      if (learningLocale != null) 'learning_locale': learningLocale,
      if (homeLocale != null) 'home_locale': homeLocale,
      if (voiceId != null) 'voice_id': voiceId,
      if (speechRate != null) 'speech_rate': speechRate,
      if (lastParagraph != null) 'last_paragraph': lastParagraph,
      if (lastOffset != null) 'last_offset': lastOffset,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (contentRevision != null) 'content_revision': contentRevision,
      if (rowid != null) 'rowid': rowid,
    });
  }

  BooksCompanion copyWith({
    Value<String>? id,
    Value<String>? title,
    Value<String>? learningLocale,
    Value<String>? homeLocale,
    Value<String?>? voiceId,
    Value<double>? speechRate,
    Value<int>? lastParagraph,
    Value<int>? lastOffset,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? contentRevision,
    Value<int>? rowid,
  }) {
    return BooksCompanion(
      id: id ?? this.id,
      title: title ?? this.title,
      learningLocale: learningLocale ?? this.learningLocale,
      homeLocale: homeLocale ?? this.homeLocale,
      voiceId: voiceId ?? this.voiceId,
      speechRate: speechRate ?? this.speechRate,
      lastParagraph: lastParagraph ?? this.lastParagraph,
      lastOffset: lastOffset ?? this.lastOffset,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      contentRevision: contentRevision ?? this.contentRevision,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (learningLocale.present) {
      map['learning_locale'] = Variable<String>(learningLocale.value);
    }
    if (homeLocale.present) {
      map['home_locale'] = Variable<String>(homeLocale.value);
    }
    if (voiceId.present) {
      map['voice_id'] = Variable<String>(voiceId.value);
    }
    if (speechRate.present) {
      map['speech_rate'] = Variable<double>(speechRate.value);
    }
    if (lastParagraph.present) {
      map['last_paragraph'] = Variable<int>(lastParagraph.value);
    }
    if (lastOffset.present) {
      map['last_offset'] = Variable<int>(lastOffset.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (contentRevision.present) {
      map['content_revision'] = Variable<int>(contentRevision.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BooksCompanion(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('learningLocale: $learningLocale, ')
          ..write('homeLocale: $homeLocale, ')
          ..write('voiceId: $voiceId, ')
          ..write('speechRate: $speechRate, ')
          ..write('lastParagraph: $lastParagraph, ')
          ..write('lastOffset: $lastOffset, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('contentRevision: $contentRevision, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PagesTable extends Pages with TableInfo<$PagesTable, Page> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PagesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _bookIdMeta = const VerificationMeta('bookId');
  @override
  late final GeneratedColumn<String> bookId = GeneratedColumn<String>(
    'book_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _orderKeyMeta = const VerificationMeta(
    'orderKey',
  );
  @override
  late final GeneratedColumn<int> orderKey = GeneratedColumn<int>(
    'order_key',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _originalPathMeta = const VerificationMeta(
    'originalPath',
  );
  @override
  late final GeneratedColumn<String> originalPath = GeneratedColumn<String>(
    'original_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _derivedPathMeta = const VerificationMeta(
    'derivedPath',
  );
  @override
  late final GeneratedColumn<String> derivedPath = GeneratedColumn<String>(
    'derived_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('pending'),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    bookId,
    orderKey,
    originalPath,
    derivedPath,
    status,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'pages';
  @override
  VerificationContext validateIntegrity(
    Insertable<Page> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('book_id')) {
      context.handle(
        _bookIdMeta,
        bookId.isAcceptableOrUnknown(data['book_id']!, _bookIdMeta),
      );
    } else if (isInserting) {
      context.missing(_bookIdMeta);
    }
    if (data.containsKey('order_key')) {
      context.handle(
        _orderKeyMeta,
        orderKey.isAcceptableOrUnknown(data['order_key']!, _orderKeyMeta),
      );
    } else if (isInserting) {
      context.missing(_orderKeyMeta);
    }
    if (data.containsKey('original_path')) {
      context.handle(
        _originalPathMeta,
        originalPath.isAcceptableOrUnknown(
          data['original_path']!,
          _originalPathMeta,
        ),
      );
    }
    if (data.containsKey('derived_path')) {
      context.handle(
        _derivedPathMeta,
        derivedPath.isAcceptableOrUnknown(
          data['derived_path']!,
          _derivedPathMeta,
        ),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Page map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Page(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      bookId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}book_id'],
      )!,
      orderKey: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}order_key'],
      )!,
      originalPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}original_path'],
      ),
      derivedPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}derived_path'],
      ),
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $PagesTable createAlias(String alias) {
    return $PagesTable(attachedDatabase, alias);
  }
}

class Page extends DataClass implements Insertable<Page> {
  final String id;
  final String bookId;
  final int orderKey;
  final String? originalPath;
  final String? derivedPath;
  final String status;
  final DateTime createdAt;
  const Page({
    required this.id,
    required this.bookId,
    required this.orderKey,
    this.originalPath,
    this.derivedPath,
    required this.status,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['book_id'] = Variable<String>(bookId);
    map['order_key'] = Variable<int>(orderKey);
    if (!nullToAbsent || originalPath != null) {
      map['original_path'] = Variable<String>(originalPath);
    }
    if (!nullToAbsent || derivedPath != null) {
      map['derived_path'] = Variable<String>(derivedPath);
    }
    map['status'] = Variable<String>(status);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  PagesCompanion toCompanion(bool nullToAbsent) {
    return PagesCompanion(
      id: Value(id),
      bookId: Value(bookId),
      orderKey: Value(orderKey),
      originalPath: originalPath == null && nullToAbsent
          ? const Value.absent()
          : Value(originalPath),
      derivedPath: derivedPath == null && nullToAbsent
          ? const Value.absent()
          : Value(derivedPath),
      status: Value(status),
      createdAt: Value(createdAt),
    );
  }

  factory Page.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Page(
      id: serializer.fromJson<String>(json['id']),
      bookId: serializer.fromJson<String>(json['bookId']),
      orderKey: serializer.fromJson<int>(json['orderKey']),
      originalPath: serializer.fromJson<String?>(json['originalPath']),
      derivedPath: serializer.fromJson<String?>(json['derivedPath']),
      status: serializer.fromJson<String>(json['status']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'bookId': serializer.toJson<String>(bookId),
      'orderKey': serializer.toJson<int>(orderKey),
      'originalPath': serializer.toJson<String?>(originalPath),
      'derivedPath': serializer.toJson<String?>(derivedPath),
      'status': serializer.toJson<String>(status),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  Page copyWith({
    String? id,
    String? bookId,
    int? orderKey,
    Value<String?> originalPath = const Value.absent(),
    Value<String?> derivedPath = const Value.absent(),
    String? status,
    DateTime? createdAt,
  }) => Page(
    id: id ?? this.id,
    bookId: bookId ?? this.bookId,
    orderKey: orderKey ?? this.orderKey,
    originalPath: originalPath.present ? originalPath.value : this.originalPath,
    derivedPath: derivedPath.present ? derivedPath.value : this.derivedPath,
    status: status ?? this.status,
    createdAt: createdAt ?? this.createdAt,
  );
  Page copyWithCompanion(PagesCompanion data) {
    return Page(
      id: data.id.present ? data.id.value : this.id,
      bookId: data.bookId.present ? data.bookId.value : this.bookId,
      orderKey: data.orderKey.present ? data.orderKey.value : this.orderKey,
      originalPath: data.originalPath.present
          ? data.originalPath.value
          : this.originalPath,
      derivedPath: data.derivedPath.present
          ? data.derivedPath.value
          : this.derivedPath,
      status: data.status.present ? data.status.value : this.status,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Page(')
          ..write('id: $id, ')
          ..write('bookId: $bookId, ')
          ..write('orderKey: $orderKey, ')
          ..write('originalPath: $originalPath, ')
          ..write('derivedPath: $derivedPath, ')
          ..write('status: $status, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    bookId,
    orderKey,
    originalPath,
    derivedPath,
    status,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Page &&
          other.id == this.id &&
          other.bookId == this.bookId &&
          other.orderKey == this.orderKey &&
          other.originalPath == this.originalPath &&
          other.derivedPath == this.derivedPath &&
          other.status == this.status &&
          other.createdAt == this.createdAt);
}

class PagesCompanion extends UpdateCompanion<Page> {
  final Value<String> id;
  final Value<String> bookId;
  final Value<int> orderKey;
  final Value<String?> originalPath;
  final Value<String?> derivedPath;
  final Value<String> status;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const PagesCompanion({
    this.id = const Value.absent(),
    this.bookId = const Value.absent(),
    this.orderKey = const Value.absent(),
    this.originalPath = const Value.absent(),
    this.derivedPath = const Value.absent(),
    this.status = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PagesCompanion.insert({
    required String id,
    required String bookId,
    required int orderKey,
    this.originalPath = const Value.absent(),
    this.derivedPath = const Value.absent(),
    this.status = const Value.absent(),
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       bookId = Value(bookId),
       orderKey = Value(orderKey),
       createdAt = Value(createdAt);
  static Insertable<Page> custom({
    Expression<String>? id,
    Expression<String>? bookId,
    Expression<int>? orderKey,
    Expression<String>? originalPath,
    Expression<String>? derivedPath,
    Expression<String>? status,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (bookId != null) 'book_id': bookId,
      if (orderKey != null) 'order_key': orderKey,
      if (originalPath != null) 'original_path': originalPath,
      if (derivedPath != null) 'derived_path': derivedPath,
      if (status != null) 'status': status,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PagesCompanion copyWith({
    Value<String>? id,
    Value<String>? bookId,
    Value<int>? orderKey,
    Value<String?>? originalPath,
    Value<String?>? derivedPath,
    Value<String>? status,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return PagesCompanion(
      id: id ?? this.id,
      bookId: bookId ?? this.bookId,
      orderKey: orderKey ?? this.orderKey,
      originalPath: originalPath ?? this.originalPath,
      derivedPath: derivedPath ?? this.derivedPath,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (bookId.present) {
      map['book_id'] = Variable<String>(bookId.value);
    }
    if (orderKey.present) {
      map['order_key'] = Variable<int>(orderKey.value);
    }
    if (originalPath.present) {
      map['original_path'] = Variable<String>(originalPath.value);
    }
    if (derivedPath.present) {
      map['derived_path'] = Variable<String>(derivedPath.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PagesCompanion(')
          ..write('id: $id, ')
          ..write('bookId: $bookId, ')
          ..write('orderKey: $orderKey, ')
          ..write('originalPath: $originalPath, ')
          ..write('derivedPath: $derivedPath, ')
          ..write('status: $status, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ParagraphsTable extends Paragraphs
    with TableInfo<$ParagraphsTable, Paragraph> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ParagraphsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _bookIdMeta = const VerificationMeta('bookId');
  @override
  late final GeneratedColumn<String> bookId = GeneratedColumn<String>(
    'book_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _pageIdMeta = const VerificationMeta('pageId');
  @override
  late final GeneratedColumn<String> pageId = GeneratedColumn<String>(
    'page_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _orderKeyMeta = const VerificationMeta(
    'orderKey',
  );
  @override
  late final GeneratedColumn<int> orderKey = GeneratedColumn<int>(
    'order_key',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _contentMeta = const VerificationMeta(
    'content',
  );
  @override
  late final GeneratedColumn<String> content = GeneratedColumn<String>(
    'content',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _localeOverrideMeta = const VerificationMeta(
    'localeOverride',
  );
  @override
  late final GeneratedColumn<String> localeOverride = GeneratedColumn<String>(
    'locale_override',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _textRevisionMeta = const VerificationMeta(
    'textRevision',
  );
  @override
  late final GeneratedColumn<int> textRevision = GeneratedColumn<int>(
    'text_revision',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    bookId,
    pageId,
    orderKey,
    content,
    localeOverride,
    textRevision,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'paragraphs';
  @override
  VerificationContext validateIntegrity(
    Insertable<Paragraph> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('book_id')) {
      context.handle(
        _bookIdMeta,
        bookId.isAcceptableOrUnknown(data['book_id']!, _bookIdMeta),
      );
    } else if (isInserting) {
      context.missing(_bookIdMeta);
    }
    if (data.containsKey('page_id')) {
      context.handle(
        _pageIdMeta,
        pageId.isAcceptableOrUnknown(data['page_id']!, _pageIdMeta),
      );
    } else if (isInserting) {
      context.missing(_pageIdMeta);
    }
    if (data.containsKey('order_key')) {
      context.handle(
        _orderKeyMeta,
        orderKey.isAcceptableOrUnknown(data['order_key']!, _orderKeyMeta),
      );
    } else if (isInserting) {
      context.missing(_orderKeyMeta);
    }
    if (data.containsKey('content')) {
      context.handle(
        _contentMeta,
        content.isAcceptableOrUnknown(data['content']!, _contentMeta),
      );
    } else if (isInserting) {
      context.missing(_contentMeta);
    }
    if (data.containsKey('locale_override')) {
      context.handle(
        _localeOverrideMeta,
        localeOverride.isAcceptableOrUnknown(
          data['locale_override']!,
          _localeOverrideMeta,
        ),
      );
    }
    if (data.containsKey('text_revision')) {
      context.handle(
        _textRevisionMeta,
        textRevision.isAcceptableOrUnknown(
          data['text_revision']!,
          _textRevisionMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Paragraph map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Paragraph(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      bookId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}book_id'],
      )!,
      pageId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}page_id'],
      )!,
      orderKey: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}order_key'],
      )!,
      content: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}content'],
      )!,
      localeOverride: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}locale_override'],
      ),
      textRevision: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}text_revision'],
      )!,
    );
  }

  @override
  $ParagraphsTable createAlias(String alias) {
    return $ParagraphsTable(attachedDatabase, alias);
  }
}

class Paragraph extends DataClass implements Insertable<Paragraph> {
  final String id;
  final String bookId;
  final String pageId;
  final int orderKey;
  final String content;
  final String? localeOverride;
  final int textRevision;
  const Paragraph({
    required this.id,
    required this.bookId,
    required this.pageId,
    required this.orderKey,
    required this.content,
    this.localeOverride,
    required this.textRevision,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['book_id'] = Variable<String>(bookId);
    map['page_id'] = Variable<String>(pageId);
    map['order_key'] = Variable<int>(orderKey);
    map['content'] = Variable<String>(content);
    if (!nullToAbsent || localeOverride != null) {
      map['locale_override'] = Variable<String>(localeOverride);
    }
    map['text_revision'] = Variable<int>(textRevision);
    return map;
  }

  ParagraphsCompanion toCompanion(bool nullToAbsent) {
    return ParagraphsCompanion(
      id: Value(id),
      bookId: Value(bookId),
      pageId: Value(pageId),
      orderKey: Value(orderKey),
      content: Value(content),
      localeOverride: localeOverride == null && nullToAbsent
          ? const Value.absent()
          : Value(localeOverride),
      textRevision: Value(textRevision),
    );
  }

  factory Paragraph.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Paragraph(
      id: serializer.fromJson<String>(json['id']),
      bookId: serializer.fromJson<String>(json['bookId']),
      pageId: serializer.fromJson<String>(json['pageId']),
      orderKey: serializer.fromJson<int>(json['orderKey']),
      content: serializer.fromJson<String>(json['content']),
      localeOverride: serializer.fromJson<String?>(json['localeOverride']),
      textRevision: serializer.fromJson<int>(json['textRevision']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'bookId': serializer.toJson<String>(bookId),
      'pageId': serializer.toJson<String>(pageId),
      'orderKey': serializer.toJson<int>(orderKey),
      'content': serializer.toJson<String>(content),
      'localeOverride': serializer.toJson<String?>(localeOverride),
      'textRevision': serializer.toJson<int>(textRevision),
    };
  }

  Paragraph copyWith({
    String? id,
    String? bookId,
    String? pageId,
    int? orderKey,
    String? content,
    Value<String?> localeOverride = const Value.absent(),
    int? textRevision,
  }) => Paragraph(
    id: id ?? this.id,
    bookId: bookId ?? this.bookId,
    pageId: pageId ?? this.pageId,
    orderKey: orderKey ?? this.orderKey,
    content: content ?? this.content,
    localeOverride: localeOverride.present
        ? localeOverride.value
        : this.localeOverride,
    textRevision: textRevision ?? this.textRevision,
  );
  Paragraph copyWithCompanion(ParagraphsCompanion data) {
    return Paragraph(
      id: data.id.present ? data.id.value : this.id,
      bookId: data.bookId.present ? data.bookId.value : this.bookId,
      pageId: data.pageId.present ? data.pageId.value : this.pageId,
      orderKey: data.orderKey.present ? data.orderKey.value : this.orderKey,
      content: data.content.present ? data.content.value : this.content,
      localeOverride: data.localeOverride.present
          ? data.localeOverride.value
          : this.localeOverride,
      textRevision: data.textRevision.present
          ? data.textRevision.value
          : this.textRevision,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Paragraph(')
          ..write('id: $id, ')
          ..write('bookId: $bookId, ')
          ..write('pageId: $pageId, ')
          ..write('orderKey: $orderKey, ')
          ..write('content: $content, ')
          ..write('localeOverride: $localeOverride, ')
          ..write('textRevision: $textRevision')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    bookId,
    pageId,
    orderKey,
    content,
    localeOverride,
    textRevision,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Paragraph &&
          other.id == this.id &&
          other.bookId == this.bookId &&
          other.pageId == this.pageId &&
          other.orderKey == this.orderKey &&
          other.content == this.content &&
          other.localeOverride == this.localeOverride &&
          other.textRevision == this.textRevision);
}

class ParagraphsCompanion extends UpdateCompanion<Paragraph> {
  final Value<String> id;
  final Value<String> bookId;
  final Value<String> pageId;
  final Value<int> orderKey;
  final Value<String> content;
  final Value<String?> localeOverride;
  final Value<int> textRevision;
  final Value<int> rowid;
  const ParagraphsCompanion({
    this.id = const Value.absent(),
    this.bookId = const Value.absent(),
    this.pageId = const Value.absent(),
    this.orderKey = const Value.absent(),
    this.content = const Value.absent(),
    this.localeOverride = const Value.absent(),
    this.textRevision = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ParagraphsCompanion.insert({
    required String id,
    required String bookId,
    required String pageId,
    required int orderKey,
    required String content,
    this.localeOverride = const Value.absent(),
    this.textRevision = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       bookId = Value(bookId),
       pageId = Value(pageId),
       orderKey = Value(orderKey),
       content = Value(content);
  static Insertable<Paragraph> custom({
    Expression<String>? id,
    Expression<String>? bookId,
    Expression<String>? pageId,
    Expression<int>? orderKey,
    Expression<String>? content,
    Expression<String>? localeOverride,
    Expression<int>? textRevision,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (bookId != null) 'book_id': bookId,
      if (pageId != null) 'page_id': pageId,
      if (orderKey != null) 'order_key': orderKey,
      if (content != null) 'content': content,
      if (localeOverride != null) 'locale_override': localeOverride,
      if (textRevision != null) 'text_revision': textRevision,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ParagraphsCompanion copyWith({
    Value<String>? id,
    Value<String>? bookId,
    Value<String>? pageId,
    Value<int>? orderKey,
    Value<String>? content,
    Value<String?>? localeOverride,
    Value<int>? textRevision,
    Value<int>? rowid,
  }) {
    return ParagraphsCompanion(
      id: id ?? this.id,
      bookId: bookId ?? this.bookId,
      pageId: pageId ?? this.pageId,
      orderKey: orderKey ?? this.orderKey,
      content: content ?? this.content,
      localeOverride: localeOverride ?? this.localeOverride,
      textRevision: textRevision ?? this.textRevision,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (bookId.present) {
      map['book_id'] = Variable<String>(bookId.value);
    }
    if (pageId.present) {
      map['page_id'] = Variable<String>(pageId.value);
    }
    if (orderKey.present) {
      map['order_key'] = Variable<int>(orderKey.value);
    }
    if (content.present) {
      map['content'] = Variable<String>(content.value);
    }
    if (localeOverride.present) {
      map['locale_override'] = Variable<String>(localeOverride.value);
    }
    if (textRevision.present) {
      map['text_revision'] = Variable<int>(textRevision.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ParagraphsCompanion(')
          ..write('id: $id, ')
          ..write('bookId: $bookId, ')
          ..write('pageId: $pageId, ')
          ..write('orderKey: $orderKey, ')
          ..write('content: $content, ')
          ..write('localeOverride: $localeOverride, ')
          ..write('textRevision: $textRevision, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ImportJobsTable extends ImportJobs
    with TableInfo<$ImportJobsTable, ImportJob> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ImportJobsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _bookIdMeta = const VerificationMeta('bookId');
  @override
  late final GeneratedColumn<String> bookId = GeneratedColumn<String>(
    'book_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _pageIdMeta = const VerificationMeta('pageId');
  @override
  late final GeneratedColumn<String> pageId = GeneratedColumn<String>(
    'page_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _imagePathMeta = const VerificationMeta(
    'imagePath',
  );
  @override
  late final GeneratedColumn<String> imagePath = GeneratedColumn<String>(
    'image_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _stateMeta = const VerificationMeta('state');
  @override
  late final GeneratedColumn<String> state = GeneratedColumn<String>(
    'state',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('queued'),
  );
  static const VerificationMeta _attemptsMeta = const VerificationMeta(
    'attempts',
  );
  @override
  late final GeneratedColumn<int> attempts = GeneratedColumn<int>(
    'attempts',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _errorCodeMeta = const VerificationMeta(
    'errorCode',
  );
  @override
  late final GeneratedColumn<String> errorCode = GeneratedColumn<String>(
    'error_code',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    bookId,
    pageId,
    imagePath,
    state,
    attempts,
    errorCode,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'import_jobs';
  @override
  VerificationContext validateIntegrity(
    Insertable<ImportJob> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('book_id')) {
      context.handle(
        _bookIdMeta,
        bookId.isAcceptableOrUnknown(data['book_id']!, _bookIdMeta),
      );
    } else if (isInserting) {
      context.missing(_bookIdMeta);
    }
    if (data.containsKey('page_id')) {
      context.handle(
        _pageIdMeta,
        pageId.isAcceptableOrUnknown(data['page_id']!, _pageIdMeta),
      );
    } else if (isInserting) {
      context.missing(_pageIdMeta);
    }
    if (data.containsKey('image_path')) {
      context.handle(
        _imagePathMeta,
        imagePath.isAcceptableOrUnknown(data['image_path']!, _imagePathMeta),
      );
    }
    if (data.containsKey('state')) {
      context.handle(
        _stateMeta,
        state.isAcceptableOrUnknown(data['state']!, _stateMeta),
      );
    }
    if (data.containsKey('attempts')) {
      context.handle(
        _attemptsMeta,
        attempts.isAcceptableOrUnknown(data['attempts']!, _attemptsMeta),
      );
    }
    if (data.containsKey('error_code')) {
      context.handle(
        _errorCodeMeta,
        errorCode.isAcceptableOrUnknown(data['error_code']!, _errorCodeMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ImportJob map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ImportJob(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      bookId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}book_id'],
      )!,
      pageId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}page_id'],
      )!,
      imagePath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}image_path'],
      ),
      state: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}state'],
      )!,
      attempts: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}attempts'],
      )!,
      errorCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}error_code'],
      ),
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $ImportJobsTable createAlias(String alias) {
    return $ImportJobsTable(attachedDatabase, alias);
  }
}

class ImportJob extends DataClass implements Insertable<ImportJob> {
  final String id;
  final String bookId;
  final String pageId;
  final String? imagePath;
  final String state;
  final int attempts;
  final String? errorCode;
  final DateTime updatedAt;
  const ImportJob({
    required this.id,
    required this.bookId,
    required this.pageId,
    this.imagePath,
    required this.state,
    required this.attempts,
    this.errorCode,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['book_id'] = Variable<String>(bookId);
    map['page_id'] = Variable<String>(pageId);
    if (!nullToAbsent || imagePath != null) {
      map['image_path'] = Variable<String>(imagePath);
    }
    map['state'] = Variable<String>(state);
    map['attempts'] = Variable<int>(attempts);
    if (!nullToAbsent || errorCode != null) {
      map['error_code'] = Variable<String>(errorCode);
    }
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  ImportJobsCompanion toCompanion(bool nullToAbsent) {
    return ImportJobsCompanion(
      id: Value(id),
      bookId: Value(bookId),
      pageId: Value(pageId),
      imagePath: imagePath == null && nullToAbsent
          ? const Value.absent()
          : Value(imagePath),
      state: Value(state),
      attempts: Value(attempts),
      errorCode: errorCode == null && nullToAbsent
          ? const Value.absent()
          : Value(errorCode),
      updatedAt: Value(updatedAt),
    );
  }

  factory ImportJob.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ImportJob(
      id: serializer.fromJson<String>(json['id']),
      bookId: serializer.fromJson<String>(json['bookId']),
      pageId: serializer.fromJson<String>(json['pageId']),
      imagePath: serializer.fromJson<String?>(json['imagePath']),
      state: serializer.fromJson<String>(json['state']),
      attempts: serializer.fromJson<int>(json['attempts']),
      errorCode: serializer.fromJson<String?>(json['errorCode']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'bookId': serializer.toJson<String>(bookId),
      'pageId': serializer.toJson<String>(pageId),
      'imagePath': serializer.toJson<String?>(imagePath),
      'state': serializer.toJson<String>(state),
      'attempts': serializer.toJson<int>(attempts),
      'errorCode': serializer.toJson<String?>(errorCode),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  ImportJob copyWith({
    String? id,
    String? bookId,
    String? pageId,
    Value<String?> imagePath = const Value.absent(),
    String? state,
    int? attempts,
    Value<String?> errorCode = const Value.absent(),
    DateTime? updatedAt,
  }) => ImportJob(
    id: id ?? this.id,
    bookId: bookId ?? this.bookId,
    pageId: pageId ?? this.pageId,
    imagePath: imagePath.present ? imagePath.value : this.imagePath,
    state: state ?? this.state,
    attempts: attempts ?? this.attempts,
    errorCode: errorCode.present ? errorCode.value : this.errorCode,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  ImportJob copyWithCompanion(ImportJobsCompanion data) {
    return ImportJob(
      id: data.id.present ? data.id.value : this.id,
      bookId: data.bookId.present ? data.bookId.value : this.bookId,
      pageId: data.pageId.present ? data.pageId.value : this.pageId,
      imagePath: data.imagePath.present ? data.imagePath.value : this.imagePath,
      state: data.state.present ? data.state.value : this.state,
      attempts: data.attempts.present ? data.attempts.value : this.attempts,
      errorCode: data.errorCode.present ? data.errorCode.value : this.errorCode,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ImportJob(')
          ..write('id: $id, ')
          ..write('bookId: $bookId, ')
          ..write('pageId: $pageId, ')
          ..write('imagePath: $imagePath, ')
          ..write('state: $state, ')
          ..write('attempts: $attempts, ')
          ..write('errorCode: $errorCode, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    bookId,
    pageId,
    imagePath,
    state,
    attempts,
    errorCode,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ImportJob &&
          other.id == this.id &&
          other.bookId == this.bookId &&
          other.pageId == this.pageId &&
          other.imagePath == this.imagePath &&
          other.state == this.state &&
          other.attempts == this.attempts &&
          other.errorCode == this.errorCode &&
          other.updatedAt == this.updatedAt);
}

class ImportJobsCompanion extends UpdateCompanion<ImportJob> {
  final Value<String> id;
  final Value<String> bookId;
  final Value<String> pageId;
  final Value<String?> imagePath;
  final Value<String> state;
  final Value<int> attempts;
  final Value<String?> errorCode;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const ImportJobsCompanion({
    this.id = const Value.absent(),
    this.bookId = const Value.absent(),
    this.pageId = const Value.absent(),
    this.imagePath = const Value.absent(),
    this.state = const Value.absent(),
    this.attempts = const Value.absent(),
    this.errorCode = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ImportJobsCompanion.insert({
    required String id,
    required String bookId,
    required String pageId,
    this.imagePath = const Value.absent(),
    this.state = const Value.absent(),
    this.attempts = const Value.absent(),
    this.errorCode = const Value.absent(),
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       bookId = Value(bookId),
       pageId = Value(pageId),
       updatedAt = Value(updatedAt);
  static Insertable<ImportJob> custom({
    Expression<String>? id,
    Expression<String>? bookId,
    Expression<String>? pageId,
    Expression<String>? imagePath,
    Expression<String>? state,
    Expression<int>? attempts,
    Expression<String>? errorCode,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (bookId != null) 'book_id': bookId,
      if (pageId != null) 'page_id': pageId,
      if (imagePath != null) 'image_path': imagePath,
      if (state != null) 'state': state,
      if (attempts != null) 'attempts': attempts,
      if (errorCode != null) 'error_code': errorCode,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ImportJobsCompanion copyWith({
    Value<String>? id,
    Value<String>? bookId,
    Value<String>? pageId,
    Value<String?>? imagePath,
    Value<String>? state,
    Value<int>? attempts,
    Value<String?>? errorCode,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return ImportJobsCompanion(
      id: id ?? this.id,
      bookId: bookId ?? this.bookId,
      pageId: pageId ?? this.pageId,
      imagePath: imagePath ?? this.imagePath,
      state: state ?? this.state,
      attempts: attempts ?? this.attempts,
      errorCode: errorCode ?? this.errorCode,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (bookId.present) {
      map['book_id'] = Variable<String>(bookId.value);
    }
    if (pageId.present) {
      map['page_id'] = Variable<String>(pageId.value);
    }
    if (imagePath.present) {
      map['image_path'] = Variable<String>(imagePath.value);
    }
    if (state.present) {
      map['state'] = Variable<String>(state.value);
    }
    if (attempts.present) {
      map['attempts'] = Variable<int>(attempts.value);
    }
    if (errorCode.present) {
      map['error_code'] = Variable<String>(errorCode.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ImportJobsCompanion(')
          ..write('id: $id, ')
          ..write('bookId: $bookId, ')
          ..write('pageId: $pageId, ')
          ..write('imagePath: $imagePath, ')
          ..write('state: $state, ')
          ..write('attempts: $attempts, ')
          ..write('errorCode: $errorCode, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PageDraftsTable extends PageDrafts
    with TableInfo<$PageDraftsTable, PageDraft> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PageDraftsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _bookIdMeta = const VerificationMeta('bookId');
  @override
  late final GeneratedColumn<String> bookId = GeneratedColumn<String>(
    'book_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _pageIdMeta = const VerificationMeta('pageId');
  @override
  late final GeneratedColumn<String> pageId = GeneratedColumn<String>(
    'page_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _jobIdMeta = const VerificationMeta('jobId');
  @override
  late final GeneratedColumn<String> jobId = GeneratedColumn<String>(
    'job_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _rawTextMeta = const VerificationMeta(
    'rawText',
  );
  @override
  late final GeneratedColumn<String> rawText = GeneratedColumn<String>(
    'raw_text',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _paragraphsJsonMeta = const VerificationMeta(
    'paragraphsJson',
  );
  @override
  late final GeneratedColumn<String> paragraphsJson = GeneratedColumn<String>(
    'paragraphs_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _revisionMeta = const VerificationMeta(
    'revision',
  );
  @override
  late final GeneratedColumn<int> revision = GeneratedColumn<int>(
    'revision',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    bookId,
    pageId,
    jobId,
    rawText,
    paragraphsJson,
    revision,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'page_drafts';
  @override
  VerificationContext validateIntegrity(
    Insertable<PageDraft> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('book_id')) {
      context.handle(
        _bookIdMeta,
        bookId.isAcceptableOrUnknown(data['book_id']!, _bookIdMeta),
      );
    } else if (isInserting) {
      context.missing(_bookIdMeta);
    }
    if (data.containsKey('page_id')) {
      context.handle(
        _pageIdMeta,
        pageId.isAcceptableOrUnknown(data['page_id']!, _pageIdMeta),
      );
    } else if (isInserting) {
      context.missing(_pageIdMeta);
    }
    if (data.containsKey('job_id')) {
      context.handle(
        _jobIdMeta,
        jobId.isAcceptableOrUnknown(data['job_id']!, _jobIdMeta),
      );
    } else if (isInserting) {
      context.missing(_jobIdMeta);
    }
    if (data.containsKey('raw_text')) {
      context.handle(
        _rawTextMeta,
        rawText.isAcceptableOrUnknown(data['raw_text']!, _rawTextMeta),
      );
    } else if (isInserting) {
      context.missing(_rawTextMeta);
    }
    if (data.containsKey('paragraphs_json')) {
      context.handle(
        _paragraphsJsonMeta,
        paragraphsJson.isAcceptableOrUnknown(
          data['paragraphs_json']!,
          _paragraphsJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_paragraphsJsonMeta);
    }
    if (data.containsKey('revision')) {
      context.handle(
        _revisionMeta,
        revision.isAcceptableOrUnknown(data['revision']!, _revisionMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PageDraft map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PageDraft(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      bookId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}book_id'],
      )!,
      pageId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}page_id'],
      )!,
      jobId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}job_id'],
      )!,
      rawText: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}raw_text'],
      )!,
      paragraphsJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}paragraphs_json'],
      )!,
      revision: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}revision'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $PageDraftsTable createAlias(String alias) {
    return $PageDraftsTable(attachedDatabase, alias);
  }
}

class PageDraft extends DataClass implements Insertable<PageDraft> {
  final String id;
  final String bookId;
  final String pageId;
  final String jobId;
  final String rawText;
  final String paragraphsJson;
  final int revision;
  final DateTime updatedAt;
  const PageDraft({
    required this.id,
    required this.bookId,
    required this.pageId,
    required this.jobId,
    required this.rawText,
    required this.paragraphsJson,
    required this.revision,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['book_id'] = Variable<String>(bookId);
    map['page_id'] = Variable<String>(pageId);
    map['job_id'] = Variable<String>(jobId);
    map['raw_text'] = Variable<String>(rawText);
    map['paragraphs_json'] = Variable<String>(paragraphsJson);
    map['revision'] = Variable<int>(revision);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  PageDraftsCompanion toCompanion(bool nullToAbsent) {
    return PageDraftsCompanion(
      id: Value(id),
      bookId: Value(bookId),
      pageId: Value(pageId),
      jobId: Value(jobId),
      rawText: Value(rawText),
      paragraphsJson: Value(paragraphsJson),
      revision: Value(revision),
      updatedAt: Value(updatedAt),
    );
  }

  factory PageDraft.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PageDraft(
      id: serializer.fromJson<String>(json['id']),
      bookId: serializer.fromJson<String>(json['bookId']),
      pageId: serializer.fromJson<String>(json['pageId']),
      jobId: serializer.fromJson<String>(json['jobId']),
      rawText: serializer.fromJson<String>(json['rawText']),
      paragraphsJson: serializer.fromJson<String>(json['paragraphsJson']),
      revision: serializer.fromJson<int>(json['revision']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'bookId': serializer.toJson<String>(bookId),
      'pageId': serializer.toJson<String>(pageId),
      'jobId': serializer.toJson<String>(jobId),
      'rawText': serializer.toJson<String>(rawText),
      'paragraphsJson': serializer.toJson<String>(paragraphsJson),
      'revision': serializer.toJson<int>(revision),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  PageDraft copyWith({
    String? id,
    String? bookId,
    String? pageId,
    String? jobId,
    String? rawText,
    String? paragraphsJson,
    int? revision,
    DateTime? updatedAt,
  }) => PageDraft(
    id: id ?? this.id,
    bookId: bookId ?? this.bookId,
    pageId: pageId ?? this.pageId,
    jobId: jobId ?? this.jobId,
    rawText: rawText ?? this.rawText,
    paragraphsJson: paragraphsJson ?? this.paragraphsJson,
    revision: revision ?? this.revision,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  PageDraft copyWithCompanion(PageDraftsCompanion data) {
    return PageDraft(
      id: data.id.present ? data.id.value : this.id,
      bookId: data.bookId.present ? data.bookId.value : this.bookId,
      pageId: data.pageId.present ? data.pageId.value : this.pageId,
      jobId: data.jobId.present ? data.jobId.value : this.jobId,
      rawText: data.rawText.present ? data.rawText.value : this.rawText,
      paragraphsJson: data.paragraphsJson.present
          ? data.paragraphsJson.value
          : this.paragraphsJson,
      revision: data.revision.present ? data.revision.value : this.revision,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PageDraft(')
          ..write('id: $id, ')
          ..write('bookId: $bookId, ')
          ..write('pageId: $pageId, ')
          ..write('jobId: $jobId, ')
          ..write('rawText: $rawText, ')
          ..write('paragraphsJson: $paragraphsJson, ')
          ..write('revision: $revision, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    bookId,
    pageId,
    jobId,
    rawText,
    paragraphsJson,
    revision,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PageDraft &&
          other.id == this.id &&
          other.bookId == this.bookId &&
          other.pageId == this.pageId &&
          other.jobId == this.jobId &&
          other.rawText == this.rawText &&
          other.paragraphsJson == this.paragraphsJson &&
          other.revision == this.revision &&
          other.updatedAt == this.updatedAt);
}

class PageDraftsCompanion extends UpdateCompanion<PageDraft> {
  final Value<String> id;
  final Value<String> bookId;
  final Value<String> pageId;
  final Value<String> jobId;
  final Value<String> rawText;
  final Value<String> paragraphsJson;
  final Value<int> revision;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const PageDraftsCompanion({
    this.id = const Value.absent(),
    this.bookId = const Value.absent(),
    this.pageId = const Value.absent(),
    this.jobId = const Value.absent(),
    this.rawText = const Value.absent(),
    this.paragraphsJson = const Value.absent(),
    this.revision = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PageDraftsCompanion.insert({
    required String id,
    required String bookId,
    required String pageId,
    required String jobId,
    required String rawText,
    required String paragraphsJson,
    this.revision = const Value.absent(),
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       bookId = Value(bookId),
       pageId = Value(pageId),
       jobId = Value(jobId),
       rawText = Value(rawText),
       paragraphsJson = Value(paragraphsJson),
       updatedAt = Value(updatedAt);
  static Insertable<PageDraft> custom({
    Expression<String>? id,
    Expression<String>? bookId,
    Expression<String>? pageId,
    Expression<String>? jobId,
    Expression<String>? rawText,
    Expression<String>? paragraphsJson,
    Expression<int>? revision,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (bookId != null) 'book_id': bookId,
      if (pageId != null) 'page_id': pageId,
      if (jobId != null) 'job_id': jobId,
      if (rawText != null) 'raw_text': rawText,
      if (paragraphsJson != null) 'paragraphs_json': paragraphsJson,
      if (revision != null) 'revision': revision,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PageDraftsCompanion copyWith({
    Value<String>? id,
    Value<String>? bookId,
    Value<String>? pageId,
    Value<String>? jobId,
    Value<String>? rawText,
    Value<String>? paragraphsJson,
    Value<int>? revision,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return PageDraftsCompanion(
      id: id ?? this.id,
      bookId: bookId ?? this.bookId,
      pageId: pageId ?? this.pageId,
      jobId: jobId ?? this.jobId,
      rawText: rawText ?? this.rawText,
      paragraphsJson: paragraphsJson ?? this.paragraphsJson,
      revision: revision ?? this.revision,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (bookId.present) {
      map['book_id'] = Variable<String>(bookId.value);
    }
    if (pageId.present) {
      map['page_id'] = Variable<String>(pageId.value);
    }
    if (jobId.present) {
      map['job_id'] = Variable<String>(jobId.value);
    }
    if (rawText.present) {
      map['raw_text'] = Variable<String>(rawText.value);
    }
    if (paragraphsJson.present) {
      map['paragraphs_json'] = Variable<String>(paragraphsJson.value);
    }
    if (revision.present) {
      map['revision'] = Variable<int>(revision.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PageDraftsCompanion(')
          ..write('id: $id, ')
          ..write('bookId: $bookId, ')
          ..write('pageId: $pageId, ')
          ..write('jobId: $jobId, ')
          ..write('rawText: $rawText, ')
          ..write('paragraphsJson: $paragraphsJson, ')
          ..write('revision: $revision, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $BooksTable books = $BooksTable(this);
  late final $PagesTable pages = $PagesTable(this);
  late final $ParagraphsTable paragraphs = $ParagraphsTable(this);
  late final $ImportJobsTable importJobs = $ImportJobsTable(this);
  late final $PageDraftsTable pageDrafts = $PageDraftsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    books,
    pages,
    paragraphs,
    importJobs,
    pageDrafts,
  ];
}

typedef $$BooksTableCreateCompanionBuilder = BooksCompanion Function({
  required String id,
  required String title,
  Value<String> learningLocale,
  Value<String> homeLocale,
  Value<String?> voiceId,
  Value<double> speechRate,
  Value<int> lastParagraph,
  Value<int> lastOffset,
  required DateTime createdAt,
  required DateTime updatedAt,
  Value<int> contentRevision,
  Value<int> rowid,
});
typedef $$BooksTableUpdateCompanionBuilder = BooksCompanion Function({
  Value<String> id,
  Value<String> title,
  Value<String> learningLocale,
  Value<String> homeLocale,
  Value<String?> voiceId,
  Value<double> speechRate,
  Value<int> lastParagraph,
  Value<int> lastOffset,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<int> contentRevision,
  Value<int> rowid,
});

class $$BooksTableFilterComposer extends Composer<_$AppDatabase, $BooksTable> {
  $$BooksTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get learningLocale => $composableBuilder(
    column: $table.learningLocale,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get homeLocale => $composableBuilder(
    column: $table.homeLocale,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get voiceId => $composableBuilder(
    column: $table.voiceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get speechRate => $composableBuilder(
    column: $table.speechRate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get lastParagraph => $composableBuilder(
    column: $table.lastParagraph,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get lastOffset => $composableBuilder(
    column: $table.lastOffset,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get contentRevision => $composableBuilder(
    column: $table.contentRevision,
    builder: (column) => ColumnFilters(column),
  );
}

class $$BooksTableOrderingComposer
    extends Composer<_$AppDatabase, $BooksTable> {
  $$BooksTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get learningLocale => $composableBuilder(
    column: $table.learningLocale,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get homeLocale => $composableBuilder(
    column: $table.homeLocale,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get voiceId => $composableBuilder(
    column: $table.voiceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get speechRate => $composableBuilder(
    column: $table.speechRate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get lastParagraph => $composableBuilder(
    column: $table.lastParagraph,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get lastOffset => $composableBuilder(
    column: $table.lastOffset,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get contentRevision => $composableBuilder(
    column: $table.contentRevision,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$BooksTableAnnotationComposer
    extends Composer<_$AppDatabase, $BooksTable> {
  $$BooksTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get learningLocale => $composableBuilder(
    column: $table.learningLocale,
    builder: (column) => column,
  );

  GeneratedColumn<String> get homeLocale => $composableBuilder(
    column: $table.homeLocale,
    builder: (column) => column,
  );

  GeneratedColumn<String> get voiceId =>
      $composableBuilder(column: $table.voiceId, builder: (column) => column);

  GeneratedColumn<double> get speechRate => $composableBuilder(
    column: $table.speechRate,
    builder: (column) => column,
  );

  GeneratedColumn<int> get lastParagraph => $composableBuilder(
    column: $table.lastParagraph,
    builder: (column) => column,
  );

  GeneratedColumn<int> get lastOffset => $composableBuilder(
    column: $table.lastOffset,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<int> get contentRevision => $composableBuilder(
    column: $table.contentRevision,
    builder: (column) => column,
  );
}

class $$BooksTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $BooksTable,
          Book,
          $$BooksTableFilterComposer,
          $$BooksTableOrderingComposer,
          $$BooksTableAnnotationComposer,
          $$BooksTableCreateCompanionBuilder,
          $$BooksTableUpdateCompanionBuilder,
          (Book, BaseReferences<_$AppDatabase, $BooksTable, Book>),
          Book,
          PrefetchHooks Function()
        > {
  $$BooksTableTableManager(_$AppDatabase db, $BooksTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$BooksTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$BooksTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$BooksTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String> learningLocale = const Value.absent(),
                Value<String> homeLocale = const Value.absent(),
                Value<String?> voiceId = const Value.absent(),
                Value<double> speechRate = const Value.absent(),
                Value<int> lastParagraph = const Value.absent(),
                Value<int> lastOffset = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> contentRevision = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => BooksCompanion(
                id: id,
                title: title,
                learningLocale: learningLocale,
                homeLocale: homeLocale,
                voiceId: voiceId,
                speechRate: speechRate,
                lastParagraph: lastParagraph,
                lastOffset: lastOffset,
                createdAt: createdAt,
                updatedAt: updatedAt,
                contentRevision: contentRevision,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String title,
                Value<String> learningLocale = const Value.absent(),
                Value<String> homeLocale = const Value.absent(),
                Value<String?> voiceId = const Value.absent(),
                Value<double> speechRate = const Value.absent(),
                Value<int> lastParagraph = const Value.absent(),
                Value<int> lastOffset = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<int> contentRevision = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => BooksCompanion.insert(
                id: id,
                title: title,
                learningLocale: learningLocale,
                homeLocale: homeLocale,
                voiceId: voiceId,
                speechRate: speechRate,
                lastParagraph: lastParagraph,
                lastOffset: lastOffset,
                createdAt: createdAt,
                updatedAt: updatedAt,
                contentRevision: contentRevision,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$BooksTable, Book>(table),
                  BaseReferences<_$AppDatabase, $BooksTable, Book>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$BooksTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $BooksTable,
      Book,
      $$BooksTableFilterComposer,
      $$BooksTableOrderingComposer,
      $$BooksTableAnnotationComposer,
      $$BooksTableCreateCompanionBuilder,
      $$BooksTableUpdateCompanionBuilder,
      (Book, BaseReferences<_$AppDatabase, $BooksTable, Book>),
      Book,
      PrefetchHooks Function()
    >;
typedef $$PagesTableCreateCompanionBuilder = PagesCompanion Function({
  required String id,
  required String bookId,
  required int orderKey,
  Value<String?> originalPath,
  Value<String?> derivedPath,
  Value<String> status,
  required DateTime createdAt,
  Value<int> rowid,
});
typedef $$PagesTableUpdateCompanionBuilder = PagesCompanion Function({
  Value<String> id,
  Value<String> bookId,
  Value<int> orderKey,
  Value<String?> originalPath,
  Value<String?> derivedPath,
  Value<String> status,
  Value<DateTime> createdAt,
  Value<int> rowid,
});

class $$PagesTableFilterComposer extends Composer<_$AppDatabase, $PagesTable> {
  $$PagesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get bookId => $composableBuilder(
    column: $table.bookId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get orderKey => $composableBuilder(
    column: $table.orderKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get originalPath => $composableBuilder(
    column: $table.originalPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get derivedPath => $composableBuilder(
    column: $table.derivedPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$PagesTableOrderingComposer
    extends Composer<_$AppDatabase, $PagesTable> {
  $$PagesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get bookId => $composableBuilder(
    column: $table.bookId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get orderKey => $composableBuilder(
    column: $table.orderKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get originalPath => $composableBuilder(
    column: $table.originalPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get derivedPath => $composableBuilder(
    column: $table.derivedPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PagesTableAnnotationComposer
    extends Composer<_$AppDatabase, $PagesTable> {
  $$PagesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get bookId =>
      $composableBuilder(column: $table.bookId, builder: (column) => column);

  GeneratedColumn<int> get orderKey =>
      $composableBuilder(column: $table.orderKey, builder: (column) => column);

  GeneratedColumn<String> get originalPath => $composableBuilder(
    column: $table.originalPath,
    builder: (column) => column,
  );

  GeneratedColumn<String> get derivedPath => $composableBuilder(
    column: $table.derivedPath,
    builder: (column) => column,
  );

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$PagesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PagesTable,
          Page,
          $$PagesTableFilterComposer,
          $$PagesTableOrderingComposer,
          $$PagesTableAnnotationComposer,
          $$PagesTableCreateCompanionBuilder,
          $$PagesTableUpdateCompanionBuilder,
          (Page, BaseReferences<_$AppDatabase, $PagesTable, Page>),
          Page,
          PrefetchHooks Function()
        > {
  $$PagesTableTableManager(_$AppDatabase db, $PagesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PagesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PagesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PagesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> bookId = const Value.absent(),
                Value<int> orderKey = const Value.absent(),
                Value<String?> originalPath = const Value.absent(),
                Value<String?> derivedPath = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PagesCompanion(
                id: id,
                bookId: bookId,
                orderKey: orderKey,
                originalPath: originalPath,
                derivedPath: derivedPath,
                status: status,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String bookId,
                required int orderKey,
                Value<String?> originalPath = const Value.absent(),
                Value<String?> derivedPath = const Value.absent(),
                Value<String> status = const Value.absent(),
                required DateTime createdAt,
                Value<int> rowid = const Value.absent(),
              }) => PagesCompanion.insert(
                id: id,
                bookId: bookId,
                orderKey: orderKey,
                originalPath: originalPath,
                derivedPath: derivedPath,
                status: status,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$PagesTable, Page>(table),
                  BaseReferences<_$AppDatabase, $PagesTable, Page>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$PagesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PagesTable,
      Page,
      $$PagesTableFilterComposer,
      $$PagesTableOrderingComposer,
      $$PagesTableAnnotationComposer,
      $$PagesTableCreateCompanionBuilder,
      $$PagesTableUpdateCompanionBuilder,
      (Page, BaseReferences<_$AppDatabase, $PagesTable, Page>),
      Page,
      PrefetchHooks Function()
    >;
typedef $$ParagraphsTableCreateCompanionBuilder = ParagraphsCompanion Function({
  required String id,
  required String bookId,
  required String pageId,
  required int orderKey,
  required String content,
  Value<String?> localeOverride,
  Value<int> textRevision,
  Value<int> rowid,
});
typedef $$ParagraphsTableUpdateCompanionBuilder = ParagraphsCompanion Function({
  Value<String> id,
  Value<String> bookId,
  Value<String> pageId,
  Value<int> orderKey,
  Value<String> content,
  Value<String?> localeOverride,
  Value<int> textRevision,
  Value<int> rowid,
});

class $$ParagraphsTableFilterComposer
    extends Composer<_$AppDatabase, $ParagraphsTable> {
  $$ParagraphsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get bookId => $composableBuilder(
    column: $table.bookId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get pageId => $composableBuilder(
    column: $table.pageId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get orderKey => $composableBuilder(
    column: $table.orderKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get content => $composableBuilder(
    column: $table.content,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get localeOverride => $composableBuilder(
    column: $table.localeOverride,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get textRevision => $composableBuilder(
    column: $table.textRevision,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ParagraphsTableOrderingComposer
    extends Composer<_$AppDatabase, $ParagraphsTable> {
  $$ParagraphsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get bookId => $composableBuilder(
    column: $table.bookId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get pageId => $composableBuilder(
    column: $table.pageId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get orderKey => $composableBuilder(
    column: $table.orderKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get content => $composableBuilder(
    column: $table.content,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get localeOverride => $composableBuilder(
    column: $table.localeOverride,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get textRevision => $composableBuilder(
    column: $table.textRevision,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ParagraphsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ParagraphsTable> {
  $$ParagraphsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get bookId =>
      $composableBuilder(column: $table.bookId, builder: (column) => column);

  GeneratedColumn<String> get pageId =>
      $composableBuilder(column: $table.pageId, builder: (column) => column);

  GeneratedColumn<int> get orderKey =>
      $composableBuilder(column: $table.orderKey, builder: (column) => column);

  GeneratedColumn<String> get content =>
      $composableBuilder(column: $table.content, builder: (column) => column);

  GeneratedColumn<String> get localeOverride => $composableBuilder(
    column: $table.localeOverride,
    builder: (column) => column,
  );

  GeneratedColumn<int> get textRevision => $composableBuilder(
    column: $table.textRevision,
    builder: (column) => column,
  );
}

class $$ParagraphsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ParagraphsTable,
          Paragraph,
          $$ParagraphsTableFilterComposer,
          $$ParagraphsTableOrderingComposer,
          $$ParagraphsTableAnnotationComposer,
          $$ParagraphsTableCreateCompanionBuilder,
          $$ParagraphsTableUpdateCompanionBuilder,
          (
            Paragraph,
            BaseReferences<_$AppDatabase, $ParagraphsTable, Paragraph>,
          ),
          Paragraph,
          PrefetchHooks Function()
        > {
  $$ParagraphsTableTableManager(_$AppDatabase db, $ParagraphsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ParagraphsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ParagraphsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ParagraphsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> bookId = const Value.absent(),
                Value<String> pageId = const Value.absent(),
                Value<int> orderKey = const Value.absent(),
                Value<String> content = const Value.absent(),
                Value<String?> localeOverride = const Value.absent(),
                Value<int> textRevision = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ParagraphsCompanion(
                id: id,
                bookId: bookId,
                pageId: pageId,
                orderKey: orderKey,
                content: content,
                localeOverride: localeOverride,
                textRevision: textRevision,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String bookId,
                required String pageId,
                required int orderKey,
                required String content,
                Value<String?> localeOverride = const Value.absent(),
                Value<int> textRevision = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ParagraphsCompanion.insert(
                id: id,
                bookId: bookId,
                pageId: pageId,
                orderKey: orderKey,
                content: content,
                localeOverride: localeOverride,
                textRevision: textRevision,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ParagraphsTable, Paragraph>(table),
                  BaseReferences<_$AppDatabase, $ParagraphsTable, Paragraph>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ParagraphsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ParagraphsTable,
      Paragraph,
      $$ParagraphsTableFilterComposer,
      $$ParagraphsTableOrderingComposer,
      $$ParagraphsTableAnnotationComposer,
      $$ParagraphsTableCreateCompanionBuilder,
      $$ParagraphsTableUpdateCompanionBuilder,
      (Paragraph, BaseReferences<_$AppDatabase, $ParagraphsTable, Paragraph>),
      Paragraph,
      PrefetchHooks Function()
    >;
typedef $$ImportJobsTableCreateCompanionBuilder = ImportJobsCompanion Function({
  required String id,
  required String bookId,
  required String pageId,
  Value<String?> imagePath,
  Value<String> state,
  Value<int> attempts,
  Value<String?> errorCode,
  required DateTime updatedAt,
  Value<int> rowid,
});
typedef $$ImportJobsTableUpdateCompanionBuilder = ImportJobsCompanion Function({
  Value<String> id,
  Value<String> bookId,
  Value<String> pageId,
  Value<String?> imagePath,
  Value<String> state,
  Value<int> attempts,
  Value<String?> errorCode,
  Value<DateTime> updatedAt,
  Value<int> rowid,
});

class $$ImportJobsTableFilterComposer
    extends Composer<_$AppDatabase, $ImportJobsTable> {
  $$ImportJobsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get bookId => $composableBuilder(
    column: $table.bookId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get pageId => $composableBuilder(
    column: $table.pageId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get imagePath => $composableBuilder(
    column: $table.imagePath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get state => $composableBuilder(
    column: $table.state,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get attempts => $composableBuilder(
    column: $table.attempts,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get errorCode => $composableBuilder(
    column: $table.errorCode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ImportJobsTableOrderingComposer
    extends Composer<_$AppDatabase, $ImportJobsTable> {
  $$ImportJobsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get bookId => $composableBuilder(
    column: $table.bookId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get pageId => $composableBuilder(
    column: $table.pageId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get imagePath => $composableBuilder(
    column: $table.imagePath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get state => $composableBuilder(
    column: $table.state,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get attempts => $composableBuilder(
    column: $table.attempts,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get errorCode => $composableBuilder(
    column: $table.errorCode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ImportJobsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ImportJobsTable> {
  $$ImportJobsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get bookId =>
      $composableBuilder(column: $table.bookId, builder: (column) => column);

  GeneratedColumn<String> get pageId =>
      $composableBuilder(column: $table.pageId, builder: (column) => column);

  GeneratedColumn<String> get imagePath =>
      $composableBuilder(column: $table.imagePath, builder: (column) => column);

  GeneratedColumn<String> get state =>
      $composableBuilder(column: $table.state, builder: (column) => column);

  GeneratedColumn<int> get attempts =>
      $composableBuilder(column: $table.attempts, builder: (column) => column);

  GeneratedColumn<String> get errorCode =>
      $composableBuilder(column: $table.errorCode, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$ImportJobsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ImportJobsTable,
          ImportJob,
          $$ImportJobsTableFilterComposer,
          $$ImportJobsTableOrderingComposer,
          $$ImportJobsTableAnnotationComposer,
          $$ImportJobsTableCreateCompanionBuilder,
          $$ImportJobsTableUpdateCompanionBuilder,
          (
            ImportJob,
            BaseReferences<_$AppDatabase, $ImportJobsTable, ImportJob>,
          ),
          ImportJob,
          PrefetchHooks Function()
        > {
  $$ImportJobsTableTableManager(_$AppDatabase db, $ImportJobsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ImportJobsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ImportJobsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ImportJobsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> bookId = const Value.absent(),
                Value<String> pageId = const Value.absent(),
                Value<String?> imagePath = const Value.absent(),
                Value<String> state = const Value.absent(),
                Value<int> attempts = const Value.absent(),
                Value<String?> errorCode = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ImportJobsCompanion(
                id: id,
                bookId: bookId,
                pageId: pageId,
                imagePath: imagePath,
                state: state,
                attempts: attempts,
                errorCode: errorCode,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String bookId,
                required String pageId,
                Value<String?> imagePath = const Value.absent(),
                Value<String> state = const Value.absent(),
                Value<int> attempts = const Value.absent(),
                Value<String?> errorCode = const Value.absent(),
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => ImportJobsCompanion.insert(
                id: id,
                bookId: bookId,
                pageId: pageId,
                imagePath: imagePath,
                state: state,
                attempts: attempts,
                errorCode: errorCode,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ImportJobsTable, ImportJob>(table),
                  BaseReferences<_$AppDatabase, $ImportJobsTable, ImportJob>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ImportJobsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ImportJobsTable,
      ImportJob,
      $$ImportJobsTableFilterComposer,
      $$ImportJobsTableOrderingComposer,
      $$ImportJobsTableAnnotationComposer,
      $$ImportJobsTableCreateCompanionBuilder,
      $$ImportJobsTableUpdateCompanionBuilder,
      (ImportJob, BaseReferences<_$AppDatabase, $ImportJobsTable, ImportJob>),
      ImportJob,
      PrefetchHooks Function()
    >;
typedef $$PageDraftsTableCreateCompanionBuilder = PageDraftsCompanion Function({
  required String id,
  required String bookId,
  required String pageId,
  required String jobId,
  required String rawText,
  required String paragraphsJson,
  Value<int> revision,
  required DateTime updatedAt,
  Value<int> rowid,
});
typedef $$PageDraftsTableUpdateCompanionBuilder = PageDraftsCompanion Function({
  Value<String> id,
  Value<String> bookId,
  Value<String> pageId,
  Value<String> jobId,
  Value<String> rawText,
  Value<String> paragraphsJson,
  Value<int> revision,
  Value<DateTime> updatedAt,
  Value<int> rowid,
});

class $$PageDraftsTableFilterComposer
    extends Composer<_$AppDatabase, $PageDraftsTable> {
  $$PageDraftsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get bookId => $composableBuilder(
    column: $table.bookId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get pageId => $composableBuilder(
    column: $table.pageId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get jobId => $composableBuilder(
    column: $table.jobId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get rawText => $composableBuilder(
    column: $table.rawText,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get paragraphsJson => $composableBuilder(
    column: $table.paragraphsJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get revision => $composableBuilder(
    column: $table.revision,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$PageDraftsTableOrderingComposer
    extends Composer<_$AppDatabase, $PageDraftsTable> {
  $$PageDraftsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get bookId => $composableBuilder(
    column: $table.bookId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get pageId => $composableBuilder(
    column: $table.pageId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get jobId => $composableBuilder(
    column: $table.jobId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get rawText => $composableBuilder(
    column: $table.rawText,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get paragraphsJson => $composableBuilder(
    column: $table.paragraphsJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get revision => $composableBuilder(
    column: $table.revision,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PageDraftsTableAnnotationComposer
    extends Composer<_$AppDatabase, $PageDraftsTable> {
  $$PageDraftsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get bookId =>
      $composableBuilder(column: $table.bookId, builder: (column) => column);

  GeneratedColumn<String> get pageId =>
      $composableBuilder(column: $table.pageId, builder: (column) => column);

  GeneratedColumn<String> get jobId =>
      $composableBuilder(column: $table.jobId, builder: (column) => column);

  GeneratedColumn<String> get rawText =>
      $composableBuilder(column: $table.rawText, builder: (column) => column);

  GeneratedColumn<String> get paragraphsJson => $composableBuilder(
    column: $table.paragraphsJson,
    builder: (column) => column,
  );

  GeneratedColumn<int> get revision =>
      $composableBuilder(column: $table.revision, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$PageDraftsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PageDraftsTable,
          PageDraft,
          $$PageDraftsTableFilterComposer,
          $$PageDraftsTableOrderingComposer,
          $$PageDraftsTableAnnotationComposer,
          $$PageDraftsTableCreateCompanionBuilder,
          $$PageDraftsTableUpdateCompanionBuilder,
          (
            PageDraft,
            BaseReferences<_$AppDatabase, $PageDraftsTable, PageDraft>,
          ),
          PageDraft,
          PrefetchHooks Function()
        > {
  $$PageDraftsTableTableManager(_$AppDatabase db, $PageDraftsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PageDraftsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PageDraftsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PageDraftsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> bookId = const Value.absent(),
                Value<String> pageId = const Value.absent(),
                Value<String> jobId = const Value.absent(),
                Value<String> rawText = const Value.absent(),
                Value<String> paragraphsJson = const Value.absent(),
                Value<int> revision = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PageDraftsCompanion(
                id: id,
                bookId: bookId,
                pageId: pageId,
                jobId: jobId,
                rawText: rawText,
                paragraphsJson: paragraphsJson,
                revision: revision,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String bookId,
                required String pageId,
                required String jobId,
                required String rawText,
                required String paragraphsJson,
                Value<int> revision = const Value.absent(),
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => PageDraftsCompanion.insert(
                id: id,
                bookId: bookId,
                pageId: pageId,
                jobId: jobId,
                rawText: rawText,
                paragraphsJson: paragraphsJson,
                revision: revision,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$PageDraftsTable, PageDraft>(table),
                  BaseReferences<_$AppDatabase, $PageDraftsTable, PageDraft>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$PageDraftsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PageDraftsTable,
      PageDraft,
      $$PageDraftsTableFilterComposer,
      $$PageDraftsTableOrderingComposer,
      $$PageDraftsTableAnnotationComposer,
      $$PageDraftsTableCreateCompanionBuilder,
      $$PageDraftsTableUpdateCompanionBuilder,
      (PageDraft, BaseReferences<_$AppDatabase, $PageDraftsTable, PageDraft>),
      PageDraft,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$BooksTableTableManager get books =>
      $$BooksTableTableManager(_db, _db.books);
  $$PagesTableTableManager get pages =>
      $$PagesTableTableManager(_db, _db.pages);
  $$ParagraphsTableTableManager get paragraphs =>
      $$ParagraphsTableTableManager(_db, _db.paragraphs);
  $$ImportJobsTableTableManager get importJobs =>
      $$ImportJobsTableTableManager(_db, _db.importJobs);
  $$PageDraftsTableTableManager get pageDrafts =>
      $$PageDraftsTableTableManager(_db, _db.pageDrafts);
}
