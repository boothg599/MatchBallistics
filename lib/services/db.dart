import 'dart:async';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import '../models/dope_point.dart';
import '../models/profile.dart';

class AppDatabase {
  static final AppDatabase instance = AppDatabase._internal();
  static const _dbName = 'empirical_dope.db';
  static const _dbVersion = 3;

  Database? _database;

  AppDatabase._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final documentsDirectory = await getApplicationDocumentsDirectory();
    final path = join(documentsDirectory.path, _dbName);
    return openDatabase(
      path,
      version: _dbVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE profiles (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        unit TEXT NOT NULL,
        advanced INTEGER NOT NULL DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE dope_points (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        profile_id INTEGER NOT NULL,
        distance_yards REAL NOT NULL,
        elevation REAL NOT NULL,
        muzzle_velocity REAL,
        temperature_f REAL,
        pressure_inhg REAL,
        humidity_percent REAL,
        confirmed INTEGER NOT NULL DEFAULT 1,
        source TEXT,
        FOREIGN KEY (profile_id) REFERENCES profiles (id) ON DELETE CASCADE
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE profiles ADD COLUMN advanced INTEGER NOT NULL DEFAULT 0;');
      await db.execute('ALTER TABLE dope_points ADD COLUMN muzzle_velocity REAL;');
      await db.execute('ALTER TABLE dope_points ADD COLUMN temperature_f REAL;');
      await db.execute('ALTER TABLE dope_points ADD COLUMN pressure_inhg REAL;');
      await db.execute('ALTER TABLE dope_points ADD COLUMN humidity_percent REAL;');
    }
    if (oldVersion < 3) {
      await db.execute('ALTER TABLE dope_points ADD COLUMN confirmed INTEGER NOT NULL DEFAULT 1;');
      await db.execute('ALTER TABLE dope_points ADD COLUMN source TEXT;');
    }
  }

  Future<int> insertProfile(Profile profile) async {
    final db = await database;
    final profileId = await db.insert('profiles', profile.toMap());
    await insertDopePoint(DopePoint(
      profileId: profileId,
      distanceYards: 100,
      elevation: 0,
      confirmed: true,
      source: 'Zero',
    ));
    return profileId;
  }

  Future<void> updateProfile(Profile profile) async {
    final db = await database;
    await db.update(
      'profiles',
      profile.toMap(),
      where: 'id = ?',
      whereArgs: [profile.id],
    );
  }

  Future<void> deleteProfile(int profileId) async {
    final db = await database;
    await db.delete('dope_points', where: 'profile_id = ?', whereArgs: [profileId]);
    await db.delete('profiles', where: 'id = ?', whereArgs: [profileId]);
  }

  Future<int> insertDopePoint(DopePoint point) async {
    final db = await database;
    return db.insert('dope_points', point.toMap());
  }

  Future<void> updateDopePoint(DopePoint point) async {
    final db = await database;
    await db.update(
      'dope_points',
      point.toMap(),
      where: 'id = ?',
      whereArgs: [point.id],
    );
  }

  Future<void> deleteDopePoint(int id) async {
    final db = await database;
    await db.delete('dope_points', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Profile>> fetchProfiles() async {
    final db = await database;
    final profileMaps = await db.query('profiles');
    final profiles = <Profile>[];

    for (final map in profileMaps) {
      final profileId = map['id'] as int;
      final points = await db.query(
        'dope_points',
        where: 'profile_id = ?',
        whereArgs: [profileId],
        orderBy: 'distance_yards ASC',
      );
      final dopePoints = points.map((p) => DopePoint.fromMap(p)).toList();
      if (!dopePoints.any((p) => p.distanceYards == 100)) {
        await insertDopePoint(DopePoint(
          profileId: profileId,
          distanceYards: 100,
          elevation: 0,
          confirmed: true,
          source: 'Zero',
        ));
        dopePoints.add(DopePoint(profileId: profileId, distanceYards: 100, elevation: 0, confirmed: true, source: 'Zero'));
      }
      profiles.add(Profile.fromMap(map, dopePoints));
    }

    return profiles;
  }
}
