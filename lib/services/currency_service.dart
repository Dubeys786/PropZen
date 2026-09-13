import 'package:flutter/foundation.dart';
import '../models/nri_model.dart';

class CurrencyService extends ChangeNotifier {
  CurrencyService._internal() {
    _initDefaultRates();
  }
  static final CurrencyService instance = CurrencyService._internal();
  factory CurrencyService() => instance;

  final Map<String, CurrencyRateModel> _rates = {};
  Map<String, CurrencyRateModel> get rates => Map.unmodifiable(_rates);

  String _selectedCurrency = 'INR';
  String get selectedCurrency => _selectedCurrency;

  void _initDefaultRates() {
    final now = DateTime.now();
    _rates['INR'] = CurrencyRateModel(code: 'INR', name: 'Indian Rupee', symbol: '₹', inrRate: 1.0, lastUpdatedAt: now);
    _rates['USD'] = CurrencyRateModel(code: 'USD', name: 'US Dollar', symbol: '\$', inrRate: 86.80, lastUpdatedAt: now);
    _rates['AED'] = CurrencyRateModel(code: 'AED', name: 'UAE Dirham', symbol: 'AED ', inrRate: 23.63, lastUpdatedAt: now);
    _rates['GBP'] = CurrencyRateModel(code: 'GBP', name: 'British Pound', symbol: '£', inrRate: 110.25, lastUpdatedAt: now);
    _rates['EUR'] = CurrencyRateModel(code: 'EUR', name: 'Euro', symbol: '€', inrRate: 92.40, lastUpdatedAt: now);
    _rates['CAD'] = CurrencyRateModel(code: 'CAD', name: 'Canadian Dollar', symbol: 'CA\$', inrRate: 61.20, lastUpdatedAt: now);
    _rates['AUD'] = CurrencyRateModel(code: 'AUD', name: 'Australian Dollar', symbol: 'AU\$', inrRate: 56.30, lastUpdatedAt: now);
    _rates['SGD'] = CurrencyRateModel(code: 'SGD', name: 'Singapore Dollar', symbol: 'SG\$', inrRate: 64.90, lastUpdatedAt: now);
  }

  void setCurrency(String code) {
    if (_rates.containsKey(code)) {
      _selectedCurrency = code;
      notifyListeners();
    }
  }

  /// Converts amount in INR to target currency
  double convertFromInr(double amountInInr, [String? targetCode]) {
    final code = targetCode ?? _selectedCurrency;
    if (code == 'INR') return amountInInr;
    final r = _rates[code];
    if (r == null || r.inrRate == 0) return amountInInr;
    return amountInInr / r.inrRate;
  }

  /// Formats currency with indicative note
  String formatConvertedPrice(double amountInInr, [String? targetCode]) {
    final code = targetCode ?? _selectedCurrency;
    final rate = _rates[code] ?? _rates['INR']!;
    final converted = convertFromInr(amountInInr, code);

    if (code == 'INR') {
      if (amountInInr >= 10000000) {
        return '₹${(amountInInr / 10000000).toStringAsFixed(2)} Cr';
      }
      return '₹${(amountInInr / 100000).toStringAsFixed(1)} Lakh';
    }

    if (converted >= 1000000) {
      return '${rate.symbol}${(converted / 1000000).toStringAsFixed(2)}M ($code)';
    }
    return '${rate.symbol}${(converted / 1000).toStringAsFixed(1)}k ($code)';
  }
}
