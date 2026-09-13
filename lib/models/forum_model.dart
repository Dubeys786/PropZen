import 'package:flutter/foundation.dart';

enum ForumSection {
  generalDiscussion,
  propertyQuestions,
  buyerDiscussions,
  sellerDiscussions,
  construction,
  homeLoans,
  legalDocumentation,
  localityDiscussion,
  investmentDiscussion,
  nriPropertyDiscussion;

  String get title {
    switch (this) {
      case ForumSection.generalDiscussion:
        return 'General Property Discussion';
      case ForumSection.propertyQuestions:
        return 'Property Questions & Answers';
      case ForumSection.buyerDiscussions:
        return 'Buyer Experiences & Advice';
      case ForumSection.sellerDiscussions:
        return 'Seller & Owner Insights';
      case ForumSection.construction:
        return 'Construction & Renovation';
      case ForumSection.homeLoans:
        return 'Home Loans & Mortgages';
      case ForumSection.legalDocumentation:
        return 'Legal & Registry Documentation';
      case ForumSection.localityDiscussion:
        return 'Locality & Infrastructure';
      case ForumSection.investmentDiscussion:
        return 'Real Estate Investments';
      case ForumSection.nriPropertyDiscussion:
        return 'NRI Property Hub & Remote Buying';
    }
  }

  static ForumSection fromString(String val) {
    final lower = val.trim().toLowerCase();
    if (lower.contains('loan')) return ForumSection.homeLoans;
    if (lower.contains('legal') || lower.contains('doc')) return ForumSection.legalDocumentation;
    if (lower.contains('construct')) return ForumSection.construction;
    if (lower.contains('buyer')) return ForumSection.buyerDiscussions;
    if (lower.contains('seller')) return ForumSection.sellerDiscussions;
    if (lower.contains('nri')) return ForumSection.nriPropertyDiscussion;
    if (lower.contains('invest')) return ForumSection.investmentDiscussion;
    if (lower.contains('local')) return ForumSection.localityDiscussion;
    if (lower.contains('quest')) return ForumSection.propertyQuestions;
    return ForumSection.generalDiscussion;
  }
}

class ForumPostModel {
  final String postId;
  final ForumSection section;
  final String title;
  final String content;
  final String authorId;
  final String authorName;
  final String authorRole; // USER, DEALER, LAWYER, ADMIN
  final List<String> tags;
  final int upvotes;
  final int commentCount;
  final bool isPinned;
  final String status; // ACTIVE, REPORTED, REMOVED
  final DateTime createdAt;
  final DateTime updatedAt;

  const ForumPostModel({
    required this.postId,
    required this.section,
    required this.title,
    required this.content,
    required this.authorId,
    required this.authorName,
    this.authorRole = 'USER',
    this.tags = const [],
    this.upvotes = 0,
    this.commentCount = 0,
    this.isPinned = false,
    this.status = 'ACTIVE',
    required this.createdAt,
    required this.updatedAt,
  });

  factory ForumPostModel.fromMap(Map<String, dynamic> map, String id) {
    return ForumPostModel(
      postId: id,
      section: ForumSection.fromString(map['section']?.toString() ?? 'generalDiscussion'),
      title: map['title']?.toString() ?? '',
      content: map['content']?.toString() ?? '',
      authorId: map['authorId']?.toString() ?? '',
      authorName: map['authorName']?.toString() ?? 'PropZen Community Member',
      authorRole: map['authorRole']?.toString() ?? 'USER',
      tags: map['tags'] is List ? List<String>.from(map['tags']) : [],
      upvotes: int.tryParse(map['upvotes']?.toString() ?? '0') ?? 0,
      commentCount: int.tryParse(map['commentCount']?.toString() ?? '0') ?? 0,
      isPinned: map['isPinned'] == true,
      status: map['status']?.toString() ?? 'ACTIVE',
      createdAt: DateTime.tryParse(map['createdAt']?.toString() ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(map['updatedAt']?.toString() ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
        'postId': postId,
        'section': section.name,
        'title': title,
        'content': content,
        'authorId': authorId,
        'authorName': authorName,
        'authorRole': authorRole,
        'tags': tags,
        'upvotes': upvotes,
        'commentCount': commentCount,
        'isPinned': isPinned,
        'status': status,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };
}

class ForumCommentModel {
  final String commentId;
  final String postId;
  final String authorId;
  final String authorName;
  final String content;
  final int upvotes;
  final String status;
  final DateTime createdAt;

  const ForumCommentModel({
    required this.commentId,
    required this.postId,
    required this.authorId,
    required this.authorName,
    required this.content,
    this.upvotes = 0,
    this.status = 'ACTIVE',
    required this.createdAt,
  });

  factory ForumCommentModel.fromMap(Map<String, dynamic> map, String id) {
    return ForumCommentModel(
      commentId: id,
      postId: map['postId']?.toString() ?? '',
      authorId: map['authorId']?.toString() ?? '',
      authorName: map['authorName']?.toString() ?? 'Community Member',
      content: map['content']?.toString() ?? '',
      upvotes: int.tryParse(map['upvotes']?.toString() ?? '0') ?? 0,
      status: map['status']?.toString() ?? 'ACTIVE',
      createdAt: DateTime.tryParse(map['createdAt']?.toString() ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
        'commentId': commentId,
        'postId': postId,
        'authorId': authorId,
        'authorName': authorName,
        'content': content,
        'upvotes': upvotes,
        'status': status,
        'createdAt': createdAt.toIso8601String(),
      };
}

class ConversationModel {
  final String conversationId;
  final String? propertyId;
  final String propertyTitle;
  final List<String> participants;
  final Map<String, String> participantNames;
  final String lastMessage;
  final DateTime lastMessageAt;
  final String status;

  const ConversationModel({
    required this.conversationId,
    this.propertyId,
    required this.propertyTitle,
    required this.participants,
    required this.participantNames,
    required this.lastMessage,
    required this.lastMessageAt,
    this.status = 'ACTIVE',
  });
}

class ChatMessageModel {
  final String messageId;
  final String conversationId;
  final String senderId;
  final String senderName;
  final String message;
  final DateTime createdAt;

  const ChatMessageModel({
    required this.messageId,
    required this.conversationId,
    required this.senderId,
    required this.senderName,
    required this.message,
    required this.createdAt,
  });
}
