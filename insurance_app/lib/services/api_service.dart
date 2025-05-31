import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  // ✅ Your FastAPI backend IP
  static const String baseUrl = "http://127.0.0.1:8000";

  // 🔐 Login API
  static Future<Map<String, dynamic>> login(
    String username,
    String password,
  ) async {
    final response = await http.post(
      Uri.parse("$baseUrl/login"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"username": username, "password": password}),
    );

    if (response.statusCode == 200) {
      return {"success": true, "data": jsonDecode(response.body)};
    } else {
      return {"success": false, "message": "Invalid username or password"};
    }
  }

  // 📝 Register API
  static Future<Map<String, dynamic>> register(
    Map<String, dynamic> user,
  ) async {
    final response = await http.post(
      Uri.parse("$baseUrl/register"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(user),
    );

    if (response.statusCode == 200) {
      return {"success": true, "data": jsonDecode(response.body)};
    } else {
      final body = jsonDecode(response.body);
      return {
        "success": false,
        "message": body['detail'] ?? "Registration failed.",
      };
    }
  }

  // 👤 Check username availability
  static Future<bool> isUsernameAvailable(String username) async {
    try {
      final response = await http.get(
        Uri.parse("$baseUrl/check-username?username=$username"),
      );
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        return json['available'] == true;
      }
    } catch (_) {}
    return false;
  }

  // 📧 Check email availability
  static Future<bool> isEmailAvailable(String email) async {
    try {
      final response = await http.get(
        Uri.parse("$baseUrl/check-email?email=$email"),
      );
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        return json['available'] == true;
      }
    } catch (_) {}
    return false;
  }
static Future<Map<String, dynamic>> getCompanyTables() async {
    try {
      final response = await http.get(Uri.parse("$baseUrl/company-tables"));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {"success": true, "tables": data["tables"]};
      } else {
        return {"success": false, "message": "Failed to fetch tables"};
      }
    } catch (e) {
      return {"success": false, "message": "Error: $e"};
    }
  }
 static Future<Map<String, dynamic>> getTableSchema(String tableName) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/get-table-schema?table_name=$tableName'));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {"success": true, "fields": data};
      } else {
        return {"success": false, "message": "Failed to load schema"};
      }
    } catch (e) {
      return {"success": false, "message": "Error: $e"};
    }
  }

  static Future<Map<String, dynamic>> insertData(String tableName, Map<String, String> data) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/insert-data/$tableName'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(data),
      );

      if (response.statusCode == 200) {
        return {"success": true};
      } else {
        final body = jsonDecode(response.body);
        return {"success": false, "message": body['detail'] ?? "Insert failed"};
      }
    } catch (e) {
      return {"success": false, "message": "Error: $e"};
    }
  }
  // 📱 Check phone number availability
  static Future<bool> isPhoneAvailable(String phone) async {
    try {
      final response = await http.get(
        Uri.parse("$baseUrl/check-phone?phone=$phone"),
      );
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        return json['available'] == true;
      }
    } catch (_) {}
    return false;
  }

}
