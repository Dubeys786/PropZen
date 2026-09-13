/// Payment Record Model for Transaction History and Receipts
class PaymentRecord {
  final String id;
  final String orderId;
  final String userId;
  final String userEmail;
  final String planId;
  final String planName;
  final String tier;
  final double amount;
  final String currency;
  final String status; // 'success', 'failed', 'pending', 'refunded'
  final String provider; // 'razorpay'
  final String? transactionId;
  final DateTime createdAt;

  const PaymentRecord({
    required this.id,
    required this.orderId,
    required this.userId,
    required this.userEmail,
    required this.planId,
    required this.planName,
    this.tier = 'premium',
    required this.amount,
    this.currency = 'INR',
    required this.status,
    this.provider = 'razorpay',
    this.transactionId,
    required this.createdAt,
  });

  bool get isSuccess => status.toLowerCase() == 'success';
  bool get isFailed => status.toLowerCase() == 'failed';
  bool get isPending => status.toLowerCase() == 'pending';
  bool get isRefunded => status.toLowerCase() == 'refunded';

  String get formattedAmount => '₹${amount.toStringAsFixed(0)}';

  String get formattedDate {
    final d = createdAt;
    final day = d.day.toString().padLeft(2, '0');
    final month = d.month.toString().padLeft(2, '0');
    final year = d.year.toString();
    final hour = d.hour.toString().padLeft(2, '0');
    final min = d.minute.toString().padLeft(2, '0');
    return '$day/$month/$year $hour:$min';
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'orderId': orderId,
      'userId': userId,
      'userEmail': userEmail,
      'planId': planId,
      'planName': planName,
      'tier': tier,
      'amount': amount,
      'currency': currency,
      'status': status,
      'provider': provider,
      'transactionId': transactionId,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory PaymentRecord.fromJson(Map<String, dynamic> json) {
    return PaymentRecord(
      id: json['id'] as String? ?? 'pay_${DateTime.now().millisecondsSinceEpoch}',
      orderId: json['orderId'] as String? ?? json['order_id'] as String? ?? '',
      userId: json['userId'] as String? ?? json['user_id'] as String? ?? '',
      userEmail: json['userEmail'] as String? ?? json['user_email'] as String? ?? '',
      planId: json['planId'] as String? ?? json['plan_id'] as String? ?? '',
      planName: json['planName'] as String? ?? json['plan_name'] as String? ?? 'NRI Remote Pass',
      tier: json['tier'] as String? ?? 'premium',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      currency: json['currency'] as String? ?? 'INR',
      status: json['status'] as String? ?? 'pending',
      provider: json['provider'] as String? ?? 'razorpay',
      transactionId: json['transactionId'] as String? ?? json['transaction_id'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}
