import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';

class ReceiptPage extends StatelessWidget {
  final Map<String, String> data;

  const ReceiptPage({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    // 1. መረጃዎቹን ማዘጋጀት
    final String name = data['name'] ?? data['fullName'] ?? 'ያልተጠቀሰ';
    final String tin = data['tin'] ?? data['tinNumber'] ?? 'ያልተጠቀሰ';
    final String amount = data['amount'] ?? '0.00';
    final String group = data['group'] ?? data['taxGroup'] ?? 'አጠቃላይ';
    final String period = data['period'] ?? data['taxPeriod'] ?? '2016 ዓ.ም';
    final String method = data['method'] ?? data['paymentMethod'] ?? 'Telebirr';
    final String agent = data['agentName'] ?? 'ኤጀንት 01';

    // ለደረሰኝ ቁጥር የሚሆን ተለዋዋጭ (እዚህ ጋር ተገልጿል)
    final String receiptNo =
        "BD-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}";

    // 2. ለ QR Code የሚሆን ዳታ (Multi-line string)
    final String qrData =
        """
የባህር ዳር ከተማ አስተዳደር ገቢዎች ጽ/ቤት
የክፍያ ማረጋገጫ (Official Receipt)
----------------------------------
ደረሰኝ ቁጥር: $receiptNo
ግብር ከፋይ: $name
የቲን ቁጥር: $tin
የግብር ዘርፍ: $group
የክፍያ ዘመን: $period
የክፍያ ዘዴ: $method
ጠቅላላ ክፍያ: $amount ETB
ሰብሳቢ (Agent): $agent
ቀን: ${DateTime.now().toString().split(' ')[0]}
----------------------------------
VERIFIED ✅
""";

    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        title: const Text('የክፍያ ማረጋገጫ ደረሰኝ'),
        backgroundColor: Colors.green[800],
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {
              final String receiptText =
                  """
📜 የባህር ዳር ገቢዎች ደረሰኝ
ደረሰኝ ቁጥር: $receiptNo
ግብር ከፋይ: $name
TIN: $tin
መጠን: $amount ETB
""";
              Share.share(receiptText);
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[300]!),
                boxShadow: const [
                  BoxShadow(color: Colors.black12, blurRadius: 10),
                ],
              ),
              child: Column(
                children: [
                  _buildHeader(),
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildPaidBadge(),
                        const SizedBox(height: 20),

                        _receiptRow('የግብር ከፋይ ስም:', name, isBold: true),
                        _receiptRow('የቲን (TIN) ቁጥር:', tin, isBold: true),
                        const Divider(),
                        _receiptRow('የግብር ዘርፍ:', group),
                        _receiptRow('የክፍያ ዘመን:', period),
                        _receiptRow('የክፍያ ዘዴ:', method),
                        _receiptRow('ሰብሳቢ (Agent):', agent),

                        const SizedBox(height: 20),
                        _buildAmountBox(amount),

                        const SizedBox(height: 30),

                        Center(
                          child: Column(
                            children: [
                              QrImageView(
                                data: qrData,
                                size: 180,
                              ), // መረጃው ስለበዛ መጠኑን ጨምሬዋለሁ
                              const SizedBox(height: 10),
                              Text(
                                'ደረሰኝ ቁጥር: $receiptNo',
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 20),
                        const Center(
                          child: Text(
                            'ይህ ደረሰኝ በሲስተም የተዘጋጀ በመሆኑ ያለ ማህተም የጸና ነው::',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(15),
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.green[50],
        borderRadius: const BorderRadius.only(
          topRight: Radius.circular(12),
          topLeft: Radius.circular(12),
        ),
      ),
      child: Column(
        children: [
          const Text(
            'የአማራ ብሔራዊ ክልላዊ መንግሥት',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          ),
          Text(
            'የባህር ዳር ከተማ አስተዳደር ገቢዎች ጽ/ቤት',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 17,
              color: Colors.green[900],
            ),
          ),
          const Divider(color: Colors.green, thickness: 2),
        ],
      ),
    );
  }

  Widget _buildPaidBadge() {
    return Align(
      alignment: Alignment.topRight,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.green, width: 2),
        ),
        child: const Text(
          'ተከፍሏል / PAID',
          style: TextStyle(
            color: Colors.green,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildAmountBox(String amount) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'ጠቅላላ ክፍያ (Total):',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          Text(
            '$amount ETB',
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.blue,
            ),
          ),
        ],
      ),
    );
  }

  Widget _receiptRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 14, color: Colors.black54),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
