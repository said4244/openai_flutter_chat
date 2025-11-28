import 'package:json_annotation/json_annotation.dart';
//import 'chat_message.dart';

part 'roleplay.g.dart';

@JsonSerializable()
class RoleplayTitle {
  final String id;
  final String title;
  final String description;
  final String scenario;
  final DifficultyLevel difficulty;
  final List<String> estimatedVocabulary;
  final String culturalContext;

  RoleplayTitle({
    required this.id,
    required this.title,
    required this.description,
    required this.scenario,
    required this.difficulty,
    required this.estimatedVocabulary,
    required this.culturalContext,
  });

  factory RoleplayTitle.fromJson(Map<String, dynamic> json) =>
      _$RoleplayTitleFromJson(json);

  Map<String, dynamic> toJson() => _$RoleplayTitleToJson(this);
}

@JsonSerializable()
class RoleplayOption {
  final String id;
  final String title;
  final String description;
  final String scenario;
  final List<RoleplayMessage> messages;
  final DifficultyLevel difficulty;
  final List<String> targetVocabulary;
  final String culturalContext;

  RoleplayOption({
    required this.id,
    required this.title,
    required this.description,
    required this.scenario,
    required this.messages,
    required this.difficulty,
    required this.targetVocabulary,
    required this.culturalContext,
  });

  factory RoleplayOption.fromJson(Map<String, dynamic> json) =>
      _$RoleplayOptionFromJson(json);

  Map<String, dynamic> toJson() => _$RoleplayOptionToJson(this);
  
  factory RoleplayOption.fromTitle({
    required RoleplayTitle title,
    required List<RoleplayMessage> messages,
  }) {
    return RoleplayOption(
      id: title.id,
      title: title.title,
      description: title.description,
      scenario: title.scenario,
      difficulty: title.difficulty,
      targetVocabulary: title.estimatedVocabulary,
      culturalContext: title.culturalContext,
      messages: messages,
    );
  }
}

@JsonSerializable()
class RoleplayMessage {
  final int index;
  final MessageRole role;
  final String arabicText;
  final String transliteration;
  final String englishTranslation;
  final List<String> keyVocabulary;
  final String? culturalNote;

  RoleplayMessage({
    required this.index,
    required this.role,
    required this.arabicText,
    required this.transliteration,
    required this.englishTranslation,
    required this.keyVocabulary,
    this.culturalNote,
  });

  factory RoleplayMessage.fromJson(Map<String, dynamic> json) =>
      _$RoleplayMessageFromJson(json);

  Map<String, dynamic> toJson() => _$RoleplayMessageToJson(this);
}

enum MessageRole {
  @JsonValue('ai')
  ai,
  @JsonValue('user')
  user,
}

enum DifficultyLevel {
  @JsonValue('easy')
  easy,
  @JsonValue('medium')
  medium,
  @JsonValue('hard')
  hard,
}

@JsonSerializable()
class RoleplaySession {
  final String sessionId;
  final String roleplayId;
  final UserLevel userLevel;
  final List<CompletedMessage> completedMessages;
  final int currentMessageIndex;
  final DateTime startedAt;
  final DateTime? completedAt;
  final SessionStatistics statistics;

  RoleplaySession({
    required this.sessionId,
    required this.roleplayId,
    required this.userLevel,
    required this.completedMessages,
    required this.currentMessageIndex,
    required this.startedAt,
    this.completedAt,
    required this.statistics,
  });

  factory RoleplaySession.fromJson(Map<String, dynamic> json) =>
      _$RoleplaySessionFromJson(json);

  Map<String, dynamic> toJson() => _$RoleplaySessionToJson(this);

  bool get isCompleted => completedAt != null;
  
  double get progressPercentage => 
      completedMessages.length / 20 * 100; // 20 total messages
}

enum UserLevel {
  @JsonValue('level1')
  level1, // Guided typing
  @JsonValue('level2')
  level2, // Free typing with hints
}



@JsonSerializable()
class CompletedMessage {
  final int messageIndex;
  final String userInput;
  final int attempts;
  final int mistakeCount;
  final Duration timeTaken;
  final List<TypingMistake> mistakes;

  CompletedMessage({
    required this.messageIndex,
    required this.userInput,
    required this.attempts,
    required this.mistakeCount,
    required this.timeTaken,
    required this.mistakes,
  });

  factory CompletedMessage.fromJson(Map<String, dynamic> json) =>
      _$CompletedMessageFromJson(json);

  Map<String, dynamic> toJson() => _$CompletedMessageToJson(this);
}

@JsonSerializable()
class TypingMistake {
  final int position;
  final String expected;
  final String actual;
  final DateTime timestamp;

  TypingMistake({
    required this.position,
    required this.expected,
    required this.actual,
    required this.timestamp,
  });

  factory TypingMistake.fromJson(Map<String, dynamic> json) =>
      _$TypingMistakeFromJson(json);

  Map<String, dynamic> toJson() => _$TypingMistakeToJson(this);
}

@JsonSerializable()
class SessionStatistics {
  final int totalAttempts;
  final int totalMistakes;
  final Duration totalTime;
  final double accuracy;
  final List<String> learnedWords;

  SessionStatistics({
    required this.totalAttempts,
    required this.totalMistakes,
    required this.totalTime,
    required this.accuracy,
    required this.learnedWords,
  });

  factory SessionStatistics.fromJson(Map<String, dynamic> json) =>
      _$SessionStatisticsFromJson(json);

  Map<String, dynamic> toJson() => _$SessionStatisticsToJson(this);
}