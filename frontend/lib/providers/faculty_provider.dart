import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../main.dart' show apiUrl;

class FacultyProvider with ChangeNotifier {
  List<dynamic> _faculties = [];
  String? _selectedFacultyId;
  bool _isLoading = false;
  String? _error;

  List<dynamic> get faculties => _faculties;
  String? get selectedFacultyId => _selectedFacultyId;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Get selected faculty name
  String? get selectedFacultyName {
    if (_selectedFacultyId == null) return null;
    try {
      final faculty = _faculties.firstWhere(
        (f) => f['_id'] == _selectedFacultyId,
      );
      return faculty['name']?.toString();
    } catch (e) {
      return null;
    }
  }

  Future<void> loadFaculties() async {
    if (_isLoading) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await http
          .get(
            Uri.parse('$apiUrl/api/faculties'),
            headers: {'Content-Type': 'application/json'},
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _faculties = data is List ? data : [];
        _error = null;

        // Auto-select first faculty if available
        if (_faculties.isNotEmpty && _selectedFacultyId == null) {
          _selectedFacultyId = _faculties.first['_id']?.toString();
        }
      } else {
        _error =
            'Erreur lors du chargement des facultés (${response.statusCode})';
      }
    } catch (e) {
      _error = 'Erreur réseau: $e';
      debugPrint('❌ Error loading faculties: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void selectFaculty(String? facultyId) {
    if (_selectedFacultyId != facultyId) {
      _selectedFacultyId = facultyId;
      notifyListeners();
    }
  }

  void clearSelection() {
    _selectedFacultyId = null;
    notifyListeners();
  }
}
