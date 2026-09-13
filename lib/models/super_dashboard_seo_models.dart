class PlatformOverviewMetrics {
  final int totalUsers;
  final int activeUsers;
  final int totalDealers;
  final int verifiedDealers;
  final int pendingDealers;
  final int totalProperties;
  final int liveProperties;
  final int pendingProperties;
  final int rejectedProperties;
  final int verifiedProperties;
  final int totalEnquiries;
  final int totalSiteVisits;
  final int totalLeads;
  final int convertedLeads;
  final double totalRevenueInr;
  final int walletTransactionsCount;
  final double conversionRatePercent;

  const PlatformOverviewMetrics({
    required this.totalUsers,
    required this.activeUsers,
    required this.totalDealers,
    required this.verifiedDealers,
    required this.pendingDealers,
    required this.totalProperties,
    required this.liveProperties,
    required this.pendingProperties,
    required this.rejectedProperties,
    required this.verifiedProperties,
    required this.totalEnquiries,
    required this.totalSiteVisits,
    required this.totalLeads,
    required this.convertedLeads,
    required this.totalRevenueInr,
    required this.walletTransactionsCount,
    required this.conversionRatePercent,
  });
}

class CategorySlice {
  final String categoryName;
  final int count;
  final double percentage;

  const CategorySlice({
    required this.categoryName,
    required this.count,
    required this.percentage,
  });
}

class LocationMetric {
  final String sectorOrCity;
  final int propertyCount;
  final double avgPriceCr;

  const LocationMetric({
    required this.sectorOrCity,
    required this.propertyCount,
    required this.avgPriceCr,
  });
}

class MonthlyRevenueDataPoint {
  final String month;
  final double subscriptionRevenue;
  final double walletRechargeRevenue;
  final double leadPurchaseRevenue;

  const MonthlyRevenueDataPoint({
    required this.month,
    required this.subscriptionRevenue,
    required this.walletRechargeRevenue,
    required this.leadPurchaseRevenue,
  });

  double get total => subscriptionRevenue + walletRechargeRevenue + leadPurchaseRevenue;
}

class PropertySeoMetadataModel {
  final String propertyId;
  final String slug;
  final String metaTitle;
  final String metaDescription;
  final String canonicalUrl;
  final String ogTitle;
  final String ogDescription;
  final String ogImageUrl;
  final Map<String, dynamic> structuredDataJson;
  final DateTime updatedAt;

  const PropertySeoMetadataModel({
    required this.propertyId,
    required this.slug,
    required this.metaTitle,
    required this.metaDescription,
    required this.canonicalUrl,
    required this.ogTitle,
    required this.ogDescription,
    required this.ogImageUrl,
    required this.structuredDataJson,
    required this.updatedAt,
  });
}

class SeoIndexingLogModel {
  final String id;
  final String entityType; // property, vendor, locality
  final String entityId;
  final String url;
  final DateTime requestedAt;
  final String status; // PENDING, SUBMITTED, DISCOVERED, INDEXED, ERROR
  final String? response;
  final DateTime? lastCheckedAt;

  const SeoIndexingLogModel({
    required this.id,
    this.entityType = 'property',
    required this.entityId,
    required this.url,
    required this.requestedAt,
    required this.status,
    this.response,
    this.lastCheckedAt,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'entity_type': entityType,
        'entity_id': entityId,
        'url': url,
        'requested_at': requestedAt.toIso8601String(),
        'status': status,
        'response': response,
        'last_checked_at': lastCheckedAt?.toIso8601String(),
      };

  factory SeoIndexingLogModel.fromMap(Map<String, dynamic> map) {
    return SeoIndexingLogModel(
      id: map['id']?.toString() ?? 'SEO-${DateTime.now().millisecondsSinceEpoch}',
      entityType: map['entity_type']?.toString() ?? 'property',
      entityId: map['entity_id']?.toString() ?? '',
      url: map['url']?.toString() ?? 'https://propzen.ai',
      requestedAt: map['requested_at'] != null ? DateTime.tryParse(map['requested_at'].toString()) ?? DateTime.now() : DateTime.now(),
      status: map['status']?.toString() ?? 'SUBMITTED',
      response: map['response']?.toString(),
      lastCheckedAt: map['last_checked_at'] != null ? DateTime.tryParse(map['last_checked_at'].toString()) : null,
    );
  }
}
