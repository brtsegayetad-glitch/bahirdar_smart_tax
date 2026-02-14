import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'telebirr_service.dart';

class TaxPayerPage extends StatefulWidget {
  const TaxPayerPage({super.key});

  @override
  State<TaxPayerPage> createState() => _TaxPayerPageState();
}

class _TaxPayerPageState extends State<TaxPayerPage> {
  final _formKey = GlobalKey<FormState>();

  // መቆጣጠሪያዎች (Controllers)
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _tinController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();

  // የግብር ዘርፎች (Tax Groups)
  String _selectedTaxGroup = 'የከተማ ግብር';
  final List<String> _taxGroups = [
    'የከተማ ግብር',
    'የቤት ኪራይ ገቢ ግብር',
    'የንግድ ትርፍ ግብር',
    'የግል ሙያዊ አገልግሎት',
    'ሌላ...',
  ];

  bool _isProcessing = false;

  @override
  void dispose() {
    _nameController.dispose();
    _tinController.dispose();
    _phoneController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  void _processPayment() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isProcessing = true);

      // 1. የቴሌብር ክፍያ ሂደት
      String orderId = "BD-SELF-TAX-${DateTime.now().millisecondsSinceEpoch}";

      try {
        bool isPaid = await TelebirrService().makePayment(
          phoneNumber: _phoneController.text,
          amount: _amountController.text,
          orderId: orderId,
        );

        if (isPaid) {
          // 2. ክፍያው ከተሳካ ወደ Firebase መመዝገብ
          await FirebaseFirestore.instance.collection('tax_payments').add({
            'fullName': _nameController.text,
            'tinNumber': _tinController.text,
            'phone': _phoneController.text,
            'taxGroup': _selectedTaxGroup,
            'amount': _amountController.text,
            'paymentMethod': 'telebirr (Self)',
            'createdAt': FieldValue.serverTimestamp(),
          });

          if (!mounted) return;
          _showSuccessMessage();
        } else {
          _showErrorMessage("የቴሌብር ክፍያ አልተሳካም። እባክዎ ሂሳብዎን ያረጋግጡ።");
        }
      } catch (e) {
        _showErrorMessage("ስህተት ተከስቷል: $e");
      } finally {
        if (mounted) setState(() => _isProcessing = false);
      }
    }
  }

  void _showSuccessMessage() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("ክፍያው ተሳክቷል"),
        content: const Text(
          "የግብር ክፍያዎ በስኬት ተጠናቋል። ዲጂታል ደረሰኝዎ በFirebase ተመዝግቧል።",
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context); // ወደ ዋናው ገጽ ይመለሳል
            },
            child: const Text("እሺ"),
          ),
        ],
      ),
    );
  }

  void _showErrorMessage(String msg) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('የግብር መክፈያ (Tax Payer)'),
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'የመንግስት ግብርዎን እዚህ ይክፈሉ',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              _buildTextField(_nameController, 'ሙሉ ስም', Icons.person),
              const SizedBox(height: 15),
              _buildTextField(
                _tinController,
                'የTIN ቁጥር',
                Icons.badge,
                isNumber: true,
              ),
              const SizedBox(height: 15),
              _buildTextField(
                _phoneController,
                'የቴሌብር ስልክ ቁጥር',
                Icons.phone,
                isNumber: true,
              ),
              const SizedBox(height: 15),
              _buildDropdown(),
              const SizedBox(height: 15),
              _buildTextField(
                _amountController,
                'የገንዘብ መጠን (ብር)',
                Icons.money,
                isNumber: true,
              ),
              const SizedBox(height: 30),

              _isProcessing
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton.icon(
                      icon: const Icon(Icons.payment),
                      label: const Text(
                        "በቴሌብር አሁኑኑ ክፈል",
                        style: TextStyle(fontSize: 16),
                      ),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        backgroundColor: Colors.blueAccent,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: _processPayment,
                    ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    IconData icon, {
    bool isNumber = false,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      ),
      // እዚህ ጋር ነው ህጎቹን የምንጨምረው
      validator: (val) {
        if (val == null || val.isEmpty) {
          return 'እባክዎ $label ያስገቡ';
        }

        // ለስልክ ቁጥር ብቻ የሚሰሩ ህጎች
        if (label == 'የቴሌብር ስልክ ቁጥር') {
          // ቁጥሩ 10 መሆን አለበት እና በ 09 ወይም 07 መጀመር አለበት
          if (val.length != 10) {
            return 'ስልክ ቁጥር 10 ዲጂት መሆን አለበት';
          }
          if (!val.startsWith('09') && !val.startsWith('07')) {
            return 'ስልክ ቁጥር በ 09 ወይም 07 መጀመር አለበት';
          }
        }

        // ለTIN ቁጥር (ለምሳሌ 10 ዲጂት መሆን ካለበት)
        if (label == 'የTIN ቁጥር') {
          if (val.length < 10) {
            return 'ትክክለኛ የTIN ቁጥር ያስገቡ (ቢያንስ 10 ዲጂት)';
          }
        }

        // ለገንዘብ መጠን
        if (label == 'የገንዘብ መጠን (ብር)') {
          double? amount = double.tryParse(val);
          if (amount == null || amount <= 0) {
            return 'እባክዎ ትክክለኛ የገንዘብ መጠን ያስገቡ';
          }
          if (amount > 100000) {
            // ለደህንነት ሲባል ገደብ ማስቀመጥ
            return 'በአንድ ጊዜ ከ100,000 ብር በላይ መክፈል አይቻልም';
          }
        }

        return null; // ሁሉም ነገር ትክክል ከሆነ null ይመልሳል (ቀዩ ይጠፋል)
      },
    );
  }

  Widget _buildDropdown() {
    return DropdownButtonFormField<String>(
      initialValue: _selectedTaxGroup,
      decoration: InputDecoration(
        labelText: 'የግብር አይነት',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      ),
      items: _taxGroups
          .map((group) => DropdownMenuItem(value: group, child: Text(group)))
          .toList(),
      onChanged: (val) => setState(() => _selectedTaxGroup = val!),
    );
  }
}
