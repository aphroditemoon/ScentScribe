
import 'dart:async';
import 'package:dio/dio.dart';
import 'package:geolocator/geolocator.dart';
import '../models/perfume_model.dart';

class WeatherService {
  static final WeatherService _instance = WeatherService._internal();
  factory WeatherService() => _instance;
  WeatherService._internal();

  final Dio _dio = Dio(BaseOptions(
    baseUrl: 'https://api.openweathermap.org/data/2.5',
    connectTimeout: const Duration(seconds: 12),
    receiveTimeout: const Duration(seconds: 12),
  ));

  static const String _apiKey = 'YOUR_OPENWEATHERMAP_API_KEY';

  WeatherSnapshot? _cachedWeather;
  Position? _cachedPosition;
  DateTime? _lastFetch;
  DateTime? _lastPositionFetch;


  static const Duration _weatherCacheDuration = Duration(minutes: 20);
  static const Duration _locationCacheDuration = Duration(minutes: 5);

  Future<WeatherSnapshot?> getCurrentWeather() async {
    if (_cachedWeather != null && _lastFetch != null) {
      if (DateTime.now().difference(_lastFetch!) < _weatherCacheDuration) {
        return _cachedWeather;
      }
    }

    try {
      final position = await _getLocation();
      if (position == null) return _getMockWeather();

      final response = await _dio.get(
        '/weather',
        queryParameters: {
          'lat': position.latitude.toStringAsFixed(6),
          'lon': position.longitude.toStringAsFixed(6),
          'appid': _apiKey,
          'units': 'metric',
          'lang': 'en',
        },
      );

      if (response.statusCode == 200) {
        final data = response.data;
        _cachedWeather = WeatherSnapshot(
          condition: data['weather'][0]['main'] ?? 'Clear',
          description: data['weather'][0]['description'],
          temperature: (data['main']['temp'] as num).toDouble(),
          humidity: (data['main']['humidity'] as num).toDouble(),
          city: data['name'],
          icon: data['weather'][0]['icon'],
          windSpeed: (data['wind']['speed'] as num?)?.toDouble(),
          feelsLike: (data['main']['feels_like'] as num?)?.toDouble(),
          pressure: (data['main']['pressure'] as num?)?.toDouble(),
          uvIndex: null,
        );
        _lastFetch = DateTime.now();
        return _cachedWeather;
      }
    } catch (e) {

      if (_cachedWeather != null) return _cachedWeather;
      return _getMockWeather();
    }
    return _cachedWeather ?? _getMockWeather();
  }


  Future<Position?> _getLocation() async {

    if (_cachedPosition != null && _lastPositionFetch != null) {
      if (DateTime.now().difference(_lastPositionFetch!) < _locationCacheDuration) {
        return _cachedPosition;
      }
    }

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return _cachedPosition;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return _cachedPosition;
      }
      if (permission == LocationPermission.deniedForever) return _cachedPosition;


      Position? position;
      try {
        position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.best,
          timeLimit: const Duration(seconds: 8),
        );
      } catch (_) {

        try {
          position = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.medium,
            timeLimit: const Duration(seconds: 5),
          );
        } catch (_) {

          position = await Geolocator.getLastKnownPosition();
        }
      }

      if (position != null) {
        _cachedPosition = position;
        _lastPositionFetch = DateTime.now();
      }
      return _cachedPosition;
    } catch (e) {
      return _cachedPosition;
    }
  }

  WeatherSnapshot _getMockWeather() {
    final hour = DateTime.now().hour;
    double temp = hour >= 10 && hour <= 15 ? 32.5 : 27.0;
    double humidity = hour >= 14 && hour <= 17 ? 78.0 : 65.0;
    double feelsLike = temp + (humidity > 70 ? 3 : 1.5);
    String condition = hour >= 14 && hour <= 16 ? 'Clouds' : 'Clear';

    return WeatherSnapshot(
      condition: condition,
      description: condition == 'Clouds' ? 'partly cloudy' : 'clear sky',
      temperature: temp,
      humidity: humidity,
      city: 'Jakarta',
      feelsLike: feelsLike,
      windSpeed: 3.5,
      pressure: 1010,
    );
  }

  String getCurrentTimeOfDay() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 10) return 'morning';
    if (hour >= 10 && hour < 14) return 'late morning';
    if (hour >= 14 && hour < 17) return 'afternoon';
    if (hour >= 17 && hour < 20) return 'evening';
    return 'night';
  }

  Future<List<WeatherSnapshot>> getWeekForecast() async {
    try {
      final position = await _getLocation();
      if (position == null) return _getMockForecast();

      final response = await _dio.get(
        '/forecast',
        queryParameters: {
          'lat': position.latitude.toStringAsFixed(6),
          'lon': position.longitude.toStringAsFixed(6),
          'appid': _apiKey,
          'units': 'metric',
          'cnt': 7,
        },
      );

      if (response.statusCode == 200) {
        final list = response.data['list'] as List;
        return list.map((item) => WeatherSnapshot(
          condition: item['weather'][0]['main'],
          description: item['weather'][0]['description'],
          temperature: (item['main']['temp'] as num).toDouble(),
          humidity: (item['main']['humidity'] as num).toDouble(),
          icon: item['weather'][0]['icon'],
          windSpeed: (item['wind']['speed'] as num?)?.toDouble(),
          feelsLike: (item['main']['feels_like'] as num?)?.toDouble(),
        )).toList();
      }
    } catch (_) {}
    return _getMockForecast();
  }

  List<WeatherSnapshot> _getMockForecast() {
    final conditions = ['Clear', 'Clouds', 'Rain', 'Clear', 'Clouds', 'Clear', 'Clear'];
    final temps = [32.0, 29.0, 26.0, 33.0, 30.0, 31.0, 34.0];
    final humidities = [65.0, 75.0, 85.0, 60.0, 70.0, 63.0, 58.0];
    return List.generate(7, (i) => WeatherSnapshot(
      condition: conditions[i],
      description: conditions[i].toLowerCase(),
      temperature: temps[i],
      humidity: humidities[i],
      feelsLike: temps[i] + 2,
    ));
  }
}
