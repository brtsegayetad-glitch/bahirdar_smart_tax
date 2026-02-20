import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class MethodCard extends StatelessWidget {
  final String title;
  final double amount;
  final IconData icon;
  final VoidCallback onTap; // ይህንን ጨምረናል

  const MethodCard({
    super.key,
    required this.title,
    required this.amount,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap, // ክሊክ ሲደረግ የሚሰራ
      child: Container(
        width: 150,
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(10),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: const Color(0xFF1E3C72), size: 20),
            const Spacer(),
            Text(
              title,
              style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold),
            ),
            Text(
              "${NumberFormat('#,###').format(amount)} ብር",
              style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E3C72)),
            ),
          ],
        ),
      ),
    );
  }
}