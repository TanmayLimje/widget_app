import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:aantan/update_history_service.dart';

void main() {
  group('UserUpdate', () {
    test('creates with required parameters', () {
      final update = UserUpdate(
        id: 'test-id-123',
        timestamp: DateTime(2024, 1, 15, 10, 30),
        userId: 'user1',
        userName: 'Tanmay',
        colorHex: 'FF6366F1',
      );

      expect(update.id, 'test-id-123');
      expect(update.timestamp, DateTime(2024, 1, 15, 10, 30));
      expect(update.userId, 'user1');
      expect(update.userName, 'Tanmay');
      expect(update.text, isNull);
      expect(update.imagePath, isNull);
      expect(update.colorHex, 'FF6366F1');
    });

    test('creates with all parameters', () {
      final update = UserUpdate(
        id: 'full-update',
        timestamp: DateTime(2024, 1, 15),
        userId: 'user2',
        userName: 'Aanchal',
        text: 'Hello there!',
        imagePath: '/path/to/image.jpg',
        colorHex: 'FF3B82F6',
      );

      expect(update.id, 'full-update');
      expect(update.userId, 'user2');
      expect(update.userName, 'Aanchal');
      expect(update.text, 'Hello there!');
      expect(update.imagePath, '/path/to/image.jpg');
      expect(update.colorHex, 'FF3B82F6');
    });

    group('color getter', () {
      test('converts hex to Color correctly', () {
        final update = UserUpdate(
          id: 'color-test',
          timestamp: DateTime.now(),
          userId: 'user1',
          userName: 'Test',
          colorHex: 'FF6366F1',
        );

        final color = update.color;
        expect(color, isA<Color>());
        expect(color.value, 0xFF6366F1);
      });

      test('handles blue color hex', () {
        final update = UserUpdate(
          id: 'blue-test',
          timestamp: DateTime.now(),
          userId: 'user2',
          userName: 'Test',
          colorHex: 'FF3B82F6',
        );

        expect(update.color.value, 0xFF3B82F6);
      });
    });

    group('toJson', () {
      test('serializes all fields correctly', () {
        final timestamp = DateTime(2024, 1, 15, 12, 0, 0);
        final update = UserUpdate(
          id: 'json-test',
          timestamp: timestamp,
          userId: 'user1',
          userName: 'Tanmay',
          text: 'Test message',
          imagePath: '/test/image.png',
          colorHex: 'FFFF0000',
        );

        final json = update.toJson();

        expect(json['id'], 'json-test');
        expect(json['timestamp'], timestamp.toIso8601String());
        expect(json['userId'], 'user1');
        expect(json['userName'], 'Tanmay');
        expect(json['text'], 'Test message');
        expect(json['imagePath'], '/test/image.png');
        expect(json['colorHex'], 'FFFF0000');
      });

      test('serializes null optional fields', () {
        final update = UserUpdate(
          id: 'null-test',
          timestamp: DateTime.now(),
          userId: 'user1',
          userName: 'Test',
          colorHex: 'FF000000',
        );

        final json = update.toJson();

        expect(json['text'], isNull);
        expect(json['imagePath'], isNull);
      });
    });

    group('fromJson', () {
      test('deserializes all fields correctly', () {
        final json = {
          'id': 'from-json-test',
          'timestamp': '2024-01-15T14:30:00.000',
          'userId': 'user2',
          'userName': 'Aanchal',
          'text': 'Deserialized text',
          'imagePath': '/deserialized/path.jpg',
          'colorHex': 'FF00FF00',
        };

        final update = UserUpdate.fromJson(json);

        expect(update.id, 'from-json-test');
        expect(update.timestamp, DateTime(2024, 1, 15, 14, 30));
        expect(update.userId, 'user2');
        expect(update.userName, 'Aanchal');
        expect(update.text, 'Deserialized text');
        expect(update.imagePath, '/deserialized/path.jpg');
        expect(update.colorHex, 'FF00FF00');
      });

      test('deserializes null optional fields', () {
        final json = {
          'id': 'null-from-json',
          'timestamp': '2024-01-15T10:00:00.000',
          'userId': 'user1',
          'userName': 'Test',
          'text': null,
          'imagePath': null,
          'colorHex': 'FF123456',
        };

        final update = UserUpdate.fromJson(json);

        expect(update.text, isNull);
        expect(update.imagePath, isNull);
      });
    });

    group('round-trip serialization', () {
      test('toJson then fromJson preserves data', () {
        final original = UserUpdate(
          id: 'round-trip',
          timestamp: DateTime(2024, 6, 15, 9, 45, 30),
          userId: 'user1',
          userName: 'Tanmay',
          text: 'Round trip test',
          imagePath: '/round/trip.png',
          colorHex: 'FFABCDEF',
        );

        final json = original.toJson();
        final restored = UserUpdate.fromJson(json);

        expect(restored.id, original.id);
        expect(restored.timestamp, original.timestamp);
        expect(restored.userId, original.userId);
        expect(restored.userName, original.userName);
        expect(restored.text, original.text);
        expect(restored.imagePath, original.imagePath);
        expect(restored.colorHex, original.colorHex);
      });

      test('round-trip with null optional fields', () {
        final original = UserUpdate(
          id: 'null-round-trip',
          timestamp: DateTime(2024, 1, 1),
          userId: 'user2',
          userName: 'Test',
          colorHex: 'FF000000',
        );

        final json = original.toJson();
        final restored = UserUpdate.fromJson(json);

        expect(restored.text, isNull);
        expect(restored.imagePath, isNull);
      });
    });

    group('fromSnapshot (backward compatibility)', () {
      test('converts snapshot with both users having content', () {
        final snapshot = {
          'id': 'snapshot-id',
          'timestamp': '2024-01-15T10:00:00.000',
          'user1Text': 'User 1 text',
          'user1ImagePath': '/user1/image.jpg',
          'user1ColorHex': 'FF6366F1',
          'user2Text': 'User 2 text',
          'user2ImagePath': '/user2/image.jpg',
          'user2ColorHex': 'FF3B82F6',
        };

        final updates = UserUpdate.fromSnapshot(snapshot);

        expect(updates.length, 2);

        final user1Update = updates.firstWhere((u) => u.userId == 'user1');
        expect(user1Update.id, 'snapshot-id_user1');
        expect(user1Update.userName, 'User 1');
        expect(user1Update.text, 'User 1 text');
        expect(user1Update.imagePath, '/user1/image.jpg');
        expect(user1Update.colorHex, 'FF6366F1');

        final user2Update = updates.firstWhere((u) => u.userId == 'user2');
        expect(user2Update.id, 'snapshot-id_user2');
        expect(user2Update.userName, 'User 2');
        expect(user2Update.text, 'User 2 text');
      });

      test('converts snapshot with only user1 having content', () {
        final snapshot = {
          'id': 'single-user',
          'timestamp': '2024-01-15T10:00:00.000',
          'user1Text': 'Only user 1',
          'user1ImagePath': null,
          'user1ColorHex': 'FF6366F1',
          'user2Text': null,
          'user2ImagePath': null,
          'user2ColorHex': 'FF3B82F6',
        };

        final updates = UserUpdate.fromSnapshot(snapshot);

        expect(updates.length, 1);
        expect(updates.first.userId, 'user1');
        expect(updates.first.text, 'Only user 1');
      });

      test('converts snapshot with only image (no text)', () {
        final snapshot = {
          'id': 'image-only',
          'timestamp': '2024-01-15T10:00:00.000',
          'user1Text': null,
          'user1ImagePath': '/user1/image.jpg',
          'user1ColorHex': 'FF6366F1',
          'user2Text': null,
          'user2ImagePath': null,
          'user2ColorHex': 'FF3B82F6',
        };

        final updates = UserUpdate.fromSnapshot(snapshot);

        expect(updates.length, 1);
        expect(updates.first.text, isNull);
        expect(updates.first.imagePath, '/user1/image.jpg');
      });

      test('returns empty list when no content for either user', () {
        final snapshot = {
          'id': 'empty',
          'timestamp': '2024-01-15T10:00:00.000',
          'user1Text': null,
          'user1ImagePath': null,
          'user1ColorHex': 'FF6366F1',
          'user2Text': null,
          'user2ImagePath': null,
          'user2ColorHex': 'FF3B82F6',
        };

        final updates = UserUpdate.fromSnapshot(snapshot);

        expect(updates, isEmpty);
      });

      test('user2 timestamp is slightly after user1', () {
        final snapshot = {
          'id': 'timing-test',
          'timestamp': '2024-01-15T10:00:00.000',
          'user1Text': 'User 1',
          'user1ImagePath': null,
          'user1ColorHex': 'FF6366F1',
          'user2Text': 'User 2',
          'user2ImagePath': null,
          'user2ColorHex': 'FF3B82F6',
        };

        final updates = UserUpdate.fromSnapshot(snapshot);
        final user1 = updates.firstWhere((u) => u.userId == 'user1');
        final user2 = updates.firstWhere((u) => u.userId == 'user2');

        expect(user2.timestamp.isAfter(user1.timestamp), isTrue);
        expect(user2.timestamp.difference(user1.timestamp).inMilliseconds, 1);
      });
    });
  });
}
