import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/supplier_model.dart';
import '../services/supplier_service.dart';
import '../theme/app_theme.dart';

class SupplierDirectoryScreen extends StatefulWidget {
  const SupplierDirectoryScreen({super.key});

  @override
  State<SupplierDirectoryScreen> createState() => _SupplierDirectoryScreenState();
}

class _SupplierDirectoryScreenState extends State<SupplierDirectoryScreen> {
  final SupplierService _supplierService = SupplierService.instance;
  SupplierCategory? _selectedCategory;
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openQuoteDialog(SupplierModel supplier) {
    final materialCtrl = TextEditingController(text: supplier.products.isNotEmpty ? supplier.products.first : '');
    final qtyCtrl = TextEditingController(text: '100 Bags / Metric Units');
    final locCtrl = TextEditingController(text: 'Sector 150 Construction Site, Noida');
    final phoneCtrl = TextEditingController(text: '+91 98765 43210');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.cardWhite,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(left: 20, right: 20, top: 20, bottom: MediaQuery.of(ctx).viewInsets.bottom + 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Request Direct Wholesale Quote', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                IconButton(icon: const Icon(LucideIcons.x, size: 20), onPressed: () => Navigator.pop(ctx)),
              ],
            ),
            Text('Vendor: ${supplier.businessName}', style: GoogleFonts.inter(fontSize: 12, color: AppTheme.primaryViolet, fontWeight: FontWeight.w600)),
            const SizedBox(height: 14),
            TextField(
              controller: materialCtrl,
              decoration: InputDecoration(
                labelText: 'Material / Product',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                prefixIcon: const Icon(LucideIcons.package, size: 18),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: qtyCtrl,
              decoration: InputDecoration(
                labelText: 'Estimated Quantity',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                prefixIcon: const Icon(LucideIcons.scale, size: 18),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: locCtrl,
              decoration: InputDecoration(
                labelText: 'Delivery Site Location',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                prefixIcon: const Icon(LucideIcons.mapPin, size: 18),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryViolet,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(46),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              icon: const Icon(LucideIcons.send, size: 16),
              label: const Text('Submit Quote Request to Vendor', style: TextStyle(fontWeight: FontWeight.bold)),
              onPressed: () {
                _supplierService.requestQuote(
                  supplierId: supplier.supplierId,
                  userId: 'usr_buyer_demo',
                  userName: 'PropZen Builder',
                  userPhone: phoneCtrl.text,
                  materialNeeded: materialCtrl.text,
                  quantity: qtyCtrl.text,
                  siteLocation: locCtrl.text,
                );
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Quote request submitted! The verified vendor will contact you with wholesale pricing.')),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _supplierService,
      builder: (context, _) {
        final list = _supplierService.filterSuppliers(
          category: _selectedCategory,
          query: _searchController.text,
        );

        return Scaffold(
          backgroundColor: AppTheme.pageBackground,
          appBar: AppBar(
            backgroundColor: AppTheme.cardWhite,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(LucideIcons.arrowLeft, color: AppTheme.textPrimary),
              onPressed: () => Navigator.of(context).pop(),
            ),
            title: Text(
              'Construction Marketplace',
              style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
            ),
          ),
          body: Column(
            children: [
              // Search Bar
              Container(
                color: AppTheme.cardWhite,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: TextField(
                  controller: _searchController,
                  onChanged: (v) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: 'Search cement, TMT steel, tiles, contractors...',
                    prefixIcon: const Icon(LucideIcons.search, size: 18, color: AppTheme.textMuted),
                    filled: true,
                    fillColor: AppTheme.surfaceSubtle,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),

              // Categories Filter Strip
              SizedBox(
                height: 48,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: ChoiceChip(
                        label: const Text('All Categories'),
                        selected: _selectedCategory == null,
                        selectedColor: AppTheme.primaryViolet,
                        labelStyle: TextStyle(
                          color: _selectedCategory == null ? Colors.white : AppTheme.textPrimary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                        onSelected: (_) => setState(() => _selectedCategory = null),
                      ),
                    ),
                    ...SupplierCategory.values.map((cat) {
                      final isSel = _selectedCategory == cat;
                      return Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: ChoiceChip(
                          label: Text(cat.displayName),
                          selected: isSel,
                          selectedColor: AppTheme.primaryViolet,
                          labelStyle: TextStyle(
                            color: isSel ? Colors.white : AppTheme.textPrimary,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                          onSelected: (_) => setState(() => _selectedCategory = cat),
                        ),
                      );
                    }),
                  ],
                ),
              ),

              const SizedBox(height: 8),

              // Supplier Results
              Expanded(
                child: list.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(LucideIcons.packageOpen, size: 48, color: AppTheme.textMuted),
                            const SizedBox(height: 12),
                            Text('No verified suppliers found for this category', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textSecondary)),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        itemCount: list.length,
                        itemBuilder: (context, idx) {
                          final sup = list[idx];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppTheme.cardWhite,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: AppTheme.borderLight),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        sup.businessName,
                                        style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                                      ),
                                    ),
                                    if (sup.isVerified)
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: AppTheme.emeraldSuccess.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(LucideIcons.shieldCheck, size: 12, color: AppTheme.emeraldSuccess),
                                            const SizedBox(width: 4),
                                            Text('VERIFIED', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.emeraldSuccess)),
                                          ],
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text('${sup.subCategory} • ${sup.locality}, ${sup.city}', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textSecondary)),
                                const SizedBox(height: 6),
                                Text(sup.description, style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textSecondary)),
                                const SizedBox(height: 10),

                                // Products preview tags
                                Wrap(
                                  spacing: 6,
                                  runSpacing: 4,
                                  children: sup.products.map((p) => Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: AppTheme.surfaceSubtle,
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(p, style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textPrimary)),
                                      )).toList(),
                                ),
                                const SizedBox(height: 12),

                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('Indicative Pricing', style: GoogleFonts.inter(fontSize: 10, color: AppTheme.textMuted)),
                                        Text(sup.priceRange, style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.primaryViolet)),
                                      ],
                                    ),
                                    Row(
                                      children: [
                                        OutlinedButton.icon(
                                          style: OutlinedButton.styleFrom(
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                          ),
                                          icon: const Icon(LucideIcons.messageSquare, size: 14, color: AppTheme.emeraldSuccess),
                                          label: const Text('WhatsApp', style: TextStyle(fontSize: 12, color: AppTheme.emeraldSuccess)),
                                          onPressed: () {
                                            launchUrl(Uri.parse('https://wa.me/${sup.whatsapp}?text=Hi%20${Uri.encodeComponent(sup.businessName)},%20I%20saw%20your%20verified%20listing%20on%20PropZen%20Marketplace.'));
                                          },
                                        ),
                                        const SizedBox(width: 8),
                                        ElevatedButton.icon(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: AppTheme.primaryViolet,
                                            foregroundColor: Colors.white,
                                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                          ),
                                          icon: const Icon(LucideIcons.fileText, size: 14),
                                          label: const Text('Get Quote', style: TextStyle(fontSize: 12)),
                                          onPressed: () => _openQuoteDialog(sup),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}
