import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_application_1/models/user.dart';

void main() {
  group('UserModel', () {
    test('isAdmin returns true when role is admin', () {
      final user = UserModel(
        uid: '123',
        name: 'Test',
        email: 'test@test.com',
        barangay: 'Apokon',
        contactNumber: '09123456789',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        role: 'admin',
      );
      expect(user.isAdmin, true);
    });

    test('isAdmin returns false when role is user', () {
      final user = UserModel(
        uid: '123',
        name: 'Test',
        email: 'test@test.com',
        barangay: 'Apokon',
        contactNumber: '09123456789',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        role: 'user',
      );
      expect(user.isAdmin, false);
    });

    test('canModerateBarangay returns true for admin', () {
      final user = UserModel(
        uid: '123',
        name: 'Test',
        email: 'test@test.com',
        barangay: 'Apokon',
        contactNumber: '09123456789',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        role: 'admin',
      );
      expect(user.canModerateBarangay('Madaum'), true);
    });

    test('canModerateBarangay returns false for non-admin', () {
      final user = UserModel(
        uid: '123',
        name: 'Test',
        email: 'test@test.com',
        barangay: 'Apokon',
        contactNumber: '09123456789',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        role: 'user',
      );
      expect(user.canModerateBarangay('Apokon'), false);
    });

    test('toMap serialization works', () {
      final now = DateTime.now();
      final user = UserModel(
        uid: '123',
        name: 'Test User',
        email: 'test@test.com',
        barangay: 'Apokon',
        contactNumber: '09123456789',
        createdAt: now,
        updatedAt: now,
        role: 'user',
      );

      final map = user.toMap();
      expect(map['uid'], '123');
      expect(map['name'], 'Test User');
      expect(map['email'], 'test@test.com');
      expect(map['barangay'], 'Apokon');
      expect(map['role'], 'user');
      expect(map['isActive'], true);
      expect(map['createdAt'], isA<Timestamp>());
    });

    test('fromMap serialization works', () {
      final now = Timestamp.now();
      final map = {
        'name': 'Test User',
        'email': 'test@test.com',
        'barangay': 'Apokon',
        'role': 'user',
        'contactNumber': '09123456789',
        'createdAt': now,
        'updatedAt': now,
        'isActive': true,
        'isBanned': false,
      };

      final user = UserModel.fromMap(map, '123');
      expect(user.uid, '123');
      expect(user.name, 'Test User');
      expect(user.email, 'test@test.com');
      expect(user.barangay, 'Apokon');
      expect(user.createdAt, now.toDate());
    });
  });
}
