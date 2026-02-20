import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:csv/csv.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;

// Web-specific import
import 'web_download_web.dart';

// Widgets Folder Imports
import 'widgets/custom_app_bar.dart';
import 'widgets/audit_trail_dialog.dart';
import 'widgets/stat_cards.dart';
import 'widgets/tax_type_row.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  String _selectedPeriod = 'Today';
  String _searchQuery = "";

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
        return todayMidnight;
    }
  }

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

      // --- This is the conditional logic ---
      if (kIsWeb) {
        // This function from 'web_download_web.dart' is called on Web
        downloadWebFile(
          bytes,
          "BahirDar_Revenue_Report_${_selectedPeriod.replaceAll(' ', '_')}.csv",
        );
      } else {
        // On mobile (Android/iOS), it shares the file
        await Share.shareXFiles([
          XFile.fromData(
            Uint8List.fromList(bytes),
            name: "Tax_Report.csv",
            mimeType: 'text/csv',
          ),
        ], text: 'የባህር ዳር ከተማ ገቢዎች ሪፖርት');
      }

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
          "የግብር ክፍያዎች ተጠቃለው ወርደዋል።\n\nማሳሰቢያ፡ በExcel ፋይሉ ላይ ጽሁፎቹ ተጨናንቀው ከታዩ የኮለም መስመሮቹን ማስፋት ይችላሉ።",
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
      appBar: const CustomAppBar(pageTitle: "Admin Dashboard"),
      body: Column(
        children: [
          // 1. Period Selection Header (Dropdown)
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

          // 2. Main Content Area
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

                // Data Processing Logic
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
                      // Revenue Card
                      _buildHeaderCard(
                        totalRevenue,
                        docs.length,
                        () => _exportToExcel(docs),
                      ),
                      const SizedBox(height: 25),

                      // Search Bar
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

                      // Payment Methods Section (Horizontal List)
                      const Text(
                        "በክፍያ ዘዴ (Methods)",
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 110,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          children: byMethod.entries.map((e) {
                            return MethodCard(
                              title: e.key,
                              amount: e.value,
                              icon: e.key == 'Telebirr'
                                  ? Icons.phone_android
                                  : e.key == 'Bank'
                                  ? Icons.account_balance
                                  : Icons.money,
                              onTap: () => _showFilterDialog(
                                context,
                                "ክፍያ ዘዴ",
                                e.key,
                                docs,
                              ),
                            );
                          }).toList(),
                        ),
                      ),

                      const SizedBox(height: 30),

                      // Tax Type Section (Clickable Stats)
                      const Text(
                        "በታክስ አይነት (Stats)",
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ...byType.entries.map(
                        (e) => TaxTypeRow(
                          name: e.key,
                          value: e.value,
                          totalRevenue: totalRevenue,
                          onTap: () => _showFilterDialog(
                            context,
                            "የታክስ አይነት",
                            e.key,
                            docs,
                          ),
                        ),
                      ),

                      const SizedBox(height: 30),

                      // Recent Payments List
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
                              onTap: () => showAuditTrailDialog(context, d),
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
              color: Colors.white.withAlpha(50),
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

  void _showFilterDialog(
    BuildContext context,
    String filterTitle,
    String filterValue,
    List<QueryDocumentSnapshot> allDocs,
  ) {
    final filteredList = allDocs.where((doc) {
      final d = doc.data() as Map<String, dynamic>;
      if (filterTitle == "ክፍያ ዘዴ") {
        String m = (d['paymentMethod'] ?? 'cash').toString().toLowerCase();
        if (filterValue == "Telebirr") return m.contains('tele');
        if (filterValue == "Bank") return m.contains('bank');
        return !m.contains('tele') && !m.contains('bank');
      } else {
        return d['taxGroup'] == filterValue;
      }
    }).toList();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          "የ$filterValue ዝርዝር መረጃ",
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: filteredList.isEmpty
              ? const Center(child: Text("ምንም ዳታ የለም"))
              : ListView.builder(
                  itemCount: filteredList.length,
                  itemBuilder: (context, i) {
                    final data = filteredList[i].data() as Map<String, dynamic>;
                    return ListTile(
                      leading: const CircleAvatar(child: Icon(Icons.person)),
                      title: Text(data['fullName'] ?? "ስም የለም"),
                      subtitle: Text(
                        "${data['amount']} ብር | TIN: ${data['tinNumber']}",
                      ),
                      onTap: () {
                        Navigator.pop(context);
                        showAuditTrailDialog(context, data);
                      },
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("ዝጋ"),
          ),
        ],
      ),
    );
  }
}
