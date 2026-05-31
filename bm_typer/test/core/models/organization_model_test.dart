import 'package:bm_typer/core/models/organization_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('OrganizationModel', () {
    test('parses Firestore Timestamp values for date fields', () {
      final createdAt = DateTime(2026, 4, 19, 10, 30);
      final expiryDate = DateTime(2026, 5, 19, 10, 30);

      final organization = OrganizationModel.fromJson({
        'id': 'org-1',
        'name': 'TechZone',
        'adminEmail': 'admin@example.com',
        'createdAt': Timestamp.fromDate(createdAt),
        'expiryDate': Timestamp.fromDate(expiryDate),
      });

      expect(organization.createdAt, createdAt);
      expect(organization.expiryDate, expiryDate);
    });
  });

  group('OrgMemberModel', () {
    test('parses Firestore Timestamp values for joinedAt', () {
      final joinedAt = DateTime(2026, 4, 19, 9, 15);

      final member = OrgMemberModel.fromJson({
        'id': 'member-1',
        'userId': 'user-1',
        'email': 'member@example.com',
        'name': 'Member One',
        'joinedAt': Timestamp.fromDate(joinedAt),
      });

      expect(member.joinedAt, joinedAt);
    });

    test('falls back safely when joinedAt is missing', () {
      final beforeParse = DateTime.now().subtract(const Duration(seconds: 1));

      final member = OrgMemberModel.fromJson({
        'id': 'member-2',
        'userId': 'user-2',
        'email': 'member2@example.com',
        'name': 'Member Two',
      });

      expect(member.joinedAt.isAfter(beforeParse), isTrue);
    });
  });
}
