import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'form_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  List<String> _tables = [];
  String? _selectedTable;
  bool _isLoading = false;
  bool _showDropdown = false;

  Future<void> _fetchCompanyTables() async {
    setState(() {
      _isLoading = true;
      _showDropdown = true;
    });

    final result = await ApiService.getCompanyTables();

    setState(() {
      _isLoading = false;
      if (result['success']) {
        _tables = List<String>.from(result['tables']);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message'])),
        );
      }
    });
  }

  void _proceedToForm() {
    if (_selectedTable != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => FormScreen(tableName: _selectedTable!),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Dashboard")),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: _fetchCompanyTables,
                child: const Text("New Quote"),
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: () {
                  // Handle history screen logic
                },
                child: const Text("History"),
              ),
              const SizedBox(height: 20),
              if (_isLoading) const CircularProgressIndicator(),
              if (_showDropdown && !_isLoading)
                DropdownButton<String>(
                  hint: const Text("Select Company Table"),
                  value: _selectedTable,
                  onChanged: (value) {
                    setState(() {
                      _selectedTable = value;
                    });
                  },
                  items: _tables
                      .map((table) => DropdownMenuItem<String>(
                            value: table,
                            child: Text(table),
                          ))
                      .toList(),
                ),
              const SizedBox(height: 20),
              if (_selectedTable != null)
                ElevatedButton(
                  onPressed: _proceedToForm,
                  child: const Text("Proceed"),
                ),
            ],
          ),
        ),
      ),
    );
  }
}