import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import '../models/user.dart';
import '../utils/database_helper.dart';

class AuthService {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  Future<bool> register({
    required String username,
    required String email,
    required String password,
  }) async {
    if (await _dbHelper.isUsernameTaken(username)) {
      throw Exception('Username sudah digunakan');
    }

    if (await _dbHelper.isEmailRegistered(email)) {
      throw Exception('Email sudah terdaftar');
    }

    final user = User(username: username, email: email, password: password);

    try {
      await _dbHelper.insertUser(user);
      return true;
    } catch (e) {
      throw Exception('Gagal mendaftar: ${e.toString()}');
    }
  }

  Future<User?> loginWithUsername(String username, String password) async {
    return await _dbHelper.loginWithUsername(username, password);
  }

  Future<User?> loginWithEmail(String email, String password) async {
    return await _dbHelper.loginWithEmail(email, password);
  }

  Future<User?> getUserByEmail(String email) async {
    return await _dbHelper.getUserByEmail(email);
  }

  Future<User?> getUserById(int id) async {
    return await _dbHelper.getUserById(id);
  }

  Future<void> updateUser(User user) async {
    await _dbHelper.updateUser(user);
  }

  Future<bool> verifyPassword(int userId, String currentPassword) async {
    return await _dbHelper.verifyPassword(userId, currentPassword);
  }

  Future<void> updatePassword(int userId, String newPassword) async {
    await _dbHelper.updatePassword(userId, newPassword);
  }

  // Helper to save profile image and get the path
  Future<String?> saveProfileImage(File imageFile) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final fileName =
          '${DateTime.now().millisecondsSinceEpoch}_${path.basename(imageFile.path)}';
      final savedImage = await imageFile.copy('${directory.path}/$fileName');
      return savedImage.path;
    } catch (e) {
      print('Error saving profile image: $e');
      return null;
    }
  }

  // Helper to delete old profile image if it exists
  Future<void> deleteProfileImage(String? imagePath) async {
    if (imagePath != null && imagePath.isNotEmpty) {
      try {
        final file = File(imagePath);
        if (await file.exists()) {
          await file.delete();
        }
      } catch (e) {
        print('Error deleting profile image: $e');
      }
    }
  }
}
