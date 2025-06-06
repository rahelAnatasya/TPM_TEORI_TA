import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import '../models/plant.dart';

class ApiService {
  static String url = "https://flora-shop-2.vercel.app/api/v1/plants";

  static Future<List<dynamic>> getPlants() async {
    try {
      final response = await http
          .get(Uri.parse(url), headers: {"Content-Type": "application/json"})
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final decodedData = jsonDecode(response.body);
        final plantsData = decodedData['data']['plants'];
        return plantsData;
      } else {
        throw Exception('HTTP ${response.statusCode}: Failed to load plants');
      }
    } on SocketException {
      throw Exception('Tidak ada koneksi internet. Periksa koneksi Anda.');
    } on HttpException {
      throw Exception('Server tidak dapat dijangkau.');
    } on FormatException {
      throw Exception('Response format error dari server.');
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  static Future<List<dynamic>> searchPlants(String query) async {
    try {
      final response = await http.get(Uri.parse("$url/search?q=$query"));

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return responseData['data']['plants'] ?? [];
      } else {
        throw Exception('Failed to search plants: ${response.statusCode}');
      }
    } catch (e) {
      print('Exception while searching plants: $e');
      throw Exception('Failed to search plants: $e');
    }
  }

  static Future<Map<String, dynamic>> getPlantDetail(int id) async {
    final response = await http.get(Uri.parse("$url/$id"));
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> addPlant(Plant newPlant) async {
    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(newPlant),
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode >= 400) {
        print(
          'Error adding plant: ${response.statusCode} - ${responseData['message'] ?? 'Unknown error'}',
        );
        throw Exception(
          'Failed to add plant: ${responseData['message'] ?? 'Unknown error'}',
        );
      }

      return responseData;
    } catch (e) {
      print('Exception while adding plant: $e');
      throw Exception('Failed to add plant: $e');
    }
  }

  static Future<Map<String, dynamic>> updatePlant(Plant updatedPlant) async {
    try {
      final response = await http.put(
        Uri.parse("$url/${updatedPlant.id}"),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(updatedPlant),
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode >= 400) {
        print(
          'Error updating plant: ${response.statusCode} - ${responseData['message'] ?? 'Unknown error'}',
        );
        throw Exception(
          'Failed to update plant: ${responseData['message'] ?? 'Unknown error'} (Response: ${response.body})',
        );
      }

      return responseData;
    } catch (e) {
      print('Exception while updating plant: $e');
      throw Exception('Failed to update plant: $e');
    }
  }

  static Future<Map<String, dynamic>> deletePlant(int id) async {
    try {
      final response = await http.delete(Uri.parse("$url/$id"));

      final responseData = jsonDecode(response.body);

      if (response.statusCode >= 400) {
        print(
          'Error deleting plant: ${response.statusCode} - ${responseData['message'] ?? 'Unknown error'}',
        );
        throw Exception(
          'Failed to delete plant: ${responseData['message'] ?? 'Unknown error'}',
        );
      }

      return responseData;
    } catch (e) {
      print('Exception while deleting plant: $e');
      throw Exception('Failed to delete plant: $e');
    }
  }
}
