import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AIDietCoach {
  final String _apiKey = dotenv.env['OPENAI_API_KEY'] ?? '';
  final String _baseUrl = 'https://api.openai.com/v1/chat/completions';
  
  Future<String> sendMessage({
    required String userId,
    required String message,
    List<Map<String, String>>? conversationHistory,
  }) async {
    if (_apiKey.isEmpty) {
      return 'API key not configured. Please add OPENAI_API_KEY to .env file.';
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
          'Authorization': 'Bearer $_apiKey',
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
