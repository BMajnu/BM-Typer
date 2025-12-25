import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bm_typer/core/services/sync_queue_service.dart';
import 'package:bm_typer/core/services/connectivity_service.dart';

/// Provider for the SyncQueueService singleton
final syncQueueServiceProvider = Provider<SyncQueueService>((ref) {
  return SyncQueueService();
});

/// Provider for the sync status stream
final syncStatusProvider = StreamProvider<SyncStatus>((ref) {
  final service = ref.watch(syncQueueServiceProvider);
  return service.syncStatusStream;
});

/// Provider for connectivity status
final isOnlineProvider = StreamProvider<bool>((ref) {
  final connectivity = ConnectivityService();
  return connectivity.onConnectivityChanged;
});
