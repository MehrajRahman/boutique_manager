import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseService {
  static final DatabaseService instance = DatabaseService._init();
  static Database? _database;

  DatabaseService._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('boutique_manager.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 2,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute(
          'ALTER TABLE products ADD COLUMN category_id TEXT REFERENCES categories(id)');
      await db.execute(
          'ALTER TABLE products ADD COLUMN is_public INTEGER NOT NULL DEFAULT 1');
      await _createV2Tables(db);
    }
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE categories (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        description TEXT,
        icon_name TEXT,
        cover_image_path TEXT,
        sort_order INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        is_synced INTEGER NOT NULL DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE products (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        price REAL NOT NULL,
        quantity INTEGER NOT NULL DEFAULT 0,
        low_stock_threshold INTEGER NOT NULL DEFAULT 5,
        image_path TEXT,
        image_url TEXT,
        visual_fingerprint TEXT,
        custom_fields TEXT DEFAULT '{}',
        barcode TEXT,
        category_id TEXT REFERENCES categories(id),
        is_public INTEGER NOT NULL DEFAULT 1,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        is_synced INTEGER NOT NULL DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE ledger_entries (
        id TEXT PRIMARY KEY,
        product_id TEXT NOT NULL,
        product_name TEXT NOT NULL,
        quantity_change INTEGER NOT NULL,
        quantity_after INTEGER NOT NULL,
        reason TEXT DEFAULT '',
        created_at TEXT NOT NULL,
        is_synced INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY (product_id) REFERENCES products (id) ON DELETE CASCADE
      )
    ''');

    await _createV2Tables(db);

    await db.execute('CREATE INDEX idx_products_name ON products (name)');
    await db.execute('CREATE INDEX idx_products_category ON products (category_id)');
    await db.execute('CREATE INDEX idx_ledger_product_id ON ledger_entries (product_id)');
    await db.execute('CREATE INDEX idx_ledger_created_at ON ledger_entries (created_at DESC)');
    await db.execute('CREATE INDEX idx_orders_status ON orders (status)');
    await db.execute('CREATE INDEX idx_order_items_order ON order_items (order_id)');
  }

  Future<void> _createV2Tables(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS orders (
        id TEXT PRIMARY KEY,
        buyer_name TEXT NOT NULL,
        buyer_phone TEXT,
        buyer_note TEXT,
        total_amount REAL NOT NULL,
        status TEXT NOT NULL DEFAULT 'pending',
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        is_synced INTEGER NOT NULL DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS order_items (
        id TEXT PRIMARY KEY,
        order_id TEXT NOT NULL,
        product_id TEXT NOT NULL,
        product_name TEXT NOT NULL,
        price REAL NOT NULL,
        quantity INTEGER NOT NULL,
        FOREIGN KEY (order_id) REFERENCES orders (id) ON DELETE CASCADE,
        FOREIGN KEY (product_id) REFERENCES products (id)
      )
    ''');
  }

  // Product CRUD
  Future<int> insertProduct(Map<String, dynamic> product) async {
    final db = await database;
    return db.insert('products', product,
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<int> updateProduct(Map<String, dynamic> product) async {
    final db = await database;
    return db.update('products', product,
        where: 'id = ?', whereArgs: [product['id']]);
  }

  Future<int> deleteProduct(String id) async {
    final db = await database;
    return db.delete('products', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Map<String, dynamic>>> getProducts({
    int limit = 20,
    int offset = 0,
    String? searchQuery,
  }) async {
    final db = await database;
    if (searchQuery != null && searchQuery.isNotEmpty) {
      return db.query(
        'products',
        where: 'name LIKE ?',
        whereArgs: ['%$searchQuery%'],
        orderBy: 'updated_at DESC',
        limit: limit,
        offset: offset,
      );
    }
    return db.query(
      'products',
      orderBy: 'updated_at DESC',
      limit: limit,
      offset: offset,
    );
  }

  Future<Map<String, dynamic>?> getProduct(String id) async {
    final db = await database;
    final results =
        await db.query('products', where: 'id = ?', whereArgs: [id]);
    return results.isNotEmpty ? results.first : null;
  }

  Future<List<Map<String, dynamic>>> getLowStockProducts() async {
    final db = await database;
    return db.rawQuery(
      'SELECT * FROM products WHERE quantity <= low_stock_threshold ORDER BY quantity ASC',
    );
  }

  Future<List<Map<String, dynamic>>> getUnsyncedProducts() async {
    final db = await database;
    return db.query('products', where: 'is_synced = 0');
  }

  Future<int> getProductCount() async {
    final db = await database;
    final result =
        await db.rawQuery('SELECT COUNT(*) as count FROM products');
    return result.first['count'] as int;
  }

  // Ledger CRUD
  Future<int> insertLedgerEntry(Map<String, dynamic> entry) async {
    final db = await database;
    return db.insert('ledger_entries', entry);
  }

  Future<List<Map<String, dynamic>>> getLedgerEntries({
    int limit = 30,
    int offset = 0,
    String? productId,
  }) async {
    final db = await database;
    if (productId != null) {
      return db.query(
        'ledger_entries',
        where: 'product_id = ?',
        whereArgs: [productId],
        orderBy: 'created_at DESC',
        limit: limit,
        offset: offset,
      );
    }
    return db.query(
      'ledger_entries',
      orderBy: 'created_at DESC',
      limit: limit,
      offset: offset,
    );
  }

  Future<List<Map<String, dynamic>>> getUnsyncedLedgerEntries() async {
    final db = await database;
    return db.query('ledger_entries', where: 'is_synced = 0');
  }

  Future<void> markSynced(String table, List<String> ids) async {
    final db = await database;
    final batch = db.batch();
    for (final id in ids) {
      batch.update(table, {'is_synced': 1},
          where: 'id = ?', whereArgs: [id]);
    }
    await batch.commit(noResult: true);
  }

  // ─── Category CRUD ───

  Future<int> insertCategory(Map<String, dynamic> category) async {
    final db = await database;
    return db.insert('categories', category,
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<int> updateCategory(Map<String, dynamic> category) async {
    final db = await database;
    return db.update('categories', category,
        where: 'id = ?', whereArgs: [category['id']]);
  }

  Future<int> deleteCategory(String id) async {
    final db = await database;
    // Move products in this category to uncategorized
    await db.update('products', {'category_id': null},
        where: 'category_id = ?', whereArgs: [id]);
    return db.delete('categories', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Map<String, dynamic>>> getCategories() async {
    final db = await database;
    return db.query('categories', orderBy: 'sort_order ASC, name ASC');
  }

  Future<int> getCategoryProductCount(String categoryId) async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM products WHERE category_id = ?',
      [categoryId],
    );
    return result.first['count'] as int;
  }

  Future<int> getUncategorizedProductCount() async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM products WHERE category_id IS NULL',
    );
    return result.first['count'] as int;
  }

  // ─── Products by category ───

  Future<List<Map<String, dynamic>>> getProductsByCategory({
    String? categoryId,
    int limit = 20,
    int offset = 0,
    String? searchQuery,
  }) async {
    final db = await database;
    final where = <String>[];
    final args = <dynamic>[];

    if (categoryId != null) {
      where.add('category_id = ?');
      args.add(categoryId);
    } else {
      where.add('category_id IS NULL');
    }

    if (searchQuery != null && searchQuery.isNotEmpty) {
      where.add('name LIKE ?');
      args.add('%$searchQuery%');
    }

    return db.query(
      'products',
      where: where.join(' AND '),
      whereArgs: args,
      orderBy: 'updated_at DESC',
      limit: limit,
      offset: offset,
    );
  }

  Future<List<Map<String, dynamic>>> getPublicProducts({
    int limit = 20,
    int offset = 0,
    String? searchQuery,
  }) async {
    final db = await database;
    if (searchQuery != null && searchQuery.isNotEmpty) {
      return db.query(
        'products',
        where: 'is_public = 1 AND quantity > 0 AND name LIKE ?',
        whereArgs: ['%$searchQuery%'],
        orderBy: 'name ASC',
        limit: limit,
        offset: offset,
      );
    }
    return db.query(
      'products',
      where: 'is_public = 1 AND quantity > 0',
      orderBy: 'name ASC',
      limit: limit,
      offset: offset,
    );
  }

  // ─── Order CRUD ───

  Future<void> insertOrder(
      Map<String, dynamic> order, List<Map<String, dynamic>> items) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.insert('orders', order);
      for (final item in items) {
        await txn.insert('order_items', item);
      }
    });
  }

  Future<int> updateOrderStatus(String orderId, String status) async {
    final db = await database;
    return db.update(
      'orders',
      {'status': status, 'updated_at': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [orderId],
    );
  }

  Future<List<Map<String, dynamic>>> getOrders({
    String? status,
    int limit = 20,
    int offset = 0,
  }) async {
    final db = await database;
    if (status != null) {
      return db.query('orders',
          where: 'status = ?',
          whereArgs: [status],
          orderBy: 'created_at DESC',
          limit: limit,
          offset: offset);
    }
    return db.query('orders',
        orderBy: 'created_at DESC', limit: limit, offset: offset);
  }

  Future<List<Map<String, dynamic>>> getOrderItems(String orderId) async {
    final db = await database;
    return db.query('order_items',
        where: 'order_id = ?', whereArgs: [orderId]);
  }

  Future<Map<String, dynamic>> getOrderStats() async {
    final db = await database;
    final pending = await db.rawQuery(
        "SELECT COUNT(*) as c FROM orders WHERE status = 'pending'");
    final total = await db.rawQuery(
        "SELECT COALESCE(SUM(total_amount), 0) as t FROM orders WHERE status = 'fulfilled'");
    return {
      'pending_count': pending.first['c'] as int,
      'total_revenue': (total.first['t'] as num).toDouble(),
    };
  }
}
