import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'agent_page.dart';
import 'admin_dashboard.dart';
import 'tax_payer_page.dart';
import 'login_page.dart';
import 'firebase_options.dart';
import 'dart:io';

class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  HttpOverrides.global = MyHttpOverrides();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

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
      initialRoute: '/selection',
      routes: {
        '/selection': (context) => const UserSelectionScreen(),
        '/login': (context) => const LoginPage(),
        '/home': (context) => const TaxPayerPage(),
        '/admin': (context) => const AdminDashboard(),
        '/agent': (context) => const AgentPaymentPage(),
      },
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
                  color: Color(0xFF1E3C72),
                ),
                const SizedBox(height: 20),

                const Text(
                  'የባህር ዳር ከተማ ገቢዎች አስተዳደር',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4), 
                const Text(
                  'BAHIR DAR CITY REVENUE ADMINISTRATION',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.normal, 
                    color: Colors.grey,
                    letterSpacing: 1.2,
                  ),
                ),

                const SizedBox(height: 50),
                _buildRoleCard(
                  context,
                  title: 'ግብር ከፋይ (Tax Payer)',
                  subtitle: 'የራስዎን ግብር ለመክፈል',
                  icon: Icons.person,
                  color: Colors.blue,
                  onTap: () => Navigator.pushNamed(
                    context,
                    '/login',
                    arguments: 'TaxPayer',
                  ),
                ),
                const SizedBox(height: 20),

                _buildRoleCard(
                  context,
                  title: 'ወኪል / ሰራተኛ (Agent)',
                  subtitle: 'ክፍያዎችን ለመቀበል',
                  icon: Icons.badge,
                  color: Colors.green[700]!,
                  onTap: () => Navigator.pushNamed(
                    context,
                    '/login',
                    arguments: 'Agent',
                  ),
                ),
                const SizedBox(height: 20),

                _buildRoleCard(
                  context,
                  title: 'አስተዳደር (Admin)',
                  subtitle: 'ሪፖርቶችን ለማየት',
                  icon: Icons.admin_panel_settings,
                  color: Colors.orange[800]!,
                  onTap: () => Navigator.pushNamed(
                    context,
                    '/login',
                    arguments: 'Admin',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
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
