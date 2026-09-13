import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/youtube_media_service.dart';
import '../theme/app_theme.dart';

class YouTubePropertyVideoPlayer extends StatefulWidget {
  final String? videoUrl;
  final String? videoId;
  final String propertyTitle;
  final double aspectRatio;
  final bool autoPlayOnTap;

  const YouTubePropertyVideoPlayer({
    super.key,
    this.videoUrl,
    this.videoId,
    this.propertyTitle = 'Property Tour',
    this.aspectRatio = 16 / 9,
    this.autoPlayOnTap = true,
  });

  @override
  State<YouTubePropertyVideoPlayer> createState() => _YouTubePropertyVideoPlayerState();
}

class _YouTubePropertyVideoPlayerState extends State<YouTubePropertyVideoPlayer> {
  bool _isPlaying = false;
  late final YouTubeValidationResult _valResult;

  @override
  void initState() {
    super.initState();
    final input = widget.videoId != null && widget.videoId!.isNotEmpty
        ? widget.videoId
        : widget.videoUrl;
    _valResult = YouTubeMediaService.validateAndExtract(input);
  }

  void _launchYouTube() async {
    if (_valResult.isValid && _valResult.watchUrl != null) {
      final uri = Uri.parse(_valResult.watchUrl!);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.platformDefault);
      }
    }
  }

  void _onPlayTap() {
    setState(() {
      _isPlaying = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    // 1. Invalid or No Video State
    if (!_valResult.isValid || _valResult.videoId == null) {
      return Container(
        height: 180,
        decoration: BoxDecoration(
          color: const Color(0xFF0F172A),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF1E293B)),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.06),
                  shape: BoxShape.circle,
                ),
                child: const Icon(LucideIcons.videoOff, color: Color(0xFF94A3B8), size: 24),
              ),
              const SizedBox(height: 10),
              Text(
                'Video Tour Not Available',
                style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFFF1F5F9)),
              ),
              const SizedBox(height: 4),
              Text(
                'Dealer has not linked a YouTube walk-through for this listing.',
                style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF64748B)),
              ),
            ],
          ),
        ),
      );
    }

    final thumbUrl = _valResult.thumbnailUrl!;

    // 2. Active Play State (Interactive Embed Card or Launch Modal)
    if (_isPlaying) {
      return AspectRatio(
        aspectRatio: widget.aspectRatio,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.4),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Background Poster
                Image.network(
                  thumbUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(color: Colors.black),
                ),
                Container(
                  color: Colors.black.withOpacity(0.75),
                ),
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: const BoxDecoration(
                            color: Color(0xFFFF0000), // YouTube Red
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(LucideIcons.play, color: Colors.white, size: 32),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          widget.propertyTitle,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Official YouTube Video Tour (1080p HD)',
                          style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFFCBD5E1)),
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton.icon(
                          onPressed: _launchYouTube,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFF0000),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          icon: const Icon(LucideIcons.externalLink, size: 16),
                          label: Text('Open in YouTube HD Player', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // 3. Optimized Poster View (Lazy Loaded Thumbnail with Play Overlay)
    return AspectRatio(
      aspectRatio: widget.aspectRatio,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.12),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // High-Res Lazy Poster
              Image.network(
                thumbUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: const Color(0xFF0F172A),
                  child: const Center(
                    child: Icon(LucideIcons.video, color: Colors.white54, size: 40),
                  ),
                ),
              ),

              // Gradient Backdrop
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withOpacity(0.2),
                      Colors.transparent,
                      Colors.black.withOpacity(0.8),
                    ],
                  ),
                ),
              ),

              // Top YouTube Badge
              Positioned(
                top: 14,
                left: 14,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.75),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(LucideIcons.youtube, color: Color(0xFFFF0000), size: 16),
                      const SizedBox(width: 6),
                      Text(
                        'Verified Video Tour',
                        style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ),

              // Center Interactive Play Button
              Center(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _onPlayTap,
                    borderRadius: BorderRadius.circular(50),
                    child: Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF0000).withOpacity(0.92),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFFF0000).withOpacity(0.5),
                            blurRadius: 20,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: const Icon(LucideIcons.play, color: Colors.white, size: 28),
                    ),
                  ),
                ),
              ),

              // Bottom Title & Duration Overlay
              Positioned(
                bottom: 14,
                left: 14,
                right: 14,
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            widget.propertyTitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                          Text(
                            'Click to stream walkthrough',
                            style: GoogleFonts.inter(fontSize: 11, color: Colors.white70),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'HD 1080p',
                        style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: const Color(0xFF38BDF8)),
                      ),
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
