import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'receipt_page.dart'; // ደረሰኝ የሚቀበለው ገጽ
import 'telebirr_service.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AgentPaymentPage extends StatefulWidget {
  const AgentPaymentPage({super.key});

  @override
  State<AgentPaymentPage> createState() => _AgentPaymentPageState();
}

class _AgentPaymentPageState extends State<AgentPaymentPage> {
  final _formKey = GlobalKey<FormState>();

  // መቆጣጠሪያዎች (Controllers)
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _tinController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();

  // 1. የግብር ዘርፎች (Tax Groups) - አዲስ የተጨመረ
  // ሰራተኛው መጀመሪያ ይህንን ይመርጣል (ለምሳሌ፡ የትራንስፖርት አገልግሎት)
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

  // 2. የክፍያ ዘመን (Periods) - አዲስ የተጨመረ
  // ሰራተኛው የትኛውን ሩብ ዓመት እንደከፈለ ይመርጣል
  String _selectedPeriod = '1ኛ ሩብ ዓመት (ሐምሌ-መስከረም)';
  final List<String> _taxPeriods = [
    '1ኛ ሩብ ዓመት (ሐምሌ-መስከረም)',
    '2ኛ ሩብ ዓመት (ጥቅምት-ታህሳስ)',
    '3ኛ ሩብ ዓመት (ጥር-መጋቢት)',
    '4ኛ ሩብ ዓመት (ሚያዝያ-ሰኔ)',
    'ዓመታዊ ክፍያ (Annual)',
  ];

  // 3. የክፍያ ዘዴ
  final Map<String, String> _paymentOptions = {
    'cash': 'በጥሬ ገንዘብ (Cash)',
    'telebirr': 'በቴሌብር (Telebirr)',
    'bank': 'በባንክ (Bank Transfer)',
  };
  String _selectedPaymentKey = 'cash'; // Default

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
      appBar: AppBar(
        title: const Text('የግብር መቀበያ (Agent Terminal)'),
        backgroundColor: Colors.green[700],
        foregroundColor: Colors.white,
        elevation: 0,
      ),
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
                      color: Colors.green,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),

                  // TIN እና ስም
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

                  // 1. የግብር ዘርፍ ምርጫ
                  _buildDropdown(
                    'የግብር ዘርፍ (Tax Group)',
                    _selectedTaxGroup,
                    _taxGroups,
                    (val) => setState(() => _selectedTaxGroup = val!),
                  ),

                  // 2. የክፍያ ዘመን (Quarterly/Annual) ምርጫ
                  _buildDropdown(
                    'የክፍያ ዘመን (Period)',
                    _selectedPeriod,
                    _taxPeriods,
                    (val) => setState(() => _selectedPeriod = val!),
                  ),

                  // 3. የክፍያ ዘዴ
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
                      backgroundColor: Colors.green[700],
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
    final user = FirebaseAuth.instance.currentUser;

    if (_formKey.currentState!.validate()) {
      // 1. የቴሌብር ክፍያ ከሆነ መጀመሪያ እሱን ማከናወን
      if (_selectedPaymentKey == 'telebirr') {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const Center(
            child: CircularProgressIndicator(color: Colors.green),
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
          Navigator.pop(context); // Loading ማጥፋት

          if (!isPaid) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('የቴሌብር ክፍያ አልተሳካም!'),
                backgroundColor: Colors.red,
              ),
            );
            return; // ክፍያው ካልተሳካ እዚህ ጋር ይቆማል
          }
        } catch (e) {
          if (!mounted) return;
          Navigator.pop(context);
          return;
        }
      }

      // 2. ክፍያው ከተሳካ (ወይም በCash ከሆነ) ዳታቤዝ ላይ መመዝገብ
      // *** ልብ በል፡ እዚህ ጋር ነው አንድ ጊዜ ብቻ መመዝገብ ያለበት! ***
      try {
        await FirebaseFirestore.instance.collection('tax_payments').add({
          'fullName': _nameController.text,
          'tinNumber': _tinController.text,
          'phone': _phoneController.text,
          'taxGroup': _selectedTaxGroup,
          'taxPeriod': _selectedPeriod,
          'amount': _amountController.text,
          'paymentMethod': _selectedPaymentKey,
          'recordedBy': user?.email ?? "Unknown",
          'createdAt': FieldValue.serverTimestamp(),
        });

        if (!mounted) return;

        Navigator.push(
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
                'date': DateTime.now().toString(),
              },
            ),
          ),
        );

        // ፎርሙን ማጽዳት
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
  // --- እነዚህን መልሰህ ጨምራቸው (Helper Methods) ---

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
        prefixIcon: Icon(icon, color: Colors.green[700]),
        filled: true,
        fillColor: Colors.grey[50],
      ),
      keyboardType: type,
      // --- አዲስ፡ ተጠቃሚው ሲጽፍ የሚደረግ ገደብ (Input Formatters) ---
      inputFormatters:
          type == TextInputType.phone ||
              label.contains('TIN') ||
              label.contains('መጠን')
          ? [
              FilteringTextInputFormatter.digitsOnly, // ቁጥር ብቻ
              if (label == 'ስልክ ቁጥር')
                LengthLimitingTextInputFormatter(10), // ስልክ 10 ዲጂት ብቻ
              if (label.contains('TIN'))
                LengthLimitingTextInputFormatter(13), // TIN ቢበዛ 13
            ]
          : [],

      // --- አዲስ፡ ቅጹ ሲላክ የሚደረግ ፍተሻ (Validator) ---
      validator: (val) {
        if (val == null || val.isEmpty) {
          return 'እባክዎ $label ያስገቡ';
        }

        // 1. ለስልክ ቁጥር
        if (label == 'ስልክ ቁጥር') {
          if (val.length != 10) return 'ስልክ ቁጥር 10 ዲጂት መሆን አለበት';
          if (!val.startsWith('09') && !val.startsWith('07')) {
            return 'በ 09 ወይም 07 መጀመር አለበት';
          }
        }

        // 2. ለTIN ቁጥር
        if (label == 'የTIN ቁጥር') {
          if (val.length < 10) return 'ቢያንስ 10 ዲጂት መሆን አለበት';
        }

        // 3. ለገንዘብ መጠን
        if (label.contains('መጠን')) {
          double? amt = double.tryParse(val);
          if (amt == null || amt <= 0) return 'ትክክለኛ ቁጥር ያስገቡ';
          if (amt < 1) return 'ከ 1 ብር በታች መክፈል አይቻልም';
        }

        return null; // ስህተት ከሌለ
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
        initialValue:
            value, // እዚህ ጋር 'initialValue' የነበረውን ወደ 'value' ቀይረነዋል ለበለጠ ጥንቃቄ
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
