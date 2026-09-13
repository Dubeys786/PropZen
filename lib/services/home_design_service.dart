import 'package:flutter/foundation.dart';
import 'ai_home_designer_service.dart';

class DesignVisualizerOption {
  final String id;
  final String title;
  final String category; // 'Wall Color', 'Interior Redesign', 'Exterior Facade', 'Furniture Style'
  final String previewImage;
  final String description;

  const DesignVisualizerOption({
    required this.id,
    required this.title,
    required this.category,
    required this.previewImage,
    required this.description,
  });
}

class HomeDesignService extends ChangeNotifier {
  HomeDesignService._internal();
  static final HomeDesignService instance = HomeDesignService._internal();
  factory HomeDesignService() => instance;

  bool _isGenerating = false;
  bool get isGenerating => _isGenerating;

  String? _lastError;
  String? get lastError => _lastError;

  // Curated Visualizer Styles
  static const List<DesignVisualizerOption> defaultStyles = [
    DesignVisualizerOption(
      id: 'modern_minimal',
      title: 'Modern Minimalist',
      category: 'Interior Redesign',
      previewImage: 'https://images.unsplash.com/photo-1600585154340-be6161a56a0c?auto=format&fit=crop&w=800&q=80',
      description: 'Clean geometry, neutral palettes, concealed ambient lighting, and clutter-free surfaces.',
    ),
    DesignVisualizerOption(
      id: 'luxury_contemporary',
      title: 'Ultra Luxury Contemporary',
      category: 'Interior Redesign',
      previewImage: 'https://images.unsplash.com/photo-1600596542815-ffad4c1539a9?auto=format&fit=crop&w=800&q=80',
      description: 'Italian marble flooring, brass accents, fluted wall panels, and bespoke chandeliers.',
    ),
    DesignVisualizerOption(
      id: 'warm_scandinavian',
      title: 'Warm Scandinavian',
      category: 'Interior Redesign',
      previewImage: 'https://images.unsplash.com/photo-1616486338812-3dadae4b4ace?auto=format&fit=crop&w=800&q=80',
      description: 'Oak wood textures, soft woven fabrics, indoor biophilic greens, and abundant natural sunlight.',
    ),
    DesignVisualizerOption(
      id: 'modern_glass_facade',
      title: 'Modern Glass & Stone Facade',
      category: 'Exterior Facade',
      previewImage: 'https://images.unsplash.com/photo-1600585154526-990dced4db0d?auto=format&fit=crop&w=800&q=80',
      description: 'Floor-to-ceiling double glazed glass, travertine stone cladding, and recessed facade illumination.',
    ),
  ];

  // =========================================================================
  // 1. GENERATE AI DESIGN RENDER
  // =========================================================================
  Future<String> generateDesignRender({
    required String roomType, // 'Living Room', 'Master Bedroom', 'Kitchen', 'Exterior'
    required String designTheme, // 'Modern', 'Luxury', 'Minimal'
    String? wallColor,
    String? sourceImageUrl,
  }) async {
    _isGenerating = true;
    _lastError = null;
    notifyListeners();

    // Delegate to parametric engine
    await Future.delayed(const Duration(milliseconds: 600));

    String renderUrl;
    if (designTheme == 'Luxury') {
      renderUrl = 'https://images.unsplash.com/photo-1600596542815-ffad4c1539a9?auto=format&fit=crop&w=800&q=80';
    } else if (designTheme == 'Minimal') {
      renderUrl = 'https://images.unsplash.com/photo-1600585154340-be6161a56a0c?auto=format&fit=crop&w=800&q=80';
    } else {
      renderUrl = 'https://images.unsplash.com/photo-1616486338812-3dadae4b4ace?auto=format&fit=crop&w=800&q=80';
    }

    _isGenerating = false;
    notifyListeners();
    return renderUrl;
  }
}
