import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Service to monitor network connectivity status
class ConnectivityService {
  static final ConnectivityService _instance = ConnectivityService._internal();
  factory ConnectivityService() => _instance;
  ConnectivityService._internal();

  final Connectivity _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _subscription;

  final _connectivityController = StreamController<bool>.broadcast();
  Stream<bool> get onConnectivityChanged => _connectivityController.stream;

  bool _isOnline = false;
  bool get isOnline => _isOnline;

  /// Initialize the connectivity listener
  Future<void> initialize() async {
    // Check initial status
    final result = await _connectivity.checkConnectivity();
    _isOnline = _isConnected(result);

    // Listen for changes
    _subscription = _connectivity.onConnectivityChanged.listen((result) {
      final wasOnline = _isOnline;
      _isOnline = _isConnected(result);

      if (_isOnline != wasOnline) {
        _connectivityController.add(_isOnline);
        debugPrint('📶 Connectivity changed: ${_isOnline ? "ONLINE" : "OFFLINE"}');
      }
    });
  }

  bool _isConnected(List<ConnectivityResult> result) {
    return result.isNotEmpty &&
        !result.contains(ConnectivityResult.none) &&
        (result.contains(ConnectivityResult.wifi) ||
            result.contains(ConnectivityResult.mobile) ||
            result.contains(ConnectivityResult.ethernet));
  }

  /// Check current connectivity
  Future<bool> checkConnectivity() async {
    final result = await _connectivity.checkConnectivity();
    _isOnline = _isConnected(result);
    return _isOnline;
  }

  /// Dispose resources
  void dispose() {
    _subscription?.cancel();
    _connectivityController.close();
  }
}

/// Provider for connectivity status
final connectivityServiceProvider = Provider<ConnectivityService>((ref) {
  final service = ConnectivityService();
  ref.onDispose(() => service.dispose());
  return service;
});

/// Provider for online status stream
final isOnlineProvider = StreamProvider<bool>((ref) {
  final service = ref.watch(connectivityServiceProvider);
  return service.onConnectivityChanged;
});

/// Provider for current online status
final isOnlineNowProvider = Provider<bool>((ref) {
  final asyncValue = ref.watch(isOnlineProvider);
  return asyncValue.when(
    data: (isOnline) => isOnline,
    loading: () => ref.read(connectivityServiceProvider).isOnline,
    error: (_, __) => false,
  );
});
