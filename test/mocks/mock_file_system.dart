import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

/// Creates a temporary directory for file-based testing
/// Returns the path to the temp directory
Future<Directory> createTestDirectory() async {
  final tempDir = await Directory.systemTemp.createTemp('widget_app_test_');
  return tempDir;
}

/// Cleans up the test directory after tests
Future<void> cleanupTestDirectory(Directory dir) async {
  if (await dir.exists()) {
    await dir.delete(recursive: true);
  }
}

/// A helper class to manage test file operations
class TestFileSystem {
  final Directory testDir;

  TestFileSystem(this.testDir);

  /// Creates a file with content in the test directory
  Future<File> createFile(String fileName, String content) async {
    final file = File('${testDir.path}/$fileName');
    await file.writeAsString(content);
    return file;
  }

  /// Gets the path to a file in the test directory
  String getPath(String fileName) => '${testDir.path}/$fileName';

  /// Reads content from a file in the test directory
  Future<String> readFile(String fileName) async {
    final file = File('${testDir.path}/$fileName');
    return file.readAsString();
  }

  /// Checks if a file exists in the test directory
  Future<bool> fileExists(String fileName) async {
    final file = File('${testDir.path}/$fileName');
    return file.exists();
  }
}

/// Extension to easily create test fixtures
extension TestFixtures on TestFileSystem {
  /// Creates a sample history JSON file
  Future<File> createHistoryFile(List<Map<String, dynamic>> updates) async {
    final content = updates.toString();
    return createFile('user_updates_history.json', content);
  }

  /// Creates a sample last state JSON file
  Future<File> createLastStateFile(Map<String, dynamic> state) async {
    final content = state.toString();
    return createFile('last_widget_state.json', content);
  }
}
