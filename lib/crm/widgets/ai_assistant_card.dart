import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../theme/app_theme.dart';
import '../models/crm_ai_models.dart';
import '../services/crm_ai_service.dart';

/// Card displaying the AI Lead Score, qualification tier, and key scoring drivers.
class AiLeadScoreCard extends StatefulWidget {
  final String leadId;
  final int? initialScore;
  final VoidCallback? onScoreUpdated;

  const AiLeadScoreCard({
    super.key,
    required this.leadId,
    this.initialScore,
    this.onScoreUpdated,
  });

  @override
  State<AiLeadScoreCard> createState() => _AiLeadScoreCardState();
}

class _AiLeadScoreCardState extends State<AiLeadScoreCard> {
  AiLeadScore? _score;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadScore();
  }

  Future<void> _loadScore() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final res = await CrmAiService.instance.calculateLeadScore(widget.leadId);
      if (mounted) {
        setState(() {
          _score = res;
          _isLoading = false;
        });
        widget.onScoreUpdated?.call();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final scoreVal = _score?.score ?? widget.initialScore ?? 0;
    final category = _score?.category ?? (scoreVal >= 75 ? 'HOT' : scoreVal >= 45 ? 'WARM' : 'COLD');
    final categoryColor = _score?.categoryColor ??
        (category == 'HOT'
            ? const Color(0xFFEF4444)
            : category == 'WARM'
                ? const Color(0xFFF59E0B)
                : const Color(0xFF3B82F6));

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
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
                      color: const Color(0xFF7C3AED).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(LucideIcons.sparkles, color: Color(0xFF7C3AED), size: 18),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'AI Lead Score',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ],
              ),
              IconButton(
                icon: _isLoading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF7C3AED)),
                      )
                    : const Icon(LucideIcons.refreshCw, size: 16, color: Color(0xFF64748B)),
                tooltip: 'Recalculate AI Score',
                onPressed: _isLoading ? null : _loadScore,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: categoryColor.withOpacity(0.12),
                  border: Border.all(color: categoryColor.withOpacity(0.3), width: 2),
                ),
                child: Center(
                  child: Text(
                    '$scoreVal',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: categoryColor,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                      decoration: BoxDecoration(
                        color: categoryColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '$category ENGAGEMENT',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: categoryColor,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _score?.recommendedAction ??
                          (scoreVal >= 75
                              ? 'High conversion likelihood. Schedule site visit immediately.'
                              : 'Qualified prospect. Send relevant listings and follow up.'),
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (_score != null && _score!.reasons.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Divider(color: Color(0xFFF1F5F9), height: 1),
            const SizedBox(height: 12),
            Text(
              'Key Scoring Signals:',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF475569),
              ),
            ),
            const SizedBox(height: 8),
            ..._score!.reasons.map((reason) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(LucideIcons.checkCircle2, size: 14, color: Color(0xFF10B981)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          reason,
                          style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textSecondary),
                        ),
                      ),
                    ],
                  ),
                )),
          ],
        ],
      ),
    );
  }
}

/// Card presenting the AI recommended next action with urgency tag.
class AiNextActionCard extends StatefulWidget {
  final String leadId;

  const AiNextActionCard({super.key, required this.leadId});

  @override
  State<AiNextActionCard> createState() => _AiNextActionCardState();
}

class _AiNextActionCardState extends State<AiNextActionCard> {
  AiNextAction? _action;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadAction();
  }

  Future<void> _loadAction() async {
    setState(() => _isLoading = true);
    try {
      final res = await CrmAiService.instance.recommendNextAction(widget.leadId);
      if (mounted) {
        setState(() {
          _action = res;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: const Center(
          child: Padding(
            padding: EdgeInsets.all(8.0),
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF7C3AED)),
            ),
          ),
        ),
      );
    }

    if (_action == null) return const SizedBox.shrink();

    final isImmediate = _action!.urgency.toUpperCase() == 'IMMEDIATE';
    final tagColor = isImmediate ? const Color(0xFFEF4444) : const Color(0xFF3B82F6);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(LucideIcons.zap, size: 16, color: Color(0xFF7C3AED)),
                  const SizedBox(width: 8),
                  Text(
                    'AI Recommended Action',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: tagColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  _action!.urgency.replaceAll('_', ' '),
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: tagColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            _action!.actionSummary,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1E293B),
            ),
          ),
          if (_action!.actionReason != null) ...[
            const SizedBox(height: 6),
            Text(
              _action!.actionReason!,
              style: GoogleFonts.inter(
                fontSize: 12,
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Card providing AI generated contextual follow-up message drafts with user editability.
class AiFollowUpAssistantCard extends StatefulWidget {
  final String leadId;
  final String customerPhone;
  final String customerName;

  const AiFollowUpAssistantCard({
    super.key,
    required this.leadId,
    required this.customerPhone,
    required this.customerName,
  });

  @override
  State<AiFollowUpAssistantCard> createState() => _AiFollowUpAssistantCardState();
}

class _AiFollowUpAssistantCardState extends State<AiFollowUpAssistantCard> {
  final TextEditingController _msgController = TextEditingController();
  AiFollowUpDraft? _draft;
  bool _isLoading = false;
  bool _isCopied = false;

  @override
  void initState() {
    super.initState();
    _loadDraft();
  }

  @override
  void dispose() {
    _msgController.dispose();
    super.dispose();
  }

  Future<void> _loadDraft() async {
    setState(() => _isLoading = true);
    try {
      final res = await CrmAiService.instance.generateFollowUpDraft(widget.leadId);
      if (mounted) {
        setState(() {
          _draft = res;
          _msgController.text = res.draftMessage;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _msgController.text =
              'Hello ${widget.customerName}, following up from PropZen regarding your property enquiry. Please let us know a convenient time to connect.';
        });
      }
    }
  }

  void _copyToClipboard() {
    Clipboard.setData(ClipboardData(text: _msgController.text));
    setState(() => _isCopied = true);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Message copied to clipboard')),
    );
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _isCopied = false);
    });
  }

  Future<void> _openWhatsApp() async {
    final cleanPhone = widget.customerPhone.replaceAll(RegExp(r'[^0-9]'), '');
    final text = Uri.encodeComponent(_msgController.text);
    final url = Uri.parse('https://wa.me/$cleanPhone?text=$text');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
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
                      color: const Color(0xFF25D366).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(LucideIcons.messageSquare, color: Color(0xFF25D366), size: 18),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'AI Follow-up Assistant',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ],
              ),
              IconButton(
                icon: _isLoading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF25D366)),
                      )
                    : const Icon(LucideIcons.refreshCw, size: 16, color: Color(0xFF64748B)),
                tooltip: 'Regenerate Draft',
                onPressed: _isLoading ? null : _loadDraft,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Text(
                  'The message below is generated by PropZen CRM AI. You can review and edit it freely before sending.',
                  style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textSecondary),
                ),
              ),
              if (_draft != null && _draft!.messageIntent.isNotEmpty) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Text(
                    _draft!.messageIntent,
                    style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, color: const Color(0xFF475569)),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _msgController,
            maxLines: 4,
            style: GoogleFonts.inter(fontSize: 13, height: 1.4),
            decoration: InputDecoration(
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFF25D366)),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              OutlinedButton.icon(
                icon: Icon(
                  _isCopied ? LucideIcons.check : LucideIcons.copy,
                  size: 14,
                  color: _isCopied ? const Color(0xFF10B981) : AppTheme.textPrimary,
                ),
                label: Text(
                  _isCopied ? 'Copied' : 'Copy',
                  style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600),
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  side: const BorderSide(color: Color(0xFFCBD5E1)),
                ),
                onPressed: _copyToClipboard,
              ),
              const SizedBox(width: 10),
              ElevatedButton.icon(
                icon: const Icon(LucideIcons.messageCircle, size: 14, color: Colors.white),
                label: Text(
                  'Send via WhatsApp',
                  style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF25D366),
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: widget.customerPhone.isNotEmpty ? _openWhatsApp : null,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
