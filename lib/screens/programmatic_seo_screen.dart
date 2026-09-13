import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../models/seo_content_model.dart';
import '../models/property.dart';
import '../services/seo_content_service.dart';
import '../services/property_state_service.dart';
import '../theme/app_theme.dart';
import '../routes/app_routes.dart';

class ProgrammaticSeoScreen extends StatefulWidget {
  final String location;
  final String city;
  final String? propertyType;

  const ProgrammaticSeoScreen({
    super.key,
    required this.location,
    this.city = 'Noida',
    this.propertyType,
  });

  @override
  State<ProgrammaticSeoScreen> createState() => _ProgrammaticSeoScreenState();
}

class _ProgrammaticSeoScreenState extends State<ProgrammaticSeoScreen> {
  final SeoContentService _seoService = SeoContentService.instance;
  ProgrammaticPageModel? _pageData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPageData();
  }

  Future<void> _loadPageData() async {
    setState(() => _isLoading = true);
    final data = await _seoService.fetchLocationPageData(widget.location, city: widget.city);
    if (mounted) {
      setState(() {
        _pageData = data;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppTheme.pageBackground,
        appBar: AppBar(
          backgroundColor: AppTheme.cardWhite,
          title: Text('Loading Market Intelligence...', style: GoogleFonts.poppins(fontSize: 16, color: AppTheme.textPrimary)),
        ),
        body: const Center(child: CircularProgressIndicator(color: AppTheme.primaryViolet)),
      );
    }

    final p = _pageData!;
    final matchingProperties = PropertyStateService.instance.allProperties
        .where((prop) =>
            prop.sector.toLowerCase().contains(widget.location.toLowerCase()) ||
            prop.city.toLowerCase().contains(widget.city.toLowerCase()))
        .take(4)
        .toList();

    return Scaffold(
      backgroundColor: AppTheme.pageBackground,
      appBar: AppBar(
        backgroundColor: AppTheme.cardWhite,
        elevation: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.primaryViolet.withOpacity(0.08),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: AppTheme.primaryViolet.withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  const Icon(LucideIcons.shieldCheck, size: 14, color: AppTheme.primaryViolet),
                  const SizedBox(width: 4),
                  Text('VERIFIED MARKET DATA', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.primaryViolet)),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.share2, size: 20, color: AppTheme.textSecondary),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Canonical SEO link copied to clipboard!')),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Breadcrumbs
            Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.of(context).pushNamed(AppRoutes.home),
                  child: Text('Home', style: GoogleFonts.inter(fontSize: 12, color: AppTheme.primaryViolet)),
                ),
                Text('  /  ', style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textMuted)),
                Text('Property Rates', style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textSecondary)),
                Text('  /  ', style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textMuted)),
                Text(widget.city, style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textSecondary)),
                Text('  /  ', style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textMuted)),
                Text(widget.location, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
              ],
            ),
            const SizedBox(height: 16),

            // 2. Hero Header Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.surfaceSubtle,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.borderLight),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${widget.location}, ${widget.city}',
                    style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Institutional Real Estate Price Index & Market Trends',
                    style: GoogleFonts.inter(fontSize: 13, color: AppTheme.textSecondary),
                  ),
                  const SizedBox(height: 16),

                  // Key Stats Row
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppTheme.cardWhite,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppTheme.borderLight),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Average Rate', style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textMuted)),
                              const SizedBox(height: 4),
                              Text('₹${p.avgPriceSqft.toStringAsFixed(0)} / sq.ft', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.emeraldSuccess)),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppTheme.cardWhite,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppTheme.borderLight),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('6-Month Trend', style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textMuted)),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(LucideIcons.trendingUp, size: 16, color: AppTheme.emeraldSuccess),
                                  const SizedBox(width: 4),
                                  Text('+${p.trendPercentage}%', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.emeraldSuccess)),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // 3. Locality Trend Summary
            Text('Locality Dynamics & Market Overview', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
            const SizedBox(height: 8),
            Text(
              p.trendSummary,
              style: GoogleFonts.inter(fontSize: 13, color: AppTheme.textSecondary, height: 1.5),
            ),
            const SizedBox(height: 24),

            // 4. Available Verified Properties in Location
            if (matchingProperties.isNotEmpty) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Verified Listings in ${widget.location}', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                  Text('${matchingProperties.length} Available', style: GoogleFonts.inter(fontSize: 12, color: AppTheme.primaryViolet)),
                ],
              ),
              const SizedBox(height: 12),
              ...matchingProperties.map((prop) => Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.cardWhite,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.borderLight),
                    ),
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          prop.imageUrl,
                          width: 60,
                          height: 60,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(width: 60, height: 60, color: AppTheme.surfaceSubtle),
                        ),
                      ),
                      title: Text(prop.title, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
                      subtitle: Text('${prop.bhk} • ₹${prop.askingPriceCr} Cr • ${prop.sector}', style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textSecondary)),
                      trailing: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryViolet,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        onPressed: () {
                          Navigator.of(context).pushNamed(AppRoutes.propertyDetails, arguments: prop);
                        },
                        child: Text('View', style: GoogleFonts.inter(fontSize: 12, color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  )),
              const SizedBox(height: 20),
            ],

            // 5. Frequently Asked Questions (Structured Data)
            Text('Frequently Asked Questions', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
            const SizedBox(height: 12),
            ...p.faqs.map((faq) => Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: AppTheme.cardWhite,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppTheme.borderLight),
                  ),
                  child: ExpansionTile(
                    title: Text(faq.question, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        child: Text(faq.answer, style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textSecondary, height: 1.4)),
                      ),
                    ],
                  ),
                )),
            const SizedBox(height: 24),

            // 6. Seamless Internal Links
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.cardWhite,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.primaryViolet.withOpacity(0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Related Real Estate Tools', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ActionChip(
                        label: Text('Home Loan Calculator', style: GoogleFonts.inter(fontSize: 12, color: AppTheme.primaryViolet)),
                        backgroundColor: AppTheme.primaryViolet.withOpacity(0.08),
                        onPressed: () => Navigator.of(context).pushNamed(AppRoutes.emiCalculator),
                      ),
                      ActionChip(
                        label: Text('AI Property Advisor', style: GoogleFonts.inter(fontSize: 12, color: AppTheme.primaryViolet)),
                        backgroundColor: AppTheme.primaryViolet.withOpacity(0.08),
                        onPressed: () => Navigator.of(context).pushNamed(AppRoutes.aiAdvisor),
                      ),
                      ActionChip(
                        label: Text('Market Intelligence Hub', style: GoogleFonts.inter(fontSize: 12, color: AppTheme.primaryViolet)),
                        backgroundColor: AppTheme.primaryViolet.withOpacity(0.08),
                        onPressed: () => Navigator.of(context).pushNamed(AppRoutes.marketHub),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}
