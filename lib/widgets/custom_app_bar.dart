import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String pageTitle;

  const CustomAppBar({super.key, required this.pageTitle});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: const Color(0xFF1E3C72),
      elevation: 4,
      iconTheme: const IconThemeData(color: Colors.white),
      title: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  "የባህር ዳር ከተማ ገቢዎች መመሪያ",
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  "BAHIR DAR CITY REVENUE ADMINISTRATION",
                  style: TextStyle(
                    fontSize: 8,
                    color: Colors.white.withOpacity(0.7),
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        // የገባው ሰው ኢሜይል አጠገብ ትንሽ ክብ ምልክት
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              FirebaseAuth.instance.currentUser?.email?.split('@')[0] ?? "User",
              style: const TextStyle(fontSize: 10, color: Colors.white70),
            ),
            Text(
              pageTitle, // የአሁኑ ገጽ ስም (Admin, Agent...)
              style: const TextStyle(
                fontSize: 9,
                color: Colors.orangeAccent,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        IconButton(
          icon: const Icon(Icons.logout, color: Colors.white, size: 22),
          onPressed: () async {
            await FirebaseAuth.instance.signOut();
            Navigator.pushReplacementNamed(context, '/selection');
          },
        ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(60.0);
}
