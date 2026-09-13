import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../services/profile_image_picker_service.dart';
import '../services/supabase_service.dart';
import '../services/supabase_storage_service.dart';
import '../screens/user_profile_screen.dart';

class ProfileImagePreviewDialog extends StatefulWidget {
  final Uint8List imageBytes;
  final String fileName;

  const ProfileImagePreviewDialog({
    super.key,
    required this.imageBytes,
    required this.fileName,
  });

  static Future<bool?> show(
    BuildContext context, {
    required Uint8List imageBytes,
    required String fileName,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => ProfileImagePreviewDialog(
        imageBytes: imageBytes,
        fileName: fileName,
      ),
    );
  }

  @override
  State<ProfileImagePreviewDialog> createState() => _ProfileImagePreviewDialogState();
}

class _ProfileImagePreviewDialogState extends State<ProfileImagePreviewDialog> {
  final TransformationController _transformController = TransformationController();
  double _zoom = 1.0;
  bool _isUploading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _transformController.addListener(_onTransformChanged);
  }

  @override
  void dispose() {
    _transformController.removeListener(_onTransformChanged);
    _transformController.dispose();
    super.dispose();
  }

  void _onTransformChanged() {
    final matrix = _transformController.value;
    final scale = matrix.getMaxScaleOnAxis();
    if ((scale - _zoom).abs() > 0.02 && mounted) {
      setState(() {
        _zoom = scale.clamp(1.0, 3.0);
      });
    }
  }

  void _updateZoom(double newZoom) {
    setState(() => _zoom = newZoom.clamp(1.0, 3.0));
    final matrix = Matrix4.identity()..scale(_zoom);
    _transformController.value = matrix;
  }

  void _resetTransform() {
    setState(() => _zoom = 1.0);
    _transformController.value = Matrix4.identity();
  }

  Future<void> _handleSave() async {
    if (_isUploading) return;

    setState(() {
      _isUploading = true;
      _errorMessage = null;
    });

    try {
      // 1. Calculate pan offset and zoom for cropping
      final matrix = _transformController.value;
      final scale = matrix.getMaxScaleOnAxis();
      final translation = matrix.getTranslation();

      // Normalize pan relative to circle diameter (220)
      const viewportSize = 220.0;
      final panXRatio = (-translation.x / viewportSize).clamp(-1.0, 1.0);
      final panYRatio = (-translation.y / viewportSize).clamp(-1.0, 1.0);

      // 2. Crop and optimize to 512x512 crisp avatar
      final optimizedBytes = ProfileImagePickerService.optimizeAvatarImage(
        widget.imageBytes,
        targetDimension: 512,
        zoom: scale,
        panXRatio: panXRatio,
        panYRatio: panYRatio,
      );

      // 3. Resolve user identity
      final userEmailOrPhone = UserSession.email.isNotEmpty
          ? UserSession.email
          : (UserSession.phone.isNotEmpty ? UserSession.phone : 'propzen_user');

      final authUser = SupabaseService.instance.auth.currentUser;
      final effectiveUserId = (authUser != null && authUser.id.isNotEmpty)
          ? authUser.id
          : userEmailOrPhone.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');

      // 4. Upload to Supabase Storage: profile-avatars/{user_id}/avatar.jpg
      final uploadResult = await SupabaseStorageService.instance.uploadAvatar(
        userId: effectiveUserId,
        bytes: optimizedBytes,
        fileName: 'avatar.jpg',
      );

      if (!uploadResult.isSuccess || uploadResult.fileUrl == null) {
        throw Exception(uploadResult.errorMessage ?? 'Storage upload failed');
      }

      final newUrl = uploadResult.fileUrl!;

      // 5. Update avatar_url in profiles table
      final dbSuccess = await SupabaseService.instance.updateUserAvatarUrl(userEmailOrPhone, newUrl);
      if (!dbSuccess) {
        debugPrint('[ProfileImagePreviewDialog] Database avatar update returned false, keeping storage URL in session.');
      }

      // 6. Refresh global session state
      UserSession.avatarUrlNotifier.value = newUrl;

      if (!mounted) return;

      // Close dialog with success
      Navigator.of(context).pop(true);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile picture updated successfully.'),
          backgroundColor: Color(0xFF10B981),
          duration: Duration(seconds: 3),
        ),
      );
    } on SocketException catch (_) {
      if (mounted) {
        setState(() {
          _isUploading = false;
          _errorMessage = 'Upload failed. Please check your internet connection and try again.';
        });
      }
    } catch (e) {
      debugPrint('[ProfileImagePreviewDialog] Upload error: $e');
      if (mounted) {
        final errStr = e.toString().toLowerCase();
        final isNetwork = errStr.contains('socket') || errStr.contains('connection') || errStr.contains('failed to fetch') || errStr.contains('network');
        setState(() {
          _isUploading = false;
          _errorMessage = isNetwork
              ? 'Upload failed. Please check your internet connection and try again.'
              : 'Unable to update profile picture. Please try again.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final dialogWidth = size.width > 500 ? 460.0 : (size.width - 32);
    final cropSize = (dialogWidth - 80).clamp(180.0, 220.0);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: Colors.white,
      elevation: 16,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        width: dialogWidth,
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Profile Image Preview',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                  IconButton(
                    onPressed: _isUploading ? null : () => Navigator.of(context).pop(false),
                    icon: const Icon(LucideIcons.x, size: 20, color: Color(0xFF64748B)),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    tooltip: 'Close',
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Adjust position and zoom to fit inside your profile picture.',
                  style: GoogleFonts.inter(
                    fontSize: 12.5,
                    color: const Color(0xFF64748B),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Interactive Circular Crop Viewport
              Container(
                width: cropSize,
                height: cropSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF0F172A),
                  border: Border.all(
                    color: const Color(0xFF7C3AED),
                    width: 3.0,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF7C3AED).withOpacity(0.28),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipOval(
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      InteractiveViewer(
                        transformationController: _transformController,
                        minScale: 1.0,
                        maxScale: 3.0,
                        boundaryMargin: const EdgeInsets.all(60),
                        child: Center(
                          child: Image.memory(
                            widget.imageBytes,
                            fit: BoxFit.cover,
                            width: cropSize,
                            height: cropSize,
                          ),
                        ),
                      ),
                      // Subtle guidance vignette overlay
                      IgnorePointer(
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white.withOpacity(0.35),
                              width: 1.0,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 18),

              // Controls: Zoom Slider + Reset
              Row(
                children: [
                  const Icon(LucideIcons.zoomOut, size: 16, color: Color(0xFF94A3B8)),
                  Expanded(
                    child: SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        trackHeight: 3.0,
                        activeTrackColor: const Color(0xFF7C3AED),
                        inactiveTrackColor: const Color(0xFFE2E8F0),
                        thumbColor: const Color(0xFF7C3AED),
                        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7.0),
                        overlayShape: const RoundSliderOverlayShape(overlayRadius: 14.0),
                      ),
                      child: Slider(
                        value: _zoom,
                        min: 1.0,
                        max: 3.0,
                        onChanged: _isUploading ? null : _updateZoom,
                      ),
                    ),
                  ),
                  const Icon(LucideIcons.zoomIn, size: 16, color: Color(0xFF94A3B8)),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: _isUploading ? null : _resetTransform,
                    icon: const Icon(LucideIcons.rotateCcw, size: 16, color: Color(0xFF64748B)),
                    tooltip: 'Reset view',
                    padding: const EdgeInsets.all(6),
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),

              Text(
                'Drag to reposition • Pinch or scroll to zoom',
                style: GoogleFonts.inter(
                  fontSize: 11.5,
                  color: const Color(0xFF94A3B8),
                ),
              ),

              // Error Message Banner
              if (_errorMessage != null) ...[
                const SizedBox(height: 14),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFFCA5A5)),
                  ),
                  child: Row(
                    children: [
                      const Icon(LucideIcons.alertCircle, size: 16, color: Color(0xFFEF4444)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: const Color(0xFFB91C1C),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 22),

              // Actions: Cancel & Save Photo
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isUploading ? null : () => Navigator.of(context).pop(false),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        side: const BorderSide(color: Color(0xFFCBD5E1)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(
                        'Cancel',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF475569),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isUploading ? null : _handleSave,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF7C3AED),
                        disabledBackgroundColor: const Color(0xFFA78BFA),
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: _isUploading
                          ? Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const SizedBox(
                                  width: 15,
                                  height: 15,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Uploading...',
                                  style: GoogleFonts.inter(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            )
                          : Text(
                              'Save Photo',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
