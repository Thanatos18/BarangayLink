import 'package:flutter/material.dart';
import '../constants/app_constants.dart';

class BarangayProvider extends ChangeNotifier {
  // 1. Define the getter properly
  // It simply returns the constant list imported from app_constants.dart
  List<String> get tagumBarangaysList => tagumBarangays;

  // Global filter state
  String? _currentFilter;
  String? get currentFilter => _currentFilter;

  void setFilter(String? barangay) {
    _currentFilter = barangay;
    notifyListeners();
  }

  void clearFilter() {
    _currentFilter = null;
    notifyListeners();
  }

  List<String> searchBarangays(String query) {
    if (query.isEmpty) {
      // 2. Use the getter 'tagumBarangaysList'
      return tagumBarangaysList;
    }
    return tagumBarangaysList
        .where((b) => b.toLowerCase().contains(query.toLowerCase()))
        .toList();
  }

  bool isValidBarangay(String barangayName) {
    // 3. Use the getter 'tagumBarangaysList'
    return tagumBarangaysList.contains(barangayName);
  }
}
