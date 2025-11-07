import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AuthService extends ChangeNotifier {
  String? _token;
  String? _role; // admin / staff / client
  String? _name;
  bool _isLoading = false;

  String baseUrl = "https://crm.msmesoftwares.com/perfex_mobile_app_api"; // 🔹 change to your Perfex API URL

  String? get token => _token;
  String? get role => _role;
  String? get name => _name;
  bool get isLoading => _isLoading;

  /// 🔐 LOGIN FUNCTION
  Future<bool> login(String email, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/login'),
        body: {
          'email': email,
          'password': password,
        },
      );

      print("Response: ${response.body}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['success'] == 1) {
          // ✅ Extract user details from API
          final user = data['user'];
          print(user);
          _token = user['authentication_token'];
          _role = user['admin'] == 1 ? 'staff' : 'client';
          // You can set based on your logic
          _name = "${user['firstname']} ${user['lastname']}";

          // Save locally
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('token', _token!);
          await prefs.setString('staffId', user['staffid'].toString());
          // if user['admin'] is 1 role is staff else customer
          await prefs.setString('role', _role.toString());
          await prefs.setString('name', _name!);

          _isLoading = false;
          notifyListeners();
          return true;
        } else {
          debugPrint("Login failed: ${data['message']}");
        }
      }
    } catch (e) {
      debugPrint("Login error: $e");
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }


  /// 🚪 LOGOUT FUNCTION
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    _token = null;
    _role = null;
    _name = null;

    notifyListeners();
  }

  /// 🔁 AUTO LOGIN CHECK
  Future<User?> getStoredUser() async {
    final prefs = await SharedPreferences.getInstance();
    final savedToken = prefs.getString('token');
    final savedRole = prefs.getString('role');
    final savedName = prefs.getString('name');

    if (savedToken != null && savedRole != null) {
      _token = savedToken;
      _role = savedRole;
      _name = savedName;
      notifyListeners();
      return User(name: savedName ?? '', role: savedRole);
    }
    return null;
  }
}

class User {
  final String name;
  final String role;
  User({required this.name, required this.role});
}
