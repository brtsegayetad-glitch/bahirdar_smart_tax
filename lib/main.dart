import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb; // አዲስ የተጨመረ
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'agent_page.dart';
import 'admin_dashboard.dart';
import 'tax_payer_page.dart';
import 'login_page.dart';

// 1. የቴሌብር ክፍያ እንዲሰራ (ለሞባይል ብቻ)
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

  // በWeb ላይ ከሆነ HttpOverrides አያስፈልግም (ስህተት እንዳይመጣ)
  if (!kIsWeb) {
    HttpOverrides.global = MyHttpOverrides();
  }

  // 2. የFirebase ኮንፊገሬሽን (የሰጠኸኝን መረጃ እዚህ አስገብቼዋለሁ)
  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: "AIzaSyC2tdrXOp5xDDRXUwKXp1q21rZ5nNAOZUM",
      authDomain: "bahirdar-smart-tax.firebaseapp.com",
      projectId: "bahirdar-smart-tax",
      storageBucket: "bahirdar-smart-tax.firebasestorage.app",
      messagingSenderId: "1021409884080",
      appId: "1:1021409884080:web:76bd7fef20475719d84875",
      measurementId: "G-3XHP4T0ZC3",
    ),
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
      // 2. አፑ ሲከፈት መጀመሪያ ምርጫ (Selection) እንዲመጣ
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

// -------------------------------------------------------------------
// የተጠቃሚ መምረጫ ገጽ (Role Selection)
// -------------------------------------------------------------------
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
                // 1. ኦፊሴላዊ ምልክት (Logo Icon)
                const Icon(
                  Icons.account_balance,
                  size: 80,
                  color: Color(0xFF1E3C72), // ከ Login Header ጋር የሚመሳሰል ከለር
                ),
                const SizedBox(height: 20),

                // 2. የአስተዳደሩ ስም (አማርኛ ከላይ - እንግሊዝኛ ከታች)
                const Text(
                  'የባህር ዳር ከተማ ገቢዎች አስተዳደር',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4), // በሁለቱ መካከለኛ ትንሽ ክፍተት
                const Text(
                  'BAHIR DAR CITY REVENUE ADMINISTRATION',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.normal, // Normal font እንዲሆን
                    color: Colors.grey,
                    letterSpacing: 1.2,
                  ),
                ),

                const SizedBox(height: 50), // ከምርጫዎቹ በፊት ያለው ክፍተት
                // 3. ምርጫዎች (Role Cards) - እነዚህ እንዳሉ ይቀጥላሉ
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

  // _buildRoleCard ሜተድህ እዚህ ይቀጥላል...

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
