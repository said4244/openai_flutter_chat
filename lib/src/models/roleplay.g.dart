// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'roleplay.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RoleplayOption _$RoleplayOptionFromJson(Map<String, dynamic> json) =>
    RoleplayOption(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      scenario: json['scenario'] as String,
      messages: (json['messages'] as List<dynamic>)
          .map((e) => RoleplayMessage.fromJson(e as Map<String, dynamic>))
          .toList(),
      difficulty: $enumDecode(_$DifficultyLevelEnumMap, json['difficulty']),
      targetVocabulary: (json['targetVocabulary'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      culturalContext: json['culturalContext'] as String,
    );

Map<String, dynamic> _$RoleplayOptionToJson(RoleplayOption instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'description': instance.description,
      'scenario': instance.scenario,
      'messages': instance.messages,
      'difficulty': _$DifficultyLevelEnumMap[instance.difficulty]!,
      'targetVocabulary': instance.targetVocabulary,
      'culturalContext': instance.culturalContext,
    };

const _$DifficultyLevelEnumMap = {
  DifficultyLevel.easy: 'easy',
  DifficultyLevel.medium: 'medium',
  DifficultyLevel.hard: 'hard',
};

RoleplayMessage _$RoleplayMessageFromJson(Map<String, dynamic> json) =>
    RoleplayMessage(
      index: (json['index'] as num).toInt(),
      role: $enumDecode(_$MessageRoleEnumMap, json['role']),
      arabicText: json['arabicText'] as String,
      transliteration: json['transliteration'] as String,
      englishTranslation: json['englishTranslation'] as String,
      keyVocabulary: (json['keyVocabulary'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      culturalNote: json['culturalNote'] as String?,
    );

Map<String, dynamic> _$RoleplayMessageToJson(RoleplayMessage instance) =>
    <String, dynamic>{
      'index': instance.index,
      'role': _$MessageRoleEnumMap[instance.role]!,
      'arabicText': instance.arabicText,
      'transliteration': instance.transliteration,
      'englishTranslation': instance.englishTranslation,
      'keyVocabulary': instance.keyVocabulary,
      'culturalNote': instance.culturalNote,
    };

const _$MessageRoleEnumMap = {
  MessageRole.ai: 'ai',
  MessageRole.user: 'user',
};

RoleplaySession _$RoleplaySessionFromJson(Map<String, dynamic> json) =>
    RoleplaySession(
      sessionId: json['sessionId'] as String,
      roleplayId: json['roleplayId'] as String,
      userLevel: $enumDecode(_$UserLevelEnumMap, json['userLevel']),
      completedMessages: (json['completedMessages'] as List<dynamic>)
          .map((e) => CompletedMessage.fromJson(e as Map<String, dynamic>))
          .toList(),
      currentMessageIndex: (json['currentMessageIndex'] as num).toInt(),
      startedAt: DateTime.parse(json['startedAt'] as String),
      completedAt: json['completedAt'] == null
          ? null
          : DateTime.parse(json['completedAt'] as String),
      statistics: SessionStatistics.fromJson(
          json['statistics'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$RoleplaySessionToJson(RoleplaySession instance) =>
    <String, dynamic>{
      'sessionId': instance.sessionId,
      'roleplayId': instance.roleplayId,
      'userLevel': _$UserLevelEnumMap[instance.userLevel]!,
      'completedMessages': instance.completedMessages,
      'currentMessageIndex': instance.currentMessageIndex,
      'startedAt': instance.startedAt.toIso8601String(),
      'completedAt': instance.completedAt?.toIso8601String(),
      'statistics': instance.statistics,
    };

const _$UserLevelEnumMap = {
  UserLevel.level1: 'level1',
  UserLevel.level2: 'level2',
};

CompletedMessage _$CompletedMessageFromJson(Map<String, dynamic> json) =>
    CompletedMessage(
      messageIndex: (json['messageIndex'] as num).toInt(),
      userInput: json['userInput'] as String,
      attempts: (json['attempts'] as num).toInt(),
      mistakeCount: (json['mistakeCount'] as num).toInt(),
      timeTaken: Duration(microseconds: (json['timeTaken'] as num).toInt()),
      mistakes: (json['mistakes'] as List<dynamic>)
          .map((e) => TypingMistake.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$CompletedMessageToJson(CompletedMessage instance) =>
    <String, dynamic>{
      'messageIndex': instance.messageIndex,
      'userInput': instance.userInput,
      'attempts': instance.attempts,
      'mistakeCount': instance.mistakeCount,
      'timeTaken': instance.timeTaken.inMicroseconds,
      'mistakes': instance.mistakes,
    };

TypingMistake _$TypingMistakeFromJson(Map<String, dynamic> json) =>
    TypingMistake(
      position: (json['position'] as num).toInt(),
      expected: json['expected'] as String,
      actual: json['actual'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );

Map<String, dynamic> _$TypingMistakeToJson(TypingMistake instance) =>
    <String, dynamic>{
      'position': instance.position,
      'expected': instance.expected,
      'actual': instance.actual,
      'timestamp': instance.timestamp.toIso8601String(),
    };

SessionStatistics _$SessionStatisticsFromJson(Map<String, dynamic> json) =>
    SessionStatistics(
      totalAttempts: (json['totalAttempts'] as num).toInt(),
      totalMistakes: (json['totalMistakes'] as num).toInt(),
      totalTime: Duration(microseconds: (json['totalTime'] as num).toInt()),
      accuracy: (json['accuracy'] as num).toDouble(),
      learnedWords: (json['learnedWords'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
    );

Map<String, dynamic> _$SessionStatisticsToJson(SessionStatistics instance) =>
    <String, dynamic>{
      'totalAttempts': instance.totalAttempts,
      'totalMistakes': instance.totalMistakes,
      'totalTime': instance.totalTime.inMicroseconds,
      'accuracy': instance.accuracy,
      'learnedWords': instance.learnedWords,
    };
