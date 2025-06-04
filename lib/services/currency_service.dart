import 'dart:convert';
import 'package:http/http.dart' as http;

class CurrencyService {
  static const String _baseUrl =
      'https://api.exchangerate-api.com/v4/latest/IDR';
  static Map<String, double> _exchangeRates = {};
  static DateTime? _lastFetchTime;

  // Cache exchange rates for 1 hour
  static const Duration _cacheExpiry = Duration(hours: 1);

  static Future<Map<String, double>> getExchangeRates() async {
    final now = DateTime.now();

    // Return cached rates if still valid
    if (_lastFetchTime != null &&
        now.difference(_lastFetchTime!).compareTo(_cacheExpiry) < 0 &&
        _exchangeRates.isNotEmpty) {
      return _exchangeRates;
    }

    try {
      final response = await http.get(Uri.parse(_baseUrl));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final rates = Map<String, double>.from(data['rates']);

        _exchangeRates = {
          'IDR': 1.0,
          'USD': rates['USD'] ?? 0.000067,
          'GBP': rates['GBP'] ?? 0.000053,
        };
        _lastFetchTime = now;

        return _exchangeRates;
      } else {
        throw Exception('Failed to fetch exchange rates');
      }
    } catch (e) {
      // Fallback to default rates if API fails
      _exchangeRates = {
        'IDR': 1.0,
        'USD': 0.000067, // Approximate rate
        'GBP': 0.000053, // Approximate rate
      };
      return _exchangeRates;
    }
  }

  static Future<double> convertFromIDR(
    double idrAmount,
    String targetCurrency,
  ) async {
    final rates = await getExchangeRates();
    final rate = rates[targetCurrency] ?? 1.0;
    return idrAmount * rate;
  }

  static String formatCurrency(double amount, String currencyCode) {
    switch (currencyCode) {
      case 'USD':
        return '\$${amount.toStringAsFixed(2)}';
      case 'GBP':
        return '£${amount.toStringAsFixed(2)}';
      case 'IDR':
        return 'Rp${amount.toStringAsFixed(0)}';
      default:
        return '${amount.toStringAsFixed(2)} $currencyCode';
    }
  }
}
