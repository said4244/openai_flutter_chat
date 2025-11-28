import '../models/chat_message.dart';

class InputValidator {
  
  InputState processCharacterInput({
    required InputState currentState,
    required String inputCharacter,
    required int position,
  }) {
    // Validate position
    if (position < 0 || position >= currentState.expectedInput.length) {
      return currentState;
    }
    
    // Get expected character at this position
    final expectedChar = currentState.expectedInput[position];
    final isCorrect = inputCharacter == expectedChar;
    
    // Create new character states list
    final newCharacterStates = List<CharacterState>.from(currentState.characterStates);
    
    // Find if we already have a state for this position
    final existingIndex = newCharacterStates.indexWhere((s) => s.index == position);
    
    final newCharState = CharacterState(
      index: position,
      character: inputCharacter,
      status: isCorrect ? CharacterStatus.correct : CharacterStatus.incorrect,
    );
    
    if (existingIndex >= 0) {
      // Update existing state
      newCharacterStates[existingIndex] = newCharState;
    } else {
      // Add new state
      newCharacterStates.add(newCharState);
    }
    
    // Sort by index to maintain order
    newCharacterStates.sort((a, b) => a.index.compareTo(b.index));
    
    // Build current input string
    final currentInputBuilder = StringBuffer();
    for (int i = 0; i < currentState.expectedInput.length; i++) {
      final charState = newCharacterStates.firstWhere(
        (s) => s.index == i,
        orElse: () => CharacterState(
          index: i,
          character: '',
          status: CharacterStatus.pending,
        ),
      );
      
      if (charState.status != CharacterStatus.pending) {
        currentInputBuilder.write(charState.character);
      }
    }
    
    final newCurrentInput = currentInputBuilder.toString();
    
    // Check if complete (all characters are correct)
    final isComplete = newCharacterStates.length == currentState.expectedInput.length &&
        newCharacterStates.every((s) => s.status == CharacterStatus.correct);
    
    return currentState.copyWith(
      currentInput: newCurrentInput,
      characterStates: newCharacterStates,
      isComplete: isComplete,
      cursorPosition: position + 1,
    );
  }
  
  InputState processBackspace({
    required InputState currentState,
  }) {
    if (currentState.characterStates.isEmpty) {
      return currentState;
    }
    
    // Find the last incorrect character to remove
    // If no incorrect characters, remove the last character
    final incorrectStates = currentState.characterStates
        .where((s) => s.status == CharacterStatus.incorrect)
        .toList();
    
    CharacterState? stateToRemove;
    
    if (incorrectStates.isNotEmpty) {
      // Remove the first incorrect character (leftmost)
      stateToRemove = incorrectStates.reduce((a, b) => a.index < b.index ? a : b);
    } else {
      // Remove the last typed character
      stateToRemove = currentState.characterStates.reduce((a, b) => a.index > b.index ? a : b);
    }
    
    if (stateToRemove == null) return currentState;
    
    // Create new character states list without the removed state
    final newCharacterStates = currentState.characterStates
        .where((s) => s.index != stateToRemove!.index)
        .toList();
    
    // Build current input string
    final currentInputBuilder = StringBuffer();
    for (int i = 0; i < currentState.expectedInput.length; i++) {
      final charState = newCharacterStates.firstWhere(
        (s) => s.index == i,
        orElse: () => CharacterState(
          index: i,
          character: '',
          status: CharacterStatus.pending,
        ),
      );
      
      if (charState.status != CharacterStatus.pending) {
        currentInputBuilder.write(charState.character);
      }
    }
    
    final newCurrentInput = currentInputBuilder.toString();
    
    // Update cursor position
    final newCursorPosition = stateToRemove.index;
    
    // Check if complete
    final isComplete = newCharacterStates.length == currentState.expectedInput.length &&
        newCharacterStates.every((s) => s.status == CharacterStatus.correct);
    
    return currentState.copyWith(
      currentInput: newCurrentInput,
      characterStates: newCharacterStates,
      isComplete: isComplete,
      cursorPosition: newCursorPosition,
    );
  }
  
  bool hasIncorrectCharacters(InputState state) {
    return state.characterStates.any((s) => s.status == CharacterStatus.incorrect);
  }
  
  bool validateFullInput({
    required String input,
    required String expected,
  }) {
    // Normalize Arabic text for comparison
    final normalizedInput = _normalizeArabicText(input);
    final normalizedExpected = _normalizeArabicText(expected);
    
    return normalizedInput == normalizedExpected;
  }
  
  List<int> findDifferences({
    required String input,
    required String expected,
  }) {
    final differences = <int>[];
    final minLength = input.length < expected.length ? input.length : expected.length;
    
    for (int i = 0; i < minLength; i++) {
      if (input[i] != expected[i]) {
        differences.add(i);
      }
    }
    
    // If lengths differ, all extra positions are differences
    if (input.length != expected.length) {
      for (int i = minLength; i < expected.length; i++) {
        differences.add(i);
      }
    }
    
    return differences;
  }
  
  double calculateAccuracy({
    required String input,
    required String expected,
  }) {
    if (expected.isEmpty) return 100.0;
    
    final differences = findDifferences(input: input, expected: expected);
    final correctCount = expected.length - differences.length;
    
    return (correctCount / expected.length) * 100;
  }
  
  // Private helper methods
  
  String _normalizeArabicText(String text) {
    // Remove common Arabic diacritics for comparison
    return text
        .replaceAll(RegExp(r'[\u064B-\u065F\u0670]'), '') // Remove diacritics
        .replaceAll(RegExp(r'\s+'), ' ') // Normalize whitespace
        .trim();
  }
}