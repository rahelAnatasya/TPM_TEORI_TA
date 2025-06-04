import 'package:sqflite/sqflite.dart';
import '../helpers/database_helper.dart';
import '../models/transaction.dart' as model;

class TransactionService {
  static Future<int> addTransaction(model.Transaction transaction) async {
    final db = await DatabaseHelper().database;
    return await db.insert('transactions', transaction.toJson());
  }

  static Future<List<model.Transaction>> getTransactionsByUser(
    String userEmail,
  ) async {
    final db = await DatabaseHelper().database;
    final List<Map<String, dynamic>> maps = await db.query(
      'transactions',
      where: 'user_email = ?',
      whereArgs: [userEmail],
      orderBy: 'transaction_date DESC',
    );

    return List.generate(maps.length, (i) {
      return model.Transaction.fromJson(maps[i]);
    });
  }

  static Future<List<model.Transaction>> getAllTransactions() async {
    final db = await DatabaseHelper().database;
    final List<Map<String, dynamic>> maps = await db.query(
      'transactions',
      orderBy: 'transaction_date DESC',
    );

    return List.generate(maps.length, (i) {
      return model.Transaction.fromJson(maps[i]);
    });
  }

  static Future<double> getTotalSpendingByUser(String userEmail) async {
    final db = await DatabaseHelper().database;
    final result = await db.rawQuery(
      'SELECT SUM(total_amount) as total FROM transactions WHERE user_email = ? AND status = "completed"',
      [userEmail],
    );

    return (result.first['total'] as double?) ?? 0.0;
  }

  static Future<int> getTransactionCountByUser(String userEmail) async {
    final db = await DatabaseHelper().database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM transactions WHERE user_email = ? AND status = "completed"',
      [userEmail],
    );

    return (result.first['count'] as int?) ?? 0;
  }
}
