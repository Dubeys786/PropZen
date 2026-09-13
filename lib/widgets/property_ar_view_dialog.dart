import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/property.dart';
import '../services/ar_capability_helper.dart';
import '../services/property_visualization_service.dart';
import 'property_3d_model_viewer.dart';

enum _ArDialogView {
  instructions,
  modelUnavailable,
  deviceUnsupported,
  cameraPermissionPrompt,
  permissionDenied,
}

class PropertyArViewDialog extends StatefulWidget {
  final Property property;
  final bool isPage;

  const PropertyArViewDialog({
    super.key,
    required this.property,
    this.isPage = false,
  });

  static void show(BuildContext context, Property property) {
    PropertyVisualizationService.instance.logVisualizationEvent(
      eventName: 'ar_view_started',
      propertyId: property.id,
      propertyTitle: property.title,
    );

    showDialog(
      context: context,
      builder: (ctx) => PropertyArViewDialog(property: property),
    );
  }

  @override
  State<PropertyArViewDialog> createState() => _PropertyArViewDialogState();
}

class _PropertyArViewDialogState extends State<PropertyArViewDialog> {
  int _currentInstructionStep = 0;
  bool _isLaunching = false;
  _ArDialogView _currentView = _ArDialogView.instructions;
  bool _cameraPermissionGranted = false;

  final List<Map<String, dynamic>> _steps = [
    {
      'title': 'Find a Flat Surface',
      'desc': 'Point your phone camera toward a flat floor, table, or clear ground area.',
      'icon': LucideIcons.scan,
    },
    {
      'title': 'Scan Surroundings',
      'desc': 'Slowly move your phone in a circular motion until AR anchor points appear.',
      'icon': LucideIcons.smartphone,
    },
    {
      'title': 'Place the Property',
      'desc': 'Tap on the detected plane to anchor the 3D property or plot layout in your room.',
      'icon': LucideIcons.mapPin,
    },
    {
      'title': 'Adjust Scale & Rotation',
      'desc': 'Pinch to switch between 1:1 real-life walk-in scale and 1:50 tabletop overview.',
      'icon': LucideIcons.scaling,
    },
    {
      'title': 'Walk Around & Explore',
      'desc': 'Walk freely around your room to inspect bedrooms, balconies, and spatial flow.',
      'icon': LucideIcons.footprints,
    },
  ];

  Future<void> _handleLaunchArClick() async {
    final prop = widget.property;
    final vizService = PropertyVisualizationService.instance;

    // 1. Verify Property Model: Reject demo models or missing models
    if (!vizService.hasValidArModel(prop)) {
      setState(() => _currentView = _ArDialogView.modelUnavailable);
      return;
    }

    // 2. Verify Device Capability: Desktop browsers cannot perform AR room placement
    if (!vizService.isArSupportedOnCurrentDevice()) {
      setState(() => _currentView = _ArDialogView.deviceUnsupported);
      return;
    }

    // 3. Verify Camera Permission on supported mobile devices
    if (!_cameraPermissionGranted) {
      if (ArCapabilityHelper.hasPermissionDeniedPreviously) {
        setState(() => _currentView = _ArDialogView.permissionDenied);
        return;
      }
      setState(() => _currentView = _ArDialogView.cameraPermissionPrompt);
      return;
    }

    // 4. Permission already acquired -> Launch AR
    await _executeArLaunch();
  }

  Future<void> _requestCameraAndLaunch() async {
    setState(() => _isLaunching = true);

    try {
      final granted = await ArCapabilityHelper.requestCameraPermission();
      if (!mounted) return;

      if (granted) {
        setState(() {
          _cameraPermissionGranted = true;
        });
        await _executeArLaunch();
      } else {
        ArCapabilityHelper.markPermissionDenied();
        setState(() {
          _currentView = _ArDialogView.permissionDenied;
          _isLaunching = false;
        });
      }
    } catch (_) {
      if (mounted) {
        ArCapabilityHelper.markPermissionDenied();
        setState(() {
          _currentView = _ArDialogView.permissionDenied;
          _isLaunching = false;
        });
      }
    }
  }

  Future<void> _executeArLaunch() async {
    final prop = widget.property;
    final glbUrl = prop.arModelUrl;

    if (glbUrl == null || glbUrl.isEmpty || PropertyVisualizationService.isDemoOrUnsafeModelUrl(glbUrl)) {
      if (mounted) {
        setState(() {
          _currentView = _ArDialogView.modelUnavailable;
          _isLaunching = false;
        });
      }
      return;
    }

    final launchUrlStr = PropertyVisualizationService.instance.generateArLaunchUrl(
      glbUrl: glbUrl,
      propertyTitle: prop.title,
    );

    if (launchUrlStr.isEmpty) {
      // Keep user inside PropZen: show device unsupported / in-app 3D fallback
      if (mounted) {
        setState(() {
          _currentView = _ArDialogView.deviceUnsupported;
          _isLaunching = false;
        });
      }
      return;
    }

    try {
      final uri = Uri.parse(launchUrlStr);
      final launched = await launchUrl(uri);
      if (!launched && mounted) {
        setState(() {
          _currentView = _ArDialogView.deviceUnsupported;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _currentView = _ArDialogView.deviceUnsupported;
        });
      }
    } finally {
      if (mounted) setState(() => _isLaunching = false);
    }
  }

  void _open3dViewer() {
    if (!widget.isPage) {
      Navigator.of(context).pop();
    }
    Property3DModelViewer.show(context, widget.property);
  }

  @override
  Widget build(BuildContext context) {
    final prop = widget.property;

    final content = Container(
      constraints: const BoxConstraints(maxWidth: 540),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFF334155)),
        boxShadow: const [
          BoxShadow(color: Color(0x66000000), blurRadius: 24, offset: Offset(0, 8)),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF38BDF8).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(LucideIcons.sparkles, color: Color(0xFF38BDF8), size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'AR Property Placement',
                      style: GoogleFonts.poppins(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    Text(
                      'Experience ${prop.title} in Augmented Reality',
                      style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF94A3B8)),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (!widget.isPage)
                IconButton(
                  icon: const Icon(LucideIcons.x, color: Colors.white70, size: 20),
                  onPressed: () => Navigator.of(context).pop(),
                ),
            ],
          ),
          const SizedBox(height: 20),

            // Main Content depending on current view state
            if (_currentView == _ArDialogView.instructions)
              _buildInstructionsView(prop)
            else if (_currentView == _ArDialogView.modelUnavailable)
              _buildModelUnavailableView(prop)
            else if (_currentView == _ArDialogView.deviceUnsupported)
              _buildDeviceUnsupportedView(prop)
            else if (_currentView == _ArDialogView.cameraPermissionPrompt)
              _buildCameraPermissionPromptView(prop)
            else if (_currentView == _ArDialogView.permissionDenied)
              _buildPermissionDeniedView(prop),
          ],
        ),
      );

    if (widget.isPage) {
      return content;
    }

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: content,
    );
  }

  /// Default 5-Step Instructions View
  Widget _buildInstructionsView(Property prop) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Step Progress Indicator
        Row(
          children: List.generate(
            _steps.length,
            (index) => Expanded(
              child: Container(
                height: 4,
                margin: EdgeInsets.only(right: index < _steps.length - 1 ? 6 : 0),
                decoration: BoxDecoration(
                  color: index <= _currentInstructionStep ? const Color(0xFF38BDF8) : const Color(0xFF334155),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),

        // Active Step Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF38BDF8).withOpacity(0.3)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF38BDF8).withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _steps[_currentInstructionStep]['icon'] as IconData,
                  color: const Color(0xFF38BDF8),
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Step ${_currentInstructionStep + 1}: ${_steps[_currentInstructionStep]['title']}',
                      style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _steps[_currentInstructionStep]['desc'] as String,
                      style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFFCBD5E1), height: 1.35),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Next / Prev Step Controls
        Row(
          children: [
            if (_currentInstructionStep > 0)
              TextButton.icon(
                onPressed: () => setState(() => _currentInstructionStep--),
                icon: const Icon(LucideIcons.arrowLeft, size: 14, color: Colors.white70),
                label: Text('Back', style: GoogleFonts.inter(fontSize: 12, color: Colors.white70)),
              ),
            const Spacer(),
            if (_currentInstructionStep < _steps.length - 1)
              TextButton.icon(
                onPressed: () => setState(() => _currentInstructionStep++),
                label: Text('Next Step', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF38BDF8))),
                icon: const Icon(LucideIcons.arrowRight, size: 14, color: Color(0xFF38BDF8)),
              ),
          ],
        ),
        const SizedBox(height: 12),

        // Action Buttons: Launch AR / Fallback 3D
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _open3dViewer,
                icon: const Icon(LucideIcons.box, size: 16),
                label: const Text('Explore in 3D'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Color(0xFF475569)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _isLaunching ? null : _handleLaunchArClick,
                icon: _isLaunching
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(LucideIcons.view, size: 16),
                label: Text(_isLaunching ? 'Opening...' : 'Launch AR View'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0284C7),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// State: Model Unavailable
  Widget _buildModelUnavailableView(Property prop) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.amber.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(LucideIcons.alertTriangle, color: Colors.amber, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'AR model is currently unavailable for this property.',
                  style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'A 3D architectural AR model has not been uploaded for ${prop.title} yet. You can still inspect the full architectural layout, dimensions, and spaces in our interactive 3D viewer.',
            style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFFCBD5E1), height: 1.4),
          ),
          const SizedBox(height: 20),
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            runSpacing: 10,
            spacing: 10,
            children: [
              TextButton.icon(
                onPressed: () => setState(() => _currentView = _ArDialogView.instructions),
                icon: const Icon(LucideIcons.arrowLeft, size: 14, color: Colors.white70),
                label: Text('Back to Steps', style: GoogleFonts.inter(fontSize: 12, color: Colors.white70)),
              ),
              ElevatedButton.icon(
                onPressed: _open3dViewer,
                icon: const Icon(LucideIcons.box, size: 16),
                label: const Text('Explore in 3D'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0284C7),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// State: Device / Browser Unsupported (e.g. Desktop)
  Widget _buildDeviceUnsupportedView(Property prop) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF38BDF8).withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF38BDF8).withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(LucideIcons.smartphone, color: Color(0xFF38BDF8), size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'AR is not supported on this device/browser.',
                  style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Augmented Reality room placement requires a mobile device with ARCore (Android) or ARKit (iOS) and camera capability. On desktop browsers, please explore the property using our interactive 3D model viewer.',
            style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFFCBD5E1), height: 1.4),
          ),
          const SizedBox(height: 20),
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            runSpacing: 10,
            spacing: 10,
            children: [
              TextButton.icon(
                onPressed: () => setState(() => _currentView = _ArDialogView.instructions),
                icon: const Icon(LucideIcons.arrowLeft, size: 14, color: Colors.white70),
                label: Text('Back to Steps', style: GoogleFonts.inter(fontSize: 12, color: Colors.white70)),
              ),
              ElevatedButton.icon(
                onPressed: _open3dViewer,
                icon: const Icon(LucideIcons.box, size: 16),
                label: const Text('Explore in 3D'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0284C7),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// State: Camera Permission Explanation Prompt
  Widget _buildCameraPermissionPromptView(Property prop) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF38BDF8).withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF38BDF8).withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(LucideIcons.camera, color: Color(0xFF38BDF8), size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Camera Access Required',
                  style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'PropZen needs access to your device camera to detect floors, tables, and open spaces so you can anchor ${prop.title} in your room at real scale.',
            style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFFCBD5E1), height: 1.4),
          ),
          const SizedBox(height: 20),
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            runSpacing: 10,
            spacing: 10,
            children: [
              TextButton.icon(
                onPressed: () => setState(() => _currentView = _ArDialogView.instructions),
                icon: const Icon(LucideIcons.arrowLeft, size: 14, color: Colors.white70),
                label: Text('Back to Steps', style: GoogleFonts.inter(fontSize: 12, color: Colors.white70)),
              ),
              Wrap(
                runSpacing: 8,
                spacing: 8,
                children: [
                  OutlinedButton.icon(
                    onPressed: _open3dViewer,
                    icon: const Icon(LucideIcons.box, size: 14),
                    label: const Text('Explore in 3D'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Color(0xFF475569)),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: _isLaunching ? null : _requestCameraAndLaunch,
                    icon: _isLaunching
                        ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(LucideIcons.checkCircle2, size: 16),
                    label: Text(_isLaunching ? 'Requesting...' : 'Allow Camera'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0284C7),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// State: Camera Permission Denied
  Widget _buildPermissionDeniedView(Property prop) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF43F5E).withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF43F5E).withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(LucideIcons.cameraOff, color: Color(0xFFF43F5E), size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Camera Permission Denied',
                  style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Camera access was denied or is restricted. PropZen needs camera access to place the property in AR. Please enable camera permissions in your browser or device settings.',
            style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFFCBD5E1), height: 1.4),
          ),
          const SizedBox(height: 20),
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            runSpacing: 10,
            spacing: 10,
            children: [
              TextButton.icon(
                onPressed: () => setState(() => _currentView = _ArDialogView.instructions),
                icon: const Icon(LucideIcons.arrowLeft, size: 14, color: Colors.white70),
                label: Text('Back to Steps', style: GoogleFonts.inter(fontSize: 12, color: Colors.white70)),
              ),
              ElevatedButton.icon(
                onPressed: _open3dViewer,
                icon: const Icon(LucideIcons.box, size: 16),
                label: const Text('Explore in 3D'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0284C7),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

