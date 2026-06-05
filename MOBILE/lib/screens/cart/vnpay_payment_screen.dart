import 'package:flutter/material.dart';

class VnpayPaymentScreen extends StatefulWidget {
  final double amount;
  final String orderId;
  final String paymentUrl;

  const VnpayPaymentScreen({
    super.key,
    required this.amount,
    required this.orderId,
    required this.paymentUrl,
  });

  @override
  State<VnpayPaymentScreen> createState() => _VnpayPaymentScreenState();
}

class _VnpayPaymentScreenState extends State<VnpayPaymentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _cardNumberController = TextEditingController();
  final _holderNameController = TextEditingController();
  final _dateController = TextEditingController();
  final _otpController = TextEditingController();

  int _step = 1; // 1: Card Entry, 2: OTP Entry, 3: Processing, 4: Success
  bool _isConnecting = false;

  @override
  void dispose() {
    _cardNumberController.dispose();
    _holderNameController.dispose();
    _dateController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  void _autofillSandbox() {
    setState(() {
      _cardNumberController.text = "9704198526191432198";
      _holderNameController.text = "NGUYEN VAN A";
      _dateController.text = "07/15";
    });
  }

  void _submitCard() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isConnecting = true;
    });

    // Simulate connecting to bank gateway
    await Future.delayed(const Duration(seconds: 1));

    setState(() {
      _isConnecting = false;
      _step = 2; // Move to OTP
    });
  }

  void _submitOtp() async {
    if (_otpController.text != "123456") {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Invalid OTP code. Sandbox code is 123456"),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() {
      _step = 3; // Processing
    });

    // Simulate checking txn details on VNPAY
    await Future.delayed(const Duration(seconds: 2));

    setState(() {
      _step = 4; // Success
    });

    // Wait 2 seconds on success page before completing redirect
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) {
      Navigator.pop(context, '00'); // '00' is VNPAY Success Response Code
    }
  }

  @override
  Widget build(BuildContext context) {
    final amountInVnd = (widget.amount * 25000).toInt();
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: const Color(0xFFF2F4F7),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.payment, color: Colors.blueAccent),
            const SizedBox(width: 6),
            const Text(
              "VNPAY",
              style: TextStyle(
                color: Color(0xFF0F3D8D),
                fontWeight: FontWeight.w900,
                fontSize: 22,
                letterSpacing: 0.5,
              ),
            ),
            Text(
              " Gateway",
              style: TextStyle(
                color: Colors.orange.shade700,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.grey),
          onPressed: () {
            Navigator.pop(context, '99'); // Cancel payment
          },
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Order Summary banner
              Card(
                color: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.grey.shade200),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text("Merchant", style: TextStyle(color: Colors.grey)),
                          const Text("Tiem Hoa Xinh Store", style: TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text("Order Code", style: TextStyle(color: Colors.grey)),
                          Text(widget.orderId, style: const TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const Divider(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text("Payment Amount", style: TextStyle(fontWeight: FontWeight.bold)),
                          Text(
                            "$amountInVnd VND",
                            style: const TextStyle(
                              color: Color(0xFF0F3D8D),
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Steps Content
              if (_step == 1) _buildCardForm(textTheme),
              if (_step == 2) _buildOtpForm(textTheme),
              if (_step == 3) _buildProcessingState(),
              if (_step == 4) _buildSuccessState(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCardForm(TextTheme textTheme) {
    return Form(
      key: _formKey,
      child: Card(
        color: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.grey.shade200),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                "Debit/ATM Bank Card Details",
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF0F3D8D),
                ),
              ),
              const SizedBox(height: 16),
              
              // Auto fill Helper Button
              ElevatedButton.icon(
                onPressed: _autofillSandbox,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange.shade50,
                  foregroundColor: Colors.orange.shade800,
                  minimumSize: const Size(double.infinity, 44),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: BorderSide(color: Colors.orange.shade200),
                  ),
                ),
                icon: const Icon(Icons.auto_awesome, size: 16),
                label: const Text("AUTO FILL SANDBOX CARD"),
              ),
              
              const SizedBox(height: 20),

              TextFormField(
                controller: _cardNumberController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: "ATM Card Number (NCB)",
                  hintText: "9704 1985 2619 1432 198",
                  prefixIcon: Icon(Icons.credit_card),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) return "Enter card number";
                  if (value.replaceAll(' ', '').length < 16) return "Invalid format";
                  return null;
                },
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _holderNameController,
                textCapitalization: TextCapitalization.characters,
                decoration: const InputDecoration(
                  labelText: "Card Holder Name",
                  hintText: "NGUYEN VAN A",
                  prefixIcon: Icon(Icons.person),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) return "Enter holder name";
                  return null;
                },
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _dateController,
                keyboardType: TextInputType.datetime,
                decoration: const InputDecoration(
                  labelText: "Issue Date (MM/YY)",
                  hintText: "07/15",
                  prefixIcon: Icon(Icons.calendar_today),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) return "Enter issue date";
                  return null;
                },
              ),
              
              const SizedBox(height: 24),

              _isConnecting
                  ? const Center(
                      child: CircularProgressIndicator(color: Color(0xFF0F3D8D)),
                    )
                  : ElevatedButton(
                      onPressed: _submitCard,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0F3D8D),
                        foregroundColor: Colors.white,
                      ),
                      child: const Text("Proceed to Verify"),
                    ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOtpForm(TextTheme textTheme) {
    return Card(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              "SMS OTP Verification",
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: const Color(0xFF0F3D8D),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            const Text(
              "A verification code has been sent to your registered phone number. Sandbox OTP is 123456.",
              style: TextStyle(color: Colors.grey, fontSize: 13),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),

            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _otpController.text = "123456";
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade50,
                foregroundColor: Colors.green.shade800,
                minimumSize: const Size(double.infinity, 44),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: BorderSide(color: Colors.green.shade200),
                ),
              ),
              icon: const Icon(Icons.pin_outlined, size: 16),
              label: const Text("AUTO ENTER OTP"),
            ),

            const SizedBox(height: 20),
            TextFormField(
              controller: _otpController,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 20, letterSpacing: 6, fontWeight: FontWeight.bold),
              decoration: const InputDecoration(
                hintText: "123456",
                contentPadding: EdgeInsets.symmetric(vertical: 16),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _submitOtp,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade700,
                foregroundColor: Colors.white,
              ),
              child: const Text("Confirm Payment"),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProcessingState() {
    return Card(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
        child: Column(
          children: [
            const CircularProgressIndicator(color: Color(0xFF0F3D8D)),
            const SizedBox(height: 24),
            const Text(
              "Processing Transaction...",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              "Please do not close this window or lock your screen.",
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuccessState() {
    return Card(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.check_circle,
                color: Colors.green.shade700,
                size: 60,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              "Payment Completed!",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: Colors.green,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              "VNPAY has successfully authenticated and authorized your transaction. Redirecting back to Tiem Hoa Xinh...",
              style: TextStyle(color: Colors.grey, fontSize: 13),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
