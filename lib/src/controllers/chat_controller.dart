import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';
import 'package:uuid/uuid.dart';
import '../models/chat_message.dart';
import '../models/roleplay.dart';
import '../models/user_profile.dart';
import '../api/openai_service.dart';
import 'input_validator.dart';

class ChatController extends ChangeNotifier {
  final OpenAIService _openAIService;
  final UserProfile userProfile;
  final Logger _logger = Logger();
  final _uuid = const Uuid();
  
  // State
  List<RoleplayTitle> _roleplayTitles = [];
  RoleplayTitle? _selectedRoleplayTitle;
  RoleplayOption? _selectedRoleplay;
  RoleplaySession? _currentSession;
  List<ChatMessage> _messages = [];
  InputState? _currentInputState;
  int _currentMessageIndex = 0;
  bool _isLoadingTitles = false;
  bool _isLoadingConversation = false;
  String? _error;
  bool _keyboardGuideEnabled = true;  // New state for keyboard highlighting
  
  // Controllers
  final InputValidator _inputValidator = InputValidator();
  
  // Streams
  final _messageStreamController = StreamController<ChatMessage>.broadcast();
  
  ChatController({
    required OpenAIService openAIService,
    required this.userProfile,
  }) : _openAIService = openAIService;

  // Getters - updated to expose titles instead of full options
  List<RoleplayTitle> get roleplayTitles => _roleplayTitles;
  RoleplayOption? get selectedRoleplay => _selectedRoleplay;
  List<ChatMessage> get messages => _messages;
  InputState? get currentInputState => _currentInputState;
  bool get isLoading => _isLoadingTitles || _isLoadingConversation;
  bool get isLoadingTitles => _isLoadingTitles;
  bool get isLoadingConversation => _isLoadingConversation;
  String? get error => _error;
  bool get hasActiveSession => _currentSession != null;
  double get sessionProgress {
    if (_currentSession == null || _selectedRoleplay == null) return 0.0;
    // Calculate based on completed messages out of 10 user messages
    final progress = (_currentSession!.completedMessages.length / 10) * 100;
    return progress.clamp(0.0, 100.0);
  }
  Stream<ChatMessage> get messageStream => _messageStreamController.stream;
  
  // New getter for checking if backspace is needed
  bool get shouldHighlightBackspace => 
      _currentInputState != null && 
      _inputValidator.hasIncorrectCharacters(_currentInputState!);
  
  // New getter for checking if session is completed
  bool get isSessionCompleted => 
      _currentSession != null && 
      _currentSession!.completedAt != null;
      
  // Keyboard guide toggle
  bool get keyboardGuideEnabled => _keyboardGuideEnabled;
  
  void toggleKeyboardGuide() {
    _keyboardGuideEnabled = !_keyboardGuideEnabled;
    _logger.i('Keyboard guide toggled: $_keyboardGuideEnabled');
    notifyListeners();
  }

  // Public Methods - Updated for two-step process
  
  // Step 1: Load only roleplay titles (fast)
  Future<void> loadRoleplayTitles({
    required String selectedLevel,
    String? specialContext,
  }) async {
    try {
      _setLoadingTitles(true);
      _error = null;
      
      _logger.i('Loading roleplay titles for level: $selectedLevel');
      
      _roleplayTitles = await _openAIService.generateRoleplayTitles(
        userProfile: userProfile,
        selectedLevel: selectedLevel,
        specialContext: specialContext,
      );
      
      _logger.i('Loaded ${_roleplayTitles.length} roleplay titles');
      notifyListeners();
    } catch (e) {
      _logger.e('Failed to load roleplay titles', error: e);
      _error = 'Failed to load roleplays: ${e.toString()}';
      notifyListeners();
    } finally {
      _setLoadingTitles(false);
    }
  }

  // Step 2: Load full conversation for selected roleplay only
  Future<void> selectRoleplayTitle(RoleplayTitle title) async {
    try {
      _selectedRoleplayTitle = title;
      _setLoadingConversation(true);
      _error = null;
      
      _logger.i('Loading conversation for roleplay: ${title.title}');
      
      _selectedRoleplay = await _openAIService.generateRoleplayConversation(
        userProfile: userProfile,
        selectedRoleplay: title,
      );
      
      _logger.i('Loaded conversation with ${_selectedRoleplay!.messages.length} messages');
      
      // Start the session
      _startSession();
    } catch (e) {
      _logger.e('Failed to load roleplay conversation', error: e);
      _error = 'Failed to load conversation: ${e.toString()}';
      _selectedRoleplayTitle = null;
      notifyListeners();
    } finally {
      _setLoadingConversation(false);
    }
  }

  // Keep old method for compatibility but update it to use new approach
  Future<void> loadRoleplayOptions({
    required String selectedLevel,
    String? specialContext,
  }) async {
    await loadRoleplayTitles(
      selectedLevel: selectedLevel,
      specialContext: specialContext,
    );
  }

  void selectRoleplay(RoleplayOption roleplay) {
    _logger.i('Selected roleplay: ${roleplay.title}');
    _selectedRoleplay = roleplay;
    _startSession();
  }

  void cancelSelection() {
    _logger.i('Cancelled roleplay selection');
    _selectedRoleplayTitle = null;
    _selectedRoleplay = null;
    _currentSession = null;
    _messages.clear();
    _currentMessageIndex = 0;
    _currentInputState = null;
    notifyListeners();
  }

  void processCharacterInput(String character, int position) {
    if (_currentInputState == null || _selectedRoleplay == null) return;
    
    final expectedMessage = _selectedRoleplay!.messages[_currentMessageIndex];
    if (expectedMessage.role != MessageRole.user) return;
    
    final newState = _inputValidator.processCharacterInput(
      currentState: _currentInputState!,
      inputCharacter: character,
      position: position,
    );
    
    _currentInputState = newState;
    
    // Update the current message's input state
    if (_messages.isNotEmpty) {
      final lastMessage = _messages.last;
      if (lastMessage.type == MessageType.user) {
        _messages[_messages.length - 1] = ChatMessage(
          id: lastMessage.id,
          content: newState.currentInput,
          type: lastMessage.type,
          timestamp: lastMessage.timestamp,
          inputState: newState,
          metadata: lastMessage.metadata,
        );
      }
    }
    
    notifyListeners();
  }
  
  void processBackspace() {
    if (_currentInputState == null) return;
    
    _logger.i('Processing backspace');
    
    final newState = _inputValidator.processBackspace(
      currentState: _currentInputState!,
    );
    
    _currentInputState = newState;
    
    // Update the current message's input state
    if (_messages.isNotEmpty) {
      final lastMessage = _messages.last;
      if (lastMessage.type == MessageType.user) {
        _messages[_messages.length - 1] = ChatMessage(
          id: lastMessage.id,
          content: newState.currentInput,
          type: lastMessage.type,
          timestamp: lastMessage.timestamp,
          inputState: newState,
          metadata: lastMessage.metadata,
        );
      }
    }
    
    notifyListeners();
  }

  bool canSendMessage() {
    return _currentInputState?.isComplete ?? false;
  }
  
  bool validateBeforeSend() {
    if (_currentInputState == null) return false;
    
    // If keyboard guide is off and there are mistakes, return false
    if (!_keyboardGuideEnabled && _inputValidator.hasIncorrectCharacters(_currentInputState!)) {
      return false;
    }
    
    return canSendMessage();
  }

  void sendMessage() {
    if (!canSendMessage() || _selectedRoleplay == null) return;
    
    _logger.i('Sending message at index $_currentMessageIndex');
    
    // Record completion
    final completedMessage = CompletedMessage(
      messageIndex: _currentMessageIndex,
      userInput: _currentInputState!.currentInput,
      attempts: 1, // TODO: Track actual attempts
      mistakeCount: _currentInputState!.characterStates
          .where((c) => c.status == CharacterStatus.incorrect)
          .length,
      timeTaken: Duration(seconds: 10), // TODO: Track actual time
      mistakes: [], // TODO: Track mistakes
    );
    
    _currentSession?.completedMessages.add(completedMessage);
    
    // Move to next message
    _currentMessageIndex++;
    
    if (_currentMessageIndex < _selectedRoleplay!.messages.length) {
      _showNextMessage();
    } else {
      _completeSession();
    }
  }

  // Private Methods
  
  void _startSession() {
    if (_selectedRoleplay == null) return;
    
    _currentSession = RoleplaySession(
      sessionId: _uuid.v4(),
      roleplayId: _selectedRoleplay!.id,
      userLevel: UserLevel.level1, // TODO: Make this configurable
      completedMessages: [],
      currentMessageIndex: 0,
      startedAt: DateTime.now(),
      statistics: SessionStatistics(
        totalAttempts: 0,
        totalMistakes: 0,
        totalTime: Duration.zero,
        accuracy: 100.0,
        learnedWords: [],
      ),
    );
    
    _messages.clear();
    _currentMessageIndex = 0;
    _showNextMessage();
  }

  void _showNextMessage() {
    if (_selectedRoleplay == null || 
        _currentMessageIndex >= _selectedRoleplay!.messages.length) return;
    
    final roleplayMessage = _selectedRoleplay!.messages[_currentMessageIndex];
    
    if (roleplayMessage.role == MessageRole.ai) {
      // AI message - just display it
      final aiMessage = ChatMessage(
        id: _uuid.v4(),
        content: roleplayMessage.arabicText,
        type: MessageType.ai,
        timestamp: DateTime.now(),
        metadata: {
          'transliteration': roleplayMessage.transliteration,
          'translation': roleplayMessage.englishTranslation,
          'vocabulary': roleplayMessage.keyVocabulary,
          'culturalNote': roleplayMessage.culturalNote,
        },
      );
      
      _messages.add(aiMessage);
      _messageStreamController.add(aiMessage);
      
      // Automatically move to next message (user's turn)
      _currentMessageIndex++;
      
      // Small delay before showing user input
      Future.delayed(const Duration(milliseconds: 500), () {
        _showNextMessage();
      });
    } else {
      // User message - prepare input state
      _currentInputState = InputState.empty(roleplayMessage.arabicText);
      
      final userMessage = ChatMessage(
        id: _uuid.v4(),
        content: '',
        type: MessageType.user,
        timestamp: DateTime.now(),
        inputState: _currentInputState,
        metadata: {
          'expectedText': roleplayMessage.arabicText,
          'transliteration': roleplayMessage.transliteration,
          'translation': roleplayMessage.englishTranslation,
        },
      );
      
      _messages.add(userMessage);
      _messageStreamController.add(userMessage);
    }
    
    notifyListeners();
  }

  void _completeSession() {
    if (_currentSession == null) return;
    
    _logger.i('Completing session ${_currentSession!.sessionId}');
    
    // Update the current session with completion time
    _currentSession = RoleplaySession(
      sessionId: _currentSession!.sessionId,
      roleplayId: _currentSession!.roleplayId,
      userLevel: _currentSession!.userLevel,
      completedMessages: _currentSession!.completedMessages,
      currentMessageIndex: _currentMessageIndex,
      startedAt: _currentSession!.startedAt,
      completedAt: DateTime.now(),
      statistics: _calculateStatistics(),
    );
    
    // Add completion message
    final completionMessage = ChatMessage(
      id: _uuid.v4(),
      content: 'مبروك! لقد أكملت المحادثة بنجاح! 🎉',
      type: MessageType.system,
      timestamp: DateTime.now(),
      metadata: {
        'translation': 'Congratulations! You completed the conversation successfully!',
        'statistics': _currentSession!.statistics.toJson(),
        'isCompletion': true,  // Flag to identify completion message
      },
    );
    
    _messages.add(completionMessage);
    _messageStreamController.add(completionMessage);
    
    // Clear input state since conversation is done
    _currentInputState = null;
    
    // TODO: Save completed roleplay to user profile
    
    notifyListeners();
  }

  SessionStatistics _calculateStatistics() {
    if (_currentSession == null) return SessionStatistics(
      totalAttempts: 0,
      totalMistakes: 0,
      totalTime: Duration.zero,
      accuracy: 0.0,
      learnedWords: [],
    );
    
    int totalMistakes = 0;
    final learnedWords = <String>{};
    
    for (final completed in _currentSession!.completedMessages) {
      totalMistakes += completed.mistakeCount;
      
      // Extract learned words from the message
      if (_selectedRoleplay != null) {
        final message = _selectedRoleplay!.messages[completed.messageIndex];
        learnedWords.addAll(message.keyVocabulary);
      }
    }
    
    final totalCharacters = _currentSession!.completedMessages
        .map((m) => m.userInput.length)
        .fold(0, (sum, length) => sum + length);
    
    final accuracy = totalCharacters > 0 
        ? ((totalCharacters - totalMistakes) / totalCharacters * 100)
        : 100.0;
    
    return SessionStatistics(
      totalAttempts: _currentSession!.completedMessages.length,
      totalMistakes: totalMistakes,
      totalTime: DateTime.now().difference(_currentSession!.startedAt),
      accuracy: accuracy,
      learnedWords: learnedWords.toList(),
    );
  }

  void _setLoadingTitles(bool value) {
    _isLoadingTitles = value;
    notifyListeners();
  }
  
  void _setLoadingConversation(bool value) {
    _isLoadingConversation = value;
    notifyListeners();
  }

  @override
  void dispose() {
    _messageStreamController.close();
    _openAIService.dispose();
    super.dispose();
  }
}