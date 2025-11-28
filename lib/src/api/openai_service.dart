import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';
import 'dart:html' as html;
import '../models/api_models.dart';
import '../models/roleplay.dart';
import '../models/user_profile.dart';
import '../utils/constants.dart';

class OpenAIService {
  // Replace the late variable with a direct initialization
  final String apiKey = 'OPENAI_API_KEY';
  final http.Client? httpClient;
  final Logger _logger = Logger();
  late final http.Client _client;

  OpenAIService({
    this.httpClient,
  }) : _client = httpClient ?? http.Client();

  // New optimized method - Step 1: Generate only titles
  Future<List<RoleplayTitle>> generateRoleplayTitles({
    required UserProfile userProfile,
    required String selectedLevel,
    DateTime? currentDate,
    String? specialContext,
  }) async {
    try {
      _logger.i('Generating roleplay titles for user: ${userProfile.userId}');
      
      final request = GenerateRoleplayTitlesRequest(
        userProfile: userProfile,
        selectedLevel: selectedLevel,
        currentDate: currentDate ?? DateTime.now(),
        specialContext: specialContext,
      );

      final openAIRequest = OpenAIRequest(
        model: Constants.openAIModel,
        messages: [
          OpenAIMessage(
            role: 'system',
            content: 'You are an expert Arabic language tutor. Generate engaging roleplay titles for language learners. Respond with valid JSON only.',
          ),
          OpenAIMessage(
            role: 'user',
            content: request.toPrompt(),
          ),
        ],
        temperature: 0.8,
        maxTokens: 2000, // Much smaller since we only need titles
        responseFormat: ResponseFormat.json(),
      );

      final response = await _makeApiCall(openAIRequest);
      
      if (response.choices.isEmpty) {
        throw Exception('No response from OpenAI');
      }

      final content = response.choices.first.message.content;
      final jsonData = jsonDecode(content) as Map<String, dynamic>;
      
      _logger.d('Received ${jsonData['roleplays']?.length ?? 0} roleplay titles');
      
      final titlesResponse = GenerateRoleplayTitlesResponse.fromJson(jsonData);
      
      return titlesResponse.roleplays;
    } catch (e, stackTrace) {
      _logger.e('Failed to generate roleplay titles', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  // New optimized method - Step 2: Generate conversation for selected roleplay
  Future<RoleplayOption> generateRoleplayConversation({
    required UserProfile userProfile,
    required RoleplayTitle selectedRoleplay,
  }) async {
    try {
      _logger.i('Generating conversation for roleplay: ${selectedRoleplay.title}');
      
      final request = GenerateRoleplayConversationRequest(
        userProfile: userProfile,
        selectedRoleplay: selectedRoleplay,
      );

      final openAIRequest = OpenAIRequest(
        model: Constants.openAIModel,
        messages: [
          OpenAIMessage(
            role: 'system',
            content: '''You are an expert Arabic language tutor creating a conversation for language practice. 
Generate exactly 20 messages (10 AI, 10 user) that are appropriate for the student's level. 
Keep messages simple and use vocabulary the student knows when possible. Try to incorporate a word that will help the kid learn what he stated he's trying to learn. Respond with valid JSON only.''',
          ),
          OpenAIMessage(
            role: 'user',
            content: request.toPrompt(),
          ),
        ],
        temperature: 0.7,
        maxTokens: 8000, // Reduced since we only generate one conversation
        responseFormat: ResponseFormat.json(),
      );

      final response = await _makeApiCall(openAIRequest);
      
      if (response.choices.isEmpty) {
        throw Exception('No response from OpenAI');
      }

      final content = response.choices.first.message.content;
      
      Map<String, dynamic> jsonData;
      try {
        jsonData = jsonDecode(content) as Map<String, dynamic>;
      } catch (e) {
        _logger.e('Failed to parse JSON response');
        // Try to extract JSON from markdown if needed
        final jsonMatch = RegExp(r'```json\s*(.*?)\s*```', dotAll: true).firstMatch(content);
        if (jsonMatch != null) {
          jsonData = jsonDecode(jsonMatch.group(1)!) as Map<String, dynamic>;
        } else {
          rethrow;
        }
      }
      
      final conversationResponse = GenerateRoleplayConversationResponse.fromJson(jsonData);
      
      // Validate we have exactly 20 messages
      if (conversationResponse.messages.length != 20) {
        _logger.w('Got ${conversationResponse.messages.length} messages, expected 20');
      }
      
      // Create full RoleplayOption from title and messages
      final roleplayOption = RoleplayOption.fromTitle(
        title: selectedRoleplay,
        messages: conversationResponse.messages,
      );
      
      return roleplayOption;
    } catch (e, stackTrace) {
      _logger.e('Failed to generate roleplay conversation', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  // Keep the old method for backwards compatibility (can be removed later)
  Future<List<RoleplayOption>> generateRoleplays({
    required UserProfile userProfile,
    required String selectedLevel,
    DateTime? currentDate,
    String? specialContext,
  }) async {
    try {
      _logger.i('Generating roleplays for user: ${userProfile.userId}');
      
      final request = GenerateRoleplaysRequest(
        userProfile: userProfile,
        selectedLevel: selectedLevel,
        currentDate: currentDate ?? DateTime.now(),
        specialContext: specialContext,
      );

      final openAIRequest = OpenAIRequest(
        model: Constants.openAIModel,
        messages: [
          OpenAIMessage(
            role: 'system',
            content: '''You are an expert Arabic language tutor specializing in creating 
engaging, age-appropriate roleplay scenarios for language learners. You understand 
cultural contexts and create realistic daily-life situations. Always respond with 
valid JSON containing exactly 3 roleplay scenarios, each with exactly 20 messages 
(10 from AI, 10 from user). Keep responses concise to fit within token limits.''',
          ),
          OpenAIMessage(
            role: 'user',
            content: request.toPrompt(),
          ),
        ],
        temperature: 0.8,
        maxTokens: 16000, // Increased token limit
        responseFormat: ResponseFormat.json(),
      );

      final response = await _makeApiCall(openAIRequest);
      
      if (response.choices.isEmpty) {
        throw Exception('No response from OpenAI');
      }

      final content = response.choices.first.message.content;
      
      // Log the raw content for debugging
      _logger.d('Raw response length: ${content.length} characters');
      
      Map<String, dynamic> jsonData;
      try {
        jsonData = jsonDecode(content) as Map<String, dynamic>;
      } catch (e) {
        _logger.e('Failed to parse JSON response');
        _logger.e('Raw content (first 500 chars): ${content.substring(0, content.length > 500 ? 500 : content.length)}');
        _logger.e('Raw content (last 500 chars): ${content.substring(content.length > 500 ? content.length - 500 : 0)}');
        
        // Try to extract and parse just the JSON part if it's wrapped in markdown
        final jsonMatch = RegExp(r'```json\s*(.*?)\s*```', dotAll: true).firstMatch(content);
        if (jsonMatch != null) {
          _logger.i('Found JSON in markdown code block, attempting to parse');
          try {
            jsonData = jsonDecode(jsonMatch.group(1)!) as Map<String, dynamic>;
          } catch (e2) {
            _logger.e('Failed to parse extracted JSON: $e2');
            rethrow;
          }
        } else {
          rethrow;
        }
      }
      
      _logger.d('Received ${jsonData['roleplays']?.length ?? 0} roleplays');
      
      final roleplaysResponse = GenerateRoleplaysResponse.fromJson(jsonData);
      
      // Validate each roleplay has exactly 20 messages
      for (final roleplay in roleplaysResponse.roleplays) {
        if (roleplay.messages.length != 20) {
          _logger.w('Roleplay ${roleplay.id} has ${roleplay.messages.length} messages, expected 20');
        }
        
        // Validate alternating roles
        for (int i = 0; i < roleplay.messages.length; i++) {
          final expectedRole = i % 2 == 0 ? MessageRole.ai : MessageRole.user;
          if (roleplay.messages[i].role != expectedRole) {
            _logger.w('Message $i in roleplay ${roleplay.id} has unexpected role');
          }
        }
      }
      
      return roleplaysResponse.roleplays;
    } catch (e, stackTrace) {
      _logger.e('Failed to generate roleplays', error: e, stackTrace: stackTrace);
      
      // If it's a JSON parsing error, let's try with fewer messages
      if (e.toString().contains('FormatException') || e.toString().contains('JSON')) {
        _logger.i('Retrying with reduced content...');
        return _generateReducedRoleplays(userProfile, selectedLevel, currentDate, specialContext);
      }
      
      rethrow;
    }
  }
  
  Future<List<RoleplayOption>> _generateReducedRoleplays(
    UserProfile userProfile,
    String selectedLevel,
    DateTime? currentDate,
    String? specialContext,
  ) async {
    try {
      _logger.i('Generating reduced roleplays (10 messages each)');
      
      final request = GenerateRoleplaysRequest(
        userProfile: userProfile,
        selectedLevel: selectedLevel,
        currentDate: currentDate ?? DateTime.now(),
        specialContext: specialContext,
      );

      final prompt = '''
Create 3 SHORT Arabic roleplay scenarios for:
- Age: ${userProfile.age}, Arabic Level: ${userProfile.arabicLevel.name}
- Each roleplay: 10 messages (5 AI, 5 user), alternating AI-first
- Keep VERY brief and simple

JSON structure:
{
  "roleplays": [{
    "id": "1",
    "title": "Simple Greeting",
    "description": "Basic hello",
    "scenario": "Meeting someone",
    "difficulty": "easy",
    "targetVocabulary": ["مرحبا", "كيف"],
    "culturalContext": "Greeting",
    "messages": [
      {"index": 0, "role": "ai", "arabicText": "مرحبا", "transliteration": "marhaba", 
       "englishTranslation": "Hello", "keyVocabulary": ["مرحبا"], "culturalNote": null},
      {"index": 1, "role": "user", "arabicText": "مرحبا", "transliteration": "marhaba", 
       "englishTranslation": "Hello", "keyVocabulary": ["مرحبا"], "culturalNote": null}
    ]
  }]
}''';

      final openAIRequest = OpenAIRequest(
        model: Constants.openAIModel,
        messages: [
          OpenAIMessage(
            role: 'system',
            content: 'You are an Arabic tutor. Create simple, short roleplays. Respond ONLY with valid JSON.',
          ),
          OpenAIMessage(
            role: 'user',
            content: prompt,
          ),
        ],
        temperature: 0.7,
        maxTokens: 8000,
        responseFormat: ResponseFormat.json(),
      );

      final response = await _makeApiCall(openAIRequest);
      final content = response.choices.first.message.content;
      final jsonData = jsonDecode(content) as Map<String, dynamic>;
      
      // Manually adjust to have 20 messages by duplicating/expanding
      final roleplays = GenerateRoleplaysResponse.fromJson(jsonData).roleplays;
      
      // Expand each roleplay to 20 messages
      for (final roleplay in roleplays) {
        while (roleplay.messages.length < 20) {
          final lastUserIndex = roleplay.messages.length - 1;
          final nextAiIndex = roleplay.messages.length;
          final nextUserIndex = roleplay.messages.length + 1;
          
          // Add simple continuation messages
          roleplay.messages.add(RoleplayMessage(
            index: nextAiIndex,
            role: MessageRole.ai,
            arabicText: 'شكرا',
            transliteration: 'shukran',
            englishTranslation: 'Thank you',
            keyVocabulary: ['شكرا'],
            culturalNote: null,
          ));
          
          if (roleplay.messages.length < 20) {
            roleplay.messages.add(RoleplayMessage(
              index: nextUserIndex,
              role: MessageRole.user,
              arabicText: 'عفوا',
              transliteration: 'afwan',
              englishTranslation: 'You\'re welcome',
              keyVocabulary: ['عفوا'],
              culturalNote: null,
            ));
          }
        }
      }
      
      return roleplays;
    } catch (e) {
      _logger.e('Failed to generate reduced roleplays', error: e);
      throw Exception('Unable to generate roleplays. Please try again.');
    }
  }

  Future<OpenAIResponse> _makeApiCall(OpenAIRequest request) async {
    try {
      final uri = Uri.parse(Constants.openAIApiEndpoint);
      
      final response = await _client.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: jsonEncode(request.toJson()),
      ).timeout(
        const Duration(seconds: 120),
        onTimeout: () => throw Exception('API request timed out'),
      );

      _logger.d('API Response Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body) as Map<String, dynamic>;
        return OpenAIResponse.fromJson(jsonData);
      } else {
        final error = jsonDecode(response.body);
        throw Exception('OpenAI API error: ${error['error']?['message'] ?? response.body}');
      }
    } catch (e) {
      _logger.e('API call failed', error: e);
      rethrow;
    }
  }

  void dispose() {
    if (httpClient == null) {
      _client.close();
    }
  }
}
