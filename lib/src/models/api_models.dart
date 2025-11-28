import 'package:json_annotation/json_annotation.dart';
import 'user_profile.dart';
import 'roleplay.dart';

part 'api_models.g.dart';

// Request Models

@JsonSerializable()
class GenerateRoleplaysRequest {
  final UserProfile userProfile;
  final String selectedLevel;
  final DateTime currentDate;
  final String? specialContext; // e.g., "Eid is coming", "Birthday season"

  GenerateRoleplaysRequest({
    required this.userProfile,
    required this.selectedLevel,
    required this.currentDate,
    this.specialContext,
  });

  factory GenerateRoleplaysRequest.fromJson(Map<String, dynamic> json) =>
      _$GenerateRoleplaysRequestFromJson(json);

  Map<String, dynamic> toJson() => _$GenerateRoleplaysRequestToJson(this);

  String toPrompt() {
    final age = userProfile.age;
    final culture = userProfile.motherCulture;
    final country = userProfile.motherCountry;
    final arabicLevel = userProfile.arabicLevel.name;
    final strongestLang = userProfile.strongestLanguage;
    final grammarTypes = userProfile.grammarCapabilities.getKnownGrammarTypes();
    final canHandleBig = userProfile.canHandleBigSentences();
    final completedRoleplays = userProfile.completedRoleplays.join(', ');
    final learnedWords = userProfile.learnedWords.take(50).join(', '); // Limit to 50 words

    return '''
Create 3 Arabic roleplay scenarios for:
- Age: $age, Culture: $culture ($country)
- Arabic Level: $arabicLevel, Strongest Language: $strongestLang
- Grammar: ${grammarTypes.join(', ')} (Complex sentences: ${canHandleBig ? 'Yes' : 'No'})
- Learned words (sample): $learnedWords
- Avoid these completed: $completedRoleplays
- Date: ${currentDate.toIso8601String()}${specialContext != null ? ', Context: $specialContext' : ''}

Requirements:
1. Age-appropriate daily life situations
2. Each roleplay: 20 messages (10 AI, 10 user), alternating AI-first
3. Use learned vocabulary when possible
4. Keep messages short and simple for the level
5. Minimize cultural notes and vocabulary lists to save space

JSON structure (be concise):
{
  "roleplays": [{
    "id": "unique_id",
    "title": "Title",
    "description": "Brief desc",
    "scenario": "Setup",
    "difficulty": "easy",
    "targetVocabulary": ["word1", "word2"],
    "culturalContext": "Brief note",
    "messages": [
      {
        "index": 0,
        "role": "ai",
        "arabicText": "السلام عليكم",
        "transliteration": "as-salāmu ʿalaykum",
        "englishTranslation": "Peace be upon you",
        "keyVocabulary": ["السلام"],
        "culturalNote": null
      },
      {
        "index": 1,
        "role": "user",
        "arabicText": "وعليكم السلام",
        "transliteration": "wa ʿalaykumu s-salām",
        "englishTranslation": "And peace be upon you",
        "keyVocabulary": ["وعليكم"],
        "culturalNote": null
      }
    ]
  }]
}''';
  }
}

// Response Models

@JsonSerializable()
class GenerateRoleplaysResponse {
  final List<RoleplayOption> roleplays;

  GenerateRoleplaysResponse({
    required this.roleplays,
  });

  factory GenerateRoleplaysResponse.fromJson(Map<String, dynamic> json) =>
      _$GenerateRoleplaysResponseFromJson(json);

  Map<String, dynamic> toJson() => _$GenerateRoleplaysResponseToJson(this);
}

// OpenAI API Models

@JsonSerializable()
class OpenAIRequest {
  final String model;
  final List<OpenAIMessage> messages;
  final double temperature;
  @JsonKey(name: 'max_tokens')
  final int maxTokens;
  @JsonKey(name: 'response_format')
  final ResponseFormat? responseFormat;

  OpenAIRequest({
    required this.model,
    required this.messages,
    this.temperature = 0.7,
    this.maxTokens = 4000,
    this.responseFormat,
  });

  factory OpenAIRequest.fromJson(Map<String, dynamic> json) =>
      _$OpenAIRequestFromJson(json);

  Map<String, dynamic> toJson() => _$OpenAIRequestToJson(this);
}

@JsonSerializable()
class OpenAIMessage {
  final String role;
  final String content;

  OpenAIMessage({
    required this.role,
    required this.content,
  });

  factory OpenAIMessage.fromJson(Map<String, dynamic> json) =>
      _$OpenAIMessageFromJson(json);

  Map<String, dynamic> toJson() => _$OpenAIMessageToJson(this);
}

@JsonSerializable()
class ResponseFormat {
  final String type;

  ResponseFormat({
    required this.type,
  });

  factory ResponseFormat.json() => ResponseFormat(type: 'json_object');

  factory ResponseFormat.fromJson(Map<String, dynamic> json) =>
      _$ResponseFormatFromJson(json);

  Map<String, dynamic> toJson() => _$ResponseFormatToJson(this);
}

@JsonSerializable()
class OpenAIResponse {
  final String id;
  final String object;
  final int created;
  final String model;
  final List<OpenAIChoice> choices;
  final OpenAIUsage? usage;

  OpenAIResponse({
    required this.id,
    required this.object,
    required this.created,
    required this.model,
    required this.choices,
    this.usage,
  });

  factory OpenAIResponse.fromJson(Map<String, dynamic> json) =>
      _$OpenAIResponseFromJson(json);

  Map<String, dynamic> toJson() => _$OpenAIResponseToJson(this);
}

@JsonSerializable()
class OpenAIChoice {
  final int index;
  final OpenAIMessage message;
  @JsonKey(name: 'finish_reason')
  final String? finishReason;

  OpenAIChoice({
    required this.index,
    required this.message,
    this.finishReason,
  });

  factory OpenAIChoice.fromJson(Map<String, dynamic> json) =>
      _$OpenAIChoiceFromJson(json);

  Map<String, dynamic> toJson() => _$OpenAIChoiceToJson(this);
}

@JsonSerializable()
class OpenAIUsage {
  @JsonKey(name: 'prompt_tokens')
  final int promptTokens;
  @JsonKey(name: 'completion_tokens')
  final int completionTokens;
  @JsonKey(name: 'total_tokens')
  final int totalTokens;

  OpenAIUsage({
    required this.promptTokens,
    required this.completionTokens,
    required this.totalTokens,
  });

  factory OpenAIUsage.fromJson(Map<String, dynamic> json) =>
      _$OpenAIUsageFromJson(json);

  Map<String, dynamic> toJson() => _$OpenAIUsageToJson(this);
}