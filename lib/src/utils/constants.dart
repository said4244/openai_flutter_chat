class Constants {
  // API Configuration
  static const String openAIApiEndpoint = 'https://api.openai.com/v1/chat/completions';
  static const String openAIModel = 'gpt-4o-mini';
  
  // UI Constants
  static const double chatMessageFontSize = 18.0;
  static const double keyboardButtonSize = 50.0;
  static const double chatContainerHeight = 0.5; // 50% of screen
  static const double keyboardContainerHeight = 0.5; // 50% of screen
  
  // Animation Durations
  static const Duration typingAnimationDuration = Duration(milliseconds: 150);
  static const Duration scrollAnimationDuration = Duration(milliseconds: 300);
  static const Duration colorTransitionDuration = Duration(milliseconds: 200);
  
  // Colors
  static const int correctColorValue = 0xFF4CAF50; // Green
  static const int incorrectColorValue = 0xFFF44336; // Red
  static const int pendingColorValue = 0xFF757575; // Grey
  
  // Limits
  static const int maxRoleplayMessages = 20;
  static const int maxRetries = 3;
  static const Duration retryDelay = Duration(seconds: 2);
}