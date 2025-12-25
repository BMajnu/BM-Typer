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
  final String? lastKeyPress; // Track previous key press for Bijoy composite logic (Linker)
  final String?
      pendingPreBaseVowel; // Track if a pre-base vowel (i, e, oi) was typed first
  final bool pendingHasanta; // Track if hasanta (্) was typed for vowel composition (G + vowel key)

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

  // Get the character that the user is EXPECTED to type right now.
  // This handles Bijoy Pre-base vowel reordering (where visual order != Unicode order).
  String getExpectedCharacter(bool isBijoy) {
    if (charIndex >= exerciseLength) return '';

    // Default: The character at the current index
    String expected = exerciseText[charIndex];

    if (isBijoy && charIndex < exerciseLength - 1) {
       final nextChar = exerciseText[charIndex + 1];
       // Check for Pre-base vowels: ি (09BF), ে (09C7), ৈ (09C8)
       if (['ি', 'ে', 'ৈ'].contains(nextChar)) {
          // If we haven't typed the vowel yet (it's not pending),
          // then in Bijoy we MUST type the Vowel Sign FIRST.
          if (pendingPreBaseVowel == null) {
              return nextChar;
          }
       }
    }
    
    return expected;
  }
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
        pendingPreBaseVowel: null,
      );
      
      // Auto-resume: Check user progress for this lesson
      final user = _ref.read(currentUserProvider);
      if (user != null) {
         final lessonTitle = lessons[index].title;
         final completed = user.completedExercises[lessonTitle] ?? [];
         
         // Find first uncompleted exercise
         for (int i = 0; i < lessons[index].exercises.length; i++) {
             if (!completed.contains(i)) {
                 // Found first incomplete - jump to it
                 state = state.copyWith(currentExerciseIndex: i);
                 break;
             }
         }
      }
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

    // Bijoy Pre-base Vowel Logic (Vowel Sign before Consonant)
    // For 'ি' (i), 'ে' (e), 'ৈ' (oi), users type the vowel sign BEFORE the consonant in Bijoy.
    // But Unicode stores Consonant + Vowel Sign.
    // Example: 'দি' = 'দ' + 'ি'. User types: 'ি' -> 'দ'.
    
    final layoutState = _ref.read(keyboardLayoutProvider);
    if (layoutState.isBengali &&
        layoutState.currentLayout == KeyboardLayout.bijoy &&
        state.charIndex < state.exerciseText.length - 1) { // Need at least 2 chars remaining
      
      final currentChar = state.exerciseText[state.charIndex];
      final nextChar = state.exerciseText[state.charIndex + 1];

      // Check if next char is a pre-base vowel sign
      // ি (09BF), ে (09C7), ৈ (09C8)
      if (['ি', 'ে', 'ৈ'].contains(nextChar)) {
        
        // Scenario 1: User types the Pre-base Vowel FIRST (Correct Bijoy Order)
        if (state.pendingPreBaseVowel == null) {
          if (typedChar == nextChar) {
             // Correct! User typed the vowel sign first.
             // Play generic key press sound
             _ref.read(soundServiceProvider).playSound(SoundType.keyPress);

             // We don't advance the cursor yet. We wait for the consonant.
             // But we mark that the vowel is "pending" (buffered).
             state = state.copyWith(
               pendingPreBaseVowel: nextChar,
               mistakes: state.mistakes, // No mistake
             );
             return; // Stop processing, wait for next key (consonant)
          } else if (typedChar == currentChar) {
             // User typed Consonant first (Unicode order, but wrong for Bijoy typing flow)
             // We can mark this as a mistake or leniently accept it.
             // Strict Bijoy typing requires Vowel Sign first.
             // Let's treat it as a mistake to enforce correct typing habit.
             // ... fall through to normal check which will likely fail or pass depending on logic below?
             // Actually, normal check expects `currentChar`. But `typedChar == currentChar`.
             // So normal check would PASS it. 
             // We must intercept and FAIL it if we want to enforce Order.
             // "না! আগে কার চিহ্ন দিতে হবে!"
             
             // Play error sound
             _ref.read(soundServiceProvider).playSound(SoundType.keyError);
             
             // Update logic to count mistake but NOT advance
             // ... fall through normal mistake logic? No, return here.
              final newMistakes = state.mistakes + 1;
              final newIncorrectIndices = List<int>.from(state.incorrectIndices)
                ..add(state.charIndex);
              state = state.copyWith(
                mistakes: newMistakes,
                incorrectIndices: newIncorrectIndices,
              );
              _updateStats();
              return;
          } else {
             // Wrong key entirely
             // Let normal logic handle it
          }
        } 
        // Scenario 2: User already typed the Vowel, now typing the Consonant
        else {
           // We are expecting 'currentChar' (the Consonant)
           if (typedChar == currentChar) {
              // Match! User typed Vowel (buffered) + Consonant (now).
              // We should commit BOTH. 'Consonant' + 'Vowel' into output history.
              
              // Play key press sound
              _ref.read(soundServiceProvider).playSound(SoundType.keyPress);

              final newCharIndex = state.charIndex + 2; // Advance 2 steps
              final isCompleted = newCharIndex >= state.exerciseText.length;
              
              final updatedSessionHistory = List<String>.from(state.sessionTypedCharacters)
                 ..add(currentChar) // Add Consonant first (Unicode order)
                 ..add(state.pendingPreBaseVowel!); // Add Vowel second
                 
               state = state.copyWith(
                  charIndex: newCharIndex,
                  sessionTypedCharacters: updatedSessionHistory,
                  lastKeyPress: event.character,
                  clearPendingPreBaseVowel: true, // Clear buffer
               );
               
               if (isCompleted) {
                 _handleExerciseCompletion();
               } else {
                 _updateStats();
               }
               return; // Done
           } else {
              // User typed something else instead of expected Consonant
              // Mistake.
              // Should we clear the pending vowel? Usually no, give them chance to type consonant.
              // Play error sound
              _ref.read(soundServiceProvider).playSound(SoundType.keyError);

              final newMistakes = state.mistakes + 1;
              final newIncorrectIndices = List<int>.from(state.incorrectIndices)
                 ..add(state.charIndex); // Mark the Consonant position as error
              
              state = state.copyWith(
                mistakes: newMistakes,
                incorrectIndices: newIncorrectIndices,
                // Keep pendingPreBaseVowel
              );
              _updateStats();
              return;
           }
        }
      } else {
        // Next char is NOT a pre-base vowel?
        // Ensure pendingPreBaseVowel is cleared if we moved away (safety)
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
              
          // Persist Exercise Completion
          final lessonTitle = state.currentLesson.title;
          _ref.read(currentUserProvider.notifier).markExerciseCompleted(lessonTitle, state.currentExerciseIndex);
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

        // Persist Exercise Completion (No reps case)
        final lessonTitle = state.currentLesson.title;
        _ref.read(currentUserProvider.notifier).markExerciseCompleted(lessonTitle, state.currentExerciseIndex);

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
