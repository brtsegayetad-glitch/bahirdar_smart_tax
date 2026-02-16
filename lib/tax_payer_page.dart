import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'telebirr_service.dart';
import 'package:flutter/services.dart'; // ለቁጥር ገደቦች አስፈላጊ ነው
import 'widgets/custom_app_bar.dart';

class TaxPayerPage extends StatefulWidget {
  const TaxPayerPage({super.key});

  @override
  State<TaxPayerPage> createState() => _TaxPayerPageState();
}

class _TaxPayerPageState extends State<TaxPayerPage> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _tinController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();

  // የግብር ዘርፎች
  String _selectedTaxGroup = 'የከተማ ግብር';
  final List<String> _taxGroups = [
    'የከተማ ግብር',
    'የቤት ኪራይ ገቢ ግብር',
    'የንግድ ትርፍ ግብር',
    'የግል ሙያዊ አገልግሎት',
    'ሌላ...',
  ];

  // አዲስ፡ የክፍያ ዘመን (Period) - ዳታው ከ Admin ጋር እንዲናበብ
  String _selectedPeriod = '1ኛ ሩብ ዓመት (ሐምሌ-መስከረም)';
  final List<String> _taxPeriods = [
    '1ኛ ሩብ ዓመት (ሐምሌ-መስከረም)',
    '2ኛ ሩብ ዓመት (ጥቅምት-ታህሳስ)',
    '3ኛ ሩብ ዓመት (ጥር-መጋቢት)',
    '4ኛ ሩብ ዓመት (ሚያዝያ-ሰኔ)',
    'ዓመታዊ ክፍያ (Annual)',
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

      String orderId = "BD-SELF-TAX-${DateTime.now().millisecondsSinceEpoch}";

      try {
        bool isPaid = await TelebirrService().makePayment(
          phoneNumber: _phoneController.text,
          amount: _amountController.text,
          orderId: orderId,
        );

        if (isPaid) {
          // 'taxPeriod' እዚህ ጋር ተጨምሯል
          await FirebaseFirestore.instance.collection('tax_payments').add({
            'fullName': _nameController.text,
            'tinNumber': _tinController.text,
            'phone': _phoneController.text,
            'taxGroup': _selectedTaxGroup,
            'taxPeriod': _selectedPeriod, // መረሳት የሌለበት!
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
          "የግብር ክፍያዎ በስኬት ተጠናቋል። ዲጂታል ደረሰኝዎ በስርዓቱ ላይ ተመዝግቧል።",
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context);
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
      backgroundColor: Colors.grey[50],
      appBar: const CustomAppBar(pageTitle: "የግብር መክፈያ (Self Service)"),
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
                    'የመንግስት ግብርዎን እዚህ ይክፈሉ',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E3C72),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 25),

                  _buildTextField(
                    _nameController,
                    'ሙሉ ስም',
                    Icons.person,
                    TextInputType.text,
                  ),
                  const SizedBox(height: 15),
                  _buildTextField(
                    _tinController,
                    'የTIN ቁጥር',
                    Icons.badge,
                    TextInputType.number,
                  ),
                  const SizedBox(height: 15),
                  _buildTextField(
                    _phoneController,
                    'የቴሌብር ስልክ ቁጥር',
                    Icons.phone,
                    TextInputType.phone,
                  ),

                  const Divider(height: 40),

                  // የግብር ዘርፍ
                  _buildDropdown(
                    "የግብር አይነት",
                    _selectedTaxGroup,
                    _taxGroups,
                    (val) => setState(() => _selectedTaxGroup = val!),
                  ),
                  const SizedBox(height: 15),

                  // የክፍያ ዘመን
                  _buildDropdown(
                    "የክፍያ ዘመን (Period)",
                    _selectedPeriod,
                    _taxPeriods,
                    (val) => setState(() => _selectedPeriod = val!),
                  ),
                  const SizedBox(height: 15),

                  _buildTextField(
                    _amountController,
                    'የገንዘብ መጠን (ብር)',
                    Icons.money,
                    TextInputType.number,
                  ),
                  const SizedBox(height: 30),

                  _isProcessing
                      ? const Center(
                          child: CircularProgressIndicator(
                            color: Color(0xFF1E3C72),
                          ),
                        )
                      : ElevatedButton.icon(
                          icon: const Icon(Icons.security),
                          label: const Text(
                            "በቴሌብር ክፍያውን ፈጽም",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            backgroundColor: const Color(0xFF1E3C72),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          onPressed: _processPayment,
                        ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    IconData icon,
    TextInputType type,
  ) {
    return TextFormField(
      controller: controller,
      keyboardType: type,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: const Color(0xFF1E3C72)),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        filled: true,
        fillColor: Colors.grey[50],
      ),
      inputFormatters:
          type == TextInputType.number || type == TextInputType.phone
          ? [
              FilteringTextInputFormatter.digitsOnly,
              if (label.contains('ስልክ')) LengthLimitingTextInputFormatter(10),
            ]
          : [],
      validator: (val) {
        if (val == null || val.isEmpty) return 'እባክዎ $label ያስገቡ';
        if (label.contains('ስልክ') && val.length != 10) return 'ትክክለኛ ስልክ ያስገቡ';
        if (label.contains('TIN') && val.length < 10)
          return 'TIN ቢያንስ 10 ዲጂት ነው';
        return null;
      },
    );
  }

  Widget _buildDropdown(
    String label,
    String value,
    List<String> items,
    Function(String?) onChanged,
  ) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        filled: true,
        fillColor: Colors.grey[50],
      ),
      items: items
          .map(
            (group) => DropdownMenuItem(
              value: group,
              child: Text(group, style: const TextStyle(fontSize: 13)),
            ),
          )
          .toList(),
      onChanged: onChanged,
    );
  }
}
