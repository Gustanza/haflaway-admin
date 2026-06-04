import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:haflaway/models/attendee.dart';
import 'package:haflaway/models/event.dart';
import 'package:haflaway/services/checkpoint_db.dart';

enum SyncStatus { idle, downloading, syncing, synced, error }

class CheckpointSyncService extends ChangeNotifier {
  final String eId;

  CheckpointSyncService({required this.eId});

  final _db = CheckpointLocalDB.instance;
  final _firestore = FirebaseFirestore.instance;

  SyncStatus _status = SyncStatus.idle;
  DateTime? _lastSynced;
  String? _errorMessage;
  int _downloadTotal = 0;
  int _downloadDone = 0;
  Timer? _syncTimer;
  bool _disposed = false;

  SyncStatus get status => _status;
  DateTime? get lastSynced => _lastSynced;
  String? get errorMessage => _errorMessage;
  int get downloadTotal => _downloadTotal;
  int get downloadDone => _downloadDone;

  // ── Public API ─────────────────────────────────────────────────────────────

  /// Full initial download of all attendees for [eId] into SQLite.
  /// Shows progress via [downloadDone] / [downloadTotal].
  Future<bool> downloadAll() async {
    _set(SyncStatus.downloading, downloadDone: 0, downloadTotal: 0);

    try {
      // Get total count first for progress
      final countSnap =
          await _firestore
              .collection(ecol)
              .doc(eId)
              .collection(atcol)
              .count()
              .get();
      _downloadTotal = countSnap.count ?? 0;
      _notify();

      // Page through in batches of 200 to avoid memory spikes
      const batchSize = 200;
      DocumentSnapshot? lastDoc;
      int fetched = 0;

      while (true) {
        Query query = _firestore
            .collection(ecol)
            .doc(eId)
            .collection(atcol)
            .limit(batchSize);

        if (lastDoc != null) {
          query = query.startAfterDocument(lastDoc);
        }

        final snap = await query.get();
        if (snap.docs.isEmpty) break;

        final rows =
            snap.docs.map((d) {
              final data = Map<String, dynamic>.from(d.data() as Map);
              data['id'] = d.id;
              return data;
            }).toList();

        await _db.upsertAll(eId, rows);
        fetched += snap.docs.length;
        _downloadDone = fetched;
        _notify();

        if (snap.docs.length < batchSize) break;
        lastDoc = snap.docs.last;
      }

      await _db.setLastSyncTime(eId);
      _lastSynced = DateTime.now();
      _set(SyncStatus.synced);
      return true;
    } catch (e) {
      _set(SyncStatus.error, error: e.toString());
      return false;
    }
  }

  /// Start the autonomous 15-second background sync loop.
  /// Safe to call even if already started (idempotent).
  void startAutoSync() {
    if (_syncTimer != null) return;
    _syncTimer = Timer.periodic(const Duration(seconds: 15), (_) => _syncOnce());
    // Also kick off an immediate sync pass
    _syncOnce();
  }

  void stopAutoSync() {
    _syncTimer?.cancel();
    _syncTimer = null;
  }

  // ── Internal ───────────────────────────────────────────────────────────────

  Future<void> _syncOnce() async {
    if (_disposed) return;
    if (_status == SyncStatus.downloading) return;

    _set(SyncStatus.syncing);
    try {
      // Fetch only docs updated since last sync — use a simple full re-pull
      // for correctness (attendee count rarely exceeds a few thousand).
      const batchSize = 200;
      DocumentSnapshot? lastDoc;

      while (true) {
        Query query = _firestore
            .collection(ecol)
            .doc(eId)
            .collection(atcol)
            .limit(batchSize);

        if (lastDoc != null) {
          query = query.startAfterDocument(lastDoc);
        }

        final snap = await query.get();
        if (snap.docs.isEmpty) break;

        final rows =
            snap.docs.map((d) {
              final data = Map<String, dynamic>.from(d.data() as Map);
              data['id'] = d.id;
              return data;
            }).toList();

        await _db.upsertAll(eId, rows);

        if (snap.docs.length < batchSize) break;
        lastDoc = snap.docs.last;
      }

      await _db.setLastSyncTime(eId);
      if (!_disposed) {
        _lastSynced = DateTime.now();
        _set(SyncStatus.synced);
      }
    } catch (_) {
      if (!_disposed) _set(SyncStatus.error);
    }
  }

  void _set(
    SyncStatus s, {
    String? error,
    int? downloadDone,
    int? downloadTotal,
  }) {
    _status = s;
    if (error != null) _errorMessage = error;
    if (downloadDone != null) _downloadDone = downloadDone;
    if (downloadTotal != null) _downloadTotal = downloadTotal;
    _notify();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    stopAutoSync();
    super.dispose();
  }
}
