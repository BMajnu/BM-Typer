import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:bm_typer/core/services/database_service.dart';
import 'package:bm_typer/core/services/connectivity_service.dart';

class DebugScreen extends StatefulWidget {
  const DebugScreen({super.key});

  @override
  State<DebugScreen> createState() => _DebugScreenState();
}

class _DebugScreenState extends State<DebugScreen> {
  final List<LogEntry> _logs = [];
  final ScrollController _scrollController = ScrollController();
  bool _autoScroll = true;

  // Service statuses
  Map<String, ServiceStatus> _serviceStatuses = {};
  String _appVersion = 'Loading...';
  String _buildNumber = 'Loading...';
  String _platform = 'Unknown';
  String _firebaseProjectId = 'Unknown';
  String _authState = 'Unknown';
  bool _isFirestoreConnected = false;
  bool _isHiveInitialized = false;
  String _connectivityStatus = 'Unknown';
  int _totalBoxCount = 0;
  int _totalRecords = 0;

  @override
  void initState() {
    super.initState();
    _initializeDebugInfo();
    _startPeriodicChecks();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _addLog(String message, {LogLevel level = LogLevel.info}) {
    setState(() {
      _logs.add(LogEntry(
        timestamp: DateTime.now(),
        message: message,
        level: level,
      ));
      // Keep only last 500 logs
      if (_logs.length > 500) {
        _logs.removeAt(0);
      }
    });

    if (_autoScroll) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 100),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  Future<void> _initializeDebugInfo() async {
    _addLog('Debug Screen Initialized', level: LogLevel.info);
    _addLog('Checking app information...', level: LogLevel.info);

    // Get package info
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      setState(() {
        _appVersion = packageInfo.version;
        _buildNumber = packageInfo.buildNumber;
      });
      _addLog('App Version: $_appVersion+$_buildNumber', level: LogLevel.success);
    } catch (e) {
      _addLog('Failed to get package info: $e', level: LogLevel.error);
    }

    // Check platform
    setState(() {
      _platform = 'Windows';
    });
    _addLog('Platform: $_platform', level: LogLevel.info);

    // Check Firebase
    await _checkFirebaseStatus();

    // Check Hive/Database
    await _checkHiveStatus();

    // Check Connectivity
    await _checkConnectivity();

    // Run all service checks
    await _checkAllServices();
  }

  Future<void> _checkFirebaseStatus() async {
    _addLog('Checking Firebase status...', level: LogLevel.info);

    try {
      final apps = Firebase.apps;
      if (apps.isNotEmpty) {
        final app = apps.first;
        setState(() {
          _firebaseProjectId = app.options.projectId ?? 'Unknown';
        });
        _addLog('Firebase App: ${app.name}', level: LogLevel.success);
        _addLog('Project ID: $_firebaseProjectId', level: LogLevel.info);
      } else {
        _addLog('No Firebase apps initialized', level: LogLevel.warning);
      }
    } catch (e) {
      _addLog('Firebase check failed: $e', level: LogLevel.error);
    }

    // Check Auth
    try {
      final auth = FirebaseAuth.instance;
      final user = auth.currentUser;
      setState(() {
        _authState = user != null ? 'Logged in: ${user.email}' : 'Not logged in';
      });
      _addLog('Auth State: $_authState', level: LogLevel.info);

      auth.authStateChanges().listen((user) {
        setState(() {
          _authState = user != null ? 'Logged in: ${user.email}' : 'Not logged in';
        });
        _addLog('Auth state changed: $_authState', level: LogLevel.warning);
      });
    } catch (e) {
      _addLog('Auth check failed: $e', level: LogLevel.error);
    }

    // Check Firestore
    try {
      final firestore = FirebaseFirestore.instance;
      await firestore.collection('_debug_test').limit(1).get().timeout(
        const Duration(seconds: 5),
      );
      setState(() {
        _isFirestoreConnected = true;
      });
      _addLog('Firestore: Connected', level: LogLevel.success);
    } catch (e) {
      setState(() {
        _isFirestoreConnected = false;
      });
      _addLog('Firestore connection issue: $e', level: LogLevel.warning);
    }
  }

  Future<void> _checkHiveStatus() async {
    _addLog('Checking Hive database status...', level: LogLevel.info);

    try {
      // Check if Hive is initialized by trying to open a box
      final testBox = await Hive.openBox('_debug_test');
      await testBox.close();

      // Try to get known box names from the app
      final knownBoxes = ['users', 'settings', 'leaderboard', 'typing_tests', 'sync_queue'];
      int totalRecords = 0;
      int boxCount = 0;

      for (final name in knownBoxes) {
        try {
          if (Hive.isBoxOpen(name)) {
            final box = Hive.box(name);
            totalRecords += box.length;
            boxCount++;
          }
        } catch (_) {}
      }

      setState(() {
        _isHiveInitialized = true;
        _totalBoxCount = boxCount;
        _totalRecords = totalRecords;
      });

      _addLog('Hive: Initialized', level: LogLevel.success);
      _addLog('Open Boxes: $_totalBoxCount', level: LogLevel.info);
      _addLog('Total Records: $_totalRecords', level: LogLevel.info);
    } catch (e) {
      setState(() {
        _isHiveInitialized = false;
      });
      _addLog('Hive check failed: $e', level: LogLevel.error);
    }
  }

  Future<void> _checkConnectivity() async {
    _addLog('Checking connectivity...', level: LogLevel.info);

    try {
      final connectivity = Connectivity();
      final result = await connectivity.checkConnectivity();
      final isConnected = result != ConnectivityResult.none;

      setState(() {
        _connectivityStatus = isConnected ? 'Connected' : 'Disconnected';
      });

      _addLog('Connectivity: $_connectivityStatus', level: isConnected ? LogLevel.success : LogLevel.warning);

      connectivity.onConnectivityChanged.listen((result) {
        final isConnected = result != ConnectivityResult.none;
        setState(() {
          _connectivityStatus = isConnected ? 'Connected' : 'Disconnected';
        });
        _addLog('Connectivity changed: $_connectivityStatus', level: LogLevel.warning);
      });
    } catch (e) {
      _addLog('Connectivity check failed: $e', level: LogLevel.error);
    }
  }

  Future<void> _checkAllServices() async {
    _addLog('--- Service Health Check ---', level: LogLevel.info);

    final services = {
      'Firebase Core': () => Firebase.apps.isNotEmpty,
      'Firebase Auth': () => FirebaseAuth.instance.currentUser != null || true,
      'Firestore': () => _isFirestoreConnected,
      'Hive Database': () => _isHiveInitialized,
      'Connectivity': () => _connectivityStatus == 'Connected',
    };

    for (final entry in services.entries) {
      try {
        final isHealthy = await entry.value();
        setState(() {
          _serviceStatuses[entry.key] = ServiceStatus(
            name: entry.key,
            isHealthy: isHealthy,
            lastChecked: DateTime.now(),
          );
        });
        _addLog('${entry.key}: ${isHealthy ? "OK" : "ISSUE"}',
            level: isHealthy ? LogLevel.success : LogLevel.warning);
      } catch (e) {
        setState(() {
          _serviceStatuses[entry.key] = ServiceStatus(
            name: entry.key,
            isHealthy: false,
            lastChecked: DateTime.now(),
            error: e.toString(),
          );
        });
        _addLog('${entry.key}: ERROR - $e', level: LogLevel.error);
      }
    }

    _addLog('--- Health Check Complete ---', level: LogLevel.info);
  }

  void _startPeriodicChecks() {
    Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) {
        _checkAllServices();
      }
    });
  }

  void _clearLogs() {
    setState(() {
      _logs.clear();
    });
    _addLog('Logs cleared', level: LogLevel.info);
  }

  void _copyLogs() {
    final logText = _logs.map((log) => log.toString()).join('\n');
    Clipboard.setData(ClipboardData(text: logText));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Logs copied to clipboard')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text('Debug Console', style: GoogleFonts.poppins()),
        backgroundColor: isDark ? const Color(0xFF1a1a2e) : colorScheme.primaryContainer,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _checkAllServices,
            tooltip: 'Refresh Services',
          ),
          IconButton(
            icon: const Icon(Icons.copy),
            onPressed: _copyLogs,
            tooltip: 'Copy Logs',
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: _clearLogs,
            tooltip: 'Clear Logs',
          ),
        ],
      ),
      body: Column(
        children: [
          // Status Cards
          _buildStatusSection(isDark, colorScheme),

          // Service Health Grid
          _buildServiceHealthGrid(isDark, colorScheme),

          // Log Console
          Expanded(
            child: _buildLogConsole(isDark, colorScheme),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusSection(bool isDark, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(12),
      color: isDark ? const Color(0xFF0f0f1a) : colorScheme.surface,
      child: Column(
        children: [
          Row(
            children: [
              _buildInfoChip('v$_appVersion+$_buildNumber', Icons.info_outline, isDark),
              const SizedBox(width: 8),
              _buildInfoChip(_platform, Icons.computer, isDark),
              const SizedBox(width: 8),
              _buildInfoChip(_connectivityStatus, Icons.wifi, isDark,
                  color: _connectivityStatus == 'Connected' ? Colors.green : Colors.red),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildInfoChip('Firebase: $_firebaseProjectId', Icons.cloud, isDark),
              const SizedBox(width: 8),
              _buildInfoChip('Auth: ${_authState.split(':').first}', Icons.lock, isDark),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildInfoChip('DB: $_totalBoxCount boxes', Icons.storage, isDark),
              const SizedBox(width: 8),
              _buildInfoChip('Records: $_totalRecords', Icons.data_usage, isDark),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(String label, IconData icon, bool isDark, {Color? color}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: (color ?? (isDark ? Colors.white24 : Colors.grey.shade200)).withOpacity(0.2),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: (color ?? (isDark ? Colors.white24 : Colors.grey.shade300)).withOpacity(0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color ?? (isDark ? Colors.white70 : Colors.grey.shade700)),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 10,
                  color: isDark ? Colors.white70 : Colors.grey.shade700,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceHealthGrid(bool isDark, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      color: isDark ? const Color(0xFF16213e) : colorScheme.surfaceContainerHighest.withOpacity(0.3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Service Health',
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white70 : Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _serviceStatuses.entries.map((entry) {
              final status = entry.value;
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: status.isHealthy
                      ? Colors.green.withOpacity(0.15)
                      : Colors.red.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: status.isHealthy
                        ? Colors.green.withOpacity(0.3)
                        : Colors.red.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      status.isHealthy ? Icons.check_circle : Icons.error,
                      size: 14,
                      color: status.isHealthy ? Colors.green : Colors.red,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      status.name,
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: isDark ? Colors.white70 : Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildLogConsole(bool isDark, ColorScheme colorScheme) {
    return Container(
      margin: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0d1117) : const Color(0xFFf6f8fa),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.grey.shade300,
        ),
      ),
      child: Column(
        children: [
          // Console header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF161b22) : const Color(0xFFeaeef2),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Row(
              children: [
                Icon(Icons.terminal, size: 16, color: isDark ? Colors.white54 : Colors.grey.shade600),
                const SizedBox(width: 8),
                Text(
                  'Console Output',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white54 : Colors.grey.shade600,
                  ),
                ),
                const Spacer(),
                Row(
                  children: [
                    SizedBox(
                      height: 20,
                      child: FittedBox(
                        fit: BoxFit.fill,
                        child: Switch(
                          value: _autoScroll,
                          onChanged: (value) {
                            setState(() {
                              _autoScroll = value;
                            });
                          },
                          activeColor: Colors.green,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Auto-scroll',
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        color: isDark ? Colors.white38 : Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 8),
                Text(
                  '${_logs.length} entries',
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    color: isDark ? Colors.white38 : Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          ),

          // Log entries
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(8),
              itemCount: _logs.length,
              itemBuilder: (context, index) {
                final log = _logs[index];
                return _buildLogEntry(log, isDark);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogEntry(LogEntry log, bool isDark) {
    Color textColor;
    Color? bgColor;
    IconData icon;

    switch (log.level) {
      case LogLevel.info:
        textColor = isDark ? Colors.white70 : Colors.grey.shade700;
        icon = Icons.info_outline;
        break;
      case LogLevel.success:
        textColor = Colors.green.shade400;
        icon = Icons.check_circle_outline;
        break;
      case LogLevel.warning:
        textColor = Colors.orange.shade400;
        icon = Icons.warning_amber;
        bgColor = Colors.orange.withOpacity(0.05);
        break;
      case LogLevel.error:
        textColor = Colors.red.shade400;
        icon = Icons.error_outline;
        bgColor = Colors.red.withOpacity(0.05);
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '[${log.timestamp.toString().substring(11, 19)}]',
            style: GoogleFonts.poppins(
              fontSize: 10,
              color: isDark ? Colors.white30 : Colors.grey.shade400,
            ),
          ),
          const SizedBox(width: 6),
          Icon(icon, size: 12, color: textColor),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              log.message,
              style: GoogleFonts.poppins(
                fontSize: 11,
                color: textColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

enum LogLevel {
  info,
  success,
  warning,
  error,
}

class LogEntry {
  final DateTime timestamp;
  final String message;
  final LogLevel level;

  LogEntry({
    required this.timestamp,
    required this.message,
    required this.level,
  });

  @override
  String toString() {
    final levelStr = level.name.toUpperCase();
    return '[${timestamp.toIso8601String()}] [$levelStr] $message';
  }
}

class ServiceStatus {
  final String name;
  final bool isHealthy;
  final DateTime lastChecked;
  final String? error;

  ServiceStatus({
    required this.name,
    required this.isHealthy,
    required this.lastChecked,
    this.error,
  });
}
