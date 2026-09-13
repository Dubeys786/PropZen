import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:file_picker/file_picker.dart';
import '../models/trust_engine_models.dart';
import 'trust_engine_document_viewer.dart';

class TrustEngineUploadArea extends StatelessWidget {
  final List<VerificationDocument> documents;
  final ValueChanged<VerificationDocument> onDocumentAdded;
  final ValueChanged<String> onDocumentRemoved;

  const TrustEngineUploadArea({
    super.key,
    required this.documents,
    required this.onDocumentAdded,
    required this.onDocumentRemoved,
  });

  Future<void> _pickFile(BuildContext context, {FileType fileType = FileType.any}) async {
    try {
      final result = await FilePicker.pickFiles(
        type: fileType,
        allowedExtensions: fileType == FileType.custom ? ['pdf', 'jpg', 'jpeg', 'png'] : null,
        allowMultiple: true,
      );

      if (result != null && result.files.isNotEmpty) {
        for (final f in result.files) {
          final ext = f.extension?.toLowerCase() ?? '';
          String docType = 'Sale Deed';
          if (ext == 'pdf') {
            docType = 'Registered Sale Deed';
          } else if (f.name.toLowerCase().contains('tax')) {
            docType = 'Property Tax Receipt';
          } else if (f.name.toLowerCase().contains('khatauni') || f.name.toLowerCase().contains('mutation')) {
            docType = 'Revenue Mutation';
          }

          final doc = VerificationDocument(
            id: 'doc_${DateTime.now().millisecondsSinceEpoch}_${f.name.hashCode.abs()}',
            name: f.name,
            documentType: docType,
            fileSizeBytes: f.size,
            status: DocumentProcessingStatus.uploaded,
            uploadedAt: DateTime.now(),
            localPath: f.path,
          );
          onDocumentAdded(doc);
        }
      }
    } catch (e) {
      debugPrint('[TrustEngine] FilePicker error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(color: Color(0x04000000), blurRadius: 10, offset: Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF7C3AED).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(LucideIcons.uploadCloud, size: 16, color: Color(0xFF7C3AED)),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Upload Property Documents',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),
              Text(
                'Supported: PDF, JPG, JPEG, PNG',
                style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF94A3B8), fontWeight: FontWeight.w500),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Upload registry, sale deed, mutation, khatauni, tax receipt or other supporting documents.',
            style: GoogleFonts.inter(fontSize: 12.5, color: const Color(0xFF64748B)),
          ),
          const SizedBox(height: 18),

          // Dropzone Container
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFCBD5E1), style: BorderStyle.solid),
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [BoxShadow(color: Color(0x08000000), blurRadius: 8, offset: Offset(0, 2))],
                  ),
                  child: const Icon(LucideIcons.fileUp, size: 28, color: Color(0xFF7C3AED)),
                ),
                const SizedBox(height: 12),
                Text(
                  'Drag and drop property documents here, or choose an upload method',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'End-to-end encrypted • Scanned with OCR structure validation',
                  style: GoogleFonts.inter(fontSize: 11.5, color: const Color(0xFF64748B)),
                ),
                const SizedBox(height: 16),

                // Upload Action Buttons
                Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  alignment: WrapAlignment.center,
                  children: [
                    ElevatedButton.icon(
                      icon: const Icon(LucideIcons.fileText, size: 14),
                      label: const Text('Upload PDF'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF7C3AED),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        textStyle: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                      onPressed: () => _pickFile(context, fileType: FileType.custom),
                    ),
                    OutlinedButton.icon(
                      icon: const Icon(LucideIcons.image, size: 14, color: Color(0xFF475569)),
                      label: const Text('Upload Images'),
                      style: OutlinedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFF1E293B),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        side: const BorderSide(color: Color(0xFFCBD5E1)),
                        textStyle: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                      onPressed: () => _pickFile(context, fileType: FileType.image),
                    ),
                    OutlinedButton.icon(
                      icon: const Icon(LucideIcons.camera, size: 14, color: Color(0xFF475569)),
                      label: const Text('Take Photo'),
                      style: OutlinedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFF1E293B),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        side: const BorderSide(color: Color(0xFFCBD5E1)),
                        textStyle: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                      onPressed: () => _pickFile(context, fileType: FileType.image),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // Uploaded Documents List / Empty State
          if (documents.isEmpty) ...[
            Container(
              padding: const EdgeInsets.symmetric(vertical: 24),
              alignment: Alignment.center,
              child: Column(
                children: [
                  Icon(LucideIcons.folderX, size: 28, color: Colors.grey.shade400),
                  const SizedBox(height: 8),
                  Text(
                    'No documents uploaded yet.',
                    style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF64748B), fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
          ] else ...[
            Text(
              'Uploaded Documents (${documents.length})',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 10),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: documents.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final doc = documents[index];
                return _buildDocumentCard(context, doc, index);
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDocumentCard(BuildContext context, VerificationDocument doc, int index) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF7C3AED).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(LucideIcons.fileText, size: 16, color: Color(0xFF7C3AED)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        doc.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                      decoration: BoxDecoration(
                        color: doc.status.color.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        doc.status.label,
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: doc.status.color,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '${doc.documentType} • ${doc.formattedSize} • Uploaded ${doc.uploadedAt.hour.toString().padLeft(2, '0')}:${doc.uploadedAt.minute.toString().padLeft(2, '0')}',
                  style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF64748B)),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),

          // Preview Button
          OutlinedButton.icon(
            icon: const Icon(LucideIcons.eye, size: 13),
            label: const Text('Preview'),
            style: OutlinedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF475569),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
              side: const BorderSide(color: Color(0xFFCBD5E1)),
              textStyle: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600),
            ),
            onPressed: () {
              TrustEngineDocumentViewer.show(context, documents: documents, initialIndex: index);
            },
          ),
          const SizedBox(width: 8),

          // Delete Button
          IconButton(
            icon: const Icon(LucideIcons.trash2, size: 15, color: Color(0xFFEF4444)),
            onPressed: () => onDocumentRemoved(doc.id),
            tooltip: 'Remove Document',
          ),
        ],
      ),
    );
  }
}
