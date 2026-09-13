import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../models/property.dart';
import '../models/super_dashboard_seo_models.dart';
import 'supabase_service.dart';

class SeoEngineService extends ChangeNotifier {
  SeoEngineService._internal();
  static final SeoEngineService instance = SeoEngineService._internal();
  factory SeoEngineService() => instance;

  final List<SeoIndexingLogModel> _logs = [
    SeoIndexingLogModel(
      id: 'SEO-LOG-001',
      entityId: 'PROP-001',
      url: 'https://propzen.ai/property/mahagun-manorialle-sector-128-noida',
      requestedAt: DateTime.now().subtract(const Duration(hours: 12)),
      status: 'INDEXED',
      response: 'Indexed via Google Search Console Sitemap pipeline',
    ),
    SeoIndexingLogModel(
      id: 'SEO-LOG-002',
      entityId: 'PROP-002',
      url: 'https://propzen.ai/property/ats-homekraft-happy-trails-sector-10-greater-noida',
      requestedAt: DateTime.now().subtract(const Duration(hours: 6)),
      status: 'DISCOVERED',
      response: 'Crawled by Googlebot. Queued for standard index pass.',
    ),
  ];

  List<SeoIndexingLogModel> get logs => List.unmodifiable(_logs);

  // =========================================================================
  // 1. GENERATE DYNAMIC PROPERTY SEO SLUG & METADATA
  // =========================================================================
  PropertySeoMetadataModel generateSeoMetadataForProperty(Property property) {
    final rawSlug = '${property.title}-${property.sector}-${property.city}'
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9\s-]'), '')
        .replaceAll(RegExp(r'\s+'), '-');

    final cleanSlug = '/property/$rawSlug';
    final canonicalUrl = 'https://propzen.ai$cleanSlug';
    final title = '${property.title} in ${property.sector}, ${property.city} | PropZen AI Real Estate';
    final description = 'Explore ${property.title} (${property.bhk}) in ${property.sector}, ${property.city}. Asking ₹${property.askingPriceCr} Cr, ${property.sqft} sq.ft. Verified RERA, AI Risk Score ${property.intelligenceScore}/100, live 3D walkthrough.';

    final structuredData = {
      '@context': 'https://schema.org',
      '@type': 'RealEstateListing',
      'name': property.title,
      'description': description,
      'url': canonicalUrl,
      'image': property.imageUrl,
      'offers': {
        '@type': 'Offer',
        'price': (property.askingPriceCr * 10000000).toStringAsFixed(0),
        'priceCurrency': 'INR',
        'availability': 'https://schema.org/InStock',
      },
      'address': {
        '@type': 'PostalAddress',
        'addressLocality': property.sector,
        'addressRegion': property.city,
        'addressCountry': 'IN',
      },
      'geo': {
        '@type': 'GeoCoordinates',
        'latitude': property.latitude,
        'longitude': property.longitude,
      },
    };

    return PropertySeoMetadataModel(
      propertyId: property.id,
      slug: cleanSlug,
      metaTitle: title,
      metaDescription: description,
      canonicalUrl: canonicalUrl,
      ogTitle: title,
      ogDescription: description,
      ogImageUrl: property.imageUrl,
      structuredDataJson: structuredData,
      updatedAt: DateTime.now(),
    );
  }

  // =========================================================================
  // 2. GENERATE XML SITEMAP
  // =========================================================================
  String generateSitemapXml(List<Property> properties) {
    final buffer = StringBuffer();
    buffer.writeln('<?xml version="1.0" encoding="UTF-8"?>');
    buffer.writeln('<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">');

    // Static pages
    const staticPages = [
      'https://propzen.ai/',
      'https://propzen.ai/search',
      'https://propzen.ai/loan-advisor',
      'https://propzen.ai/design-studio',
      'https://propzen.ai/reporter-feed',
      'https://propzen.ai/ai-advisor',
    ];

    for (final page in staticPages) {
      buffer.writeln('  <url>');
      buffer.writeln('    <loc>$page</loc>');
      buffer.writeln('    <changefreq>daily</changefreq>');
      buffer.writeln('    <priority>1.0</priority>');
      buffer.writeln('  </url>');
    }

    // Dynamic properties
    for (final p in properties) {
      final meta = generateSeoMetadataForProperty(p);
      buffer.writeln('  <url>');
      buffer.writeln('    <loc>${meta.canonicalUrl}</loc>');
      buffer.writeln('    <lastmod>${DateTime.now().toIso8601String().split('T').first}</lastmod>');
      buffer.writeln('    <changefreq>weekly</changefreq>');
      buffer.writeln('    <priority>0.8</priority>');
      buffer.writeln('  </url>');
    }

    buffer.writeln('</urlset>');
    return buffer.toString();
  }

  // =========================================================================
  // 3. RECORD INDEXING REQUEST
  // =========================================================================
  Future<bool> recordIndexingRequest(String entityId, String url) async {
    final log = SeoIndexingLogModel(
      id: 'SEO-${DateTime.now().millisecondsSinceEpoch}',
      entityId: entityId,
      url: url,
      requestedAt: DateTime.now(),
      status: 'SUBMITTED',
      response: 'Sitemap updated and pinged to Search Console API',
      lastCheckedAt: DateTime.now(),
    );

    _logs.insert(0, log);
    notifyListeners();
    return true;
  }
}
