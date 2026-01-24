import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:bm_typer/core/models/typing_session.dart';
import 'package:bm_typer/core/providers/user_provider.dart';

class TypingSessionHistory extends ConsumerStatefulWidget {
  final List<String> typedCharacters;
  final bool isDarkMode;

  const TypingSessionHistory({
    Key? key,
    required this.typedCharacters,
    this.isDarkMode = false,
  }) : super(key: key);

  @override
  ConsumerState<TypingSessionHistory> createState() => _TypingSessionHistoryState();
}

class _TypingSessionHistoryState extends ConsumerState<TypingSessionHistory> {
  final ScrollController _scrollController = ScrollController();
  bool _isExpanded = true; // Default to expanded - show history by default

  @override
  void didUpdateWidget(TypingSessionHistory oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Auto-scroll to the end when new characters are added
    if (widget.typedCharacters.length > oldWidget.typedCharacters.length) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDarkMode = theme.brightness == Brightness.dark;
    final surfaceColor = isDarkMode
        ? colorScheme.surfaceVariant.withOpacity(0.7)
        : colorScheme.surface;
    final borderColor = colorScheme.outline.withOpacity(0.2);
    
    // Get current session typed characters
    final typedText = widget.typedCharacters.join();
    
    // Get previous sessions for sidebar display
    final user = ref.watch(currentUserProvider);
    final previousSessions = user?.typingSessions ?? [];
    
    // Get the last session's typed text or lesson info
    String? lastTypedText;
    String? lastSessionInfo;
    if (previousSessions.isNotEmpty) {
      // Get the most recent session
      final lastSession = previousSessions.last;
      lastSessionInfo = '${previousSessions.length} সেশন • শেষ: ${lastSession.lessonId ?? "অনুশীলন"}';
      
      // Find the most recent session with typed text
      for (final session in previousSessions.reversed) {
        if (session.typedText != null && session.typedText!.isNotEmpty) {
          lastTypedText = session.typedText;
          break;
        }
      }
    }

    // FOLDED: Only header bar (~48px), UNFOLDED: Full content (~130px)
    const double headerHeight = 48.0;
    const double contentHeight = 82.0;
    final double totalHeight = _isExpanded ? (headerHeight + contentHeight) : headerHeight;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      height: totalHeight,
      child: Card(
        elevation: 0,
        margin: EdgeInsets.zero,
        color: surfaceColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: borderColor,
            width: 1,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header with title - always visible
              GestureDetector(
                onTap: () {
                  setState(() {
                    _isExpanded = !_isExpanded;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer.withOpacity(0.3),
                    borderRadius: _isExpanded 
                        ? const BorderRadius.only(
                            topLeft: Radius.circular(15),
                            topRight: Radius.circular(15),
                          )
                        : BorderRadius.circular(15),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Left side: Icon + Title + Session count when collapsed
                      Expanded(
                        child: Row(
                          children: [
                            Icon(
                              Icons.history,
                              size: 16,
                              color: colorScheme.primary,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'অনুশীলন ইতিহাস',
                              style: GoogleFonts.hindSiliguri(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: colorScheme.primary,
                              ),
                            ),
                            // Show session count when collapsed
                            if (!_isExpanded && previousSessions.isNotEmpty) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: colorScheme.primary.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  '${previousSessions.length} সেশন',
                                  style: GoogleFonts.hindSiliguri(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                    color: colorScheme.primary,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      // Right side: Actions
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // "সব দেখুন" button - only show when expanded
                          if (_isExpanded)
                            TextButton(
                              onPressed: () => _showFullHistory(context),
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'সব দেখুন',
                                    style: GoogleFonts.hindSiliguri(
                                      fontSize: 12,
                                      color: colorScheme.primary,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Icon(
                                    Icons.open_in_full,
                                    size: 14,
                                    color: colorScheme.primary,
                                  ),
                                ],
                              ),
                            ),
                          // Fold/Unfold button with rotation animation
                          AnimatedRotation(
                            turns: _isExpanded ? 0.5 : 0.0,
                            duration: const Duration(milliseconds: 200),
                            child: Icon(
                              Icons.keyboard_arrow_down,
                              size: 22,
                              color: colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              // Content section - only visible when expanded
              if (_isExpanded) ...[
                Divider(
                  height: 1,
                  thickness: 1,
                  color: colorScheme.outline.withOpacity(0.1),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: _buildHistoryContent(
                      currentTypedText: typedText,
                      lastTypedText: lastTypedText,
                      lastSessionInfo: lastSessionInfo,
                      colorScheme: colorScheme,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// Build sidebar history content - shows typed text or session info
  Widget _buildHistoryContent({
    required String currentTypedText,
    required String? lastTypedText,
    String? lastSessionInfo,
    required ColorScheme colorScheme,
  }) {
    // Priority: Current session > Last session typed text > Session info
    String? displayText;
    bool isSessionInfo = false;
    
    if (currentTypedText.isNotEmpty) {
      displayText = currentTypedText;
    } else if (lastTypedText != null && lastTypedText.isNotEmpty) {
      displayText = lastTypedText;
    } else if (lastSessionInfo != null) {
      displayText = lastSessionInfo;
      isSessionInfo = true;
    }
    
    if (displayText == null || displayText.isEmpty) {
      return Center(
        child: Text(
          'এখনো কোন টাইপিং ইতিহাস নেই',
          style: GoogleFonts.hindSiliguri(
            fontSize: 12,
            fontStyle: FontStyle.italic,
            color: colorScheme.onSurfaceVariant.withOpacity(0.7),
          ),
        ),
      );
    }
    
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: ShaderMask(
            shaderCallback: (Rect rect) {
              return LinearGradient(
                begin: Alignment.centerRight,
                end: Alignment.centerLeft,
                colors: [
                  Colors.transparent,
                  Colors.black,
                  Colors.black,
                  Colors.transparent,
                ],
                stops: const [0.0, 0.05, 0.95, 1.0],
              ).createShader(rect);
            },
            blendMode: BlendMode.dstIn,
            child: SingleChildScrollView(
              controller: _scrollController,
              scrollDirection: Axis.horizontal,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Text(
                  displayText,
                  style: GoogleFonts.notoSans(
                    fontSize: 16,
                    color: colorScheme.onSurface,
                  ),
                ),
              ),
            ),
          ),
        ),
        if (_isExpanded)
          SizedBox(
            height: 24,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  currentTypedText.isNotEmpty 
                      ? 'বর্তমান সেশন • ${currentTypedText.length} অক্ষর'
                      : 'শেষ সেশন থেকে',
                  style: GoogleFonts.hindSiliguri(
                    fontSize: 11,
                    color: colorScheme.onSurfaceVariant.withOpacity(0.7),
                  ),
                ),
                if (currentTypedText.isNotEmpty)
                  TextButton(
                    onPressed: _scrollToEnd,
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      visualDensity: VisualDensity.compact,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'শেষে যান',
                          style: GoogleFonts.hindSiliguri(
                            fontSize: 12,
                            color: colorScheme.primary,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.arrow_forward,
                          size: 14,
                          color: colorScheme.primary,
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }

  void _scrollToEnd() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _showFullHistory(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final typedText = widget.typedCharacters.join();

    showDialog(
      context: context,
      builder: (dialogContext) => Consumer(
        builder: (context, ref, child) {
          // Get typing sessions from Firebase (user state) - REACTIVE
          final user = ref.watch(currentUserProvider);
          final allSessions = user?.typingSessions ?? [];
          final completedLessons = user?.completedLessons ?? [];
          
          // Sort by timestamp descending (newest first)
          final sortedSessions = List<TypingSession>.from(allSessions)
            ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
          
          return AlertDialog(
            backgroundColor: isDark 
                ? colorScheme.surfaceVariant.withOpacity(0.95)
                : colorScheme.surface,
            title: Row(
              children: [
                Icon(
                  Icons.history,
                  size: 24,
                  color: colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'টাইপিং ইতিহাস',
                  style: GoogleFonts.hindSiliguri(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            content: SizedBox(
              width: double.maxFinite,
              height: 500,
              child: DefaultTabController(
                length: 2,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TabBar(
                      labelColor: colorScheme.primary,
                      unselectedLabelColor: colorScheme.onSurfaceVariant,
                      indicatorColor: colorScheme.primary,
                      tabs: [
                        Tab(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.cloud_done, size: 18),
                              const SizedBox(width: 6),
                              Text('সেভ করা (${sortedSessions.length})', 
                                style: GoogleFonts.hindSiliguri(fontSize: 13)),
                            ],
                          ),
                        ),
                        Tab(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.edit, size: 18),
                              const SizedBox(width: 6),
                              Text('বর্তমান সেশন', 
                                style: GoogleFonts.hindSiliguri(fontSize: 13)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: TabBarView(
                        children: [
                          // Tab 1: Firebase saved sessions with expandable details
                          _buildSavedSessionsTab(
                            sortedSessions: sortedSessions,
                            completedLessons: completedLessons,
                            colorScheme: colorScheme,
                          ),
                          // Tab 2: Current session typed characters
                          _buildCurrentSessionTab(
                            typedText: typedText,
                            colorScheme: colorScheme,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: Text(
                  'বন্ধ করুন',
                  style: GoogleFonts.hindSiliguri(
                    color: colorScheme.primary,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSavedSessionsTab({
    required List<TypingSession> sortedSessions,
    required List<String> completedLessons,
    required ColorScheme colorScheme,
  }) {
    if (sortedSessions.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.keyboard_alt_outlined,
              size: 48,
              color: colorScheme.onSurfaceVariant.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'এখনো কোন টাইপিং ইতিহাস সেভ নেই',
              style: GoogleFonts.hindSiliguri(
                fontSize: 14,
                fontStyle: FontStyle.italic,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'অনুশীলন সম্পন্ন করলে ইতিহাস সেভ হবে',
              style: GoogleFonts.hindSiliguri(
                fontSize: 12,
                color: colorScheme.onSurfaceVariant.withOpacity(0.7),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: sortedSessions.length,
      itemBuilder: (context, index) {
        final session = sortedSessions[index];
        final formattedDate = DateFormat('dd MMM yyyy, hh:mm a').format(session.timestamp);
        
        // Get lesson name - improve display for old "Practice" entries
        String lessonName;
        if (session.lessonId == null || session.lessonId == 'Practice' || session.lessonId!.isEmpty) {
          // For old sessions without proper lessonId, try to show typed text preview
          if (session.typedText != null && session.typedText!.isNotEmpty) {
            final preview = session.typedText!.length > 30 
                ? '${session.typedText!.substring(0, 30)}...'
                : session.typedText!;
            lessonName = 'অনুশীলন: $preview';
          } else {
            lessonName = 'সাধারণ অনুশীলন • ${session.wpm.toInt()} WPM';
          }
        } else {
          lessonName = session.lessonId!;
        }
        
        // Check if this lesson is completed
        final isCompleted = session.lessonId != null && 
            (completedLessons.contains(session.lessonId) ||
             session.lessonId!.contains('সম্পন্ন') ||
             session.lessonId!.contains('✓'));
        
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 4),
          elevation: 0,
          color: colorScheme.surfaceVariant.withOpacity(0.3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: colorScheme.outline.withOpacity(0.1),
            ),
          ),
          child: ExpansionTile(
            tilePadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            leading: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer.withOpacity(0.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '${session.wpm.toInt()}',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.primary,
                    ),
                  ),
                  Text(
                    'WPM',
                    style: GoogleFonts.poppins(
                      fontSize: 8,
                      color: colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),
            title: Row(
              children: [
                Expanded(
                  child: Text(
                    lessonName,
                    style: GoogleFonts.hindSiliguri(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: colorScheme.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                // Show checkmark for completed lessons
                if (isCompleted)
                  Container(
                    margin: const EdgeInsets.only(left: 8),
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check,
                      size: 14,
                      color: Colors.green,
                    ),
                  ),
              ],
            ),
            subtitle: Text(
              formattedDate,
              style: GoogleFonts.poppins(
                fontSize: 11,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: session.accuracy >= 90 
                        ? Colors.green.withOpacity(0.2)
                        : session.accuracy >= 70
                            ? Colors.orange.withOpacity(0.2)
                            : Colors.red.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${session.accuracy.toStringAsFixed(1)}%',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: session.accuracy >= 90 
                          ? Colors.green
                          : session.accuracy >= 70
                              ? Colors.orange
                              : Colors.red,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.keyboard_arrow_down,
                  size: 20,
                  color: colorScheme.onSurfaceVariant,
                ),
              ],
            ),
            children: [
              // Expanded details - Stats + Typed Text
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colorScheme.surface.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Stats row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildDetailStat(
                          icon: Icons.speed,
                          label: 'গতি',
                          value: '${session.wpm.toInt()} WPM',
                          colorScheme: colorScheme,
                        ),
                        _buildDetailStat(
                          icon: Icons.percent,
                          label: 'সঠিকতা',
                          value: '${session.accuracy.toStringAsFixed(1)}%',
                          colorScheme: colorScheme,
                        ),
                        _buildDetailStat(
                          icon: Icons.schedule,
                          label: 'সময়',
                          value: DateFormat('hh:mm a').format(session.timestamp),
                          colorScheme: colorScheme,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    
                    // Typed text section
                    if (session.typedText != null && session.typedText!.isNotEmpty) ...[
                      Container(
                        padding: const EdgeInsets.all(4),
                        child: Row(
                          children: [
                            Icon(
                              Icons.keyboard,
                              size: 14,
                              color: colorScheme.primary,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'টাইপ করা টেক্সট:',
                              style: GoogleFonts.hindSiliguri(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceVariant.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: colorScheme.outline.withOpacity(0.2),
                          ),
                        ),
                        child: SelectableText(
                          session.typedText!,
                          style: GoogleFonts.notoSans(
                            fontSize: 13,
                            color: colorScheme.onSurface,
                            height: 1.4,
                          ),
                          maxLines: 5,
                        ),
                      ),
                    ] else
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceVariant.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.info_outline,
                              size: 14,
                              color: colorScheme.onSurfaceVariant.withOpacity(0.6),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'টাইপ করা টেক্সট সেভ হয়নি',
                              style: GoogleFonts.hindSiliguri(
                                fontSize: 12,
                                fontStyle: FontStyle.italic,
                                color: colorScheme.onSurfaceVariant.withOpacity(0.6),
                              ),
                            ),
                          ],
                        ),
                      ),
                    
                    const SizedBox(height: 8),
                    
                    // Completion status
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isCompleted 
                            ? Colors.green.withOpacity(0.1)
                            : colorScheme.primaryContainer.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            isCompleted ? Icons.check_circle : Icons.info_outline,
                            size: 16,
                            color: isCompleted ? Colors.green : colorScheme.primary,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              isCompleted 
                                  ? 'এই লেসনটি সম্পন্ন হয়েছে ✓'
                                  : 'লেসন: ${session.lessonId ?? "সাধারণ অনুশীলন"}',
                              style: GoogleFonts.hindSiliguri(
                                fontSize: 12,
                                color: isCompleted 
                                    ? Colors.green
                                    : colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailStat({
    required IconData icon,
    required String label,
    required String value,
    required ColorScheme colorScheme,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 20, color: colorScheme.primary),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.hindSiliguri(
            fontSize: 10,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildCurrentSessionTab({
    required String typedText,
    required ColorScheme colorScheme,
  }) {
    if (widget.typedCharacters.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.keyboard,
              size: 48,
              color: colorScheme.onSurfaceVariant.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'এই সেশনে এখনো কিছু টাইপ হয়নি',
              style: GoogleFonts.hindSiliguri(
                fontSize: 14,
                fontStyle: FontStyle.italic,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer.withOpacity(0.3),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 16,
                  color: colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'টাইপ করা অক্ষর: ${widget.typedCharacters.length}',
                  style: GoogleFonts.hindSiliguri(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colorScheme.surfaceVariant.withOpacity(0.3),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: colorScheme.outline.withOpacity(0.2),
              ),
            ),
            child: SelectableText(
              typedText,
              style: GoogleFonts.notoSans(
                fontSize: 16,
                color: colorScheme.onSurface,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
