import 'dart:async';
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

  int _remainingSeconds = 60; // Default to 1 minute
  Timer? _timer;

  double _currentWpm = 0;
  double _accuracy = 0;
  int _correctChars = 0;
  int _incorrectChars = 0;

  // Results data
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
    // Select text based on difficulty
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

    // Randomly select a paragraph
    final random =
        paragraphs[DateTime.now().millisecondsSinceEpoch % paragraphs.length];

    setState(() {
      _targetText = random;
      _typedText = '';
      _textEditingController.text = '';
    });
  }

  void _startTest() {
    // Set test duration
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

    // Start the timer
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

    // Focus the text field
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

    // Calculate WPM: (characters typed / 5) / time in minutes
    final elapsedMinutes = _getDurationInMinutes() - (_remainingSeconds / 60);
    if (elapsedMinutes <= 0) return;

    // Count correct and incorrect characters
    _correctChars = 0;
    _incorrectChars = 0;

    for (int i = 0; i < _typedText.length && i < _targetText.length; i++) {
      if (_typedText[i] == _targetText[i]) {
        _correctChars++;
      } else {
        _incorrectChars++;
      }
    }

    // Calculate WPM based on correct characters
    final grossWpm = (_typedText.length / 5) / elapsedMinutes;
    final netWpm = ((_typedText.length - _incorrectChars) / 5) / elapsedMinutes;

    // Calculate accuracy
    final totalChars = _correctChars + _incorrectChars;
    final accuracyValue = totalChars > 0 ? _correctChars / totalChars : 0;

    setState(() {
      _currentWpm = netWpm > 0 ? netWpm : 0;
      _accuracy = accuracyValue.toDouble();
    });
  }

  void _completeTest() {
    _timer?.cancel();

    // Calculate final stats
    _calculateStats();

    // Store results
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

    // Update state
    setState(() {
      _isTestActive = false;
      _isTestComplete = true;
    });

    // Save results to user history (to be implemented)
    _saveResults();
  }

  void _saveResults() {
    // TODO: Save results to user history
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    // This will be implemented in a future step
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

    // Play sound
    final soundService = ref.read(soundServiceProvider);

    // Check if the user has reached the end of the text
    if (_typedText.length >= _targetText.length) {
      _completeTest();
    }

    _calculateStats();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Typing Speed Test',
          style: GoogleFonts.hindSiliguri(
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!_isTestActive && !_isTestComplete)
              _buildTestSetupSection(context),
            if (_isTestActive) _buildActiveTestSection(context),
            if (_isTestComplete) _buildTestResultsSection(context),
          ],
        ),
      ),
    );
  }

  Widget _buildTestSetupSection(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Test Duration',
          style: GoogleFonts.hindSiliguri(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: colorScheme.primary,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _buildDurationOption(context, TestDuration.oneMinute, '1 Minute'),
            const SizedBox(width: 12),
            _buildDurationOption(context, TestDuration.twoMinutes, '2 Minutes'),
            const SizedBox(width: 12),
            _buildDurationOption(
                context, TestDuration.fiveMinutes, '5 Minutes'),
          ],
        ),
        const SizedBox(height: 24),
        Text(
          'Difficulty Level',
          style: GoogleFonts.hindSiliguri(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: colorScheme.primary,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _buildDifficultyOption(context, TestDifficulty.easy, 'Easy'),
            const SizedBox(width: 12),
            _buildDifficultyOption(context, TestDifficulty.medium, 'Medium'),
            const SizedBox(width: 12),
            _buildDifficultyOption(context, TestDifficulty.hard, 'Hard'),
          ],
        ),
        const SizedBox(height: 32),
        Center(
          child: ElevatedButton(
            onPressed: _startTest,
            style: ElevatedButton.styleFrom(
              backgroundColor: colorScheme.primary,
              foregroundColor: colorScheme.onPrimary,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              'Start Test',
              style: GoogleFonts.hindSiliguri(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'How It Works',
                  style: GoogleFonts.hindSiliguri(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '1. Select your test duration and difficulty level',
                  style: GoogleFonts.hindSiliguri(fontSize: 14),
                ),
                const SizedBox(height: 4),
                Text(
                  '2. Click "Start Test" and begin typing the displayed text',
                  style: GoogleFonts.hindSiliguri(fontSize: 14),
                ),
                const SizedBox(height: 4),
                Text(
                  '3. Your WPM and accuracy are calculated in real-time',
                  style: GoogleFonts.hindSiliguri(fontSize: 14),
                ),
                const SizedBox(height: 4),
                Text(
                  '4. When the timer ends, you\'ll see your detailed results',
                  style: GoogleFonts.hindSiliguri(fontSize: 14),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDurationOption(
      BuildContext context, TestDuration duration, String label) {
    final colorScheme = Theme.of(context).colorScheme;
    final isSelected = _selectedDuration == duration;

    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedDuration = duration;
          });
        },
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? colorScheme.primaryContainer
                : colorScheme.surfaceVariant,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected
                  ? colorScheme.primary
                  : colorScheme.outline.withOpacity(0.2),
              width: 2,
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: isSelected
                    ? colorScheme.onPrimaryContainer
                    : colorScheme.onSurfaceVariant,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDifficultyOption(
      BuildContext context, TestDifficulty difficulty, String label) {
    final colorScheme = Theme.of(context).colorScheme;
    final isSelected = _selectedDifficulty == difficulty;

    Color getColor() {
      if (!isSelected) return colorScheme.surfaceVariant;

      switch (difficulty) {
        case TestDifficulty.easy:
          return Colors.green.shade100;
        case TestDifficulty.medium:
          return Colors.orange.shade100;
        case TestDifficulty.hard:
          return Colors.red.shade100;
      }
    }

    Color getBorderColor() {
      if (!isSelected) return colorScheme.outline.withOpacity(0.2);

      switch (difficulty) {
        case TestDifficulty.easy:
          return Colors.green;
        case TestDifficulty.medium:
          return Colors.orange;
        case TestDifficulty.hard:
          return Colors.red;
      }
    }

    Color getTextColor() {
      if (!isSelected) return colorScheme.onSurfaceVariant;

      switch (difficulty) {
        case TestDifficulty.easy:
          return Colors.green.shade800;
        case TestDifficulty.medium:
          return Colors.orange.shade800;
        case TestDifficulty.hard:
          return Colors.red.shade800;
      }
    }

    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedDifficulty = difficulty;
          });
          _loadTestText();
        },
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: getColor(),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: getBorderColor(),
              width: 2,
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: getTextColor(),
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActiveTestSection(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Timer and stats bar
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem(
                context,
                'Time',
                _formatTime(_remainingSeconds),
                Icons.timer,
              ),
              _buildStatItem(
                context,
                'WPM',
                _currentWpm.toStringAsFixed(1),
                Icons.speed,
              ),
              _buildStatItem(
                context,
                'Accuracy',
                '${(_accuracy * 100).toStringAsFixed(1)}%',
                Icons.check_circle_outline,
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // Target text display
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colorScheme.surfaceVariant.withOpacity(0.5),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: colorScheme.outline.withOpacity(0.2),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Type this text:',
                style: TextStyle(
                  fontSize: 14,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 8),
              RichText(
                text: TextSpan(
                  children: _buildHighlightedText(),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // Input field
        TextField(
          controller: _textEditingController,
          focusNode: _focusNode,
          onChanged: _handleTextChanged,
          maxLines: 5,
          decoration: InputDecoration(
            hintText: 'Start typing here...',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            fillColor: colorScheme.surface,
            filled: true,
          ),
          style: const TextStyle(
            fontSize: 16,
            height: 1.5,
          ),
        ),

        const SizedBox(height: 16),

        // Cancel button
        Center(
          child: TextButton.icon(
            onPressed: () {
              _timer?.cancel();
              setState(() {
                _isTestActive = false;
                _isTestComplete = false;
              });
            },
            icon: const Icon(Icons.cancel),
            label: const Text('Cancel Test'),
            style: TextButton.styleFrom(
              foregroundColor: colorScheme.error,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTestResultsSection(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: Column(
            children: [
              const Icon(
                Icons.emoji_events,
                size: 64,
                color: Colors.amber,
              ),
              const SizedBox(height: 8),
              Text(
                'Test Complete!',
                style: GoogleFonts.hindSiliguri(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.primary,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // Results cards
        Row(
          children: [
            Expanded(
              child: _buildResultCard(
                context,
                'WPM',
                _currentWpm.toStringAsFixed(1),
                Icons.speed,
                colorScheme.primary,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildResultCard(
                context,
                'Accuracy',
                '${(_accuracy * 100).toStringAsFixed(1)}%',
                Icons.check_circle_outline,
                _accuracy > 0.95
                    ? Colors.green
                    : _accuracy > 0.85
                        ? Colors.orange
                        : Colors.red,
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // Detailed stats
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Detailed Statistics',
                  style: GoogleFonts.hindSiliguri(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                _buildDetailRow('Total Characters', '${_typedText.length}'),
                _buildDetailRow('Correct Characters', '$_correctChars'),
                _buildDetailRow('Incorrect Characters', '$_incorrectChars'),
                _buildDetailRow(
                    'Test Duration', '${_getDurationInMinutes()} minutes'),
                _buildDetailRow('Difficulty',
                    _selectedDifficulty.toString().split('.').last),
              ],
            ),
          ),
        ),

        const SizedBox(height: 24),

        // Action buttons
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () {
                _loadTestText();
                _startTest();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.primary,
                foregroundColor: colorScheme.onPrimary,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: const Text('Try Again'),
            ),
            const SizedBox(width: 16),
            OutlinedButton(
              onPressed: () {
                setState(() {
                  _isTestComplete = false;
                });
              },
              style: OutlinedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: const Text('New Test'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatItem(
      BuildContext context, String label, String value, IconData icon) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        Icon(
          icon,
          color: colorScheme.onPrimaryContainer,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: colorScheme.onPrimaryContainer,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: colorScheme.onPrimaryContainer.withOpacity(0.8),
          ),
        ),
      ],
    );
  }

  Widget _buildResultCard(
    BuildContext context,
    String label,
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
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: color,
              width: 4,
            ),
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 32,
              color: color,
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            Text(
              label,
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

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  List<TextSpan> _buildHighlightedText() {
    List<TextSpan> spans = [];
    final colorScheme = Theme.of(context).colorScheme;

    // Show the entire target text
    for (int i = 0; i < _targetText.length; i++) {
      Color color;

      if (i < _typedText.length) {
        // Character has been typed
        if (_typedText[i] == _targetText[i]) {
          // Correct character
          color = Colors.green;
        } else {
          // Incorrect character
          color = Colors.red;
        }
      } else if (i == _typedText.length) {
        // Current position
        color = colorScheme.primary;
      } else {
        // Not yet typed
        color = colorScheme.onSurfaceVariant;
      }

      spans.add(
        TextSpan(
          text: _targetText[i],
          style: TextStyle(
            color: color,
            fontSize: 16,
            fontWeight:
                i == _typedText.length ? FontWeight.bold : FontWeight.normal,
            backgroundColor: i == _typedText.length
                ? colorScheme.primaryContainer.withOpacity(0.3)
                : null,
          ),
        ),
      );
    }

    return spans;
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '$minutes:${remainingSeconds.toString().padLeft(2, '0')}';
  }
}
