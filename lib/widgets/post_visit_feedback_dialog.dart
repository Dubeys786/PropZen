import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../models/post_visit_retention_model.dart';
import '../services/post_visit_retention_service.dart';
import '../services/propzen_voice_service.dart';
import '../theme/app_theme.dart';
import '../screens/deal_room_screen.dart';
import '../screens/ai_property_rematch_screen.dart';

class PostVisitFeedbackDialog extends StatefulWidget {
  final String visitId;
  final String propertyId;
  final String propertyTitle;
  final String sector;
  final VoidCallback? onCompleted;

  const PostVisitFeedbackDialog({
    super.key,
    required this.visitId,
    required this.propertyId,
    required this.propertyTitle,
    this.sector = 'Sector 150, Noida',
    this.onCompleted,
  });

  static Future<void> show(
    BuildContext context, {
    required String visitId,
    required String propertyId,
    required String propertyTitle,
    String sector = 'Sector 150, Noida',
    VoidCallback? onCompleted,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => PostVisitFeedbackDialog(
        visitId: visitId,
        propertyId: propertyId,
        propertyTitle: propertyTitle,
        sector: sector,
        onCompleted: onCompleted,
      ),
    );
  }

  @override
  State<PostVisitFeedbackDialog> createState() => _PostVisitFeedbackDialogState();
}

class _PostVisitFeedbackDialogState extends State<PostVisitFeedbackDialog> {
  BuyerInterestLevel _selectedInterest = BuyerInterestLevel.interested;
  final TextEditingController _notesController = TextEditingController();
  bool _isListening = false;
  PostVisitFeedback? _generatedFeedback;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    // Check if feedback was already submitted
    final existing = PostVisitRetentionService.instance.getFeedbackForVisit(widget.visitId);
    if (existing != null) {
      _selectedInterest = existing.interestLevel;
      _notesController.text = existing.rawNotes;
      _generatedFeedback = existing;
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    PropzenVoiceService.instance.stopListening();
    super.dispose();
  }

  void _toggleVoiceInput() async {
    if (_isListening) {
      PropzenVoiceService.instance.stopListening();
      setState(() => _isListening = false);
      return;
    }

    setState(() => _isListening = true);
    await PropzenVoiceService.instance.startListening(
      languageCode: 'hi-IN',
      onResult: (text, isFinal) {
        setState(() {
          _notesController.text = text;
          _updateAiExtraction(text);
        });
      },
      onError: (err) {
        setState(() => _isListening = false);
      },
      onDone: () {
        setState(() => _isListening = false);
      },
    );
  }

  void _updateAiExtraction(String text) {
    if (text.trim().isEmpty) return;
    setState(() {
      _generatedFeedback = PostVisitFeedback.parse(
        visitId: widget.visitId,
        propertyId: widget.propertyId,
        propertyTitle: widget.propertyTitle,
        buyerId: 'usr_active',
        interestLevel: _selectedInterest,
        rawNotes: text.trim(),
      );
    });
  }

  Future<void> _submitFeedback() async {
    if (_notesController.text.trim().isEmpty) {
      // Default note if user only selected interest chip
      _notesController.text = _selectedInterest == BuyerInterestLevel.lovedIt
          ? 'Loved the property and amenities.'
          : (_selectedInterest == BuyerInterestLevel.interested
              ? 'Good property layout and location.'
              : 'Looking for better options.');
    }

    setState(() => _isSubmitting = true);

    final feedback = await PostVisitRetentionService.instance.submitFeedback(
      visitId: widget.visitId,
      propertyId: widget.propertyId,
      propertyTitle: widget.propertyTitle,
      interestLevel: _selectedInterest,
      rawNotes: _notesController.text.trim(),
      customPros: _generatedFeedback?.pros,
      customCons: _generatedFeedback?.cons,
      customConcerns: _generatedFeedback?.concerns,
    );

    setState(() {
      _generatedFeedback = feedback;
      _isSubmitting = false;
    });

    widget.onCompleted?.call();
  }

  void _handleNextStepAction() {
    Navigator.of(context).pop();

    if (_selectedInterest == BuyerInterestLevel.lovedIt || _selectedInterest == BuyerInterestLevel.interested) {
      // Start negotiation in Safe Deal Room
      if (_generatedFeedback != null) {
        final room = PostVisitRetentionService.instance.startNegotiationFromFeedback(_generatedFeedback!);
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => DealRoomScreen(dealRoomId: room.id)),
        );
      }
    } else {
      // Navigate to AI Property Re-Match Screen
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => AiPropertyRematchScreen(feedback: _generatedFeedback),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final screenHeight = MediaQuery.of(context).size.height;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 680),
        child: Container(
          height: (screenHeight * 0.88).clamp(520.0, 780.0),
          padding: EdgeInsets.only(bottom: bottomInset),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // Drag handle
              Container(
                margin: const EdgeInsets.only(top: 10, bottom: 6),
                width: 40,
                height: 4,
                decoration: BoxDecoration(color: const Color(0xFFCBD5E1), borderRadius: BorderRadius.circular(2)),
              ),

              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: AppTheme.emeraldSuccess.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  'SITE VISIT COMPLETED ✓',
                                  style: GoogleFonts.inter(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.emeraldSuccess,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'How was your site visit?',
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          Text(
                            widget.propertyTitle,
                            style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textMuted),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(LucideIcons.x, color: AppTheme.textMuted),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: AppTheme.borderLight),

              // Scrollable Body
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 1. Interest Level Buttons
                      Text(
                        'Your Overall Impression',
                        style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: BuyerInterestLevel.values.map((lvl) {
                          final isSelected = _selectedInterest == lvl;
                          return ChoiceChip(
                            label: Text(
                              lvl.label,
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                color: isSelected ? Colors.white : AppTheme.textPrimary,
                              ),
                            ),
                            selected: isSelected,
                            selectedColor: AppTheme.primaryViolet,
                            backgroundColor: AppTheme.surfaceSubtle,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            onSelected: (val) {
                              if (val) {
                                setState(() {
                                  _selectedInterest = lvl;
                                  if (_notesController.text.isNotEmpty) {
                                    _updateAiExtraction(_notesController.text);
                                  }
                                });
                              }
                            },
                          );
                        }).toList(),
                      ),

                      const SizedBox(height: 20),

                      // 2. Tell PropZen about your visit (Text & Voice Input)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Tell PropZen about your visit',
                            style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF3E8FF),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(LucideIcons.sparkles, size: 11, color: AppTheme.primaryViolet),
                                const SizedBox(width: 4),
                                Text(
                                  'AI Structured Extraction',
                                  style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600, color: AppTheme.primaryViolet),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      Container(
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceSubtle,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _isListening ? AppTheme.primaryViolet : AppTheme.borderLight,
                            width: _isListening ? 1.5 : 1.0,
                          ),
                        ),
                        child: Column(
                          children: [
                            TextField(
                              controller: _notesController,
                              maxLines: 3,
                              onChanged: _updateAiExtraction,
                              decoration: InputDecoration(
                                hintText: 'Example: "Flat acha tha but parking chhoti thi. Location achhi hai but price thoda high hai."',
                                hintStyle: GoogleFonts.inter(fontSize: 12, color: AppTheme.textMuted),
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.all(12),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.vertical(bottom: Radius.circular(12)),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    _isListening ? '🎙️ Listening... Speak naturally in Hindi/English' : 'Type or tap mic to speak',
                                    style: GoogleFonts.inter(
                                      fontSize: 11,
                                      color: _isListening ? AppTheme.primaryViolet : AppTheme.textMuted,
                                      fontWeight: _isListening ? FontWeight.bold : FontWeight.normal,
                                    ),
                                  ),
                                  IconButton(
                                    icon: Icon(
                                      _isListening ? LucideIcons.micOff : LucideIcons.mic,
                                      color: _isListening ? AppTheme.coralDanger : AppTheme.primaryViolet,
                                      size: 18,
                                    ),
                                    onPressed: _toggleVoiceInput,
                                    tooltip: 'Voice Input',
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // 3. AI Structured Extraction View (Pros, Cons, Concerns)
                      if (_generatedFeedback != null || _notesController.text.isNotEmpty) ...[
                        Builder(
                          builder: (context) {
                            final fb = _generatedFeedback ??
                                PostVisitFeedback.parse(
                                  visitId: widget.visitId,
                                  propertyId: widget.propertyId,
                                  propertyTitle: widget.propertyTitle,
                                  buyerId: 'usr_active',
                                  interestLevel: _selectedInterest,
                                  rawNotes: _notesController.text,
                                );

                            return Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: const Color(0xFFE2E8F0)),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(LucideIcons.brain, size: 14, color: AppTheme.primaryViolet),
                                      const SizedBox(width: 6),
                                      Text(
                                        'AI VISIT SUMMARY',
                                        style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),

                                  // Pros
                                  if (fb.pros.isNotEmpty) ...[
                                    Text('Pros:', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.emeraldSuccess)),
                                    const SizedBox(height: 4),
                                    ...fb.pros.map((p) => Padding(
                                          padding: const EdgeInsets.only(bottom: 3),
                                          child: Row(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              const Text('✓ ', style: TextStyle(color: AppTheme.emeraldSuccess, fontWeight: FontWeight.bold)),
                                              Expanded(child: Text(p, style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textPrimary))),
                                            ],
                                          ),
                                        )),
                                    const SizedBox(height: 8),
                                  ],

                                  // Cons
                                  if (fb.cons.isNotEmpty) ...[
                                    Text('Cons:', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.coralDanger)),
                                    const SizedBox(height: 4),
                                    ...fb.cons.map((c) => Padding(
                                          padding: const EdgeInsets.only(bottom: 3),
                                          child: Row(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              const Text('✗ ', style: TextStyle(color: AppTheme.coralDanger, fontWeight: FontWeight.bold)),
                                              Expanded(child: Text(c, style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textPrimary))),
                                            ],
                                          ),
                                        )),
                                    const SizedBox(height: 8),
                                  ],

                                  // Concerns / Deal Breakers
                                  if (fb.concerns.isNotEmpty || fb.dealBreakers.isNotEmpty) ...[
                                    Text('Concerns / Deal Breakers:', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFFD97706))),
                                    const SizedBox(height: 4),
                                    ...fb.concerns.map((cn) => Padding(
                                          padding: const EdgeInsets.only(bottom: 3),
                                          child: Row(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              const Text('⚠ ', style: TextStyle(color: Color(0xFFD97706), fontWeight: FontWeight.bold)),
                                              Expanded(child: Text(cn, style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textPrimary))),
                                            ],
                                          ),
                                        )),
                                    const SizedBox(height: 8),
                                  ],

                                  // Recommended Next Step
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: const Color(0xFFCBD5E1)),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(LucideIcons.compass, size: 14, color: AppTheme.primaryViolet),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            fb.recommendedNextStep,
                                            style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              // Bottom Action Buttons
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    if (_generatedFeedback == null)
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: _isSubmitting ? null : _submitFeedback,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryViolet,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: _isSubmitting
                              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                              : Text(
                                  'Save AI Visit Summary',
                                  style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600),
                                ),
                        ),
                      )
                    else
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () {
                                _submitFeedback();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Feedback saved successfully!'), backgroundColor: AppTheme.emeraldSuccess),
                                );
                              },
                              icon: const Icon(LucideIcons.check, size: 16),
                              label: const Text('Update Summary'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppTheme.primaryViolet,
                                side: const BorderSide(color: AppTheme.primaryViolet),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            flex: 2,
                            child: ElevatedButton.icon(
                              onPressed: _handleNextStepAction,
                              icon: Icon(
                                (_selectedInterest == BuyerInterestLevel.lovedIt || _selectedInterest == BuyerInterestLevel.interested)
                                    ? LucideIcons.shieldCheck
                                    : LucideIcons.search,
                                size: 16,
                              ),
                              label: Text(
                                (_selectedInterest == BuyerInterestLevel.lovedIt || _selectedInterest == BuyerInterestLevel.interested)
                                    ? 'Start Negotiation'
                                    : 'Find Better Properties',
                                style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.bold),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: (_selectedInterest == BuyerInterestLevel.lovedIt || _selectedInterest == BuyerInterestLevel.interested)
                                    ? AppTheme.emeraldSuccess
                                    : AppTheme.primaryViolet,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
