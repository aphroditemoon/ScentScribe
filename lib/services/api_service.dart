
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/perfume_model.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  static const String _baseUrl =
      'http://10.0.2.2:3000';


  late final Dio _dio;
  String? _token;

  Future<void> initialize() async {
    _dio = Dio(BaseOptions(
      baseUrl: _baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 15),
      headers: {'Content-Type': 'application/json'},
    ));


    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          _token ??= await _getStoredToken();
          if (_token != null) {
            options.headers['Authorization'] = 'Bearer $_token';
          }
          handler.next(options);
        },
        onError: (error, handler) {
          if (error.response?.statusCode == 401) {
            _token = null;
            _clearToken();
          }
          handler.next(error);
        },
      ),
    );


    _dio.interceptors.add(LogInterceptor(
      requestBody: false,
      responseBody: false,
      error: true,
    ));
  }


  Future<Map<String, dynamic>?> register(
      String email, String password, String name) async {
    try {
      final res = await _dio.post('/api/auth/register', data: {
        'email': email,
        'password': password,
        'name': name,
      });
      await _saveToken(res.data['token']);
      return res.data;
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<Map<String, dynamic>?> login(String email, String password) async {
    try {
      final res = await _dio.post('/api/auth/login', data: {
        'email': email,
        'password': password,
      });
      await _saveToken(res.data['token']);
      return res.data;
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<void> logout() async {
    _token = null;
    await _clearToken();
  }


  Future<List<Map<String, dynamic>>> fetchPerfumes(
      {bool wishlist = false}) async {
    try {
      final res = await _dio.get('/api/perfumes',
          queryParameters: wishlist ? {'wishlist': 'true'} : null);
      return List<Map<String, dynamic>>.from(res.data);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<Map<String, dynamic>> savePerfumeToCloud(
      Perfume perfume) async {
    try {
      final data = {
        'name': perfume.name,
        'brand': perfume.brand,
        'description': perfume.description,
        'family': perfume.family.toString().split('.').last,
        'notes': perfume.notes.map((n) => n.toMap()).toList(),
        'ml_owned': perfume.mlOwned,
        'price': perfume.price,
        'rating': perfume.rating,
        'is_wishlist': perfume.isWishlist,
        'best_seasons': perfume.bestSeasons
            .map((s) => s.toString().split('.').last)
            .toList(),
        'best_times': perfume.bestTimes
            .map((t) => t.toString().split('.').last)
            .toList(),
        'occasions': perfume.occasions
            .map((o) => o.toString().split('.').last)
            .toList(),
        'country_of_origin': perfume.countryOfOrigin,
        'launch_year': perfume.launchYear,
        'perfumer': perfume.perfumer,
      };
      final res = await _dio.post('/api/perfumes', data: data);
      return res.data;
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<void> deletePerfumeFromCloud(String id) async {
    try {
      await _dio.delete('/api/perfumes/$id');
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }


  Future<List<Map<String, dynamic>>> fetchJournal(
      {String? perfumeId}) async {
    try {
      final res = await _dio.get('/api/journal',
          queryParameters:
              perfumeId != null ? {'perfume_id': perfumeId} : null);
      return List<Map<String, dynamic>>.from(res.data);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<Map<String, dynamic>> saveJournalEntry(
      JournalEntry entry) async {
    try {
      final data = {
        'perfume_id': entry.perfumeId,
        'longevity_rating': entry.longevityRating,
        'sillage_rating': entry.sillageRating,
        'projection_rating': entry.projectionRating,
        'mood_rating': entry.moodRating,
        'notes': entry.notes,
        'weather_condition': entry.weather?.condition,
        'weather_temp': entry.weather?.temperature,
        'weather_humidity': entry.weather?.humidity,
        'occasion': entry.occasion,
        'moods': entry.moods,
        'temperature': entry.temperature,
        'humidity': entry.humidity,
      };
      final res = await _dio.post('/api/journal', data: data);
      return res.data;
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }


  Future<List<Map<String, dynamic>>> getAIRecommendations({
    required double temperature,
    required double humidity,
    required String condition,
    required String timeOfDay,
  }) async {
    try {
      final res = await _dio.post('/api/ai/recommend', data: {
        'temperature': temperature,
        'humidity': humidity,
        'condition': condition,
        'time_of_day': timeOfDay,
      });
      return List<Map<String, dynamic>>.from(res.data);
    } on DioException catch (e) {

      return [];
    }
  }


  Future<Map<String, dynamic>> getStats() async {
    try {
      final res = await _dio.get('/api/analytics/stats');
      return Map<String, dynamic>.from(res.data);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }


  Future<bool> isServerReachable() async {
    try {
      final res = await _dio.get('/health');
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }


  Future<void> _saveToken(String token) async {
    _token = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
  }

  Future<String?> _getStoredToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  Future<void> _clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
  }

  bool get isAuthenticated => _token != null;
}

class ApiException implements Exception {
  final String message;
  final int? statusCode;

  ApiException(this.message, {this.statusCode});

  factory ApiException.fromDio(DioException e) {
    final code = e.response?.statusCode;
    final msg = e.response?.data?['error'] ??
        e.message ??
        'Network error';
    return ApiException(msg, statusCode: code);
  }

  @override
  String toString() => 'ApiException: $message (HTTP $statusCode)';
}
