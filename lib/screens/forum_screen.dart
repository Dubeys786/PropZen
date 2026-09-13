import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../models/forum_model.dart';
import '../services/forum_service.dart';
import '../theme/app_theme.dart';
import '../routes/app_routes.dart';

class ForumScreen extends StatefulWidget {
  const ForumScreen({super.key});

  @override
  State<ForumScreen> createState() => _ForumScreenState();
}

class _ForumScreenState extends State<ForumScreen> {
  final ForumService _forumService = ForumService.instance;
  ForumSection? _selectedSection;
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openCreatePostDialog() {
    ForumSection section = _selectedSection ?? ForumSection.generalDiscussion;
    final titleCtrl = TextEditingController();
    final contentCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.cardWhite,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.only(left: 20, right: 20, top: 20, bottom: MediaQuery.of(ctx).viewInsets.bottom + 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Start a Community Discussion', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                  IconButton(icon: const Icon(LucideIcons.x, size: 20), onPressed: () => Navigator.pop(ctx)),
                ],
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<ForumSection>(
                value: section,
                decoration: InputDecoration(
                  labelText: 'Discussion Category',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
                items: ForumSection.values
                    .map((s) => DropdownMenuItem(value: s, child: Text(s.title, style: const TextStyle(fontSize: 13))))
                    .toList(),
                onChanged: (v) {
                  if (v != null) setModalState(() => section = v);
                },
              ),
              const SizedBox(height: 10),
              TextField(
                controller: titleCtrl,
                decoration: InputDecoration(
                  labelText: 'Discussion Title',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: contentCtrl,
                maxLines: 4,
                decoration: InputDecoration(
                  labelText: 'Describe your question or insight...',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryViolet,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(46),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                icon: const Icon(LucideIcons.plusCircle, size: 16),
                label: const Text('Publish Discussion Post', style: TextStyle(fontWeight: FontWeight.bold)),
                onPressed: () {
                  if (titleCtrl.text.trim().isEmpty || contentCtrl.text.trim().isEmpty) return;
                  _forumService.createPost(
                    section: section,
                    title: titleCtrl.text.trim(),
                    content: contentCtrl.text.trim(),
                    authorId: 'usr_current_user',
                    authorName: 'Community Contributor',
                    authorRole: 'USER',
                  );
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Discussion published to PropZen Community!')),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openCommentsDialog(ForumPostModel post) {
    final commentCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.cardWhite,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setCommentsState) {
          final comments = _forumService.getComments(post.postId);

          return Container(
            height: MediaQuery.of(ctx).size.height * 0.75,
            padding: EdgeInsets.only(left: 20, right: 20, top: 16, bottom: MediaQuery.of(ctx).viewInsets.bottom + 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(post.title, style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textPrimary), maxLines: 2, overflow: TextOverflow.ellipsis),
                    ),
                    IconButton(icon: const Icon(LucideIcons.x, size: 20), onPressed: () => Navigator.pop(ctx)),
                  ],
                ),
                const Divider(height: 16),
                Expanded(
                  child: comments.isEmpty
                      ? Center(child: Text('No comments yet. Be the first to share an insight!', style: GoogleFonts.inter(fontSize: 13, color: AppTheme.textMuted)))
                      : ListView.builder(
                          itemCount: comments.length,
                          itemBuilder: (c, idx) {
                            final com = comments[idx];
                            return Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppTheme.surfaceSubtle,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(com.authorName, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                                      Text('${com.createdAt.hour}:${com.createdAt.minute.toString().padLeft(2, '0')}', style: GoogleFonts.inter(fontSize: 10, color: AppTheme.textMuted)),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(com.content, style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textSecondary)),
                                ],
                              ),
                            );
                          },
                        ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: commentCtrl,
                        decoration: InputDecoration(
                          hintText: 'Write a helpful response...',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(LucideIcons.send, color: AppTheme.primaryViolet),
                      onPressed: () {
                        if (commentCtrl.text.trim().isEmpty) return;
                        _forumService.addComment(post.postId, 'usr_current_user', 'You', commentCtrl.text.trim());
                        commentCtrl.clear();
                        setCommentsState(() {});
                      },
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _forumService,
      builder: (context, _) {
        final posts = _forumService.getPostsForSection(
          _selectedSection,
          query: _searchController.text,
        );

        return Scaffold(
          backgroundColor: AppTheme.pageBackground,
          appBar: AppBar(
            backgroundColor: AppTheme.cardWhite,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(LucideIcons.arrowLeft, color: AppTheme.textPrimary),
              onPressed: () => Navigator.of(context).pop(),
            ),
            title: Text(
              'Buyer–Seller Forum & Insights',
              style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
            ),
            actions: [
              IconButton(
                icon: const Icon(LucideIcons.messageCircle, color: AppTheme.primaryViolet),
                tooltip: 'Direct Messages',
                onPressed: () => Navigator.of(context).pushNamed(AppRoutes.chat),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            backgroundColor: AppTheme.primaryViolet,
            foregroundColor: Colors.white,
            icon: const Icon(LucideIcons.edit3, size: 18),
            label: const Text('Start Discussion', style: TextStyle(fontWeight: FontWeight.bold)),
            onPressed: _openCreatePostDialog,
          ),
          body: Column(
            children: [
              // Search & Filter
              Container(
                color: AppTheme.cardWhite,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: TextField(
                  controller: _searchController,
                  onChanged: (v) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: 'Search forum topics, legal queries, localities...',
                    prefixIcon: const Icon(LucideIcons.search, size: 18, color: AppTheme.textMuted),
                    filled: true,
                    fillColor: AppTheme.surfaceSubtle,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),

              // Forum Sections Strip
              SizedBox(
                height: 48,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: ChoiceChip(
                        label: const Text('All Topics'),
                        selected: _selectedSection == null,
                        selectedColor: AppTheme.primaryViolet,
                        labelStyle: TextStyle(
                          color: _selectedSection == null ? Colors.white : AppTheme.textPrimary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                        onSelected: (_) => setState(() => _selectedSection = null),
                      ),
                    ),
                    ...ForumSection.values.map((sec) {
                      final isSel = _selectedSection == sec;
                      return Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: ChoiceChip(
                          label: Text(sec.title),
                          selected: isSel,
                          selectedColor: AppTheme.primaryViolet,
                          labelStyle: TextStyle(
                            color: isSel ? Colors.white : AppTheme.textPrimary,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                          onSelected: (_) => setState(() => _selectedSection = sec),
                        ),
                      );
                    }),
                  ],
                ),
              ),

              const SizedBox(height: 8),

              // Posts List
              Expanded(
                child: posts.isEmpty
                    ? Center(
                        child: Text('No active discussions found in this section.', style: GoogleFonts.inter(fontSize: 13, color: AppTheme.textMuted)),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        itemCount: posts.length,
                        itemBuilder: (context, idx) {
                          final p = posts[idx];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppTheme.cardWhite,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: AppTheme.borderLight),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: AppTheme.primaryViolet.withOpacity(0.08),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(p.section.title, style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.primaryViolet)),
                                    ),
                                    if (p.isPinned)
                                      Row(
                                        children: [
                                          const Icon(LucideIcons.pin, size: 12, color: Color(0xFFD97706)),
                                          const SizedBox(width: 4),
                                          Text('PINNED', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: const Color(0xFFD97706))),
                                        ],
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(p.title, style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                                const SizedBox(height: 6),
                                Text(p.content, style: GoogleFonts.inter(fontSize: 13, color: AppTheme.textSecondary, height: 1.4)),
                                const SizedBox(height: 10),

                                // Tags
                                if (p.tags.isNotEmpty)
                                  Wrap(
                                    spacing: 6,
                                    runSpacing: 4,
                                    children: p.tags.map((t) => Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: AppTheme.surfaceSubtle,
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text('#$t', style: GoogleFonts.inter(fontSize: 10, color: AppTheme.textMuted)),
                                        )).toList(),
                                  ),

                                const SizedBox(height: 12),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('By ${p.authorName} (${p.authorRole})', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.textMuted)),
                                    Row(
                                      children: [
                                        IconButton(
                                          icon: Row(
                                            children: [
                                              const Icon(LucideIcons.thumbsUp, size: 14, color: AppTheme.primaryViolet),
                                              const SizedBox(width: 4),
                                              Text('${p.upvotes}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.primaryViolet)),
                                            ],
                                          ),
                                          onPressed: () => _forumService.upvotePost(p.postId),
                                        ),
                                        TextButton.icon(
                                          icon: const Icon(LucideIcons.messageSquare, size: 14),
                                          label: Text('${p.commentCount} Comments', style: const TextStyle(fontSize: 12)),
                                          onPressed: () => _openCommentsDialog(p),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}
