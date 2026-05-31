import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bm_typer/core/models/lesson_model.dart';
import 'package:bm_typer/data/local_lesson_data.dart';
import 'package:bm_typer/core/providers/user_provider.dart';
import 'package:bm_typer/core/services/sound_service.dart';
import 'package:bm_typer/core/providers/sound_provider.dart';
import 'package:bm_typer/core/providers/keyboard_layout_provider.dart';
import 'package:bm_typer/core/constants/keyboard_layouts.dart';

class PendingPracticeTransition {
  final int completedLessonIndex;
  final int completedExerciseIndex;
  final int? nextLessonIndex;
  final int? nextExerciseIndex;
  final bool isLessonAdvance;

  const PendingPracticeTransition({
    required this.completedLessonIndex,
    required this.completedExerciseIndex,
    required this.nextLessonIndex,
    required this.nextExerciseIndex,
    required this.isLessonAdvance,
  });

  bool get hasNextStep =>
      nextLessonIndex != null && nextExerciseIndex != null;
}

class TutorState {
  final int currentLessonIndex;
  final int currentExerciseIndex;
  final int charIndex;
  final int mistakes;
  final List<int> incorrectIndices;
  final DateTime? startTime;
  final int wpm;
  final int accuracy;
  final int repsCompleted;
  final bool isTyping;
  final bool isFocused;
  final List<String>
      sessionTypedCharacters; // Track all typed characters in the session
  final bool
      waitingForNextRep; // Add this field to track if waiting for next repetition
  final String? lastKeyPress; // Track previous key press for Bijoy composite logic (Linker)
  final String?
      pendingPreBaseVowel; // Track if a pre-base vowel (i, e, oi) was typed first
  final bool pendingHasanta; // Track if hasanta (্) was typed for vowel composition (G + vowel key)
  final String? pendingPhoneticSequence;
  final PendingPracticeTransition? pendingTransition;

  TutorState({
    this.currentLessonIndex = 0,
    this.currentExerciseIndex = 0,
    this.charIndex = 0,
    this.mistakes = 0,
    this.incorrectIndices = const [],
    this.startTime,
    this.wpm = 0,
    this.accuracy = 100,
    this.repsCompleted = 0,
    this.isTyping = false,
    this.isFocused = false,
    this.sessionTypedCharacters = const [],
    this.waitingForNextRep = false,
    this.lastKeyPress,
    this.pendingPreBaseVowel,
    this.pendingHasanta = false,
    this.pendingPhoneticSequence,
    this.pendingTransition,
  });



  TutorState copyWith({
    int? currentLessonIndex,
    int? currentExerciseIndex,
    int? charIndex,
    int? mistakes,
    List<int>? incorrectIndices,
    DateTime? startTime,
    bool clearStartTime = false,
    int? wpm,
    int? accuracy,
    int? repsCompleted,
    bool? isTyping,
    bool? isFocused,
    List<String>? sessionTypedCharacters,
    bool? waitingForNextRep,
    String? lastKeyPress,
    String? pendingPreBaseVowel,
    bool clearPendingPreBaseVowel = false, // Flag to explicitly clear pending vowel
    bool? pendingHasanta,
    String? pendingPhoneticSequence,
    bool clearPendingPhoneticSequence = false,
    PendingPracticeTransition? pendingTransition,
    bool clearPendingTransition = false,
  }) {
    return TutorState(
      currentLessonIndex: currentLessonIndex ?? this.currentLessonIndex,
      currentExerciseIndex: currentExerciseIndex ?? this.currentExerciseIndex,
      charIndex: charIndex ?? this.charIndex,
      mistakes: mistakes ?? this.mistakes,
      incorrectIndices: incorrectIndices ?? this.incorrectIndices,
      startTime: clearStartTime ? null : startTime ?? this.startTime,
      wpm: wpm ?? this.wpm,
      accuracy: accuracy ?? this.accuracy,
      repsCompleted: repsCompleted ?? this.repsCompleted,
      isTyping: isTyping ?? this.isTyping,
      isFocused: isFocused ?? this.isFocused,
      sessionTypedCharacters:
          sessionTypedCharacters ?? this.sessionTypedCharacters,
      waitingForNextRep:
          waitingForNextRep ?? this.waitingForNextRep,
      lastKeyPress: lastKeyPress ?? this.lastKeyPress,
      pendingPreBaseVowel: clearPendingPreBaseVowel ? null : pendingPreBaseVowel ?? this.pendingPreBaseVowel,
      pendingHasanta: pendingHasanta ?? this.pendingHasanta,
      pendingPhoneticSequence: clearPendingPhoneticSequence
          ? null
          : pendingPhoneticSequence ?? this.pendingPhoneticSequence,
      pendingTransition: clearPendingTransition
          ? null
          : pendingTransition ?? this.pendingTransition,
    );
  }

  Lesson get currentLesson => lessons[currentLessonIndex];
  Exercise get currentExercise => currentLesson.exercises[currentExerciseIndex];
  String get exerciseText => currentExercise.text;
  int get exerciseLength => exerciseText.length;
  bool get isCompleted => charIndex >= exerciseLength;
  bool get isLocked {
    return false; // Unlock all steps for user convenience
  }

  // Check if this is the last exercise in the current lesson
  bool get isLastExerciseInLesson =>
      currentExerciseIndex == currentLesson.exercises.length - 1;

  // Check if all repetitions of the current exercise are completed
  bool get isExerciseFullyCompleted =>
      currentExercise.repetitions <= repsCompleted;

  // Get the character (or conjunct) that the user is EXPECTED to type right now.
  // This handles:
  // 1. Bijoy Pre-base vowel reordering (where visual order != Unicode order)
  // 2. Conjuncts (ফলা) like ্র, ্য, র্ that are typed with single keys
  // 3. Pre-base vowels after conjuncts (e.g., ন্তি = ি → ন → ্ → ত)
  String getExpectedCharacter(bool isBijoy) {
    if (charIndex >= exerciseLength) return '';

    const preBaseVowels = ['ি', 'ে', 'ৈ'];
    const hasanta = '্';

    // Helper: Check if character is a Bengali consonant
    bool isConsonant(String ch) {
      final code = ch.codeUnitAt(0);
      return code >= 0x0995 && code <= 0x09B9;
    }

    // Helper: Find the end of a conjunct starting at idx
    // Returns the index AFTER the last character of the conjunct
    int findConjunctEnd(int idx) {
      int pos = idx;
      if (pos >= exerciseLength || !isConsonant(exerciseText[pos])) return pos;
      pos++;
      
      while (pos < exerciseLength - 1 && exerciseText[pos] == hasanta) {
        if (pos + 1 < exerciseLength && isConsonant(exerciseText[pos + 1])) {
          pos += 2;
        } else {
          break;
        }
      }
      return pos;
    }

    // For Bijoy keyboard layout
    if (isBijoy && charIndex < exerciseLength - 1) {
      final currentChar = exerciseText[charIndex];
      
      // IMPORTANT: If we already have a pending pre-base vowel,
      // the user should type the current character (consonant/hasanta), NOT the vowel again!
      if (pendingPreBaseVowel != null) {
        return currentChar; // Return consonant or hasanta directly
      }
      
      // Check for র-ফলা (্র), য-ফলা (্য), or রেফ (র্)
      // These are typed with single keys: Z, Shift+Z, Shift+A respectively
      final twoChars = exerciseText.substring(charIndex, charIndex + 2);
      if (twoChars == '্র' || twoChars == '্য' || twoChars == 'র্') {
        return twoChars;  // Return the full 2-char conjunct
      }
      
      // Check if current position starts a conjunct (consonant + hasanta)
      if (isConsonant(currentChar) && exerciseText[charIndex + 1] == hasanta) {
        // Find where the conjunct ends
        int conjEnd = findConjunctEnd(charIndex);
        
        // Check if there's a pre-base vowel after the conjunct
        if (conjEnd < exerciseLength && preBaseVowels.contains(exerciseText[conjEnd])) {
          // In Bijoy, we type the pre-base vowel FIRST before the conjunct
          return exerciseText[conjEnd]; // Return the pre-base vowel
        }
      }
      
      // Check for simple Pre-base vowels: ি (09BF), ে (09C7), ৈ (09C8)
      final nextChar = exerciseText[charIndex + 1];
      if (preBaseVowels.contains(nextChar)) {
        // In Bijoy we MUST type the Vowel Sign FIRST.
        return nextChar;
      }
    }
    
    // Default: The character at the current index
    return exerciseText[charIndex];
  }
}

class TutorNotifier extends StateNotifier<TutorState> {
  final Ref _ref;

  TutorNotifier(this._ref) : super(TutorState()) {
    // Initialize with saved position on startup
    _loadSavedPosition();
  }
  
  /// Load saved lesson/exercise position and rep progress on startup
  void _loadSavedPosition() {
    final user = _ref.read(currentUserProvider);
    if (user != null) {
      final savedLessonIndex = user.lastLessonIndex;
      final savedExerciseIndex = user.lastExerciseIndex;
      
      // Validate saved indices
      if (savedLessonIndex >= 0 && savedLessonIndex < lessons.length) {
        final lesson = lessons[savedLessonIndex];
        final exerciseIndex = savedExerciseIndex >= 0 && savedExerciseIndex < lesson.exercises.length
            ? savedExerciseIndex : 0;
        
        // Load saved rep progress
        final savedReps = user.getExerciseRepProgress(savedLessonIndex, exerciseIndex);
        
        debugPrint('📍 Restoring position: Lesson $savedLessonIndex, Exercise $exerciseIndex, Reps: $savedReps');
        
        state = state.copyWith(
          currentLessonIndex: savedLessonIndex,
          currentExerciseIndex: exerciseIndex,
          repsCompleted: savedReps,
        );
      }
    }
  }

  void selectExercise(int index) {
    if (index >= 0 &&
        index < lessons[state.currentLessonIndex].exercises.length) {
      
      // Load saved rep progress for this exercise
      final user = _ref.read(currentUserProvider);
      final savedReps = user?.getExerciseRepProgress(state.currentLessonIndex, index) ?? 0;
      
      state = state.copyWith(
        currentExerciseIndex: index,
        charIndex: 0,
        mistakes: 0,
        incorrectIndices: [],
        clearStartTime: true,
        wpm: 0,
        accuracy: 100,
        isTyping: false,
        repsCompleted: savedReps, // Restore saved reps!
        sessionTypedCharacters: [], // Reset session history for new exercise
        waitingForNextRep: false,
        lastKeyPress: null,
        clearPendingPreBaseVowel: true,
        pendingHasanta: false,
        clearPendingPhoneticSequence: true,
        clearPendingTransition: true,
      );
      
      // Save current position
      _ref.read(currentUserProvider.notifier).updateLastPosition(state.currentLessonIndex, index);
      
      // Skip leading spaces for drill exercises
      _skipSpaces();
    }
  }

  /// Skip space characters in drill exercises (display spacing without requiring typing)
  void _skipSpaces() {
    // Only skip spaces for Drill exercises in Bengali mode
    // English mode requires typing spaces
    if (state.currentExercise.type != ExerciseType.drill) return;
    if (!_ref.read(keyboardLayoutProvider).isBengali) return;
    
    while (state.charIndex < state.exerciseText.length &&
           state.exerciseText[state.charIndex] == ' ') {
      state = state.copyWith(
        charIndex: state.charIndex + 1,
        sessionTypedCharacters: List<String>.from(state.sessionTypedCharacters)..add(' '),
      );
    }
    
    if (state.charIndex >= state.exerciseText.length) {
      _handleExerciseCompletion();
    }
  }

  /// Get the type of the current exercise
  ExerciseType get currentExerciseType => state.currentExercise.type;

  /// Get the source of the current exercise, if available
  String? get currentExerciseSource => state.currentExercise.source;

  /// Get the difficulty level of the current exercise
  int get currentExerciseDifficulty => state.currentExercise.difficultyLevel;

  /// Select a specific lesson by index
  void selectLesson(int index) {
    if (index >= 0 && index < lessons.length) {
      // Find first uncompleted exercise
      int targetExercise = 0;
      final user = _ref.read(currentUserProvider);
      
      if (user != null) {
         final lessonTitle = lessons[index].title;
         final completed = user.completedExercises[lessonTitle] ?? [];
         
         // Find first uncompleted exercise
         for (int i = 0; i < lessons[index].exercises.length; i++) {
             if (!completed.contains(i)) {
                 targetExercise = i;
                 break;
             }
         }
      }
      
      // Load saved rep progress for target exercise
      final savedReps = user?.getExerciseRepProgress(index, targetExercise) ?? 0;
      
      state = state.copyWith(
        currentLessonIndex: index,
        currentExerciseIndex: targetExercise,
        charIndex: 0,
        mistakes: 0,
        incorrectIndices: [],
        clearStartTime: true,
        wpm: 0,
        accuracy: 100,
        repsCompleted: savedReps, // Restore saved reps!
        isTyping: false,
        lastKeyPress: null,
        clearPendingPreBaseVowel: true,
        pendingHasanta: false,
        waitingForNextRep: false,
        sessionTypedCharacters: [],
        clearPendingPhoneticSequence: true,
        clearPendingTransition: true,
      );
      
      // Save current position
      _ref.read(currentUserProvider.notifier).updateLastPosition(index, targetExercise);
    }
  }

  void goToNextLesson() {
    if (state.currentLessonIndex < lessons.length - 1) {
      state = state.copyWith(
        currentLessonIndex: state.currentLessonIndex + 1,
        currentExerciseIndex: 0,
        charIndex: 0,
        mistakes: 0,
        incorrectIndices: [],
        clearStartTime: true,
        wpm: 0,
        accuracy: 100,
        repsCompleted: 0,
        isTyping: false,
        clearPendingPhoneticSequence: true,
      );
    }
  }

  void goToPreviousLesson() {
    if (state.currentLessonIndex > 0) {
      state = state.copyWith(
        currentLessonIndex: state.currentLessonIndex - 1,
        currentExerciseIndex: 0,
        charIndex: 0,
        mistakes: 0,
        incorrectIndices: [],
        clearStartTime: true,
        wpm: 0,
        accuracy: 100,
        repsCompleted: 0,
        isTyping: false,
        clearPendingPhoneticSequence: true,
      );
    }
  }

  void setFocus(bool focused) {
    state = state.copyWith(isFocused: focused);
  }

  bool _matchesPhoneticOutputAtCursor(String output) {
    if (output.isEmpty) return false;

    final endIndex = state.charIndex + output.length;
    if (endIndex > state.exerciseText.length) return false;

    return state.exerciseText.substring(state.charIndex, endIndex) == output;
  }

  void _commitPhoneticOutput(String output, String rawSequence) {
    _ref.read(soundServiceProvider).playSound(SoundType.keyPress);

    final newCharIndex = state.charIndex + output.length;
    final updatedSessionHistory =
        List<String>.from(state.sessionTypedCharacters)..add(output);

    state = state.copyWith(
      charIndex: newCharIndex,
      sessionTypedCharacters: updatedSessionHistory,
      lastKeyPress: rawSequence,
      clearPendingPhoneticSequence: true,
    );

    if (newCharIndex >= state.exerciseText.length) {
      _handleExerciseCompletion();
    } else {
      _updateStats();
      _skipSpaces();
    }
  }

  void _recordPhoneticMistake(String attemptedOutput, String rawSequence) {
    _ref.read(soundServiceProvider).playSound(SoundType.keyError);

    final updatedSessionHistory =
        List<String>.from(state.sessionTypedCharacters)..add(attemptedOutput);
    final newIncorrectIndices =
        List<int>.from(state.incorrectIndices)..add(state.charIndex);

    state = state.copyWith(
      mistakes: state.mistakes + 1,
      incorrectIndices: newIncorrectIndices,
      sessionTypedCharacters: updatedSessionHistory,
      lastKeyPress: rawSequence,
      clearPendingPhoneticSequence: true,
    );
    _updateStats();
  }

  bool _handlePhoneticKeyPress(KeyEvent event) {
    if (event is! KeyDownEvent) return false;

    if (event.logicalKey == LogicalKeyboardKey.backspace) {
      if (state.pendingPhoneticSequence != null &&
          state.pendingPhoneticSequence!.isNotEmpty) {
        state = state.copyWith(clearPendingPhoneticSequence: true);
        return true;
      }
      return false;
    }

    final rawChar = event.character;
    if (rawChar == null || rawChar.isEmpty) {
      return true;
    }

    final startTime = state.startTime ?? DateTime.now();
    if (!state.isTyping) {
      state = state.copyWith(
        startTime: startTime,
        isTyping: true,
      );
    }

    final pendingSequence = state.pendingPhoneticSequence ?? '';
    final combinedSequence = '$pendingSequence$rawChar';
    final matchingEntries =
        PhoneticKeyboardLayout.getMatchingEntriesStartingWith(combinedSequence);
    final exactOutput =
        PhoneticKeyboardLayout.getOutputForSequence(combinedSequence);
    final longerMatchingEntries = matchingEntries
        .where((entry) => entry.key.length > combinedSequence.length)
        .where((entry) => _matchesPhoneticOutputAtCursor(entry.value))
        .toList();
    final exactMatchesExpected =
        exactOutput != null && _matchesPhoneticOutputAtCursor(exactOutput);

    if (longerMatchingEntries.isNotEmpty) {
      state = state.copyWith(
        pendingPhoneticSequence: combinedSequence,
        lastKeyPress: combinedSequence,
      );
      return true;
    }

    if (exactMatchesExpected && exactOutput != null) {
      _commitPhoneticOutput(exactOutput, combinedSequence);
      return true;
    }

    if (matchingEntries.isNotEmpty && !exactMatchesExpected) {
      final shouldWait =
          pendingSequence.isEmpty && exactOutput != null && matchingEntries.any(
            (entry) =>
                entry.key.length > combinedSequence.length &&
                _matchesPhoneticOutputAtCursor(entry.value),
          );

      if (shouldWait) {
        state = state.copyWith(
          pendingPhoneticSequence: combinedSequence,
          lastKeyPress: combinedSequence,
        );
        return true;
      }
    }

    final fallbackOutput = exactOutput ??
        PhoneticKeyboardLayout.getCharacter(rawChar) ??
        combinedSequence;
    _recordPhoneticMistake(fallbackOutput, combinedSequence);
    return true;
  }

  void handleKeyPress(KeyEvent event) {
    if (event is! KeyDownEvent) return;

    // Check if waiting for next repetition and space is pressed
    if (state.waitingForNextRep) {
      if (event.logicalKey == LogicalKeyboardKey.space) {
        _startNextRepetition();
      }
      return;
    }

    if (state.isCompleted) return;

    final currentLayoutState = _ref.read(keyboardLayoutProvider);
    if (currentLayoutState.currentLayout != KeyboardLayout.phonetic &&
        state.pendingPhoneticSequence != null) {
      state = state.copyWith(clearPendingPhoneticSequence: true);
    }

    if (currentLayoutState.currentLayout == KeyboardLayout.phonetic &&
        _handlePhoneticKeyPress(event)) {
      return;
    }

    // Get the typed character
    String? typedChar;
    if (event.logicalKey == LogicalKeyboardKey.backspace) {
      typedChar = 'Backspace';
    } else {
      typedChar = event.character;
      
      // Convert English to Bengali based on keyboard layout
      if (typedChar != null) {
        final layoutState = _ref.read(keyboardLayoutProvider);
        print('DEBUG: Current Layout = ${layoutState.currentLayout}');
        print('DEBUG: isBengali = ${layoutState.isBengali}');
        print('DEBUG: typedChar = "$typedChar"');
        if (layoutState.isBengali && typedChar.isNotEmpty) {
          
          // =====================================================
          // PHONETIC LAYOUT - CHECK FIRST (simpler conversion)
          // =====================================================
          if (layoutState.currentLayout == KeyboardLayout.phonetic) {
            print('DEBUG: Entering Phonetic conversion (FIRST)');
            final converted = layoutState.convertToBengali(typedChar);
            print('DEBUG: Phonetic converted "$typedChar" -> "$converted"');
            if (converted != null) {
              typedChar = converted;
            }
            // Continue to validation logic below (skip Bijoy block)
          }
          // =====================================================
          // BIJOY VOWEL COMPOSITION LOGIC
          // G (হসন্ত/্) + vowel sign key = Full Independent Vowel
          // Example: G + F = আ, G + D = ই, G + S = উ, etc.
          // =====================================================
          else if (layoutState.currentLayout == KeyboardLayout.bijoy) {
            
            // --- STEP 1: Check if we have a pending hasanta waiting for vowel key ---
            if (state.pendingHasanta && event.character != null) {
              // Try to compose a vowel using the current key
              final composedVowel = BijoyKeyboardLayout.getComposedVowel(event.character!);
              
              if (composedVowel != null) {
                // SUCCESS! We have pending G + vowel key = Full Vowel
                _ref.read(soundServiceProvider).playSound(SoundType.keyPress);
                
                // Check if composed vowel matches expected character
                if (state.charIndex < state.exerciseText.length) {
                  final expectedChar = state.exerciseText[state.charIndex];
                  
                  if (composedVowel == expectedChar) {
                    // CORRECT! Add the vowel and advance
                    final newCharIndex = state.charIndex + 1;
                    final updatedSession = List<String>.from(state.sessionTypedCharacters)..add(composedVowel);
                    
                    state = state.copyWith(
                      charIndex: newCharIndex,
                      sessionTypedCharacters: updatedSession,
                      lastKeyPress: event.character,
                      pendingHasanta: false, // Clear pending state
                    );
                    
                    if (newCharIndex >= state.exerciseText.length) {
                      _handleExerciseCompletion();
                    } else {
                      _updateStats();
                      _skipSpaces();
                    }
                    return; // Done, vowel composed successfully
                  } else {
                    // Composed vowel doesn't match - count as mistake
                    final newCharIndex = state.charIndex + 1;
                    final updatedSession = List<String>.from(state.sessionTypedCharacters)..add(composedVowel);
                    final newIncorrect = List<int>.from(state.incorrectIndices)..add(state.charIndex);
                    
                    _ref.read(soundServiceProvider).playSound(SoundType.keyError);
                    
                    state = state.copyWith(
                      charIndex: newCharIndex,
                      mistakes: state.mistakes + 1,
                      incorrectIndices: newIncorrect,
                      sessionTypedCharacters: updatedSession,
                      lastKeyPress: event.character,
                      pendingHasanta: false,
                    );
                    _updateStats();
                    return;
                  }
                }
              } else {
                // User pressed a non-vowel key after hasanta - cancel composition
                // Treat the hasanta as a mistake and continue with current key
                _ref.read(soundServiceProvider).playSound(SoundType.keyError);
                
                final hasantaIndex = state.charIndex;
                final newIncorrect = List<int>.from(state.incorrectIndices)..add(hasantaIndex);
                
                state = state.copyWith(
                  charIndex: state.charIndex + 1,
                  mistakes: state.mistakes + 1,
                  incorrectIndices: newIncorrect,
                  sessionTypedCharacters: List<String>.from(state.sessionTypedCharacters)..add('্'),
                  pendingHasanta: false,
                );
                _updateStats();
                // Continue to process current key normally...
              }
            }
            
            // --- STEP 2: Check if user is pressing G (hasanta) to start vowel composition ---
            // This is valid when the expected character is a full vowel that can be composed
            if (event.character == 'g' && !state.pendingHasanta) {
              final expectedChar = state.charIndex < state.exerciseText.length 
                  ? state.exerciseText[state.charIndex] 
                  : '';
              
              // Check if expected char is a composable vowel (আ, ই, ঈ, উ, ঊ, ঋ, এ, ঐ, ও, ঔ)
              const composableVowels = ['আ', 'ই', 'ঈ', 'উ', 'ঊ', 'ঋ', 'এ', 'ঐ', 'ও', 'ঔ'];
              
              if (composableVowels.contains(expectedChar)) {
                // User is starting vowel composition - DON'T show error!
                // Just play a soft key sound and wait for next key
                _ref.read(soundServiceProvider).playSound(SoundType.keyPress);
                
                // Start timer if not started
                final startTime = state.startTime ?? DateTime.now();
                
                state = state.copyWith(
                  pendingHasanta: true,
                  startTime: startTime,
                  isTyping: true,
                  lastKeyPress: event.character,
                );
                
                return; // Wait for next keystroke (vowel key)
              }
              // If expected char is not a composable vowel, fall through to normal processing
            }
            
            // --- STEP 3: Legacy check for hasanta in session history ---
            // This handles cases where hasanta was already added to session
            final hasHasantaInHistory = state.sessionTypedCharacters.isNotEmpty &&
                state.sessionTypedCharacters.last == '্';
            
            if (hasHasantaInHistory && event.character != null) {
              final composedVowel = BijoyKeyboardLayout.getComposedVowel(event.character!);
              
              if (composedVowel != null) {
                _ref.read(soundServiceProvider).playSound(SoundType.keyPress);
                
                int currentCharIndex = state.charIndex;
                int currentMistakes = state.mistakes;
                List<int> currentIncorrect = List.from(state.incorrectIndices);
                final currentSessionChars = List<String>.from(state.sessionTypedCharacters);
                
                // Remove the hasanta from history
                if (currentSessionChars.isNotEmpty) {
                  currentSessionChars.removeLast();
                }
                
                // Step back the cursor (undo the hasanta position)
                if (currentCharIndex > 0) {
                  final prevIndex = currentCharIndex - 1;
                  if (currentIncorrect.contains(prevIndex)) {
                    currentMistakes = currentMistakes > 0 ? currentMistakes - 1 : 0;
                    currentIncorrect.remove(prevIndex);
                  }
                  currentCharIndex--;
                }
                
                // Check if composed vowel matches expected
                if (currentCharIndex < state.exerciseText.length) {
                  final expectedChar = state.exerciseText[currentCharIndex];
                  
                  if (composedVowel == expectedChar) {
                    currentSessionChars.add(composedVowel);
                    currentCharIndex++;
                    
                    state = state.copyWith(
                      charIndex: currentCharIndex,
                      mistakes: currentMistakes,
                      incorrectIndices: currentIncorrect,
                      sessionTypedCharacters: currentSessionChars,
                      lastKeyPress: event.character,
                      pendingHasanta: false,
                    );
                    
                    if (currentCharIndex >= state.exerciseText.length) {
                      _handleExerciseCompletion();
                    } else {
                      _updateStats();
                      _skipSpaces();
                    }
                    return;
                  }
                }
              }
            }
          }

          // Normal Bijoy mapping (no composition)
          final bengaliChar = BijoyKeyboardLayout.englishToBengali[typedChar];
          if (bengaliChar != null) {
            typedChar = bengaliChar;
          }
          }
      }
    }

    if (typedChar == null) return;

    // Bijoy Pre-base Vowel Logic (Vowel Sign before Consonant or Conjunct)
    // For 'ি' (i), 'ে' (e), 'ৈ' (oi), users type the vowel sign BEFORE the consonant/conjunct in Bijoy.
    // But Unicode stores Consonant + (Hasanta + Consonant)* + Vowel Sign.
    // Example 1: 'দি' = 'দ' + 'ি'. User types: 'ি' -> 'দ'.
    // Example 2: 'ন্তি' = 'ন' + '্' + 'ত' + 'ি'. User types: 'ি' -> 'ন' -> '্' -> 'ত'.
    
    final layoutState = _ref.read(keyboardLayoutProvider);
    if (layoutState.isBengali &&
        layoutState.currentLayout == KeyboardLayout.bijoy &&
        state.charIndex < state.exerciseText.length) {
      
      const preBaseVowels = ['ি', 'ে', 'ৈ'];
      const hasanta = '্';
      
      // Helper: Check if character is a Bengali consonant
      bool isConsonant(String ch) {
        final code = ch.codeUnitAt(0);
        return code >= 0x0995 && code <= 0x09B9;
      }
      
      // Helper: Find the end of a conjunct starting at idx
      // Returns the index AFTER the last character of the conjunct
      int findConjunctEnd(int idx) {
        int pos = idx;
        if (pos >= state.exerciseText.length || !isConsonant(state.exerciseText[pos])) return pos;
        pos++;
        
        while (pos < state.exerciseText.length - 1 && state.exerciseText[pos] == hasanta) {
          if (pos + 1 < state.exerciseText.length && isConsonant(state.exerciseText[pos + 1])) {
            pos += 2;
          } else {
            break;
          }
        }
        return pos;
      }
      
      final currentChar = state.exerciseText[state.charIndex];
      
      // CRITICAL: If we already have a pending pre-base vowel,
      // user is typing characters of the conjunct. Just match current char directly!
      if (state.pendingPreBaseVowel != null) {
        if (typedChar == currentChar) {
          // Correct! Match the current character (consonant or hasanta)
          _ref.read(soundServiceProvider).playSound(SoundType.keyPress);
          
          final newCharIndex = state.charIndex + 1;
          final updatedSession = List<String>.from(state.sessionTypedCharacters)..add(currentChar);
          
          // Check if next char is the pending pre-base vowel
          if (newCharIndex < state.exerciseText.length && 
              state.exerciseText[newCharIndex] == state.pendingPreBaseVowel) {
            // We've reached the vowel position! Skip it and clear pending.
            final finalCharIndex = newCharIndex + 1;
            updatedSession.add(state.pendingPreBaseVowel!);
            
            final isCompleted = finalCharIndex >= state.exerciseText.length;
            
            state = state.copyWith(
              charIndex: finalCharIndex,
              sessionTypedCharacters: updatedSession,
              lastKeyPress: event.character,
              clearPendingPreBaseVowel: true,
            );
            
            if (isCompleted) {
              _handleExerciseCompletion();
            } else {
              _updateStats();
            }
            return;
          } else {
            // More characters to type before vowel
            state = state.copyWith(
              charIndex: newCharIndex,
              sessionTypedCharacters: updatedSession,
              lastKeyPress: event.character,
            );
            _updateStats();
            return;
          }
        } else {
          // Wrong key
          _ref.read(soundServiceProvider).playSound(SoundType.keyError);
          
          final newMistakes = state.mistakes + 1;
          final newIncorrectIndices = List<int>.from(state.incorrectIndices)
            ..add(state.charIndex);
          
          state = state.copyWith(
            mistakes: newMistakes,
            incorrectIndices: newIncorrectIndices,
          );
          _updateStats();
          return;
        }
      }
      
      // Check if this starts a conjunct (consonant + hasanta)
      if (isConsonant(currentChar) && 
          state.charIndex + 1 < state.exerciseText.length && 
          state.exerciseText[state.charIndex + 1] == hasanta) {
        
        // Find where the conjunct ends
        int conjEnd = findConjunctEnd(state.charIndex);
        
        // Check if there's a pre-base vowel after the conjunct
        if (conjEnd < state.exerciseText.length && preBaseVowels.contains(state.exerciseText[conjEnd])) {
          final preBaseVowel = state.exerciseText[conjEnd];
          
          // Scenario 1: User types the Pre-base Vowel FIRST (Correct Bijoy Order)
          if (state.pendingPreBaseVowel == null) {
            if (typedChar == preBaseVowel) {
              // Correct! User typed the vowel sign first.
              _ref.read(soundServiceProvider).playSound(SoundType.keyPress);
              
              // Store the vowel and the conjunct end position
              state = state.copyWith(
                pendingPreBaseVowel: preBaseVowel,
                mistakes: state.mistakes,
              );
              return; // Wait for conjunct characters
            } else if (typedChar == currentChar) {
              // User typed Consonant first (wrong for Bijoy)
              _ref.read(soundServiceProvider).playSound(SoundType.keyError);
              
              final newMistakes = state.mistakes + 1;
              final newIncorrectIndices = List<int>.from(state.incorrectIndices)
                ..add(state.charIndex);
              state = state.copyWith(
                mistakes: newMistakes,
                incorrectIndices: newIncorrectIndices,
              );
              _updateStats();
              return;
            }
            // Wrong key entirely - let normal logic handle it
          }
          // Scenario 2: User already typed the Vowel, now typing the Conjunct
          else {
            // We expect the user to type the conjunct characters in order
            if (typedChar == currentChar) {
              // Correct! Advance to next character in conjunct
              _ref.read(soundServiceProvider).playSound(SoundType.keyPress);
              
              final newCharIndex = state.charIndex + 1;
              final updatedSessionHistory = List<String>.from(state.sessionTypedCharacters)..add(currentChar);
              
              // Check if we've completed the entire conjunct + vowel
              if (newCharIndex >= conjEnd) {
                // We've typed all conjunct characters, now add the vowel and skip past it
                final finalCharIndex = conjEnd + 1; // Past the vowel
                updatedSessionHistory.add(state.pendingPreBaseVowel!);
                
                final isCompleted = finalCharIndex >= state.exerciseText.length;
                
                state = state.copyWith(
                  charIndex: finalCharIndex,
                  sessionTypedCharacters: updatedSessionHistory,
                  lastKeyPress: event.character,
                  clearPendingPreBaseVowel: true,
                );
                
                if (isCompleted) {
                  _handleExerciseCompletion();
                } else {
                  _updateStats();
                }
                return;
              } else {
                // More conjunct characters to type
                state = state.copyWith(
                  charIndex: newCharIndex,
                  sessionTypedCharacters: updatedSessionHistory,
                  lastKeyPress: event.character,
                );
                _updateStats();
                return;
              }
            } else {
              // Wrong key
              _ref.read(soundServiceProvider).playSound(SoundType.keyError);
              
              final newMistakes = state.mistakes + 1;
              final newIncorrectIndices = List<int>.from(state.incorrectIndices)
                ..add(state.charIndex);
              
              state = state.copyWith(
                mistakes: newMistakes,
                incorrectIndices: newIncorrectIndices,
              );
              _updateStats();
              return;
            }
          }
        }
      }
      
      // Simple consonant + pre-base vowel (no conjunct)
      // Only evaluate this pattern when a safe lookahead exists and the
      // current character is actually a consonant. Without this guard,
      // standalone drill characters at the end of the exercise can stall
      // because `charIndex + 1` points past the string boundary.
      final hasNextCharacter = state.charIndex + 1 < state.exerciseText.length;
      if (isConsonant(currentChar) && hasNextCharacter) {
        final nextChar = state.exerciseText[state.charIndex + 1];
        if (preBaseVowels.contains(nextChar)) {
        
          // Scenario 1: User types the Pre-base Vowel FIRST (Correct Bijoy Order)
          if (state.pendingPreBaseVowel == null) {
            if (typedChar == nextChar) {
               // Correct! User typed the vowel sign first.
               _ref.read(soundServiceProvider).playSound(SoundType.keyPress);

               state = state.copyWith(
                 pendingPreBaseVowel: nextChar,
                 mistakes: state.mistakes,
               );
               return; // Wait for consonant
            } else if (typedChar == currentChar) {
               // User typed Consonant first (wrong for Bijoy)
               _ref.read(soundServiceProvider).playSound(SoundType.keyError);
               
                final newMistakes = state.mistakes + 1;
                final newIncorrectIndices = List<int>.from(state.incorrectIndices)
                  ..add(state.charIndex);
                state = state.copyWith(
                  mistakes: newMistakes,
                  incorrectIndices: newIncorrectIndices,
                );
                _updateStats();
                return;
            }
          } 
          // Scenario 2: User already typed the Vowel, now typing the Consonant
          else {
             if (typedChar == currentChar) {
                // Match! Commit both characters
                _ref.read(soundServiceProvider).playSound(SoundType.keyPress);

                final newCharIndex = state.charIndex + 2;
                final isCompleted = newCharIndex >= state.exerciseText.length;
                
                final updatedSessionHistory = List<String>.from(state.sessionTypedCharacters)
                   ..add(currentChar)
                   ..add(state.pendingPreBaseVowel!);
                   
                 state = state.copyWith(
                    charIndex: newCharIndex,
                    sessionTypedCharacters: updatedSessionHistory,
                    lastKeyPress: event.character,
                    clearPendingPreBaseVowel: true,
                 );
                 
                 if (isCompleted) {
                   _handleExerciseCompletion();
                 } else {
                   _updateStats();
                 }
                 return;
             } else {
                // Wrong key
                _ref.read(soundServiceProvider).playSound(SoundType.keyError);

                final newMistakes = state.mistakes + 1;
                final newIncorrectIndices = List<int>.from(state.incorrectIndices)
                   ..add(state.charIndex);
                
                state = state.copyWith(
                  mistakes: newMistakes,
                  incorrectIndices: newIncorrectIndices,
                );
                _updateStats();
                return;
             }
          }
        } else if (state.pendingPreBaseVowel != null) {
          state = state.copyWith(clearPendingPreBaseVowel: true);
        }
      } else {
        // Next char is NOT a pre-base vowel
        if (state.pendingPreBaseVowel != null) {
           state = state.copyWith(clearPendingPreBaseVowel: true);
        }
      }
    } else {
       // Not Bijoy or End of text: Clear any pending pre-base vowel
       if (state.pendingPreBaseVowel != null) {
           state = state.copyWith(clearPendingPreBaseVowel: true);
       }
    }

    // Bijoy Split Vowel Logic (O-kar and Ou-kar)
    // O-kar (ো) = e-kar (ে) + Consonant + a-kar (া)
    // Ou-kar (ৌ) = e-kar (ে) + Consonant + Ou-independent (ঔ) [or similar suffix key]
    // The previous logic for Pre-base vowel commits 'Consonant' then 'e-kar'.
    // So session history has [..., Consonant, e-kar].
    // If user now types 'a-kar' (f), we must detect this [Consonant, e-kar] + 'a-kar' pattern
    // and replace it with [Consonant, o-kar].

    if (layoutState.isBengali && 
        layoutState.currentLayout == KeyboardLayout.bijoy && 
        typedChar != null && 
        state.sessionTypedCharacters.length >= 2) {
        
        final lastChar = state.sessionTypedCharacters.last;
        final secondLastChar = state.sessionTypedCharacters[state.sessionTypedCharacters.length - 2];

        // Check for O-kar pattern: [Consonant, e-kar] + a-kar
        if (lastChar == 'ে' && typedChar == 'া') { // 'f' maps to 'া'
             // We have Consonant + e-kar + a-kar
             // Replace with Consonant + o-kar (ো)
             // We need to check if the char BEFORE 'e-kar' is a valid consonant? 
             // Generally yes, but safely just merge 'e-kar' + 'a-kar' -> 'o-kar'.
             // Note: 'o-kar' is 09CB.
             
             // Play Generic Key Press sound (since we are modifying history)
             _ref.read(soundServiceProvider).playSound(SoundType.keyPress);

             final updatedSessionHistory = List<String>.from(state.sessionTypedCharacters)
                ..removeLast() // Remove 'e-kar'
                ..add('ো'); // Add 'o-kar' (This replaces e-kar + a-kar concept)
                // Wait, we removed e-kar. The current 'typedChar' (a-kar) is NOT added yet.
                // So we added 'o-kar' to history. 
                // We must prevent 'typedChar' (a-kar) from being added below.
                
             // We also need to update mistakes/charIndex if necessary.
             // If the text EXPECTED 'o-kar', then:
             // 1. We typed 'e-kar' (buffered).
             // 2. We typed 'Consonant'. 'e-kar' committed after 'Consonant'.
             //    If text was "দো" (do), expected: 'দ' then 'ো'.
             //    We typed 'ে' (pending), then 'দ'.
             //    Logic committed 'দ' (Match!) then 'ে' (Mistake? because expected 'ো').
             //    So 'e-kar' might be marked as error in history?
             //    Actually my previous pre-base logic:
             //       if (typedChar == currentChar) { ... add(Consonant); add(pendingPreBaseVowel); ... }
             //    If expected was 'ো', then `add(pending)` which is `ে` -> Mistake.
             //    So `mistakes` count increased.
             // So we need to FIX the mistake count too.
             
             int currentMistakes = state.mistakes;
             List<int> currentIncorrect = List.from(state.incorrectIndices);
             // The 'e-kar' index was 'state.charIndex'. (Wait, valid 'd' was charIndex-1?).
             // If 'e-kar' was wrong, it's at index 'state.charIndex - 1'? No.
             // 'charIndex' points to NEXT expected char.
             
             // If we merged, we simply update the last char.
             // But we must correct the 'typedChar' to be 'null' or handled so we don't proceed to normal logic.
             // And we must update state.
             
             state = state.copyWith(
                 sessionTypedCharacters: updatedSessionHistory,
                 lastKeyPress: event.character,
                 // We kept charIndex same? 
                 // If previous 'ে' was a mistake (because expected 'ো'), and now we fixed it to 'ো'.
                 // Then 'o-kar' matches 'o-kar'. So it IS correct.
                 // So we should decrement mistake count if it was wrong.
                 // How to know? Check if 'incorrectIndices' contains the index of 'e-kar'.
                 // The 'e-kar' was added at index = charIndex (assuming we advanced).
                 // Actually, let's look at pre-base logic:
                 // "newCharIndex = state.charIndex + 2;"
                 // "add(state.pendingPreBaseVowel!);"
                 // If pending (e-kar) didn't match (o-kar), then mistake added?
                 // Wait, pre-base logic only marks mistake if 'Consonant' didn't match.
                 // It doesn't check if 'Vowel' matches?
                 // "state.copyWith(charIndex: newCharIndex...)"
                 // It blindly accepts buffer?
                 // If blindly accepted, then 'mistakes' wasn't incremented for 'e-kar'.
                 // But 'incorrectIndices' might not track it?
                 // No, verification logic is usually: "check if typed == expected".
                 // But pre-base logic "forced" the commit. It didn't validate Vowel against Text.
                 // So 'e-kar' is in history, considered "typed".
                 // Whether it counts as mistake depends on... well, nothing checked it.
                 // So 'mistakes' is likely 0 for that 'e-kar' unless later validater checked?
                 // But we advanced 'charIndex'.
                 
                 // So: We entered 'দ' and 'ে'. Text expects 'দ' and 'ো'.
                 // 'দ' matches. 'ে' != 'ো'.
                 // But since we forcibly advanced charIndex, avoiding normal validation...
                 // The 'mistakes' logic in 'handleKeyPress' (lines 485+) wasn't run for these chars.
                 // So 'mistakes' count is ostensibly correct (0), but we have wrong char in history.
                 // Now we replace 'ে' with 'ো'. 'ো' == 'ো'. Perfect.
                 // So just updating session history is enough!
             );
             return; // Done.
        } else if (lastChar == 'ে' && (typedChar == 'ঔ' || event.character == 'X')) { // Check for Ou-pattern
             // Replace 'e-kar' + 'Ou-independent' -> 'Ou-kar' (ৌ)
              _ref.read(soundServiceProvider).playSound(SoundType.keyPress);

             final updatedSessionHistory = List<String>.from(state.sessionTypedCharacters)
                ..removeLast()
                ..add('ৌ');
             
             state = state.copyWith(
                 sessionTypedCharacters: updatedSessionHistory,
                 lastKeyPress: event.character,
             );
             return;
        }

    }

    // Start timer on first keypress
    final startTime = state.startTime ?? DateTime.now();
    if (!state.isTyping) {
      state = state.copyWith(
        startTime: startTime,
        isTyping: true,
      );
    }

    // Handle backspace
    if (typedChar == 'Backspace') {
      if (state.charIndex > 0) {
        final newCharIndex = state.charIndex - 1;
        final wasIncorrect = state.incorrectIndices.contains(newCharIndex);
        final newMistakes = wasIncorrect ? state.mistakes - 1 : state.mistakes;
        final newIncorrectIndices = List<int>.from(state.incorrectIndices)
          ..removeWhere((index) => index == newCharIndex);

        // Update the state and CLEAR pending pre-base vowel on backspace
        state = state.copyWith(
          charIndex: newCharIndex,
          mistakes: newMistakes,
          incorrectIndices: newIncorrectIndices,
          clearPendingPreBaseVowel: true, // Clear pending vowel on backspace
        );
      } else if (state.pendingPreBaseVowel != null) {
        // Even if charIndex is 0, if there's a pending vowel, clear it
        state = state.copyWith(clearPendingPreBaseVowel: true);
      }
      return;
    }

    // Check if the typed character matches the expected one
    if (state.charIndex < state.exerciseText.length) {
      final layoutState = _ref.read(keyboardLayoutProvider);
      
      // ============================================================
      // BIJOY CONJUNCT MATCHING (র-ফলা, য-ফলা, রেফ)
      // These are 2-character sequences typed with single keys in Bijoy
      // ============================================================
      if (layoutState.currentLayout == KeyboardLayout.bijoy &&
          state.charIndex < state.exerciseText.length - 1) {
        final twoChars = state.exerciseText.substring(state.charIndex, state.charIndex + 2);
        
        // Check if we're expecting a conjunct (ফলা/রেফ)
        if (twoChars == '্র' || twoChars == '্য' || twoChars == 'র্') {
          // Check if typed character matches the conjunct
          if (typedChar == twoChars) {
            // Correct! User typed the conjunct with single key
            _ref.read(soundServiceProvider).playSound(SoundType.keyPress);
            
            final newCharIndex = state.charIndex + 2;  // Skip both characters
            final updatedSessionHistory =
                List<String>.from(state.sessionTypedCharacters)..add(typedChar);
            
            state = state.copyWith(
              charIndex: newCharIndex,
              sessionTypedCharacters: updatedSessionHistory,
              lastKeyPress: event.character,
            );
            
            if (newCharIndex >= state.exerciseText.length) {
              _handleExerciseCompletion();
            } else {
              _updateStats();
              _skipSpaces();
            }
            return;  // Handled, exit
          }
        }
      }
      
      // Normal single-character matching
      final expectedChar = state.exerciseText[state.charIndex];
      final isCorrect = typedChar == expectedChar;

      // Track the typed character in session history
      final updatedSessionHistory =
          List<String>.from(state.sessionTypedCharacters)..add(typedChar);

      if (isCorrect) {
        // Play key press sound
        _ref.read(soundServiceProvider).playSound(SoundType.keyPress);

        // Correct character typed
        final newCharIndex = state.charIndex + 1;
        final isCompleted = newCharIndex >= state.exerciseText.length;

        // Update the state
        state = state.copyWith(
          charIndex: newCharIndex,
          sessionTypedCharacters: updatedSessionHistory,
          lastKeyPress: event.character, // Update last key press
        );

        // If the exercise is completed, update stats
        if (isCompleted) {
          _handleExerciseCompletion();
        } else {
          // Update WPM and accuracy as typing progresses
          _updateStats();
          // Skip any following spaces for drill exercises
          _skipSpaces();
        }
      } else {
        // Play error sound
        _ref.read(soundServiceProvider).playSound(SoundType.keyError);

        // Incorrect character typed
        final newMistakes = state.mistakes + 1;
        final newIncorrectIndices = List<int>.from(state.incorrectIndices)
          ..add(state.charIndex);

        // Update the state
        state = state.copyWith(
          mistakes: newMistakes,
          incorrectIndices: newIncorrectIndices,
          sessionTypedCharacters: updatedSessionHistory,
        );

        // Update accuracy
        _updateStats();
      }
    }
  }

  void _updateStats() {
    if (state.startTime == null || state.charIndex == 0) return;

    // Calculate WPM
    final elapsedMinutes =
        DateTime.now().difference(state.startTime!).inMilliseconds / 60000;
    final wordsTyped = state.charIndex / 5; // Assuming 5 chars = 1 word
    final wpm = elapsedMinutes > 0 ? (wordsTyped / elapsedMinutes).round() : 0;

    // Calculate accuracy
    final accuracy = state.charIndex > 0
        ? (((state.charIndex - state.mistakes) / state.charIndex) * 100).round()
        : 100;

    state = state.copyWith(
      wpm: wpm,
      accuracy: accuracy,
    );
  }

  void _handleExerciseCompletion() {
    final currentExercise =
        lessons[state.currentLessonIndex].exercises[state.currentExerciseIndex];
    final repsRequired = currentExercise.repetitions;
    final currentUser = _ref.read(currentUserProvider);
    final accuracy = state.accuracy;
    
    // Minimum accuracy threshold for counting a rep as successful
    const int minAccuracyThreshold = 85;
    
    // Check if this attempt qualifies as a successful rep
    final isSuccessfulRep = accuracy >= minAccuracyThreshold;
    
    // Only increment rep count if accuracy is above threshold
    final newRepsCompleted = isSuccessfulRep 
        ? state.repsCompleted + 1 
        : state.repsCompleted;
    final hasFinishedExercise = newRepsCompleted >= repsRequired;

    // Play appropriate sound
    if (isSuccessfulRep) {
      _ref.read(soundServiceProvider).playSound(SoundType.levelComplete);
    } else {
      _ref.read(soundServiceProvider).playSound(SoundType.keyError);
    }
    
    // ALWAYS save session history for EVERY repetition attempt (for tracking)
    if (currentUser != null) {
      final lessonTitle = state.currentLesson.title;
      final exerciseNum = state.currentExerciseIndex + 1;
      
      // Build exercise name
      String exerciseName;
      if (currentExercise.isParagraph) {
        exerciseName = 'অনুচ্ছেদ $exerciseNum';
      } else {
        final displayText = currentExercise.text.length > 20 
            ? '${currentExercise.text.substring(0, 20)}...' 
            : currentExercise.text;
        exerciseName = displayText;
      }
      
      // Build complete session name with rep info
      String sessionName;
      if (repsRequired > 1) {
        if (isSuccessfulRep) {
          sessionName = '$lessonTitle • $exerciseName ($newRepsCompleted/$repsRequired রেপ) ✓';
        } else {
          sessionName = '$lessonTitle • $exerciseName [${accuracy}% - ব্যর্থ, পুনরায় চেষ্টা করুন]';
        }
      } else {
        sessionName = '$lessonTitle • $exerciseName';
        if (!isSuccessfulRep) {
          sessionName = '$sessionName [${accuracy}% - ব্যর্থ]';
        }
      }
      
      debugPrint('📝 Saving session: $sessionName, WPM: ${state.wpm}, Accuracy: ${accuracy}%, Success: $isSuccessfulRep');
      
      // Build actual typed text from session history (what user actually typed)
      final actualTypedText = state.sessionTypedCharacters.isNotEmpty 
          ? state.sessionTypedCharacters.join('') 
          : currentExercise.text;
      
      debugPrint('📝 Actual typed text: $actualTypedText');
      
      // Save to history (XP only for successful attempts)
      _ref.read(currentUserProvider.notifier).updateTypingStats(
        wpm: state.wpm.toDouble(),
        accuracy: accuracy.toDouble(),
        completedLesson: sessionName,
        earnedXp: isSuccessfulRep ? 5 : 0, // No XP for failed attempts
        typedText: actualTypedText, // Save actual typed text, not exercise text
      );
    }

    // Update state - only increment rep if successful
    state = state.copyWith(
      repsCompleted: newRepsCompleted,
      waitingForNextRep: !hasFinishedExercise,
    );
    
    // PERSIST rep progress to user model (survives refresh!)
    if (isSuccessfulRep && currentUser != null) {
      _ref.read(currentUserProvider.notifier).updateExerciseRepProgress(
        state.currentLessonIndex, 
        state.currentExerciseIndex, 
        newRepsCompleted
      );
    }

    // Check if all repetitions are successfully completed
    if (hasFinishedExercise) {
      // Complete the exercise (move to next or mark lesson complete)
      debugPrint('✅ Exercise completed! All $repsRequired reps done.');
      _completeExercise();
    } else {
      // Schedule next repetition after delay
      final message = isSuccessfulRep 
          ? '⏳ Next rep in 2 seconds...' 
          : '❌ Accuracy too low ($accuracy% < $minAccuracyThreshold%). Try again...';
      debugPrint(message);
      
      Future.delayed(const Duration(seconds: 2), () {
        // Only restart if still waiting (user hasn't pressed space)
        if (state.waitingForNextRep) {
          _startNextRepetition();
        }
      });
    }
  }

  void _startNextRepetition() {
    state = state.copyWith(
      charIndex: 0,
      mistakes: 0,
      incorrectIndices: [],
      isTyping: false,
      waitingForNextRep: false, // Reset waiting flag
      sessionTypedCharacters: [],
      lastKeyPress: null,
      clearPendingPreBaseVowel: true,
      pendingHasanta: false,
      clearPendingPhoneticSequence: true,
    );
  }

  void _completeExercise() {
    // This is called when ALL reps are completed (from _handleExerciseCompletion)
    // Session history is already saved in _handleExerciseCompletion for each rep
    final completedLessonIndex = state.currentLessonIndex;
    final completedExerciseIndex = state.currentExerciseIndex;
    final isLastExercise = state.isLastExerciseInLesson;
    final currentUser = _ref.read(currentUserProvider);
    
    // Mark exercise as completed
    if (currentUser != null) {
      final lessonTitle = state.currentLesson.title;
      _ref.read(currentUserProvider.notifier).markExerciseCompleted(
            lessonTitle,
            completedExerciseIndex,
          );
      
      // DON'T reset rep progress to 0! Keep it at the completed count.
      // This ensures the exercise shows as completed when revisited.
    }
    
    // Stop typing mode
    state = state.copyWith(
      isTyping: false,
      waitingForNextRep: false,
      sessionTypedCharacters: [],
      lastKeyPress: null,
      clearPendingPreBaseVowel: true,
      pendingHasanta: false,
      clearPendingPhoneticSequence: true,
    );
    
    // Check if this is the last exercise
    if (isLastExercise) {
      // Mark lesson as completed
      _markLessonComplete();
      final nextLessonIndex = completedLessonIndex < lessons.length - 1
          ? completedLessonIndex + 1
          : null;
      state = state.copyWith(
        pendingTransition: PendingPracticeTransition(
          completedLessonIndex: completedLessonIndex,
          completedExerciseIndex: completedExerciseIndex,
          nextLessonIndex: nextLessonIndex,
          nextExerciseIndex: nextLessonIndex == null ? null : 0,
          isLessonAdvance: true,
        ),
      );
    } else {
      state = state.copyWith(
        pendingTransition: PendingPracticeTransition(
          completedLessonIndex: completedLessonIndex,
          completedExerciseIndex: completedExerciseIndex,
          nextLessonIndex: completedLessonIndex,
          nextExerciseIndex: completedExerciseIndex + 1,
          isLessonAdvance: false,
        ),
      );
    }
  }

  // Mark the current lesson as completed in the user's profile
  void _markLessonComplete() {
    final currentUser = _ref.read(currentUserProvider);
    if (currentUser != null) {
      final lessonTitle = state.currentLesson.title;
      final sessionName = '$lessonTitle • লেসন সম্পন্ন ✓';
      
      _ref.read(currentUserProvider.notifier).updateTypingStats(
            wpm: state.wpm.toDouble(),
            accuracy: state.accuracy.toDouble(),
            completedLesson: sessionName,
            earnedXp: 20, // Bonus XP for completing a lesson
          );
    }
  }

  void resetExercise() {
    state = state.copyWith(
      charIndex: 0,
      mistakes: 0,
      incorrectIndices: [],
      clearStartTime: true,
      wpm: 0,
      accuracy: 100,
      isTyping: false,
      waitingForNextRep: false,
      sessionTypedCharacters: [],
      lastKeyPress: null,
      clearPendingPreBaseVowel: true,
      pendingHasanta: false,
      clearPendingPhoneticSequence: true,
      clearPendingTransition: true,
    );
  }

  void clearPendingTransition() {
    if (state.pendingTransition != null) {
      state = state.copyWith(clearPendingTransition: true);
    }
  }
}

final tutorProvider = StateNotifierProvider<TutorNotifier, TutorState>((ref) {
  return TutorNotifier(ref);
});
