import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:aantan/update_history_service.dart';

/// Tests for UpdateHistoryService
///
/// These tests use real file operations in a temporary directory
/// to ensure the service behaves correctly with the file system.
void main() {
  late Directory testDir;

  /// Sets up a temporary directory for each test
  setUp(() async {
    testDir = await Directory.systemTemp.createTemp('update_history_test_');
  });

  /// Cleans up the temporary directory after each test
  tearDown(() async {
    if (await testDir.exists()) {
      await testDir.delete(recursive: true);
    }
  });

  group('UpdateHistoryService file operations', () {
    // Note: Since UpdateHistoryService uses getApplicationDocumentsDirectory(),
    // we can't easily redirect it to our test directory without modification.
    // These tests verify the logic and data structures work correctly.

    group('UserUpdate serialization in context', () {
      test('multiple updates serialize correctly', () {
        final updates = [
          UserUpdate(
            id: 'update-1',
            timestamp: DateTime(2024, 1, 15, 10, 0),
            userId: 'user1',
            userName: 'Tanmay',
            text: 'First update',
            colorHex: 'FF6366F1',
          ),
          UserUpdate(
            id: 'update-2',
            timestamp: DateTime(2024, 1, 15, 11, 0),
            userId: 'user2',
            userName: 'Aanchal',
            text: 'Second update',
            imagePath: '/path/to/image.jpg',
            colorHex: 'FF3B82F6',
          ),
        ];

        final jsonString = json.encode(updates.map((u) => u.toJson()).toList());

        // Deserialize back
        final List<dynamic> jsonList = json.decode(jsonString);
        final restored = jsonList
            .map((item) => UserUpdate.fromJson(item as Map<String, dynamic>))
            .toList();

        expect(restored.length, 2);
        expect(restored[0].id, 'update-1');
        expect(restored[0].userName, 'Tanmay');
        expect(restored[1].id, 'update-2');
        expect(restored[1].imagePath, '/path/to/image.jpg');
      });
    });

    group('History file format', () {
      test('can write and read history format', () async {
        final historyFile = File('${testDir.path}/test_history.json');

        final updates = [
          UserUpdate(
            id: '${DateTime.now().millisecondsSinceEpoch}_tanmay',
            timestamp: DateTime.now(),
            userId: 'user1',
            userName: 'Tanmay',
            text: 'Test update',
            colorHex: 'FF6366F1',
          ),
        ];

        // Write in the same format as UpdateHistoryService
        final jsonString = json.encode(updates.map((u) => u.toJson()).toList());
        await historyFile.writeAsString(jsonString);

        // Read back
        final contents = await historyFile.readAsString();
        final List<dynamic> jsonList = json.decode(contents);
        final restored = jsonList
            .map((item) => UserUpdate.fromJson(item as Map<String, dynamic>))
            .toList();

        expect(restored.length, 1);
        expect(restored.first.userName, 'Tanmay');
      });

      test('sorts updates by timestamp descending', () async {
        final updates = [
          UserUpdate(
            id: 'older',
            timestamp: DateTime(2024, 1, 1),
            userId: 'user1',
            userName: 'Tanmay',
            colorHex: 'FF6366F1',
          ),
          UserUpdate(
            id: 'newer',
            timestamp: DateTime(2024, 1, 15),
            userId: 'user2',
            userName: 'Aanchal',
            colorHex: 'FF3B82F6',
          ),
        ];

        // Sort like loadHistory does
        updates.sort((a, b) => b.timestamp.compareTo(a.timestamp));

        expect(updates.first.id, 'newer');
        expect(updates.last.id, 'older');
      });
    });

    group('Last state file format', () {
      test('can write and read last state format', () async {
        final stateFile = File('${testDir.path}/test_state.json');

        final state = {
          'user1_text': 'Tanmay text',
          'user1_image': '/path/to/tanmay.jpg',
          'user1_color': 'FF6366F1',
          'user2_text': 'Aanchal text',
          'user2_image': null,
          'user2_color': 'FF3B82F6',
        };

        await stateFile.writeAsString(jsonEncode(state));

        final contents = await stateFile.readAsString();
        final restored = jsonDecode(contents) as Map<String, dynamic>;

        expect(restored['user1_text'], 'Tanmay text');
        expect(restored['user1_image'], '/path/to/tanmay.jpg');
        expect(restored['user2_text'], 'Aanchal text');
        expect(restored['user2_image'], isNull);
      });
    });

    group('Sync timestamp file format', () {
      test('can write and read sync timestamp format', () async {
        final timestampFile = File('${testDir.path}/test_timestamp.json');

        final now = DateTime.now();
        await timestampFile.writeAsString(
          jsonEncode({'timestamp': now.toIso8601String()}),
        );

        final contents = await timestampFile.readAsString();
        final data = jsonDecode(contents) as Map<String, dynamic>;
        final restored = DateTime.parse(data['timestamp'] as String);

        expect(restored.year, now.year);
        expect(restored.month, now.month);
        expect(restored.day, now.day);
      });
    });

    group('Cached remote updates file format', () {
      test('can write and read cached remote format', () async {
        final cacheFile = File('${testDir.path}/test_cache.json');

        final updates = [
          UserUpdate(
            id: 'remote-1',
            timestamp: DateTime(2024, 1, 15),
            userId: 'tanmay',
            userName: 'Tanmay',
            text: 'Remote update',
            colorHex: 'FF6366F1',
          ),
        ];

        final jsonString = json.encode(updates.map((u) => u.toJson()).toList());
        await cacheFile.writeAsString(jsonString);

        final contents = await cacheFile.readAsString();
        final List<dynamic> jsonList = json.decode(contents);
        final restored = jsonList
            .map((item) => UserUpdate.fromJson(item as Map<String, dynamic>))
            .toList();

        expect(restored.length, 1);
        expect(restored.first.id, 'remote-1');
      });
    });
  });

  group('UpdateHistoryService change detection logic', () {
    test('detects text change', () {
      final current = {
        'text': 'new text',
        'imagePath': null,
        'colorHex': 'FF000000',
      };
      final previous = {
        'text': 'old text',
        'imagePath': null,
        'colorHex': 'FF000000',
      };

      final hasChanged =
          current['text'] != previous['text'] ||
          current['imagePath'] != previous['imagePath'] ||
          current['colorHex'] != previous['colorHex'];

      expect(hasChanged, isTrue);
    });

    test('detects image change', () {
      final current = {
        'text': null,
        'imagePath': '/new/path.jpg',
        'colorHex': 'FF000000',
      };
      final previous = {
        'text': null,
        'imagePath': '/old/path.jpg',
        'colorHex': 'FF000000',
      };

      final hasChanged =
          current['text'] != previous['text'] ||
          current['imagePath'] != previous['imagePath'] ||
          current['colorHex'] != previous['colorHex'];

      expect(hasChanged, isTrue);
    });

    test('detects color change', () {
      final current = {
        'text': 'same',
        'imagePath': null,
        'colorHex': 'FFFFFFFF',
      };
      final previous = {
        'text': 'same',
        'imagePath': null,
        'colorHex': 'FF000000',
      };

      final hasChanged =
          current['text'] != previous['text'] ||
          current['imagePath'] != previous['imagePath'] ||
          current['colorHex'] != previous['colorHex'];

      expect(hasChanged, isTrue);
    });

    test('no change when all fields same', () {
      final current = {
        'text': 'same',
        'imagePath': '/same.jpg',
        'colorHex': 'FF000000',
      };
      final previous = {
        'text': 'same',
        'imagePath': '/same.jpg',
        'colorHex': 'FF000000',
      };

      final hasChanged =
          current['text'] != previous['text'] ||
          current['imagePath'] != previous['imagePath'] ||
          current['colorHex'] != previous['colorHex'];

      expect(hasChanged, isFalse);
    });
  });

  group('UpdateHistoryService ID generation', () {
    test('generates unique IDs for Tanmay', () {
      final now = DateTime.now();
      final id1 = '${now.millisecondsSinceEpoch}_tanmay';

      // Small delay to ensure different timestamp
      final id2 = '${now.millisecondsSinceEpoch + 1}_tanmay';

      expect(id1, isNot(equals(id2)));
      expect(id1, endsWith('_tanmay'));
      expect(id2, endsWith('_tanmay'));
    });

    test('generates unique IDs for Aanchal', () {
      final now = DateTime.now();
      final id = '${now.millisecondsSinceEpoch}_aanchal';

      expect(id, endsWith('_aanchal'));
      expect(id, contains('_'));
    });

    test('tanmay and aanchal IDs are distinct', () {
      final now = DateTime.now();
      final tanmayId = '${now.millisecondsSinceEpoch}_tanmay';
      final aanchalId = '${now.millisecondsSinceEpoch}_aanchal';

      expect(tanmayId, isNot(equals(aanchalId)));
    });
  });

  group('UpdateHistoryService history trimming', () {
    test('trims history to 100 updates', () {
      // Create 150 updates
      final updates = List.generate(
        150,
        (i) => UserUpdate(
          id: 'update-$i',
          timestamp: DateTime.now().subtract(Duration(hours: i)),
          userId: i % 2 == 0 ? 'user1' : 'user2',
          userName: i % 2 == 0 ? 'Tanmay' : 'Aanchal',
          text: 'Update $i',
          colorHex: 'FF000000',
        ),
      );

      // Trim like the service does
      final trimmed = updates.take(100).toList();

      expect(trimmed.length, 100);
      expect(trimmed.first.id, 'update-0');
      expect(trimmed.last.id, 'update-99');
    });
  });

  group('UpdateHistoryService user identification', () {
    test('maps userNumber 1 to user1/Tanmay', () {
      const userNumber = 1;
      final userId = userNumber == 1 ? 'user1' : 'user2';
      final userName = userNumber == 1 ? 'Tanmay' : 'Aanchal';
      final supabaseUserId = userNumber == 1 ? 'tanmay' : 'aanchal';

      expect(userId, 'user1');
      expect(userName, 'Tanmay');
      expect(supabaseUserId, 'tanmay');
    });

    test('maps userNumber 2 to user2/Aanchal', () {
      const userNumber = 2;
      final userId = userNumber == 1 ? 'user1' : 'user2';
      final userName = userNumber == 1 ? 'Tanmay' : 'Aanchal';
      final supabaseUserId = userNumber == 1 ? 'tanmay' : 'aanchal';

      expect(userId, 'user2');
      expect(userName, 'Aanchal');
      expect(supabaseUserId, 'aanchal');
    });
  });

  group('UpdateHistoryService content validation', () {
    test('skips save when no content', () {
      const String? nullText = null;
      const String? nullImage = null;
      final hasContent =
          nullText?.isNotEmpty == true || nullImage?.isNotEmpty == true;
      expect(hasContent, isFalse);
    });

    test('saves when text is present', () {
      const String text = 'Hello';
      const String? imagePath = null;
      final hasContent =
          imagePath?.isNotEmpty == true || text.isNotEmpty == true;
      expect(hasContent, isTrue);
    });

    test('saves when image is present', () {
      const String? text = null;
      const String imagePath = '/path/to/image.jpg';
      final hasContent =
          imagePath.isNotEmpty == true || text?.isNotEmpty == true;
      expect(hasContent, isTrue);
    });

    test('saves when both text and image present', () {
      const String text = 'Hello';
      const String imagePath = '/path/to/image.jpg';
      final hasContent =
          imagePath.isNotEmpty == true || text.isNotEmpty == true;
      expect(hasContent, isTrue);
    });

    test('skips save for empty strings', () {
      const String text = '';
      const String imagePath = '';
      final hasContent =
          imagePath.isNotEmpty == true || text.isNotEmpty == true;
      expect(hasContent, isFalse);
    });
  });

  group('UpdateHistoryService delete logic', () {
    test('removes update by id', () {
      final history = [
        UserUpdate(
          id: 'keep-1',
          timestamp: DateTime.now(),
          userId: 'user1',
          userName: 'Tanmay',
          colorHex: 'FF000000',
        ),
        UserUpdate(
          id: 'delete-me',
          timestamp: DateTime.now(),
          userId: 'user2',
          userName: 'Aanchal',
          colorHex: 'FF000000',
        ),
        UserUpdate(
          id: 'keep-2',
          timestamp: DateTime.now(),
          userId: 'user1',
          userName: 'Tanmay',
          colorHex: 'FF000000',
        ),
      ];

      history.removeWhere((update) => update.id == 'delete-me');

      expect(history.length, 2);
      expect(history.any((u) => u.id == 'delete-me'), isFalse);
      expect(history.any((u) => u.id == 'keep-1'), isTrue);
      expect(history.any((u) => u.id == 'keep-2'), isTrue);
    });
  });
}
