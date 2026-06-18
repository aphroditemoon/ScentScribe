
import 'package:flutter/material.dart';

enum PerfumeFamily {
  floral, oriental, woody, fresh, fougere, chypre, gourmand, aquatic, green, powdery, citrus
}

enum NoteCategory { top, heart, base }

enum Season { spring, summer, autumn, winter }

enum ScentTimeOfDay { morning, afternoon, evening, night }

enum Occasion { casual, office, date, formal, sport, outdoor }

class FragranceNote {
  final String name;
  final NoteCategory category;
  final double intensity;
  final String? emoji;

  const FragranceNote({
    required this.name,
    required this.category,
    this.intensity = 0.5,
    this.emoji,
  });

  Map<String, dynamic> toMap() => {
    'name': name,
    'category': category.index,
    'intensity': intensity,
    'emoji': emoji,
  };

  factory FragranceNote.fromMap(Map<String, dynamic> map) => FragranceNote(
    name: map['name'],
    category: NoteCategory.values[map['category']],
    intensity: map['intensity']?.toDouble() ?? 0.5,
    emoji: map['emoji'],
  );
}

class Perfume {
  final String id;
  final String name;
  final String brand;
  final String? description;
  final PerfumeFamily family;
  final List<FragranceNote> notes;
  final String? imageUrl;
  final String? imagePath;
  final double? mlOwned;
  final double? price;
  final String? purchaseUrl;
  final double rating;
  final DateTime addedAt;
  final bool isWishlist;
  final List<Season> bestSeasons;
  final List<ScentTimeOfDay> bestTimes;
  final List<Occasion> occasions;
  final String? countryOfOrigin;
  final int? launchYear;
  final String? perfumer;
  final Map<String, double>? mlPrediction;

  Perfume({
    required this.id,
    required this.name,
    required this.brand,
    this.description,
    required this.family,
    required this.notes,
    this.imageUrl,
    this.imagePath,
    this.mlOwned,
    this.price,
    this.purchaseUrl,
    this.rating = 0,
    required this.addedAt,
    this.isWishlist = false,
    this.bestSeasons = const [],
    this.bestTimes = const [],
    this.occasions = const [],
    this.countryOfOrigin,
    this.launchYear,
    this.perfumer,
    this.mlPrediction,
  });

  List<FragranceNote> get topNotes =>
      notes.where((n) => n.category == NoteCategory.top).toList();
  List<FragranceNote> get heartNotes =>
      notes.where((n) => n.category == NoteCategory.heart).toList();
  List<FragranceNote> get baseNotes =>
      notes.where((n) => n.category == NoteCategory.base).toList();

  Color get familyColor {
    switch (family) {
      case PerfumeFamily.floral: return const Color(0xFFEF476F);
      case PerfumeFamily.oriental: return const Color(0xFFD4AF37);
      case PerfumeFamily.woody: return const Color(0xFF8B6914);
      case PerfumeFamily.fresh: return const Color(0xFF4ECDC4);
      case PerfumeFamily.fougere: return const Color(0xFF06D6A0);
      case PerfumeFamily.chypre: return const Color(0xFF9B59B6);
      case PerfumeFamily.gourmand: return const Color(0xFFFFB6A3);
      case PerfumeFamily.aquatic: return const Color(0xFF118AB2);
      case PerfumeFamily.green: return const Color(0xFF26A96C);
      case PerfumeFamily.powdery: return const Color(0xFFB0B0C0);
      case PerfumeFamily.citrus: return const Color(0xFFFFD166);
    }
  }

  String get familyEmoji {
    switch (family) {
      case PerfumeFamily.floral: return '🌸';
      case PerfumeFamily.oriental: return '🌙';
      case PerfumeFamily.woody: return '🌲';
      case PerfumeFamily.fresh: return '🍃';
      case PerfumeFamily.fougere: return '🌿';
      case PerfumeFamily.chypre: return '🌺';
      case PerfumeFamily.gourmand: return '🍫';
      case PerfumeFamily.aquatic: return '🌊';
      case PerfumeFamily.green: return '🍀';
      case PerfumeFamily.powdery: return '✨';
      case PerfumeFamily.citrus: return '🍋';
    }
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'brand': brand,
    'description': description,
    'family': family.index,
    'notes': notes.map((n) => n.toMap()).toList(),
    'imageUrl': imageUrl,
    'imagePath': imagePath,
    'mlOwned': mlOwned,
    'price': price,
    'purchaseUrl': purchaseUrl,
    'rating': rating,
    'addedAt': addedAt.millisecondsSinceEpoch,
    'isWishlist': isWishlist ? 1 : 0,
    'bestSeasons': bestSeasons.map((s) => s.index).toList(),
    'bestTimes': bestTimes.map((t) => t.index).toList(),
    'occasions': occasions.map((o) => o.index).toList(),
    'countryOfOrigin': countryOfOrigin,
    'launchYear': launchYear,
    'perfumer': perfumer,
  };

  factory Perfume.fromMap(Map<String, dynamic> map) => Perfume(
    id: map['id'],
    name: map['name'],
    brand: map['brand'],
    description: map['description'],
    family: PerfumeFamily.values[map['family'] ?? 0],
    notes: (map['notes'] as List?)
        ?.map((n) => FragranceNote.fromMap(n))
        .toList() ?? [],
    imageUrl: map['imageUrl'],
    imagePath: map['imagePath'],
    mlOwned: map['mlOwned']?.toDouble(),
    price: map['price']?.toDouble(),
    purchaseUrl: map['purchaseUrl'],
    rating: map['rating']?.toDouble() ?? 0,
    addedAt: DateTime.fromMillisecondsSinceEpoch(map['addedAt']),
    isWishlist: map['isWishlist'] == 1,
    bestSeasons: (map['bestSeasons'] as List?)
        ?.map((s) => Season.values[s])
        .toList() ?? [],
    bestTimes: (map['bestTimes'] as List?)
        ?.map((t) => ScentTimeOfDay.values[t])
        .toList() ?? [],
    occasions: (map['occasions'] as List?)
        ?.map((o) => Occasion.values[o])
        .toList() ?? [],
    countryOfOrigin: map['countryOfOrigin'],
    launchYear: map['launchYear'],
    perfumer: map['perfumer'],
  );

  Perfume copyWith({
    String? name, String? brand, String? description,
    PerfumeFamily? family, List<FragranceNote>? notes,
    String? imageUrl, String? imagePath, double? mlOwned,
    double? price, double? rating, bool? isWishlist,
    List<Season>? bestSeasons, List<ScentTimeOfDay>? bestTimes,
    List<Occasion>? occasions,
  }) => Perfume(
    id: id,
    name: name ?? this.name,
    brand: brand ?? this.brand,
    description: description ?? this.description,
    family: family ?? this.family,
    notes: notes ?? this.notes,
    imageUrl: imageUrl ?? this.imageUrl,
    imagePath: imagePath ?? this.imagePath,
    mlOwned: mlOwned ?? this.mlOwned,
    price: price ?? this.price,
    rating: rating ?? this.rating,
    addedAt: addedAt,
    isWishlist: isWishlist ?? this.isWishlist,
    bestSeasons: bestSeasons ?? this.bestSeasons,
    bestTimes: bestTimes ?? this.bestTimes,
    occasions: occasions ?? this.occasions,
    countryOfOrigin: countryOfOrigin,
    launchYear: launchYear,
    perfumer: perfumer,
  );
}


class JournalEntry {
  final String id;
  final String perfumeId;
  final DateTime date;
  final int longevityRating;
  final int sillageRating;
  final int projectionRating;
  final int moodRating;
  final String? notes;
  final WeatherSnapshot? weather;
  final String? occasion;
  final List<String> moods;
  final double? temperature;
  final double? humidity;
  final String? skinCondition;

  JournalEntry({
    required this.id,
    required this.perfumeId,
    required this.date,
    required this.longevityRating,
    required this.sillageRating,
    this.projectionRating = 5,
    this.moodRating = 3,
    this.notes,
    this.weather,
    this.occasion,
    this.moods = const [],
    this.temperature,
    this.humidity,
    this.skinCondition,
  });

  double get overallScore =>
      (longevityRating + sillageRating + projectionRating) / 3.0;

  Map<String, dynamic> toMap() => {
    'id': id,
    'perfumeId': perfumeId,
    'date': date.millisecondsSinceEpoch,
    'longevityRating': longevityRating,
    'sillageRating': sillageRating,
    'projectionRating': projectionRating,
    'moodRating': moodRating,
    'notes': notes,
    'weatherCondition': weather?.condition,
    'weatherTemp': weather?.temperature,
    'weatherHumidity': weather?.humidity,
    'occasion': occasion,
    'moods': moods.join(','),
    'temperature': temperature,
    'humidity': humidity,
    'skinCondition': skinCondition,
  };

  factory JournalEntry.fromMap(Map<String, dynamic> map) => JournalEntry(
    id: map['id'],
    perfumeId: map['perfumeId'],
    date: DateTime.fromMillisecondsSinceEpoch(map['date']),
    longevityRating: map['longevityRating'] ?? 5,
    sillageRating: map['sillageRating'] ?? 5,
    projectionRating: map['projectionRating'] ?? 5,
    moodRating: map['moodRating'] ?? 3,
    notes: map['notes'],
    weather: map['weatherCondition'] != null ? WeatherSnapshot(
      condition: map['weatherCondition'],
      temperature: map['weatherTemp']?.toDouble() ?? 25,
      humidity: map['weatherHumidity']?.toDouble() ?? 60,
    ) : null,
    occasion: map['occasion'],
    moods: map['moods'] != null
        ? (map['moods'] as String).split(',').where((s) => s.isNotEmpty).toList()
        : [],
    temperature: map['temperature']?.toDouble(),
    humidity: map['humidity']?.toDouble(),
    skinCondition: map['skinCondition'],
  );
}


class WeatherSnapshot {
  final String condition;
  final String? description;
  final double temperature;
  final double humidity;
  final String? city;
  final String? icon;
  final double? windSpeed;
  final double? feelsLike;
  final double? pressure;
  final double? uvIndex;

  WeatherSnapshot({
    required this.condition,
    this.description,
    required this.temperature,
    required this.humidity,
    this.city,
    this.icon,
    this.windSpeed,
    this.feelsLike,
    this.pressure,
    this.uvIndex,
  });

  String get emoji {
    final c = condition.toLowerCase();
    if (c.contains('sun') || c.contains('clear')) return '☀️';
    if (c.contains('cloud')) return '☁️';
    if (c.contains('rain')) return '🌧️';
    if (c.contains('snow')) return '❄️';
    if (c.contains('storm')) return '⛈️';
    if (c.contains('mist') || c.contains('fog')) return '🌫️';
    if (c.contains('wind')) return '💨';
    return '🌤️';
  }

  bool get isHot => temperature >= 30;
  bool get isWarm => temperature >= 20 && temperature < 30;
  bool get isCool => temperature >= 10 && temperature < 20;
  bool get isCold => temperature < 10;
  bool get isHumid => humidity >= 70;
  bool get isDry => humidity < 40;
}


class ScentRecommendation {
  final Perfume perfume;
  final double score;
  final String reason;
  final List<String> matchFactors;
  final WeatherSnapshot? weather;
  final String? timeRecommendation;

  ScentRecommendation({
    required this.perfume,
    required this.score,
    required this.reason,
    this.matchFactors = const [],
    this.weather,
    this.timeRecommendation,
  });
}


class UserProfile {
  final String id;
  final String name;
  final String? bio;
  final String? photoPath;
  final String? avatarPath;
  final List<String> preferredFamilies;
  final List<String> preferredNotes;
  final List<String> avoidedNotes;
  final String? skinType;
  final String? climateType;
  final bool isPremium;
  final DateTime createdAt;

  UserProfile({
    required this.id,
    required this.name,
    this.bio,
    this.photoPath,
    this.avatarPath,
    this.preferredFamilies = const [],
    this.preferredNotes = const [],
    this.avoidedNotes = const [],
    this.skinType,
    this.climateType,
    this.isPremium = false,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'bio': bio,
    'photoPath': photoPath,
    'avatarPath': avatarPath,
    'preferredFamilies': preferredFamilies.join(','),
    'preferredNotes': preferredNotes.join(','),
    'avoidedNotes': avoidedNotes.join(','),
    'skinType': skinType,
    'climateType': climateType,
    'isPremium': isPremium ? 1 : 0,
    'createdAt': createdAt.millisecondsSinceEpoch,
  };

  factory UserProfile.fromMap(Map<String, dynamic> map) => UserProfile(
    id: map['id'],
    name: map['name'],
    bio: map['bio'],
    photoPath: map['photoPath'],
    avatarPath: map['avatarPath'],
    preferredFamilies: map['preferredFamilies'] != null
        ? (map['preferredFamilies'] as String).split(',')
        : [],
    preferredNotes: map['preferredNotes'] != null
        ? (map['preferredNotes'] as String).split(',')
        : [],
    avoidedNotes: map['avoidedNotes'] != null
        ? (map['avoidedNotes'] as String).split(',')
        : [],
    skinType: map['skinType'],
    climateType: map['climateType'],
    isPremium: map['isPremium'] == 1,
    createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt']),
  );

  UserProfile copyWith({
    String? name,
    String? bio,
    String? photoPath,
    String? avatarPath,
    List<String>? preferredFamilies,
    List<String>? preferredNotes,
    List<String>? avoidedNotes,
    String? skinType,
    String? climateType,
    bool? isPremium,
    bool clearBio = false,
    bool clearPhotoPath = false,
    bool clearAvatarPath = false,
  }) => UserProfile(
    id: id,
    name: name ?? this.name,
    bio: clearBio ? null : (bio ?? this.bio),
    photoPath: clearPhotoPath ? null : (photoPath ?? this.photoPath),
    avatarPath: clearAvatarPath ? null : (avatarPath ?? this.avatarPath),
    preferredFamilies: preferredFamilies ?? this.preferredFamilies,
    preferredNotes: preferredNotes ?? this.preferredNotes,
    avoidedNotes: avoidedNotes ?? this.avoidedNotes,
    skinType: skinType ?? this.skinType,
    climateType: climateType ?? this.climateType,
    isPremium: isPremium ?? this.isPremium,
    createdAt: createdAt,
  );

}


class LayeringCombo {
  final String id;
  final String name;
  final List<String> perfumeIds;
  final String? description;
  final double mlPredictedScore;
  final List<String> resultingNotes;
  final DateTime createdAt;

  LayeringCombo({
    required this.id,
    required this.name,
    required this.perfumeIds,
    this.description,
    this.mlPredictedScore = 0,
    this.resultingNotes = const [],
    required this.createdAt,
  });
}
