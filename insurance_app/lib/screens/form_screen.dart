import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'dart:convert';

// Model for table column
class TableColumn {
  final String name;
  final String type;
  final bool isIdentity;

  TableColumn({
    required this.name,
    required this.type,
    required this.isIdentity,
  });

  factory TableColumn.fromJson(Map<String, dynamic> json) {
    return TableColumn(
      name: json['name'],
      type: json['type'] ?? '',
      isIdentity: json['is_identity'] ?? false,
    );
  }
}

class FormScreen extends StatefulWidget {
  final String tableName;

  const FormScreen({Key? key, required this.tableName}) : super(key: key);

  @override
  State<FormScreen> createState() => _FormScreenState();
}

class _FormScreenState extends State<FormScreen> {
  bool _isLoading = true;
  List<TableColumn> _fields = [];
  final Map<String, TextEditingController> _controllers = {};

  @override
  void initState() {
    super.initState();
    _fetchTableSchema();
  }

  Future<void> _fetchTableSchema() async {
    final result = await ApiService.getTableSchema(widget.tableName);

    setState(() {
      _isLoading = false;

      if (result['success']) {
        _fields = (result['fields'] as List)
            .map((item) => TableColumn.fromJson(item))
            .where((field) => !field.isIdentity) // exclude identity fields
            .toList();

        for (var field in _fields) {
          _controllers[field.name] = TextEditingController();
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message'] ?? 'No fields found.')),
        );
      }
    });
  }

  Future<void> _submitForm() async {
    final formData = <String, String>{};
    for (var field in _fields) {
      formData[field.name] = _controllers[field.name]?.text ?? '';
    }

    final result = await ApiService.insertData(widget.tableName, formData);

    if (result['success']) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Form submitted successfully!")),
      );

      // Clear form
      for (var controller in _controllers.values) {
        controller.clear();
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message'] ?? 'Submission failed')),
      );
    }
  }

  @override
  void dispose() {
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Form for ${widget.tableName}")),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Expanded(
                    child: ListView(
                      children: _fields.map((field) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: TextField(
                            controller: _controllers[field.name],
                            decoration: InputDecoration(
                             labelText: "${field.name[0].toUpperCase()}${field.name.substring(1)}",
                              border: const OutlineInputBorder(),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: _submitForm,
                    child: const Text("Submit"),
                  ),
                ],
              ),
            ),
    );
  }
}