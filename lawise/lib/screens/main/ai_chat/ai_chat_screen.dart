import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';
import '../../../theme/app_theme.dart';
import '../../../providers/theme_provider.dart';
import '../../../providers/language_provider.dart';
import '../../../providers/user_profile_provider.dart';
import '../../../providers/ai_provider.dart';
import '../../../providers/navigation_provider.dart';
import '../../../models/chat_message.dart' as models;
import '../../../widgets/profile_image_widget.dart';
import '../settings/settings_screen.dart';

class AiChatScreen extends ConsumerStatefulWidget {
  const AiChatScreen({super.key});

  @override
  ConsumerState<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends ConsumerState<AiChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  @override
  void initState() {
    super.initState();
    // Initialize with welcome message if no messages exist
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final aiState = ref.read(aiProvider);
      if (aiState.messages.isEmpty) {
        _addWelcomeMessage();
      }
    });
  }
  
  void _addWelcomeMessage() {
    final welcomeMessage = models.ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      conversationId: DateTime.now().millisecondsSinceEpoch.toString(),
      content: "Hello! I'm your AI Legal Assistant. How can I help you today with legal matters?",
      type: models.MessageType.ai,
      timestamp: DateTime.now(),
    );
    
    ref.read(aiProvider.notifier).state = ref.read(aiProvider.notifier).state.copyWith(
      messages: [welcomeMessage],
      currentConversationId: welcomeMessage.conversationId,
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage() async {
    if (_messageController.text.trim().isNotEmpty) {
      final message = _messageController.text.trim();
      _messageController.clear();
      
      // Send message through AI provider
      await ref.read(aiProvider.notifier).sendMessage(message);
      
      // Scroll to bottom after sending message
      _scrollToBottom();
    }
  }
  
  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }
  
  void _sendPredefinedMessage(String message) async {
    await ref.read(aiProvider.notifier).sendMessage(message);
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = ref.watch(themeProvider);
    final currentLanguage = ref.watch(languageProvider);
    
    return WillPopScope(
      onWillPop: () async {
        // Navigate to Home tab instead of popping the route to avoid white screen
        ref.read(navigationProvider.notifier).navigateToTab(0);
        return false;
      },
      child: Scaffold(
      backgroundColor: isDarkMode ? AppTheme.darkBackgroundColor : Colors.white,
      appBar: AppBar(
        backgroundColor: isDarkMode ? AppTheme.darkSurfaceColor : const Color(0xFFF5F5F5),
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: isDarkMode ? Colors.white : Colors.black),
          onPressed: () {
            // Switch to Home tab instead of popping the route
            ref.read(navigationProvider.notifier).navigateToTab(0);
          },
        ),
        title: Text(
          currentLanguage == 'urdu' ? 'AI قانونی اسسٹنٹ' : 'AI Legal Assistant',
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: isDarkMode ? Colors.white : Colors.black,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: isDarkMode ? Colors.white : Colors.black),
            onPressed: () {
              // Refresh chat history
            },
          ),
          GestureDetector(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const SettingsScreen(),
                ),
              );
            },
            child: const Padding(
              padding: EdgeInsets.all(8.0),
              child: ProfileImageWidget(
                size: 32,
                borderWidth: 1,
                showBorder: true,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Chat messages
          Expanded(
            child: Consumer(
              builder: (context, ref, child) {
                final aiState = ref.watch(aiProvider);
                
                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: aiState.messages.length,
                  itemBuilder: (context, index) {
                    final message = aiState.messages[index];
                    return _buildMessageBubble(message);
                  },
                );
              },
            ),
          ),
          
          // Typing indicator
          Consumer(
            builder: (context, ref, child) {
              final aiState = ref.watch(aiProvider);
              if (aiState.isTyping) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: isDarkMode ? Colors.grey[700] : const Color(0xFF424242),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Icon(
                          Icons.smart_toy,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isDarkMode ? AppTheme.darkSurfaceColor : const Color(0xFFF5F5F5),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  isDarkMode ? Colors.white : Colors.black,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'AI is typing...',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                color: isDarkMode ? Colors.white : Colors.black,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),

          // Action buttons
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Expanded(
                  child: _buildActionButton(
                    icon: Icons.gavel,
                    label: currentLanguage == 'urdu' ? 'کیس کی وضاحت' : 'Explain Case',
                    onTap: () {
                      _sendPredefinedMessage('Can you help me understand the legal aspects of my case and provide guidance on next steps?');
                    },
                    isDarkMode: isDarkMode,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildActionButton(
                    icon: Icons.search,
                    label: currentLanguage == 'urdu' ? 'قوانین تلاش کریں' : 'Find Laws',
                    onTap: () {
                      _sendPredefinedMessage('I need help finding relevant laws and regulations for my legal matter. Can you assist me with legal research?');
                    },
                    isDarkMode: isDarkMode,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildActionButton(
                    icon: Icons.description,
                    label: currentLanguage == 'urdu' ? 'تیار کریں' : 'Generate',
                    onTap: () {
                      _sendPredefinedMessage('Can you help me draft a legal document or provide a template for my specific legal needs?');
                    },
                    isDarkMode: isDarkMode,
                  ),
                ),
              ],
            ),
          ),

          // Input field
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Voice input button
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: isDarkMode ? AppTheme.darkSurfaceColor : const Color(0xFFF5F5F5),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: IconButton(
                    icon: Icon(Icons.mic, color: isDarkMode ? Colors.white : Colors.black),
                    onPressed: () {
                      // Handle voice input
                    },
                  ),
                ),
                const SizedBox(width: 12),
                
                // Text input field
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: isDarkMode ? AppTheme.darkSurfaceColor : const Color(0xFFF5F5F5),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: TextField(
                      controller: _messageController,
                      decoration: InputDecoration(
                        hintText: currentLanguage == 'urdu' 
                          ? 'قوانین، کیسز، یا قانونی مشورے کے بارے میں پوچھیں'
                          : 'Ask about laws, cases, or legal advice',
                        hintStyle: GoogleFonts.inter(
                          color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                          fontSize: 16,
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 16,
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(Icons.attach_file, color: isDarkMode ? Colors.grey[400] : Colors.grey),
                          onPressed: () {
                            // Handle file attachment
                          },
                        ),
                      ),
                      style: GoogleFonts.inter(
                        color: isDarkMode ? Colors.white : Colors.black,
                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                ),
                
                const SizedBox(width: 12),
                
                // Send button
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.white),
                    onPressed: _sendMessage,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
  }

  Widget _buildMessageBubble(models.ChatMessage message) {
    final isDarkMode = ref.watch(themeProvider);
    final userProfile = ref.watch(userProfileProvider);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!message.isUser) ...[
            // AI avatar
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isDarkMode ? Colors.grey[700] : const Color(0xFF424242),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.smart_toy,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
          ],
          
          Expanded(
            child: Column(
              crossAxisAlignment: message.isUser 
                ? CrossAxisAlignment.end 
                : CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: message.isUser 
                      ? AppTheme.primaryColor
                      : (isDarkMode ? AppTheme.darkSurfaceColor : const Color(0xFFF5F5F5)),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    message.content,
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      color: message.isUser 
                        ? Colors.white 
                        : (isDarkMode ? Colors.white : Colors.black),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          if (message.isUser) ...[
            const SizedBox(width: 12),
            // User avatar with profile picture
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isDarkMode ? AppTheme.darkSurfaceColor : const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isDarkMode ? Colors.grey[600]! : Colors.grey[300]!,
                  width: 1,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(19),
                child: userProfile?.profileImagePath != null
                  ? kIsWeb
                      ? Image.network(
                          userProfile!.profileImagePath!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return _buildDefaultUserAvatar(isDarkMode);
                          },
                        )
                      : Image.file(
                          File(userProfile!.profileImagePath!),
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return _buildDefaultUserAvatar(isDarkMode);
                          },
                        )
                  : Image.network(
                      'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=40&h=40&fit=crop&crop=face',
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return _buildDefaultUserAvatar(isDarkMode);
                      },
                    ),
              ),
            ),
          ],
        ],
      ),
    );
  }
  
  Widget _buildDefaultUserAvatar(bool isDarkMode) {
    return Container(
      color: isDarkMode ? AppTheme.darkBackgroundColor : const Color(0xFFE0E0E0),
      child: Icon(
        Icons.person,
        color: isDarkMode ? Colors.grey[400] : Colors.grey,
        size: 20,
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required bool isDarkMode,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: isDarkMode ? AppTheme.darkSurfaceColor : const Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: isDarkMode ? Colors.white : Colors.black, size: 20),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: isDarkMode ? Colors.white : Colors.black,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
  });
}
