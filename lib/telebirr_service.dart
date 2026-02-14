import 'dart:convert';
import 'package:http/http.dart' as http;

class TelebirrService {
  // ያቀረብካቸው ሚስጥራዊ ቁጥሮች (Credentials)
  static const String merchantAppId = "1577254329062408";
  static const String fabricAppId = "c4182ef8-9249-458a-985e-06d191f4d505";
  static const String appSecret = "fad0f06383c6297f545876694b974599";
  static const String shortCode = "826810";
  
  // የቴሌብር Sandbox URL
  static const String baseUrl = "https://196.188.120.3:38443/bie/api/v1";

  // 1. መጀመሪያ Token ለመቀበል (Authentication)
  Future<String?> _getAuthToken() async {
    try {
      final url = Uri.parse('$baseUrl/auth/oauth/token');
      
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'X-APP-Key': fabricAppId, // Fabric App ID እዚህ ላይ ጥቅም ላይ ይውላል
        },
        body: jsonEncode({
          "appId": merchantAppId,
          "appSecret": appSecret,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['accessToken']; 
      }
    } catch (e) {
      print("Token Error: $e");
    }
    return null;
  }

  // 2. ክፍያ ለመጠየቅ (ApplyFabricToken & Payment)
  Future<bool> makePayment({
    required String phoneNumber,
    required String amount,
    required String orderId,
  }) async {
    String? token = await _getAuthToken();
    if (token == null) return false;

    try {
      final url = Uri.parse('$baseUrl/toPay');
      
      final Map<String, dynamic> requestBody = {
        "appid": merchantAppId,
        "sign": "SANDBOX_SIGN_VALUE", // ለሙከራ ጊዜ ማንኛውንም ጽሁፍ መውሰድ ይችላል
        "ussd": {
          "shortCode": shortCode,
          "receiveName": "Bahir Dar Smart Tax",
          "returnUrl": "http://localhost",
          "notifyUrl": "http://localhost/callback",
          "subject": "Tax Payment",
          "totalAmount": amount,
          "outTradeNo": orderId,
          "timeoutExpress": "30m",
        }
      };

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': token, // የተቀበልነውን Token እዚህ እንጠቀማለን
        },
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        return true; 
      }
    } catch (e) {
      print("Payment Request Error: $e");
    }
    
    return false;
  }
}