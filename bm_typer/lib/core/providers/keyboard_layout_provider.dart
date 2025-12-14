import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bm_typer/core/constants/keyboard_layouts.dart';

/// Keyboard layout state provider
/// Manages which keyboard layout is currently active
final keyboardLayoutProvider =
    StateNotifierProvider<KeyboardLayoutNotifier, KeyboardLayoutState>((ref) {
  return KeyboardLayoutNotifier();
});

/// State for keyboard layout
class KeyboardLayoutState {
  final KeyboardLayout currentLayout;
  final bool isShiftPressed;
  final bool isCapsLock;

  const KeyboardLayoutState({
    this.currentLayout = KeyboardLayout.bijoy, // Default to Bijoy for Bangla typing
    this.isShiftPressed = false,
    this.isCapsLock = false,
  });

  KeyboardLayoutState copyWith({
    KeyboardLayout? currentLayout,
    bool? isShiftPressed,
    bool? isCapsLock,
  }) {
    return KeyboardLayoutState(
      currentLayout: currentLayout ?? this.currentLayout,
      isShiftPressed: isShiftPressed ?? this.isShiftPressed,
      isCapsLock: isCapsLock ?? this.isCapsLock,
    );
  }

  /// Get display rows for current layout
  List<List<String>> getDisplayRows() {
    final useShift = isShiftPressed || isCapsLock;

    switch (currentLayout) {
      case KeyboardLayout.bijoy:
        return useShift
            ? BijoyKeyboardLayout.getShiftDisplayRows()
            : BijoyKeyboardLayout.getDisplayRows();
      case KeyboardLayout.phonetic:
        // Phonetic uses same display as Bijoy for now (Bengali chars)
        return useShift
            ? BijoyKeyboardLayout.getShiftDisplayRows()
            : BijoyKeyboardLayout.getDisplayRows();
      case KeyboardLayout.qwerty:
        return useShift
            ? QwertyKeyboardLayout.getShiftDisplayRows()
            : QwertyKeyboardLayout.getDisplayRows();
    }
  }

  /// Get the layout display name
  String get layoutName {
    switch (currentLayout) {
      case KeyboardLayout.bijoy:
        return 'বিজয়';
      case KeyboardLayout.phonetic:
        return 'Phonetic';
      case KeyboardLayout.qwerty:
        return 'English';
    }
  }

  /// Check if current layout is Bengali
  bool get isBengali => currentLayout == KeyboardLayout.bijoy || currentLayout == KeyboardLayout.phonetic;

  /// Convert English character to Bengali based on current layout
  String? convertToBengali(String englishChar) {
    if (currentLayout == KeyboardLayout.qwerty) {
      return englishChar; // No conversion for English layout
    }
    
    if (currentLayout == KeyboardLayout.phonetic) {
      return PhoneticKeyboardLayout.getCharacter(englishChar) ?? englishChar;
    }
    
    // Bijoy layout
    return BijoyKeyboardLayout.englishToBengali[englishChar] ?? englishChar;
  }
}

/// Notifier for keyboard layout state
class KeyboardLayoutNotifier extends StateNotifier<KeyboardLayoutState> {
  KeyboardLayoutNotifier() : super(const KeyboardLayoutState());

  /// Change the keyboard layout
  void setLayout(KeyboardLayout layout) {
    state = state.copyWith(currentLayout: layout);
  }

  /// Toggle between layouts
  void toggleLayout() {
    final newLayout = state.currentLayout == KeyboardLayout.bijoy
        ? KeyboardLayout.qwerty
        : KeyboardLayout.bijoy;
    state = state.copyWith(currentLayout: newLayout);
  }

  /// Set shift state
  void setShift(bool pressed) {
    state = state.copyWith(isShiftPressed: pressed);
  }

  /// Toggle caps lock
  void toggleCapsLock() {
    state = state.copyWith(isCapsLock: !state.isCapsLock);
  }

  /// Reset modifier keys
  void resetModifiers() {
    state = state.copyWith(isShiftPressed: false);
  }

  /// Convert English input to Bengali
  String? convertInput(String englishChar) {
    return state.convertToBengali(englishChar);
  }
}

/// Provider for getting character from key press based on current layout
final keyCharacterProvider = Provider.family<String?, String>((ref, key) {
  final layoutState = ref.watch(keyboardLayoutProvider);

  switch (layoutState.currentLayout) {
    case KeyboardLayout.bijoy:
      return BijoyKeyboardLayout.getCharacter(
        key,
        shift: layoutState.isShiftPressed || layoutState.isCapsLock,
      );
    case KeyboardLayout.phonetic:
      return PhoneticKeyboardLayout.getCharacter(
        key,
        shift: layoutState.isShiftPressed || layoutState.isCapsLock,
      );
    case KeyboardLayout.qwerty:
      return layoutState.isShiftPressed || layoutState.isCapsLock
          ? key.toUpperCase()
          : key.toLowerCase();
  }
});
