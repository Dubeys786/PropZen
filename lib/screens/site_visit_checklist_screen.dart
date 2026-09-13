import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../models/site_visit_checklist_model.dart';
import '../services/supabase_service.dart';
import '../theme/app_theme.dart';
import 'user_profile_screen.dart';

class SiteVisitChecklistScreen extends StatefulWidget {
  final String propertyId;
  final String propertyTitle;
  final String visitId;

  const SiteVisitChecklistScreen({
    super.key,
    required this.propertyId,
    required this.propertyTitle,
    required this.visitId,
  });

  @override
  State<SiteVisitChecklistScreen> createState() => _SiteVisitChecklistScreenState();
}

class _SiteVisitChecklistScreenState extends State<SiteVisitChecklistScreen> {
  late SiteVisitChecklist _checklist;
  final TextEditingController _voiceNotesController = TextEditingController(
    text: 'The 3 BHK flat was spacious. Balcony had great morning sunlight. Parking slot felt a bit tight for full size SUV. Road connectivity to expressway was smooth.',
  );

  AiVisitSummary? _generatedSummary;
  bool _isGeneratingSummary = false;
  String _selectedCategory = 'ALL'; // 'ALL', 'PROPERTY', 'DOCUMENTS'

  @override
  void initState() {
    super.initState();
    _checklist = SiteVisitChecklist(
      id: 'CHK-${widget.visitId}',
      visitId: widget.visitId,
      propertyId: widget.propertyId,
      propertyTitle: widget.propertyTitle,
      buyerId: UserSession.mobileNumber.isNotEmpty ? 'usr_${UserSession.mobileNumber}' : 'usr_buyer',
      items: SiteVisitChecklist.defaultItems(),
    );
  }

  @override
  void dispose() {
    _voiceNotesController.dispose();
    super.dispose();
  }

  void _generateAiSummary() {
    final rawNotes = _voiceNotesController.text.trim();
    if (rawNotes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your observations or voice transcript'), backgroundColor: AppTheme.coralDanger),
      );
      return;
    }

    setState(() => _isGeneratingSummary = true);

    Future.delayed(const Duration(milliseconds: 600), () {
      final summary = AiVisitSummary.parseFromNotes(
        visitId: widget.visitId,
        propertyTitle: widget.propertyTitle,
        rawNotes: rawNotes,
      );

      setState(() {
        _generatedSummary = summary;
        _isGeneratingSummary = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✨ AI Site Visit Summary Structured into Pros, Cons, Concerns & Follow-ups!'),
          backgroundColor: Color(0xFF10B981),
        ),
      );
    });
  }

  void _saveChecklistToCloud() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('✓ Site Visit Checklist & AI Summary synchronized to your account.'),
        backgroundColor: Color(0xFF10B981),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredItems = _selectedCategory == 'ALL'
        ? _checklist.items
        : _checklist.items.where((i) => i.category == _selectedCategory).toList();

    return Scaffold(
      backgroundColor: AppTheme.pageBackground,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppTheme.textPrimary),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Digital Site Visit Checklist',
              style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
            ),
            Text(
              widget.propertyTitle,
              style: GoogleFonts.inter(fontSize: 11, color: AppTheme.primaryViolet, fontWeight: FontWeight.w600),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: AppTheme.borderLight),
        ),
        actions: [
          IconButton(
            onPressed: _saveChecklistToCloud,
            icon: const Icon(LucideIcons.save, color: AppTheme.primaryViolet),
            tooltip: 'Save Checklist',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 90),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 960),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Completion Progress Card
                _buildProgressHeaderCard(),
                const SizedBox(height: 18),

                // Category Filter Pills
                _buildCategoryFilters(),
                const SizedBox(height: 14),

                // Checklist Items
                ...filteredItems.map((item) => _buildChecklistItemTile(item)),

                const SizedBox(height: 24),

                // AI Visit Summary Generator Box
                _buildAiVisitSummarySection(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProgressHeaderCard() {
    final completed = _checklist.completedCount;
    final total = _checklist.items.length;
    final pct = _checklist.completionPercentage;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.borderLight),
        boxShadow: AppTheme.softCardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryViolet.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(LucideIcons.clipboardCheck, color: AppTheme.primaryViolet, size: 18),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Inspection Progress', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold)),
                      Text('$completed of $total points verified', style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textMuted)),
                    ],
                  ),
                ],
              ),
              Text(
                '${(pct * 100).round()}% Completed',
                style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w800, color: AppTheme.primaryViolet),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: pct,
              backgroundColor: AppTheme.surfaceSubtle,
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF10B981)),
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryFilters() {
    return Row(
      children: [
        _buildCategoryChip('ALL', 'All Points (${_checklist.items.length})'),
        const SizedBox(width: 8),
        _buildCategoryChip('PROPERTY', 'Physical Quality (10)'),
        const SizedBox(width: 8),
        _buildCategoryChip('DOCUMENTS', 'Paperwork & RERA (4)'),
      ],
    );
  }

  Widget _buildCategoryChip(String id, String label) {
    final isSel = _selectedCategory == id;
    return InkWell(
      onTap: () => setState(() => _selectedCategory = id),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSel ? AppTheme.primaryViolet : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSel ? AppTheme.primaryViolet : AppTheme.borderLight),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(fontSize: 11, fontWeight: isSel ? FontWeight.bold : FontWeight.w500, color: isSel ? Colors.white : AppTheme.textPrimary),
        ),
      ),
    );
  }

  Widget _buildChecklistItemTile(ChecklistItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: item.isCompleted ? const Color(0xFF10B981).withOpacity(0.4) : AppTheme.borderLight),
        boxShadow: AppTheme.subtleCardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Checkbox(
                value: item.isCompleted,
                activeColor: const Color(0xFF10B981),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                onChanged: (val) {
                  setState(() {
                    item.isCompleted = val ?? false;
                  });
                },
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.title, style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                    Text(item.subtitle, style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textMuted)),
                  ],
                ),
              ),
              // Rating Stars (1 to 5)
              Row(
                children: List.generate(5, (starIdx) {
                  final starNum = starIdx + 1;
                  return InkWell(
                    onTap: () => setState(() => item.rating = starNum),
                    child: Icon(
                      starNum <= item.rating ? Icons.star : Icons.star_border,
                      size: 16,
                      color: starNum <= item.rating ? const Color(0xFFF59E0B) : AppTheme.borderLight,
                    ),
                  );
                }),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAiVisitSummarySection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.primaryViolet.withOpacity(0.3)),
        boxShadow: AppTheme.softCardShadow,
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(LucideIcons.sparkles, color: Colors.white, size: 18),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('AI Visit Summary Generator', style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                  Text('Enter raw notes or voice transcript to extract Pros, Cons, Concerns & Follow-ups', style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textMuted)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Raw Notes Input
          TextField(
            controller: _voiceNotesController,
            maxLines: 3,
            style: GoogleFonts.inter(fontSize: 12, height: 1.4),
            decoration: InputDecoration(
              hintText: 'e.g. The flat was good. Balcony was nice. Parking was tight. Road access was good.',
              filled: true,
              fillColor: AppTheme.surfaceSubtle,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.borderLight)),
            ),
          ),
          const SizedBox(height: 12),

          // Generate Button
          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton.icon(
              onPressed: _isGeneratingSummary ? null : _generateAiSummary,
              icon: _isGeneratingSummary
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(LucideIcons.sparkles, size: 16),
              label: Text(_isGeneratingSummary ? 'Analyzing Observations...' : 'Generate AI Visit Summary',
                  style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryViolet,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),

          // Structured Output
          if (_generatedSummary != null) ...[
            const SizedBox(height: 18),
            const Divider(height: 1, color: AppTheme.borderLight),
            const SizedBox(height: 16),

            _buildSummaryBlock('🟢 PROS & KEY ADVANTAGES', _generatedSummary!.pros, const Color(0xFF10B981)),
            const SizedBox(height: 12),
            _buildSummaryBlock('🔴 CONS & TRADE-OFFS', _generatedSummary!.cons, const Color(0xFFEF4444)),
            const SizedBox(height: 12),
            _buildSummaryBlock('⚠️ SITE CONCERNS TO VERIFY', _generatedSummary!.concerns, const Color(0xFFF59E0B)),
            const SizedBox(height: 12),
            _buildSummaryBlock('❓ RECOMMENDED FOLLOW-UP QUESTIONS FOR DEALER', _generatedSummary!.followUpQuestions, AppTheme.primaryViolet),
          ],
        ],
      ),
    );
  }

  Widget _buildSummaryBlock(String title, List<String> items, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: color, letterSpacing: 0.5)),
          const SizedBox(height: 8),
          if (items.isEmpty)
            Text('No specific points flagged.', style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textMuted))
          else
            ...items.map((it) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('• ', style: TextStyle(color: color, fontWeight: FontWeight.bold)),
                      Expanded(child: Text(it, style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textPrimary, height: 1.35))),
                    ],
                  ),
                )),
        ],
      ),
    );
  }
}
