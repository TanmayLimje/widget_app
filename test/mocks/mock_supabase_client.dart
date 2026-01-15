import 'package:mockito/annotations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Generates mock classes for Supabase testing
/// Run `flutter pub run build_runner build` to generate mocks
@GenerateMocks([
  SupabaseClient,
  SupabaseStorageClient,
  StorageFileApi,
  SupabaseQueryBuilder,
  PostgrestFilterBuilder,
  PostgrestTransformBuilder,
  RealtimeChannel,
])
void main() {}
