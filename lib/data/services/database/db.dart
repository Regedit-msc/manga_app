import 'dart:io';

import 'package:path/path.dart';
import "package:path_provider/path_provider.dart";
import 'package:sqflite/sqflite.dart';
import 'package:webcomic/data/models/local_data_models/chapter_read_model.dart';
import 'package:webcomic/data/models/local_data_models/recently_read_model.dart';
import 'package:webcomic/data/models/local_data_models/read_progress_model.dart';
import 'package:webcomic/data/models/local_data_models/subscribed_model.dart';

class DatabaseHelper {
  static const _databaseName = "webcomic.db";
  static const _databaseVersion = 3; // Increment version for schema change
  static final DatabaseHelper instance = DatabaseHelper._();
  DatabaseHelper._();
  Database? _database;
  get database async {
    if (_database != null) return _database;
    _database = await initDatabase();
    return _database;
  }

  initDatabase() async {
    Directory dataDirectory = await getApplicationDocumentsDirectory();
    String dbPath = join(dataDirectory.path, _databaseName);
    return await openDatabase(dbPath,
        version: _databaseVersion,
        onCreate: _onCreateDB,
        onUpgrade: _onUpgrade);
  }

  _onCreateDB(Database db, int version) async {
    await db.execute('''
    CREATE TABLE ${RecentlyRead.tblName}(
    ${RecentlyRead.colMangaUrl} TEXT PRIMARY KEY,
    ${RecentlyRead.colChapterTitle} TEXT NOT NULL,
    ${RecentlyRead.colImageUrl}  TEXT NOT NULL,
    ${RecentlyRead.colMostRecentReadDate}  TEXT NOT NULL,
    ${RecentlyRead.colTitle}  TEXT NOT NULL,
    ${RecentlyRead.colChapterUrl}  TEXT NOT NULL,
    ${RecentlyRead.colMangaSource}  TEXT   
    )
   ''');
    await db.execute('''
    CREATE TABLE ${Subscribe.tblName}(
    ${Subscribe.colMangaUrl} TEXT PRIMARY KEY,
    ${Subscribe.colImageUrl} TEXT NOT NULL,
    ${Subscribe.colTitle}  TEXT NOT NULL,
    ${Subscribe.colDateSubscribed}  TEXT NOT NULL
    )
   ''');
    await db.execute('''
    CREATE TABLE ${ChapterRead.tblName}(
    ${ChapterRead.colChapterUrl} TEXT PRIMARY KEY,
    ${ChapterRead.colMangaUrl} TEXT NOT NULL
    )
   ''');
    await db.execute('''
    CREATE TABLE ${ReadProgress.tblName}(
    ${ReadProgress.colChapterUrl} TEXT PRIMARY KEY,
    ${ReadProgress.colMangaUrl} TEXT NOT NULL,
    ${ReadProgress.colLastPageIndex} INTEGER NOT NULL,
    ${ReadProgress.colTotalPages} INTEGER NOT NULL,
    ${ReadProgress.colUpdatedAt} TEXT NOT NULL
    )
   ''');
  }

  _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Add mangaSource column to existing RecentlyRead table
      await db.execute('''
        ALTER TABLE ${RecentlyRead.tblName} ADD COLUMN ${RecentlyRead.colMangaSource} TEXT
      ''');
    }
    if (oldVersion < 3) {
      // Create readprogress table
      await db.execute('''
        CREATE TABLE IF NOT EXISTS ${ReadProgress.tblName}(
          ${ReadProgress.colChapterUrl} TEXT PRIMARY KEY,
          ${ReadProgress.colMangaUrl} TEXT NOT NULL,
          ${ReadProgress.colLastPageIndex} INTEGER NOT NULL,
          ${ReadProgress.colTotalPages} INTEGER NOT NULL,
          ${ReadProgress.colUpdatedAt} TEXT NOT NULL
        )
      ''');
    }
  }

  insertRecentlyRead(RecentlyRead manga) async {
    Database db = await instance.database;
    await db.insert(RecentlyRead.tblName, manga.toMap());
  }

  insertSubscription(Subscribe manga) async {
    Database db = await instance.database;
    await db.insert(Subscribe.tblName, manga.toMap());
  }

  insertChapterRead(ChapterRead manga) async {
    Database db = await instance.database;
    await db.insert(ChapterRead.tblName, manga.toMap());
  }

  deleteRecentlyReadTable() async {
    Database db = await instance.database;
    await db.delete(RecentlyRead.tblName);
  }

  deleteSubscriptionTable() async {
    Database db = await instance.database;
    await db.delete(Subscribe.tblName);
  }

  Future<RecentlyRead> findRecentlyRead(String mangaUrl) async {
    final db = await instance.database;

    final maps = await db.query(
      RecentlyRead.tblName,
      columns: RecentlyRead.columnsToSelect,
      where: '${RecentlyRead.colMangaUrl} = ?',
      whereArgs: [mangaUrl],
    );

    if (maps.isNotEmpty) {
      return RecentlyRead.fromMap(maps.first);
    } else {
      throw Exception('Not found $mangaUrl');
    }
  }

  Future<int> updateRecentlyRead(RecentlyRead recentlyRead) async {
    final db = await instance.database;
    return db.update(
      RecentlyRead.tblName,
      recentlyRead.toMap(),
      where: '${RecentlyRead.colMangaUrl} = ?',
      whereArgs: [recentlyRead.mangaUrl],
    );
  }

  Future<void> updateOrInsertRecentlyRead(RecentlyRead mangaRead) async {
    final db = await instance.database;
    try {
      dynamic res = await db.rawQuery('''
       SELECT ${RecentlyRead.colMangaUrl} FROM ${RecentlyRead.tblName} WHERE ${RecentlyRead.colMangaUrl}="${mangaRead.mangaUrl}"
    ''');
      if (res.length == 0) {
        await insertRecentlyRead(mangaRead);
      } else {
        await updateRecentlyRead(mangaRead);
      }
    } catch (e) {
      await insertRecentlyRead(mangaRead);
    }
  }

  Future<void> updateOrInsertSubscription(Subscribe mangaInfo) async {
    final db = await instance.database;
    try {
      dynamic res = await db.rawQuery('''
       SELECT ${Subscribe.colMangaUrl} FROM ${Subscribe.tblName} WHERE ${Subscribe.colMangaUrl}="${mangaInfo.mangaUrl}"
    ''');
      if (res.length == 0) {
        await insertSubscription(mangaInfo);
      } else {
        await deleteSubscription(mangaInfo.mangaUrl);
      }
    } catch (e) {
      await insertSubscription(mangaInfo);
    }
  }

  Future<void> updateOrInsertChapterRead(ChapterRead chapterRead) async {
    final db = await instance.database;
    try {
      dynamic res = await db.rawQuery('''
       SELECT ${ChapterRead.colChapterUrl} FROM ${ChapterRead.tblName} WHERE ${ChapterRead.colChapterUrl}="${chapterRead.chapterUrl}"
    ''');
      if (res.length == 0) {
        await insertChapterRead(chapterRead);
      }
      //print(res[0]["mangaUrl"].runtimeType);
    } catch (e) {
      await insertChapterRead(chapterRead);
    }
  }

  // ReadProgress helpers
  Future<void> upsertReadProgress(ReadProgress progress) async {
    final db = await instance.database;
    await db.insert(
      ReadProgress.tblName,
      progress.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<ReadProgress?> getReadProgress(String chapterUrl) async {
    final db = await instance.database;
    final maps = await db.query(
      ReadProgress.tblName,
      columns: ReadProgress.columnsToSelect,
      where: '${ReadProgress.colChapterUrl} = ?',
      whereArgs: [chapterUrl],
      limit: 1,
    );
    if (maps.isNotEmpty) return ReadProgress.fromMap(maps.first);
    return null;
  }

  Future<ReadProgress?> getLastProgressForManga(String mangaUrl) async {
    final db = await instance.database;
    final maps = await db.query(
      ReadProgress.tblName,
      columns: ReadProgress.columnsToSelect,
      where: '${ReadProgress.colMangaUrl} = ?',
      whereArgs: [mangaUrl],
      orderBy: '${ReadProgress.colUpdatedAt} DESC',
      limit: 1,
    );
    if (maps.isNotEmpty) return ReadProgress.fromMap(maps.first);
    return null;
  }

  Future<int> deleteRecentlyRead(String mangaUrl) async {
    final db = await instance.database;
    return await db.delete(
      RecentlyRead.tblName,
      where: '${RecentlyRead.colMangaUrl} = ?',
      whereArgs: [mangaUrl],
    );
  }

  Future<int> deleteSubscription(String mangaUrl) async {
    final db = await instance.database;
    return await db.delete(
      Subscribe.tblName,
      where: '${Subscribe.colMangaUrl} = ?',
      whereArgs: [mangaUrl],
    );
  }

  Future<List<RecentlyRead>?>? getRecentReads() async {
    Database db = await instance.database;
    List<Map<String, dynamic>> recentReads =
        await db.query(RecentlyRead.tblName);
    return recentReads.isEmpty
        ? null
        : recentReads.map((i) => RecentlyRead.fromMap(i)).toList();
  }

  Future<List<Subscribe>?>? getSubscriptions() async {
    Database db = await instance.database;
    List<Map<String, dynamic>> subs = await db.query(Subscribe.tblName);
    return subs.isEmpty ? null : subs.map((i) => Subscribe.fromMap(i)).toList();
  }

  Future<List<ChapterRead>?>? getChaptersRead() async {
    Database db = await instance.database;
    List<Map<String, dynamic>> chaptersRead =
        await db.query(ChapterRead.tblName);
    return chaptersRead.isEmpty
        ? null
        : chaptersRead.map((i) => ChapterRead.fromMap(i)).toList();
  }

  Future close() async {
    final db = await instance.database;
    db.close();
  }
}
