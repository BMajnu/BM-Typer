import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:bm_typer/core/models/sync_operation.dart';
import 'package:bm_typer/core/services/connectivity_service.dart';
import 'package:bm_typer/core/services/cloud_sync_service.dart';

/// Service to manage offline sync queue
class SyncQueueService {
  static const String _boxName = 'sync_queue';
  static const int _maxRetries = 3;

  static final SyncQueueService _instance = SyncQueueService._internal();
  factory SyncQueueService() => _instance;
  SyncQueueService._internal();

  Box<Map>? _box;
  final ConnectivityService _connectivity = ConnectivityService();
  StreamSubscription<bool>? _connectivitySubscription;
  bool _isProcessing = false;

  /// Initialize the sync queue service
  Future<void> initialize() async {
    if (!Hive.isBoxOpen(_boxName)) {
      _box = await Hive.openBox<Map>(_boxName);
    } else {
      _box = Hive.box<Map>(_boxName);
    }

    // Listen for connectivity changes
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen((isOnline) {
      if (isOnline) {
        processQueue();
      }
    });

    // Process any pending operations if online
    if (_connectivity.isOnline) {
      processQueue();
    }
  }

  /// Add an operation to the queue
  Future<void> addOperation(SyncOperation operation) async {
    if (_box == null) await initialize();
    await _box!.put(operation.id, operation.toJson());
    debugPrint('📥 Added sync operation: ${operation.operationType} on ${operation.collection}/${operation.documentId}');

    // Try to process immediately if online
    if (_connectivity.isOnline && !_isProcessing) {
      processQueue();
    }
  }

  /// Get all pending operations
  List<SyncOperation> getPendingOperations() {
    if (_box == null) return [];
    return _box!.values
        .map((json) => SyncOperation.fromJson(Map<String, dynamic>.from(json)))
        .toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
  }

  /// Get count of pending operations
  int get pendingCount => _box?.length ?? 0;

  /// Process the sync queue
  Future<void> processQueue() async {
    if (_isProcessing) return;
    if (_box == null || _box!.isEmpty) return;
    if (!_connectivity.isOnline) return;

    _isProcessing = true;
    debugPrint('🔄 Processing sync queue (${_box!.length} operations)...');

    final operations = getPendingOperations();

    for (final operation in operations) {
      try {
        final success = await CloudSyncService().processOperation(operation);
        
        if (success) {
          await _box!.delete(operation.id);
          debugPrint('✅ Synced: ${operation.operationType} on ${operation.collection}/${operation.documentId}');
        } else {
          // Increment retry count
          final updated = operation.copyWith(retryCount: operation.retryCount + 1);
          if (updated.retryCount >= _maxRetries) {
            await _box!.delete(operation.id);
            debugPrint('❌ Max retries reached, removed: ${operation.id}');
          } else {
            await _box!.put(operation.id, updated.toJson());
          }
        }
      } catch (e) {
        debugPrint('❌ Sync error: $e');
        final updated = operation.copyWith(
          retryCount: operation.retryCount + 1,
          errorMessage: e.toString(),
        );
        await _box!.put(operation.id, updated.toJson());
      }
    }

    _isProcessing = false;
    debugPrint('✅ Sync queue processing complete. Remaining: ${_box!.length}');
  }

  /// Clear all pending operations
  Future<void> clearQueue() async {
    await _box?.clear();
  }

  /// Dispose resources
  void dispose() {
    _connectivitySubscription?.cancel();
  }
}
