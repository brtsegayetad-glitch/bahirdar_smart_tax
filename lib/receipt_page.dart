import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

class ReceiptPage extends StatelessWidget {
  final Map<String, String> data;

  const ReceiptPage({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    // 1. QR Code ላይ የሚቀመጠው መረጃ (አዲሶቹን መረጃዎች አካተናል)
    final String qrData =
        "TIN: ${data['tin']}\n"
        "Name: ${data['name']}\n"
        "Group: ${data['group']}\n" // የግብር ዘርፍ
        "Period: ${data['period']}\n" // የክፍያ ዘመን
        "Amount: ${data['amount']} ETB\n"
        "Date: ${DateTime.now().toString().split('.')[0]}";

    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        title: const Text('የክፍያ ደረሰኝ'),
        centerTitle: true,
        backgroundColor:
            Colors.green[700], // ከ Agent page ጋር እንዲሄድ አረንጓዴ አደረግነው
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(25),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.2),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // የባለስልጣኑ አርማ/ስም
                  Icon(Icons.verified, color: Colors.green[700], size: 60),
                  const SizedBox(height: 10),
                  const Text(
                    'የባህር ዳር ከተማ ገቢዎች ባለስልጣን',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const Text(
                    'Bahir Dar City Revenues Authority',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const Divider(height: 30, thickness: 1),

                  // 2. ዋናው መረጃ (አዲሶቹን መስኮች ጨምረናል)
                  _receiptRow('ግብር ከፋይ:', data['name'] ?? ''),
                  _receiptRow('TIN ቁጥር:', data['tin'] ?? ''),
                  const SizedBox(height: 10), // ክፍተት
                  // እዚህ ጋር ነው ለውጡ ያለው
                  _receiptRow('የግብር ዘርፍ:', data['group'] ?? 'N/A'),
                  _receiptRow('የክፍያ ዘመን:', data['period'] ?? 'N/A'),
                  _receiptRow('የክፍያ ዘዴ:', data['method'] ?? 'Cash'),

                  const Divider(height: 25),

                  // የገንዘብ መጠን (ጎላ ብሎ እንዲታይ)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'የተከፈለ መጠን:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        '${data['amount']} ብር',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 22,
                          color: Colors.green[800],
                        ),
                      ),
                    ],
                  ),

                  const Divider(height: 30),

                  const Text(
                    'የክፍያ ማረጋገጫ QR Code',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 10),

                  // 3. QR Code
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[200]!),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: QrImageView(
                      data: qrData,
                      version: QrVersions.auto,
                      size: 160.0,
                    ),
                  ),

                  const SizedBox(height: 20),
                  Text(
                    'ደረሰኝ ቁጥር: BD-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 25),

            // መመለሻ ቁልፍ
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.print),
                label: const Text(
                  'ይህንን ደረሰኝ አትም (Print)',
                  style: TextStyle(fontSize: 16),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[800],
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper Widget
  Widget _receiptRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[700], fontSize: 14)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: Colors.black87,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
