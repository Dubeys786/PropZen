import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../theme/app_theme.dart';
import '../../services/property_state_service.dart';
import '../../models/property.dart';
import '../../routes/app_routes.dart';
import '../services/crm_service.dart';

class CrmPropertiesScreen extends StatefulWidget {
  const CrmPropertiesScreen({super.key});

  @override
  State<CrmPropertiesScreen> createState() => _CrmPropertiesScreenState();
}

class _CrmPropertiesScreenState extends State<CrmPropertiesScreen> {
  final PropertyStateService _propService = PropertyStateService.instance;
  final CrmService _crmService = CrmService.instance;
  List<Property> _properties = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProperties();
  }

  Future<void> _loadProperties() async {
    setState(() => _isLoading = true);
    try {
      final list = _propService.allProperties;
      if (mounted) {
        setState(() {
          _properties = list;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _findMatchingLeads(Property prop) async {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(LucideIcons.sparkles, color: AppTheme.primaryColor, size: 20),
            const SizedBox(width: 8),
            Text('Matching Leads for ${prop.title}', style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: SizedBox(
          width: 500,
          height: 350,
          child: FutureBuilder<CrmLeadPage>(
            future: _crmService.searchLeads(query: prop.city.isNotEmpty ? prop.city : null, size: 10),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              final leads = snapshot.data?.content ?? [];
              if (leads.isEmpty) {
                return Center(
                  child: Text('No matching leads found for this location/budget.', style: GoogleFonts.inter(color: AppTheme.textMuted)),
                );
              }
              return ListView.separated(
                itemCount: leads.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (ctx, i) {
                  final lead = leads[i];
                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                    title: Text(lead.fullName, style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14)),
                    subtitle: Text('${lead.city ?? prop.city} • Budget: ₹${lead.budgetMin ?? 0} - ₹${lead.budgetMax ?? 0} • Status: ${lead.status.label}', style: GoogleFonts.inter(fontSize: 12)),
                    trailing: IconButton(
                      icon: const Icon(LucideIcons.messageSquare, color: Color(0xFF10B981), size: 18),
                      tooltip: 'Share via WhatsApp',
                      onPressed: () {
                        Navigator.pop(ctx);
                        _sharePropertyViaWhatsApp(prop, defaultPhone: lead.phoneNumber);
                      },
                    ),
                  );
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
        ],
      ),
    );
  }

  Future<void> _sharePropertyViaWhatsApp(Property prop, {String? defaultPhone}) async {
    final phoneCtrl = TextEditingController(text: defaultPhone ?? '');
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Share Property via WhatsApp', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Property: ${prop.title}', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
            Text('Price: ${prop.askingPriceCr > 0 ? "₹${prop.askingPriceCr} Cr" : "On Request"} • ${prop.locality}, ${prop.city}', style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textSecondary)),
            const SizedBox(height: 16),
            TextField(
              controller: phoneCtrl,
              decoration: const InputDecoration(
                labelText: 'Lead WhatsApp Number',
                hintText: 'e.g. +91 9876543210',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.phone,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton.icon(
            icon: const Icon(LucideIcons.send, size: 16),
            label: const Text('Send WhatsApp'),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981), foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx, true),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final phone = phoneCtrl.text.replaceAll(RegExp(r'[^0-9]'), '');
      final message = 'Hello! Check out this property on PropZen: *${prop.title}* in ${prop.locality}, ${prop.city}. Asking: ₹${prop.askingPriceCr.toStringAsFixed(2)} Cr. Contact us for private walkthrough!';
      final uri = Uri.parse(phone.isNotEmpty ? 'https://wa.me/$phone?text=${Uri.encodeComponent(message)}' : 'https://wa.me/?text=${Uri.encodeComponent(message)}');
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.pageBackground,
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'CRM Property Portfolio',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Monitor lead velocity, enquiries, and site visit conversions across active listings.',
                      style: GoogleFonts.inter(fontSize: 13, color: AppTheme.textSecondary),
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  icon: const Icon(LucideIcons.plus, size: 16),
                  label: const Text('Post Property'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    elevation: 0,
                  ),
                  onPressed: () => Navigator.of(context).pushNamed(AppRoutes.postProperty),
                ),
              ],
            ),
            const SizedBox(height: 24),

            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor))
                  : _properties.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(LucideIcons.building, size: 48, color: Colors.grey.shade300),
                              const SizedBox(height: 16),
                              Text('No properties in CRM portfolio', style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w700)),
                              const SizedBox(height: 6),
                              Text('Active listings will automatically link to generated CRM leads.', style: GoogleFonts.inter(fontSize: 13, color: AppTheme.textSecondary)),
                            ],
                          ),
                        )
                      : ListView.separated(
                          itemCount: _properties.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 12),
                          itemBuilder: (context, idx) {
                            final prop = _properties[idx];
                            return _buildPropertyCard(prop);
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPropertyCard(Property prop) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.01),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image / Thumbnail
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Container(
              width: 90,
              height: 75,
              color: const Color(0xFFF1F5F9),
              child: prop.imageUrl.isNotEmpty
                  ? Image.network(
                      prop.imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Icon(LucideIcons.home, size: 30, color: Color(0xFF94A3B8)),
                    )
                  : const Icon(LucideIcons.home, size: 30, color: Color(0xFF94A3B8)),
            ),
          ),
          const SizedBox(width: 16),

          // Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        prop.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
                      ),
                    ),
                    Text(
                      prop.askingPriceCr > 0 ? '₹${prop.askingPriceCr.toStringAsFixed(2)} Cr' : 'Price on Request',
                      style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w800, color: AppTheme.primaryColor),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(LucideIcons.mapPin, size: 12, color: Color(0xFF64748B)),
                    const SizedBox(width: 4),
                    Text('${prop.locality}, ${prop.city}', style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textSecondary)),
                    const SizedBox(width: 12),
                    const Icon(LucideIcons.layoutGrid, size: 12, color: Color(0xFF64748B)),
                    const SizedBox(width: 4),
                    Text('${prop.bhk} • ${prop.sqft} sq ft', style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textSecondary)),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        _metricBadge(LucideIcons.messageSquare, 'Enquiries', const Color(0xFF3B82F6)),
                        const SizedBox(width: 8),
                        _metricBadge(LucideIcons.compass, 'Site Visits', const Color(0xFF8B5CF6)),
                        const SizedBox(width: 8),
                        _metricBadge(LucideIcons.checkCircle, 'Verified', const Color(0xFF10B981)),
                      ],
                    ),
                    Row(
                      children: [
                        OutlinedButton.icon(
                          icon: const Icon(LucideIcons.users, size: 12),
                          label: const Text('Find Matching Leads', style: TextStyle(fontSize: 11)),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            side: const BorderSide(color: Color(0xFFCBD5E1)),
                          ),
                          onPressed: () => _findMatchingLeads(prop),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          tooltip: 'Share via WhatsApp',
                          icon: const Icon(LucideIcons.share2, size: 16, color: Color(0xFF10B981)),
                          onPressed: () => _sharePropertyViaWhatsApp(prop),
                        ),
                        const SizedBox(width: 4),
                        OutlinedButton.icon(
                          icon: const Icon(LucideIcons.externalLink, size: 12),
                          label: const Text('View Listing', style: TextStyle(fontSize: 11)),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            side: const BorderSide(color: Color(0xFFCBD5E1)),
                          ),
                          onPressed: () {
                            Navigator.of(context).pushNamed(
                              AppRoutes.propertyDetails,
                              arguments: prop,
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _metricBadge(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 4),
          Text(label, style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600, color: color)),
        ],
      ),
    );
  }
}
