
import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/perfume_model.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  Database? _database;
  static const String _dbName = 'scentscribe.db';
  static const int _dbVersion = 3;

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _dbName);
    return openDatabase(
      path,
      version: _dbVersion,
      onCreate: _createDb,
      onUpgrade: _upgradeDb,
    );
  }

  Future<void> _createDb(Database db, int version) async {
    await db.execute('''
      CREATE TABLE perfumes (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        brand TEXT NOT NULL,
        description TEXT,
        family INTEGER NOT NULL,
        notes TEXT NOT NULL,
        imageUrl TEXT,
        imagePath TEXT,
        mlOwned REAL,
        price REAL,
        purchaseUrl TEXT,
        rating REAL DEFAULT 0,
        addedAt INTEGER NOT NULL,
        isWishlist INTEGER DEFAULT 0,
        bestSeasons TEXT,
        bestTimes TEXT,
        occasions TEXT,
        countryOfOrigin TEXT,
        launchYear INTEGER,
        perfumer TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE journal_entries (
        id TEXT PRIMARY KEY,
        perfumeId TEXT NOT NULL,
        date INTEGER NOT NULL,
        longevityRating INTEGER NOT NULL,
        sillageRating INTEGER NOT NULL,
        projectionRating INTEGER DEFAULT 5,
        moodRating INTEGER DEFAULT 3,
        notes TEXT,
        weatherCondition TEXT,
        weatherTemp REAL,
        weatherHumidity REAL,
        occasion TEXT,
        moods TEXT,
        temperature REAL,
        humidity REAL,
        skinCondition TEXT,
        FOREIGN KEY (perfumeId) REFERENCES perfumes (id)
      )
    ''');

    await db.execute('''
      CREATE TABLE user_profile (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        bio TEXT,
        photoPath TEXT,
        avatarPath TEXT,
        preferredFamilies TEXT,
        preferredNotes TEXT,
        avoidedNotes TEXT,
        skinType TEXT,
        climateType TEXT,
        isPremium INTEGER DEFAULT 0,
        createdAt INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE layering_combos (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        perfumeIds TEXT NOT NULL,
        description TEXT,
        mlPredictedScore REAL DEFAULT 0,
        resultingNotes TEXT,
        createdAt INTEGER NOT NULL
      )
    ''');


    await _insertSampleData(db);
  }

  Future<void> _upgradeDb(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {

      try { await db.execute("ALTER TABLE user_profile ADD COLUMN bio TEXT"); } catch (_) {}
      try { await db.execute("ALTER TABLE user_profile ADD COLUMN photoPath TEXT"); } catch (_) {}
    }
    if (oldVersion < 3) {

      try { await db.execute("ALTER TABLE user_profile ADD COLUMN avatarPath TEXT"); } catch (_) {}
      try { await db.execute("ALTER TABLE user_profile ADD COLUMN preferredNotes TEXT"); } catch (_) {}
      try { await db.execute("ALTER TABLE user_profile ADD COLUMN avoidedNotes TEXT"); } catch (_) {}
      try { await db.execute("ALTER TABLE user_profile ADD COLUMN skinType TEXT"); } catch (_) {}
      try { await db.execute("ALTER TABLE user_profile ADD COLUMN climateType TEXT"); } catch (_) {}
      try { await db.execute("ALTER TABLE user_profile ADD COLUMN isPremium INTEGER DEFAULT 0"); } catch (_) {}
    }
  }

  Future<void> _insertSampleData(Database db) async {
    final samplePerfumes = _getSamplePerfumes();
    for (final p in samplePerfumes) {
      final map = p.toMap();
      map['notes'] = jsonEncode(map['notes']);
      map['bestSeasons'] = jsonEncode(map['bestSeasons']);
      map['bestTimes'] = jsonEncode(map['bestTimes']);
      map['occasions'] = jsonEncode(map['occasions']);
      await db.insert('perfumes', map);
    }
  }

  List<Perfume> _getSamplePerfumes() => [
    Perfume(
      id: 'bleu_chanel_01',
      name: 'Bleu de Chanel',
      brand: 'Chanel',
      description: 'A free, bold fragrance for the man who defies convention. Fresh citrus meets aromatic notes with a woody dry-down.',
      family: PerfumeFamily.fresh,
      notes: [
        const FragranceNote(name: 'Citrus', category: NoteCategory.top, intensity: 0.9, emoji: '🍋'),
        const FragranceNote(name: 'Grapefruit', category: NoteCategory.top, intensity: 0.8, emoji: '🍊'),
        const FragranceNote(name: 'Mint', category: NoteCategory.top, intensity: 0.6, emoji: '🌿'),
        const FragranceNote(name: 'Ginger', category: NoteCategory.heart, intensity: 0.7, emoji: '🫚'),
        const FragranceNote(name: 'Jasmine', category: NoteCategory.heart, intensity: 0.5, emoji: '🌸'),
        const FragranceNote(name: 'Nutmeg', category: NoteCategory.heart, intensity: 0.6, emoji: '🌰'),
        const FragranceNote(name: 'Sandalwood', category: NoteCategory.base, intensity: 0.8, emoji: '🪵'),
        const FragranceNote(name: 'Cedar', category: NoteCategory.base, intensity: 0.7, emoji: '🌲'),
        const FragranceNote(name: 'Vetiver', category: NoteCategory.base, intensity: 0.6, emoji: '🌾'),
      ],
      rating: 4.5,
      addedAt: DateTime.now().subtract(const Duration(days: 30)),
      bestSeasons: [Season.spring, Season.summer],
      bestTimes: [ScentTimeOfDay.morning, ScentTimeOfDay.afternoon],
      occasions: [Occasion.office, Occasion.casual],
      mlOwned: 100,
      perfumer: 'Jacques Polge',
      launchYear: 2010,
      countryOfOrigin: 'France',
    ),
    Perfume(
      id: 'baccarat_rouge_02',
      name: 'Baccarat Rouge 540',
      brand: 'Maison Francis Kurkdjian',
      description: 'A luminous and sublime scent. Amber florals that leave an impression of crystalline transparency.',
      family: PerfumeFamily.oriental,
      notes: [
        const FragranceNote(name: 'Saffron', category: NoteCategory.top, intensity: 0.8, emoji: '🧡'),
        const FragranceNote(name: 'Jasmine', category: NoteCategory.heart, intensity: 0.9, emoji: '🌸'),
        const FragranceNote(name: 'Amberwood', category: NoteCategory.base, intensity: 1.0, emoji: '🪵'),
        const FragranceNote(name: 'Ambergris', category: NoteCategory.base, intensity: 0.9, emoji: '⚗️'),
        const FragranceNote(name: 'Fir Resin', category: NoteCategory.base, intensity: 0.7, emoji: '🌲'),
      ],
      rating: 4.8,
      addedAt: DateTime.now().subtract(const Duration(days: 60)),
      bestSeasons: [Season.autumn, Season.winter],
      bestTimes: [ScentTimeOfDay.evening, ScentTimeOfDay.night],
      occasions: [Occasion.date, Occasion.formal],
      mlOwned: 70,
      price: 340.0,
      perfumer: 'Francis Kurkdjian',
      launchYear: 2015,
      countryOfOrigin: 'France',
    ),
    Perfume(
      id: 'lost_cherry_03',
      name: 'Lost Cherry',
      brand: 'Tom Ford',
      description: 'A luscious, intoxicating cherry gourmand with boozy accords and dark woods.',
      family: PerfumeFamily.gourmand,
      notes: [
        const FragranceNote(name: 'Cherry', category: NoteCategory.top, intensity: 1.0, emoji: '🍒'),
        const FragranceNote(name: 'Bitter Almond', category: NoteCategory.heart, intensity: 0.8, emoji: '🌰'),
        const FragranceNote(name: 'Turkish Rose', category: NoteCategory.heart, intensity: 0.7, emoji: '🌹'),
        const FragranceNote(name: 'Clove', category: NoteCategory.heart, intensity: 0.6, emoji: '🫙'),
        const FragranceNote(name: 'Sandalwood', category: NoteCategory.base, intensity: 0.8, emoji: '🪵'),
        const FragranceNote(name: 'Tonka Bean', category: NoteCategory.base, intensity: 0.9, emoji: '🫘'),
        const FragranceNote(name: 'Vanilla', category: NoteCategory.base, intensity: 0.7, emoji: '🍦'),
      ],
      rating: 4.6,
      addedAt: DateTime.now().subtract(const Duration(days: 15)),
      bestSeasons: [Season.autumn, Season.winter],
      bestTimes: [ScentTimeOfDay.evening, ScentTimeOfDay.night],
      occasions: [Occasion.date, Occasion.casual],
      mlOwned: 50,
      price: 450.0,
      perfumer: 'Givaudan',
      launchYear: 2018,
      countryOfOrigin: 'USA',
    ),
    Perfume(
      id: 'acqua_gio_04',
      name: 'Acqua di Giò',
      brand: 'Giorgio Armani',
      description: 'Inspired by the island of Pantelleria, this aquatic floral captures the essence of the Mediterranean sea.',
      family: PerfumeFamily.aquatic,
      notes: [
        const FragranceNote(name: 'Bergamot', category: NoteCategory.top, intensity: 0.9, emoji: '🍋'),
        const FragranceNote(name: 'Marine Notes', category: NoteCategory.top, intensity: 1.0, emoji: '🌊'),
        const FragranceNote(name: 'Neroli', category: NoteCategory.top, intensity: 0.7, emoji: '🌺'),
        const FragranceNote(name: 'Jasmine', category: NoteCategory.heart, intensity: 0.6, emoji: '🌸'),
        const FragranceNote(name: 'Rosemary', category: NoteCategory.heart, intensity: 0.5, emoji: '🌿'),
        const FragranceNote(name: 'White Cedar', category: NoteCategory.base, intensity: 0.8, emoji: '🌲'),
        const FragranceNote(name: 'Musk', category: NoteCategory.base, intensity: 0.7, emoji: '⚪'),
      ],
      rating: 4.2,
      addedAt: DateTime.now().subtract(const Duration(days: 90)),
      bestSeasons: [Season.spring, Season.summer],
      bestTimes: [ScentTimeOfDay.morning, ScentTimeOfDay.afternoon],
      occasions: [Occasion.casual, Occasion.sport, Occasion.outdoor],
      mlOwned: 200,
      price: 120.0,
      launchYear: 1996,
      countryOfOrigin: 'Italy',
    ),
    Perfume(
      id: 'oud_wood_05',
      name: 'Oud Wood',
      brand: 'Tom Ford',
      description: 'Rare oud wood combined with sandalwood and tonka bean for an exotic woody scent.',
      family: PerfumeFamily.woody,
      notes: [
        const FragranceNote(name: 'Oud', category: NoteCategory.top, intensity: 1.0, emoji: '🪵'),
        const FragranceNote(name: 'Rosewood', category: NoteCategory.heart, intensity: 0.8, emoji: '🌹'),
        const FragranceNote(name: 'Cardamom', category: NoteCategory.heart, intensity: 0.7, emoji: '🫙'),
        const FragranceNote(name: 'Sandalwood', category: NoteCategory.base, intensity: 0.9, emoji: '🪵'),
        const FragranceNote(name: 'Vetiver', category: NoteCategory.base, intensity: 0.7, emoji: '🌾'),
        const FragranceNote(name: 'Tonka Bean', category: NoteCategory.base, intensity: 0.6, emoji: '🫘'),
      ],
      rating: 4.7,
      addedAt: DateTime.now().subtract(const Duration(days: 45)),
      bestSeasons: [Season.autumn, Season.winter],
      bestTimes: [ScentTimeOfDay.evening, ScentTimeOfDay.night],
      occasions: [Occasion.formal, Occasion.date],
      mlOwned: 30,
      price: 280.0,
      isWishlist: false,
      perfumer: 'Richard Herpin',
      launchYear: 2007,
      countryOfOrigin: 'USA',
    ),
  ];


  Future<List<Perfume>> getAllPerfumes({bool wishlistOnly = false}) async {
    final db = await database;
    final maps = await db.query(
      'perfumes',
      where: wishlistOnly ? 'isWishlist = 1' : null,
      orderBy: 'addedAt DESC',
    );
    return maps.map((m) {
      final decoded = Map<String, dynamic>.from(m);
      if (decoded['notes'] is String) {
        decoded['notes'] = jsonDecode(decoded['notes']);
      }
      if (decoded['bestSeasons'] is String) {
        decoded['bestSeasons'] = jsonDecode(decoded['bestSeasons']);
      }
      if (decoded['bestTimes'] is String) {
        decoded['bestTimes'] = jsonDecode(decoded['bestTimes']);
      }
      if (decoded['occasions'] is String) {
        decoded['occasions'] = jsonDecode(decoded['occasions']);
      }
      return Perfume.fromMap(decoded);
    }).toList();
  }

  Future<Perfume?> getPerfumeById(String id) async {
    final db = await database;
    final maps = await db.query('perfumes', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    final decoded = Map<String, dynamic>.from(maps.first);
    if (decoded['notes'] is String) decoded['notes'] = jsonDecode(decoded['notes']);
    if (decoded['bestSeasons'] is String) decoded['bestSeasons'] = jsonDecode(decoded['bestSeasons']);
    if (decoded['bestTimes'] is String) decoded['bestTimes'] = jsonDecode(decoded['bestTimes']);
    if (decoded['occasions'] is String) decoded['occasions'] = jsonDecode(decoded['occasions']);
    return Perfume.fromMap(decoded);
  }

  Future<void> savePerfume(Perfume perfume) async {
    final db = await database;
    final map = perfume.toMap();
    map['notes'] = jsonEncode(map['notes']);
    map['bestSeasons'] = jsonEncode(map['bestSeasons']);
    map['bestTimes'] = jsonEncode(map['bestTimes']);
    map['occasions'] = jsonEncode(map['occasions']);
    await db.insert('perfumes', map, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> updatePerfume(Perfume perfume) async {
    final db = await database;
    final map = perfume.toMap();
    map['notes'] = jsonEncode(map['notes']);
    map['bestSeasons'] = jsonEncode(map['bestSeasons']);
    map['bestTimes'] = jsonEncode(map['bestTimes']);
    map['occasions'] = jsonEncode(map['occasions']);
    await db.update('perfumes', map, where: 'id = ?', whereArgs: [perfume.id]);
  }

  Future<void> deletePerfume(String id) async {
    final db = await database;
    await db.delete('perfumes', where: 'id = ?', whereArgs: [id]);
    await db.delete('journal_entries', where: 'perfumeId = ?', whereArgs: [id]);
  }


  Future<List<JournalEntry>> getJournalEntries({String? perfumeId}) async {
    final db = await database;
    final maps = await db.query(
      'journal_entries',
      where: perfumeId != null ? 'perfumeId = ?' : null,
      whereArgs: perfumeId != null ? [perfumeId] : null,
      orderBy: 'date DESC',
    );
    return maps.map((m) => JournalEntry.fromMap(m)).toList();
  }

  Future<void> saveJournalEntry(JournalEntry entry) async {
    final db = await database;
    await db.insert('journal_entries', entry.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> updateJournalEntry(JournalEntry entry) async {
    final db = await database;
    await db.update('journal_entries', entry.toMap(),
        where: 'id = ?', whereArgs: [entry.id]);
  }

  Future<void> deleteJournalEntry(String id) async {
    final db = await database;
    await db.delete('journal_entries', where: 'id = ?', whereArgs: [id]);
  }


  Future<UserProfile?> getUserProfile() async {
    final db = await database;
    final maps = await db.query('user_profile', limit: 1);
    if (maps.isEmpty) return null;
    return UserProfile.fromMap(maps.first);
  }

  Future<void> saveUserProfile(UserProfile profile) async {
    final db = await database;
    await db.insert('user_profile', profile.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }


  Future<Map<String, dynamic>> getStats() async {
    final db = await database;
    final perfumeCount = Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM perfumes WHERE isWishlist = 0'))
        ?? 0;
    final wishlistCount = Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM perfumes WHERE isWishlist = 1'))
        ?? 0;
    final journalCount = Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM journal_entries'))
        ?? 0;
    final avgRating = await db.rawQuery(
        'SELECT AVG(rating) as avg FROM perfumes WHERE isWishlist = 0');
    return {
      'perfumeCount': perfumeCount,
      'wishlistCount': wishlistCount,
      'journalCount': journalCount,
      'avgRating': (avgRating.first['avg'] as num?)?.toDouble() ?? 0.0,
    };
  }
}
