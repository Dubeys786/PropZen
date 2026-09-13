import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../models/property.dart';
import '../models/nri_subscription_model.dart';
import '../services/nri_subscription_service.dart';
import '../theme/app_theme.dart';

/// NRI Family Decision Mode & Voting Dialog
class NriFamilyDecisionDialog extends StatefulWidget {
  final Property property;

  const NriFamilyDecisionDialog({
    super.key,
    required this.property,
  });

  static Future<void> show(BuildContext context, {required Property property}) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => NriFamilyDecisionDialog(property: property),
    );
  }

  @override
  State<NriFamilyDecisionDialog> createState() => _NriFamilyDecisionDialogState();
}

class _NriFamilyDecisionDialogState extends State<NriFamilyDecisionDialog> {
  final NriSubscriptionService _subService = NriSubscriptionService.instance;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _commentController = TextEditingController();
  String _selectedRelation = 'Spouse';
  String _selectedVote = 'like';
  double _rating = 4.5;
  bool _isSubmitting = false;

  final List<String> _relations = const ['Spouse', 'Parent', 'Sibling', 'Child', 'Financial Advisor'];

  @override
  void dispose() {
    _nameController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _subService,
      builder: (context, _) {
        final reviews = _subService.getFamilyReviewsForProperty(widget.property.id);
        final summary = _subService.getFamilySummaryForProperty(widget.property.id);

        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
          insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          backgroundColor: Colors.white,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 620, maxHeight: 760),
            child: Column(
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: const BoxDecoration(
                    color: Color(0xFF0F172A),
                    borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryViolet.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(LucideIcons.users, color: Colors.white, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Family Decision Mode',
                              style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                            Text(
                              widget.property.title,
                              style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFFCBD5E1)),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(LucideIcons.x, color: Colors.white70, size: 18),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                ),

                // Body
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Summary Banner
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF0F172A), Color(0xFF1E1B4B)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'FAMILY PREFERENCE SUMMARY',
                                    style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: const Color(0xFFCBD5E1), letterSpacing: 0.5),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF10B981),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      '${summary['consensus']}',
                                      style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  _buildSummaryItem('Total Votes', '${summary['totalVotes']}', Colors.white),
                                  _buildSummaryItem('Likes', '👍 ${summary['likes']}', Colors.greenAccent),
                                  _buildSummaryItem('Dislikes', '👎 ${summary['dislikes']}', Colors.orangeAccent),
                                  _buildSummaryItem('Avg Rating', '★ ${(summary['avgRating'] as num).toStringAsFixed(1)}', Colors.cyanAccent),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Reviews Feed
                        Text('Family Feedback (${reviews.length})', style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                        const SizedBox(height: 10),

                        if (reviews.isEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 20),
                            child: Center(child: Text('No family feedback submitted yet.', style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textMuted))),
                          )
                        else
                          Column(
                            children: reviews.map((r) => _buildReviewTile(r)).toList(),
                          ),

                        const Divider(height: 28, color: AppTheme.borderLight),

                        // Add Review Form
                        Text('Submit Family Member Review', style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                        const SizedBox(height: 10),

                        _buildField(_nameController, 'Family Member Name (e.g. Rahul Sharma)', LucideIcons.user),
                        const SizedBox(height: 8),

                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceSubtle,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppTheme.borderLight),
                          ),
                          child: DropdownButton<String>(
                            value: _selectedRelation,
                            isExpanded: true,
                            underline: const SizedBox.shrink(),
                            style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textPrimary),
                            items: _relations.map((rel) => DropdownMenuItem(value: rel, child: Text('Relation: $rel'))).toList(),
                            onChanged: (val) => setState(() => _selectedRelation = val!),
                          ),
                        ),
                        const SizedBox(height: 10),

                        Row(
                          children: [
                            Expanded(
                              child: InkWell(
                                onTap: () => setState(() => _selectedVote = 'like'),
                                borderRadius: BorderRadius.circular(10),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                  decoration: BoxDecoration(
                                    color: _selectedVote == 'like' ? const Color(0xFFDCFCE7) : const Color(0xFFF1F5F9),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: _selectedVote == 'like' ? const Color(0xFF16A34A) : Colors.transparent),
                                  ),
                                  child: Center(
                                    child: Text('👍 Like Property', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF16A34A))),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: InkWell(
                                onTap: () => setState(() => _selectedVote = 'dislike'),
                                borderRadius: BorderRadius.circular(10),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                  decoration: BoxDecoration(
                                    color: _selectedVote == 'dislike' ? const Color(0xFFFEE2E2) : const Color(0xFFF1F5F9),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: _selectedVote == 'dislike' ? const Color(0xFFDC2626) : Colors.transparent),
                                  ),
                                  child: Center(
                                    child: Text('👎 Dislike', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFFDC2626))),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),

                        _buildField(_commentController, 'Feedback / Consideration (e.g. good location)', LucideIcons.messageSquare, maxLines: 2),
                        const SizedBox(height: 12),

                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _submitReview,
                            icon: const Icon(LucideIcons.check, size: 15, color: Colors.white),
                            label: Text('Save Family Vote', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.bold)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryViolet,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Footer CTA: Share link
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: const BoxDecoration(
                    color: Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.vertical(bottom: Radius.circular(22)),
                  ),
                  child: Row(
                    children: [
                      const Icon(LucideIcons.share2, size: 16, color: AppTheme.primaryViolet),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Invite family with private link: propzen.ai/family/vote/${widget.property.id}',
                          style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textSecondary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Private Family Invite Link copied to clipboard!')),
                          );
                        },
                        child: Text('Copy', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.primaryViolet)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSummaryItem(String label, String val, Color valColor) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: GoogleFonts.inter(fontSize: 10, color: const Color(0xFF94A3B8))),
          const SizedBox(height: 2),
          Text(val, style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.bold, color: valColor)),
        ],
      ),
    );
  }

  Widget _buildReviewTile(FamilyDecisionReview rev) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: AppTheme.primaryViolet.withOpacity(0.12),
            child: Text(rev.memberName[0], style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.primaryViolet)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('${rev.memberName} (${rev.relation})', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                    Text(rev.vote == 'like' ? '👍 Liked' : '👎 Disliked', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: rev.vote == 'like' ? const Color(0xFF16A34A) : const Color(0xFFDC2626))),
                  ],
                ),
                const SizedBox(height: 4),
                Text(rev.comment, style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textSecondary, height: 1.35)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildField(TextEditingController controller, String hint, IconData icon, {int maxLines = 1}) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceSubtle,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textPrimary),
        decoration: InputDecoration(
          hintText: hint,
          prefixIcon: Icon(icon, size: 15, color: AppTheme.primaryViolet),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        ),
      ),
    );
  }

  void _submitReview() async {
    if (_nameController.text.trim().isEmpty || _commentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter name and feedback comment.')),
      );
      return;
    }

    await _subService.submitFamilyReview(
      propertyId: widget.property.id,
      memberName: _nameController.text.trim(),
      relation: _selectedRelation,
      vote: _selectedVote,
      rating: _rating,
      comment: _commentController.text.trim(),
    );

    _nameController.clear();
    _commentController.clear();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Family vote recorded successfully!'), backgroundColor: Color(0xFF16A34A)),
      );
    }
  }
}
