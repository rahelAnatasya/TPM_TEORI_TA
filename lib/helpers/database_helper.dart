import 'dart:async';
import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

// Database helper class
class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;

  static Database? _database;

  // Private constructor
  DatabaseHelper._internal();

  // Initialize the database
  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  // Create and open the database
  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'flora_store.db');
    return await openDatabase(path, version: 1, onCreate: _createDb);
  }

  // Create tables in the database
  static Future<void> _createDb(Database db, int version) async {
    // Create users table
    await db.execute('''
      CREATE TABLE users(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        email TEXT NOT NULL UNIQUE,
        password TEXT NOT NULL,
        profile_picture_path TEXT
      )
    ''');

    // Create plants table
    await db.execute('''
      CREATE TABLE plants(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        scientific_name TEXT,
        description TEXT,
        image_url TEXT,
        price REAL NOT NULL,
        currency TEXT NOT NULL DEFAULT 'IDR',
        stock INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // Create transactions table
    await db.execute('''
      CREATE TABLE transactions(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_email TEXT NOT NULL,
        plant_id INTEGER NOT NULL,
        plant_name TEXT NOT NULL,
        plant_image_url TEXT,
        price REAL NOT NULL,
        currency TEXT NOT NULL DEFAULT 'IDR',
        quantity INTEGER NOT NULL DEFAULT 1,
        total_amount REAL NOT NULL,
        transaction_date TEXT NOT NULL,
        status TEXT NOT NULL DEFAULT 'completed'
      )
    ''');
  }

  // Add other database helper methods (CRUD operations) here
}
