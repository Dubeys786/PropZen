import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../models/vendor_monetization_models.dart';
import '../../services/vendor_wallet_lead_service.dart';
import '../../theme/app_theme.dart';

class AdminMonetizationWorkspaceWidget extends StatefulWidget {
  const AdminMonetizationWorkspaceWidget({super.key});

  @override
  State<AdminMonetizationWorkspaceWidget> createState() => _AdminMonetizationWorkspaceWidgetState();
}

class _AdminMonetizationWorkspaceWidgetState extends State<AdminMonetizationWorkspaceWidget> {
  final VendorWalletLeadService _service = VendorWalletLeadService.instance;

  late double _subWeight;
  late double _locWeight;
  late double _catWeight;
  late double _verWeight;
  late double _respWeight;
  late double _rotWeight;
  late double _leadCost;
  late int _timeoutMins;

  @override
  void initState() {
    super.initState();
    final r = _service.rules;
    _subWeight = r.subscriptionWeight;
    _locWeight = r.locationWeight;
    _catWeight = r.categoryWeight;
    _verWeight = r.verificationWeight;
    _respWeight = r.responseRateWeight;
    _rotWeight = r.rotationWeight;
    _leadCost = r.defaultLeadCostInr;
    _timeoutMins = r.leadResponseTimeoutMins;
  }

  void _saveRules() {
    final updated = LeadDistributionRulesModel(
      subscriptionWeight: _subWeight,
      locationWeight: _locWeight,
      categoryWeight: _catWeight,
      verificationWeight: _verWeight,
      responseRateWeight: _respWeight,
      rotationWeight: _rotWeight,
      defaultLeadCostInr: _leadCost,
      leadResponseTimeoutMins: _timeoutMins,
    );

    _service.updateDistributionRules(updated);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Lead distribution scoring weights updated successfully!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 1000;
    final totalWeight = _subWeight + _locWeight + _catWeight + _verWeight + _respWeight + _rotWeight;

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: isDesktop ? 40 : 16, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Card
          Container(
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
                    Text('Fair Lead Distribution Scoring Engine', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: (totalWeight - 1.0).abs() < 0.01 ? AppTheme.emeraldSuccess.withOpacity(0.15) : AppTheme.coralDanger.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Total Weight: ${(totalWeight * 100).toStringAsFixed(0)}%',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: (totalWeight - 1.0).abs() < 0.01 ? AppTheme.emeraldSuccess : AppTheme.coralDanger),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'PropZen distributes leads fairly based on multi-factor scoring rather than selling exclusively to the highest bidder.',
                  style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textMuted),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Sliders Container
          Container(
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
                Text('Distribution Factor Weights', style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                _buildSlider('Subscription Tier Priority', _subWeight, (v) => setState(() => _subWeight = v)),
                _buildSlider('Location Proximity Match', _locWeight, (v) => setState(() => _locWeight = v)),
                _buildSlider('Category Match', _catWeight, (v) => setState(() => _catWeight = v)),
                _buildSlider('Dealer Verification Status', _verWeight, (v) => setState(() => _verWeight = v)),
                _buildSlider('Historical Response Rate', _respWeight, (v) => setState(() => _respWeight = v)),
                _buildSlider('Fair Rotation (Least Recently Assigned)', _rotWeight, (v) => setState(() => _rotWeight = v)),
                const Divider(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Lead Cost (₹)', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 6),
                          DropdownButtonFormField<double>(
                            value: _leadCost,
                            decoration: const InputDecoration(border: OutlineInputBorder()),
                            items: [250.0, 350.0, 500.0, 750.0, 1000.0]
                                .map((c) => DropdownMenuItem(value: c, child: Text('₹ ${c.toStringAsFixed(0)} / lead')))
                                .toList(),
                            onChanged: (v) {
                              if (v != null) setState(() => _leadCost = v);
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Response Timeout', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 6),
                          DropdownButtonFormField<int>(
                            value: _timeoutMins,
                            decoration: const InputDecoration(border: OutlineInputBorder()),
                            items: [15, 30, 60, 120]
                                .map((m) => DropdownMenuItem(value: m, child: Text('$m Minutes')))
                                .toList(),
                            onChanged: (v) {
                              if (v != null) setState(() => _timeoutMins = v);
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryViolet,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: _saveRules,
                    child: const Text('Save Distribution Rules', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildSlider(String label, double val, ValueChanged<double> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600)),
            Text('${(val * 100).toStringAsFixed(0)}%', style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.primaryViolet)),
          ],
        ),
        Slider(
          value: val,
          min: 0.0,
          max: 0.5,
          divisions: 50,
          activeColor: AppTheme.primaryViolet,
          onChanged: onChanged,
        ),
      ],
    );
  }
}
