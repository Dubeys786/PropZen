class CrmAnalyticsData {
  final int totalLeads;
  final int totalEnquiries;
  final int totalFollowUps;
  final int totalTasks;
  final int totalCommunications;

  final Map<String, int> leadsByStage;
  final Map<String, int> leadsByStatus;
  final Map<String, int> leadsBySource;
  final Map<String, int> tasksByStatus;

  final double followUpCompletionRate;
  final double taskCompletionRate;
  final double overallConversionRate;

  const CrmAnalyticsData({
    this.totalLeads = 0,
    this.totalEnquiries = 0,
    this.totalFollowUps = 0,
    this.totalTasks = 0,
    this.totalCommunications = 0,
    this.leadsByStage = const {},
    this.leadsByStatus = const {},
    this.leadsBySource = const {},
    this.tasksByStatus = const {},
    this.followUpCompletionRate = 0.0,
    this.taskCompletionRate = 0.0,
    this.overallConversionRate = 0.0,
  });

  factory CrmAnalyticsData.fromJson(Map<String, dynamic> json) {
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

    Map<String, int> parseMap(dynamic map) {
      if (map is! Map) return {};
      final res = <String, int>{};
      map.forEach((k, v) {
        res[k.toString()] = parseInt(v);
      });
      return res;
    }

    return CrmAnalyticsData(
      totalLeads: parseInt(json['totalLeads']),
      totalEnquiries: parseInt(json['totalEnquiries']),
      totalFollowUps: parseInt(json['totalFollowUps']),
      totalTasks: parseInt(json['totalTasks']),
      totalCommunications: parseInt(json['totalCommunications']),
      leadsByStage: parseMap(json['leadsByStage']),
      leadsByStatus: parseMap(json['leadsByStatus']),
      leadsBySource: parseMap(json['leadsBySource']),
      tasksByStatus: parseMap(json['tasksByStatus']),
      followUpCompletionRate: parseDouble(json['followUpCompletionRate']),
      taskCompletionRate: parseDouble(json['taskCompletionRate']),
      overallConversionRate: parseDouble(json['overallConversionRate']),
    );
  }
}
