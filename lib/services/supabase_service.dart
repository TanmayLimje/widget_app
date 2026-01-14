import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:path_provider/path_provider.dart';

/// Supabase service for real-time sync between devices
///
/// See docs/SUPABASE.md for removal instructions
class SupabaseService {
  // Supabase credentials
  static const String _supabaseUrl = 'https://kqjrlilptldulylnijbr.supabase.co';
  static const String _supabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImtxanJsaWxwdGxkdWx5bG5pamJyIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjcwMjEwODQsImV4cCI6MjA4MjU5NzA4NH0.DzthYx2FEmFrDqBCfOG2zej5tJ-_5fWQ6sbKR4bvH64';

  static SupabaseClient? _client;
  static RealtimeChannel? _channel;

  /// Initialize Supabase client
  static Future<void> initialize() async {
    try {
      await Supabase.initialize(url: _supabaseUrl, anonKey: _supabaseAnonKey);
      _client = Supabase.instance.client;
      debugPrint('Supabase initialized successfully');
    } catch (e) {
      debugPrint('Supabase initialization failed: $e');
    }
  }

  /// Check if Supabase is properly configured
  static bool get isConfigured =>
      _supabaseUrl != 'YOUR_SUPABASE_URL' &&
      _supabaseAnonKey != 'YOUR_ANON_KEY';

  /// Get the Supabase client
  static SupabaseClient? get client => _client;

  /// Sync an update to Supabase
  static Future<void> syncUpdate({
    required String id,
    required String userId,
    required String userName,
    String? text,
    String? localImagePath,
    required String colorHex,
  }) async {
    if (!isConfigured || _client == null) {
      debugPrint('Supabase not configured, skipping sync');
      return;
    }

    try {
      String? imageUrl;

      // Upload image if exists
      if (localImagePath != null && localImagePath.isNotEmpty) {
        imageUrl = await _uploadImage(localImagePath, id);
      }

      // Upsert to database
      await _client!.from('updates').upsert({
        'id': id,
        'user_id': userId,
        'user_name': userName,
        'text': text,
        'image_url': imageUrl,
        'color_hex': colorHex,
        'updated_at': DateTime.now().toIso8601String(),
      });

      debugPrint('Synced update $id to Supabase');
    } catch (e) {
      debugPrint('Failed to sync update: $e');
    }
  }

  /// Upload image to Supabase Storage
  static Future<String?> _uploadImage(String localPath, String updateId) async {
    try {
      final file = File(localPath);
      if (!await file.exists()) return null;

      final fileName = '$updateId.jpg';
      final bytes = await file.readAsBytes();

      await _client!.storage
          .from('update-images')
          .uploadBinary(
            fileName,
            bytes,
            fileOptions: const FileOptions(cacheControl: '3600', upsert: true),
          );

      // Get public URL
      final publicUrl = _client!.storage
          .from('update-images')
          .getPublicUrl(fileName);

      return publicUrl;
    } catch (e) {
      debugPrint('Failed to upload image: $e');
      return null;
    }
  }

  /// Download image from Supabase Storage
  static Future<String?> downloadImage(String imageUrl, String updateId) async {
    try {
      final response = await _client!.storage
          .from('update-images')
          .download('$updateId.jpg');

      // Save to local file
      final appDir = await getApplicationDocumentsDirectory();
      final localPath = '${appDir.path}/remote_$updateId.jpg';
      final file = File(localPath);
      await file.writeAsBytes(response);

      return localPath;
    } catch (e) {
      debugPrint('Failed to download image: $e');
      return null;
    }
  }

  /// Stream real-time updates
  static Stream<List<Map<String, dynamic>>> streamUpdates() {
    if (!isConfigured || _client == null) {
      return const Stream.empty();
    }

    // Create a broadcast stream controller
    final controller = StreamController<List<Map<String, dynamic>>>.broadcast();

    // Subscribe to realtime changes
    _channel = _client!
        .channel('updates_channel')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'updates',
          callback: (payload) async {
            // Fetch all updates when any change occurs
            try {
              final data = await _client!
                  .from('updates')
                  .select()
                  .order('updated_at', ascending: false);
              controller.add(List<Map<String, dynamic>>.from(data));
            } catch (e) {
              debugPrint('Failed to fetch updates: $e');
            }
          },
        )
        .subscribe();

    // Fetch initial data
    _fetchInitialUpdates(controller);

    return controller.stream;
  }

  /// Fetch initial updates
  static Future<void> _fetchInitialUpdates(
    StreamController<List<Map<String, dynamic>>> controller,
  ) async {
    try {
      final data = await _client!
          .from('updates')
          .select()
          .order('updated_at', ascending: false);
      controller.add(List<Map<String, dynamic>>.from(data));
    } catch (e) {
      debugPrint('Failed to fetch initial updates: $e');
    }
  }

  /// Get the latest update for a specific user
  static Future<Map<String, dynamic>?> getLatestUpdate(String userId) async {
    if (!isConfigured || _client == null) return null;

    try {
      final data = await _client!
          .from('updates')
          .select()
          .eq('user_id', userId)
          .order('updated_at', ascending: false)
          .limit(1)
          .maybeSingle();

      return data;
    } catch (e) {
      debugPrint('Failed to get latest update: $e');
      return null;
    }
  }

  /// Delete an update from Supabase
  static Future<void> deleteUpdate(String id) async {
    if (!isConfigured || _client == null) return;

    try {
      await _client!.from('updates').delete().eq('id', id);

      // Also delete image from storage
      try {
        await _client!.storage.from('update-images').remove(['$id.jpg']);
      } catch (_) {
        // Image might not exist
      }

      debugPrint('Deleted update $id from Supabase');
    } catch (e) {
      debugPrint('Failed to delete update: $e');
    }
  }

  /// Dispose and cleanup
  static Future<void> dispose() async {
    await _channel?.unsubscribe();
    _channel = null;
  }
}
