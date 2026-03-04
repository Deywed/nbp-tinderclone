import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tinderclone/api_endpoints.dart';
import 'package:tinderclone/common/user_model.dart';

class SwipeRepository {
  static const Duration _requestTimeout = Duration(seconds: 10);

  Future<Map<String, String>> _authHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token') ?? '';
    return {
      'Content-Type': 'application/json',
      if (token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  Future<bool> likeUser(String userId, String likedUserId) async {
    try {
      final url = Uri.parse(
        '${ApiEndpoints.likeUser}?userId=$userId&likedUserId=$likedUserId',
      );
      final response = await http
          .post(url, headers: await _authHeaders())
          .timeout(_requestTimeout);

      if (response.statusCode == 200) {
        return response.body.contains("match");
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  Future<bool> dislikeUser(String userId, String dislikedUserId) async {
    try {
      final url = Uri.parse(
        '${ApiEndpoints.dislikeUser}?userId=$userId&dislikedUserId=$dislikedUserId',
      );
      final response = await http
          .post(url, headers: await _authHeaders())
          .timeout(_requestTimeout);

      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  Future<List<UserModel>> getMatches(String userId) async {
    try {
      final url = Uri.parse(ApiEndpoints.getMatches(userId));
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

  Future<bool> removeMatch(String userId, String matchedUserId) async {
    try {
      final url = Uri.parse(
        '${ApiEndpoints.removeMatch}?userId=$userId&matchedUserId=$matchedUserId',
      );
      final response = await http
          .delete(url, headers: await _authHeaders())
          .timeout(_requestTimeout);

      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  Future<bool> blockUser(String userId, String blockedUserId) async {
    try {
      final url = Uri.parse(
        '${ApiEndpoints.blockUser}?userId=$userId&blockedUserId=$blockedUserId',
      );
      final response = await http
          .put(url, headers: await _authHeaders())
          .timeout(_requestTimeout);

      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}
