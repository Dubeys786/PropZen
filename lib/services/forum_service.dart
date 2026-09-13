import 'package:flutter/foundation.dart';
import '../models/forum_model.dart';

class ForumService extends ChangeNotifier {
  ForumService._internal() {
    _initDefaultPosts();
  }
  static final ForumService instance = ForumService._internal();
  factory ForumService() => instance;

  final List<ForumPostModel> _posts = [];
  List<ForumPostModel> get posts => List.unmodifiable(_posts);

  final Map<String, List<ForumCommentModel>> _comments = {};

  void _initDefaultPosts() {
    final now = DateTime.now();
    _posts.addAll([
      ForumPostModel(
        postId: 'post_01',
        section: ForumSection.localityDiscussion,
        title: 'Sector 150 low density green zoning vs Sector 137 IT hub: 5-year outlook',
        content: 'Evaluating between low-density eco-city developments along Sector 150 vs existing mature commercial hubs near Advant Navis in Sector 137. Key considerations include Aqua line frequency, air quality buffers, and capital appreciation.',
        authorId: 'usr_investor_01',
        authorName: 'Vikram Mehta (NCR Investor)',
        authorRole: 'USER',
        tags: ['Sector 150', 'Sector 137', 'Capital Growth', 'Eco City'],
        upvotes: 28,
        commentCount: 9,
        isPinned: true,
        createdAt: now.subtract(const Duration(hours: 14)),
        updatedAt: now.subtract(const Duration(hours: 14)),
      ),
      ForumPostModel(
        postId: 'post_02',
        section: ForumSection.legalDocumentation,
        title: 'Checklist for RERA title search and encumbrance certificate verification in UP',
        content: 'Before executing agreement to sale, ensure UP RERA sanctioned map matches floor layout plan. Advocate guidance on obtaining non-encumbrance certificate (Form 15/16) from Sub-Registrar Office.',
        authorId: 'usr_lawyer_sharma',
        authorName: 'Advocate Rajesh Sharma',
        authorRole: 'LAWYER',
        tags: ['UP RERA', 'Title Search', 'Legal Checklist', 'Encumbrance'],
        upvotes: 45,
        commentCount: 14,
        isPinned: true,
        createdAt: now.subtract(const Duration(days: 1)),
        updatedAt: now.subtract(const Duration(days: 1)),
      ),
      ForumPostModel(
        postId: 'post_03',
        section: ForumSection.homeLoans,
        title: 'Repo rate linkage vs Fixed home loan rates in 2026: What buyers should know',
        content: 'Most public and private sector banks offer External Benchmark Linked Lending Rate (EBLR). Keep an eye on the spread markup and foreclosure fee clauses when negotiating loan sanctions.',
        authorId: 'usr_advisor_02',
        authorName: 'Neha Kapoor (Financial Planner)',
        authorRole: 'USER',
        tags: ['Home Loans', 'EBLR', 'Interest Rates', 'Banking'],
        upvotes: 19,
        commentCount: 6,
        isPinned: false,
        createdAt: now.subtract(const Duration(days: 2)),
        updatedAt: now.subtract(const Duration(days: 2)),
      ),
    ]);

    _comments['post_01'] = [
      ForumCommentModel(
        commentId: 'comm_01',
        postId: 'post_01',
        authorId: 'usr_dealer_01',
        authorName: 'Amit Verma (Verified Dealer)',
        content: 'Sector 150 provides 70% open green space mandate which ensures higher resale value and healthier living standard for families.',
        upvotes: 8,
        createdAt: now.subtract(const Duration(hours: 8)),
      ),
    ];
  }

  List<ForumPostModel> getPostsForSection(ForumSection? section, {String? query}) {
    return _posts.where((p) {
      if (p.status == 'REMOVED') return false;
      if (section != null && p.section != section) return false;
      if (query != null && query.trim().isNotEmpty) {
        final q = query.toLowerCase().trim();
        final match = p.title.toLowerCase().contains(q) ||
            p.content.toLowerCase().contains(q) ||
            p.tags.any((t) => t.toLowerCase().contains(q));
        if (!match) return false;
      }
      return true;
    }).toList();
  }

  List<ForumCommentModel> getComments(String postId) {
    return _comments[postId] ?? [];
  }

  void createPost({
    required ForumSection section,
    required String title,
    required String content,
    required String authorId,
    required String authorName,
    String authorRole = 'USER',
    List<String> tags = const [],
  }) {
    final newPost = ForumPostModel(
      postId: 'post_${DateTime.now().millisecondsSinceEpoch}',
      section: section,
      title: title,
      content: content,
      authorId: authorId,
      authorName: authorName,
      authorRole: authorRole,
      tags: tags,
      upvotes: 1,
      commentCount: 0,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    _posts.insert(0, newPost);
    notifyListeners();
  }

  void addComment(String postId, String authorId, String authorName, String content) {
    final comment = ForumCommentModel(
      commentId: 'comm_${DateTime.now().millisecondsSinceEpoch}',
      postId: postId,
      authorId: authorId,
      authorName: authorName,
      content: content,
      createdAt: DateTime.now(),
    );
    _comments.putIfAbsent(postId, () => []).add(comment);

    final idx = _posts.indexWhere((p) => p.postId == postId);
    if (idx != -1) {
      final old = _posts[idx];
      _posts[idx] = ForumPostModel(
        postId: old.postId,
        section: old.section,
        title: old.title,
        content: old.content,
        authorId: old.authorId,
        authorName: old.authorName,
        authorRole: old.authorRole,
        tags: old.tags,
        upvotes: old.upvotes,
        commentCount: old.commentCount + 1,
        isPinned: old.isPinned,
        createdAt: old.createdAt,
        updatedAt: DateTime.now(),
      );
    }
    notifyListeners();
  }

  void upvotePost(String postId) {
    final idx = _posts.indexWhere((p) => p.postId == postId);
    if (idx != -1) {
      final old = _posts[idx];
      _posts[idx] = ForumPostModel(
        postId: old.postId,
        section: old.section,
        title: old.title,
        content: old.content,
        authorId: old.authorId,
        authorName: old.authorName,
        authorRole: old.authorRole,
        tags: old.tags,
        upvotes: old.upvotes + 1,
        commentCount: old.commentCount,
        isPinned: old.isPinned,
        createdAt: old.createdAt,
        updatedAt: old.updatedAt,
      );
      notifyListeners();
    }
  }
}
