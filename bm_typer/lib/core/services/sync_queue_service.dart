import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:bm_typer/core/models/sync_operation.dart';
import 'package:bm_typer/core/services/connectivity_service.dart';
import 'package:bm_typer/core/services/cloud_sync_service.dart';

/// Status of the sync process
enum SyncStatus {
  synced,
  syncing,
  offline,
  error,
}

/// Service to manage offline sync queue
class SyncQueueService {
  static const String _boxName = 'sync_queue';
  // Increase max retries or remove limit for transient errors
  static const int _maxRetries = 10; 

  static final SyncQueueService _instance = SyncQueueService._internal();
  factory SyncQueueService() => _instance;
  SyncQueueService._internal();

  Box<Map>? _box;
  final ConnectivityService _connectivity = ConnectivityService();
  StreamSubscription<bool>? _connectivitySubscription;
  bool _isProcessing = false;

  // Status Stream
  final _statusController = StreamController<SyncStatus>.broadcast();
  Stream<SyncStatus> get syncStatusStream => _statusController.stream;
  SyncStatus _currentStatus = SyncStatus.synced;

  /// Initialize the sync queue service
  Future<void> initialize() async {
    if (!Hive.isBoxOpen(_boxName)) {
      _box = await Hive.openBox<Map>(_boxName);
    } else {
      _box = Hive.box<Map>(_boxName);
    }

    // Initial Status Check
    _updateStatus(_connectivity.isOnline ? SyncStatus.synced : SyncStatus.offline);

    // Listen for connectivity changes
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen((isOnline) {
      if (isOnline) {
        _updateStatus(SyncStatus.syncing); // Temporary state before syncing
        processQueue();
      } else {
        _updateStatus(SyncStatus.offline);
      }
    });

    // Process any pending operations if online
    if (_connectivity.isOnline) {
      processQueue();
    }
  }

  void _updateStatus(SyncStatus status) {
    _currentStatus = status;
    _statusController.add(status);
  }

  /// Add an operation to the queue
  Future<void> addOperation(SyncOperation operation) async {
    if (_box == null) await initialize();
    await _box!.put(operation.id, operation.toJson());
    debugPrint('📥 Added sync operation: ${operation.operationType} on ${operation.collection}/${operation.documentId}');
    
    // Notify UI that we have pending items
    _updateStatus(SyncStatus.syncing);

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
    if (_box == null || _box!.isEmpty) {
        if (_connectivity.isOnline) _updateStatus(SyncStatus.synced);
        return;
    }
    if (!_connectivity.isOnline) {
        _updateStatus(SyncStatus.offline);
        return;
    }

    _isProcessing = true;
    _updateStatus(SyncStatus.syncing);
    debugPrint('🔄 Processing sync queue (${_box!.length} operations)...');

    final operations = getPendingOperations();
    int successCount = 0;

    for (final operation in operations) {
      // Re-check connectivity loop
       if (!_connectivity.isOnline) {
          debugPrint('⚠️ Network lost during sync');
          _updateStatus(SyncStatus.offline);
          break;
       }

      try {
        final success = await CloudSyncService().processOperation(operation);
        
        if (success) {
          // Success: Remove from queue
          await _box!.delete(operation.id);
          debugPrint('✅ Synced: ${operation.operationType} on ${operation.collection}/${operation.documentId}');
          successCount++;
        } else {
          // Permanent Failure (Validation/Permission): Remove to unblock queue
          // In a real app, we might want to log this via Crashlytics or move to a "Dead Letter Queue"
          await _box!.delete(operation.id);
          debugPrint('❌ Permanent Sync Fail (Removed): ${operation.id}');
        }
      } catch (e) {
        // Transient Failure (Network): Keep in queue, increment retry
        debugPrint('⚠️ Transient Sync Fail: $e');
        
        final updated = operation.copyWith(
          retryCount: operation.retryCount + 1,
          errorMessage: e.toString(),
        );
        
        // Use exponential backoff or simple cap? 
        // For now, simple cap, but we DON'T delete. We just stop processing to avoid batter drain loop.
        await _box!.put(operation.id, updated.toJson());
        
        // Stop batch processing on first error to preserve order dependent operations
        // (Create -> Update sequence matters)
        _updateStatus(SyncStatus.error);
        _isProcessing = false;
        return; 
      }
    }

    _isProcessing = false;
    
    if (_box!.isEmpty) {
        _updateStatus(SyncStatus.synced);
        debugPrint('✅ Sync processed completely.');
    } else {
        debugPrint('️⚠️ Sync paused. Remaining: ${_box!.length}');
    }
  }

  /// Clear all pending operations
  Future<void> clearQueue() async {
    await _box?.clear();
    _updateStatus(SyncStatus.synced);
  }

  /// Dispose resources
  void dispose() {
    _connectivitySubscription?.cancel();
    _statusController.close();
  }
}

