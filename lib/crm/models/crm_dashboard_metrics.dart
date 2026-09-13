/// Aggregated pipeline metrics returned by GET /api/v1/crm/dashboard
class CrmDashboardMetrics {
  final int totalLeads;
  final int newLeads;
  final int contactedLeads;
  final int qualifiedLeads;
  final int followUpsDue;
  final int siteVisits;
  final int convertedLeads;
  final int lostLeads;
  final double conversionRate;

  const CrmDashboardMetrics({
    this.totalLeads = 0,
    this.newLeads = 0,
    this.contactedLeads = 0,
    this.qualifiedLeads = 0,
    this.followUpsDue = 0,
    this.siteVisits = 0,
    this.convertedLeads = 0,
    this.lostLeads = 0,
    this.conversionRate = 0.0,
  });

  factory CrmDashboardMetrics.fromJson(Map<String, dynamic> json) {
    int parseInt(dynamic val) {
      if (val == null) return 0;
      if (val is int) return val;
      return int.tryParse(val.toString()) ?? 0;
    }

    double parseDouble(dynamic val) {
      if (val == null) return 0.0;
      if (val is num) return val.toDouble();
      return double.tryParse(val.toString()) ?? 0.0;
    }

    return CrmDashboardMetrics(
      totalLeads: parseInt(json['totalLeads']),
      newLeads: parseInt(json['newLeads']),
      contactedLeads: parseInt(json['contactedLeads']),
      qualifiedLeads: parseInt(json['qualifiedLeads']),
      followUpsDue: parseInt(json['followUpsDue']),
      siteVisits: parseInt(json['siteVisits']),
      convertedLeads: parseInt(json['convertedLeads']),
      lostLeads: parseInt(json['lostLeads']),
      conversionRate: parseDouble(json['conversionRate']),
    );
  }

  static const CrmDashboardMetrics zero = CrmDashboardMetrics();
}
