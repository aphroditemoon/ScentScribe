
import 'dart:math';
import '../models/perfume_model.dart';


class MLEngine {
  static final MLEngine _instance = MLEngine._internal();
  factory MLEngine() => _instance;
  MLEngine._internal();

  final Random _rng = Random();


  static const Map<String, double> _weatherWeights = {
    'temperature': 0.35,
    'humidity': 0.25,
    'season': 0.20,
    'timeOfDay': 0.20,
  };

  static const Map<PerfumeFamily, Map<String, dynamic>> _familyWeatherProfile = {
    PerfumeFamily.fresh: {
      'idealTempRange': [20.0, 35.0],
      'idealHumidity': [30.0, 60.0],
      'bestSeasons': ['summer', 'spring'],
      'bestTimes': ['morning', 'afternoon'],
      'hotWeatherBoost': 1.3,
      'coldWeatherPenalty': 0.6,
      'highHumidityBoost': 1.1,
    },
    PerfumeFamily.citrus: {
      'idealTempRange': [22.0, 35.0],
      'idealHumidity': [35.0, 65.0],
      'bestSeasons': ['summer', 'spring'],
      'bestTimes': ['morning', 'afternoon'],
      'hotWeatherBoost': 1.25,
      'coldWeatherPenalty': 0.65,
      'highHumidityBoost': 1.05,
    },
    PerfumeFamily.aquatic: {
      'idealTempRange': [18.0, 32.0],
      'idealHumidity': [40.0, 70.0],
      'bestSeasons': ['summer', 'spring'],
      'bestTimes': ['morning', 'afternoon'],
      'hotWeatherBoost': 1.2,
      'coldWeatherPenalty': 0.65,
    },
    PerfumeFamily.oriental: {
      'idealTempRange': [0.0, 20.0],
      'idealHumidity': [20.0, 55.0],
      'bestSeasons': ['winter', 'autumn'],
      'bestTimes': ['evening', 'night'],
      'coldWeatherBoost': 1.4,
      'hotWeatherPenalty': 0.5,
      'dryWeatherBoost': 1.2,
    },
    PerfumeFamily.gourmand: {
      'idealTempRange': [0.0, 18.0],
      'idealHumidity': [20.0, 50.0],
      'bestSeasons': ['winter', 'autumn'],
      'bestTimes': ['evening', 'night'],
      'coldWeatherBoost': 1.5,
      'hotWeatherPenalty': 0.45,
    },
    PerfumeFamily.woody: {
      'idealTempRange': [5.0, 22.0],
      'idealHumidity': [30.0, 60.0],
      'bestSeasons': ['autumn', 'winter'],
      'bestTimes': ['evening', 'afternoon'],
      'coldWeatherBoost': 1.3,
      'hotWeatherPenalty': 0.7,
    },
    PerfumeFamily.floral: {
      'idealTempRange': [15.0, 28.0],
      'idealHumidity': [40.0, 70.0],
      'bestSeasons': ['spring', 'summer'],
      'bestTimes': ['morning', 'afternoon'],
      'warmWeatherBoost': 1.2,
    },
    PerfumeFamily.chypre: {
      'idealTempRange': [12.0, 25.0],
      'idealHumidity': [35.0, 65.0],
      'bestSeasons': ['spring', 'autumn'],
      'bestTimes': ['afternoon', 'evening'],
    },
    PerfumeFamily.fougere: {
      'idealTempRange': [10.0, 24.0],
      'idealHumidity': [30.0, 60.0],
      'bestSeasons': ['spring', 'autumn'],
      'bestTimes': ['morning', 'afternoon'],
    },
    PerfumeFamily.green: {
      'idealTempRange': [15.0, 28.0],
      'idealHumidity': [50.0, 75.0],
      'bestSeasons': ['spring', 'summer'],
      'bestTimes': ['morning', 'afternoon'],
      'highHumidityBoost': 1.15,
    },
    PerfumeFamily.powdery: {
      'idealTempRange': [8.0, 22.0],
      'idealHumidity': [25.0, 55.0],
      'bestSeasons': ['winter', 'autumn'],
      'bestTimes': ['evening', 'night'],
    },
  };


  List<ScentRecommendation> rankPerfumesForWeather({
    required List<Perfume> collection,
    required WeatherSnapshot weather,
    required String currentTime,
    UserProfile? userProfile,
    int maxResults = 10,
  }) {
    final List<ScentRecommendation> recommendations = [];

    for (final perfume in collection) {
      if (perfume.isWishlist) continue;

      final score = _computeWeatherCompatibilityScore(
        perfume: perfume,
        weather: weather,
        currentTime: currentTime,
        userProfile: userProfile,
      );

      final matchFactors = _explainScore(perfume, weather, currentTime);
      final reason = _generateReason(perfume, weather, score);

      recommendations.add(ScentRecommendation(
        perfume: perfume,
        score: score,
        reason: reason,
        matchFactors: matchFactors,
        weather: weather,
        timeRecommendation: _getTimeRecommendation(perfume),
      ));
    }

    recommendations.sort((a, b) => b.score.compareTo(a.score));
    return recommendations.take(maxResults).toList();
  }

  double _computeWeatherCompatibilityScore({
    required Perfume perfume,
    required WeatherSnapshot weather,
    required String currentTime,
    UserProfile? userProfile,
  }) {
    double score = 50.0;

    final profile = _familyWeatherProfile[perfume.family];
    if (profile == null) return score;


    final tempRange = profile['idealTempRange'] as List<double>?;
    final List<double>? tempRangeOuter = tempRange;
    if (tempRange != null) {
      final idealMin = tempRange[0];
      final idealMax = tempRange[1];
      final temp = weather.temperature;

      if (temp >= idealMin && temp <= idealMax) {

        score += 30;
      } else if (temp < idealMin) {

        final coldPenalty = profile['coldWeatherPenalty'] as double? ?? 0.8;
        final boost = profile['coldWeatherBoost'] as double? ?? 1.0;
        final delta = idealMin - temp;
        score += (30 - min(30, delta * 1.5)) * coldPenalty * boost;
      } else {

        final hotPenalty = profile['hotWeatherPenalty'] as double? ?? 0.8;
        final boost = profile['hotWeatherBoost'] as double? ?? 1.0;
        final delta = temp - idealMax;
        score += (30 - min(30, delta * 1.5)) * hotPenalty * boost;
      }
    }


    final humRange = profile['idealHumidity'] as List<double>?;
    if (humRange != null) {
      final idealMin = humRange[0];
      final idealMax = humRange[1];
      final hum = weather.humidity;

      if (hum >= idealMin && hum <= idealMax) {
        score += 20;
        final humBoost = profile['highHumidityBoost'] as double? ?? 1.0;
        if (hum > 65) score += (humBoost - 1.0) * 10;
      } else {
        final delta = hum < idealMin ? idealMin - hum : hum - idealMax;
        score += max(0, 20 - delta * 0.4);

        final dryBoost = profile['dryWeatherBoost'] as double? ?? 1.0;
        if (hum < 40 && dryBoost > 1.0) score += (dryBoost - 1.0) * 10;
      }
    }


    final bestTimes = profile['bestTimes'] as List<String>? ?? [];
    if (bestTimes.contains(currentTime)) {
      score += 15;
    } else {
      score += 5;
    }


    final currentSeason = _getCurrentSeason();
    final bestSeasons = profile['bestSeasons'] as List<String>? ?? [];
    if (bestSeasons.contains(currentSeason)) {
      score += 10;
    }


    if (userProfile != null) {
      final preferredFamilies = userProfile.preferredFamilies;
      final familyName = perfume.family.toString().split('.').last;
      if (preferredFamilies.contains(familyName)) {
        score += 15;
      }


      final preferredNotes = userProfile.preferredNotes;
      int noteMatches = 0;
      for (final note in perfume.notes) {
        if (preferredNotes.any((pn) =>
            note.name.toLowerCase().contains(pn.toLowerCase()))) {
          noteMatches++;
        }
      }
      score += min(10, noteMatches * 3.0);
    }


    score += (perfume.rating / 5.0) * 5;


    if (weather.feelsLike != null && tempRangeOuter != null) {
      final feelsLike = weather.feelsLike!;
      final idealMin = tempRangeOuter[0];
      final idealMax = tempRangeOuter[1];
      if (feelsLike >= idealMin && feelsLike <= idealMax) {
        score += 3;
      } else if ((feelsLike - weather.temperature).abs() > 5) {
        score -= 2;
      }
    }


    if (userProfile?.skinType != null) {
      final skin = userProfile!.skinType!;

      if (skin == 'oily' &&
          (perfume.family == PerfumeFamily.oriental ||
           perfume.family == PerfumeFamily.gourmand ||
           perfume.family == PerfumeFamily.woody)) {
        score += 4;
      }

      if (skin == 'dry' &&
          (perfume.family == PerfumeFamily.fresh ||
           perfume.family == PerfumeFamily.citrus ||
           perfume.family == PerfumeFamily.aquatic)) {
        score += 3;
      }
    }


    final cond = weather.condition.toLowerCase();
    if ((cond.contains('rain') || cond.contains('storm')) &&
        (perfume.family == PerfumeFamily.oriental ||
         perfume.family == PerfumeFamily.gourmand)) {
      score -= 8;
    }
    if ((cond.contains('rain') || cond.contains('storm')) &&
        (perfume.family == PerfumeFamily.fresh ||
         perfume.family == PerfumeFamily.aquatic ||
         perfume.family == PerfumeFamily.green)) {
      score += 6;
    }


    if (weather.windSpeed != null) {
      if (weather.windSpeed! > 5 &&
          (perfume.family == PerfumeFamily.fresh ||
           perfume.family == PerfumeFamily.citrus)) {
        score += 3;
      }
      if (weather.windSpeed! > 5 &&
          (perfume.family == PerfumeFamily.oriental ||
           perfume.family == PerfumeFamily.gourmand)) {
        score -= 3;
      }
    }


    score += (_rng.nextDouble() - 0.5) * 2;

    return score.clamp(0, 100);
  }

  List<String> _explainScore(Perfume perfume, WeatherSnapshot weather, String time) {
    final factors = <String>[];
    final profile = _familyWeatherProfile[perfume.family];
    if (profile == null) return factors;

    final tempRange = profile['idealTempRange'] as List<double>?;
    if (tempRange != null) {
      if (weather.temperature >= tempRange[0] && weather.temperature <= tempRange[1]) {
        factors.add('Perfect temperature range');
      } else if (weather.temperature > (tempRange[1] ?? 30)) {
        factors.add('Might be heavy in this heat');
      } else {
        factors.add('Cold weather enhances this scent');
      }
    }

    final humRange = profile['idealHumidity'] as List<double>?;
    if (humRange != null) {
      if (weather.humidity >= humRange[0] && weather.humidity <= humRange[1]) {
        factors.add('Ideal humidity level');
      } else if (weather.humidity > (humRange[1] ?? 70)) {
        factors.add('High humidity may amplify projection');
      }
    }

    final bestTimes = profile['bestTimes'] as List<String>? ?? [];
    if (bestTimes.contains(time)) {
      factors.add('Ideal for $time wear');
    }

    return factors;
  }

  String _generateReason(Perfume perfume, WeatherSnapshot weather, double score) {
    final temp = weather.temperature;
    final hum = weather.humidity;
    final family = perfume.family;

    if (score >= 85) {
      if (family == PerfumeFamily.fresh || family == PerfumeFamily.aquatic) {
        return 'This ${_familyName(family)} scent thrives in ${temp.toInt()}°C — the warmth will lift the notes beautifully.';
      }
      if (family == PerfumeFamily.oriental || family == PerfumeFamily.gourmand) {
        return 'Cool, dry air at ${temp.toInt()}°C is perfect — the rich notes will linger elegantly without being overwhelming.';
      }
      return 'Exceptional match for today\'s ${weather.condition} conditions at ${temp.toInt()}°C.';
    }

    if (score >= 65) {
      if (hum > 75) {
        return 'Solid choice, but apply lightly — high humidity (${hum.toInt()}%) will amplify sillage significantly.';
      }
      return 'Good match for today\'s weather. The ${_familyName(family)} character will show well.';
    }

    if (score >= 45) {
      return 'Moderate fit — apply lightly or consider saving this one for a cooler evening.';
    }

    return 'Not ideal for today\'s ${weather.condition} at ${temp.toInt()}°C. Consider a lighter alternative.';
  }

  String _getTimeRecommendation(Perfume perfume) {
    final profile = _familyWeatherProfile[perfume.family];
    final bestTimes = profile?['bestTimes'] as List<String>? ?? ['anytime'];
    return 'Best worn: ${bestTimes.join(' or ')}';
  }

  String _getCurrentSeason() {
    final month = DateTime.now().month;
    if (month >= 3 && month <= 5) return 'spring';
    if (month >= 6 && month <= 8) return 'summer';
    if (month >= 9 && month <= 11) return 'autumn';
    return 'winter';
  }

  String _familyName(PerfumeFamily family) =>
      family.toString().split('.').last;


  LayeringResult predictLayeringCompatibility(List<Perfume> perfumes) {
    if (perfumes.length < 2) {
      return LayeringResult(score: 0, resultNotes: [], analysis: 'Select at least 2 perfumes');
    }

    double compatibilityScore = 100.0;
    final allNotes = <String>[];
    final families = perfumes.map((p) => p.family).toList();


    for (final perfume in perfumes) {
      allNotes.addAll(perfume.notes.map((n) => n.name));
    }


    final familyScore = _computeFamilyCompatibility(families);
    compatibilityScore *= familyScore;


    final clashPenalty = _detectNoteClashes(perfumes);
    compatibilityScore *= clashPenalty;


    final synergyBoost = _detectNoteSynergies(perfumes);
    compatibilityScore = min(100, compatibilityScore * synergyBoost);


    final resultNotes = _predictResultingNotes(perfumes);

    final analysis = _generateLayeringAnalysis(
        perfumes, compatibilityScore, resultNotes);

    return LayeringResult(
      score: compatibilityScore.clamp(0, 100),
      resultNotes: resultNotes,
      analysis: analysis,
      clashWarnings: _getClashWarnings(perfumes),
    );
  }

  double _computeFamilyCompatibility(List<PerfumeFamily> families) {
    final compatibilityMap = {

      '${PerfumeFamily.fresh}_${PerfumeFamily.aquatic}': 0.95,
      '${PerfumeFamily.fresh}_${PerfumeFamily.floral}': 0.90,
      '${PerfumeFamily.fresh}_${PerfumeFamily.green}': 0.92,
      '${PerfumeFamily.oriental}_${PerfumeFamily.woody}': 0.95,
      '${PerfumeFamily.oriental}_${PerfumeFamily.gourmand}': 0.85,
      '${PerfumeFamily.woody}_${PerfumeFamily.chypre}': 0.88,
      '${PerfumeFamily.floral}_${PerfumeFamily.chypre}': 0.87,
      '${PerfumeFamily.floral}_${PerfumeFamily.woody}': 0.82,
      '${PerfumeFamily.gourmand}_${PerfumeFamily.oriental}': 0.85,
      '${PerfumeFamily.fresh}_${PerfumeFamily.oriental}': 0.55,
      '${PerfumeFamily.aquatic}_${PerfumeFamily.gourmand}': 0.40,
    };

    double totalScore = 1.0;
    for (int i = 0; i < families.length - 1; i++) {
      for (int j = i + 1; j < families.length; j++) {
        final key1 = '${families[i]}_${families[j]}';
        final key2 = '${families[j]}_${families[i]}';
        final score = compatibilityMap[key1] ?? compatibilityMap[key2] ?? 0.70;
        totalScore *= score;
      }
    }
    return totalScore;
  }

  double _detectNoteClashes(List<Perfume> perfumes) {
    final clashingPairs = [
      ['Musk', 'Citrus'],
      ['Oud', 'Marine Notes'],
      ['Vanilla', 'Vetiver'],
    ];

    double penalty = 1.0;
    for (final pair in clashingPairs) {
      bool hasFirst = false, hasSecond = false;
      for (final perfume in perfumes) {
        for (final note in perfume.notes) {
          if (note.name == pair[0]) hasFirst = true;
          if (note.name == pair[1]) hasSecond = true;
        }
      }
      if (hasFirst && hasSecond) penalty *= 0.85;
    }
    return penalty;
  }

  double _detectNoteSynergies(List<Perfume> perfumes) {
    final synergyPairs = [
      ['Sandalwood', 'Rose'],
      ['Bergamot', 'Jasmine'],
      ['Oud', 'Rose'],
      ['Vanilla', 'Sandalwood'],
      ['Amber', 'Musk'],
      ['Cedar', 'Vetiver'],
    ];

    double boost = 1.0;
    for (final pair in synergyPairs) {
      bool hasFirst = false, hasSecond = false;
      for (final perfume in perfumes) {
        for (final note in perfume.notes) {
          if (note.name.contains(pair[0])) hasFirst = true;
          if (note.name.contains(pair[1])) hasSecond = true;
        }
      }
      if (hasFirst && hasSecond) boost = min(1.25, boost + 0.05);
    }
    return boost;
  }

  List<String> _predictResultingNotes(List<Perfume> perfumes) {

    final noteScores = <String, double>{};

    for (final perfume in perfumes) {
      for (final note in perfume.notes) {
        final key = note.name;
        noteScores[key] = (noteScores[key] ?? 0) + note.intensity;
      }
    }

    final sorted = noteScores.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sorted.take(6).map((e) => e.key).toList();
  }

  String _generateLayeringAnalysis(
      List<Perfume> perfumes, double score, List<String> resultNotes) {
    final names = perfumes.map((p) => p.name).join(' + ');

    if (score >= 85) {
      return 'Exceptional harmony! $names creates a sophisticated accord. '
          'The blend will evolve beautifully with your skin chemistry.';
    }
    if (score >= 70) {
      return 'Good compatibility. The combination of $names should create '
          'an interesting layered effect. Apply the heavier scent first.';
    }
    if (score >= 50) {
      return 'Mixed result. Try applying just 1 spray of each — '
          'less is more with this combination.';
    }
    return 'Challenging pairing. The scent profiles may clash. '
        'Consider testing on skin before committing.';
  }

  List<String> _getClashWarnings(List<Perfume> perfumes) {
    final warnings = <String>[];
    final families = perfumes.map((p) => p.family).toList();

    if (families.contains(PerfumeFamily.aquatic) &&
        families.contains(PerfumeFamily.gourmand)) {
      warnings.add('⚠️ Aquatic + Gourmand: Sea salt vs sweetness may clash');
    }
    if (families.contains(PerfumeFamily.fresh) &&
        families.contains(PerfumeFamily.oriental)) {
      warnings.add('⚠️ Fresh + Oriental: Light and heavy may fight each other');
    }


    int baseNoteCount = 0;
    for (final p in perfumes) {
      baseNoteCount += p.baseNotes.length;
    }
    if (baseNoteCount > 6) {
      warnings.add('⚠️ Heavy base note overlap — may become dense');
    }

    return warnings;
  }


  PerformancePrediction predictPerformance({
    required Perfume perfume,
    required WeatherSnapshot weather,
    String? skinType,
  }) {
    double longevityBase = _getBaseLongevity(perfume);
    double sillageBase = _getBaseSillage(perfume);


    if (weather.isHot) {
      longevityBase *= 0.75;
      sillageBase *= 1.3;
    } else if (weather.isCold) {
      longevityBase *= 1.2;
      sillageBase *= 0.85;
    }


    if (weather.isHumid) {
      longevityBase *= 0.85;
      sillageBase *= 1.25;
    } else if (weather.isDry) {
      longevityBase *= 0.90;
      sillageBase *= 0.90;
    }


    if (skinType == 'oily') {
      longevityBase *= 1.15;
    } else if (skinType == 'dry') {
      longevityBase *= 0.85;
    }

    return PerformancePrediction(
      estimatedLongevityHours: longevityBase.clamp(1.0, 24.0),
      estimatedSillage: sillageBase.clamp(1.0, 10.0),
      projectionRadius: _estimateProjection(sillageBase),
      applicationTip: _getApplicationTip(perfume, weather, skinType),
    );
  }

  double _getBaseLongevity(Perfume perfume) {
    final baseNoteCount = perfume.baseNotes.length;
    final hasOud = perfume.notes.any((n) => n.name.contains('Oud'));
    final hasAmber = perfume.notes.any((n) => n.name.contains('Amber'));
    final hasMusk = perfume.notes.any((n) => n.name.contains('Musk'));

    double hours = 4.0 + (baseNoteCount * 0.8);
    if (hasOud) hours += 2.0;
    if (hasAmber) hours += 1.5;
    if (hasMusk) hours += 1.0;

    switch (perfume.family) {
      case PerfumeFamily.oriental: return hours + 2.0;
      case PerfumeFamily.woody: return hours + 1.5;
      case PerfumeFamily.gourmand: return hours + 1.0;
      case PerfumeFamily.fresh: return hours - 1.0;
      case PerfumeFamily.citrus: return hours - 0.8;
      case PerfumeFamily.aquatic: return hours - 0.5;
      default: return hours;
    }
  }

  double _getBaseSillage(Perfume perfume) {
    switch (perfume.family) {
      case PerfumeFamily.oriental: return 8.0;
      case PerfumeFamily.gourmand: return 7.5;
      case PerfumeFamily.woody: return 7.0;
      case PerfumeFamily.floral: return 6.5;
      case PerfumeFamily.chypre: return 6.5;
      case PerfumeFamily.fresh: return 5.5;
      case PerfumeFamily.aquatic: return 5.0;
      case PerfumeFamily.citrus: return 5.2;
      case PerfumeFamily.fougere: return 6.0;
      case PerfumeFamily.green: return 5.5;
      case PerfumeFamily.powdery: return 6.0;
    }
  }

  String _estimateProjection(double sillage) {
    if (sillage >= 8) return '2–3 meters';
    if (sillage >= 6) return '1–2 meters';
    if (sillage >= 4) return '0.5–1 meter';
    return 'Skin-close';
  }

  String _getApplicationTip(Perfume perfume, WeatherSnapshot weather, String? skinType) {
    final tips = <String>[];

    if (weather.isHot) {
      tips.add('Apply to pulse points only — 1-2 sprays max in this heat.');
    } else if (weather.isCold) {
      tips.add('Layer over unscented moisturizer to boost longevity in cold weather.');
    }

    if (weather.isHumid) {
      tips.add('High humidity will boost projection — use sparingly.');
    }

    if (skinType == 'dry') {
      tips.add('Moisturize first or apply to clothes for better longevity on dry skin.');
    } else if (skinType == 'oily') {
      tips.add('Your skin chemistry will extend the longevity naturally.');
    }

    if (perfume.family == PerfumeFamily.oriental || perfume.family == PerfumeFamily.gourmand) {
      tips.add('Best on wrists, neck, and behind ears for this rich family.');
    }

    return tips.isNotEmpty ? tips.join(' ') : 'Apply to warm pulse points for best diffusion.';
  }


  ScentProfile analyzeCollectionProfile(List<Perfume> collection) {
    final familyCounts = <PerfumeFamily, int>{};
    final noteCounts = <String, int>{};
    double totalRating = 0;

    for (final perfume in collection) {
      if (perfume.isWishlist) continue;
      familyCounts[perfume.family] = (familyCounts[perfume.family] ?? 0) + 1;
      totalRating += perfume.rating;
      for (final note in perfume.notes) {
        noteCounts[note.name] = (noteCounts[note.name] ?? 0) + 1;
      }
    }

    final sortedFamilies = familyCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final sortedNotes = noteCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return ScentProfile(
      dominantFamily: sortedFamilies.isNotEmpty ? sortedFamilies.first.key : null,
      familyDistribution: familyCounts,
      topNotes: sortedNotes.take(5).map((e) => e.key).toList(),
      averageRating: collection.isEmpty ? 0 : totalRating / collection.length,
      profileType: _getProfileType(sortedFamilies),
      totalPerfumes: collection.where((p) => !p.isWishlist).length,
    );
  }

  String _getProfileType(List<MapEntry<PerfumeFamily, int>> families) {
    if (families.isEmpty) return 'Beginner';
    final topFamily = families.first.key;
    switch (topFamily) {
      case PerfumeFamily.oriental: return 'Mystic Collector';
      case PerfumeFamily.fresh: return 'Fresh Enthusiast';
      case PerfumeFamily.floral: return 'Floral Romantic';
      case PerfumeFamily.woody: return 'Forest Soul';
      case PerfumeFamily.gourmand: return 'Sweet Indulger';
      case PerfumeFamily.aquatic: return 'Ocean Wanderer';
      default: return 'Eclectic Connoisseur';
    }
  }
}


class LayeringResult {
  final double score;
  final List<String> resultNotes;
  final String analysis;
  final List<String> clashWarnings;

  LayeringResult({
    required this.score,
    required this.resultNotes,
    required this.analysis,
    this.clashWarnings = const [],
  });
}

class PerformancePrediction {
  final double estimatedLongevityHours;
  final double estimatedSillage;
  final String projectionRadius;
  final String applicationTip;

  PerformancePrediction({
    required this.estimatedLongevityHours,
    required this.estimatedSillage,
    required this.projectionRadius,
    required this.applicationTip,
  });
}

class ScentProfile {
  final PerfumeFamily? dominantFamily;
  final Map<PerfumeFamily, int> familyDistribution;
  final List<String> topNotes;
  final double averageRating;
  final String profileType;
  final int totalPerfumes;

  ScentProfile({
    this.dominantFamily,
    required this.familyDistribution,
    required this.topNotes,
    required this.averageRating,
    required this.profileType,
    required this.totalPerfumes,
  });
}
