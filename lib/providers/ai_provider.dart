import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/ai_diet_coach.dart';

final aiDietCoachProvider = Provider<AIDietCoach>((ref) => AIDietCoach());

class ChatMessage {
  final String role; // 'user' or 'assistant'
  final String content;
  final DateTime timestamp;
  
  ChatMessage({
    required this.role,
    required this.content,
    required this.timestamp,
  });
}

class ChatState {
  final List<ChatMessage> messages;
  final bool isLoading;
  
  ChatState({
    this.messages = const [],
    this.isLoading = false,
  });
  
  ChatState copyWith({
    List<ChatMessage>? messages,
    bool? isLoading,
  }) {
    return ChatState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class ChatNotifier extends StateNotifier<ChatState> {
  ChatNotifier(this.aiDietCoach) : super(ChatState());
  
  final AIDietCoach aiDietCoach;
  
  Future<void> sendMessage(String message, String userId) async {
    // Add user message
    state = state.copyWith(
      messages: [
        ...state.messages,
        ChatMessage(
          role: 'user',
          content: message,
          timestamp: DateTime.now(),
        ),
      ],
      isLoading: true,
    );
    
    // Get conversation history
    final history = state.messages
        .map((msg) => {'role': msg.role, 'content': msg.content})
        .toList();
    
    // Get AI response
    final response = await aiDietCoach.sendMessage(
      userId: userId,
      message: message,
      conversationHistory: history,
    );
    
    // Add assistant message
    state = state.copyWith(
      messages: [
        ...state.messages,
        ChatMessage(
          role: 'assistant',
          content: response,
          timestamp: DateTime.now(),
        ),
      ],
      isLoading: false,
    );
  }
  
  void clearChat() {
    state = ChatState();
  }
}

final chatProvider = StateNotifierProvider<ChatNotifier, ChatState>((ref) {
  final aiDietCoach = ref.watch(aiDietCoachProvider);
  return ChatNotifier(aiDietCoach);
});
