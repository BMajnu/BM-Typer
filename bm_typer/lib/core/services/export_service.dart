import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:bm_typer/core/models/user_model.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:bm_typer/core/utils/file_helper.dart';

/// Service for exporting user data in various formats (PDF, CSV)
class ExportService {
  static final ExportService _instance = ExportService._internal();
  factory ExportService() => _instance;
  ExportService._internal();

  /// Generates a PDF report of the user's progress and statistics
  Future<Uint8List> generateProgressReportPdf(UserModel user) async {
    final pdf = pw.Document();

    // Load font for Bengali text support
    final fontData = await rootBundle.load('assets/fonts/NotoSans-Regular.ttf');
    final ttf = pw.Font.ttf(fontData);

    // Format date for the report
    final dateFormatter = DateFormat('yyyy-MM-dd HH:mm');
    final currentDate = dateFormatter.format(DateTime.now());

    // Create PDF content
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) => [
          _buildHeader(user, ttf),
          _buildSummarySection(user, ttf),
          _buildStatisticsSection(user, ttf),
          _buildAchievementsSection(user, ttf),
          _buildSessionHistorySection(user, ttf),
        ],
        footer: (pw.Context context) {
          return pw.Container(
            alignment: pw.Alignment.centerRight,
            margin: const pw.EdgeInsets.only(top: 10),
            child: pw.Text(
              'Generated on $currentDate - BM Typer',
              style: pw.TextStyle(
                font: ttf,
                fontSize: 8,
                color: PdfColors.grey700,
              ),
            ),
          );
        },
      ),
    );

    return pdf.save();
  }

  /// Generate a CSV file with the user's typing history
  Future<String> generateTypingHistoryCsv(UserModel user) async {
    final StringBuffer buffer = StringBuffer();

    // Add CSV header
    buffer.writeln('Date,WPM,Accuracy,Lesson');

    // Add typing sessions
    for (final session in user.typingSessions) {
      final date = DateFormat('yyyy-MM-dd HH:mm').format(session.timestamp);
      final wpm = session.wpm.toStringAsFixed(1);
      final accuracy = (session.accuracy * 100).toStringAsFixed(1);
      final lesson = session.lessonId ?? 'N/A';

      buffer.writeln('$date,$wpm,$accuracy%,$lesson');
    }

    // Add historical data if available
    if (user.wpmHistory.isNotEmpty && user.accuracyHistory.isNotEmpty) {
      for (int i = 0; i < user.wpmHistory.length; i++) {
        final wpm = user.wpmHistory[i].toStringAsFixed(1);
        final accuracy = (user.accuracyHistory[i] * 100).toStringAsFixed(1);

        buffer.writeln('Session ${i + 1},$wpm,$accuracy%,Historical');
      }
    }

    return buffer.toString();
  }

  /// Generate a certificate for a completed course
  Future<Uint8List> generateCertificate(
      UserModel user, String courseName) async {
    final pdf = pw.Document();

    // Load font for Bengali text support
    final fontData = await rootBundle.load('assets/fonts/NotoSans-Bold.ttf');
    final ttf = pw.Font.ttf(fontData);

    // Format date for the certificate
    final dateFormatter = DateFormat('MMMM d, yyyy');
    final currentDate = dateFormatter.format(DateTime.now());

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4.landscape,
        build: (pw.Context context) {
          return pw.Container(
            padding: const pw.EdgeInsets.all(20),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(
                color: PdfColors.blue800,
                width: 5,
              ),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                pw.Text(
                  'Certificate of Completion',
                  style: pw.TextStyle(
                    font: ttf,
                    fontSize: 30,
                    color: PdfColors.blue800,
                  ),
                ),
                pw.SizedBox(height: 20),
                pw.Text(
                  'This is to certify that',
                  style: pw.TextStyle(
                    font: ttf,
                    fontSize: 16,
                  ),
                ),
                pw.SizedBox(height: 20),
                pw.Text(
                  user.name,
                  style: pw.TextStyle(
                    font: ttf,
                    fontSize: 24,
                    color: PdfColors.black,
                  ),
                ),
                pw.SizedBox(height: 20),
                pw.Text(
                  'has successfully completed the course',
                  style: pw.TextStyle(
                    font: ttf,
                    fontSize: 16,
                  ),
                ),
                pw.SizedBox(height: 20),
                pw.Text(
                  courseName,
                  style: pw.TextStyle(
                    font: ttf,
                    fontSize: 24,
                    color: PdfColors.blue800,
                  ),
                ),
                pw.SizedBox(height: 20),
                pw.Text(
                  'with an average typing speed of ${user.averageWpm.toStringAsFixed(1)} WPM',
                  style: pw.TextStyle(
                    font: ttf,
                    fontSize: 16,
                  ),
                ),
                pw.SizedBox(height: 20),
                pw.Text(
                  'and an average accuracy of ${(user.averageAccuracy * 100).toStringAsFixed(1)}%',
                  style: pw.TextStyle(
                    font: ttf,
                    fontSize: 16,
                  ),
                ),
                pw.Spacer(),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'Date: $currentDate',
                          style: pw.TextStyle(
                            font: ttf,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Container(
                          width: 150,
                          decoration: const pw.BoxDecoration(
                            border: pw.Border(
                              bottom: pw.BorderSide(
                                color: PdfColors.black,
                              ),
                            ),
                          ),
                        ),
                        pw.Text(
                          'BM Typer',
                          style: pw.TextStyle(
                            font: ttf,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );

    return pdf.save();
  }

  /// Save a file on mobile/desktop platforms or download on Web
  Future<String?> saveFile(Uint8List bytes, String fileName) async {
    return await saveFileUniversal(bytes, fileName);
  }

  /// Download a CSV file
  Future<String?> downloadCsv(String csvContent, String fileName) async {
    return await saveStringFileUniversal(csvContent, fileName);
  }

  // Helper methods for PDF generation
  pw.Widget _buildHeader(UserModel user, pw.Font font) {
    return pw.Header(
      level: 0,
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'BM Typer - Progress Report',
                style: pw.TextStyle(
                  font: font,
                  fontSize: 24,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 5),
              pw.Text(
                'User: ${user.name}',
                style: pw.TextStyle(
                  font: font,
                  fontSize: 14,
                ),
              ),
              pw.Text(
                'Email: ${user.email}',
                style: pw.TextStyle(
                  font: font,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text(
                'Level: ${user.level}',
                style: pw.TextStyle(
                  font: font,
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.Text(
                'XP: ${user.xpPoints}',
                style: pw.TextStyle(
                  font: font,
                  fontSize: 14,
                ),
              ),
              pw.Text(
                'Streak: ${user.streakCount} days',
                style: pw.TextStyle(
                  font: font,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  pw.Widget _buildSummarySection(UserModel user, pw.Font font) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(top: 20),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Summary',
            style: pw.TextStyle(
              font: font,
              fontSize: 18,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.Divider(thickness: 1),
          pw.SizedBox(height: 10),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
            children: [
              _buildSummaryItem(
                'Average Speed',
                '${user.averageWpm.toStringAsFixed(1)} WPM',
                font,
              ),
              _buildSummaryItem(
                'Highest Speed',
                '${user.highestWpm.toStringAsFixed(1)} WPM',
                font,
              ),
              _buildSummaryItem(
                'Average Accuracy',
                '${(user.averageAccuracy * 100).toStringAsFixed(1)}%',
                font,
              ),
              _buildSummaryItem(
                'Lessons Completed',
                '${user.completedLessons.length}',
                font,
              ),
            ],
          ),
        ],
      ),
    );
  }

  pw.Widget _buildSummaryItem(String title, String value, pw.Font font) {
    return pw.Container(
      width: 120,
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(5),
      ),
      child: pw.Column(
        children: [
          pw.Text(
            title,
            style: pw.TextStyle(
              font: font,
              fontSize: 10,
              color: PdfColors.grey700,
            ),
            textAlign: pw.TextAlign.center,
          ),
          pw.SizedBox(height: 5),
          pw.Text(
            value,
            style: pw.TextStyle(
              font: font,
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
            ),
            textAlign: pw.TextAlign.center,
          ),
        ],
      ),
    );
  }

  pw.Widget _buildStatisticsSection(UserModel user, pw.Font font) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(top: 20),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Typing Statistics',
            style: pw.TextStyle(
              font: font,
              fontSize: 18,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.Divider(thickness: 1),
          pw.SizedBox(height: 10),
          pw.Row(
            children: [
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'WPM Progress',
                      style: pw.TextStyle(
                        font: font,
                        fontSize: 14,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 5),
                    _buildWpmChart(user, font),
                  ],
                ),
              ),
              pw.SizedBox(width: 20),
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Accuracy Progress',
                      style: pw.TextStyle(
                        font: font,
                        fontSize: 14,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 5),
                    _buildAccuracyChart(user, font),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  pw.Widget _buildWpmChart(UserModel user, pw.Font font) {
    // Simple chart representation with text
    final wpmHistory = user.wpmHistory;
    if (wpmHistory.isEmpty) {
      return pw.Text(
        'No WPM data available',
        style: pw.TextStyle(
          font: font,
          fontSize: 10,
          color: PdfColors.grey,
        ),
      );
    }

    // For simplicity, just show the data as text
    return pw.Container(
      height: 100,
      child: pw.Text(
        'WPM History: ${wpmHistory.map((wpm) => wpm.toStringAsFixed(1)).join(', ')}',
        style: pw.TextStyle(
          font: font,
          fontSize: 10,
        ),
      ),
    );
  }

  pw.Widget _buildAccuracyChart(UserModel user, pw.Font font) {
    // Simple chart representation with text
    final accuracyHistory = user.accuracyHistory;
    if (accuracyHistory.isEmpty) {
      return pw.Text(
        'No accuracy data available',
        style: pw.TextStyle(
          font: font,
          fontSize: 10,
          color: PdfColors.grey,
        ),
      );
    }

    // For simplicity, just show the data as text
    return pw.Container(
      height: 100,
      child: pw.Text(
        'Accuracy History: ${accuracyHistory.map((acc) => '${(acc * 100).toStringAsFixed(1)}%').join(', ')}',
        style: pw.TextStyle(
          font: font,
          fontSize: 10,
        ),
      ),
    );
  }

  pw.Widget _buildAchievementsSection(UserModel user, pw.Font font) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(top: 20),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Achievements',
            style: pw.TextStyle(
              font: font,
              fontSize: 18,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.Divider(thickness: 1),
          pw.SizedBox(height: 10),
          user.unlockedAchievements.isEmpty
              ? pw.Text(
                  'No achievements unlocked yet',
                  style: pw.TextStyle(
                    font: font,
                    fontSize: 12,
                    color: PdfColors.grey,
                  ),
                )
              : pw.Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: user.unlockedAchievements.map((achievement) {
                    return pw.Container(
                      width: 120,
                      padding: const pw.EdgeInsets.all(8),
                      decoration: pw.BoxDecoration(
                        color: PdfColors.amber50,
                        border: pw.Border.all(color: PdfColors.amber),
                        borderRadius: pw.BorderRadius.circular(5),
                      ),
                      child: pw.Column(
                        children: [
                          pw.Text(
                            '🏆',
                            style: const pw.TextStyle(
                              fontSize: 20,
                            ),
                          ),
                          pw.SizedBox(height: 5),
                          pw.Text(
                            achievement,
                            style: pw.TextStyle(
                              font: font,
                              fontSize: 10,
                            ),
                            textAlign: pw.TextAlign.center,
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

  pw.Widget _buildSessionHistorySection(UserModel user, pw.Font font) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(top: 20),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Recent Sessions',
            style: pw.TextStyle(
              font: font,
              fontSize: 18,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.Divider(thickness: 1),
          pw.SizedBox(height: 10),
          user.typingSessions.isEmpty
              ? pw.Text(
                  'No recent sessions',
                  style: pw.TextStyle(
                    font: font,
                    fontSize: 12,
                    color: PdfColors.grey,
                  ),
                )
              : pw.Table(
                  border: pw.TableBorder.all(color: PdfColors.grey300),
                  children: [
                    // Table header
                    pw.TableRow(
                      decoration: const pw.BoxDecoration(
                        color: PdfColors.grey200,
                      ),
                      children: [
                        _buildTableCell('Date', font, isHeader: true),
                        _buildTableCell('WPM', font, isHeader: true),
                        _buildTableCell('Accuracy', font, isHeader: true),
                        _buildTableCell('Lesson', font, isHeader: true),
                      ],
                    ),
                    // Table rows
                    ...user.typingSessions.take(10).map((session) {
                      final date =
                          DateFormat('yyyy-MM-dd').format(session.timestamp);
                      return pw.TableRow(
                        children: [
                          _buildTableCell(date, font),
                          _buildTableCell(
                              '${session.wpm.toStringAsFixed(1)}', font),
                          _buildTableCell(
                              '${(session.accuracy * 100).toStringAsFixed(1)}%',
                              font),
                          _buildTableCell(session.lessonId ?? 'N/A', font),
                        ],
                      );
                    }).toList(),
                  ],
                ),
        ],
      ),
    );
  }

  pw.Widget _buildTableCell(String text, pw.Font font,
      {bool isHeader = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(5),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          font: font,
          fontSize: 10,
          fontWeight: isHeader ? pw.FontWeight.bold : null,
        ),
      ),
    );
  }
}
