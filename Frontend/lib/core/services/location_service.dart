import 'dart:async';
import 'dart:convert';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tinderclone/api_endpoints.dart';

class LocationService {
  //singleton pattern
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  LocationService._internal();

  StreamSubscription<Position>? _positionStream;
  Timer? _pingTimer;

  final LocationSettings _locationSettings = const LocationSettings(
    accuracy: LocationAccuracy.high,
    distanceFilter: 500,
  );

  Future<void> startTracking(String userId) async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }

    await stopTracking();

    // Odmah pinguj i pokreni timer svakih 4min
    await _pingOnline(userId);
    _pingTimer = Timer.periodic(
      const Duration(minutes: 4),
      (_) => _pingOnline(userId),
    );

    _positionStream = Geolocator.getPositionStream(
      locationSettings: _locationSettings,
    ).listen((Position position) {
      print("Lokacija: ${position.latitude}, ${position.longitude}");

      _sendLocationToBackend(userId, position);
    });
  }

  Future<void> stopTracking() async {
    _pingTimer?.cancel();
    _pingTimer = null;
    await _positionStream?.cancel();
    _positionStream = null;
  }

  Future<void> _pingOnline(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token') ?? '';
      final headers = {
        'Content-Type': 'application/json',
        if (token.isNotEmpty) 'Authorization': 'Bearer $token',
      };
      await http
          .post(Uri.parse(ApiEndpoints.ping(userId)), headers: headers)
          .timeout(const Duration(seconds: 5));
    } catch (_) {}
  }

  void _sendLocationToBackend(String userId, Position pos) {
    _updateLocationAsync(userId, pos.latitude, pos.longitude);
  }

  Future<void> _updateLocationAsync(
    String userId,
    double lat,
    double lon,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token') ?? '';
      final headers = {
        'Content-Type': 'application/json',
        if (token.isNotEmpty) 'Authorization': 'Bearer $token',
      };
      const timeout = Duration(seconds: 10);

      // Update Redis
      final cacheUrl = Uri.parse(
        '${ApiEndpoints.updateLocationCache}?userId=$userId&lat=$lat&lon=$lon',
      );

      // Update Mongo
      final discoveryUrl = Uri.parse(
        ApiEndpoints.updateLocationDiscovery(userId),
      );
      final body = jsonEncode({'latitude': lat, 'longitude': lon});

      await Future.wait([
        http.post(cacheUrl, headers: headers).timeout(timeout),
        http.put(discoveryUrl, headers: headers, body: body).timeout(timeout),
      ]);
    } catch (e) {
      print('Failed to send location: $e');
    }
  }
}
