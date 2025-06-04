import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/address.dart';

class AddressDatabaseService {
  static Database? _database;
  static const String _tableName = 'addresses';

  static Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  static Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'flora_addresses.db');
    return await openDatabase(
      path,
      version: 2,
      onCreate: _createTables,
      onUpgrade: _onUpgrade,
    );
  }

  static Future<void> _createTables(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $_tableName (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_email TEXT NOT NULL,
        name TEXT NOT NULL,
        full_address TEXT NOT NULL,
        latitude REAL NOT NULL,
        longitude REAL NOT NULL,
        is_default INTEGER DEFAULT 0,
        created_at TEXT,
        updated_at TEXT,
        FOREIGN KEY (user_email) REFERENCES users (email)
      )
    ''');

    // Create index for better performance
    await db.execute('''
      CREATE INDEX idx_addresses_user_email ON $_tableName (user_email)
    ''');
  }

  static Future<void> _onUpgrade(
    Database db,
    int oldVersion,
    int newVersion,
  ) async {
    if (oldVersion < 2) {
      // Add any upgrade logic here for future versions
    }
  }

  // Get all addresses for a specific user
  static Future<List<Address>> getAddressesByUserEmail(String userEmail) async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        _tableName,
        where: 'user_email = ?',
        whereArgs: [userEmail],
        orderBy: 'is_default DESC, created_at DESC',
      );

      return List.generate(maps.length, (i) {
        return Address.fromMap(maps[i]);
      });
    } catch (e) {
      throw Exception('Failed to get addresses: $e');
    }
  }

  // Get default address for a user
  static Future<Address?> getDefaultAddress(String userEmail) async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        _tableName,
        where: 'user_email = ? AND is_default = 1',
        whereArgs: [userEmail],
        limit: 1,
      );

      if (maps.isNotEmpty) {
        return Address.fromMap(maps.first);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get default address: $e');
    }
  }

  // Insert new address
  static Future<int> insertAddress(Address address) async {
    try {
      final db = await database;

      // If this is set as default, unset other defaults for this user
      if (address.isDefault && address.userEmail != null) {
        await _unsetDefaultAddresses(address.userEmail!);
      }

      address.createdAt = DateTime.now();
      address.updatedAt = DateTime.now();

      final id = await db.insert(_tableName, address.toMap());
      return id;
    } catch (e) {
      throw Exception('Failed to insert address: $e');
    }
  }

  // Update existing address
  static Future<int> updateAddress(Address address) async {
    try {
      final db = await database;

      // If this is set as default, unset other defaults for this user
      if (address.isDefault && address.userEmail != null) {
        await _unsetDefaultAddresses(address.userEmail!);
      }

      address.updatedAt = DateTime.now();

      return await db.update(
        _tableName,
        address.toMap(),
        where: 'id = ?',
        whereArgs: [address.id],
      );
    } catch (e) {
      throw Exception('Failed to update address: $e');
    }
  }

  // Delete address
  static Future<int> deleteAddress(int id) async {
    try {
      final db = await database;
      return await db.delete(_tableName, where: 'id = ?', whereArgs: [id]);
    } catch (e) {
      throw Exception('Failed to delete address: $e');
    }
  }

  // Set address as default
  static Future<void> setDefaultAddress(int addressId, String userEmail) async {
    try {
      final db = await database;

      // First unset all defaults for this user
      await _unsetDefaultAddresses(userEmail);

      // Then set the specified address as default
      await db.update(
        _tableName,
        {'is_default': 1, 'updated_at': DateTime.now().toIso8601String()},
        where: 'id = ? AND user_email = ?',
        whereArgs: [addressId, userEmail],
      );
    } catch (e) {
      throw Exception('Failed to set default address: $e');
    }
  }

  // Helper method to unset all default addresses for a user
  static Future<void> _unsetDefaultAddresses(String userEmail) async {
    final db = await database;
    await db.update(
      _tableName,
      {'is_default': 0, 'updated_at': DateTime.now().toIso8601String()},
      where: 'user_email = ? AND is_default = 1',
      whereArgs: [userEmail],
    );
  }

  // Get address count for a user
  static Future<int> getAddressCount(String userEmail) async {
    try {
      final db = await database;
      final result = await db.rawQuery(
        'SELECT COUNT(*) as count FROM $_tableName WHERE user_email = ?',
        [userEmail],
      );
      return Sqflite.firstIntValue(result) ?? 0;
    } catch (e) {
      throw Exception('Failed to get address count: $e');
    }
  }

  // Check if address exists
  static Future<bool> addressExists(int id) async {
    try {
      final db = await database;
      final result = await db.query(
        _tableName,
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );
      return result.isNotEmpty;
    } catch (e) {
      throw Exception('Failed to check address existence: $e');
    }
  }

  // Clear all addresses for a user (useful for logout/cleanup)
  static Future<void> clearUserAddresses(String userEmail) async {
    try {
      final db = await database;
      await db.delete(
        _tableName,
        where: 'user_email = ?',
        whereArgs: [userEmail],
      );
    } catch (e) {
      throw Exception('Failed to clear user addresses: $e');
    }
  }
}
