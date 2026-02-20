import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

// ይህ ፋንክሽን የክፍያ ዝርዝር (Audit Trail) ፖፕአፕን ያሳያል
void showAuditTrailDialog(BuildContext context, Map<String, dynamic> data) {
  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text(
          "የክፍያ ዝርዝር (Audit Trail)", 
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("ሙሉ ስም (Name): ${data['fullName'] ?? 'N/A'}"),
              const Divider(),
              Text("TIN ቁጥር (TIN): ${data['tinNumber'] ?? 'N/A'}"),
              const Divider(),
              Text("የክፍያ መጠን (Amount): ${data['amount'] ?? '0'} ብር"),
              const Divider(),
              Text("የክፍያ ዘዴ (Method): ${data['paymentMethod'] ?? 'N/A'}"),
              const Divider(),
              Text("የግብር ዘርፍ (Tax Group): ${data['taxGroup'] ?? 'N/A'}"),
              const Divider(),
              Text("የክፍያ ዘመን (Period): ${data['taxPeriod'] ?? 'N/A'}"),
              const Divider(),
              Text(
                "የተከፈለበት ሰዓት (Date & Time): ${data['createdAt'] != null 
                  ? DateFormat('yyyy-MM-dd HH:mm').format((data['createdAt'] as Timestamp).toDate()) 
                  : 'N/A'}"
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("ዝጋ (Close)"),
          ),
        ],
      );
    },
  );
}