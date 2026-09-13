import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../models/property.dart';
import '../models/nri_valuation_models.dart';
import '../services/nri_smart_valuation_service.dart';
import '../services/property_state_service.dart';
import '../theme/app_theme.dart';

class NriSmartValuationScreen extends StatefulWidget {
  final Property? initialProperty;

  const NriSmartValuationScreen({super.key, this.initialProperty});

  @override
  State<NriSmartValuationScreen> createState() => _NriSmartValuationScreenState();
}

class _NriSmartValuationScreenState extends State<NriSmartValuationScreen> {
  final NriSmartValuationService _valuationService = NriSmartValuationService.instance;
  late Property _selectedProperty;
  PropertyValuationReportModel? _report;
  String _selectedScenario = 'Base'; // Conservative, Base, Optimistic
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    final all = PropertyStateService.instance.allProperties;
    _selectedProperty = widget.initialProperty ?? (all.isNotEmpty ? all.first : const Property(
      id: 'PROP-001',
      title: 'Mahagun Manorialle Luxury Residences',
      sector: 'Sector 128',
      locality: 'Sector 128, Noida',
      city: 'Noida',
      askingPriceCr: 3.45,
      bhk: '4 BHK',
      sqft: 2850,
      imageUrl: 'https://images.unsplash.com/photo-1600596542815-ffad4c1539a9?auto=format&fit=crop&w=800&q=80',
    ));

    _loadValuation();
  }

  Future<void> _loadValuation() async {
    setState(() => _isLoading = true);
    final rep = await _valuationService.fetchValuationForProperty(_selectedProperty);
    if (mounted) {
      setState(() {
        _report = rep;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final properties = PropertyStateService.instance.allProperties;
    final isDesktop = MediaQuery.of(context).size.width >= 1000;

    return Scaffold(
      backgroundColor: AppTheme.pageBackground,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        title: Text(
          'NRI Smart Property Valuation',
          style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
        ),
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: AppTheme.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: isDesktop ? 60 : 16, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Property Selector & Header Card
                  _buildPropertyHeaderCard(properties),

                  const SizedBox(height: 24),

                  // 2. Interactive Valuation Trajectory Chart
                  if (_report != null) _buildTrajectoryChartCard(_report!),

                  const SizedBox(height: 24),

                  // 3. Scenario Comparison Matrix Table
                  if (_report != null) _buildScenarioMatrixCard(_report!),

                  const SizedBox(height: 24),

                  // 4. AI Market Rationale & Disclaimers
                  if (_report != null) _buildAiRationaleCard(_report!),

                  const SizedBox(height: 40),
                ],
              ),
            ),
    );
  }

  Widget _buildPropertyHeaderCard(List<Property> properties) {
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
              Text('Asset Intelligence Snapshot', style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.bold)),
              if (properties.isNotEmpty)
                DropdownButton<Property>(
                  value: _selectedProperty,
                  underline: const SizedBox(),
                  items: properties.map((p) => DropdownMenuItem(value: p, child: Text(p.title, style: const TextStyle(fontSize: 12)))).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() => _selectedProperty = val);
                      _loadValuation();
                    }
                  },
                ),
            ],
          ),
          const Divider(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildHeaderMetric('Current Asking', '₹ ${_selectedProperty.askingPriceCr.toStringAsFixed(2)} Cr', AppTheme.primaryViolet),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildHeaderMetric('Area (sq.ft)', '${_selectedProperty.sqft}', AppTheme.textPrimary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildHeaderMetric('Rental Yield', '${_selectedProperty.rentalYieldPercent}% p.a.', AppTheme.emeraldSuccess),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderMetric(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textMuted)),
          const SizedBox(height: 4),
          Text(value, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }

  Widget _buildTrajectoryChartCard(PropertyValuationReportModel report) {
    final currentYear = DateTime.now().year;

    // Determine values according to selected scenario
    double v1y = report.base1yCr;
    double v3y = report.base3yCr;
    double v5y = report.base5yCr;

    if (_selectedScenario == 'Conservative') {
      v1y = report.conservative1yCr;
      v3y = report.conservative3yCr;
      v5y = report.conservative5yCr;
    } else if (_selectedScenario == 'Optimistic') {
      v1y = report.optimistic1yCr;
      v3y = report.optimistic3yCr;
      v5y = report.optimistic5yCr;
    }

    final points = [
      ...report.historicalTrend.map((h) => {'label': h.year, 'val': (h.avgPriceSqft * _selectedProperty.sqft) / 10000000}),
      {'label': '$currentYear (Now)', 'val': report.currentValueCr},
      {'label': '+1Y (${currentYear + 1})', 'val': v1y},
      {'label': '+3Y (${currentYear + 3})', 'val': v3y},
      {'label': '+5Y (${currentYear + 5})', 'val': v5y},
    ];

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
              Text('Historical Trend & Projections', style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.bold)),
              Row(
                children: ['Conservative', 'Base', 'Optimistic'].map((sc) {
                  final isSel = _selectedScenario == sc;
                  return Padding(
                    padding: const EdgeInsets.only(left: 6),
                    child: ChoiceChip(
                      label: Text(sc, style: TextStyle(fontSize: 11, color: isSel ? Colors.white : AppTheme.textPrimary)),
                      selected: isSel,
                      selectedColor: AppTheme.primaryViolet,
                      onSelected: (_) => setState(() => _selectedScenario = sc),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Visual Bar Chart
          SizedBox(
            height: 180,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: points.map((pt) {
                final val = (pt['val'] as double);
                final maxVal = report.optimistic5yCr * 1.1;
                final heightRatio = (val / maxVal).clamp(0.1, 1.0);

                final isFuture = (pt['label'] as String).contains('+');
                final isCurrent = (pt['label'] as String).contains('(Now)');

                return Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text('₹${val.toStringAsFixed(2)}Cr', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 6),
                      Container(
                        height: 120 * heightRatio,
                        width: 24,
                        decoration: BoxDecoration(
                          color: isFuture
                              ? AppTheme.accentEmerald
                              : (isCurrent ? AppTheme.primaryViolet : const Color(0xFF94A3B8)),
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(pt['label'] as String, style: GoogleFonts.inter(fontSize: 9, color: AppTheme.textMuted)),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScenarioMatrixCard(PropertyValuationReportModel report) {
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
          Text('Scenario Comparison Matrix', style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.bold)),
          const SizedBox(height: 14),
          Table(
            border: TableBorder.all(color: AppTheme.borderLight),
            children: [
              TableRow(
                decoration: const BoxDecoration(color: Color(0xFFF8FAFC)),
                children: [
                  _tableCell('Scenario', isHeader: true),
                  _tableCell('1-Year Value', isHeader: true),
                  _tableCell('3-Year Value', isHeader: true),
                  _tableCell('5-Year Value', isHeader: true),
                ],
              ),
              TableRow(
                children: [
                  _tableCell('Conservative (6% YoY)'),
                  _tableCell('₹ ${report.conservative1yCr.toStringAsFixed(2)} Cr'),
                  _tableCell('₹ ${report.conservative3yCr.toStringAsFixed(2)} Cr'),
                  _tableCell('₹ ${report.conservative5yCr.toStringAsFixed(2)} Cr'),
                ],
              ),
              TableRow(
                children: [
                  _tableCell('Base Case (11% YoY)'),
                  _tableCell('₹ ${report.base1yCr.toStringAsFixed(2)} Cr'),
                  _tableCell('₹ ${report.base3yCr.toStringAsFixed(2)} Cr'),
                  _tableCell('₹ ${report.base5yCr.toStringAsFixed(2)} Cr'),
                ],
              ),
              TableRow(
                children: [
                  _tableCell('Optimistic (16% YoY)'),
                  _tableCell('₹ ${report.optimistic1yCr.toStringAsFixed(2)} Cr'),
                  _tableCell('₹ ${report.optimistic3yCr.toStringAsFixed(2)} Cr'),
                  _tableCell('₹ ${report.optimistic5yCr.toStringAsFixed(2)} Cr'),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _tableCell(String text, {bool isHeader = false}) {
    return Padding(
      padding: const EdgeInsets.all(10),
      child: Text(
        text,
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: isHeader ? FontWeight.bold : FontWeight.normal,
          color: isHeader ? AppTheme.textPrimary : AppTheme.textSecondary,
        ),
      ),
    );
  }

  Widget _buildAiRationaleCard(PropertyValuationReportModel report) {
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
              const Icon(LucideIcons.sparkles, size: 18, color: AppTheme.primaryViolet),
              const SizedBox(width: 8),
              Text('AI Market Intelligence & Corridor Rationale', style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 12),
          Text(report.aiExplanation, style: GoogleFonts.inter(fontSize: 13, color: AppTheme.textPrimary)),
          const SizedBox(height: 12),
          Text('Key Assumptions: ${report.assumptions}', style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textMuted)),
          const Divider(height: 24),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: const Color(0xFFFEF3C7), borderRadius: BorderRadius.circular(8)),
            child: Row(
              children: [
                const Icon(LucideIcons.alertTriangle, size: 16, color: Color(0xFFD97706)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    report.disclaimer,
                    style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: const Color(0xFF92400E)),
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
