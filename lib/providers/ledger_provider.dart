import 'package:flutter/foundation.dart';
import 'package:boutique_manager/models/ledger_entry.dart';
import 'package:boutique_manager/services/database_service.dart';

class LedgerProvider extends ChangeNotifier {
  final _db = DatabaseService.instance;

  List<LedgerEntry> _entries = [];
  bool _isLoading = false;
  bool _hasMore = true;

  List<LedgerEntry> get entries => _entries;
  bool get isLoading => _isLoading;
  bool get hasMore => _hasMore;

  Future<void> loadEntries({bool refresh = false, String? productId}) async {
    if (_isLoading) return;
    _isLoading = true;
    notifyListeners();

    if (refresh) {
      _entries = [];
      _hasMore = true;
    }

    final maps = await _db.getLedgerEntries(
      limit: 30,
      offset: _entries.length,
      productId: productId,
    );

    final newEntries = maps.map((m) => LedgerEntry.fromMap(m)).toList();
    _entries.addAll(newEntries);
    _hasMore = newEntries.length == 30;

    _isLoading = false;
    notifyListeners();
  }
}
