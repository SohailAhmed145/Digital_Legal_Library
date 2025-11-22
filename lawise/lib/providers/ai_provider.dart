import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/ai_service.dart';
import '../models/chat_message.dart';

class AIState {
  final bool isLoading;
  final String? errorMessage;
  final List<ChatMessage> messages;
  final String currentConversationId;
  final bool isTyping;

  AIState({
    this.isLoading = false,
    this.errorMessage,
    this.messages = const [],
    this.currentConversationId = '',
    this.isTyping = false,
  });

  AIState copyWith({
    bool? isLoading,
    String? errorMessage,
    List<ChatMessage>? messages,
    String? currentConversationId,
    bool? isTyping,
  }) {
    return AIState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
      messages: messages ?? this.messages,
      currentConversationId: currentConversationId ?? this.currentConversationId,
      isTyping: isTyping ?? this.isTyping,
    );
  }
}

class AINotifier extends StateNotifier<AIState> {
  final AIService _aiService = AIService();

  AINotifier() : super(AIState()) {
    _initializeAI();
  }

  Future<void> _initializeAI() async {
    try {
      state = state.copyWith(isLoading: true);
      await _aiService.initialize();
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to initialize AI service: $e',
      );
    }
  }

  Future<void> sendMessage(String message, {String? context}) async {
    if (message.trim().isEmpty) return;

    // Add user message
    final userMessage = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      conversationId: state.currentConversationId.isEmpty 
          ? DateTime.now().millisecondsSinceEpoch.toString()
          : state.currentConversationId,
      content: message.trim(),
      type: MessageType.user,
      timestamp: DateTime.now(),
    );

    state = state.copyWith(
      messages: [...state.messages, userMessage],
      isTyping: true,
      currentConversationId: userMessage.conversationId,
    );

    try {
      // Get AI response
      final aiResponse = await _aiService.sendMessage(message, context: context);
      
      final aiMessage = ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        conversationId: userMessage.conversationId,
        content: aiResponse,
        type: MessageType.ai,
        timestamp: DateTime.now(),
      );

      state = state.copyWith(
        messages: [...state.messages, aiMessage],
        isTyping: false,
      );
    } catch (e) {
      state = state.copyWith(
        isTyping: false,
        errorMessage: 'Failed to get AI response: $e',
      );
    }
  }

  void clearError() {
    state = state.copyWith(errorMessage: null);
  }

  void startNewChat() {
    state = state.copyWith(
      messages: [],
      currentConversationId: '',
      errorMessage: null,
    );
    _aiService.resetChat();
  }

  void addSystemMessage(String content) {
    final systemMessage = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      conversationId: state.currentConversationId.isEmpty 
          ? DateTime.now().millisecondsSinceEpoch.toString()
          : state.currentConversationId,
      content: content,
      type: MessageType.system,
      timestamp: DateTime.now(),
    );

    state = state.copyWith(
      messages: [...state.messages, systemMessage],
      currentConversationId: systemMessage.conversationId,
    );
  }

  List<ChatMessage> getMessagesForConversation(String conversationId) {
    return state.messages
        .where((message) => message.conversationId == conversationId)
        .toList();
  }

  List<String> getConversationIds() {
    return state.messages
        .map((message) => message.conversationId)
        .toSet()
        .toList();
  }
}

// Providers
final aiProvider = StateNotifierProvider<AINotifier, AIState>((ref) {
  return AINotifier();
});

final aiMessagesProvider = Provider<List<ChatMessage>>((ref) {
  return ref.watch(aiProvider).messages;
});

final aiIsTypingProvider = Provider<bool>((ref) {
  return ref.watch(aiProvider).isTyping;
});

final aiErrorProvider = Provider<String?>((ref) {
  return ref.watch(aiProvider).errorMessage;
});

final aiConversationIdsProvider = Provider<List<String>>((ref) {
  return ref.watch(aiProvider.notifier).getConversationIds();
});
