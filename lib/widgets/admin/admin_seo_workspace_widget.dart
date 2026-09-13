import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../models/property.dart';
import '../../models/super_dashboard_seo_models.dart';
import '../../services/property_state_service.dart';
import '../../services/seo_engine_service.dart';
import '../../theme/app_theme.dart';

class AdminSeoWorkspaceWidget extends StatefulWidget {
  const AdminSeoWorkspaceWidget({super.key});

  @override
  State<AdminSeoWorkspaceWidget> createState() => _AdminSeoWorkspaceWidgetState();
}

class _AdminSeoWorkspaceWidgetState extends State<AdminSeoWorkspaceWidget> {
  final SeoEngineService _seoService = SeoEngineService.instance;
  Property? _selectedProperty;

  @override
  void initState() {
    super.initState();
    final props = PropertyStateService.instance.allProperties;
    if (props.isNotEmpty) {
      _selectedProperty = props.first;
    }
  }

  void _copySitemap() {
    final props = PropertyStateService.instance.allProperties;
    final xml = _seoService.generateSitemapXml(props);
    Clipboard.setData(ClipboardData(text: xml));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Sitemap XML copied to clipboard for Google Search Console submission!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final properties = PropertyStateService.instance.allProperties;
    final isDesktop = MediaQuery.of(context).size.width >= 1000;

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: isDesktop ? 40 : 16, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Header Banner & Sitemap Export Action
          _buildHeaderBanner(),

          const SizedBox(height: 20),

          // 2. Property SEO Inspector
          if (properties.isNotEmpty && _selectedProperty != null) _buildPropertySeoInspector(properties),

          const SizedBox(height: 24),

          // 3. SEO Indexing Log Table
          _buildIndexingLogTable(),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildHeaderBanner() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderLight),
        boxShadow: AppTheme.softCardShadow,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('PropZen Technical SEO & Indexing Hub', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(
                  'Automated Open Graph, JSON-LD Schema, Canonical Slugs, XML Sitemaps, and Search Console Submissions.',
                  style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textMuted),
                ),
              ],
            ),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryViolet,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            icon: const Icon(LucideIcons.copy, size: 16, color: Colors.white),
            label: const Text('Export Sitemap XML', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            onPressed: _copySitemap,
          ),
        ],
      ),
    );
  }

  Widget _buildPropertySeoInspector(List<Property> properties) {
    final meta = _seoService.generateSeoMetadataForProperty(_selectedProperty!);

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
              Text('Live Property SEO Preview', style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.bold)),
              DropdownButton<Property>(
                value: _selectedProperty,
                underline: const SizedBox(),
                items: properties.map((p) => DropdownMenuItem(value: p, child: Text(p.title, style: const TextStyle(fontSize: 13)))).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _selectedProperty = val);
                },
              ),
            ],
          ),
          const Divider(height: 20),

          // Google Search Snippet Simulation
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(meta.canonicalUrl, style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF202124))),
                const SizedBox(height: 4),
                Text(meta.metaTitle, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: const Color(0xFF1A0DAB))),
                const SizedBox(height: 4),
                Text(meta.metaDescription, style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF4D5156))),
              ],
            ),
          ),

          const SizedBox(height: 16),
          _buildMetaField('Canonical Slug:', meta.slug),
          _buildMetaField('Open Graph Image:', meta.ogImageUrl),
          _buildMetaField('JSON-LD Schema Type:', 'RealEstateListing + BreadcrumbList'),

          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              icon: const Icon(LucideIcons.send, size: 14, color: AppTheme.primaryViolet),
              label: const Text('Submit Indexing Request', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryViolet)),
              onPressed: () {
                _seoService.recordIndexingRequest(meta.propertyId, meta.canonicalUrl);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Submitted to Google Search Console queue.')),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetaField(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 140, child: Text(label, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textPrimary))),
          Expanded(child: Text(value, style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textMuted))),
        ],
      ),
    );
  }

  Widget _buildIndexingLogTable() {
    return AnimatedBuilder(
      animation: _seoService,
      builder: (context, _) {
        final logs = _seoService.logs;
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
                  const Icon(LucideIcons.fileText, size: 18, color: AppTheme.primaryViolet),
                  const SizedBox(width: 8),
                  Text('Search Console Indexing Logs (seo_indexing_logs)', style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 16),
              ...logs.map((l) => Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppTheme.borderLight),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(l.url, maxLines: 1, overflow: TextOverflow.ellipsis, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold)),
                              Text(l.response ?? 'Queued for sitemap crawl', style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textMuted)),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: l.status == 'INDEXED' ? AppTheme.emeraldSuccess.withOpacity(0.15) : AppTheme.primaryViolet.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(l.status, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: l.status == 'INDEXED' ? AppTheme.emeraldSuccess : AppTheme.primaryViolet)),
                        ),
                      ],
                    ),
                  )),
            ],
          ),
        );
      },
    );
  }
}
