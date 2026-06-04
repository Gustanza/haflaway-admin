import 'dart:convert';
import 'package:haflaway/models/attendee.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class CheckpointLocalDB {
  CheckpointLocalDB._();
  static final CheckpointLocalDB instance = CheckpointLocalDB._();

  Database? _db;

  Future<Database> get db async {
    _db ??= await _open();
    return _db!;
  }

  Future<Database> _open() async {
    final path = join(await getDatabasesPath(), 'checkpoint_attendees.db');
    return openDatabase(
      path,
      version: 1,
      onCreate: (db, _) async {
        await db.execute('''
          CREATE TABLE checkpoint_attendees (
            id TEXT NOT NULL,
            event_id TEXT NOT NULL,
            full_name_lower TEXT NOT NULL,
            cards_json TEXT NOT NULL,
            checkin_json TEXT NOT NULL,
            data_json TEXT NOT NULL,
            PRIMARY KEY (id, event_id)
          )
        ''');
        await db.execute(
          'CREATE INDEX idx_cp_att_search ON checkpoint_attendees(event_id, full_name_lower)',
        );
        await db.execute('''
          CREATE TABLE checkpoint_sync_meta (
            event_id TEXT PRIMARY KEY,
            last_sync_ms INTEGER NOT NULL DEFAULT 0
          )
        ''');
      },
    );
  }

  // ── Write ──────────────────────────────────────────────────────────────────

  Future<void> upsertAll(String eId, List<Map<String, dynamic>> rows) async {
    final database = await db;
    final batch = database.batch();
    for (final row in rows) {
      final id = row['id'] as String? ?? '';
      if (id.isEmpty) continue;
      batch.insert(
        'checkpoint_attendees',
        {
          'id': id,
          'event_id': eId,
          'full_name_lower':
              (row['fullNameLower'] ?? (row['fullName'] ?? '').toLowerCase())
                  as String,
          'cards_json': jsonEncode(row['cards'] ?? {}),
          'checkin_json': jsonEncode(row['checkinStatus'] ?? []),
          'data_json': jsonEncode(row),
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  Future<void> updateCheckin(String attId, List checkinStatus) async {
    final database = await db;
    await database.update(
      'checkpoint_attendees',
      {'checkin_json': jsonEncode(checkinStatus)},
      where: 'id = ?',
      whereArgs: [attId],
    );
  }

  // ── Read ───────────────────────────────────────────────────────────────────

  Future<List<Attendee>> search(String eId, String query) async {
    if (query.trim().isEmpty) return [];
    final database = await db;
    final lower = query.trim().toLowerCase();
    final rows = await database.query(
      'checkpoint_attendees',
      columns: ['id', 'data_json', 'checkin_json'],
      where: 'event_id = ? AND full_name_lower LIKE ?',
      whereArgs: [eId, '%$lower%'],
      limit: 40,
    );
    return rows.map((r) {
      final map = Map<String, dynamic>.from(
        jsonDecode(r['data_json'] as String) as Map,
      );
      // Overlay the freshest checkin_json (may be newer than data_json)
      map['checkinStatus'] = jsonDecode(r['checkin_json'] as String);
      map['id'] = r['id'];
      return Attendee.fromMap(r['id'] as String, map);
    }).toList();
  }

  Future<Attendee?> getById(String attId) async {
    final database = await db;
    final rows = await database.query(
      'checkpoint_attendees',
      columns: ['id', 'data_json', 'checkin_json'],
      where: 'id = ?',
      whereArgs: [attId],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    final r = rows.first;
    final map = Map<String, dynamic>.from(
      jsonDecode(r['data_json'] as String) as Map,
    );
    map['checkinStatus'] = jsonDecode(r['checkin_json'] as String);
    map['id'] = r['id'];
    return Attendee.fromMap(r['id'] as String, map);
  }

  Future<int> count(String eId) async {
    final database = await db;
    final result = await database.rawQuery(
      'SELECT COUNT(*) as c FROM checkpoint_attendees WHERE event_id = ?',
      [eId],
    );
    return (result.first['c'] as int?) ?? 0;
  }

  // ── Sync meta ──────────────────────────────────────────────────────────────

  Future<DateTime?> lastSyncTime(String eId) async {
    final database = await db;
    final rows = await database.query(
      'checkpoint_sync_meta',
      where: 'event_id = ?',
      whereArgs: [eId],
    );
    if (rows.isEmpty) return null;
    final ms = rows.first['last_sync_ms'] as int?;
    if (ms == null || ms == 0) return null;
    return DateTime.fromMillisecondsSinceEpoch(ms);
  }

  Future<void> setLastSyncTime(String eId) async {
    final database = await db;
    await database.insert(
      'checkpoint_sync_meta',
      {
        'event_id': eId,
        'last_sync_ms': DateTime.now().millisecondsSinceEpoch,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> clearEvent(String eId) async {
    final database = await db;
    await database.delete(
      'checkpoint_attendees',
      where: 'event_id = ?',
      whereArgs: [eId],
    );
    await database.delete(
      'checkpoint_sync_meta',
      where: 'event_id = ?',
      whereArgs: [eId],
    );
  }
}
