import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'receipt_page.dart';
import 'telebirr_service.dart';
import 'package:flutter/services.dart';
import 'widgets/custom_app_bar.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AgentPaymentPage extends StatefulWidget {
  const AgentPaymentPage({super.key});

  @override
  State<AgentPaymentPage> createState() => _AgentPaymentPageState();
}

class _AgentPaymentPageState extends State<AgentPaymentPage> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _tinController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();

  String _selectedTaxGroup = 'የትራንስፖርት አገልግሎት';
  final List<String> _taxGroups = [
    'የትራንስፖርት አገልግሎት',
    'የሸቀጣ ሸቀጥ ንግድ',
    'የሆቴል እና ቱሪዝም',
    'የቤት ኪራይ ገቢ ግብር',
    'የእጅ ስራ እና ማኑፋክቸሪንግ',
    'የግል ሙያዊ አገልግሎት',
    'የከተማ ግብር',
    'ሌላ...',
  ];

  String _selectedPeriod = '1ኛ ሩብ ዓመት (ሐምሌ-መስከረም)';
  final List<String> _taxPeriods = [
    '1ኛ ሩብ ዓመት (ሐምሌ-መስከረም)',
    '2ኛ ሩብ ዓመት (ጥቅምት-ታህሳስ)',
    '3ኛ ሩብ ዓመት (ጥር-መጋቢት)',
    '4ኛ ሩብ ዓመት (ሚያዝያ-ሰኔ)',
    'ዓመታዊ ክፍያ (Annual)',
  ];

  final Map<String, String> _paymentOptions = {
    'cash': 'በጥሬ ገንዘብ (Cash)',
    'telebirr': 'በቴሌብር (Telebirr)',
    'bank': 'በባንክ (Bank Transfer)',
  };
  String _selectedPaymentKey = 'cash';

  @override
  void dispose() {
    _nameController.dispose();
    _tinController.dispose();
    _phoneController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: const CustomAppBar(pageTitle: "የግብር መቀበያ (Agent)"),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'አዲስ ክፍያ መመዝገቢያ',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E3C72),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  _buildTextField(
                    _tinController,
                    'የTIN ቁጥር',
                    Icons.badge,
                    TextInputType.number,
                  ),
                  const SizedBox(height: 15),
                  _buildTextField(
                    _nameController,
                    'ሙሉ ስም',
                    Icons.person,
                    TextInputType.text,
                  ),
                  const SizedBox(height: 15),
                  _buildTextField(
                    _phoneController,
                    'ስልክ ቁጥር',
                    Icons.phone,
                    TextInputType.phone,
                  ),
                  const Divider(height: 30, thickness: 1),
                  _buildDropdown(
                    'የግብር ዘርፍ (Tax Group)',
                    _selectedTaxGroup,
                    _taxGroups,
                    (val) => setState(() => _selectedTaxGroup = val!),
                  ),
                  _buildDropdown(
                    'የክፍያ ዘመን (Period)',
                    _selectedPeriod,
                    _taxPeriods,
                    (val) => setState(() => _selectedPeriod = val!),
                  ),
                  _buildDropdown(
                    'የክፍያ ዘዴ',
                    _selectedPaymentKey,
                    _paymentOptions.keys.toList(),
                    (val) => setState(() => _selectedPaymentKey = val!),
                    isPaymentMethod: true,
                  ),
                  _buildTextField(
                    _amountController,
                    'የገንዘብ መጠን (ብር)',
                    Icons.attach_money,
                    TextInputType.number,
                  ),
                  const SizedBox(height: 30),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.check_circle),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1E3C72),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 5,
                    ),
                    onPressed: _submitData,
                    label: const Text(
                      'ክፍያውን አጽድቅና ደረሰኝ አውጣ',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _submitData() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedPaymentKey == 'telebirr') {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const Center(
            child: CircularProgressIndicator(color: Color(0xFF1E3C72)),
          ),
        );

        String orderId = "BD-TAX-${DateTime.now().millisecondsSinceEpoch}";

        try {
          bool isPaid = await TelebirrService().makePayment(
            phoneNumber: _phoneController.text,
            amount: _amountController.text,
            orderId: orderId,
          );

          if (!mounted) return;
          Navigator.pop(context);

          if (!isPaid) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('የቴሌብር ክፍያ አልተሳካም! እባክዎ በቂ ሂሳብ መኖሩን ያረጋግጡ።'),
                backgroundColor: Colors.red,
              ),
            );
            return;
          }
        } catch (e) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('የቴሌብር ስህተት: $e'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }
      }

      try {
        await FirebaseFirestore.instance.collection('tax_payments').add({
          'fullName': _nameController.text,
          'tinNumber': _tinController.text,
          'phone': _phoneController.text,
          'taxGroup': _selectedTaxGroup,
          'taxPeriod': _selectedPeriod,
          'amount': _amountController.text,
          'paymentMethod': _selectedPaymentKey,
          'createdAt': FieldValue.serverTimestamp(),
        });

        if (!mounted) return;

        String currentAgent = 'ያልታወቀ ኤጀንት';
        final user = FirebaseAuth.instance.currentUser;

        if (user != null) {
          currentAgent = user.displayName ?? user.email ?? 'ኤጀንት';
        }

        // SOLUTION: Wait for the ReceiptPage to be closed before continuing.
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ReceiptPage(
              data: {
                'name': _nameController.text,
                'tin': _tinController.text,
                'phone': _phoneController.text,
                'group': _selectedTaxGroup,
                'period': _selectedPeriod,
                'amount': _amountController.text,
                'method': _paymentOptions[_selectedPaymentKey]!,
                'agentName': currentAgent,
                'date': DateTime.now().toString(),
              },
            ),
          ),
        );

        // This code now runs only AFTER the user returns from the receipt page.
        _nameController.clear();
        _tinController.clear();
        _phoneController.clear();
        _amountController.clear();

      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('የዳታቤዝ ስህተት: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    IconData icon,
    TextInputType type,
  ) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        prefixIcon: Icon(icon, color: const Color(0xFF1E3C72)),
        filled: true,
        fillColor: Colors.grey[50],
      ),
      keyboardType: type,
      inputFormatters:
          type == TextInputType.phone ||
              label.contains('TIN') ||
              label.contains('መጠን')
          ? [
              FilteringTextInputFormatter.digitsOnly,
              if (label == 'ስልክ ቁጥር') LengthLimitingTextInputFormatter(10),
              if (label.contains('TIN')) LengthLimitingTextInputFormatter(13),
            ]
          : [],
      validator: (val) {
        if (val == null || val.isEmpty) return 'እባክዎ $label ያስገቡ';
        if (label == 'ስልክ ቁጥር') {
          if (val.length != 10) return 'ስልክ ቁጥር 10 ዲጂት መሆን አለበት';
          if (!val.startsWith('09') && !val.startsWith('07')) {
            return 'በ 09 ወይም 07 መጀመር አለበት';
          }
        }
        if (label == 'የTIN ቁጥር' && val.length < 10) {
          return 'ቢያንስ 10 ዲጂት መሆን አለበት';
        }
        if (label.contains('መጠን')) {
          double? amt = double.tryParse(val);
          if (amt == null || amt <= 0) return 'ትክክለኛ ቁጥር ያስገቡ';
        }
        return null;
      },
    );
  }

  Widget _buildDropdown(
    String label,
    String value,
    List<String> items,
    Function(String?) onChanged, {
    bool isPaymentMethod = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: DropdownButtonFormField<String>(
        initialValue: value,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          filled: true,
          fillColor: Colors.grey[50],
        ),
        items: items
            .map(
              (t) => DropdownMenuItem(
                value: t,
                child: Text(
                  isPaymentMethod ? _paymentOptions[t]! : t,
                  style: const TextStyle(fontSize: 13, color: Colors.black87),
                ),
              ),
            )
            .toList(),
        onChanged: onChanged,
      ),
    );
  }
}