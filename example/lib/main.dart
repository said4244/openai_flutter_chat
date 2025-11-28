import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:arabic_chat_roleplay/arabic_chat_roleplay.dart';

// Providers
final chatControllerProvider = ChangeNotifierProvider<ChatController>((ref) {
  // Mock user profile - in real app, load from storage/API
  final userProfile = UserProfile(
    userId: 'user123',
    age: 12,
    birthDate: DateTime(2011, 5, 15),
    motherCountry: 'Egypt',
    motherCulture: 'Egyptian',
    strongestLanguage: 'English',
    arabicLevel: ArabicLevel.beginner,
    learnedWords: ['مرحبا', 'شكرا', 'من فضلك', 'نعم', 'لا'],
    grammarCapabilities: GrammarCapabilities(
      knowsNouns: true,
      knowsPronouns: false,
      knowsVerbs: false,
      knowsAdjectives: false,
      knowsAdverbs: false,
      knowsPrepositions: false,
      knowsConjunctions: false,
      knowsInterjections: true,
    ),
    completedRoleplays: [],
  );

  final openAIService = OpenAIService();

  return ChatController(
    openAIService: openAIService,
    userProfile: userProfile,
  );
});

void main() {
  runApp(
    const ProviderScope(
      child: ArabicChatApp(),
    ),
  );
}

class ArabicChatApp extends StatelessWidget {
  const ArabicChatApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Arabic Chat Roleplay',
      theme: ThemeData(
        primarySwatch: Colors.teal,
        fontFamily: 'Amiri',
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends ConsumerStatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  String? selectedLevel;

  @override
  Widget build(BuildContext context) {
    final chatController = ref.watch(chatControllerProvider);

    if (chatController.selectedRoleplay != null) {
      return const ChatScreen();
    }

    if (chatController.roleplayOptions.isNotEmpty) {
      return RoleplaySelectionScreen(
        options: chatController.roleplayOptions,
        onSelect: (roleplay) {
          chatController.selectRoleplay(roleplay);
        },
        onCancel: () {
          setState(() {
            selectedLevel = null;
          });
          chatController.roleplayOptions.clear();
        },
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'مرحباً',
              style: TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1976D2),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'اختر مستواك',
              style: TextStyle(
                fontSize: 24,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 48),
            if (chatController.isLoading)
              const CircularProgressIndicator()
            else
              ..._buildLevelButtons(context, chatController),
            if (chatController.error != null) ...[
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.symmetric(horizontal: 32),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Text(
                  chatController.error!,
                  style: TextStyle(color: Colors.red.shade700),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  List<Widget> _buildLevelButtons(BuildContext context, ChatController controller) {
    final levels = [
      {'id': 'beginner', 'label': 'مبتدئ', 'icon': Icons.looks_one},
      {'id': 'elementary', 'label': 'ابتدائي', 'icon': Icons.looks_two},
      {'id': 'intermediate', 'label': 'متوسط', 'icon': Icons.looks_3},
    ];

    return levels.map((level) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: ElevatedButton.icon(
          onPressed: () {
            setState(() {
              selectedLevel = level['id'] as String;
            });
            controller.loadRoleplayOptions(
              selectedLevel: level['id'] as String,
              specialContext: _getSpecialContext(),
            );
          },
          icon: Icon(level['icon'] as IconData),
          label: Text(
            level['label'] as String,
            style: const TextStyle(fontSize: 20),
          ),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
          ),
        ),
      );
    }).toList();
  }

  String? _getSpecialContext() {
    final now = DateTime.now();
    // Check for special occasions
    // This is simplified - in real app, check actual Islamic calendar
    if (now.month == 12) {
      return 'New Year celebrations are coming';
    }
    if (now.month == 4 || now.month == 5) {
      return 'Ramadan/Eid season';
    }
    if (now.month == 6) {
      return 'Eid Adha season';
    }
    return null;
  }
}

class RoleplaySelectionScreen extends StatelessWidget {
  final List<RoleplayOption> options;
  final Function(RoleplayOption) onSelect;
  final VoidCallback onCancel;

  const RoleplaySelectionScreen({
    Key? key,
    required this.options,
    required this.onSelect,
    required this.onCancel,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('اختر المحادثة'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: onCancel,
        ),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: options.length,
        itemBuilder: (context, index) {
          final option = options[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: InkWell(
              onTap: () => onSelect(option),
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          _getIconForScenario(option.title),
                          size: 32,
                          color: Theme.of(context).primaryColor,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            option.title,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        _buildDifficultyChip(option.difficulty),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      option.description,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      children: option.targetVocabulary.take(5).map((word) {
                        return Chip(
                          label: Text(
                            word,
                            style: const TextStyle(fontSize: 12),
                          ),
                          backgroundColor: Colors.teal.shade50,
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  IconData _getIconForScenario(String title) {
    if (title.toLowerCase().contains('greeting')) return Icons.waving_hand;
    if (title.toLowerCase().contains('food')) return Icons.restaurant;
    if (title.toLowerCase().contains('shop')) return Icons.shopping_bag;
    if (title.toLowerCase().contains('school')) return Icons.school;
    if (title.toLowerCase().contains('family')) return Icons.family_restroom;
    return Icons.chat_bubble;
  }

  Widget _buildDifficultyChip(DifficultyLevel difficulty) {
    final color = switch (difficulty) {
      DifficultyLevel.easy => Colors.green,
      DifficultyLevel.medium => Colors.orange,
      DifficultyLevel.hard => Colors.red,
    };

    final label = switch (difficulty) {
      DifficultyLevel.easy => 'سهل',
      DifficultyLevel.medium => 'متوسط',
      DifficultyLevel.hard => 'صعب',
    };

    return Chip(
      label: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
        ),
      ),
      backgroundColor: color,
    );
  }
}

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _completionDialogShown = false;

  @override
  void initState() {
    super.initState();
    // Auto-scroll when new messages arrive
    ref.read(chatControllerProvider).messageStream.listen((message) {
      _scrollToBottom();
      
      // Check if this is a completion message
      if (message.metadata?['isCompletion'] == true && !_completionDialogShown) {
        _completionDialogShown = true;
        Future.delayed(const Duration(milliseconds: 500), () {
          _showCompletionDialog();
        });
      }
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: Constants.scrollAnimationDuration,
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _showKeyboardGuidePopup() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Icon(Icons.tips_and_updates, color: Colors.orange.shade700),
            const SizedBox(width: 8),
            const Text('نصيحة'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'يبدو أن هناك بعض الأخطاء في كتابتك.',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 12),
            const Text(
              'جرب تشغيل دليل لوحة المفاتيح لمساعدتك!',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Try turning on the keyboard guide to help you!',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('حسناً'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              ref.read(chatControllerProvider).toggleKeyboardGuide();
            },
            icon: const Icon(Icons.keyboard),
            label: const Text('تشغيل الدليل'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal,
            ),
          ),
        ],
      ),
    );
  }

  void _showCompletionDialog() {
    final chatController = ref.read(chatControllerProvider);
    final statistics = chatController.messages.last.metadata?['statistics'];
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Trophy icon
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.amber.shade100,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.emoji_events,
                  size: 50,
                  color: Colors.amber.shade700,
                ),
              ),
              const SizedBox(height: 20),
              
              // Congratulations text
              const Text(
                'أحسنت!',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.teal,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Well Done!',
                style: TextStyle(
                  fontSize: 20,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 24),
              
              // Statistics
              if (statistics != null) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      _buildStatRow(
                        'الدقة',
                        'Accuracy',
                        '${statistics['accuracy']?.toStringAsFixed(1) ?? '0'}%',
                        Icons.check_circle,
                        Colors.green,
                      ),
                      const Divider(height: 20),
                      _buildStatRow(
                        'الوقت',
                        'Time',
                        _formatDuration(statistics['totalTime'] ?? 0),
                        Icons.timer,
                        Colors.blue,
                      ),
                      const Divider(height: 20),
                      _buildStatRow(
                        'الأخطاء',
                        'Mistakes',
                        '${statistics['totalMistakes'] ?? 0}',
                        Icons.close,
                        Colors.red,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],
              
              // Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: const Text('مراجعة'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        chatController.cancelSelection();
                      },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        backgroundColor: Colors.teal,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: const Text(
                        'الصفحة الرئيسية',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatRow(
    String arabicLabel,
    String englishLabel,
    String value,
    IconData icon,
    Color color,
  ) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              arabicLabel,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              englishLabel,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
        const Spacer(),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  String _formatDuration(int microseconds) {
    final duration = Duration(microseconds: microseconds);
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final chatController = ref.watch(chatControllerProvider);
    final isConversationComplete = chatController.currentInputState == null && 
                                   chatController.messages.isNotEmpty &&
                                   chatController.messages.any((m) => m.metadata?['isCompletion'] == true);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(chatController.selectedRoleplay?.title ?? 'Chat'),
        actions: [
          // Keyboard guide toggle
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.keyboard, size: 20),
              Switch(
                value: chatController.keyboardGuideEnabled,
                onChanged: (_) => chatController.toggleKeyboardGuide(),
                activeColor: Colors.teal,
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('إنهاء المحادثة؟'),
                  content: const Text('هل تريد إنهاء هذه المحادثة؟'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('لا'),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                        chatController.cancelSelection();
                      },
                      child: const Text('نعم'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Progress indicator
          LinearProgressIndicator(
            value: chatController.sessionProgress / 100,
            backgroundColor: Colors.grey.shade200,
            color: Colors.teal,
          ),
          // Chat messages (50% of remaining space)
          Expanded(
            child: Container(
              color: Colors.grey.shade50,
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(16),
                itemCount: chatController.messages.length,
                itemBuilder: (context, index) {
                  final message = chatController.messages[index];
                  return ChatMessageWidget(
                    message: message,
                    isLastUserMessage: message.type == MessageType.user &&
                        index == chatController.messages.length - 1,
                  );
                },
              ),
            ),
          ),
          // Divider
          Container(
            height: 1,
            color: Colors.grey.shade300,
          ),
          // Arabic keyboard OR completion message
          Expanded(
            child: isConversationComplete
                ? _buildCompletionView()
                : Container(
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 4,
                          offset: const Offset(0, -2),
                        ),
                      ],
                    ),
                    child: ArabicKeyboardWidget(
                      onCharacterTap: (char, position) {
                        chatController.processCharacterInput(char, position);
                        // Auto-scroll when typing
                        _scrollToBottom();
                      },
                      expectedInput: chatController.currentInputState?.expectedInput ?? '',
                      currentInputState: chatController.currentInputState,
                      canSend: chatController.canSendMessage(),
                      keyboardGuideEnabled: chatController.keyboardGuideEnabled,
                      onSend: () {
                        // Validate before sending
                        if (!chatController.validateBeforeSend()) {
                          _showKeyboardGuidePopup();
                          return;
                        }
                        chatController.sendMessage();
                        _scrollToBottom();
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompletionView() {
    return Container(
      color: Colors.teal.shade50,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.celebration,
              size: 80,
              color: Colors.teal.shade700,
            ),
            const SizedBox(height: 20),
            const Text(
              'ممتاز! أكملت المحادثة',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Excellent! You completed the conversation',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () {
                ref.read(chatControllerProvider).cancelSelection();
              },
              icon: const Icon(Icons.home),
              label: const Text('العودة للصفحة الرئيسية'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                backgroundColor: Colors.teal,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
}

class ChatMessageWidget extends StatelessWidget {
  final ChatMessage message;
  final bool isLastUserMessage;

  const ChatMessageWidget({
    Key? key,
    required this.message,
    this.isLastUserMessage = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isAI = message.type == MessageType.ai;
    final isSystem = message.type == MessageType.system;

    if (isSystem) {
      return Center(
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.teal.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.teal.shade200),
          ),
          child: Column(
            children: [
              Text(
                message.content,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              if (message.metadata?['translation'] != null) ...[
                const SizedBox(height: 8),
                Text(
                  message.metadata!['translation'],
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey.shade700,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        ),
      );
    }

    return Align(
      alignment: isAI ? Alignment.centerLeft : Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.8,
        ),
        child: Column(
          crossAxisAlignment: isAI ? CrossAxisAlignment.start : CrossAxisAlignment.end,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isAI) ...[
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.teal,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.smart_toy,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                Flexible(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isAI ? Colors.white : Colors.teal.shade50,
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(20),
                        topRight: const Radius.circular(20),
                        bottomLeft: isAI ? const Radius.circular(4) : const Radius.circular(20),
                        bottomRight: isAI ? const Radius.circular(20) : const Radius.circular(4),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (message.type == MessageType.user && isLastUserMessage && message.inputState != null)
                          _buildUserInputDisplay(message)
                        else
                          Text(
                            message.content,
                            style: const TextStyle(
                              fontSize: 20,
                              height: 1.5,
                            ),
                            textAlign: isAI ? TextAlign.left : TextAlign.right,
                            textDirection: TextDirection.rtl,
                          ),
                        if (message.metadata != null && 
                            (message.metadata!['transliteration'] != null || 
                             message.metadata!['translation'] != null)) ...[
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (message.metadata!['transliteration'] != null)
                                  Text(
                                    message.metadata!['transliteration'],
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey.shade700,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                if (message.metadata!['transliteration'] != null && 
                                    message.metadata!['translation'] != null)
                                  const SizedBox(height: 4),
                                if (message.metadata!['translation'] != null)
                                  Text(
                                    message.metadata!['translation'],
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey.shade800,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                if (!isAI) ...[
                  const SizedBox(width: 8),
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.orange,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.person,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserInputDisplay(ChatMessage message) {
    final inputState = message.inputState;
    if (inputState == null || inputState.expectedInput.isEmpty) {
      return const Text(
        'اكتب الرد...',
        style: TextStyle(
          fontSize: 18,
          color: Colors.grey,
          fontStyle: FontStyle.italic,
        ),
        textDirection: TextDirection.rtl,
      );
    }

    // Build the complete string with proper Arabic connection
    final List<TextSpan> spans = [];
    
    for (int i = 0; i < inputState.expectedInput.length; i++) {
      final charState = inputState.characterStates.firstWhere(
        (s) => s.index == i,
        orElse: () => CharacterState(
          index: i,
          character: '',
          status: CharacterStatus.pending,
        ),
      );

      String displayChar;
      Color color;

      switch (charState.status) {
        case CharacterStatus.correct:
          displayChar = charState.character;
          color = const Color(Constants.correctColorValue);
          break;
        case CharacterStatus.incorrect:
          displayChar = charState.character;
          color = const Color(Constants.incorrectColorValue);
          break;
        case CharacterStatus.pending:
          displayChar = inputState.expectedInput[i] == ' ' ? '␣' : inputState.expectedInput[i];
          color = Colors.grey.shade400;
          break;
      }

      spans.add(TextSpan(
        text: displayChar,
        style: TextStyle(
          fontSize: 22,
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ));
    }

    return RichText(
      textDirection: TextDirection.rtl,
      text: TextSpan(
        children: spans,
        style: const TextStyle(
          fontFamily: 'Arial', // Ensure proper Arabic font
        ),
      ),
    );
  }
}

class ArabicKeyboardWidget extends ConsumerStatefulWidget {
  final Function(String, int) onCharacterTap;
  final String expectedInput;
  final InputState? currentInputState;
  final bool canSend;
  final bool keyboardGuideEnabled;
  final VoidCallback onSend;

  const ArabicKeyboardWidget({
    Key? key,
    required this.onCharacterTap,
    required this.expectedInput,
    this.currentInputState,
    required this.canSend,
    required this.keyboardGuideEnabled,
    required this.onSend,
  }) : super(key: key);

  @override
  ConsumerState<ArabicKeyboardWidget> createState() => _ArabicKeyboardWidgetState();
}

class _ArabicKeyboardWidgetState extends ConsumerState<ArabicKeyboardWidget> {
  @override
  Widget build(BuildContext context) {
    final chatController = ref.watch(chatControllerProvider);
    
    return Column(
      children: [
        // Expected input display
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.white,
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'اكتب:',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                  if (!widget.keyboardGuideEnabled) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.visibility_off, size: 14, color: Colors.orange.shade700),
                          const SizedBox(width: 4),
                          Text(
                            'الدليل مغلق',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.orange.shade700,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 8),
              Text(
                widget.expectedInput,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                textDirection: TextDirection.rtl,
              ),
              // Show current input with color coding
              if (widget.currentInputState != null && widget.currentInputState!.characterStates.isNotEmpty) ...[
                const SizedBox(height: 8),
                _buildCurrentInputDisplay(),
              ],
            ],
          ),
        ),
        // Keyboard
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(8),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ...ArabicKeyboard.layout.map((row) {
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: row.map((key) {
                      return _buildKey(context, key);
                    }).toList(),
                  );
                }).toList(),
                // Bottom row with delete button and send button
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Delete button
                    _buildDeleteButton(context, ref),
                    const SizedBox(width: 16),
                    // Send button
                    Expanded(
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 8),
                        child: ElevatedButton.icon(
                          onPressed: widget.canSend ? widget.onSend : null,
                          icon: const Icon(Icons.send),
                          label: const Text('إرسال'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 32,
                              vertical: 16,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCurrentInputDisplay() {
    // Build the complete string with proper Arabic connection
    final StringBuffer displayText = StringBuffer();
    final List<TextSpan> spans = [];
    
    for (int i = 0; i < widget.expectedInput.length; i++) {
      final charState = widget.currentInputState!.characterStates.firstWhere(
        (s) => s.index == i,
        orElse: () => CharacterState(
          index: i,
          character: '',
          status: CharacterStatus.pending,
        ),
      );

      String displayChar;
      Color color;

      switch (charState.status) {
        case CharacterStatus.correct:
          displayChar = charState.character;
          color = const Color(Constants.correctColorValue);
          break;
        case CharacterStatus.incorrect:
          displayChar = charState.character;
          color = const Color(Constants.incorrectColorValue);
          break;
        case CharacterStatus.pending:
          displayChar = widget.expectedInput[i] == ' ' ? '␣' : widget.expectedInput[i];
          color = Colors.grey.shade400;
          break;
      }

      displayText.write(displayChar);
      
      spans.add(TextSpan(
        text: displayChar,
        style: TextStyle(
          fontSize: 24,
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ));
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: RichText(
        textDirection: TextDirection.rtl,
        text: TextSpan(
          children: spans,
          style: const TextStyle(
            fontFamily: 'Arial', // Ensure proper Arabic font
          ),
        ),
      ),
    );
  }

  Widget _buildKey(BuildContext context, String key) {
    final nextPosition = widget.currentInputState?.cursorPosition ?? 0;
    final isSpace = key == ' ';

    return Expanded(
      flex: isSpace ? 4 : 1,
      child: Container(
        margin: const EdgeInsets.all(2),
        child: Material(
          elevation: 2,
          borderRadius: BorderRadius.circular(8),
          color: _getKeyColor(key, nextPosition),
          child: InkWell(
            onTap: () => _handleKeyTap(context, key, nextPosition),
            borderRadius: BorderRadius.circular(8),
            child: Container(
              height: Constants.keyboardButtonSize,
              alignment: Alignment.center,
              child: Text(
                isSpace ? 'مسافة' : key,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _handleKeyTap(BuildContext context, String key, int position) {
    // Check if this key has diacritics and if the expected character is one of its variants
    if (ArabicKeyboard.hasDiacritics(key) && position < widget.expectedInput.length) {
      final expectedChar = widget.expectedInput[position];
      final variants = ArabicKeyboard.getDiacritics(key);
      
      // If the expected character is one of the variants, show the popup
      if (variants.contains(expectedChar)) {
        _showDiacriticsPopup(context, key, position, expectedChar);
        return;
      }
    }
    
    // Otherwise, handle normal character input
    widget.onCharacterTap(key, position);
  }

  void _showDiacriticsPopup(BuildContext context, String baseKey, int position, String expectedChar) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        final variants = ArabicKeyboard.getDiacritics(baseKey);
        
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'اختر الشكل المناسب',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey.shade700,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: variants.map((variant) {
                    final isExpected = variant == expectedChar;
                    // Only highlight if keyboard guide is enabled
                    final shouldHighlight = isExpected && widget.keyboardGuideEnabled;
                    
                    return Material(
                      elevation: shouldHighlight ? 4 : 2,
                      borderRadius: BorderRadius.circular(12),
                      color: shouldHighlight ? Colors.blue : Colors.grey.shade100,
                      child: InkWell(
                        onTap: () {
                          Navigator.pop(context);
                          widget.onCharacterTap(variant, position);
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          width: 60,
                          height: 60,
                          alignment: Alignment.center,
                          child: Text(
                            variant,
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: shouldHighlight ? Colors.white : Colors.black87,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDeleteButton(BuildContext context, WidgetRef ref) {
    final chatController = ref.watch(chatControllerProvider);
    final shouldHighlight = chatController.shouldHighlightBackspace;
    
    return Container(
      margin: const EdgeInsets.all(2),
      child: Material(
        elevation: shouldHighlight ? 4 : 2,
        borderRadius: BorderRadius.circular(8),
        color: shouldHighlight ? Colors.blue : Colors.grey.shade300,
        child: InkWell(
          onTap: () => chatController.processBackspace(),
          borderRadius: BorderRadius.circular(8),
          child: Container(
            width: Constants.keyboardButtonSize * 2,
            height: Constants.keyboardButtonSize,
            alignment: Alignment.center,
            child: Icon(
              Icons.backspace,
              color: shouldHighlight ? Colors.white : Colors.black87,
              size: 24,
            ),
          ),
        ),
      ),
    );
  }

  Color _getKeyColor(String key, int position) {
    if (position >= widget.expectedInput.length) return Colors.grey.shade300;

    // If keyboard guide is disabled, all keys are white
    if (!widget.keyboardGuideEnabled) {
      return Colors.white;
    }

    final expectedChar = widget.expectedInput[position];
    
    // Direct match
    if (key == expectedChar) {
      return Colors.teal.shade100;
    }
    
    // Check if this key has variants and the expected char is one of them
    if (ArabicKeyboard.hasDiacritics(key)) {
      final variants = ArabicKeyboard.getDiacritics(key);
      if (variants.contains(expectedChar)) {
        return Colors.blue.shade100;  // Highlight in blue for variants
      }
    }
    
    return Colors.white;
  }
}