import 'dart:async';
import 'package:flutter/material.dart';
import '../services/api_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _dobController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false;

  bool _usernameAvailable = true;
  bool _emailAvailable = true;
  bool _phoneAvailable = true;

  bool _usernameTouched = false;
  bool _emailTouched = false;
  bool _phoneTouched = false;
  bool _passwordTouched = false;
  bool _confirmTouched = false;
  bool _nameTouched = false;
  bool _phoneFormatTouched = false;
  bool _dobTouched = false;

  Timer? _debounce;

  void _onChangedDebounced(String type, String value) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    _debounce = Timer(const Duration(milliseconds: 500), () async {
      if (value.isEmpty) return;
      bool available = false;
      if (type == 'username') {
        available = await ApiService.isUsernameAvailable(value);
        setState(() => _usernameAvailable = available);
      } else if (type == 'email') {
        available = await ApiService.isEmailAvailable(value);
        setState(() => _emailAvailable = available);
      } else if (type == 'phone') {
        available = await ApiService.isPhoneAvailable(value);
        setState(() => _phoneAvailable = available);
      }
    });
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2000),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _dobController.text = "${picked.toLocal()}".split(' ')[0];
      });
    }
  }

  bool _allValid() {
    return _formKey.currentState?.validate() == true &&
        _usernameAvailable &&
        _emailAvailable &&
        _phoneAvailable;
  }

  void _register() async {
    if (!_allValid()) return;

    setState(() => _isLoading = true);

    final user = {
      "name": _nameController.text.trim(),
      "username": _usernameController.text.trim(),
      "dob": _dobController.text.trim(),
      "email": _emailController.text.trim(),
      "phone": _phoneController.text.trim(),
      "password": _passwordController.text.trim(),
    };

    final result = await ApiService.register(user);
    setState(() => _isLoading = false);

    if (result['success']) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text("Registration Successful 🎉"),
          content: const Text("You can now log in with your credentials."),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context);
              },
              child: const Text("OK"),
            ),
          ],
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message'] ?? "Registration failed.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Register")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          autovalidateMode: AutovalidateMode.disabled,
          child: Column(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: "Full Name"),
                onChanged: (_) => setState(() => _nameTouched = true),
                validator: (_) =>
                    _nameTouched && _nameController.text.trim().isEmpty
                    ? "Enter your name"
                    : null,
              ),
              TextFormField(
                controller: _usernameController,
                decoration: InputDecoration(
                  labelText: "Username",
                  suffixIcon: _usernameTouched
                      ? _usernameAvailable
                            ? const Icon(Icons.check, color: Colors.green)
                            : const Icon(Icons.close, color: Colors.red)
                      : null,
                ),
                onChanged: (val) {
                  setState(() => _usernameTouched = true);
                  _onChangedDebounced("username", val);
                },
                validator: (_) {
                  if (!_usernameTouched) return null;
                  if (_usernameController.text.trim().isEmpty) {
                    return "Enter a username";
                  }
                  if (!_usernameAvailable) {
                    return "Username already taken";
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _dobController,
                readOnly: true,
                onTap: () {
                  _dobTouched = true;
                  _pickDate();
                },
                decoration: const InputDecoration(labelText: "Date of Birth"),
                validator: (_) => _dobTouched && _dobController.text.isEmpty
                    ? "Pick your date of birth"
                    : null,
              ),
              TextFormField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: "Email",
                  suffixIcon: _emailTouched
                      ? _emailAvailable
                            ? const Icon(Icons.check, color: Colors.green)
                            : const Icon(Icons.close, color: Colors.red)
                      : null,
                ),
                keyboardType: TextInputType.emailAddress,
                onChanged: (val) {
                  setState(() => _emailTouched = true);
                  _onChangedDebounced("email", val);
                },
                validator: (_) {
                  final val = _emailController.text.trim();
                  if (!_emailTouched) return null;
                  if (val.isEmpty) return "Enter your email";
                  final emailRegex = RegExp(
                    r"^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$",
                  );
                  if (!emailRegex.hasMatch(val)) return "Enter a valid email";
                  if (!_emailAvailable) return "Email already registered";
                  return null;
                },
              ),
              TextFormField(
                controller: _phoneController,
                decoration: InputDecoration(
                  labelText: "Phone Number",
                  suffixIcon: _phoneTouched
                      ? _phoneAvailable
                            ? const Icon(Icons.check, color: Colors.green)
                            : const Icon(Icons.close, color: Colors.red)
                      : null,
                ),
                keyboardType: TextInputType.phone,
                onChanged: (val) {
                  setState(() {
                    _phoneTouched = true;
                    _phoneFormatTouched = true;
                  });
                  _onChangedDebounced("phone", val);
                },
                validator: (_) {
                  final val = _phoneController.text.trim();
                  if (!_phoneTouched) return null;
                  if (val.isEmpty) return "Enter phone number";
                  if (_phoneFormatTouched && val.length < 10) {
                    return "Enter at least 10 digits";
                  }
                  if (!_phoneAvailable) return "Phone number already in use";
                  return null;
                },
              ),
              TextFormField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(labelText: "Password"),
                onChanged: (_) => setState(() => _passwordTouched = true),
                validator: (_) =>
                    _passwordTouched && _passwordController.text.length < 10
                    ? "Password must be at least 10 characters"
                    : null,
              ),
              TextFormField(
                controller: _confirmPasswordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: "Confirm Password",
                ),
                onChanged: (_) => setState(() => _confirmTouched = true),
                validator: (_) =>
                    _confirmTouched &&
                        _confirmPasswordController.text !=
                            _passwordController.text
                    ? "Passwords do not match"
                    : null,
              ),
              const SizedBox(height: 20),
              _isLoading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed: _allValid() ? _register : null,
                      child: const Text("Register"),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
