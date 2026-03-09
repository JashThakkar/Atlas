import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AIDietCoach {
  static const prefsKey = 'gemini_api_key';

  static const _systemPrompt =
      'You are Atlas AI Diet Coach, a supportive and knowledgeable nutritional advisor. '
      'Your role is to:\n'
      '- Provide personalized dietary guidance based on user\'s fitness goals\n'
      '- Offer meal suggestions and nutritional tips\n'
      '- Give encouraging feedback on food choices\n'
      '- Help users build sustainable eating habits\n'
      '- Track meal patterns and provide proactive check-ins\n\n'
      'Be conversational, supportive, and focus on sustainable healthy eating '
      'rather than restrictive diets.';

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
      final env = dotenv.env['GEMINI_API_KEY'] ?? '';
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
    // Google AI Studio keys start with 'AIza' and are at least 30 characters
    if (trimmed.startsWith('AIza') && trimmed.length >= 30) return false;
    // Common placeholder patterns used in .env.example / docs
    return trimmed.contains('your_') ||
        trimmed.toLowerCase().contains('_here');
  }

  Future<String> sendMessage({
    required String userId,
    required String message,
    List<Map<String, String>>? conversationHistory,
  }) async {
    final apiKey = await getApiKey();

    if (apiKey.isEmpty) {
      return 'AI Diet Coach is not configured yet.\n\n'
          'Go to ⚙️ Settings → AI Diet Coach and paste your Gemini API key.\n\n'
          'You can get a free key at https://aistudio.google.com/app/apikey';
    }

    try {
      final model = GenerativeModel(
        model: 'gemini-1.5-flash',
        apiKey: apiKey,
        systemInstruction: Content.system(_systemPrompt),
      );

      // Build conversation history for Gemini.
      // The conversationHistory list already contains the current user message
      // as its last entry (added by ChatNotifier before calling this method),
      // so we exclude that last entry and send the message separately.
      final history = <Content>[];
      if (conversationHistory != null && conversationHistory.isNotEmpty) {
        for (final msg
            in conversationHistory.sublist(0, conversationHistory.length - 1)) {
          final role = msg['role'] ?? '';
          final content = msg['content'] ?? '';
          if (role == 'user') {
            history.add(Content.text(content));
          } else if (role == 'assistant' || role == 'model') {
            history.add(Content.model([TextPart(content)]));
          }
        }
      }

      final chat = model.startChat(history: history);
      final response = await chat.sendMessage(Content.text(message));
      return response.text ?? 'No response received from AI coach.';
    } on InvalidApiKey catch (_) {
      return 'Invalid API key.\n\n'
          'Please check that your Gemini key is correct in ⚙️ Settings → AI Diet Coach.\n\n'
          'You can get a valid key at https://aistudio.google.com/app/apikey';
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
      message: 'Analyze this meal and provide brief feedback: "$mealDescription"\n\n'
          'Include:\n'
          '1. Estimated calories (rough range)\n'
          '2. Nutritional balance assessment\n'
          '3. One suggestion for improvement',
    );
  }
}
