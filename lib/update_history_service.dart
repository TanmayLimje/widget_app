import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'services/supabase_service.dart'; // Supabase sync - see docs/SUPABASE.md

/// Model class for a single user's update
class UserUpdate {
  final String id;
  final DateTime timestamp;
  final String userId; // Which user: 'user1' or 'user2'
  final String userName; // Display name: 'User 1' or 'User 2'
  final String? text;
  final String? imagePath;
  final String colorHex;

  UserUpdate({
    required this.id,
    required this.timestamp,
    required this.userId,
    required this.userName,
    this.text,
    this.imagePath,
    required this.colorHex,
  });

  // Computed property for color
  Color get color => Color(int.parse(colorHex, radix: 16));

  Map<String, dynamic> toJson() => {
    'id': id,
    'timestamp': timestamp.toIso8601String(),
    'userId': userId,
    'userName': userName,
    'text': text,
    'imagePath': imagePath,
    'colorHex': colorHex,
  };

  factory UserUpdate.fromJson(Map<String, dynamic> json) {
    return UserUpdate(
      id: json['id'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      userId: json['userId'] as String,
      userName: json['userName'] as String,
      text: json['text'] as String?,
      imagePath: json['imagePath'] as String?,
      colorHex: json['colorHex'] as String,
    );
  }

  // For backwards compatibility - convert old snapshot to user updates
  static List<UserUpdate> fromSnapshot(Map<String, dynamic> snapshot) {
    final timestamp = DateTime.parse(snapshot['timestamp'] as String);
    final baseId = snapshot['id'] as String;

    final updates = <UserUpdate>[];

    // Only add if there's content (image or text)
    final user1HasContent =
        (snapshot['user1ImagePath'] as String?)?.isNotEmpty == true ||
        (snapshot['user1Text'] as String?)?.isNotEmpty == true;
    final user2HasContent =
        (snapshot['user2ImagePath'] as String?)?.isNotEmpty == true ||
        (snapshot['user2Text'] as String?)?.isNotEmpty == true;

    if (user1HasContent) {
      updates.add(
        UserUpdate(
          id: '${baseId}_user1',
          timestamp: timestamp,
          userId: 'user1',
          userName: 'User 1',
          text: snapshot['user1Text'] as String?,
          imagePath: snapshot['user1ImagePath'] as String?,
          colorHex: snapshot['user1ColorHex'] as String,
        ),
      );
    }

    if (user2HasContent) {
      updates.add(
        UserUpdate(
          id: '${baseId}_user2',
          timestamp: timestamp.add(
            const Duration(milliseconds: 1),
          ), // Slight offset for ordering
          userId: 'user2',
          userName: 'User 2',
          text: snapshot['user2Text'] as String?,
          imagePath: snapshot['user2ImagePath'] as String?,
          colorHex: snapshot['user2ColorHex'] as String,
        ),
      );
    }

    return updates;
  }
}

/// Tracks the last known state for detecting changes
class _UserState {
  final String? text;
  final String? imagePath;
  final String colorHex;

  _UserState({this.text, this.imagePath, required this.colorHex});

  bool hasChanged(_UserState other) {
    return text != other.text ||
        imagePath != other.imagePath ||
        colorHex != other.colorHex;
  }
}

/// Service to manage update history persistence
class UpdateHistoryService {
  static const String _historyFileName = 'user_updates_history.json';
  static const String _lastStateFileName = 'last_widget_state.json';

  /// Get the history file path
  static Future<File> _getHistoryFile() async {
    final appDir = await getApplicationDocumentsDirectory();
    return File('${appDir.path}/$_historyFileName');
  }

  /// Get the last state file path
  static Future<File> _getLastStateFile() async {
    final appDir = await getApplicationDocumentsDirectory();
    return File('${appDir.path}/$_lastStateFileName');
  }

  /// Load the last known state
  static Future<Map<String, _UserState>> _loadLastState() async {
    try {
      final file = await _getLastStateFile();
      if (!await file.exists()) {
        return {};
      }
      final contents = await file.readAsString();
      final json = jsonDecode(contents) as Map<String, dynamic>;

      return {
        'user1': _UserState(
          text: json['user1_text'] as String?,
          imagePath: json['user1_image'] as String?,
          colorHex: json['user1_color'] as String? ?? 'FF6366F1',
        ),
        'user2': _UserState(
          text: json['user2_text'] as String?,
          imagePath: json['user2_image'] as String?,
          colorHex: json['user2_color'] as String? ?? 'FF3B82F6',
        ),
      };
    } catch (e) {
      debugPrint('Error loading last state: $e');
      return {};
    }
  }

  /// Save the current state as last known state
  static Future<void> _saveLastState({
    required String? user1Text,
    required String? user1ImagePath,
    required String user1ColorHex,
    required String? user2Text,
    required String? user2ImagePath,
    required String user2ColorHex,
  }) async {
    try {
      final file = await _getLastStateFile();
      final json = {
        'user1_text': user1Text,
        'user1_image': user1ImagePath,
        'user1_color': user1ColorHex,
        'user2_text': user2Text,
        'user2_image': user2ImagePath,
        'user2_color': user2ColorHex,
      };
      await file.writeAsString(jsonEncode(json));
    } catch (e) {
      debugPrint('Error saving last state: $e');
    }
  }

  /// Load all saved updates from history
  static Future<List<UserUpdate>> loadHistory() async {
    try {
      final file = await _getHistoryFile();

      if (!await file.exists()) {
        return [];
      }

      final contents = await file.readAsString();
      final List<dynamic> jsonList = json.decode(contents);

      return jsonList
          .map((item) => UserUpdate.fromJson(item as Map<String, dynamic>))
          .toList()
        ..sort((a, b) => b.timestamp.compareTo(a.timestamp)); // Newest first
    } catch (e) {
      debugPrint('Error loading update history: $e');
      return [];
    }
  }

  /// Save updates, detecting which users have changed
  static Future<void> saveUpdate({
    required String? user1Text,
    required String? user1ImagePath,
    required String user1ColorHex,
    required String? user2Text,
    required String? user2ImagePath,
    required String user2ColorHex,
  }) async {
    try {
      final lastState = await _loadLastState();
      final history = await loadHistory();
      final now = DateTime.now();

      final currentUser1 = _UserState(
        text: user1Text,
        imagePath: user1ImagePath,
        colorHex: user1ColorHex,
      );

      final currentUser2 = _UserState(
        text: user2Text,
        imagePath: user2ImagePath,
        colorHex: user2ColorHex,
      );

      // Check if User 1 (Tanmay) has changed
      final lastUser1 = lastState['user1'];
      final user1Changed =
          lastUser1 == null || currentUser1.hasChanged(lastUser1);
      if (user1Changed) {
        // Only add if there's actual content
        if (user1ImagePath?.isNotEmpty == true ||
            user1Text?.isNotEmpty == true) {
          final updateId = '${now.millisecondsSinceEpoch}_tanmay';
          history.insert(
            0,
            UserUpdate(
              id: updateId,
              timestamp: now,
              userId: 'user1',
              userName: 'Tanmay',
              text: user1Text,
              imagePath: user1ImagePath,
              colorHex: user1ColorHex,
            ),
          );

          // Sync ONLY Tanmay's update to Supabase
          await SupabaseService.syncUpdate(
            id: updateId,
            userId: 'tanmay',
            userName: 'Tanmay',
            text: user1Text,
            localImagePath: user1ImagePath,
            colorHex: user1ColorHex,
          );
        }
      }

      // Check if User 2 (Aanchal) has changed
      final lastUser2 = lastState['user2'];
      final user2Changed =
          lastUser2 == null || currentUser2.hasChanged(lastUser2);
      if (user2Changed) {
        // Only add if there's actual content
        if (user2ImagePath?.isNotEmpty == true ||
            user2Text?.isNotEmpty == true) {
          final updateId = '${now.millisecondsSinceEpoch}_aanchal';
          history.insert(
            0,
            UserUpdate(
              id: updateId,
              timestamp: now.add(const Duration(milliseconds: 1)),
              userId: 'user2',
              userName: 'Aanchal',
              text: user2Text,
              imagePath: user2ImagePath,
              colorHex: user2ColorHex,
            ),
          );

          // Sync ONLY Aanchal's update to Supabase
          await SupabaseService.syncUpdate(
            id: updateId,
            userId: 'aanchal',
            userName: 'Aanchal',
            text: user2Text,
            localImagePath: user2ImagePath,
            colorHex: user2ColorHex,
          );
        }
      }

      // Keep only last 100 updates
      final trimmedHistory = history.take(100).toList();

      // Save history
      final file = await _getHistoryFile();
      final jsonString = json.encode(
        trimmedHistory.map((u) => u.toJson()).toList(),
      );
      await file.writeAsString(jsonString);

      // Save current state as last state
      await _saveLastState(
        user1Text: user1Text,
        user1ImagePath: user1ImagePath,
        user1ColorHex: user1ColorHex,
        user2Text: user2Text,
        user2ImagePath: user2ImagePath,
        user2ColorHex: user2ColorHex,
      );
    } catch (e) {
      debugPrint('Error saving update to history: $e');
    }
  }

  /// Save only the current user's update (prevents duplicate saves)
  /// This should be used instead of saveUpdate() when only one user is updating
  static Future<void> saveUserUpdate({
    required int userNumber, // 1 for Tanmay, 2 for Aanchal
    required String? text,
    required String? imagePath,
    required String colorHex,
  }) async {
    try {
      // Only save if there's actual content
      if (imagePath?.isNotEmpty != true && text?.isNotEmpty != true) {
        debugPrint('No content to save, skipping');
        return;
      }

      final history = await loadHistory();
      final now = DateTime.now();

      final userId = userNumber == 1 ? 'user1' : 'user2';
      final userName = userNumber == 1 ? 'Tanmay' : 'Aanchal';
      final supabaseUserId = userNumber == 1 ? 'tanmay' : 'aanchal';
      final updateId = '${now.millisecondsSinceEpoch}_$supabaseUserId';

      // Add to history
      history.insert(
        0,
        UserUpdate(
          id: updateId,
          timestamp: now,
          userId: userId,
          userName: userName,
          text: text,
          imagePath: imagePath,
          colorHex: colorHex,
        ),
      );

      // Sync to Supabase
      await SupabaseService.syncUpdate(
        id: updateId,
        userId: supabaseUserId,
        userName: userName,
        text: text,
        localImagePath: imagePath,
        colorHex: colorHex,
      );

      // Keep only last 100 updates
      final trimmedHistory = history.take(100).toList();

      // Save history
      final file = await _getHistoryFile();
      final jsonString = json.encode(
        trimmedHistory.map((u) => u.toJson()).toList(),
      );
      await file.writeAsString(jsonString);

      // Update only the current user's state in lastState
      await _updateUserLastState(
        userNumber: userNumber,
        text: text,
        imagePath: imagePath,
        colorHex: colorHex,
      );

      debugPrint('Saved update for $userName: $updateId');
    } catch (e) {
      debugPrint('Error saving user update to history: $e');
    }
  }

  /// Update only one user's state in lastState file
  static Future<void> _updateUserLastState({
    required int userNumber,
    required String? text,
    required String? imagePath,
    required String colorHex,
  }) async {
    try {
      final file = await _getLastStateFile();
      Map<String, dynamic> json = {};

      // Load existing state
      if (await file.exists()) {
        final contents = await file.readAsString();
        json = jsonDecode(contents) as Map<String, dynamic>;
      }

      // Update only the specified user
      if (userNumber == 1) {
        json['user1_text'] = text;
        json['user1_image'] = imagePath;
        json['user1_color'] = colorHex;
      } else {
        json['user2_text'] = text;
        json['user2_image'] = imagePath;
        json['user2_color'] = colorHex;
      }

      await file.writeAsString(jsonEncode(json));
    } catch (e) {
      debugPrint('Error updating user last state: $e');
    }
  }

  /// Save a received real-time update to lastState (prevents re-saving)
  /// Call this when receiving an update from the other user via real-time sync
  static Future<void> saveReceivedUpdate({
    required int otherUserNumber, // The OTHER user's number (1 or 2)
    required String? text,
    required String? imagePath,
    required String colorHex,
  }) async {
    await _updateUserLastState(
      userNumber: otherUserNumber,
      text: text,
      imagePath: imagePath,
      colorHex: colorHex,
    );
    debugPrint('Saved received update for user $otherUserNumber to lastState');
  }

  /// Delete a specific update from history
  static Future<void> deleteUpdate(String id) async {
    try {
      final history = await loadHistory();
      history.removeWhere((update) => update.id == id);

      final file = await _getHistoryFile();
      final jsonString = json.encode(history.map((u) => u.toJson()).toList());
      await file.writeAsString(jsonString);
    } catch (e) {
      debugPrint('Error deleting update from history: $e');
    }
  }

  /// Clear all history
  static Future<void> clearHistory() async {
    try {
      final file = await _getHistoryFile();
      if (await file.exists()) {
        await file.delete();
      }
      final stateFile = await _getLastStateFile();
      if (await stateFile.exists()) {
        await stateFile.delete();
      }
    } catch (e) {
      debugPrint('Error clearing history: $e');
    }
  }
}
