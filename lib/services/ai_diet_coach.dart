import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AIDietCoach {
  static const prefsKey = 'openai_api_key';

  final String _baseUrl = 'https://api.openai.com/v1/chat/completions';

  /// Returns the effective API key.
  /// Priority: SharedPreferences (user-entered via Settings) → .env file.
  /// Returns empty string if neither source has a valid key.
  Future<String> getApiKey() async {
    // 1. User-entered key from SharedPreferences
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(prefsKey) ?? '';
      if (saved.isNotEmpty && !_isPlaceholder(saved)) return saved;
    } catch (_) {}

    // 2. Fall back to .env
    try {
      final env = dotenv.env['OPENAI_API_KEY'] ?? '';
      if (env.isNotEmpty && !_isPlaceholder(env)) return env;
    } on Exception catch (_) {}

    return '';
  }

  /// Saves [key] to SharedPreferences so it is used on future calls.
  Future<void> saveApiKey(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(prefsKey, key.trim());
  }

  /// Returns true if the key looks like an unedited placeholder.
  bool _isPlaceholder(String key) {
    final trimmed = key.trim();
    // OpenAI keys start with 'sk-' and are at least 40 characters long
    if (trimmed.startsWith('sk-') && trimmed.length >= 40) return false;
    // Common placeholder patterns used in .env.example / docs
    return trimmed.contains('your_') ||
        trimmed.toLowerCase().contains('_here') ||
        trimmed == 'sk-your-actual-key-here';
  }

  Future<String> sendMessage({
    required String userId,
    required String message,
    List<Map<String, String>>? conversationHistory,
  }) async {
    final apiKey = await getApiKey();

    if (apiKey.isEmpty) {
      return 'AI Diet Coach is not configured yet.\n\n'
          'Go to ⚙️ Settings → AI Diet Coach and paste your OpenAI API key.\n\n'
          'You can get a free key at https://platform.openai.com/api-keys';
    }
    
    final messages = [
      {
        'role': 'system',
        'content': '''You are Atlas AI Diet Coach, a supportive and knowledgeable nutritional advisor. 
Your role is to:
- Provide personalized dietary guidance based on user's fitness goals
- Offer meal suggestions and nutritional tips
- Give encouraging feedback on food choices
- Help users build sustainable eating habits
- Track meal patterns and provide proactive check-ins

Be conversational, supportive, and focus on sustainable healthy eating rather than restrictive diets.'''
      },
      ...?conversationHistory,
      {
        'role': 'user',
        'content': message,
      },
    ];
    
    try {
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: jsonEncode({
          'model': 'gpt-4o-mini',
          'messages': messages,
          'max_tokens': 500,
          'temperature': 0.7,
        }),
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['choices'][0]['message']['content'];
      } else if (response.statusCode == 401) {
        return 'Invalid API key (401 Unauthorized).\n\n'
            'Please check that your OpenAI key is correct in ⚙️ Settings → AI Diet Coach.\n\n'
            'You can get a valid key at https://platform.openai.com/api-keys';
      } else {
        return 'Error: Unable to get response from AI coach. Status: ${response.statusCode}';
      }
    } catch (e) {
      return 'Error connecting to AI coach: $e';
    }
  }
  
  Future<String> getDailyNutritionTip() async {
    return await sendMessage(
      userId: 'system',
      message: 'Give me one actionable nutrition tip for today in 2-3 sentences.',
    );
  }
  
  Future<String> analyzeMeal(String mealDescription) async {
    return await sendMessage(
      userId: 'system',
      message: '''Analyze this meal and provide brief feedback: "$mealDescription"
      
Include:
1. Estimated calories (rough range)
2. Nutritional balance assessment
3. One suggestion for improvement''',
    );
  }
}
