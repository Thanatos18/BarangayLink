import '../constants/app_constants.dart';

class Validators {
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    if (!emailRegex.hasMatch(value)) {
      return 'Please enter a valid email address';
    }
    return null;
  }

  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (value.length < 8) {
      return 'Password must be at least 8 characters long';
    }
    if (!value.contains(RegExp(r'[A-Z]'))) {
      return 'Password must contain at least one uppercase letter';
    }
    if (!value.contains(RegExp(r'[a-z]'))) {
      return 'Password must contain at least one lowercase letter';
    }
    if (!value.contains(RegExp(r'[0-9]'))) {
      return 'Password must contain at least one number';
    }
    return null;
  }

  static String? validateConfirmPassword(
    String? password,
    String? confirmPassword,
  ) {
    if (confirmPassword == null || confirmPassword.isEmpty) {
      return 'Please confirm your password';
    }
    if (password == null || password.isEmpty) {
      return 'Enter password first';
    }
    if (password != confirmPassword) {
      return 'Passwords do not match';
    }
    return null;
  }

  static String? validateName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Name is required';
    }
    if (value.trim().length < 2) {
      return 'Name must be at least 2 characters long';
    }
    final nameRegex = RegExp(r"^[a-zA-Z\s\.\-]+$");
    if (!nameRegex.hasMatch(value)) {
      return 'Name can only contain letters, spaces, dots, and hyphens';
    }
    return null;
  }

  static String? validatePhoneNumber(String? value) {
    if (value == null || value.isEmpty) {
      return 'Phone number is required';
    }
    final cleanValue = value.replaceAll(RegExp(r'\D'), '');

    if (cleanValue.length != 11) {
      return 'Phone number must be 11 digits (e.g., 09123456789)';
    }
    if (!cleanValue.startsWith('09')) {
      return 'Phone number must start with 09';
    }
    return null;
  }

  static String? validateBarangay(String? value) {
    if (value == null || value.isEmpty) {
      return 'Barangay selection is required';
    }
    // Fixed: Updated variable name to tagumBarangays
    if (!tagumBarangays.contains(value)) {
      return 'Please select a valid barangay from the list';
    }
    return null;
  }
}
