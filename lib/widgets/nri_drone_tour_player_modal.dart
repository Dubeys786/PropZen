import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../models/property.dart';
import '../screens/user_profile_screen.dart';
import '../screens/drone_tour_subscription_screen.dart';
import '../theme/app_theme.dart';
import 'property_3d_model_viewer.dart';
import 'nri_ai_drone_assistant_sheet.dart';

/// Ultra-Premium 4K Aerial Drone Tour Player Modal for All Users with Active Drone Subscription
class NriDroneTourPlayerModal extends StatefulWidget {
  final Property property;

  const NriDroneTourPlayerModal({
    super.key,
    required this.property,
  });

  /// Guarded entry: opens player only if user has active Drone Tour Subscription
  static Future<void> show(BuildContext context, Property property) {
    if (!UserSession.hasActiveDroneAccess) {
      return DroneTourSubscriptionScreen.show(context, returnToProperty: property);
    }

    return showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'NRI Drone Tour Player',
      barrierColor: Colors.black.withOpacity(0.92),
      transitionDuration: const Duration(milliseconds: 320),
      pageBuilder: (ctx, anim1, anim2) {
        return Center(
          child: Material(
            color: Colors.transparent,
            child: NriDroneTourPlayerModal(property: property),
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
  State<NriDroneTourPlayerModal> createState() => _NriDroneTourPlayerModalState();
}

class _NriDroneTourPlayerModalState extends State<NriDroneTourPlayerModal> with SingleTickerProviderStateMixin {
  bool _isPlaying = true;
  double _currentPositionSeconds = 0.0;
  final double _totalDurationSeconds = 165.0; // 2:45 total duration
  int _currentAltitudeMeters = 120;
  double _flightSpeedKmh = 18.5;
  String _compassHeading = '045° NE';
  String _selectedQuality = '4K UHD 60FPS';
  bool _showControls = true;
  Timer? _playbackTimer;
  Timer? _telemetryTimer;
  int _currentSceneIndex = 0;
  bool _isLoading = false;

  late final AnimationController _radarController;

  late final List<String> _aerialScenes;

  @override
  void initState() {
    super.initState();
    _currentAltitudeMeters = widget.property.droneFlightAltitudeMeters > 0
        ? widget.property.droneFlightAltitudeMeters
        : 120;

    // Use property-specific aerial photos/thumbnails as scenes
    final baseImg = widget.property.droneTourThumbnail ?? widget.property.dynamicImageUrl;
    _aerialScenes = [
      baseImg,
      'https://images.unsplash.com/photo-1545324418-cc1a3fa10c00?auto=format&fit=crop&w=1600&q=80',
      'https://images.unsplash.com/photo-1600596542815-ffad4c1539a9?auto=format&fit=crop&w=1600&q=80',
      'https://images.unsplash.com/photo-1512917774080-9991f1c4c750?auto=format&fit=crop&w=1600&q=80',
      'https://images.unsplash.com/photo-1600585154340-be6161a56a0c?auto=format&fit=crop&w=1600&q=80',
    ];

    _radarController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();

    _startPlayback();
    _startTelemetryStream();
  }

  void _startPlayback() {
    _playbackTimer?.cancel();
    _playbackTimer = Timer.periodic(const Duration(milliseconds: 250), (timer) {
      if (_isPlaying && mounted) {
        setState(() {
          _currentPositionSeconds += 0.25;
          if (_currentPositionSeconds >= _totalDurationSeconds) {
            _currentPositionSeconds = 0.0;
          }
          final sceneProgress = (_currentPositionSeconds / _totalDurationSeconds) * _aerialScenes.length;
          _currentSceneIndex = sceneProgress.floor() % _aerialScenes.length;
        });
      }
    });
  }

  void _startTelemetryStream() {
    _telemetryTimer?.cancel();
    _telemetryTimer = Timer.periodic(const Duration(seconds: 2), (t) {
      if (mounted) {
        setState(() {
          final delta = (t.tick % 5) - 2;
          _currentAltitudeMeters = (widget.property.droneFlightAltitudeMeters + delta).clamp(80, 250);
          _flightSpeedKmh = (18.0 + (t.tick % 4) * 1.2).clamp(12.0, 30.0);
          const headings = ['045° NE', '090° E', '135° SE', '180° S', '225° SW', '315° NW', '010° N'];
          _compassHeading = headings[t.tick % headings.length];
        });
      }
    });
  }

  @override
  void dispose() {
    _playbackTimer?.cancel();
    _telemetryTimer?.cancel();
    _radarController.dispose();
    super.dispose();
  }

  String _formatDuration(double seconds) {
    final mins = (seconds ~/ 60).toString().padLeft(2, '0');
    final secs = (seconds.toInt() % 60).toString().padLeft(2, '0');
    return '$mins:$secs';
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isMobile = size.width < 700;
    final points = widget.property.droneAerialPoints.isNotEmpty
        ? widget.property.droneAerialPoints
        : ['Elevation 360°', 'Clubhouse Quad', 'Green Corridor', 'Expressway Connectivity'];

    return Container(
      width: size.width > 1200 ? 1100 : size.width * 0.94,
      height: size.height > 850 ? 750 : size.height * 0.90,
      decoration: BoxDecoration(
        color: const Color(0xFF07090E),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.primaryViolet.withOpacity(0.5), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryViolet.withOpacity(0.25),
            blurRadius: 30,
            spreadRadius: 2,
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // Background 4K Aerial Visual Frame
          Positioned.fill(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 700),
              child: Image.network(
                _aerialScenes[_currentSceneIndex],
                key: ValueKey<int>(_currentSceneIndex),
                fit: BoxFit.cover,
                errorBuilder: (ctx, err, stack) => Container(
                  color: const Color(0xFF0F172A),
                  child: const Center(
                    child: Icon(LucideIcons.video, color: Colors.white24, size: 64),
                  ),
                ),
              ),
            ),
          ),

          // Vignette & Dark Overlay for Supreme Text Contrast
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xD9060810),
                    Colors.transparent,
                    Color(0xE6060810),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: [0.0, 0.45, 1.0],
                ),
              ),
            ),
          ),

          // Grid Overlay Lines (HUD Simulation)
          Positioned.fill(
            child: CustomPaint(
              painter: _DroneTelemetryGridPainter(
                altitude: _currentAltitudeMeters,
                speed: _flightSpeedKmh,
                heading: _compassHeading,
                isMobile: isMobile,
              ),
            ),
          ),

          // Top Header: Property Title, Location, Live Telemetry Badge, Close Button
          Positioned(
            top: 16,
            left: 18,
            right: 18,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE11D48),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 7,
                                  height: 7,
                                  decoration: const BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  'NRI EXCLUSIVE DRONE TOUR',
                                  style: GoogleFonts.inter(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.6),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: Colors.white24),
                            ),
                            child: Text(
                              _selectedQuality,
                              style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.greenAccent),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        widget.property.title,
                        style: GoogleFonts.poppins(
                          fontSize: isMobile ? 16 : 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        '${widget.property.sector}, ${widget.property.city} • Lat: ${widget.property.latitude.toStringAsFixed(4)}, Long: ${widget.property.longitude.toStringAsFixed(4)}',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: const Color(0xFFCBD5E1),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                InkWell(
                  onTap: () => Navigator.of(context).pop(),
                  borderRadius: BorderRadius.circular(30),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white30),
                    ),
                    child: const Icon(LucideIcons.x, color: Colors.white, size: 20),
                  ),
                ),
              ],
            ),
          ),

          // Flight Telemetry HUD (Left side on tablet/desktop)
          if (!isMobile)
            Positioned(
              top: 100,
              left: 20,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.65),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTelemetryRow(LucideIcons.arrowUpCircle, 'Altitude', '$_currentAltitudeMeters m AGL'),
                    const SizedBox(height: 8),
                    _buildTelemetryRow(LucideIcons.gauge, 'Ground Speed', '${_flightSpeedKmh.toStringAsFixed(1)} km/h'),
                    const SizedBox(height: 8),
                    _buildTelemetryRow(LucideIcons.compass, 'Bearing', _compassHeading),
                    const SizedBox(height: 8),
                    _buildTelemetryRow(LucideIcons.satellite, 'GPS Satellites', '18 Locked (RTK Fixed)'),
                  ],
                ),
              ),
            ),

          // Aerial Landmark / Flight Points Selector
          Positioned(
            bottom: isMobile ? 120 : 100,
            left: 18,
            right: 18,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: points.asMap().entries.map((entry) {
                  final idx = entry.key;
                  final pt = entry.value;
                  final isSelected = _currentSceneIndex == (idx % _aerialScenes.length);

                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          _currentSceneIndex = idx % _aerialScenes.length;
                          _currentPositionSeconds = (idx / points.length) * _totalDurationSeconds;
                        });
                      },
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                        decoration: BoxDecoration(
                          color: isSelected ? AppTheme.primaryViolet : Colors.black.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: isSelected ? Colors.white : Colors.white24),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(LucideIcons.video, size: 12, color: isSelected ? Colors.white : const Color(0xFFCBD5E1)),
                            const SizedBox(width: 6),
                            Text(
                              pt,
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                color: isSelected ? Colors.white : const Color(0xFFE2E8F0),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          // Bottom Media Controls Bar
          Positioned(
            bottom: 14,
            left: 18,
            right: 18,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xCC0F172A),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white12),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Progress Slider & Timestamps
                  Row(
                    children: [
                      Text(
                        _formatDuration(_currentPositionSeconds),
                        style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      Expanded(
                        child: SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            activeTrackColor: AppTheme.primaryViolet,
                            inactiveTrackColor: Colors.white24,
                            thumbColor: Colors.white,
                            trackHeight: 3.5,
                            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                            overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
                          ),
                          child: Slider(
                            value: _currentPositionSeconds.clamp(0.0, _totalDurationSeconds),
                            min: 0.0,
                            max: _totalDurationSeconds,
                            onChanged: (val) {
                              setState(() {
                                _currentPositionSeconds = val;
                              });
                            },
                          ),
                        ),
                      ),
                      Text(
                        _formatDuration(_totalDurationSeconds),
                        style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF94A3B8)),
                      ),
                    ],
                  ),

                  // Action Buttons: Play/Pause, Rewind, Fast-forward, 3D Hub Switcher, Fullscreen
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          IconButton(
                            icon: Icon(_isPlaying ? LucideIcons.pause : LucideIcons.play, color: Colors.white, size: 20),
                            onPressed: () => setState(() => _isPlaying = !_isPlaying),
                            tooltip: _isPlaying ? 'Pause' : 'Play',
                          ),
                          IconButton(
                            icon: const Icon(LucideIcons.rotateCcw, color: Color(0xFFCBD5E1), size: 18),
                            onPressed: () {
                              setState(() {
                                _currentPositionSeconds = (_currentPositionSeconds - 10).clamp(0.0, _totalDurationSeconds);
                              });
                            },
                            tooltip: 'Rewind 10s',
                          ),
                          IconButton(
                            icon: const Icon(LucideIcons.rotateCw, color: Color(0xFFCBD5E1), size: 18),
                            onPressed: () {
                              setState(() {
                                _currentPositionSeconds = (_currentPositionSeconds + 10).clamp(0.0, _totalDurationSeconds);
                              });
                            },
                            tooltip: 'Forward 10s',
                          ),
                        ],
                      ),

                      // Exploration Hub Tools
                      Wrap(
                        spacing: 8,
                        children: [
                          if (widget.property.has3DModel)
                            InkWell(
                              onTap: () {
                                Navigator.of(context).pop();
                                Property3DModelViewer.show(context, widget.property);
                              },
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(LucideIcons.box, size: 13, color: Colors.cyanAccent),
                                    const SizedBox(width: 5),
                                    Text('3D Walkthrough', style: GoogleFonts.inter(fontSize: 11, color: Colors.white)),
                                  ],
                                ),
                              ),
                            ),
                          InkWell(
                            onTap: () => NriAiDroneAssistantSheet.show(context, property: widget.property),
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryViolet.withOpacity(0.35),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: AppTheme.primaryViolet),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(LucideIcons.bot, size: 13, color: Colors.white),
                                  const SizedBox(width: 5),
                                  Text('Ask AI ✨', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white)),
                                ],
                              ),
                            ),
                          ),
                          InkWell(
                            onTap: () {
                              setState(() {
                                _selectedQuality = _selectedQuality == '4K UHD 60FPS' ? '1080p 60FPS' : '4K UHD 60FPS';
                              });
                            },
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(LucideIcons.settings, size: 13, color: Color(0xFF94A3B8)),
                                  const SizedBox(width: 4),
                                  Text(_selectedQuality.split(' ')[0], style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFFE2E8F0))),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTelemetryRow(IconData icon, String label, String value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: AppTheme.primaryViolet),
        const SizedBox(width: 7),
        Text(
          '$label: ',
          style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF94A3B8)),
        ),
        Text(
          value,
          style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
        ),
      ],
    );
  }
}

class _DroneTelemetryGridPainter extends CustomPainter {
  final int altitude;
  final double speed;
  final String heading;
  final bool isMobile;

  _DroneTelemetryGridPainter({
    required this.altitude,
    required this.speed,
    required this.heading,
    required this.isMobile,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.06)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    final crossPaint = Paint()
      ..color = AppTheme.primaryViolet.withOpacity(0.4)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    // Center Crosshair
    final cx = size.width / 2;
    final cy = size.height / 2;
    const cl = 20.0;

    canvas.drawLine(Offset(cx - cl, cy), Offset(cx - 6, cy), crossPaint);
    canvas.drawLine(Offset(cx + 6, cy), Offset(cx + cl, cy), crossPaint);
    canvas.drawLine(Offset(cx, cy - cl), Offset(cx, cy - 6), crossPaint);
    canvas.drawLine(Offset(cx, cy + 6), Offset(cx, cy + cl), crossPaint);

    // Subtle Corner Frame Brackets
    const bl = 24.0;
    const pad = 16.0;

    // Top-Left
    canvas.drawLine(const Offset(pad, pad), const Offset(pad + bl, pad), crossPaint);
    canvas.drawLine(const Offset(pad, pad), const Offset(pad, pad + bl), crossPaint);

    // Top-Right
    canvas.drawLine(Offset(size.width - pad, pad), Offset(size.width - pad - bl, pad), crossPaint);
    canvas.drawLine(Offset(size.width - pad, pad), Offset(size.width - pad, pad + bl), crossPaint);

    // Bottom-Left
    canvas.drawLine(Offset(pad, size.height - pad), Offset(pad + bl, size.height - pad), crossPaint);
    canvas.drawLine(Offset(pad, size.height - pad), Offset(pad, size.height - pad - bl), crossPaint);

    // Bottom-Right
    canvas.drawLine(Offset(size.width - pad, size.height - pad), Offset(size.width - pad - bl, size.height - pad), crossPaint);
    canvas.drawLine(Offset(size.width - pad, size.height - pad), Offset(size.width - pad, size.height - pad - bl), crossPaint);
  }

  @override
  bool shouldRepaint(covariant _DroneTelemetryGridPainter oldDelegate) {
    return oldDelegate.altitude != altitude || oldDelegate.speed != speed;
  }
}
