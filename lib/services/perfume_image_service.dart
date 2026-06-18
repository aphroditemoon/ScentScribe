
import 'dart:async';

import 'package:dio/dio.dart';


class PerfumeImageService {
  PerfumeImageService._internal()
      : _dio = Dio(
          BaseOptions(
            connectTimeout: const Duration(seconds: 8),
            receiveTimeout: const Duration(seconds: 8),
            followRedirects: true,
            validateStatus: (status) => status != null && status < 500,
          ),
        );

  static final PerfumeImageService instance = PerfumeImageService._internal();

  final Dio _dio;
  final Map<String, String?> _memoryCache = <String, String?>{};

  static const String placeholderAsset = 'assets/images/perfume_placeholder.png';


  static const Map<String, String> _knownQueries = <String, String>{
    'dior sauvage': 'Dior Sauvage Eau de Parfum bottle product photo',
    'sauvage dior': 'Dior Sauvage Eau de Parfum bottle product photo',
    'chanel no 5': 'Chanel No. 5 perfume bottle product photo',
    'chanel no. 5': 'Chanel No. 5 perfume bottle product photo',
    'chanel n5': 'Chanel No. 5 perfume bottle product photo',
    'ariana grande cloud': 'Ariana Grande Cloud perfume bottle product photo',
    'cloud ariana grande': 'Ariana Grande Cloud perfume bottle product photo',
    'ysl black opium': 'YSL Black Opium perfume bottle product photo',
    'yves saint laurent black opium': 'Yves Saint Laurent Black Opium perfume bottle product photo',
    'black opium ysl': 'YSL Black Opium perfume bottle product photo',
  };

  Future<String?> findImageUrl({
    required String perfumeName,
    String? brand,
  }) async {
    final key = _normalize('${brand ?? ''} $perfumeName');
    if (key.isEmpty) return null;

    if (_memoryCache.containsKey(key)) return _memoryCache[key];

    final searchQuery = _buildSearchQuery(perfumeName: perfumeName, brand: brand);
    if (searchQuery.isEmpty) {
      _memoryCache[key] = null;
      return null;
    }

    try {
      final url = _bingThumbnailUrl(searchQuery);


      final response = await _dio.get<List<int>>(
        url,
        options: Options(responseType: ResponseType.bytes),
      );
      final isImage = (response.headers.value('content-type') ?? '')
          .toLowerCase()
          .startsWith('image/');

      final result = isImage ? url : null;
      _memoryCache[key] = result;
      return result;
    } catch (_) {
      _memoryCache[key] = null;
      return null;
    }
  }

  String _buildSearchQuery({required String perfumeName, String? brand}) {
    final rawName = perfumeName.trim();
    final rawBrand = (brand ?? '').trim();
    final normalizedName = _normalize(rawName);
    final normalizedFull = _normalize('$rawBrand $rawName');

    for (final entry in _knownQueries.entries) {
      if (normalizedName == entry.key || normalizedFull == entry.key) {
        return entry.value;
      }
    }

    final pieces = <String>[];
    if (rawBrand.isNotEmpty) pieces.add(rawBrand);
    if (rawName.isNotEmpty) pieces.add(rawName);
    if (pieces.isEmpty) return '';

    return '${pieces.join(' ')} perfume bottle product photo official';
  }

  String _bingThumbnailUrl(String query) {
    final encoded = Uri.encodeComponent(query);
    return 'https://tse1.mm.bing.net/th?q=$encoded&w=420&h=420&c=7&rs=1&p=0&o=5&pid=1.7';
  }

  String _normalize(String value) {
    return value
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), ' ')
        .trim()
        .replaceAll(RegExp(r'\s+'), ' ');
  }
}


class Debouncer {
  Debouncer({this.delay = const Duration(milliseconds: 650)});

  final Duration delay;
  Timer? _timer;

  void run(void Function() action) {
    _timer?.cancel();
    _timer = Timer(delay, action);
  }

  void dispose() => _timer?.cancel();
}
