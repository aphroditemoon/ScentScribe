
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/perfume_model.dart';
import '../services/database_service.dart';
import '../services/weather_service.dart';
import '../services/ml_engine.dart';

export '../services/ml_engine.dart' show LayeringResult, ScentProfile, PerformancePrediction;

class AppProvider extends ChangeNotifier {
  final DatabaseService _db = DatabaseService();
  final WeatherService _weatherService = WeatherService();
  final MLEngine _ml = MLEngine();
  final Uuid _uuid = const Uuid();


  List<Perfume> _collection = [];
  List<JournalEntry> _journalEntries = [];
  UserProfile? _userProfile;
  WeatherSnapshot? _weather;
  List<ScentRecommendation> _recommendations = [];
  ScentProfile? _scentProfile;
  bool _isLoading = false;
  bool _isWeatherLoading = false;
  String? _error;
  int _selectedNavIndex = 0;


  List<Perfume> get collection => _collection.where((p) => !p.isWishlist).toList();
  List<Perfume> get wishlist => _collection.where((p) => p.isWishlist).toList();
  List<Perfume> get allPerfumes => _collection;
  List<JournalEntry> get journalEntries => _journalEntries;
  UserProfile? get userProfile => _userProfile;
  WeatherSnapshot? get weather => _weather;
  List<ScentRecommendation> get recommendations => _recommendations;
  ScentProfile? get scentProfile => _scentProfile;
  bool get isLoading => _isLoading;
  bool get isWeatherLoading => _isWeatherLoading;
  String? get error => _error;
  int get selectedNavIndex => _selectedNavIndex;
  String get timeOfDay => _weatherService.getCurrentTimeOfDay();


  Future<void> initialize() async {
    _setLoading(true);
    try {
      await Future.wait([
        _loadCollection(),
        _loadJournal(),
        _loadUserProfile(),
        _loadWeather(),
      ]);
      _computeRecommendations();
      _computeScentProfile();
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> _loadCollection() async {
    _collection = await _db.getAllPerfumes();
  }

  Future<void> _loadJournal() async {
    _journalEntries = await _db.getJournalEntries();
  }

  Future<void> _loadUserProfile() async {
    _userProfile = await _db.getUserProfile();
    if (_userProfile == null) {
      _userProfile = UserProfile(
        id: _uuid.v4(),
        name: '-',
        createdAt: DateTime.now(),
        preferredFamilies: ['oriental', 'woody', 'floral'],
      );
      await _db.saveUserProfile(_userProfile!);
    }
  }

  Future<void> _loadWeather() async {
    _isWeatherLoading = true;
    notifyListeners();
    _weather = await _weatherService.getCurrentWeather();
    _isWeatherLoading = false;
    notifyListeners();
  }

  void _computeRecommendations() {
    if (_weather == null || collection.isEmpty) return;
    _recommendations = _ml.rankPerfumesForWeather(
      collection: collection,
      weather: _weather!,
      currentTime: timeOfDay,
      userProfile: _userProfile,
      maxResults: 5,
    );
  }

  void _computeScentProfile() {
    if (_collection.isEmpty) return;
    _scentProfile = _ml.analyzeCollectionProfile(_collection);
  }


  void setNavIndex(int index) {
    _selectedNavIndex = index;
    notifyListeners();
  }


  Future<void> addPerfume(Perfume perfume) async {
    await _db.savePerfume(perfume);
    _collection.insert(0, perfume);
    _computeRecommendations();
    _computeScentProfile();
    notifyListeners();
  }

  Future<void> updatePerfume(Perfume perfume) async {
    await _db.updatePerfume(perfume);
    final idx = _collection.indexWhere((p) => p.id == perfume.id);
    if (idx != -1) _collection[idx] = perfume;
    _computeRecommendations();
    _computeScentProfile();
    notifyListeners();
  }

  Future<void> deletePerfume(String id) async {
    await _db.deletePerfume(id);
    _collection.removeWhere((p) => p.id == id);
    _journalEntries.removeWhere((j) => j.perfumeId == id);
    _computeRecommendations();
    _computeScentProfile();
    notifyListeners();
  }

  Future<void> toggleWishlist(String id) async {
    final idx = _collection.indexWhere((p) => p.id == id);
    if (idx == -1) return;
    final updated = _collection[idx].copyWith(
      isWishlist: !_collection[idx].isWishlist,
    );
    await updatePerfume(updated);
  }

  Perfume? getPerfumeById(String id) {
    try {
      return _collection.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  List<JournalEntry> getEntriesForPerfume(String perfumeId) =>
      _journalEntries.where((e) => e.perfumeId == perfumeId).toList();


  Future<void> addJournalEntry(JournalEntry entry) async {
    await _db.saveJournalEntry(entry);
    _journalEntries.insert(0, entry);
    notifyListeners();
  }

  Future<void> updateJournalEntry(JournalEntry entry) async {
    await _db.updateJournalEntry(entry);
    final idx = _journalEntries.indexWhere((e) => e.id == entry.id);
    if (idx != -1) _journalEntries[idx] = entry;
    notifyListeners();
  }

  Future<void> deleteJournalEntry(String id) async {
    await _db.deleteJournalEntry(id);
    _journalEntries.removeWhere((e) => e.id == id);
    notifyListeners();
  }


  LayeringResult predictLayering(List<Perfume> perfumes) =>
      _ml.predictLayeringCompatibility(perfumes);

  PerformancePrediction predictPerformance(Perfume perfume) =>
      _ml.predictPerformance(
        perfume: perfume,
        weather: _weather ?? WeatherSnapshot(
          condition: 'Clear', temperature: 28, humidity: 65),
        skinType: _userProfile?.skinType,
      );

  List<ScentRecommendation> getRecommendations() {
    if (_weather == null || collection.isEmpty) return [];
    return _ml.rankPerfumesForWeather(
      collection: collection,
      weather: _weather!,
      currentTime: timeOfDay,
      userProfile: _userProfile,
    );
  }


  Future<void> updateUserProfile(UserProfile profile) async {
    await _db.saveUserProfile(profile);
    _userProfile = profile;
    _computeRecommendations();
    notifyListeners();
  }


  Future<void> refreshWeather() async {
    _isWeatherLoading = true;
    notifyListeners();
    _weather = await _weatherService.getCurrentWeather();
    _computeRecommendations();
    _isWeatherLoading = false;
    notifyListeners();
  }

  Future<void> refresh() async {
    await initialize();
  }


  Future<Map<String, dynamic>> getStats() => _db.getStats();

  Map<String, double> getFamilyDistribution() {
    final counts = <String, int>{};
    for (final p in collection) {
      final key = p.family.toString().split('.').last;
      counts[key] = (counts[key] ?? 0) + 1;
    }
    final total = collection.length.toDouble();
    return counts.map((k, v) => MapEntry(k, v / total));
  }


  List<Perfume> searchPerfumes(String query) {
    if (query.isEmpty) return collection;
    final q = query.toLowerCase();
    return collection.where((p) =>
        p.name.toLowerCase().contains(q) ||
        p.brand.toLowerCase().contains(q) ||
        p.notes.any((n) => n.name.toLowerCase().contains(q)) ||
        p.family.toString().toLowerCase().contains(q)
    ).toList();
  }

  List<Perfume> filterByFamily(PerfumeFamily family) =>
      collection.where((p) => p.family == family).toList();


  String generateId() => _uuid.v4();

  void _setLoading(bool val) {
    _isLoading = val;
    notifyListeners();
  }
}
