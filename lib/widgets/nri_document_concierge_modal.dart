import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../models/property.dart';
import '../models/nri_subscription_model.dart';
import '../services/nri_subscription_service.dart';
import '../theme/app_theme.dart';

/// NRI Document Concierge Vault Modal
class NriDocumentConciergeModal extends StatefulWidget {
  final Property property;

  const NriDocumentConciergeModal({
    super.key,
    required this.property,
  });

  static Future<void> show(BuildContext context, {required Property property}) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => NriDocumentConciergeModal(property: property),
    );
  }

  @override
  State<NriDocumentConciergeModal> createState() => _NriDocumentConciergeModalState();
}

class _NriDocumentConciergeModalState extends State<NriDocumentConciergeModal> {
  final NriSubscriptionService _subService = NriSubscriptionService.instance;
  bool _isUploading = false;

  final TextEditingController _titleController = TextEditingController();
  String _selectedCategory = 'property_documents';

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _subService,
      builder: (context, _) {
        final docs = _subService.getDocumentsForProperty(widget.property.id);

        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
          insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          backgroundColor: Colors.white,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680, maxHeight: 760),
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
                        child: const Icon(LucideIcons.fileCheck2, color: Colors.white, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'NRI Document Concierge Vault',
                              style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                            Text(
                              '${widget.property.title} • Encrypted Legal Repository',
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
                        // Vault Banner
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: Row(
                            children: [
                              const Icon(LucideIcons.shieldCheck, color: Color(0xFF10B981), size: 20),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'All documents undergo 30-year encumbrance search and RERA Title verification before buyer handover.',
                                  style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textSecondary, height: 1.35),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 18),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Verified Documents (${docs.length})',
                              style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                            ),
                            TextButton.icon(
                              onPressed: _showUploadForm,
                              icon: const Icon(LucideIcons.uploadCloud, size: 14, color: AppTheme.primaryViolet),
                              label: Text('Upload Document', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.primaryViolet)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),

                        if (docs.isEmpty)
                          Center(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 30),
                              child: Text('No documents uploaded for this property yet.', style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textMuted)),
                            ),
                          )
                        else
                          Column(
                            children: docs.map((d) => _buildDocTile(d)).toList(),
                          ),
                      ],
                    ),
                  ),
                ),

                // Footer
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryViolet,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: Text('Close Vault', style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDocTile(NriDocumentItem item) {
    Color statusColor;
    Color statusBg;
    switch (item.status) {
      case 'verified':
        statusColor = const Color(0xFF16A34A);
        statusBg = const Color(0xFFDCFCE7);
        break;
      case 'under_review':
        statusColor = const Color(0xFFD97706);
        statusBg = const Color(0xFFFEF3C7);
        break;
      case 'needs_attention':
        statusColor = const Color(0xFFDC2626);
        statusBg = const Color(0xFFFEE2E2);
        break;
      default:
        statusColor = AppTheme.primaryViolet;
        statusBg = const Color(0xFFEDE9FE);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(LucideIcons.fileText, color: Color(0xFF475569), size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${item.categoryDisplay} • ${item.fileSize}',
                  style: GoogleFonts.inter(fontSize: 10, color: AppTheme.textMuted),
                ),
                if (item.verifiedBy != null) ...[
                  const SizedBox(height: 2),
                  Text('Verified by: ${item.verifiedBy}', style: GoogleFonts.inter(fontSize: 10, color: const Color(0xFF16A34A), fontWeight: FontWeight.w500)),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: statusBg,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              item.statusDisplay,
              style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: statusColor),
            ),
          ),
        ],
      ),
    );
  }

  void _showUploadForm() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(left: 20, right: 20, top: 20, bottom: MediaQuery.of(ctx).viewInsets.bottom + 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Upload Document to Vault', style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
            const SizedBox(height: 12),
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                hintText: 'Document Name / Description',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _selectedCategory,
              decoration: InputDecoration(
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
              items: const [
                DropdownMenuItem(value: 'property_documents', child: Text('Property Title & Deeds')),
                DropdownMenuItem(value: 'verification_documents', child: Text('RERA Verification')),
                DropdownMenuItem(value: 'agreement', child: Text('Builder-Buyer Agreement')),
                DropdownMenuItem(value: 'payment_receipts', child: Text('Payment Receipts')),
                DropdownMenuItem(value: 'floor_plan', child: Text('Architectural Drawings')),
                DropdownMenuItem(value: 'other', child: Text('Other')),
              ],
              onChanged: (val) => setState(() => _selectedCategory = val!),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton.icon(
                onPressed: () async {
                  if (_titleController.text.trim().isNotEmpty) {
                    await _subService.uploadDocument(
                      propertyId: widget.property.id,
                      title: _titleController.text.trim(),
                      category: _selectedCategory,
                      fileUrl: 'https://propzen.ai/vault/doc_${DateTime.now().millisecondsSinceEpoch}.pdf',
                    );
                    _titleController.clear();
                    Navigator.of(ctx).pop();
                  }
                },
                icon: const Icon(LucideIcons.check, size: 16, color: Colors.white),
                label: Text('Save to Concierge Vault', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.bold)),
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
    );
  }
}
