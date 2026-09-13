import 'package:flutter/foundation.dart';
import '../models/forum_model.dart';

class ChatService extends ChangeNotifier {
  ChatService._internal() {
    _initDemoConversations();
  }
  static final ChatService instance = ChatService._internal();
  factory ChatService() => instance;

  final List<ConversationModel> _conversations = [];
  List<ConversationModel> get conversations => List.unmodifiable(_conversations);

  final Map<String, List<ChatMessageModel>> _messages = {};

  void _initDemoConversations() {
    final now = DateTime.now();
    _conversations.addAll([
      ConversationModel(
        conversationId: 'conv_01',
        propertyId: 'prop_mahagun',
        propertyTitle: 'Mahagun Manorialle Luxury Suites',
        participants: ['usr_buyer_demo', 'usr_dealer_01'],
        participantNames: {
          'usr_buyer_demo': 'You',
          'usr_dealer_01': 'Rajesh Sharma (Verified Dealer)',
        },
        lastMessage: 'I can arrange a site visit this Saturday at 11:30 AM.',
        lastMessageAt: now.subtract(const Duration(minutes: 25)),
      ),
    ]);

    _messages['conv_01'] = [
      ChatMessageModel(
        messageId: 'msg_01',
        conversationId: 'conv_01',
        senderId: 'usr_buyer_demo',
        senderName: 'You',
        message: 'Hello, is the 3 BHK corner unit on the 14th floor still available?',
        createdAt: now.subtract(const Duration(minutes: 40)),
      ),
      ChatMessageModel(
        messageId: 'msg_02',
        conversationId: 'conv_01',
        senderId: 'usr_dealer_01',
        senderName: 'Rajesh Sharma (Verified Dealer)',
        message: 'Yes, it is available with park facing balcony and 2 dedicated basement car parks.',
        createdAt: now.subtract(const Duration(minutes: 32)),
      ),
      ChatMessageModel(
        messageId: 'msg_03',
        conversationId: 'conv_01',
        senderId: 'usr_dealer_01',
        senderName: 'Rajesh Sharma (Verified Dealer)',
        message: 'I can arrange a site visit this Saturday at 11:30 AM.',
        createdAt: now.subtract(const Duration(minutes: 25)),
      ),
    ];
  }

  List<ChatMessageModel> getMessagesForConversation(String conversationId, String currentUserId) {
    final conv = _conversations.firstWhere((c) => c.conversationId == conversationId, orElse: () => throw Exception('Conversation not found'));
    if (!conv.participants.contains(currentUserId)) {
      throw Exception('Access Denied: You are not a participant in this conversation.');
    }
    return _messages[conversationId] ?? [];
  }

  void sendMessage({
    required String conversationId,
    required String senderId,
    required String senderName,
    required String text,
  }) {
    final msg = ChatMessageModel(
      messageId: 'msg_${DateTime.now().millisecondsSinceEpoch}',
      conversationId: conversationId,
      senderId: senderId,
      senderName: senderName,
      message: text,
      createdAt: DateTime.now(),
    );

    _messages.putIfAbsent(conversationId, () => []).add(msg);

    final idx = _conversations.indexWhere((c) => c.conversationId == conversationId);
    if (idx != -1) {
      final old = _conversations[idx];
      _conversations[idx] = ConversationModel(
        conversationId: old.conversationId,
        propertyId: old.propertyId,
        propertyTitle: old.propertyTitle,
        participants: old.participants,
        participantNames: old.participantNames,
        lastMessage: text,
        lastMessageAt: DateTime.now(),
      );
    }
    notifyListeners();
  }
}
