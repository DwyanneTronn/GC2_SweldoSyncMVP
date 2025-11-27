import 'package:http/http.dart' as http;
import 'dart:convert';

class ApiService {
  // For local development, use localhost. For production, use the deployed URL
  // static const String baseApiUrl = 'https://gc2-sweldosyncmvp.onrender.com/api';
  static const String baseApiUrl = 'http://localhost:3000/api';
  static String? _authToken;

  static void setAuthToken(String? token) {
    _authToken = token;
  }

  static Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    if (_authToken != null) 'Authorization': 'Bearer $_authToken',
  };

  // Auth endpoints
  static Future<Map<String, dynamic>> register({
    required String email,
    required String password,
    required String name,
    required String companyName,
    required String industry,
  }) async {
    final response = await http.post(
      Uri.parse('$baseApiUrl/auth/register'),
      headers: _headers,
      body: json.encode({
        'email': email,
        'password': password,
        'name': name,
        'companyName': companyName,
        'industry': industry,
      }),
    ).timeout(
      const Duration(seconds: 10),
      onTimeout: () {
        throw Exception('Registration request timed out. Please check your connection.');
      },
    );

    if (response.statusCode == 201) {
      return json.decode(response.body);
    } else {
      throw Exception(json.decode(response.body)['error'] ?? 'Registration failed');
    }
  }

  static Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseApiUrl/auth/login'),
      headers: _headers,
      body: json.encode({
        'email': email,
        'password': password,
      }),
    ).timeout(
      const Duration(seconds: 10),
      onTimeout: () {
        throw Exception('Login request timed out. Please check your connection.');
      },
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception(json.decode(response.body)['error'] ?? 'Login failed');
    }
  }

  // Employee endpoints
  static Future<List<dynamic>> getEmployees() async {
    final response = await http.get(
      Uri.parse('$baseApiUrl/employees'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['employees'] ?? [];
    } else {
      throw Exception('Failed to load employees');
    }
  }

  static Future<Map<String, dynamic>> createEmployee({
    required String employeeId,
    required String name,
    required String role,
    required double basicSalary,
  }) async {
    final response = await http.post(
      Uri.parse('$baseApiUrl/employees'),
      headers: _headers,
      body: json.encode({
        'employeeId': employeeId,
        'name': name,
        'role': role,
        'basicSalary': basicSalary,
      }),
    ).timeout(
      const Duration(seconds: 10),
      onTimeout: () {
        throw Exception('Request timed out. Please check your connection.');
      },
    );

    if (response.statusCode == 201) {
      return json.decode(response.body);
    } else {
      throw Exception(json.decode(response.body)['error'] ?? 'Failed to create employee');
    }
  }

  // Payroll endpoints
  static Future<Map<String, dynamic>> calculatePayroll({
    required String industry,
    required List<Map<String, dynamic>> employees,
    required String payPeriod,
  }) async {
    final response = await http.post(
      Uri.parse('$baseApiUrl/payroll/calculate'),
      headers: _headers,
      body: json.encode({
        'industry': industry,
        'employees': employees,
        'payPeriod': payPeriod,
      }),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception(json.decode(response.body)['error'] ?? 'Calculation failed');
    }
  }

  // Subscription endpoints
  static Future<List<dynamic>> getSubscriptionPlans() async {
    final response = await http.get(
      Uri.parse('$baseApiUrl/subscriptions/plans'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['plans'] ?? [];
    } else {
      throw Exception('Failed to load plans');
    }
  }

  static Future<Map<String, dynamic>> getSubscription() async {
    final response = await http.get(
      Uri.parse('$baseApiUrl/subscriptions'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load subscription');
    }
  }

  static Future<Map<String, dynamic>> createSubscription({
    required String plan,
    String paymentMethod = 'credit_card',
  }) async {
    final response = await http.post(
      Uri.parse('$baseApiUrl/subscriptions'),
      headers: _headers,
      body: json.encode({
        'plan': plan,
        'paymentMethod': paymentMethod,
      }),
    );

    if (response.statusCode == 201) {
      return json.decode(response.body);
    } else {
      throw Exception(json.decode(response.body)['error'] ?? 'Subscription creation failed');
    }
  }

  // Holidays endpoint
  static Future<List<dynamic>> getHolidays() async {
    final response = await http.get(
      Uri.parse('$baseApiUrl/holidays'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load holidays');
    }
  }

  // Analytics endpoints
  static Future<Map<String, dynamic>> getDashboardAnalytics({String? startDate, String? endDate}) async {
    String url = '$baseApiUrl/analytics/dashboard';
    if (startDate != null || endDate != null) {
      final params = <String>[];
      if (startDate != null) params.add('startDate=$startDate');
      if (endDate != null) params.add('endDate=$endDate');
      url += '?${params.join('&')}';
    }

    try {
      final response = await http.get(
        Uri.parse(url),
        headers: _headers,
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Request timed out');
        },
      );

      if (response.statusCode == 200) {
        // Check if response is JSON (not HTML)
        final contentType = response.headers['content-type'] ?? '';
        if (!contentType.contains('application/json')) {
          throw Exception('Server returned invalid response. Please check if backend is running on $baseApiUrl');
        }
        
        try {
          return json.decode(response.body);
        } catch (e) {
          // If JSON decode fails, it might be HTML
          if (response.body.contains('<!DOCTYPE') || response.body.contains('<html')) {
            throw Exception('Server returned HTML instead of JSON. The analytics endpoint may not be available. Please restart the backend server.');
          }
          throw Exception('Invalid JSON response: ${e.toString()}');
        }
      } else if (response.statusCode == 401) {
        throw Exception('Authentication required. Please log in again.');
      } else if (response.statusCode == 404) {
        throw Exception('Analytics endpoint not found. Please ensure the backend server is running the latest code.');
      } else {
        // Try to parse error message
        try {
          final errorBody = json.decode(response.body);
          throw Exception(errorBody['error'] ?? 'Failed to load analytics: ${response.statusCode}');
        } catch (e) {
          throw Exception('Failed to load analytics: ${response.statusCode}');
        }
      }
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }
      throw Exception('Network error: ${e.toString()}');
    }
  }

  static Future<Map<String, dynamic>> getPayrollHistory() async {
    final response = await http.get(
      Uri.parse('$baseApiUrl/payroll/history'),
      headers: _headers,
    ).timeout(
      const Duration(seconds: 10),
      onTimeout: () {
        throw Exception('Request timed out');
      },
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load payroll history');
    }
  }
}

