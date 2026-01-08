import 'package:flutter_test/flutter_test.dart';
import 'package:barangay_link/utils/validators.dart';

void main() {
  group('Validators', () {
    test('validateEmail returns error for empty', () {
      expect(Validators.validateEmail(''), 'Email is required');
    });

    test('validateEmail returns error for invalid format', () {
      expect(
        Validators.validateEmail('invalid'),
        'Please enter a valid email address',
      );
      expect(
        Validators.validateEmail('test@'),
        'Please enter a valid email address',
      );
    });

    test('validateEmail returns null for valid email', () {
      expect(Validators.validateEmail('test@example.com'), null);
    });

    test('validatePassword returns error for short password', () {
      expect(
        Validators.validatePassword('Ab1'),
        'Password must be at least 8 characters long',
      );
    });

    test('validatePassword returns error for missing requirements', () {
      expect(
        Validators.validatePassword('abcdefgh'),
        'Password must contain at least one uppercase letter',
      );
      expect(
        Validators.validatePassword('ABCDEFGH'),
        'Password must contain at least one lowercase letter',
      );
      expect(
        Validators.validatePassword('Abcdefgh'),
        'Password must contain at least one number',
      );
    });

    test('validatePassword returns null for valid password', () {
      expect(Validators.validatePassword('Pass1234'), null);
    });

    test('validateBarangay returns error for empty', () {
      expect(Validators.validateBarangay(''), 'Barangay selection is required');
    });

    test('validateBarangay returns error for invalid barangay', () {
      expect(
        Validators.validateBarangay('Invalid'),
        'Please select a valid barangay from the list',
      );
    });

    test('validateBarangay returns null for valid barangay', () {
      expect(Validators.validateBarangay('Apokon'), null);
    });
  });
}
