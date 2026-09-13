import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../theme/app_theme.dart';
import '../services/propzen_voice_service.dart';

/// Premium In-App PropZen Video Experience Player & Modal with Professional Voice-Over Audio
class PropzenVideoModal extends StatefulWidget {
  final String? videoUrl;
  final String title;
  final String subtitle;

  const PropzenVideoModal({
    super.key,
    this.videoUrl,
    this.title = 'PropZen Property Experience',
    this.subtitle = 'AI-Powered 4K Architectural Corridor Tour',
  });

  /// Static helper to display the video modal with smooth fade/scale animation
  static Future<void> show(
    BuildContext context, {
    String? videoUrl,
    String? title,
    String? subtitle,
  }) {
    return showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'PropZen Video Player',
      barrierColor: Colors.black.withOpacity(0.85),
      transitionDuration: const Duration(milliseconds: 320),
      pageBuilder: (ctx, anim1, anim2) {
        return Center(
          child: Material(
            color: Colors.transparent,
            child: PropzenVideoModal(
              videoUrl: videoUrl,
              title: title ?? 'PropZen Property Experience',
              subtitle: subtitle ?? 'AI-Powered 4K Architectural Corridor Tour',
            ),
          ),
        );
      },
      transitionBuilder: (ctx, anim, secondaryAnim, child) {
        final curved = CurvedAnimation(parent: anim, curve: Curves.easeOutCubic);
        return ScaleTransition(
          scale: Tween<double>(begin: 0.92, end: 1.0).animate(curved),
          child: FadeTransition(
            opacity: Tween<double>(begin: 0.0, end: 1.0).animate(curved),
            child: child,
          ),
        );
      },
    );
  }

  @override
  State<PropzenVideoModal> createState() => _PropzenVideoModalState();
}

class _PropzenVideoModalState extends State<PropzenVideoModal> with SingleTickerProviderStateMixin {
  bool _isPlaying = true;
  bool _isMuted = false;
  double _volume = 0.8;
  double _playbackPosition = 0.0; // Current second
  final double _totalDuration = 135.0; // 2:15 total duration
  double _playbackSpeed = 1.2; // Default 1.2x playback speed as requested
  Timer? _playbackTimer;
  int _currentSceneIndex = 0;
  bool _isFullscreen = false;
  int _lastNarratedScene = -1;

  late final AnimationController _audioWaveController;

  final List<String> _showcaseScenes = const [
    'https://images.unsplash.com/photo-1600596542815-ffad4c1539a9?auto=format&fit=crop&w=1200&q=80',
    'https://images.unsplash.com/photo-1600585154340-be6161a56a0c?auto=format&fit=crop&w=1200&q=80',
    'https://images.unsplash.com/photo-1600607687939-ce8a6c25118c?auto=format&fit=crop&w=1200&q=80',
    'https://images.unsplash.com/photo-1600566753376-12c8ab7fb75b?auto=format&fit=crop&w=1200&q=80',
    'https://images.unsplash.com/photo-1618221195710-dd6b41faaea6?auto=format&fit=crop&w=1200&q=80',
  ];

  late final List<String> _sceneNarrations;

  @override
  void initState() {
    super.initState();
    _audioWaveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);

    _sceneNarrations = [
      'Welcome to PropZen Property Experience. Explore this property through an immersive visual walkthrough and discover its architecture, interiors, amenities and overall lifestyle experience. With PropZen, finding and experiencing your perfect property becomes smarter, faster and more convenient.',
      'Here is the grand exterior elevation with modern architectural design, earthquake-resistant construction, and landscaped green buffer zones.',
      'Step inside to spacious luxury living areas designed with optimal natural lighting, high ceilings, and designer vitrified flooring.',
      'The gourmet modular kitchen features branded German fittings, ample counter space, soft-close cabinetry, and seamless dining connectivity.',
      'Residents enjoy world-class lifestyle amenities including an infinity swimming pool, private gymnasium, sports courts, and 24/7 gated security.',
    ];

    _startPlaybackTimer();

    // Trigger initial professional consultant voice-over
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _triggerVoiceOverForScene(0);
    });
  }

  void _startPlaybackTimer() {
    _playbackTimer?.cancel();
    // Adjusted interval for 1.2x speed (increments 0.6s every 500ms)
    _playbackTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
      if (_isPlaying) {
        setState(() {
          if (_playbackPosition < _totalDuration) {
            _playbackPosition += 0.5 * _playbackSpeed;
            final newSceneIdx = ((_playbackPosition ~/ 12) % _showcaseScenes.length);
            if (newSceneIdx != _currentSceneIndex) {
              _currentSceneIndex = newSceneIdx;
              _triggerVoiceOverForScene(_currentSceneIndex);
            }
          } else {
            _playbackPosition = 0;
            _currentSceneIndex = 0;
            _triggerVoiceOverForScene(0);
          }
        });
      }
    });
  }

  void _triggerVoiceOverForScene(int sceneIdx) {
    if (_lastNarratedScene == sceneIdx && _playbackPosition > 2) return;
    _lastNarratedScene = sceneIdx;

    if (!_isMuted && _isPlaying) {
      final narrationText = _sceneNarrations[sceneIdx % _sceneNarrations.length];
      PropzenVoiceService.instance.speak(
        narrationText,
        languageCode: 'en-IN',
      );
    }
  }

  @override
  void dispose() {
    _playbackTimer?.cancel();
    _audioWaveController.dispose();
    PropzenVoiceService.instance.stopSpeaking();
    super.dispose();
  }

  void _togglePlayPause() {
    setState(() {
      _isPlaying = !_isPlaying;
      if (!_isPlaying) {
        PropzenVoiceService.instance.stopSpeaking();
      } else if (!_isMuted) {
        _triggerVoiceOverForScene(_currentSceneIndex);
      }
    });
  }

  void _toggleMute() {
    setState(() {
      _isMuted = !_isMuted;
      if (_isMuted) {
        PropzenVoiceService.instance.stopSpeaking();
      } else if (_isPlaying) {
        _triggerVoiceOverForScene(_currentSceneIndex);
      }
    });
  }

  void _seekRelative(double seconds) {
    setState(() {
      _playbackPosition = (_playbackPosition + seconds).clamp(0.0, _totalDuration);
      _currentSceneIndex = ((_playbackPosition ~/ 12) % _showcaseScenes.length);
      _triggerVoiceOverForScene(_currentSceneIndex);
    });
  }

  void _cycleSpeed() {
    setState(() {
      if (_playbackSpeed == 1.0) {
        _playbackSpeed = 1.2;
      } else if (_playbackSpeed == 1.2) {
        _playbackSpeed = 1.5;
      } else {
        _playbackSpeed = 1.0;
      }
    });
  }

  String _formatTime(double totalSec) {
    final mins = (totalSec ~/ 60).toString();
    final secs = (totalSec.toInt() % 60).toString().padLeft(2, '0');
    return '$mins:$secs';
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isMobile = screenWidth < 600;

    final modalWidth = _isFullscreen ? screenWidth : (isMobile ? (screenWidth - 24) : 820.0);
    final modalHeight = _isFullscreen ? screenHeight : (isMobile ? 500.0 : 560.0);
    final currentNarration = _sceneNarrations[_currentSceneIndex % _sceneNarrations.length];

    return Container(
      width: modalWidth,
      height: modalHeight,
      margin: _isFullscreen ? EdgeInsets.zero : const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF0B0F19),
        borderRadius: BorderRadius.circular(_isFullscreen ? 0 : 20),
        border: _isFullscreen ? null : Border.all(color: AppTheme.primaryViolet.withOpacity(0.35), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryViolet.withOpacity(0.25),
            blurRadius: 36,
            spreadRadius: 4,
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.8),
            blurRadius: 24,
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // 1. Modal Top Bar with Title, 4K Badge & Close Action
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: Color(0xFF131828),
              border: Border(bottom: BorderSide(color: Color(0xFF1E293B))),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryViolet.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(LucideIcons.play, color: AppTheme.primaryViolet, size: 14),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              widget.title,
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppTheme.emeraldSuccess.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: AppTheme.emeraldSuccess.withOpacity(0.4)),
                            ),
                            child: Text(
                              '4K HDR',
                              style: GoogleFonts.jetBrainsMono(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.emeraldSuccess,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryViolet.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: AppTheme.primaryViolet.withOpacity(0.4)),
                            ),
                            child: Text(
                              'VOICE AUDIO',
                              style: GoogleFonts.jetBrainsMono(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFFA78BFA),
                              ),
                            ),
                          ),
                        ],
                      ),
                      Text(
                        widget.subtitle,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: const Color(0xFF94A3B8),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Close Video',
                  icon: const Icon(LucideIcons.x, color: Colors.white70, size: 18),
                  onPressed: () {
                    PropzenVoiceService.instance.stopSpeaking();
                    Navigator.of(context).pop();
                  },
                ),
              ],
            ),
          ),

          // 2. Video Player Viewport Container
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Active Scene Image / Video Texture with smooth Crossfade
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 600),
                  child: Image.network(
                    _showcaseScenes[_currentSceneIndex % _showcaseScenes.length],
                    key: ValueKey<int>(_currentSceneIndex),
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                    errorBuilder: (ctx, err, stack) => Container(
                      color: const Color(0xFF0F172A),
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(LucideIcons.video, color: AppTheme.primaryViolet, size: 40),
                            const SizedBox(height: 10),
                            Text(
                              'PropZen 4K Walkthrough',
                              style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                // Cinematic Dark Vignette & Gradient Overlays
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.black.withOpacity(0.65),
                          Colors.transparent,
                          Colors.black.withOpacity(0.88),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ),

                // Center Play / Pause Indicator Button
                Center(
                  child: GestureDetector(
                    onTap: _togglePlayPause,
                    child: Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        gradient: AppTheme.primaryGradient,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primaryViolet.withOpacity(0.5),
                            blurRadius: 20,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Icon(
                        _isPlaying ? LucideIcons.pause : LucideIcons.play,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                  ),
                ),

                // Quick Rewind & Fast-Forward Buttons
                Positioned(
                  left: 20,
                  top: 0,
                  bottom: 0,
                  child: Center(
                    child: IconButton(
                      icon: const Icon(LucideIcons.rotateCcw, color: Colors.white70, size: 22),
                      tooltip: 'Rewind 10s',
                      onPressed: () => _seekRelative(-10),
                    ),
                  ),
                ),
                Positioned(
                  right: 20,
                  top: 0,
                  bottom: 0,
                  child: Center(
                    child: IconButton(
                      icon: const Icon(LucideIcons.rotateCw, color: Colors.white70, size: 22),
                      tooltip: 'Forward 10s',
                      onPressed: () => _seekRelative(10),
                    ),
                  ),
                ),

                // Top Floating Live Status Badge
                Positioned(
                  top: 14,
                  left: 14,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.65),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: _isPlaying ? AppTheme.emeraldSuccess : AppTheme.coralDanger,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _isPlaying ? 'LIVE 4K PREVIEW • ${_playbackSpeed.toStringAsFixed(1)}x' : 'PAUSED',
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Synchronized Professional Voice-Over Subtitle / Caption Overlay
                Positioned(
                  bottom: 12,
                  left: 16,
                  right: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F172A).withOpacity(0.85),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.primaryViolet.withOpacity(0.3)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.5),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        AnimatedBuilder(
                          animation: _audioWaveController,
                          builder: (ctx, _) {
                            return Icon(
                              _isMuted ? LucideIcons.volumeX : LucideIcons.mic,
                              color: _isMuted
                                  ? const Color(0xFF94A3B8)
                                  : Color.lerp(const Color(0xFFA78BFA), Colors.white, _audioWaveController.value),
                              size: 16,
                            );
                          },
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            currentNarration,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Colors.white.withOpacity(0.95),
                              height: 1.35,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 3. Playback Controller & Scrubber Bottom Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: const BoxDecoration(
              color: Color(0xFF131828),
              border: Border(top: BorderSide(color: Color(0xFF1E293B))),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Scrubber Slider
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 3,
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                    overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
                    activeTrackColor: AppTheme.primaryViolet,
                    inactiveTrackColor: Colors.white24,
                    thumbColor: Colors.white,
                  ),
                  child: Slider(
                    value: _playbackPosition.clamp(0.0, _totalDuration),
                    min: 0.0,
                    max: _totalDuration,
                    onChanged: (val) {
                      setState(() {
                        _playbackPosition = val;
                        _currentSceneIndex = ((_playbackPosition ~/ 12) % _showcaseScenes.length);
                        _triggerVoiceOverForScene(_currentSceneIndex);
                      });
                    },
                  ),
                ),

                // Control Action Row
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Row(
                    children: [
                      // Play / Pause Icon
                      IconButton(
                        icon: Icon(
                          _isPlaying ? LucideIcons.pause : LucideIcons.play,
                          color: Colors.white,
                          size: 18,
                        ),
                        onPressed: _togglePlayPause,
                      ),

                      // Timestamp
                      Text(
                        '${_formatTime(_playbackPosition)} / ${_formatTime(_totalDuration)}',
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 11,
                          color: const Color(0xFF94A3B8),
                          fontWeight: FontWeight.w500,
                        ),
                      ),

                      const SizedBox(width: 12),

                      // 1.2x Playback Speed Switcher
                      InkWell(
                        onTap: _cycleSpeed,
                        borderRadius: BorderRadius.circular(6),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E293B),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: AppTheme.primaryViolet.withOpacity(0.4)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(LucideIcons.gauge, size: 12, color: Color(0xFFA78BFA)),
                              const SizedBox(width: 4),
                              Text(
                                '${_playbackSpeed.toStringAsFixed(1)}x',
                                style: GoogleFonts.jetBrainsMono(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Volume / Mute
                      IconButton(
                        tooltip: _isMuted ? 'Unmute Audio' : 'Mute Audio',
                        icon: Icon(
                          _isMuted ? LucideIcons.volumeX : (_volume > 0.5 ? LucideIcons.volume2 : LucideIcons.volume1),
                          color: _isMuted ? const Color(0xFFEF4444) : Colors.white70,
                          size: 18,
                        ),
                        onPressed: _toggleMute,
                      ),

                      // Fullscreen Toggle
                      IconButton(
                        tooltip: _isFullscreen ? 'Exit Fullscreen' : 'Fullscreen',
                        icon: Icon(
                          _isFullscreen ? LucideIcons.minimize2 : LucideIcons.maximize2,
                          color: Colors.white70,
                          size: 18,
                        ),
                        onPressed: () {
                          setState(() {
                            _isFullscreen = !_isFullscreen;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
