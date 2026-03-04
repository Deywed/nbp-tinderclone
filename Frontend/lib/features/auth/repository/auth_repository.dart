import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tinderclone/api_endpoints.dart';
import 'package:tinderclone/common/user_model.dart';

class AuthRepository {
  static const Duration _requestTimeout = Duration(seconds: 10);

  Future<String?> login(String email, String password) async {
    try {
      final url = Uri.parse(ApiEndpoints.login);
      final response = await http
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'email': email, 'password': password}),
          )
          .timeout(_requestTimeout);

      if (response.statusCode == 200) {
        print("proslo");
        final body = jsonDecode(response.body);
        if (body is! Map<String, dynamic>) {
          return 'Invalid login response from server.';
        }

        final token = body['token'] ?? body['Token'];

        if (token is String && token.isNotEmpty) {
          await _persistLoginSession(token, email);
        }

        return null;
      }

      if (response.body.isNotEmpty) {
        return response.body;
      }

      return 'Login failed. Check credentials.';
    } catch (_) {
      return 'Network error. Please try again.';
    }
  }

  Future<bool> register(UserModel user) async {
    try {
      final url = Uri.parse(ApiEndpoints.register);

      final minAgePref = user.userPreferences?.minAgePref ?? 18;
      final maxAgePref = user.userPreferences?.maxAgePref ?? 99;
      final interestedIn = user.userPreferences?.interestedIn.index ?? 2;

      final response = await http
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'email': user.email,
              'password': user.passwordHash,
              'firstName': user.firstName,
              'lastName': user.lastName,
              'age': user.age ?? 18,
              'bio': user.bio ?? '',
              'gender': user.gender?.index ?? 2,
              'userPreferences': {
                'minAgePref': minAgePref,
                'maxAgePref': maxAgePref,
                'interestedIn': interestedIn,
              },
              "interests": user.interests ?? [],
            }),
          )
          .timeout(_requestTimeout);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  Future<void> _persistLoginSession(String token, String fallbackEmail) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);

    final emailFromToken = _extractEmailFromJwt(token) ?? fallbackEmail;
    await prefs.setString('current_user_email', emailFromToken);

    final userId = await _getAllUsers(emailFromToken);
    if (userId != null && userId.isNotEmpty) {
      await prefs.setString('current_user_id', userId);
    }
  }

  String? _extractEmailFromJwt(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;

      final payload = parts[1];
      final normalized = base64Url.normalize(payload);
      final decoded = utf8.decode(base64Url.decode(normalized));
      final json = jsonDecode(decoded);

      final sub = json['sub'];
      if (sub is String && sub.isNotEmpty) {
        return sub;
      }
    } catch (_) {
      return null;
    }
    return null;
  }

  Future<String?> _getAllUsers(String email) async {
    try {
      final usersUrl = Uri.parse(ApiEndpoints.getAllUsers);
      final response = await http.get(usersUrl).timeout(_requestTimeout);
      if (response.statusCode != 200) return null;

      final body = jsonDecode(response.body);
      if (body is! List) return null;

      for (final item in body) {
        if (item is! Map<String, dynamic>) continue;

        final userEmail = item['email']?.toString().toLowerCase();
        if (userEmail == email.toLowerCase()) {
          final userId = item['id']?.toString();
          if (userId != null && userId.isNotEmpty) {
            return userId;
          }
        }
      }
    } catch (_) {
      return null;
    }

    return null;
  }
}
