import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bm_typer/core/models/lesson_model.dart';
import 'package:bm_typer/data/local_lesson_data.dart';
import 'package:bm_typer/core/providers/user_provider.dart';
import 'package:bm_typer/core/services/sound_service.dart';
import 'package:bm_typer/core/providers/sound_provider.dart';
import 'package:bm_typer/core/providers/keyboard_layout_provider.dart';
import 'package:bm_typer/core/constants/keyboard_layouts.dart';

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
  final String? lastKeyPress; // Track previous key press for Bijoy composite logic

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
    String? lastKeyPress, // Add to copyWith
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
    );
  }

  Lesson get currentLesson => lessons[currentLessonIndex];
  Exercise get currentExercise => currentLesson.exercises[currentExerciseIndex];
  String get exerciseText => currentExercise.text;
  int get exerciseLength => exerciseText.length;
  bool get isCompleted => charIndex >= exerciseLength;
  bool get isLocked {
    final needsReps = currentExercise.repetitions > 0;
    return needsReps && repsCompleted < currentExercise.repetitions;
  }

  // Check if this is the last exercise in the current lesson
  bool get isLastExerciseInLesson =>
      currentExerciseIndex == currentLesson.exercises.length - 1;

  // Check if all repetitions of the current exercise are completed
  bool get isExerciseFullyCompleted =>
      currentExercise.repetitions <= repsCompleted;
}

class TutorNotifier extends StateNotifier<TutorState> {
  final Ref _ref;

  TutorNotifier(this._ref) : super(TutorState());

  void selectExercise(int index) {
    if (index >= 0 &&
        index < lessons[state.currentLessonIndex].exercises.length) {
      state = state.copyWith(
        currentExerciseIndex: index,
        charIndex: 0,
        mistakes: 0,
        incorrectIndices: [],
        clearStartTime: true,
        wpm: 0,
        accuracy: 100,
        isTyping: false,
        repsCompleted: 0,
        sessionTypedCharacters: [], // Reset session history for new exercise
      );
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
      state = state.copyWith(
        currentLessonIndex: index,
        currentExerciseIndex: 0,
        charIndex: 0,
        mistakes: 0,
        incorrectIndices: [],
        clearStartTime: true,
        wpm: 0,
        accuracy: 100,
        repsCompleted: 0,
        isTyping: false,
        lastKeyPress: null,
      );
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
      );
    }
  }

  void setFocus(bool focused) {
    state = state.copyWith(isFocused: focused);
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

    // Get the typed character
    String? typedChar;
    if (event.logicalKey == LogicalKeyboardKey.backspace) {
      typedChar = 'Backspace';
    } else {
      typedChar = event.character;
      
      // Convert English to Bengali based on keyboard layout
      if (typedChar != null) {
        final layoutState = _ref.read(keyboardLayoutProvider);
        if (layoutState.isBengali && typedChar.isNotEmpty) {
          
          // Bijoy Special Logic: Check for Linker 'g' + Vowel Sign
          if (state.lastKeyPress == 'g' && layoutState.currentLayout == KeyboardLayout.bijoy) {
             // Handle composite vowels (Linker + Vowel Sign)
             // g + f (Rhoshho A) = Aa (A)
             if (event.character == 'f') typedChar = 'আ';
             // g + d (Rhoshho I) = I (E) -- Standard Bijoy: g+d = ই
             else if (event.character == 'd') typedChar = 'ই';
             // g + c (E kar) = Oi (OI) -- Standard Bijoy: g+Shift+c = ঐ , but g+c = usually nothing standard? Wait, Bijoy: g + c = no standard composite? 
             // Let's stick to user request: g + f = আ (This is standard).
             // Let's implement the core vowels:
             // g + f (ax) = আ
             // g + d (ix) = ই
             // g + s (ux) = উ
             // g + c (ex) = এ - ERROR in standard logic, 'c' is 'e-kar'. 'g'+'c' -> 'এ' ? No, 'g'+'shift+c'(Oi-kar) -> 'ঐ'.
             // Wait, standard Bijoy:
             // Shift+F = অ
             // g + f = আ
             // g + d = ই
             // Shift+D = ঈ
             // g + s = উ
             // Shift+S = ঊ
             // Shift+A = ঋ (or Reph, usually Reph in typing, but independent vowel requires g+a?)
             // Shift+V = এ (Yes, V is 'Ro', Shift+V is 'A/E' independent?) No, Shift+V is 'Lo'. 
             // Standard Bijoy Vowels:
             // Shift+F = অ
             // g + f = আ
             // g + d = ই
             // Shift+D = ঈ
             // g + s = উ
             // Shift+S = ঊ
             // g + a = ঋ
             // g + Shift+c = ঐ (No, Shift+C is Oi-kar) -> g + Shift+C = likely not valid or handled differently.
             // Actually, 'Shift+C' is 'Oi-kar', 'g'+'Shift+C' = 'ঐ'.
             // 'c' is 'e-kar'. 'g'+'c' = 'এ'.
             // 'x' is 'o-kar' (Wait, x is O). No, x is 'O'. Shift+X is 'Ou'.
             // Standard:
             // g + c = এ
             // g + x = ও (But x is already O independent? No, x is O).
             // Actually, x maps to `ও` directly in my layout map. So no composite needed for O.
             // But usually 'g' is used to make the independent vowel from the kar-sign key.
             
             if (event.character == 'f') typedChar = 'আ'; // a-kar -> A
             else if (event.character == 'd') typedChar = 'ই'; // i-kar -> I
             else if (event.character == 's') typedChar = 'উ'; // u-kar -> U
             else if (event.character == 'a') typedChar = 'ঋ'; // ri-kar -> Ri
             else if (event.character == 'c') typedChar = 'এ'; // e-kar -> E
             else if (event.character == 'C') typedChar = 'ঐ'; // oi-kar -> OI (Shift+c)
             else if (event.character == 'x') typedChar = 'ও'; // o-kar (Wait x is O). If x is 'O', then g+x needed? Maybe not.
             else if (event.character == 'X') typedChar = 'ঔ'; // ou-kar -> OU (Shift+x)

             // BACKTRACKING LOGIC:
             // If a composite was formed, we must "undo" the previous key press (the Linker 'g')
             // because we want the user to type "g + f" and have it count as ONE valid character 'আ'.
             if (typedChar != null && typedChar != event.character) {
                int currentMistakes = state.mistakes;
                List<int> currentIncorrect = List.from(state.incorrectIndices);
                int currentCharIndex = state.charIndex;
                List<String> currentSessionChars = List.from(state.sessionTypedCharacters);

                if (currentCharIndex > 0) {
                     int prevIndex = currentCharIndex - 1;
                     // If the previous 'g' was marked as incorrect, remove the penalty
                     if (currentIncorrect.contains(prevIndex)) {
                         currentMistakes = currentMistakes > 0 ? currentMistakes - 1 : 0;
                         currentIncorrect.remove(prevIndex);
                     }
                     // Remove the 'g' from session history
                     if (currentSessionChars.isNotEmpty) {
                         currentSessionChars.removeLast();
                     }
                     // Step back the cursor
                     currentCharIndex--;

                     // Update state immediately so the subsequent check uses the corrected position
                     state = state.copyWith(
                         mistakes: currentMistakes,
                         incorrectIndices: currentIncorrect,
                         charIndex: currentCharIndex,
                         sessionTypedCharacters: currentSessionChars,
                     );
                }
             }
          }

          if (typedChar == event.character) {
             // If not converted by composite logic, use simple map
             final bengaliChar = BijoyKeyboardLayout.englishToBengali[typedChar];
             if (bengaliChar != null) {
               typedChar = bengaliChar;
             }
          }
        }
      }
    }

    if (typedChar == null) return;

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

        // Update the state
        state = state.copyWith(
          charIndex: newCharIndex,
          mistakes: newMistakes,
          incorrectIndices: newIncorrectIndices,
        );
      }
      return;
    }

    // Check if the typed character matches the expected one
    if (state.charIndex < state.exerciseText.length) {
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
    final newRepsCompleted = state.repsCompleted + 1;

    // Play completion sound
    _ref.read(soundServiceProvider).playSound(SoundType.levelComplete);

    // Update state to show completion
    state = state.copyWith(
      repsCompleted: newRepsCompleted,
      waitingForNextRep: true, // Set waiting flag to true
    );

    // Check if all repetitions are completed
    if (newRepsCompleted >= repsRequired) {
      // Complete the exercise
      _completeExercise();
    } else {
      // Schedule next repetition after delay
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
    );
  }

  void _completeExercise() {
    // Check accuracy threshold
    final accuracy = state.accuracy;
    final exercise = state.currentExercise;
    final currentUser = _ref.read(currentUserProvider);

    if (exercise.repetitions > 0) {
      if (accuracy >= 95) {
        // Successful completion
        final newRepsCompleted = state.repsCompleted + 1;
        state = state.copyWith(
          repsCompleted: newRepsCompleted,
          isTyping: false,
        );

        // Update user's typing stats
        if (currentUser != null) {
          _ref.read(currentUserProvider.notifier).updateTypingStats(
                wpm: state.wpm.toDouble(),
                accuracy: state.accuracy.toDouble(),
                earnedXp: 5, // Award XP for each successful repetition
              );
        }

        if (newRepsCompleted < exercise.repetitions) {
          // Reset for next repetition
          Future.delayed(const Duration(seconds: 1), () {
            state = state.copyWith(
              charIndex: 0,
              mistakes: 0,
              incorrectIndices: [],
              clearStartTime: true,
              wpm: 0,
              accuracy: 100,
              isTyping: false,
            );
          });
        } else if (state.isLastExerciseInLesson) {
          // If this is the last exercise and all repetitions completed, mark lesson as completed
          _markLessonComplete();
        } else {
          // Move to next exercise automatically after a delay
          Future.delayed(const Duration(seconds: 2), () {
            selectExercise(state.currentExerciseIndex + 1);
          });
        }
      } else {
        // Failed accuracy check, reset for retry
        Future.delayed(const Duration(seconds: 2), () {
          state = state.copyWith(
            charIndex: 0,
            mistakes: 0,
            incorrectIndices: [],
            clearStartTime: true,
            wpm: 0,
            accuracy: 100,
            isTyping: false,
          );
        });
      }
    } else {
      // No repetitions required
      state = state.copyWith(isTyping: false);

      // Update user's typing stats even for exercises without repetitions
      if (currentUser != null && state.accuracy >= 90) {
        _ref.read(currentUserProvider.notifier).updateTypingStats(
              wpm: state.wpm.toDouble(),
              accuracy: state.accuracy.toDouble(),
              earnedXp: 3, // Award some XP for completing an exercise
            );

        // If this is the last exercise, mark lesson as completed
        if (state.isLastExerciseInLesson) {
          _markLessonComplete();
        }
      }
    }
  }

  // Mark the current lesson as completed in the user's profile
  void _markLessonComplete() {
    final currentUser = _ref.read(currentUserProvider);
    if (currentUser != null) {
      final lessonTitle = state.currentLesson.title;
      _ref.read(currentUserProvider.notifier).updateTypingStats(
            wpm: state.wpm.toDouble(),
            accuracy: state.accuracy.toDouble(),
            completedLesson: lessonTitle,
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
    );
  }
}

final tutorProvider = StateNotifierProvider<TutorNotifier, TutorState>((ref) {
  return TutorNotifier(ref);
});
