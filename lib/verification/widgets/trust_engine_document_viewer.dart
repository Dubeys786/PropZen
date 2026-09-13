import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../models/trust_engine_models.dart';

class TrustEngineDocumentViewer extends StatefulWidget {
  final List<VerificationDocument> documents;
  final int initialIndex;

  const TrustEngineDocumentViewer({
    super.key,
    required this.documents,
    this.initialIndex = 0,
  });

  static Future<void> show(
    BuildContext context, {
    required List<VerificationDocument> documents,
    int initialIndex = 0,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: TrustEngineDocumentViewer(
          documents: documents,
          initialIndex: initialIndex,
        ),
      ),
    );
  }

  @override
  State<TrustEngineDocumentViewer> createState() => _TrustEngineDocumentViewerState();
}

class _TrustEngineDocumentViewerState extends State<TrustEngineDocumentViewer> {
  late int _selectedIndex;
  double _zoomLevel = 1.0;
  int _rotationQuarterTurns = 0;
  int _currentPage = 1;
  final int _totalPages = 4;
  bool _isFullscreen = false;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex.clamp(0, widget.documents.isEmpty ? 0 : widget.documents.length - 1);
  }

  void _zoomIn() {
    setState(() => _zoomLevel = (_zoomLevel + 0.25).clamp(0.5, 3.0));
  }

  void _zoomOut() {
    setState(() => _zoomLevel = (_zoomLevel - 0.25).clamp(0.5, 3.0));
  }

  void _rotate() {
    setState(() => _rotationQuarterTurns = (_rotationQuarterTurns + 1) % 4);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.documents.isEmpty) {
      return Container(
        width: 400,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(LucideIcons.fileX, size: 40, color: Color(0xFF94A3B8)),
            const SizedBox(height: 12),
            Text('No Documents Attached', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    }

    final activeDoc = widget.documents[_selectedIndex];

    return Container(
      width: _isFullscreen ? double.infinity : 1050,
      height: _isFullscreen ? double.infinity : 720,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(_isFullscreen ? 0 : 16),
        boxShadow: const [
          BoxShadow(color: Color(0x22000000), blurRadius: 24, offset: Offset(0, 8)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(_isFullscreen ? 0 : 16),
        child: Column(
          children: [
            // Top Toolbar
            _buildToolbar(activeDoc),
            const Divider(height: 1, color: Color(0xFFE2E8F0)),

            // Main Split Panel
            Expanded(
              child: Row(
                children: [
                  // Left Document List (Collapsible on mobile/narrow)
                  Container(
                    width: 260,
                    decoration: const BoxDecoration(
                      color: Color(0xFFF8FAFC),
                      border: Border(right: BorderSide(color: Color(0xFFE2E8F0))),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text(
                            'Case Documents (${widget.documents.length})',
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF0F172A),
                            ),
                          ),
                        ),
                        Expanded(
                          child: ListView.separated(
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            itemCount: widget.documents.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 6),
                            itemBuilder: (context, index) {
                              final doc = widget.documents[index];
                              final isSelected = index == _selectedIndex;

                              return InkWell(
                                onTap: () => setState(() {
                                  _selectedIndex = index;
                                  _currentPage = 1;
                                  _zoomLevel = 1.0;
                                  _rotationQuarterTurns = 0;
                                }),
                                borderRadius: BorderRadius.circular(10),
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: isSelected ? Colors.white : Colors.transparent,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: isSelected ? const Color(0xFF7C3AED) : Colors.transparent,
                                    ),
                                    boxShadow: isSelected
                                        ? [const BoxShadow(color: Color(0x0A000000), blurRadius: 6, offset: Offset(0, 2))]
                                        : null,
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(6),
                                        decoration: BoxDecoration(
                                          color: isSelected
                                              ? const Color(0xFF7C3AED).withOpacity(0.1)
                                              : const Color(0xFFE2E8F0),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Icon(
                                          LucideIcons.fileText,
                                          size: 16,
                                          color: isSelected ? const Color(0xFF7C3AED) : const Color(0xFF64748B),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              doc.name,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: GoogleFonts.inter(
                                                fontSize: 12,
                                                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                                color: const Color(0xFF0F172A),
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              '${doc.documentType} • ${doc.formattedSize}',
                                              style: GoogleFonts.inter(fontSize: 10.5, color: const Color(0xFF64748B)),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Right Preview Canvas
                  Expanded(
                    child: Container(
                      color: const Color(0xFFE2E8F0),
                      child: Center(
                        child: SingleChildScrollView(
                          child: RotatedBox(
                            quarterTurns: _rotationQuarterTurns,
                            child: Transform.scale(
                              scale: _zoomLevel,
                              child: _buildDocumentMockPage(activeDoc),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToolbar(VerificationDocument activeDoc) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      color: Colors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Icon(LucideIcons.shieldCheck, size: 18, color: Color(0xFF10B981)),
              const SizedBox(width: 8),
              Text(
                activeDoc.name,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'Authenticated OCR',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF059669),
                  ),
                ),
              ),
            ],
          ),

          // Control Actions
          Row(
            children: [
              // Page Navigation
              IconButton(
                icon: const Icon(LucideIcons.chevronLeft, size: 16),
                onPressed: _currentPage > 1 ? () => setState(() => _currentPage--) : null,
                tooltip: 'Previous Page',
              ),
              Text(
                '$_currentPage / $_totalPages',
                style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF475569)),
              ),
              IconButton(
                icon: const Icon(LucideIcons.chevronRight, size: 16),
                onPressed: _currentPage < _totalPages ? () => setState(() => _currentPage++) : null,
                tooltip: 'Next Page',
              ),
              const SizedBox(width: 8),

              // Zoom Controls
              IconButton(
                icon: const Icon(LucideIcons.zoomOut, size: 16),
                onPressed: _zoomOut,
                tooltip: 'Zoom Out',
              ),
              Text(
                '${(_zoomLevel * 100).toInt()}%',
                style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600),
              ),
              IconButton(
                icon: const Icon(LucideIcons.zoomIn, size: 16),
                onPressed: _zoomIn,
                tooltip: 'Zoom In',
              ),
              const SizedBox(width: 8),

              // Rotate
              IconButton(
                icon: const Icon(LucideIcons.rotateCw, size: 16),
                onPressed: _rotate,
                tooltip: 'Rotate 90°',
              ),

              // Fullscreen
              IconButton(
                icon: Icon(_isFullscreen ? LucideIcons.minimize : LucideIcons.maximize, size: 16),
                onPressed: () => setState(() => _isFullscreen = !_isFullscreen),
                tooltip: 'Toggle Fullscreen',
              ),

              const SizedBox(width: 8),
              // Close
              IconButton(
                icon: const Icon(LucideIcons.x, size: 18),
                onPressed: () => Navigator.of(context).pop(),
                tooltip: 'Close Viewer',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentMockPage(VerificationDocument doc) {
    return Container(
      width: 480,
      height: 640,
      margin: const EdgeInsets.all(24),
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
        boxShadow: const [
          BoxShadow(color: Color(0x1F000000), blurRadius: 16, offset: Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Official Stamp Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'GOVERNMENT OF UTTAR PRADESH',
                    style: GoogleFonts.cinzel(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.1,
                      color: const Color(0xFF1E293B),
                    ),
                  ),
                  Text(
                    'REGISTRATION AND STAMPS DEPARTMENT',
                    style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.w600, color: const Color(0xFF64748B)),
                  ),
                ],
              ),
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFFB45309), width: 1.5),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    'E-STAMP\nVERIFIED',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(fontSize: 7, fontWeight: FontWeight.bold, color: const Color(0xFFB45309)),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 2, color: Color(0xFF0F172A)),
          const SizedBox(height: 16),

          // Document Title
          Center(
            child: Text(
              doc.documentType.toUpperCase(),
              style: GoogleFonts.cinzel(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF0F172A),
                letterSpacing: 1.2,
              ),
            ),
          ),
          const SizedBox(height: 18),

          // Highlighting Extracted Fields visually
          _buildHighlightedField('EXECUTANT / SELLER:', 'ATS Infrastructure Developers Pvt. Ltd.'),
          const SizedBox(height: 8),
          _buildHighlightedField('CLAIMANT / PURCHASER:', 'Vikramaditya Sharma'),
          const SizedBox(height: 8),
          _buildHighlightedField('PROPERTY DESCRIPTION:', 'Tower 4, Flat 1204, ATS One Hamlet, Sector 104, Noida'),
          const SizedBox(height: 8),
          _buildHighlightedField('SUPER BUILT-UP AREA:', '2150 Sq.Ft. (Carpet Area: 1680 Sq.Ft.)'),
          const SizedBox(height: 8),
          _buildHighlightedField('CONSIDERATION VALUE:', '₹ 2,45,00,000 (Two Crore Forty-Five Lakhs Only)'),
          const SizedBox(height: 8),
          _buildHighlightedField('STAMP DUTY PAID:', '₹ 17,15,000 (Challan: E-CH-2023-88719)'),

          const Spacer(),
          const Divider(color: Color(0xFFE2E8F0)),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Page $_currentPage of $_totalPages',
                style: GoogleFonts.inter(fontSize: 10, color: const Color(0xFF94A3B8)),
              ),
              Text(
                'PropZen Integrity Signature: SHA256-AUTHENTICATED',
                style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.bold, color: const Color(0xFF059669)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHighlightedField(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFEDE9FE).withOpacity(0.5),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: const Color(0xFF7C3AED).withOpacity(0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label ',
            style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: const Color(0xFF4C1D95)),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600, color: const Color(0xFF1E1B4B)),
            ),
          ),
        ],
      ),
    );
  }
}
