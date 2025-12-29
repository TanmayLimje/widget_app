import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

/// Model class for an update entry
class UpdateEntry {
  final String userId;
  final String userName;
  final String? text;
  final String? imagePath;
  final Color color;
  final DateTime timestamp;

  const UpdateEntry({
    required this.userId,
    required this.userName,
    this.text,
    this.imagePath,
    required this.color,
    required this.timestamp,
  });
}

class PastUpdatesPage extends StatefulWidget {
  const PastUpdatesPage({super.key});

  @override
  State<PastUpdatesPage> createState() => _PastUpdatesPageState();
}

class _PastUpdatesPageState extends State<PastUpdatesPage> {
  List<UpdateEntry> _updates = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPastUpdates();
  }

  Future<void> _loadPastUpdates() async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final files = appDir.listSync();

      final List<UpdateEntry> updates = [];

      // Find all update images and create entries
      for (final file in files) {
        if (file is File && file.path.contains('_update_')) {
          final fileName = file.path.split(Platform.pathSeparator).last;

          // Parse filename: user1_update_timestamp.jpg or user2_update_timestamp.jpg
          final isUser1 = fileName.startsWith('user1');
          final isUser2 = fileName.startsWith('user2');

          if (isUser1 || isUser2) {
            // Extract timestamp from filename
            final timestampMatch = RegExp(
              r'_update_(\d+)',
            ).firstMatch(fileName);
            final timestamp = timestampMatch != null
                ? DateTime.fromMillisecondsSinceEpoch(
                    int.parse(timestampMatch.group(1)!),
                  )
                : DateTime.now();

            updates.add(
              UpdateEntry(
                userId: isUser1 ? 'user1' : 'user2',
                userName: isUser1 ? 'User 1' : 'User 2',
                imagePath: file.path,
                color: isUser1
                    ? const Color(0xFF6366F1) // Purple for User 1
                    : const Color(0xFF3B82F6), // Blue for User 2
                timestamp: timestamp,
              ),
            );
          }
        }
      }

      // Sort by timestamp (newest first)
      updates.sort((a, b) => b.timestamp.compareTo(a.timestamp));

      setState(() {
        _updates = updates;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading past updates: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              colorScheme.primary.withOpacity(0.1),
              colorScheme.secondary.withOpacity(0.05),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(
                        Icons.arrow_back_rounded,
                        color: colorScheme.primary,
                      ),
                      style: IconButton.styleFrom(
                        backgroundColor: colorScheme.primaryContainer,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Past Updates',
                            style: Theme.of(context).textTheme.headlineSmall
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: colorScheme.primary,
                                ),
                          ),
                          Text(
                            '${_updates.length} updates',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  color: colorScheme.onSurface.withOpacity(0.6),
                                ),
                          ),
                        ],
                      ),
                    ),
                    // Refresh button
                    IconButton(
                      onPressed: () {
                        setState(() => _isLoading = true);
                        _loadPastUpdates();
                      },
                      icon: Icon(
                        Icons.refresh_rounded,
                        color: colorScheme.primary,
                      ),
                      style: IconButton.styleFrom(
                        backgroundColor: colorScheme.primaryContainer,
                      ),
                    ),
                  ],
                ),
              ),

              // Content
              Expanded(
                child: _isLoading
                    ? Center(
                        child: CircularProgressIndicator(
                          color: colorScheme.primary,
                        ),
                      )
                    : _updates.isEmpty
                    ? _buildEmptyState(context, colorScheme)
                    : _buildUpdatesList(context, colorScheme),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, ColorScheme colorScheme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer.withOpacity(0.5),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.history_rounded,
                size: 64,
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No Past Updates',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Updates you share will appear here.\nStart by adding an image update!',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUpdatesList(BuildContext context, ColorScheme colorScheme) {
    return RefreshIndicator(
      onRefresh: _loadPastUpdates,
      color: colorScheme.primary,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        itemCount: _updates.length,
        itemBuilder: (context, index) {
          final update = _updates[index];
          return _buildUpdateCard(context, update, colorScheme);
        },
      ),
    );
  }

  Widget _buildUpdateCard(
    BuildContext context,
    UpdateEntry update,
    ColorScheme colorScheme,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: update.color.withOpacity(0.3), width: 2),
        boxShadow: [
          BoxShadow(
            color: update.color.withOpacity(0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // User header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: update.color,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(18),
                topRight: Radius.circular(18),
              ),
            ),
            child: Row(
              children: [
                // Avatar
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      update.userName.substring(0, 1).toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // User name and time
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        update.userName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      Text(
                        _formatDate(update.timestamp),
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                // Status indicator
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'Update',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Image content
          if (update.imagePath != null && File(update.imagePath!).existsSync())
            ClipRRect(
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(18),
                bottomRight: Radius.circular(18),
              ),
              child: SizedBox(
                width: double.infinity,
                height: 200,
                child: Image.file(
                  File(update.imagePath!),
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      height: 200,
                      color: update.color.withOpacity(0.1),
                      child: Center(
                        child: Icon(
                          Icons.broken_image_rounded,
                          color: update.color.withOpacity(0.5),
                          size: 48,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),

          // Text content (if available)
          if (update.text != null && update.text!.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: update.color.withOpacity(0.05),
                borderRadius: update.imagePath == null
                    ? const BorderRadius.only(
                        bottomLeft: Radius.circular(18),
                        bottomRight: Radius.circular(18),
                      )
                    : BorderRadius.zero,
              ),
              child: Text(
                update.text!,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: colorScheme.onSurface),
              ),
            ),
        ],
      ),
    );
  }
}
