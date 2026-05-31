import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:bm_typer/core/providers/typing_test_provider.dart';
import 'package:bm_typer/core/models/typing_test_result.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

class TypingTestResultsScreen extends ConsumerWidget {
  const TypingTestResultsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final resultsAsync = ref.watch(userTypingTestResultsProvider);
    final bestResultAsync = ref.watch(userBestResultProvider);
    final averageStatsAsync = ref.watch(userAverageStatsProvider);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark
                ? [const Color(0xFF1a1a2e), const Color(0xFF16213e), const Color(0xFF0f0f1a)]
                : [colorScheme.primaryContainer.withOpacity(0.3), colorScheme.surface, colorScheme.surface],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildAppBar(context, colorScheme, isDark),
              Expanded(
                child: resultsAsync.when(
                  data: (results) {
                    if (results.isEmpty) {
                      return _buildEmptyState(context, colorScheme, isDark);
                    }
                    return SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          _buildSummarySection(context, results, bestResultAsync, averageStatsAsync, colorScheme, isDark),
                          const SizedBox(height: 24),
                          _buildProgressChart(context, results, colorScheme, isDark),
                          const SizedBox(height: 24),
                          _buildRecentTestsList(context, results, colorScheme, isDark),
                        ],
                      ),
                    );
                  },
                  loading: () => Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(color: colorScheme.primary),
                        const SizedBox(height: 16),
                        Text('লোড হচ্ছে...', style: GoogleFonts.hindSiliguri(color: isDark ? Colors.white60 : Colors.black54)),
                      ],
                    ),
                  ),
                  error: (error, stack) => Center(
                    child: Text('ত্রুটি: $error', style: GoogleFonts.hindSiliguri(color: Colors.red)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context, ColorScheme colorScheme, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: (isDark ? Colors.white : Colors.black).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: isDark ? Colors.white : Colors.black87),
            ),
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 8),
          Icon(Icons.analytics_rounded, color: colorScheme.primary, size: 28),
          const SizedBox(width: 12),
          Text(
            'টেস্ট ফলাফল',
            style: GoogleFonts.hindSiliguri(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, ColorScheme colorScheme, bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: colorScheme.primary.withOpacity(0.1),
            ),
            child: Icon(Icons.speed_rounded, size: 64, color: colorScheme.primary.withOpacity(0.5)),
          ),
          const SizedBox(height: 24),
          Text(
            'এখনও কোনো ফলাফল নেই',
            style: GoogleFonts.hindSiliguri(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'একটি টাইপিং টেস্ট সম্পন্ন করুন\nআপনার ফলাফল এখানে দেখা যাবে',
            style: GoogleFonts.hindSiliguri(
              color: (isDark ? Colors.white : Colors.black).withOpacity(0.6),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.play_arrow_rounded),
            label: Text('টেস্ট দিন', style: GoogleFonts.hindSiliguri(fontWeight: FontWeight.w600)),
            style: ElevatedButton.styleFrom(
              backgroundColor: colorScheme.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummarySection(
    BuildContext context,
    List<TypingTestResult> results,
    AsyncValue<TypingTestResult?> bestResultAsync,
    AsyncValue<Map<String, double>> averageStatsAsync,
    ColorScheme colorScheme,
    bool isDark,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'সারসংক্ষেপ',
          style: GoogleFonts.hindSiliguri(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildSummaryCard('সম্পন্ন টেস্ট', '${results.length}', Icons.checklist_rounded, colorScheme.primary, isDark),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: bestResultAsync.when(
                data: (best) => _buildSummaryCard('সেরা WPM', best != null ? best.wpm.toStringAsFixed(0) : '0', Icons.emoji_events_rounded, Colors.amber, isDark),
                loading: () => _buildSummaryCard('সেরা WPM', '...', Icons.emoji_events_rounded, Colors.amber, isDark),
                error: (_, __) => _buildSummaryCard('সেরা WPM', '-', Icons.emoji_events_rounded, Colors.amber, isDark),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: averageStatsAsync.when(
                data: (stats) => _buildSummaryCard('গড় WPM', stats['averageWpm']!.toStringAsFixed(0), Icons.speed_rounded, Colors.green, isDark),
                loading: () => _buildSummaryCard('গড় WPM', '...', Icons.speed_rounded, Colors.green, isDark),
                error: (_, __) => _buildSummaryCard('গড় WPM', '-', Icons.speed_rounded, Colors.green, isDark),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: averageStatsAsync.when(
                data: (stats) => _buildSummaryCard('গড় নির্ভুলতা', '${(stats['averageAccuracy']! * 100).toStringAsFixed(0)}%', Icons.check_circle_rounded, Colors.blue, isDark),
                loading: () => _buildSummaryCard('গড় নির্ভুলতা', '...', Icons.check_circle_rounded, Colors.blue, isDark),
                error: (_, __) => _buildSummaryCard('গড় নির্ভুলতা', '-', Icons.check_circle_rounded, Colors.blue, isDark),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSummaryCard(String title, String value, IconData icon, Color color, bool isDark) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(height: 8),
              Text(
                value,
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              Text(
                title,
                style: GoogleFonts.hindSiliguri(
                  fontSize: 12,
                  color: (isDark ? Colors.white : Colors.black).withOpacity(0.6),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressChart(BuildContext context, List<TypingTestResult> results, ColorScheme colorScheme, bool isDark) {
    final chartResults = results.take(10).toList().reversed.toList();
    if (chartResults.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'অগ্রগতি',
          style: GoogleFonts.hindSiliguri(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        const SizedBox(height: 16),
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              height: 220,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: (isDark ? Colors.white : Colors.black).withOpacity(isDark ? 0.1 : 0.05),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: (isDark ? Colors.white : Colors.black).withOpacity(0.1)),
              ),
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: 20,
                    getDrawingHorizontalLine: (value) => FlLine(
                      color: (isDark ? Colors.white : Colors.black).withOpacity(0.1),
                      strokeWidth: 1,
                    ),
                  ),
                  titlesData: FlTitlesData(
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        getTitlesWidget: (value, meta) {
                          if (value.toInt() >= chartResults.length || value.toInt() < 0) return const SizedBox();
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              '${value.toInt() + 1}',
                              style: GoogleFonts.poppins(fontSize: 10, color: (isDark ? Colors.white : Colors.black).withOpacity(0.5)),
                            ),
                          );
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 35,
                        getTitlesWidget: (value, meta) => Text(
                          value.toInt().toString(),
                          style: GoogleFonts.poppins(fontSize: 10, color: (isDark ? Colors.white : Colors.black).withOpacity(0.5)),
                        ),
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  minX: 0,
                  maxX: chartResults.length - 1.0,
                  minY: 0,
                  maxY: _getMaxWpm(chartResults) + 20,
                  lineBarsData: [
                    LineChartBarData(
                      spots: List.generate(chartResults.length, (i) => FlSpot(i.toDouble(), chartResults[i].wpm)),
                      isCurved: true,
                      color: colorScheme.primary,
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: const FlDotData(show: true),
                      belowBarData: BarAreaData(
                        show: true,
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [colorScheme.primary.withOpacity(0.3), colorScheme.primary.withOpacity(0.0)],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  double _getMaxWpm(List<TypingTestResult> results) {
    if (results.isEmpty) return 100;
    double maxWpm = 0;
    for (final result in results) {
      if (result.wpm > maxWpm) maxWpm = result.wpm;
    }
    return maxWpm;
  }

  Widget _buildRecentTestsList(BuildContext context, List<TypingTestResult> results, ColorScheme colorScheme, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'সাম্প্রতিক টেস্ট',
          style: GoogleFonts.hindSiliguri(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        const SizedBox(height: 16),
        ...results.take(10).map((result) => _buildTestResultCard(context, result, colorScheme, isDark)),
      ],
    );
  }

  Widget _buildTestResultCard(BuildContext context, TypingTestResult result, ColorScheme colorScheme, bool isDark) {
    final dateFormat = DateFormat('dd MMM, yyyy • h:mm a');

    Color getWpmColor(double wpm) {
      if (wpm >= 80) return Colors.green;
      if (wpm >= 60) return Colors.lightGreen;
      if (wpm >= 40) return Colors.amber;
      return Colors.orange;
    }

    Color getAccuracyColor(double accuracy) {
      if (accuracy >= 0.95) return Colors.green;
      if (accuracy >= 0.90) return Colors.lightGreen;
      if (accuracy >= 0.80) return Colors.amber;
      return Colors.red;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: (isDark ? Colors.white : Colors.black).withOpacity(isDark ? 0.1 : 0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: (isDark ? Colors.white : Colors.black).withOpacity(0.1)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      dateFormat.format(result.timestamp),
                      style: GoogleFonts.hindSiliguri(
                        fontSize: 12,
                        color: (isDark ? Colors.white : Colors.black).withOpacity(0.5),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: colorScheme.primary.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _getDifficultyName(result.difficulty),
                        style: GoogleFonts.hindSiliguri(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.primary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildStatColumn('WPM', result.wpm.toStringAsFixed(0), getWpmColor(result.wpm), isDark),
                    ),
                    Expanded(
                      child: _buildStatColumn('নির্ভুলতা', '${(result.accuracy * 100).toStringAsFixed(0)}%', getAccuracyColor(result.accuracy), isDark),
                    ),
                    Expanded(
                      child: _buildStatColumn('অক্ষর', '${result.correctChars}/${result.totalChars}', colorScheme.primary, isDark),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: result.accuracy,
                    backgroundColor: (isDark ? Colors.white : Colors.black).withOpacity(0.1),
                    valueColor: AlwaysStoppedAnimation<Color>(getAccuracyColor(result.accuracy)),
                    minHeight: 4,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatColumn(String label, String value, Color color, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.hindSiliguri(
            fontSize: 11,
            color: (isDark ? Colors.white : Colors.black).withOpacity(0.5),
          ),
        ),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  String _getDifficultyName(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'easy':
        return 'সহজ';
      case 'medium':
        return 'মাঝারি';
      case 'hard':
        return 'কঠিন';
      default:
        return difficulty;
    }
  }
}
