import 'package:flutter/material.dart';
import 'dart:async';
import '../services/api_service.dart';
import 'register_screen.dart';
import 'dashboard_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _otpController = TextEditingController();

  bool _isOtpRequested = false;
  bool _isOtpVerified = false;
  bool _showRegenerateButton = false;
  bool _regenerateEnabled = false;
  int _regenerateCountdown = 10;
  Timer? _timer;

  static const fixedOtp = "12345";

  void _getOtp() async {
    if (_formKey.currentState!.validate()) {
      final result = await ApiService.login(
        _usernameController.text,
        _passwordController.text,
      );

      if (result['success']) {
        setState(() {
          _isOtpRequested = true;
          _isOtpVerified = false;
          _otpController.clear();
        });
      } else {
        _showErrorDialog("Login Failed", result['message']);
      }
    }
  }

  void _verifyOtp() {
    if (_otpController.text == fixedOtp) {
      setState(() {
        _isOtpVerified = true;
        _showRegenerateButton = false;
        _regenerateEnabled = false;
      });
      _showSuccessDialog("Login Successful", "Welcome, ${_usernameController.text}!");
    } else {
      _showTryAgainDialog();
    }
  }

  void _showTryAgainDialog() {
    showDialog(
      barrierDismissible: false,
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text("Invalid OTP"),
          content: const Text("Incorrect OTP. Please try again."),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _startCountdown();
              },
              child: const Text("Try Again"),
            ),
          ],
        );
      },
    );
  }

  void _startCountdown() {
    setState(() {
      _showRegenerateButton = true;
      _regenerateEnabled = false;
      _regenerateCountdown = 10;
    });

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _regenerateCountdown--;
        if (_regenerateCountdown == 0) {
          _regenerateEnabled = true;
          timer.cancel();
        }
      });
    });
  }

  void _regenerateOtp() {
    setState(() {
      _otpController.clear();
      _isOtpRequested = true;
      _showRegenerateButton = false;
      _regenerateEnabled = false;
    });
  }

  void _showSuccessDialog(String title, String message) {
    showDialog(
      context: context,
      barrierDismissible: false, // Prevent closing dialog by tapping outside
      builder: (_) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close the dialog
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const DashboardScreen()),
              ); // Navigate to Dashboard
            },
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _usernameController.dispose();
    _passwordController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Login")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _usernameController,
                decoration: const InputDecoration(labelText: "Username"),
                validator: (value) =>
                    value!.isEmpty ? "Enter your username" : null,
              ),
              TextFormField(
                controller: _passwordController,
                decoration: const InputDecoration(labelText: "Password"),
                obscureText: true,
                validator: (value) =>
                    value!.isEmpty ? "Enter your password" : null,
              ),
              const SizedBox(height: 20),
              if (!_isOtpRequested)
                ElevatedButton(
                  onPressed: _getOtp,
                  child: const Text("Get OTP"),
                ),
              if (_isOtpRequested && !_isOtpVerified) ...[
                TextFormField(
                  controller: _otpController,
                  decoration: const InputDecoration(labelText: "Enter OTP"),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: _verifyOtp,
                  child: const Text("Verify OTP"),
                ),
              ],
              if (_showRegenerateButton) ...[
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: _regenerateEnabled ? _regenerateOtp : null,
                  child: Text(_regenerateEnabled
                      ? "Regenerate OTP"
                      : "Regenerate OTP (${_regenerateCountdown}s)"),
                ),
              ],
              if (_isOtpVerified)
                const Padding(
                  padding: EdgeInsets.only(top: 20),
                  child: Text("✅ Login Successful",
                      style: TextStyle(color: Colors.green)),
                ),
              const SizedBox(height: 20),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const RegisterScreen()),
                  );
                },
                child: const Text("Not registered? Create an account"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}