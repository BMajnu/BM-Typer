import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

part 'sync_operation.g.dart';

/// Types of sync operations
enum SyncOperationType {
  create,
  update,
  delete,
}

/// Represents a pending sync operation that needs to be sent to Firebase
@HiveType(typeId: 10)
class SyncOperation extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String collection;

  @HiveField(2)
  final String documentId;

  @HiveField(3)
  final Map<String, dynamic> data;

  @HiveField(4)
  final String operationType; // 'create', 'update', 'delete'

  @HiveField(5)
  final DateTime createdAt;

  @HiveField(6)
  int retryCount;

  @HiveField(7)
  String? errorMessage;

  SyncOperation({
    String? id,
    required this.collection,
    required this.documentId,
    required this.data,
    required this.operationType,
    DateTime? createdAt,
    this.retryCount = 0,
    this.errorMessage,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now();

  SyncOperationType get type {
    switch (operationType) {
      case 'create':
        return SyncOperationType.create;
      case 'update':
        return SyncOperationType.update;
      case 'delete':
        return SyncOperationType.delete;
      default:
        return SyncOperationType.update;
    }
  }

  SyncOperation copyWith({
    int? retryCount,
    String? errorMessage,
  }) {
    return SyncOperation(
      id: id,
      collection: collection,
      documentId: documentId,
      data: data,
      operationType: operationType,
      createdAt: createdAt,
      retryCount: retryCount ?? this.retryCount,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'collection': collection,
        'documentId': documentId,
        'data': data,
        'operationType': operationType,
        'createdAt': createdAt.toIso8601String(),
        'retryCount': retryCount,
        'errorMessage': errorMessage,
      };

  factory SyncOperation.fromJson(Map<String, dynamic> json) => SyncOperation(
        id: json['id'] as String,
        collection: json['collection'] as String,
        documentId: json['documentId'] as String,
        data: json['data'] as Map<String, dynamic>,
        operationType: json['operationType'] as String,
        createdAt: DateTime.parse(json['createdAt'] as String),
        retryCount: json['retryCount'] as int? ?? 0,
        errorMessage: json['errorMessage'] as String?,
      );
}
