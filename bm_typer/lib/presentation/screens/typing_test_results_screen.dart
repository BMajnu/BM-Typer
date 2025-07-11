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
    final resultsAsync = ref.watch(userTypingTestResultsProvider);
    final bestResultAsync = ref.watch(userBestResultProvider);
    final averageStatsAsync = ref.watch(userAverageStatsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Test Results',
          style: GoogleFonts.hindSiliguri(
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
      ),
      body: resultsAsync.when(
        data: (results) {
          if (results.isEmpty) {
            return _buildEmptyState(context);
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSummarySection(
                    context, ref, results, bestResultAsync, averageStatsAsync),
                const SizedBox(height: 24),
                _buildProgressChart(context, results),
                const SizedBox(height: 24),
                _buildRecentTestsList(context, results),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Text('Error loading results: $error'),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.speed,
            size: 80,
            color: colorScheme.primary.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'No Test Results Yet',
            style: GoogleFonts.hindSiliguri(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Complete a typing test to see your results here',
            style: TextStyle(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: colorScheme.primary,
              foregroundColor: colorScheme.onPrimary,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            ),
            child: const Text('Take a Test'),
          ),
        ],
      ),
    );
  }

  Widget _buildSummarySection(
    BuildContext context,
    WidgetRef ref,
    List<TypingTestResult> results,
    AsyncValue<TypingTestResult?> bestResultAsync,
    AsyncValue<Map<String, double>> averageStatsAsync,
  ) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Summary',
          style: GoogleFonts.hindSiliguri(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildSummaryCard(
                context,
                'Tests Completed',
                '${results.length}',
                Icons.checklist_rounded,
                colorScheme.primary,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: bestResultAsync.when(
                data: (bestResult) => _buildSummaryCard(
                  context,
                  'Best WPM',
                  bestResult != null ? bestResult.wpm.toStringAsFixed(1) : '0',
                  Icons.emoji_events_rounded,
                  Colors.amber,
                ),
                loading: () => _buildSummaryCard(
                  context,
                  'Best WPM',
                  '...',
                  Icons.emoji_events_rounded,
                  Colors.amber,
                ),
                error: (_, __) => _buildSummaryCard(
                  context,
                  'Best WPM',
                  'Error',
                  Icons.emoji_events_rounded,
                  Colors.amber,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: averageStatsAsync.when(
                data: (stats) => _buildSummaryCard(
                  context,
                  'Average WPM',
                  stats['averageWpm']!.toStringAsFixed(1),
                  Icons.speed_rounded,
                  Colors.green,
                ),
                loading: () => _buildSummaryCard(
                  context,
                  'Average WPM',
                  '...',
                  Icons.speed_rounded,
                  Colors.green,
                ),
                error: (_, __) => _buildSummaryCard(
                  context,
                  'Average WPM',
                  'Error',
                  Icons.speed_rounded,
                  Colors.green,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: averageStatsAsync.when(
                data: (stats) => _buildSummaryCard(
                  context,
                  'Average Accuracy',
                  '${(stats['averageAccuracy']! * 100).toStringAsFixed(1)}%',
                  Icons.check_circle_outline_rounded,
                  Colors.blue,
                ),
                loading: () => _buildSummaryCard(
                  context,
                  'Average Accuracy',
                  '...',
                  Icons.check_circle_outline_rounded,
                  Colors.blue,
                ),
                error: (_, __) => _buildSummaryCard(
                  context,
                  'Average Accuracy',
                  'Error',
                  Icons.check_circle_outline_rounded,
                  Colors.blue,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSummaryCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(
              icon,
              color: color,
              size: 32,
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: GoogleFonts.hindSiliguri(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressChart(
      BuildContext context, List<TypingTestResult> results) {
    final colorScheme = Theme.of(context).colorScheme;

    // Take only the last 10 results for the chart
    final chartResults = results.take(10).toList().reversed.toList();

    if (chartResults.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recent Progress',
          style: GoogleFonts.hindSiliguri(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          height: 250,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colorScheme.surfaceVariant.withOpacity(0.3),
            borderRadius: BorderRadius.circular(12),
          ),
          child: LineChart(
            LineChartData(
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: 20,
              ),
              titlesData: FlTitlesData(
                show: true,
                rightTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                topTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 30,
                    getTitlesWidget: (value, meta) {
                      if (value.toInt() >= chartResults.length ||
                          value.toInt() < 0) {
                        return const SizedBox();
                      }

                      // Show index numbers instead of dates for simplicity
                      return Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          '${value.toInt() + 1}',
                          style: const TextStyle(
                            fontSize: 12,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 40,
                    getTitlesWidget: (value, meta) {
                      return Text(
                        value.toInt().toString(),
                        style: const TextStyle(
                          fontSize: 12,
                        ),
                      );
                    },
                  ),
                ),
              ),
              borderData: FlBorderData(
                show: true,
                border: Border.all(
                  color: colorScheme.outline.withOpacity(0.2),
                ),
              ),
              minX: 0,
              maxX: chartResults.length - 1.0,
              minY: 0,
              maxY: _getMaxWpm(chartResults) + 20,
              lineBarsData: [
                // WPM Line
                LineChartBarData(
                  spots: List.generate(chartResults.length, (index) {
                    return FlSpot(index.toDouble(), chartResults[index].wpm);
                  }),
                  isCurved: true,
                  color: colorScheme.primary,
                  barWidth: 3,
                  isStrokeCapRound: true,
                  dotData: FlDotData(show: true),
                  belowBarData: BarAreaData(
                    show: true,
                    color: colorScheme.primary.withOpacity(0.2),
                  ),
                ),
              ],
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
      if (result.wpm > maxWpm) {
        maxWpm = result.wpm;
      }
    }

    return maxWpm;
  }

  Widget _buildRecentTestsList(
      BuildContext context, List<TypingTestResult> results) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recent Tests',
          style: GoogleFonts.hindSiliguri(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 16),
        ...results
            .take(10)
            .map((result) => _buildTestResultCard(context, result)),
      ],
    );
  }

  Widget _buildTestResultCard(BuildContext context, TypingTestResult result) {
    final colorScheme = Theme.of(context).colorScheme;
    final dateFormat = DateFormat('MMM d, yyyy • h:mm a');

    // Determine color based on WPM
    Color getWpmColor(double wpm) {
      if (wpm >= 80) return Colors.green;
      if (wpm >= 60) return Colors.lightGreen;
      if (wpm >= 40) return Colors.amber;
      return Colors.orange;
    }

    // Determine color based on accuracy
    Color getAccuracyColor(double accuracy) {
      if (accuracy >= 0.95) return Colors.green;
      if (accuracy >= 0.90) return Colors.lightGreen;
      if (accuracy >= 0.80) return Colors.amber;
      return Colors.red;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  dateFormat.format(result.timestamp),
                  style: TextStyle(
                    fontSize: 14,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceVariant,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    result.difficulty.toUpperCase(),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'WPM',
                        style: TextStyle(
                          fontSize: 14,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      Text(
                        result.wpm.toStringAsFixed(1),
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: getWpmColor(result.wpm),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Accuracy',
                        style: TextStyle(
                          fontSize: 14,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      Text(
                        '${(result.accuracy * 100).toStringAsFixed(1)}%',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: getAccuracyColor(result.accuracy),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Characters',
                        style: TextStyle(
                          fontSize: 14,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      Text(
                        '${result.correctChars}/${result.totalChars}',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: result.accuracy,
              backgroundColor: colorScheme.surfaceVariant,
              valueColor: AlwaysStoppedAnimation<Color>(
                  getAccuracyColor(result.accuracy)),
              borderRadius: BorderRadius.circular(4),
            ),
          ],
        ),
      ),
    );
  }
}
