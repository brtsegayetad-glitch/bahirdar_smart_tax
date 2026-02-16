import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:csv/csv.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'widgets/custom_app_bar.dart';

// Web ላይ ለዳውንሎድ የሚያስፈልግ (Conditional Import)
// ይህ ለሞባይል ሪፖርት መላኪያ ነው
import 'web_download_stub.dart' if (dart.library.html) 'web_download_web.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  String _selectedPeriod = 'Today';
  String _searchQuery = "";

  // ... ከላይ ያሉት Imports እንዳሉ ሆነው

  DateTime _getStartDate() {
    DateTime now = DateTime.now();
    DateTime todayMidnight = DateTime(now.year, now.month, now.day);

    switch (_selectedPeriod) {
      case 'Yesterday':
        return todayMidnight.subtract(const Duration(days: 1));
      case 'Week':
        return todayMidnight.subtract(const Duration(days: 7));
      case 'Month':
        return DateTime(now.year, now.month - 1, now.day);
      case '3 Months':
        return DateTime(now.year, now.month - 3, now.day);
      case 'Year':
        return DateTime(now.year - 1, now.month, now.day);
      default:
        // Today
        return todayMidnight;
    }
  }

  // ... የተቀረው ኮድህ ያለምንም ለውጥ ይቀጥላል

  // ሪፖርት ማውረጃ Logic
  void _exportToExcel(List<QueryDocumentSnapshot> docs) async {
    try {
      List<List<dynamic>> rows = [];

      // ርዕሶች
      rows.add([
        "ሙሉ ስም",
        "TIN ቁጥር",
        "ስልክ",
        "የግብር ዘርፍ (Tax Group)",
        "የክፍያ ዘመን (Period)",
        "ክፍያ ዘዴ",
        "መጠን (ብር)",
        "ቀን",
      ]);

      double grandTotal = 0;

      for (var doc in docs) {
        final d = doc.data() as Map<String, dynamic>;
        double amt = double.tryParse(d['amount'].toString()) ?? 0;
        grandTotal += amt;

        rows.add([
          d['fullName'] ?? 'N/A',
          d['tinNumber'] ?? 'N/A',
          d['phone'] ?? 'N/A',
          d['taxGroup'] ?? 'N/A',
          d['taxPeriod'] ?? 'N/A',
          d['paymentMethod'] ?? 'Cash',
          amt,
          d['createdAt'] != null
              ? DateFormat(
                  'yyyy-MM-dd',
                ).format((d['createdAt'] as Timestamp).toDate())
              : 'N/A',
        ]);
      }

      // ጠቅላላ ድምርን መጨመር
      rows.add([]);
      rows.add(["", "", "", "", "", "ጠቅላላ ድምር፡", grandTotal, "ብር"]);

      String csvData = const ListToCsvConverter().convert(rows);
      final bytes = utf8.encode(csvData);

      // --- አዲሱ የ Conditional Logic እዚህ ጋር ይጀምራል ---
      if (kIsWeb) {
        // በWeb ላይ ከሆነ 'web_download_web.dart' ውስጥ ያለውን ፋንክሽን ይጠራል
        downloadWebFile(
          bytes,
          "BahirDar_Revenue_Report_${_selectedPeriod.replaceAll(' ', '_')}.csv",
        );
      } else {
        // በሞባይል (Android/iOS) ላይ ከሆነ ሼር ያደርጋል
        await Share.shareXFiles([
          XFile.fromData(
            Uint8List.fromList(bytes),
            name: "Tax_Report.csv",
            mimeType: 'text/csv',
          ),
        ], text: 'የባህር ዳር ከተማ ገቢዎች ሪፖርት');
      }
      // --- መጨረሻ ---

      _showSuccessDialog();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('ሪፖርት ማውጣት አልተቻለም: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("ሪፖርቱ ተዘጋጅቷል"),
        content: const Text(
          "የ3 ወር እና የዓመታዊ ግብር ክፍያዎች ተጠቃለው ወርደዋል።\n\n"
          "ማሳሰቢያ፡ በExcel ፋይሉ ላይ ጽሁፎቹ ተጨናንቀው ከታዩ የኮለም መስመሮቹን Double-Click በማድረግ ማስፋት ይችላሉ።",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("እሺ"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      // አዲሱ CustomAppBar ብቻ እዚህ እንዲቀመጥ ተደርጓል
      appBar: const CustomAppBar(pageTitle: "Admin Dashboard"),
      body: Column(
        children: [
          // የጊዜ መምረጫው (Dropdown) አሁን ከስሙ ስር በ body ውስጥ እንዲታይ ተደርጓል
          Container(
            color: const Color(0xFF1E3C72),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "የሪፖርት ጊዜ መምረጫ",
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
                DropdownButton<String>(
                  value: _selectedPeriod,
                  dropdownColor: const Color(0xFF2A5298),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                  underline: Container(),
                  items:
                      [
                            'Today',
                            'Yesterday',
                            'Week',
                            'Month',
                            '3 Months',
                            'Year',
                          ]
                          .map(
                            (val) =>
                                DropdownMenuItem(value: val, child: Text(val)),
                          )
                          .toList(),
                  onChanged: (val) => setState(() => _selectedPeriod = val!),
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('tax_payments')
                  .where('createdAt', isGreaterThanOrEqualTo: _getStartDate())
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text("ምንም ዳታ የለም"));
                }

                final allDocs = snapshot.data!.docs;
                final docs = allDocs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final name = (data['fullName'] ?? "")
                      .toString()
                      .toLowerCase();
                  final tin = (data['tinNumber'] ?? "")
                      .toString()
                      .toLowerCase();
                  return name.contains(_searchQuery.toLowerCase()) ||
                      tin.contains(_searchQuery.toLowerCase());
                }).toList();

                double totalRevenue = 0;
                Map<String, double> byType = {};
                Map<String, double> byMethod = {};

                for (var doc in docs) {
                  final data = doc.data() as Map<String, dynamic>;
                  double amt = double.tryParse(data['amount'].toString()) ?? 0;
                  totalRevenue += amt;

                  String type = data['taxGroup'] ?? 'ሌላ';
                  byType[type] = (byType[type] ?? 0) + amt;

                  String rawM = (data['paymentMethod'] ?? 'cash')
                      .toString()
                      .toLowerCase();
                  String cleanM = rawM.contains('tele')
                      ? 'Telebirr'
                      : (rawM.contains('bank') ? 'Bank' : 'Cash');
                  byMethod[cleanM] = (byMethod[cleanM] ?? 0) + amt;
                }

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeaderCard(
                        totalRevenue,
                        docs.length,
                        () => _exportToExcel(docs),
                      ),
                      const SizedBox(height: 25),
                      TextField(
                        decoration: InputDecoration(
                          hintText: "በስም ወይም በTIN ይፈልጉ...",
                          prefixIcon: const Icon(Icons.search),
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        onChanged: (val) => setState(() => _searchQuery = val),
                      ),
                      const SizedBox(height: 25),
                      const Text(
                        "በክፍያ ዘዴ (Methods)",
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 100,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          children: byMethod.entries
                              .map((e) => _buildMethodCard(e.key, e.value))
                              .toList(),
                        ),
                      ),
                      const SizedBox(height: 30),
                      const Text(
                        "በታክስ አይነት (Stats)",
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ...byType.entries.map(
                        (e) => _buildTypeRow(e.key, e.value, totalRevenue),
                      ),
                      const SizedBox(height: 30),
                      const Text(
                        "የቅርብ ጊዜ ክፍያዎች",
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: docs.length,
                        itemBuilder: (context, i) {
                          final d = docs[i].data() as Map<String, dynamic>;
                          return Card(
                            margin: const EdgeInsets.only(bottom: 10),
                            child: ListTile(
                              title: Text(
                                d['fullName'] ?? 'N/A',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Text(
                                "${d['taxGroup'] ?? 'N/A'} | TIN: ${d['tinNumber'] ?? 'N/A'}",
                              ),
                              trailing: Text(
                                "${d['amount'] ?? '0'} ብር",
                                style: const TextStyle(
                                  color: Colors.blue,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // --- UI Components (ሎጂክ አልተነካም) ---

  Widget _buildHeaderCard(double total, int count, VoidCallback onExport) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E3C72), Color(0xFF2A5298)],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Text(
            "ጠቅላላ የተሰበሰበ ገቢ ($_selectedPeriod)",
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 5),
          Text(
            "${NumberFormat('#,###').format(total)} ብር",
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              "ከ $count ግብር ከፋዮች የተሰበሰበ",
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: onExport,
            icon: const Icon(Icons.download),
            label: const Text("ሙሉ ሪፖርት አውርድ (Excel)"),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.blueAccent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMethodCard(String title, double val) {
    return Container(
      width: 150,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.grey,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          Text(
            "${NumberFormat('#,###').format(val)} ብር",
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E3C72),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeRow(String name, double val, double total) {
    double percent = total > 0 ? val / total : 0;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(name, style: const TextStyle(fontWeight: FontWeight.w500)),
              Text(
                "${val.toInt()} ብር (${(percent * 100).toStringAsFixed(1)}%)",
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: percent,
              minHeight: 7,
              backgroundColor: Colors.grey[200],
              color: Colors.blueAccent,
            ),
          ),
        ],
      ),
    );
  }
}
