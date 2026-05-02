import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:boutique_manager/services/database_service.dart';
import 'package:boutique_manager/services/notification_service.dart';

class SyncService {
  static final SyncService instance = SyncService._();
  SyncService._();

  bool _isInitialized = false;
  StreamSubscription? _connectivitySubscription;

  /// Initialize Supabase and listen for connectivity changes.
  /// Call this only after the user provides their Supabase credentials.
  Future<void> init({
    required String supabaseUrl,
    required String supabaseAnonKey,
  }) async {
    if (_isInitialized) return;

    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
    );
    _isInitialized = true;

    // Auto-sync when Wi-Fi becomes available
    _connectivitySubscription = Connectivity()
        .onConnectivityChanged
        .listen((results) {
      if (results.contains(ConnectivityResult.wifi)) {
        syncToCloud();
      }
    });
  }

  bool get isInitialized => _isInitialized;

  SupabaseClient? get _client =>
      _isInitialized ? Supabase.instance.client : null;

  Future<void> syncToCloud() async {
    if (!_isInitialized) return;
    final client = _client;
    if (client == null) return;

    final db = DatabaseService.instance;
    int syncedCount = 0;

    // Sync products
    final unsyncedProducts = await db.getUnsyncedProducts();
    if (unsyncedProducts.isNotEmpty) {
      final rows = unsyncedProducts.map((p) {
        final copy = Map<String, dynamic>.from(p);
        copy.remove('is_synced');
        return copy;
      }).toList();

      await client.from('products').upsert(rows);
      await db.markSynced(
          'products', unsyncedProducts.map((p) => p['id'] as String).toList());
      syncedCount += unsyncedProducts.length;
    }

    // Sync ledger entries
    final unsyncedLedger = await db.getUnsyncedLedgerEntries();
    if (unsyncedLedger.isNotEmpty) {
      final rows = unsyncedLedger.map((l) {
        final copy = Map<String, dynamic>.from(l);
        copy.remove('is_synced');
        return copy;
      }).toList();

      await client.from('ledger_entries').upsert(rows);
      await db.markSynced('ledger_entries',
          unsyncedLedger.map((l) => l['id'] as String).toList());
      syncedCount += unsyncedLedger.length;
    }

    if (syncedCount > 0) {
      await NotificationService.instance.showSyncComplete(syncedCount);
    }
  }

  void dispose() {
    _connectivitySubscription?.cancel();
  }
}
