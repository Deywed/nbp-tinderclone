import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tinderclone/api_endpoints.dart';
import 'package:tinderclone/common/top_pick_model.dart';
import 'package:tinderclone/common/user_model.dart';

class DiscoveryRepository {
  static const Duration _requestTimeout = Duration(seconds: 10);

  Future<Map<String, String>> _authHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token') ?? '';
    return {
      'Content-Type': 'application/json',
      if (token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  Future<List<UserModel>> getUsersByInterest(String interest) async {
    try {
      final url = Uri.parse(ApiEndpoints.getUsersByInterestDiscovery(interest));
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

  Future<List<TopPickModel>> getTopPicks() async {
    try {
      final url = Uri.parse(ApiEndpoints.getTopPicksDiscovery);
      final response = await http
          .get(url, headers: await _authHeaders())
          .timeout(_requestTimeout);

      if (response.statusCode == 200) {
        final List<dynamic> body = jsonDecode(response.body);
        return body
            .whereType<Map<String, dynamic>>()
            .map(TopPickModel.fromJson)
            .toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  Future<List<UserModel>> getRecommendations(
    String userId,
    List<String> nearbyIds,
  ) async {
    try {
      final queryParams = nearbyIds.map((id) => 'nearbyIds=$id').join('&');
      final rawUrl = '${ApiEndpoints.getRecommendations(userId)}?$queryParams';
      final url = Uri.parse(rawUrl);
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

  Future<List<UserModel>> getDiscoveryFeed(String userId) async {
    try {
      final url = Uri.parse(ApiEndpoints.getDiscoveryFeed(userId));
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

  Future<bool> updateLocation(
    String userId,
    double latitude,
    double longitude,
  ) async {
    try {
      final url = Uri.parse(ApiEndpoints.updateLocationDiscovery(userId));
      final response = await http
          .put(
            url,
            headers: await _authHeaders(),
            body: jsonEncode({'latitude': latitude, 'longitude': longitude}),
          )
          .timeout(_requestTimeout);

      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}
