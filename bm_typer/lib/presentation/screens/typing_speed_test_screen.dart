import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:bm_typer/core/providers/user_provider.dart';
import 'package:bm_typer/core/services/sound_service.dart';
import 'package:bm_typer/core/providers/sound_provider.dart';
import 'package:bm_typer/data/english_paragraph_data.dart';

enum TestDuration { oneMinute, twoMinutes, fiveMinutes }

enum TestDifficulty { easy, medium, hard }

class TypingSpeedTestScreen extends ConsumerStatefulWidget {
  const TypingSpeedTestScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<TypingSpeedTestScreen> createState() =>
      _TypingSpeedTestScreenState();
}

class _TypingSpeedTestScreenState extends ConsumerState<TypingSpeedTestScreen> {
  final TextEditingController _textEditingController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  TestDuration _selectedDuration = TestDuration.oneMinute;
  TestDifficulty _selectedDifficulty = TestDifficulty.medium;

  String _targetText = '';
  String _typedText = '';

  bool _isTestActive = false;
  bool _isTestComplete = false;

  int _remainingSeconds = 60;
  Timer? _timer;

  double _currentWpm = 0;
  double _accuracy = 0;
  int _correctChars = 0;
  int _incorrectChars = 0;

  Map<String, dynamic> _testResults = {};

  @override
  void initState() {
    super.initState();
    _loadTestText();
  }

  @override
  void dispose() {
    _textEditingController.dispose();
    _focusNode.dispose();
    _timer?.cancel();
    super.dispose();
  }

  void _loadTestText() {
    List<String> paragraphs;
    switch (_selectedDifficulty) {
      case TestDifficulty.easy:
        paragraphs = EnglishParagraphData.easyParagraphs;
        break;
      case TestDifficulty.medium:
        paragraphs = EnglishParagraphData.mediumParagraphs;
        break;
      case TestDifficulty.hard:
        paragraphs = EnglishParagraphData.hardParagraphs;
        break;
    }
    final random = paragraphs[DateTime.now().millisecondsSinceEpoch % paragraphs.length];
    setState(() {
      _targetText = random;
      _typedText = '';
      _textEditingController.text = '';
    });
  }

  void _startTest() {
    switch (_selectedDuration) {
      case TestDuration.oneMinute:
        _remainingSeconds = 60;
        break;
      case TestDuration.twoMinutes:
        _remainingSeconds = 120;
        break;
      case TestDuration.fiveMinutes:
        _remainingSeconds = 300;
        break;
    }

    setState(() {
      _isTestActive = true;
      _isTestComplete = false;
      _currentWpm = 0;
      _accuracy = 0;
      _correctChars = 0;
      _incorrectChars = 0;
      _typedText = '';
      _textEditingController.text = '';
      _testResults = {};
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_remainingSeconds > 0) {
          _remainingSeconds--;
          _calculateStats();
        } else {
          _completeTest();
        }
      });
    });

    _focusNode.requestFocus();
  }

  void _calculateStats() {
    if (_typedText.isEmpty) {
      setState(() {
        _currentWpm = 0;
        _accuracy = 0;
      });
      return;
    }

    final elapsedMinutes = _getDurationInMinutes() - (_remainingSeconds / 60);
    if (elapsedMinutes <= 0) return;

    _correctChars = 0;
    _incorrectChars = 0;

    for (int i = 0; i < _typedText.length && i < _targetText.length; i++) {
      if (_typedText[i] == _targetText[i]) {
        _correctChars++;
      } else {
        _incorrectChars++;
      }
    }

    final netWpm = ((_typedText.length - _incorrectChars) / 5) / elapsedMinutes;
    final totalChars = _correctChars + _incorrectChars;
    final accuracyValue = totalChars > 0 ? _correctChars / totalChars : 0;

    setState(() {
      _currentWpm = netWpm > 0 ? netWpm : 0;
      _accuracy = accuracyValue.toDouble();
    });
  }

  void _completeTest() {
    _timer?.cancel();
    _calculateStats();

    _testResults = {
      'wpm': _currentWpm,
      'accuracy': _accuracy,
      'correctChars': _correctChars,
      'incorrectChars': _incorrectChars,
      'totalChars': _typedText.length,
      'duration': _getDurationInMinutes(),
      'difficulty': _selectedDifficulty.toString().split('.').last,
      'timestamp': DateTime.now(),
    };

    setState(() {
      _isTestActive = false;
      _isTestComplete = true;
    });

    _saveResults();
  }

  void _saveResults() {
    final user = ref.read(currentUserProvider);
    if (user == null) return;
  }

  double _getDurationInMinutes() {
    switch (_selectedDuration) {
      case TestDuration.oneMinute:
        return 1.0;
      case TestDuration.twoMinutes:
        return 2.0;
      case TestDuration.fiveMinutes:
        return 5.0;
    }
  }

  void _handleTextChanged(String text) {
    if (!_isTestActive) return;

    setState(() {
      _typedText = text;
    });

    final soundService = ref.read(soundServiceProvider);

    if (_typedText.length >= _targetText.length) {
      _completeTest();
    }

    _calculateStats();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      if (!_isTestActive && !_isTestComplete)
                        _buildTestSetupSection(context, colorScheme, isDark),
                      if (_isTestActive)
                        _buildActiveTestSection(context, colorScheme, isDark),
                      if (_isTestComplete)
                        _buildTestResultsSection(context, colorScheme, isDark),
                    ],
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
          Icon(Icons.speed_rounded, color: colorScheme.primary, size: 28),
          const SizedBox(width: 12),
          Text(
            'টাইপিং স্পিড টেস্ট',
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

  Widget _buildTestSetupSection(BuildContext context, ColorScheme colorScheme, bool isDark) {
    return Column(
      children: [
        // Duration Selection
        _buildGlassCard(
          isDark: isDark,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'সময়কাল',
                style: GoogleFonts.hindSiliguri(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  _buildDurationOption(context, TestDuration.oneMinute, '১ মিনিট', colorScheme, isDark),
                  const SizedBox(width: 12),
                  _buildDurationOption(context, TestDuration.twoMinutes, '২ মিনিট', colorScheme, isDark),
                  const SizedBox(width: 12),
                  _buildDurationOption(context, TestDuration.fiveMinutes, '৫ মিনিট', colorScheme, isDark),
                ],
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Difficulty Selection
        _buildGlassCard(
          isDark: isDark,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'কঠিনতার স্তর',
                style: GoogleFonts.hindSiliguri(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  _buildDifficultyOption(context, TestDifficulty.easy, 'সহজ', Colors.green, isDark),
                  const SizedBox(width: 12),
                  _buildDifficultyOption(context, TestDifficulty.medium, 'মাঝারি', Colors.orange, isDark),
                  const SizedBox(width: 12),
                  _buildDifficultyOption(context, TestDifficulty.hard, 'কঠিন', Colors.red, isDark),
                ],
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 24),
        
        // Start Button
        SizedBox(
          width: double.infinity,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                colors: [colorScheme.primary, colorScheme.secondary],
              ),
              boxShadow: [
                BoxShadow(
                  color: colorScheme.primary.withOpacity(0.4),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: ElevatedButton.icon(
              onPressed: _startTest,
              icon: const Icon(Icons.play_arrow_rounded, size: 28),
              label: Text(
                'টেস্ট শুরু করুন',
                style: GoogleFonts.hindSiliguri(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ),
        ),
        
        const SizedBox(height: 24),
        
        // How it works
        _buildGlassCard(
          isDark: isDark,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.info_outline_rounded, color: colorScheme.primary),
                  const SizedBox(width: 8),
                  Text(
                    'কিভাবে কাজ করে',
                    style: GoogleFonts.hindSiliguri(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildInfoItem('১. সময়কাল এবং কঠিনতার স্তর বাছাই করুন', isDark),
              _buildInfoItem('২. "টেস্ট শুরু করুন" বাটনে ক্লিক করুন', isDark),
              _buildInfoItem('৩. প্রদর্শিত টেক্সট টাইপ করুন', isDark),
              _buildInfoItem('৪. সময় শেষে বিস্তারিত ফলাফল দেখুন', isDark),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoItem(String text, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Text(
        text,
        style: GoogleFonts.hindSiliguri(
          fontSize: 14,
          color: (isDark ? Colors.white : Colors.black).withOpacity(0.7),
        ),
      ),
    );
  }

  Widget _buildDurationOption(BuildContext context, TestDuration duration, String label, ColorScheme colorScheme, bool isDark) {
    final isSelected = _selectedDuration == duration;
    
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedDuration = duration),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: isSelected ? colorScheme.primary : (isDark ? Colors.white : Colors.black).withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? colorScheme.primary : (isDark ? Colors.white : Colors.black).withOpacity(0.1),
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: GoogleFonts.hindSiliguri(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.black54),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDifficultyOption(BuildContext context, TestDifficulty difficulty, String label, Color color, bool isDark) {
    final isSelected = _selectedDifficulty == difficulty;
    
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() => _selectedDifficulty = difficulty);
          _loadTestText();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: isSelected ? color.withOpacity(0.2) : (isDark ? Colors.white : Colors.black).withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: isSelected ? color : (isDark ? Colors.white : Colors.black).withOpacity(0.1), width: 2),
          ),
          child: Center(
            child: Text(
              label,
              style: GoogleFonts.hindSiliguri(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? color : (isDark ? Colors.white70 : Colors.black54),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActiveTestSection(BuildContext context, ColorScheme colorScheme, bool isDark) {
    return Column(
      children: [
        // Stats bar
        _buildGlassCard(
          isDark: isDark,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem('সময়', _formatTime(_remainingSeconds), Icons.timer_rounded, Colors.blue, isDark),
              _buildStatItem('WPM', _currentWpm.toStringAsFixed(0), Icons.speed_rounded, Colors.green, isDark),
              _buildStatItem('নির্ভুলতা', '${(_accuracy * 100).toStringAsFixed(0)}%', Icons.check_circle_rounded, Colors.orange, isDark),
            ],
          ),
        ),
        
        const SizedBox(height: 20),
        
        // Target text
        _buildGlassCard(
          isDark: isDark,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'এই টেক্সট টাইপ করুন:',
                style: GoogleFonts.hindSiliguri(
                  fontSize: 14,
                  color: (isDark ? Colors.white : Colors.black).withOpacity(0.6),
                ),
              ),
              const SizedBox(height: 12),
              RichText(
                text: TextSpan(children: _buildHighlightedText(isDark, colorScheme)),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 20),
        
        // Input field
        Container(
          decoration: BoxDecoration(
            color: (isDark ? Colors.white : Colors.black).withOpacity(0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: colorScheme.primary.withOpacity(0.3)),
          ),
          child: TextField(
            controller: _textEditingController,
            focusNode: _focusNode,
            onChanged: _handleTextChanged,
            maxLines: 5,
            style: GoogleFonts.jetBrainsMono(
              fontSize: 16,
              color: isDark ? Colors.white : Colors.black87,
            ),
            decoration: InputDecoration(
              hintText: 'এখানে টাইপ শুরু করুন...',
              hintStyle: GoogleFonts.hindSiliguri(
                color: (isDark ? Colors.white : Colors.black).withOpacity(0.3),
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(16),
            ),
          ),
        ),
        
        const SizedBox(height: 16),
        
        TextButton.icon(
          onPressed: () {
            _timer?.cancel();
            setState(() {
              _isTestActive = false;
              _isTestComplete = false;
            });
          },
          icon: Icon(Icons.cancel_rounded, color: Colors.red.shade400),
          label: Text('টেস্ট বাতিল', style: GoogleFonts.hindSiliguri(color: Colors.red.shade400)),
        ),
      ],
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color, bool isDark) {
    return Column(
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
          label,
          style: GoogleFonts.hindSiliguri(
            fontSize: 12,
            color: (isDark ? Colors.white : Colors.black).withOpacity(0.6),
          ),
        ),
      ],
    );
  }

  Widget _buildTestResultsSection(BuildContext context, ColorScheme colorScheme, bool isDark) {
    return Column(
      children: [
        // Trophy icon
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.amber.withOpacity(0.2),
          ),
          child: Icon(Icons.emoji_events_rounded, size: 64, color: Colors.amber),
        ),
        const SizedBox(height: 16),
        Text(
          'টেস্ট সম্পন্ন!',
          style: GoogleFonts.hindSiliguri(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        const SizedBox(height: 24),
        
        // Result cards
        Row(
          children: [
            Expanded(child: _buildResultCard('WPM', _currentWpm.toStringAsFixed(0), Icons.speed_rounded, colorScheme.primary, isDark)),
            const SizedBox(width: 16),
            Expanded(child: _buildResultCard(
              'নির্ভুলতা',
              '${(_accuracy * 100).toStringAsFixed(0)}%',
              Icons.check_circle_rounded,
              _accuracy > 0.95 ? Colors.green : _accuracy > 0.85 ? Colors.orange : Colors.red,
              isDark,
            )),
          ],
        ),
        
        const SizedBox(height: 16),
        
        // Detailed stats
        _buildGlassCard(
          isDark: isDark,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'বিস্তারিত পরিসংখ্যান',
                style: GoogleFonts.hindSiliguri(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 16),
              _buildDetailRow('মোট অক্ষর', '${_typedText.length}', isDark),
              _buildDetailRow('সঠিক অক্ষর', '$_correctChars', isDark),
              _buildDetailRow('ভুল অক্ষর', '$_incorrectChars', isDark),
              _buildDetailRow('সময়কাল', '${_getDurationInMinutes().toInt()} মিনিট', isDark),
              _buildDetailRow('কঠিনতা', _getDifficultyName(), isDark),
            ],
          ),
        ),
        
        const SizedBox(height: 24),
        
        // Action buttons
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {
                  _loadTestText();
                  _startTest();
                },
                icon: const Icon(Icons.replay_rounded),
                label: Text('আবার চেষ্টা', style: GoogleFonts.hindSiliguri()),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => setState(() => _isTestComplete = false),
                icon: const Icon(Icons.add_rounded),
                label: Text('নতুন টেস্ট', style: GoogleFonts.hindSiliguri()),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildResultCard(String label, String value, IconData icon, Color color, bool isDark) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 32),
              const SizedBox(height: 12),
              Text(
                value,
                style: GoogleFonts.poppins(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              Text(
                label,
                style: GoogleFonts.hindSiliguri(
                  fontSize: 14,
                  color: (isDark ? Colors.white : Colors.black).withOpacity(0.6),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.hindSiliguri(
              color: (isDark ? Colors.white : Colors.black).withOpacity(0.7),
            ),
          ),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlassCard({required bool isDark, required Widget child}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: (isDark ? Colors.white : Colors.black).withOpacity(isDark ? 0.1 : 0.05),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: (isDark ? Colors.white : Colors.black).withOpacity(0.1)),
          ),
          child: child,
        ),
      ),
    );
  }

  List<TextSpan> _buildHighlightedText(bool isDark, ColorScheme colorScheme) {
    List<TextSpan> spans = [];
    
    for (int i = 0; i < _targetText.length; i++) {
      Color color;
      FontWeight weight = FontWeight.normal;
      Color? bgColor;

      if (i < _typedText.length) {
        color = _typedText[i] == _targetText[i] ? Colors.green : Colors.red;
      } else if (i == _typedText.length) {
        color = colorScheme.primary;
        weight = FontWeight.bold;
        bgColor = colorScheme.primary.withOpacity(0.2);
      } else {
        color = (isDark ? Colors.white : Colors.black).withOpacity(0.5);
      }

      spans.add(TextSpan(
        text: _targetText[i],
        style: GoogleFonts.jetBrainsMono(
          color: color,
          fontSize: 16,
          fontWeight: weight,
          backgroundColor: bgColor,
        ),
      ));
    }

    return spans;
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '$minutes:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  String _getDifficultyName() {
    switch (_selectedDifficulty) {
      case TestDifficulty.easy:
        return 'সহজ';
      case TestDifficulty.medium:
        return 'মাঝারি';
      case TestDifficulty.hard:
        return 'কঠিন';
    }
  }
}
