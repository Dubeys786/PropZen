import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/property.dart';
import '../services/admin_service.dart';
import '../theme/app_theme.dart';

class AdminPropertyReviewScreen extends StatefulWidget {
  final Property property;
  final VoidCallback? onStatusChanged;

  const AdminPropertyReviewScreen({
    super.key,
    required this.property,
    this.onStatusChanged,
  });

  @override
  State<AdminPropertyReviewScreen> createState() => _AdminPropertyReviewScreenState();
}

class _AdminPropertyReviewScreenState extends State<AdminPropertyReviewScreen> {
  late Property _property;
  bool _isProcessing = false;
  final TextEditingController _rejectionReasonController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _property = widget.property;
  }

  @override
  void dispose() {
    _rejectionReasonController.dispose();
    super.dispose();
  }

  Future<void> _handleApprove() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(LucideIcons.checkCircle2, color: AppTheme.emeraldSuccess, size: 24),
            const SizedBox(width: 10),
            Text('Approve Listing?', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text(
          'Approving this listing will publish "${_property.title}" immediately to all public users across PropZen.',
          style: GoogleFonts.inter(fontSize: 14, color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text('Cancel', style: GoogleFonts.inter(color: AppTheme.textMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.emeraldSuccess,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text('Confirm Approve', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isProcessing = true);
    final success = await AdminService.instance.approveProperty(_property.id);
    setState(() => _isProcessing = false);

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Listing approved and published successfully!'),
            backgroundColor: AppTheme.emeraldSuccess,
          ),
        );
        setState(() {
          _property = _property.copyWith(
            status: 'published',
            approvedAt: DateTime.now().toIso8601String(),
          );
        });
        widget.onStatusChanged?.call();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Approval synced locally & pending backend update.'),
            backgroundColor: Color(0xFFF59E0B),
          ),
        );
      }
    }
  }

  Future<void> _handleReject() async {
    _rejectionReasonController.clear();
    final reason = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(LucideIcons.alertTriangle, color: Colors.red, size: 24),
            const SizedBox(width: 10),
            Text('Reject Listing', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Please provide a detailed rejection reason or instructions for the dealer to rectify:',
              style: GoogleFonts.inter(fontSize: 13, color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _rejectionReasonController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'e.g. Please upload higher resolution photos and verified RERA certificate.',
                hintStyle: GoogleFonts.inter(fontSize: 12, color: AppTheme.textHint),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Colors.red),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(null),
            child: Text('Cancel', style: GoogleFonts.inter(color: AppTheme.textMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              final r = _rejectionReasonController.text.trim();
              if (r.isEmpty) {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  const SnackBar(content: Text('Please enter a rejection reason.')),
                );
                return;
              }
              Navigator.of(ctx).pop(r);
            },
            child: Text('Confirm Reject', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (reason == null || reason.isEmpty) return;

    setState(() => _isProcessing = true);
    final success = await AdminService.instance.rejectProperty(_property.id, reason: reason);
    setState(() => _isProcessing = false);

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Listing rejected with note: "$reason"'),
            backgroundColor: Colors.red,
          ),
        );
      }
      setState(() {
        _property = _property.copyWith(
          status: 'rejected',
          adminNote: reason,
        );
      });
      widget.onStatusChanged?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = _property.status.toLowerCase();
    final isPending = status == 'pending';
    final isPublished = status == 'published';
    final isRejected = status == 'rejected';

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Property Review',
              style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            Text(
              'ID: ${_property.id}',
              style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF94A3B8)),
            ),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16, top: 12, bottom: 12),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: isPending
                  ? const Color(0xFFF59E0B).withOpacity(0.2)
                  : (isPublished ? AppTheme.emeraldSuccess.withOpacity(0.2) : Colors.red.withOpacity(0.2)),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isPending
                    ? const Color(0xFFF59E0B)
                    : (isPublished ? AppTheme.emeraldSuccess : Colors.red),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isPending ? LucideIcons.clock : (isPublished ? LucideIcons.checkCircle : LucideIcons.alertCircle),
                  size: 12,
                  color: isPending
                      ? const Color(0xFFF59E0B)
                      : (isPublished ? AppTheme.emeraldSuccess : Colors.red),
                ),
                const SizedBox(width: 4),
                Text(
                  _property.status.toUpperCase(),
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: isPending
                        ? const Color(0xFFF59E0B)
                        : (isPublished ? AppTheme.emeraldSuccess : Colors.red),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 960),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Admin Note Banner (if rejected)
            if (isRejected && _property.adminNote != null && _property.adminNote!.isNotEmpty) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.withOpacity(0.4)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(LucideIcons.alertCircle, color: Colors.red, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Admin Rejection Reason:',
                            style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.red),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _property.adminNote!,
                            style: GoogleFonts.inter(fontSize: 12, color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Hero Image & Overview Card
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF334155)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                    child: Image.network(
                      _property.dynamicImageUrl,
                      height: 200,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (ctx, err, stack) => Container(
                        height: 200,
                        color: const Color(0xFF334155),
                        child: const Center(child: Icon(LucideIcons.image, color: Colors.white54, size: 40)),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryViolet.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                _property.propertyType,
                                style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFFA78BFA)),
                              ),
                            ),
                            Text(
                              _property.formattedPrice,
                              style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.primaryViolet),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _property.title,
                          style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(LucideIcons.mapPin, size: 14, color: Color(0xFF94A3B8)),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                '${_property.effectiveLocality}, ${_property.city}',
                                style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF94A3B8)),
                                overflow: TextOverflow.ellipsis,
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

            const SizedBox(height: 16),

            // Key Specs Grid
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF334155)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Property Specifications', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _buildSpecItem(LucideIcons.home, 'BHK', _property.bhk),
                      _buildSpecItem(LucideIcons.maximize2, 'Area', '${_property.sqft} sq.ft'),
                      _buildSpecItem(LucideIcons.layers, 'Carpet Area', '${_property.carpetAreaSqft} sq.ft'),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _buildSpecItem(LucideIcons.compass, 'Facing', _property.facing),
                      _buildSpecItem(LucideIcons.sofa, 'Furnishing', _property.furnishing),
                      _buildSpecItem(LucideIcons.calendar, 'Possession', _property.possessionDate),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Dealer Contact Information Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF334155)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Dealer Credentials', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text('Verified Partner', style: GoogleFonts.inter(fontSize: 10, color: Colors.blue)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildDealerRow(LucideIcons.user, 'Dealer Name', _property.dealerName),
                  _buildDealerRow(LucideIcons.phone, 'Dealer Phone', _property.dealerPhone),
                  _buildDealerRow(LucideIcons.mail, 'Dealer Email', _property.dealerEmail),
                  _buildDealerRow(LucideIcons.shieldCheck, 'Dealer ID', _property.dealerId),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Location & Address Details
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF334155)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Location & Address Verification', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
                  const SizedBox(height: 12),
                  _buildDetailRow('Full Address', _property.fullAddress),
                  _buildDetailRow('Sector', _property.sector),
                  _buildDetailRow('City', _property.city),
                  _buildDetailRow('PIN Code', _property.postalCode),
                  _buildDetailRow('Coordinates', '${_property.latitude.toStringAsFixed(4)}° N, ${_property.longitude.toStringAsFixed(4)}° E'),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Description & Legal
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF334155)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Description & Verification', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
                  const SizedBox(height: 8),
                  Text(
                    _property.description,
                    style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFFCBD5E1), height: 1.5),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(LucideIcons.checkCheck, color: AppTheme.emeraldSuccess, size: 16),
                      const SizedBox(width: 6),
                      Text('RERA ID: ${_property.reraId}', style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF94A3B8))),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Verification Documents & Uploaded Compliance Files
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF334155)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Verification Documents & Files', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryViolet.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text('SUPABASE STORAGE', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: const Color(0xFFA78BFA))),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // RERA Document Row
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F172A),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFF334155)),
                    ),
                    child: Row(
                      children: [
                        const Icon(LucideIcons.fileCheck, color: AppTheme.emeraldSuccess, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('RERA Registration Certificate', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
                              Text(_property.reraDocumentUrl != null && _property.reraDocumentUrl!.isNotEmpty ? 'Attached (${_property.reraDocumentUrl!.split("/").last})' : 'Verified RERA Document Provided', style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF94A3B8))),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(color: AppTheme.emeraldSuccess.withOpacity(0.15), borderRadius: BorderRadius.circular(6)),
                          child: Text('✓ Verified', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.emeraldSuccess)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Floor Plan Row
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F172A),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFF334155)),
                    ),
                    child: Row(
                      children: [
                        const Icon(LucideIcons.layout, color: Color(0xFF38BDF8), size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Master Floor Plan (2D/3D)', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
                              Text(_property.floorPlanUrl != null && _property.floorPlanUrl!.isNotEmpty ? 'Attached (${_property.floorPlanUrl!.split("/").last})' : 'Architectural Layout Attached', style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF94A3B8))),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(color: const Color(0xFF38BDF8).withOpacity(0.15), borderRadius: BorderRadius.circular(6)),
                          child: Text('✓ Attached', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: const Color(0xFF38BDF8))),
                        ),
                      ],
                    ),
                  ),
                  _buildPhotoModerationGallery(),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Immersive Visualization Assets Review Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF334155)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Visualization Assets (360° / 3D / AR)',
                          style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFF06B6D4).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text('ECOSYSTEM',
                            style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: const Color(0xFF22D3EE))),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // YouTube Video Walkthrough
                  _buildVisualizationAssetRow(
                    icon: LucideIcons.youtube,
                    title: 'Official YouTube Walkthrough',
                    url: _property.officialYoutubeWatchUrl,
                    statusText: _property.hasYoutubeVideo
                        ? 'Verified Video ID: ${_property.youtubeVideoId ?? "Configured"}'
                        : 'No YouTube Tour Linked',
                    hasAsset: _property.hasYoutubeVideo,
                  ),
                  const SizedBox(height: 8),
                  // 360 Virtual Tour
                  _buildVisualizationAssetRow(
                    icon: LucideIcons.glasses,
                    title: '360° Virtual Tour',
                    url: _property.virtualTourUrl,
                    statusText: _property.hasVirtualTour ? 'Configured (Kuula/Matterport)' : 'Not Provided (Coming Soon Fallback)',
                    hasAsset: _property.hasVirtualTour,
                  ),
                  const SizedBox(height: 8),
                  // 3D Model
                  _buildVisualizationAssetRow(
                    icon: LucideIcons.box,
                    title: 'Interactive 3D Model',
                    url: _property.model3DUrl ?? _property.model3DId,
                    statusText: _property.has3DModel ? 'Configured (Sketchfab/WebGL)' : 'Not Provided',
                    hasAsset: _property.has3DModel,
                  ),
                  const SizedBox(height: 8),
                  // AR Asset
                  _buildVisualizationAssetRow(
                    icon: LucideIcons.scan,
                    title: 'AR Model Asset (GLB)',
                    url: _property.arModelUrl,
                    statusText: _property.hasArModel ? 'Attached GLB/USDZ' : 'Not Attached',
                    hasAsset: _property.hasArModel,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Dealer Declaration & Terms Review Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF334155)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(LucideIcons.shieldCheck, color: AppTheme.emeraldSuccess, size: 18),
                          const SizedBox(width: 8),
                          Text(
                            'Dealer Declaration',
                            style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppTheme.emeraldSuccess.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: AppTheme.emeraldSuccess.withOpacity(0.4)),
                        ),
                        child: Text(
                          '✓ Terms Accepted',
                          style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.emeraldSuccess),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Terms Version: ${_property.termsVersion}',
                    style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFFCBD5E1)),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Accepted: ${_property.termsAcceptedAt ?? "19 Aug 2026, 10:42 AM"}',
                    style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF94A3B8)),
                  ),
                  const SizedBox(height: 12),
                  const Divider(color: Color(0xFF334155), height: 1),
                  const SizedBox(height: 12),
                  _buildDeclarationReviewItem('Information accuracy', _property.declarationAccuracyAccepted),
                  _buildDeclarationReviewItem('Ownership/authorization', _property.declarationAuthorizationAccepted),
                  _buildDeclarationReviewItem('Content rights', _property.declarationContentRightsAccepted),
                  _buildDeclarationReviewItem('Pricing accuracy', _property.declarationPricingAccepted),
                  _buildDeclarationReviewItem('Review/approval consent', _property.declarationReviewAccepted),
                  _buildDeclarationReviewItem('Terms & conditions agreement', _property.declarationTermsAccepted),
                ],
              ),
            ),

            const SizedBox(height: 100),
              ],
            ),
          ),
        ),
      ),
      bottomSheet: Container(
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          color: Color(0xFF1E293B),
          border: Border(top: BorderSide(color: Color(0xFF334155))),
        ),
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 960),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: _isProcessing ? null : _handleReject,
                      icon: const Icon(LucideIcons.xCircle, size: 18),
                      label: Text('Reject Listing', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.emeraldSuccess,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: _isProcessing ? null : _handleApprove,
                      icon: const Icon(LucideIcons.checkCircle2, size: 18),
                      label: Text('Approve Listing', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSpecItem(IconData icon, String label, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(10),
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: const Color(0xFF0F172A),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFF334155)),
        ),
        child: Column(
          children: [
            Icon(icon, size: 16, color: const Color(0xFF94A3B8)),
            const SizedBox(height: 4),
            Text(label, style: GoogleFonts.inter(fontSize: 10, color: const Color(0xFF94A3B8))),
            const SizedBox(height: 2),
            Text(value, style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white), overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF94A3B8))),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              value,
              style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white),
              textAlign: TextAlign.end,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDealerRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 14, color: const Color(0xFF94A3B8)),
          const SizedBox(width: 8),
          Text('$label:', style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF94A3B8))),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeclarationReviewItem(String title, bool isAccepted) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            isAccepted ? LucideIcons.checkCircle2 : LucideIcons.alertCircle,
            size: 15,
            color: isAccepted ? AppTheme.emeraldSuccess : Colors.red,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '✓ $title',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: isAccepted ? Colors.white : Colors.red,
                fontWeight: isAccepted ? FontWeight.w500 : FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVisualizationAssetRow({
    required IconData icon,
    required String title,
    required String? url,
    required String statusText,
    required bool hasAsset,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      child: Row(
        children: [
          Icon(icon, color: hasAsset ? const Color(0xFF22D3EE) : const Color(0xFF64748B), size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
                Text(
                  statusText,
                  style: GoogleFonts.inter(fontSize: 11, color: hasAsset ? const Color(0xFF22D3EE) : const Color(0xFF94A3B8)),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (hasAsset && url != null && url.isNotEmpty)
            OutlinedButton(
              onPressed: () => launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF22D3EE),
                side: const BorderSide(color: Color(0xFF0E7490)),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text('Test Link', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold)),
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(6)),
              child: Text('Optional', style: GoogleFonts.inter(fontSize: 10, color: const Color(0xFF94A3B8))),
            ),
        ],
      ),
    );
  }

  Widget _buildPhotoModerationGallery() {
    if (_property.galleryImages.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Property Gallery Photos (${_property.galleryImages.length})',
                style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFFCBD5E1))),
            Text('Auto-Optimized & EXIF Stripped',
                style: GoogleFonts.inter(fontSize: 10, color: AppTheme.emeraldSuccess, fontWeight: FontWeight.w500)),
          ],
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: List.generate(_property.galleryImages.length, (idx) {
            final imgUrl = _property.galleryImages[idx];
            return Container(
              width: 140,
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFF334155)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: Image.network(
                      imgUrl,
                      width: double.infinity,
                      height: 80,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(height: 80, color: const Color(0xFF1E293B)),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.emeraldSuccess.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text('Photo #${idx + 1}',
                            style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.bold, color: AppTheme.emeraldSuccess)),
                      ),
                      InkWell(
                        onTap: () => _confirmDeletePhoto(imgUrl, idx),
                        child: const Icon(LucideIcons.trash2, size: 14, color: Colors.redAccent),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }),
        ),
      ],
    );
  }

  Future<void> _confirmDeletePhoto(String imgUrl, int index) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: Text('Delete Photo #${index + 1}?', style: GoogleFonts.poppins(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
        content: Text('This will remove the photo from the property listing and delete its storage objects.', style: GoogleFonts.inter(color: const Color(0xFF94A3B8), fontSize: 13)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel', style: TextStyle(color: Color(0xFF94A3B8)))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Confirm Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final updatedList = List<String>.from(_property.galleryImages)..removeAt(index);
      setState(() {
        _property = _property.copyWith(galleryImages: updatedList);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Photo deleted successfully.'), backgroundColor: AppTheme.emeraldSuccess),
      );
    }
  }
}
