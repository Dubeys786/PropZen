import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../models/forum_model.dart';
import '../services/chat_service.dart';
import '../theme/app_theme.dart';

class ChatScreen extends StatefulWidget {
  final String? conversationId;
  final String currentUserId;

  const ChatScreen({
    super.key,
    this.conversationId,
    this.currentUserId = 'usr_buyer_demo',
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final ChatService _chatService = ChatService.instance;
  final TextEditingController _msgController = TextEditingController();
  late String _activeConvId;

  @override
  void initState() {
    super.initState();
    _activeConvId = widget.conversationId ?? (_chatService.conversations.isNotEmpty ? _chatService.conversations.first.conversationId : '');
  }

  @override
  void dispose() {
    _msgController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _chatService,
      builder: (context, _) {
        final convs = _chatService.conversations;
        if (convs.isEmpty) {
          return Scaffold(
            appBar: AppBar(title: const Text('Direct Property Messages')),
            body: const Center(child: Text('No active conversations yet.')),
          );
        }

        final activeConv = convs.firstWhere((c) => c.conversationId == _activeConvId, orElse: () => convs.first);
        final messages = _chatService.getMessagesForConversation(activeConv.conversationId, widget.currentUserId);

        return Scaffold(
          backgroundColor: AppTheme.pageBackground,
          appBar: AppBar(
            backgroundColor: AppTheme.cardWhite,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(LucideIcons.arrowLeft, color: AppTheme.textPrimary),
              onPressed: () => Navigator.of(context).pop(),
            ),
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  activeConv.propertyTitle,
                  style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  'Verified Participant Chat • Direct Dealer Communication',
                  style: GoogleFonts.inter(fontSize: 11, color: AppTheme.emeraldSuccess, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          body: Column(
            children: [
              // Security banner
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                color: AppTheme.primaryViolet.withOpacity(0.06),
                child: Row(
                  children: [
                    const Icon(LucideIcons.shieldCheck, size: 14, color: AppTheme.primaryViolet),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'End-to-end participant verified. Financial details & passwords should never be shared.',
                        style: GoogleFonts.inter(fontSize: 10, color: AppTheme.textSecondary),
                      ),
                    ),
                  ],
                ),
              ),

              // Chat messages
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (context, idx) {
                    final msg = messages[idx];
                    final isMe = msg.senderId == widget.currentUserId;

                    return Align(
                      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                        decoration: BoxDecoration(
                          color: isMe ? AppTheme.primaryViolet : AppTheme.cardWhite,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: isMe ? Colors.transparent : AppTheme.borderLight),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.03),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (!isMe)
                              Text(
                                msg.senderName,
                                style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.primaryViolet),
                              ),
                            const SizedBox(height: 2),
                            Text(
                              msg.message,
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                color: isMe ? Colors.white : AppTheme.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Align(
                              alignment: Alignment.bottomRight,
                              child: Text(
                                '${msg.createdAt.hour}:${msg.createdAt.minute.toString().padLeft(2, '0')}',
                                style: GoogleFonts.inter(
                                  fontSize: 9,
                                  color: isMe ? Colors.white.withOpacity(0.7) : AppTheme.textMuted,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

              // Chat Input
              Container(
                color: AppTheme.cardWhite,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: SafeArea(
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _msgController,
                          decoration: InputDecoration(
                            hintText: 'Type your message to the verified dealer...',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                            filled: true,
                            fillColor: AppTheme.surfaceSubtle,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        style: IconButton.styleFrom(backgroundColor: AppTheme.primaryViolet),
                        icon: const Icon(LucideIcons.send, size: 18, color: Colors.white),
                        onPressed: () {
                          if (_msgController.text.trim().isEmpty) return;
                          _chatService.sendMessage(
                            conversationId: activeConv.conversationId,
                            senderId: widget.currentUserId,
                            senderName: 'You',
                            text: _msgController.text.trim(),
                          );
                          _msgController.clear();
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
