import 'dart:convert';
import 'package:http/http.dart' as http;

class TelebirrService {
  // Credentials
  static const String merchantAppId = "1577254329062408";
  static const String fabricAppId = "c4182ef8-9249-458a-985e-06d191f4d505";
  static const String appSecret = "fad0f06383c6297f545876694b974599";
  static const String shortCode = "826810";

  static const String baseUrl = "https://196.188.120.3:38443/bie/api/v1";

  Future<String?> _getAuthToken() async {
    try {
      final url = Uri.parse('$baseUrl/auth/oauth/token');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json', 'X-APP-Key': fabricAppId},
        body: jsonEncode({"appId": merchantAppId, "appSecret": appSecret}),
      );

      print("Token Response: ${response.body}"); // Token መምጣቱን ለማረጋገጥ

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['accessToken'];
      }
    } catch (e) {
      print("Token Error: $e");
    }
    return null;
  }

  Future<bool> makePayment({
    required String phoneNumber,
    required String amount,
    required String orderId,
  }) async {
    String? token = await _getAuthToken();
    if (token == null) {
      print("Token አልተገኘም!");
      return false;
    }

    try {
      final url = Uri.parse('$baseUrl/toPay');

      final Map<String, dynamic> requestBody = {
        "appid": merchantAppId,
        "sign": "SANDBOX_SIGN_VALUE",
        "ussd": {
          "shortCode": shortCode,
          "receiveName": "Bahir Dar Smart Tax",
          "returnUrl": "http://localhost",
          "notifyUrl": "http://localhost/callback",
          "subject": "Tax Payment",
          "totalAmount": amount,
          "outTradeNo": orderId,
          "timeoutExpress": "30m",
        },
      };

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json', 'Authorization': token},
        body: jsonEncode(requestBody),
      );

      print("Payment Response: ${response.body}"); // *** ችግሩን እዚህ ጋር እናየዋለን ***

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        // ክፍያው የተሳካው "code" 200 ሲሆን ብቻ ነው
        if (data['code'] == '200' || data['msg'] == 'Success') {
          return true;
        }
        // ክፍያው ካልተሳካ ግን ሰርቨሩ መልስ ከሰጠ (ለምሳሌ: Insufficient Balance)
        print("Payment Failed Reason: ${data['msg']}");
      }
    } catch (e) {
      print("Payment Request Error: $e");
    }

    return false;
  }
}
