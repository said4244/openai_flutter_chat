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
  }) : _client = httpClient ?? http.Client();  // Remove _loadApiKey() call

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
(10 from AI, 10 from user). Keep responses concise to fit within token limits. Avoid json errors''',
          ),
          OpenAIMessage(
            role: 'user',
            content: request.toPrompt(),
          ),
        ],
        temperature: 0.8,
        maxTokens: 16000,
        responseFormat: ResponseFormat.json(),
      );

      final response = await _makeApiCall(openAIRequest);
      
      if (response.choices.isEmpty) {
        throw Exception('No response from OpenAI');
      }

      final content = response.choices.first.message.content;
      final jsonData = jsonDecode(content) as Map<String, dynamic>;
      
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
      rethrow;
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
