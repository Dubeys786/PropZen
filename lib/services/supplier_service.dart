import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../models/supplier_model.dart';

class SupplierService extends ChangeNotifier {
  SupplierService._internal() {
    _initDefaultSuppliers();
  }
  static final SupplierService instance = SupplierService._internal();
  factory SupplierService() => instance;

  final List<SupplierModel> _suppliers = [];
  List<SupplierModel> get suppliers => List.unmodifiable(_suppliers);

  final List<SupplierQuoteRequest> _quoteRequests = [];
  List<SupplierQuoteRequest> get quoteRequests => List.unmodifiable(_quoteRequests);

  void _initDefaultSuppliers() {
    final now = DateTime.now();
    _suppliers.addAll([
      SupplierModel(
        supplierId: 'sup_01_ultratech',
        businessName: 'UltraTech & Ambuja Cement Depot (Noida Expressway)',
        category: SupplierCategory.cement,
        subCategory: 'PPC / OPC 53 Grade Cement',
        description: 'Authorized direct distributor for UltraTech, Ambuja, and ACC cement. Bulk site delivery with test certificates.',
        phone: '+91 98110 54321',
        whatsapp: '919811054321',
        email: 'sales@noidacementsupply.com',
        address: 'Plot 4A, Sector 142 Logistics Corridor',
        locality: 'Sector 142',
        city: 'Noida',
        state: 'Uttar Pradesh',
        pincode: '201305',
        latitude: 28.4980,
        longitude: 77.4180,
        products: ['UltraTech Super Cement', 'Ambuja Kawach Waterproof', 'RMC Ready Mix Concrete M25/M30'],
        priceRange: '₹360 - ₹410 / bag',
        rating: 4.9,
        reviewCount: 58,
        isVerified: true,
        createdAt: now,
        updatedAt: now,
      ),
      SupplierModel(
        supplierId: 'sup_02_jindal_steel',
        businessName: 'Jindal Panther & Tata Tiscon TMT Steel Yard',
        category: SupplierCategory.steel,
        subCategory: 'Fe 550D High Ductility Rebars',
        description: 'Certified primary steel distribution hub with computerized weighbridge and on-demand crane delivery.',
        phone: '+91 98118 77665',
        whatsapp: '919811877665',
        email: 'orders@noidasteel.in',
        address: 'Sector 10 Industrial Zone, Greater Noida West',
        locality: 'Greater Noida Sector 10',
        city: 'Greater Noida',
        state: 'Uttar Pradesh',
        pincode: '201308',
        latitude: 28.6012,
        longitude: 77.4421,
        products: ['Tata Tiscon 550D (8mm - 32mm)', 'Jindal Panther Fe550D', 'Binding Wire (20 Gauge)'],
        priceRange: '₹62,500 / Metric Ton',
        rating: 4.8,
        reviewCount: 42,
        isVerified: true,
        createdAt: now,
        updatedAt: now,
      ),
      SupplierModel(
        supplierId: 'sup_03_somany_tiles',
        businessName: 'Kajaria & Somany Ceramic Gallerie',
        category: SupplierCategory.tiles,
        subCategory: 'Vitrified & Italian Marble Finish Tiles',
        description: 'Large format vitrified tiles, anti-skid bathroom series, and outdoor pavers with wholesale builder pricing.',
        phone: '+91 98712 33445',
        whatsapp: '919871233445',
        email: 'gallerie@somanyncr.com',
        address: 'Sector 63 Commercial Complex, Noida',
        locality: 'Sector 63',
        city: 'Noida',
        state: 'Uttar Pradesh',
        pincode: '201309',
        latitude: 28.6258,
        longitude: 77.3639,
        products: ['GVT 600x1200mm Vitrified', 'Full Body Porcelain Tiles', 'Epoxy Grout & Tile Adhesives'],
        priceRange: '₹45 - ₹120 / sq.ft',
        rating: 4.7,
        reviewCount: 36,
        isVerified: true,
        createdAt: now,
        updatedAt: now,
      ),
      SupplierModel(
        supplierId: 'sup_04_havells_electrical',
        businessName: 'Havells & Polycab Electrical Trade Hub',
        category: SupplierCategory.electrical,
        subCategory: 'FR-LSH Wires, Switchgear & Conduits',
        description: 'Flame retardant low smoke house wires, modular switchboards, distribution panels and smart automation conduits.',
        phone: '+91 98101 22334',
        whatsapp: '919810122334',
        email: 'info@noidaelectric.com',
        address: 'Sector 18 Market, Noida',
        locality: 'Sector 18',
        city: 'Noida',
        state: 'Uttar Pradesh',
        pincode: '201301',
        latitude: 28.5700,
        longitude: 77.3200,
        products: ['Polycab FR Wires 1.5/2.5/4.0 sq.mm', 'Havells Crabtree Switches', 'Schneider MCB Panels'],
        priceRange: '₹₹ (Builder Wholesale)',
        rating: 4.8,
        reviewCount: 29,
        isVerified: true,
        createdAt: now,
        updatedAt: now,
      ),
    ]);
  }

  /// Filters suppliers by category, query, and city
  List<SupplierModel> filterSuppliers({
    SupplierCategory? category,
    String? query,
    String? city,
  }) {
    return _suppliers.where((s) {
      if (category != null && s.category != category) return false;
      if (city != null && city.isNotEmpty && !s.city.toLowerCase().contains(city.toLowerCase())) return false;
      if (query != null && query.trim().isNotEmpty) {
        final q = query.toLowerCase().trim();
        final match = s.businessName.toLowerCase().contains(q) ||
            s.description.toLowerCase().contains(q) ||
            s.locality.toLowerCase().contains(q) ||
            s.products.any((p) => p.toLowerCase().contains(q));
        if (!match) return false;
      }
      return true;
    }).toList();
  }

  /// Submits a quote request to a verified supplier
  Future<String> requestQuote({
    required String supplierId,
    required String userId,
    required String userName,
    required String userPhone,
    required String materialNeeded,
    required String quantity,
    required String siteLocation,
  }) async {
    final reqId = 'quot_${DateTime.now().millisecondsSinceEpoch}';
    final request = SupplierQuoteRequest(
      requestId: reqId,
      supplierId: supplierId,
      userId: userId,
      userName: userName,
      userPhone: userPhone,
      materialNeeded: materialNeeded,
      quantity: quantity,
      siteLocation: siteLocation,
      createdAt: DateTime.now(),
    );
    _quoteRequests.add(request);
    notifyListeners();
    return reqId;
  }
}
