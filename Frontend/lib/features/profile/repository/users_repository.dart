import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tinderclone/api_endpoints.dart';
import 'package:tinderclone/common/user_model.dart';

class UsersRepository {
  static const Duration _requestTimeout = Duration(seconds: 10);

  Future<Map<String, String>> _authHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token') ?? '';
    return {
      'Content-Type': 'application/json',
      if (token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  Future<UserModel?> getUserById(String id) async {
    try {
      final url = Uri.parse(ApiEndpoints.getUser(id));
      final response = await http
          .get(url, headers: await _authHeaders())
          .timeout(_requestTimeout);

      if (response.statusCode == 200) {
        return UserModel.fromJson(jsonDecode(response.body));
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<List<UserModel>> getAllUsers() async {
    try {
      final url = Uri.parse(ApiEndpoints.getAllUsers);
      final response = await http
          .get(url, headers: await _authHeaders())
          .timeout(_requestTimeout);

      if (response.statusCode == 200) {
        final List<dynamic> body = jsonDecode(response.body);
        return body
            .whereType<Map<String, dynamic>>()
            .map(UserModel.fromJson)
            .toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  Future<bool> updateUser(String id, UserModel user) async {
    try {
      final url = Uri.parse(ApiEndpoints.updateUser(id));
      final response = await http
          .put(
            url,
            headers: await _authHeaders(),
            body: jsonEncode(user.toJson()),
          )
          .timeout(_requestTimeout);

      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  Future<bool> deleteUser(String id) async {
    try {
      final url = Uri.parse(ApiEndpoints.deleteUser(id));
      final response = await http
          .delete(url, headers: await _authHeaders())
          .timeout(_requestTimeout);

      return response.statusCode == 204;
    } catch (_) {
      return false;
    }
  }

  Future<UserModel?> getUserByEmail(String email) async {
    try {
      final url = Uri.parse(ApiEndpoints.getUserByEmail);
      final response = await http
          .get(url, headers: await _authHeaders())
          .timeout(_requestTimeout);

      if (response.statusCode == 200) {
        return UserModel.fromJson(jsonDecode(response.body));
      }
      return null;
    } catch (_) {
      return null;
    }
  }
}
