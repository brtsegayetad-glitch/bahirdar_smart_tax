import 'package:flutter/material.dart';

class TaxTypeRow extends StatelessWidget {
  final String name;
  final double value;
  final double totalRevenue;
  final VoidCallback onTap;

  const TaxTypeRow({
    super.key,
    required this.name,
    required this.value,
    required this.totalRevenue,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    double percent = totalRevenue > 0 ? value / totalRevenue : 0;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 5),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
                Text("${value.toInt()} ብር (${(percent * 100).toStringAsFixed(1)}%)"),
              ],
            ),
            const SizedBox(height: 6),
            LinearProgressIndicator(
              value: percent,
              backgroundColor: Colors.grey[200],
              color: const Color(0xFF1E3C72),
              minHeight: 6,
            ),
          ],
        ),
      ),
    );
  }
}