import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'agent_page.dart';
import 'admin_dashboard.dart';
import 'tax_payer_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
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
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue.shade900),
      ),
      // አፑ ሲከፈት መጀመሪያ የሚመጣው ገጽ
      home: const AuthWrapper(),
    );
  }
}

// አፑ ሰውየው ሎጊን ማድረጉንና አለማድረጉን የሚለይበት ክፍል
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // ገና ዳታው እየመጣ ከሆነ
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        // ሰውየው ገብቶ ከሆነ ወደ Role መምረጫ ይወሰዳል
        if (snapshot.hasData) {
          return const UserSelectionScreen();
        }
        // ካልገባ ወደ መግቢያ (Login) ገጽ ይወሰዳል
        return const LoginPage();
      },
    );
  }
}

// --- 1. እውነተኛ የመግቢያ ገጽ (LoginPage) ---
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  Future<void> _login() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('እባክዎ ኢሜይል እና ይለፍ ቃል ያስገቡ')));
      return;
    }

    setState(() => _isLoading = true);
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('ስህተት፡ ${e.message}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              const Icon(
                Icons.account_balance_rounded,
                size: 80,
                color: Colors.blueAccent,
              ),
              const SizedBox(height: 10),
              const Text(
                'ባህር ዳር ስማርት ታክስ',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const Text('ለመቀጠል መለያዎትን ያስገቡ'),
              const SizedBox(height: 30),
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'ኢሜይል',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 15),
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'ይለፍ ቃል',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 25),
              _isLoading
                  ? const CircularProgressIndicator()
                  : SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _login,
                        child: const Text('ግባ (Login)'),
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}

// --- 2. የRole መምረጫ ገጽ (UserSelectionScreen) ---
class UserSelectionScreen extends StatelessWidget {
  const UserSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    // የሰራተኛውን ስም ከኢሜይሉ መለየት (ለምሳሌ abebe@tax.com ከሆነ 'Abebe')
    String displayName = user?.email?.split('@')[0].toUpperCase() ?? "ተጠቃሚ";

    return Scaffold(
      appBar: AppBar(
        title: Text('ሰላም፣ $displayName'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => FirebaseAuth.instance.signOut(),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildRoleCard(
              context,
              title: 'ግብር ከፋይ (Tax Payer)',
              subtitle: 'የራስዎን ግብር ለመክፈል',
              icon: Icons.person_search,
              color: Colors.blue.shade800,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const TaxPayerPage()),
              ),
            ),
            const SizedBox(height: 16),
            _buildRoleCard(
              context,
              title: 'ወኪል / ሰራተኛ (Agent)',
              subtitle: 'ክፍያዎችን ለመመዝገብ',
              icon: Icons.point_of_sale,
              color: Colors.green.shade700,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AgentPaymentPage(),
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (user?.email == 'admin@tax.com') // አድሚን ከሆነ ብቻ ነው የሚታየው
              _buildRoleCard(
                context,
                title: 'አስተዳደር (Admin)',
                subtitle: 'ሪፖርቶችን ለማየት',
                icon: Icons.admin_panel_settings,
                color: Colors.orange.shade900,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AdminDashboard(),
                  ),
                ),
              ),
          ],
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
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: color.withOpacity(0.1),
            child: Icon(icon, color: color),
          ),
          title: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Text(subtitle),
          trailing: const Icon(Icons.arrow_forward_ios, size: 14),
        ),
      ),
    );
  }
}
