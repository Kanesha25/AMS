import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/spare_part_model.dart';

class SparePartsDatabase {
  static final SparePartsDatabase _instance = SparePartsDatabase._internal();
  static Database? _database;

  SparePartsDatabase._internal();

  factory SparePartsDatabase() {
    return _instance;
  }

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'spare_parts.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _createTable,
    );
  }

  Future<void> _createTable(Database db, int version) async {
    await db.execute('''
      CREATE TABLE spare_parts(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        min_price INTEGER NOT NULL,
        max_price INTEGER NOT NULL
      )
    ''');

    // Insert default data
    await _insertDefaultData(db);
  }

  Future<void> _insertDefaultData(Database db) async {
    final defaultParts = [
      {'name': 'Left Headlight', 'min_price': 50000, 'max_price': 125000},
      {'name': 'Side Mirror', 'min_price': 20000, 'max_price': 75000},
      {'name': 'Tail Light', 'min_price': 50000, 'max_price': 100000},
      {'name': 'Bonnet', 'min_price': 10000, 'max_price': 15000},
      {'name': 'Bumper', 'min_price': 70000, 'max_price': 150000},
      {'name': 'Windscreen', 'min_price': 100000, 'max_price': 175000},
    ];

    for (var part in defaultParts) {
      await db.insert('spare_parts', part);
    }
  }

  Future<List<SparePart>> getAllSpareParts() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('spare_parts');

    return List.generate(maps.length, (i) {
      return SparePart(
        id: maps[i]['id'],
        name: maps[i]['name'],
        minPrice: maps[i]['min_price'],
        maxPrice: maps[i]['max_price'],
      );
    });
  }

  Future<int> insertSparePart(SparePart sparePart) async {
    final db = await database;
    return await db.insert(
      'spare_parts',
      {
        'name': sparePart.name,
        'min_price': sparePart.minPrice,
        'max_price': sparePart.maxPrice,
      },
    );
  }

  Future<int> updateSparePart(SparePart sparePart) async {
    final db = await database;
    return await db.update(
      'spare_parts',
      {
        'name': sparePart.name,
        'min_price': sparePart.minPrice,
        'max_price': sparePart.maxPrice,
      },
      where: 'id = ?',
      whereArgs: [sparePart.id],
    );
  }

  Future<int> deleteSparePart(int id) async {
    final db = await database;
    return await db.delete(
      'spare_parts',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> updateMultipleSpareParts(List<SparePart> spareParts) async {
    final db = await database;
    final batch = db.batch();

    for (var sparePart in spareParts) {
      batch.update(
        'spare_parts',
        {
          'name': sparePart.name,
          'min_price': sparePart.minPrice,
          'max_price': sparePart.maxPrice,
        },
        where: 'id = ?',
        whereArgs: [sparePart.id],
      );
    }

    await batch.commit();
  }
}