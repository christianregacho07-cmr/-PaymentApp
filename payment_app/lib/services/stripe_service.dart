import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/stripe_config.dart';

class StripeService {
  static const Map<String, String> testTokens = {
    '4242424242424242': 'tok_visa',
    '4000000034576934': 'tok_visa_debit',
    '5555555555554444': 'tok_mastercard',
    '5200828282828210': 'tok_mastercard_debit',
    '4000000000000001': 'tok_changeDeclined',
    '4000000000009995': 'tok_chargeDeclinedInsufficientFunds',
  };

  static Future<Map<String, dynamic>> processPayment({
    required String amount,
    required String cardNumber,
    required String expMonth,
    required String expYear,
    required String cvc,
  }) async {
    final doubleAmount = double.tryParse(amount) ?? 0.0;
    final amountInCents = (doubleAmount * 100).round().toString();
    final cleanCard = cardNumber.replaceAll(' ', '');
    final token = testTokens[cleanCard];

    if (token == null) {
      return <String, dynamic> {
        'success': false,
        'error': 'Unknown test card. Use 4242424242424242 for success.',
      };
    }

    try {
      final response = await http.post(
        Uri.parse('${StripeConfig.apiUrl}/payment_intents'),
        headers: <String, String> {
          'Authorization': 'Bearer ${StripeConfig.secretKey}',
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: <String, String> {
          'amount': amountInCents,
          'currency': 'usd',
          'payment_method_data[type]': 'card',
          'payment_method_data[card][token]': token,
          'confirm': 'true',
          'return_url': 'https://example.com',
        },
      );

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode == 200 && data ['status']== 'succeeded') {
        return <String, dynamic> {
          'success': true,
          'id': data['id'].toString(),
          'amount': (data['amount']as num) / 100,
          'status': data['status'].toString(),
        };
      } else {
        final errorMsg = data['error'] is Map ? (data['error']as Map)['message']?.toString() ?? 'Payment Failed': 'Payment Failed';
        return <String, dynamic> {
          'success': false,
          'error': data['error'] != null ? data['error']['message'] : 'Payment failed',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': e.toString()
      };
    }
  }
}



