import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../models/reporter_models.dart';
import '../theme/app_theme.dart';

class ReporterStudioScreen extends StatefulWidget {
  const ReporterStudioScreen({super.key});

  @override
  State<ReporterStudioScreen> createState() => _ReporterStudioScreenState();
}

class _ReporterStudioScreenState extends State<ReporterStudioScreen> {
  final TextEditingController _topicController = TextEditingController(text: 'Aqua Line Metro Extension to Jewar Airport DPR Finalized');
  final TextEditingController _sourceController = TextEditingController(text: 'Noida Metro Rail Corporation (NMRC) Official Board Release');
  String _category = 'Infrastructure';

  // Generated AI Script State
  bool _isGeneratingScript = false;
  bool _isGeneratingVideo = false;
  ReporterScriptModel? _scriptResult;
  bool _isPublished = false;

  @override
  void dispose() {
    _topicController.dispose();
    _sourceController.dispose();
    super.dispose();
  }

  Future<void> _generateAiScript() async {
    setState(() => _isGeneratingScript = true);
    await Future.delayed(const Duration(milliseconds: 1000));
    if (mounted) {
      setState(() {
        _isGeneratingScript = false;
        _scriptResult = ReporterScriptModel(
          headline: 'Aqua Line Expansion: Direct Connectivity to Jewar Airport',
          shortScript30s: 'NMRC approves DPR for 35 km Aqua Line extension connecting Sector 142 directly with Noida International Airport Jewar. Travel time estimated under 38 minutes.',
          fullScript60s: 'In a major boost for NCR infrastructure, the Noida Metro Rail Corporation board has finalized the Detailed Project Report for the Aqua Line extension. Spanning 35 kilometers with 11 strategic stations along the Expressway, this corridor will link Sector 142 to Jewar Airport, catalyzing substantial appreciation for residential and commercial assets in Sector 150 and Yamuna Expressway.',
          caption: 'NMRC Approves Jewar Metro Extension DPR #NoidaMetro #JewarAirport #RealEstateNews',
          description: 'Official NMRC project update on the 35km metro corridor linking Noida with Jewar.',
          sourceReferences: [_sourceController.text.trim()],
        );
      });
    }
  }

  Future<void> _generateVideoPipeline() async {
    setState(() => _isGeneratingVideo = true);
    await Future.delayed(const Duration(milliseconds: 1500));
    if (mounted) {
      setState(() {
        _isGeneratingVideo = false;
        _isPublished = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Video successfully compiled and PUBLISHED to PropZen Reporter Feed!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.pageBackground,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        title: Text(
          'Admin Reporter Studio',
          style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
        ),
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: AppTheme.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Topic & Source Input Card
            _buildSourceInputCard(),

            const SizedBox(height: 20),

            // 2. AI Multi-Format Script Result Card
            if (_scriptResult != null) _buildScriptPreviewCard(),

            const SizedBox(height: 24),

            // 3. Publishing Controls
            if (_scriptResult != null) _buildPublishControls(),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSourceInputCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderLight),
        boxShadow: AppTheme.softCardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(LucideIcons.newspaper, color: AppTheme.primaryViolet, size: 20),
              const SizedBox(width: 8),
              Text('Topic & Verified Source Information', style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'PropZen Reporter strictly compiles verified data. AI is prohibited from inventing facts.',
            style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textMuted),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _topicController,
            decoration: const InputDecoration(labelText: 'Report Topic / Headline', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 14),
          DropdownButtonFormField<String>(
            value: _category,
            decoration: const InputDecoration(labelText: 'Category', border: OutlineInputBorder()),
            items: ['Infrastructure', 'Noida Updates', 'Greater Noida', 'Real-Estate News', 'Government Announcements', 'PropZen Announcements']
                .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                .toList(),
            onChanged: (v) {
              if (v != null) setState(() => _category = v);
            },
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _sourceController,
            maxLines: 2,
            decoration: const InputDecoration(labelText: 'Verified Source / Authority Citation', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryViolet,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: _isGeneratingScript
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Icon(LucideIcons.sparkles, color: Colors.white),
              label: Text(_isGeneratingScript ? 'Drafting Script with AI...' : 'Generate Multi-Format Scripts', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              onPressed: _isGeneratingScript ? null : _generateAiScript,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScriptPreviewCard() {
    final s = _scriptResult!;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderLight),
        boxShadow: AppTheme.softCardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Generated Script Formats', style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.bold)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: AppTheme.emeraldSuccess.withOpacity(0.15), borderRadius: BorderRadius.circular(6)),
                child: const Text('Verified', style: TextStyle(color: AppTheme.emeraldSuccess, fontSize: 11, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _buildScriptSection('Headline:', s.headline),
          const Divider(height: 20),
          _buildScriptSection('30-Second Reel Script:', s.shortScript30s),
          const Divider(height: 20),
          _buildScriptSection('60-Second In-Depth Script:', s.fullScript60s),
          const Divider(height: 20),
          _buildScriptSection('Social Caption & Tags:', s.caption),
        ],
      ),
    );
  }

  Widget _buildScriptSection(String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.primaryViolet)),
        const SizedBox(height: 4),
        Text(content, style: GoogleFonts.inter(fontSize: 13, color: AppTheme.textPrimary)),
      ],
    );
  }

  Widget _buildPublishControls() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: _isPublished ? AppTheme.emeraldSuccess : AppTheme.coralDanger,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            icon: _isGeneratingVideo
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : Icon(_isPublished ? LucideIcons.checkCheck : LucideIcons.video, color: Colors.white),
            label: Text(
              _isGeneratingVideo
                  ? 'Compiling Video via n8n Pipeline...'
                  : (_isPublished ? 'Published to Reporter Feed (Live)' : 'Generate Video & Publish to Feed'),
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            onPressed: _isGeneratingVideo ? null : _generateVideoPipeline,
          ),
        ),
      ],
    );
  }
}
