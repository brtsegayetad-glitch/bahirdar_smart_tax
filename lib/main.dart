import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'agent_page.dart';
import 'admin_dashboard.dart'; // Admin ገጹን ለመጠቀም
import 'tax_payer_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Firebaseን እናስነሳዋለን
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(const BahirDarSmartTaxApp());
}

class BahirDarSmartTaxApp extends StatelessWidget {
  const BahirDarSmartTaxApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Bahir Dar Smart Tax',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: Colors.grey[100],
        useMaterial3: true,
      ),
      home: const UserSelectionScreen(),
    );
  }
}

class UserSelectionScreen extends StatelessWidget {
  const UserSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.account_balance,
                  size: 80,
                  color: Colors.blueAccent,
                ),
                const SizedBox(height: 20),
                const Text(
                  'ባህር ዳር ስማርት ታክስ',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 50),

                // 2. በ UserSelectionScreen ውስጥ የነበረውን የታክስ ፓየር ካርድ እንዲህ ቀይረው፡
                _buildRoleCard(
                  context,
                  title: 'ግብር ከፋይ (Tax Payer)',
                  subtitle: 'የራስዎን ግብር ለመክፈል',
                  icon: Icons.person,
                  color: Colors.blue,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const TaxPayerPage(),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 20),

                // 2. Agent (Protected - Needs PIN "1234")
                _buildRoleCard(
                  context,
                  title: 'ወኪል / ሰራተኛ (Agent)',
                  subtitle: 'ክፍያዎችን ለመቀበል',
                  icon: Icons.badge,
                  color: Colors.green[700]!,
                  onTap: () => _showPinDialog(context, 'agent'),
                ),
                const SizedBox(height: 20),

                // 3. Admin (Protected - Needs PIN "9999")
                _buildRoleCard(
                  context,
                  title: 'አስተዳደር (Admin)',
                  subtitle: 'ሪፖርቶችን ለማየት',
                  icon: Icons.admin_panel_settings,
                  color: Colors.orange[800]!,
                  onTap: () => _showPinDialog(context, 'admin'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- NEW: PIN Security Logic ---
  void _showPinDialog(BuildContext context, String role) {
    final TextEditingController pinController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            role == 'admin'
                ? 'የአስተዳደር መለያ (Admin PIN)'
                : 'የሰራተኛ መለያ (Agent PIN)',
          ),
          content: TextField(
            controller: pinController,
            keyboardType: TextInputType.number,
            obscureText: true, // Hide the numbers
            decoration: const InputDecoration(
              hintText: 'ሚስጥራዊ ቁጥር ያስገቡ',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                String pin = pinController.text;
                Navigator.pop(context); // Close dialog

                // 1. CHECK AGENT PIN (1234)
                if (role == 'agent' && pin == '1234') {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AgentPaymentPage(),
                    ),
                  );
                }
                // 2. CHECK ADMIN PIN (9999)
                else if (role == 'admin' && pin == '9999') {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AdminDashboard(),
                    ),
                  );
                }
                // 3. WRONG PIN
                else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('የተሳሳተ መለያ ቁጥር! (Wrong PIN)'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              child: const Text('ግባ (Login)'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildRoleCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 30, color: color),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      subtitle,
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[400]),
            ],
          ),
        ),
      ),
    );
  }
}
