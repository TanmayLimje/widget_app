import 'dart:io';
import 'package:flutter/material.dart';
import 'package:gal/gal.dart';
import 'update_history_service.dart';
import 'services/supabase_service.dart';

class PastUpdatesPage extends StatefulWidget {
  const PastUpdatesPage({super.key});

  @override
  State<PastUpdatesPage> createState() => _PastUpdatesPageState();
}

class _PastUpdatesPageState extends State<PastUpdatesPage> {
  List<UserUpdate> _updates = [];
  bool _isLoading = true;
  bool _isSyncing = false; // Shows subtle indicator when fetching new updates

  @override
  void initState() {
    super.initState();
    _loadPastUpdates();
  }

  Future<void> _loadPastUpdates() async {
    // Step 1: Show cached data immediately (no loading spinner if we have cache)
    final localUpdates = await UpdateHistoryService.loadHistory();
    final cachedRemoteUpdates =
        await UpdateHistoryService.loadCachedRemoteUpdates();

    // Merge local and cached remote updates
    final Map<String, UserUpdate> allUpdates = {};
    for (final update in localUpdates) {
      allUpdates[update.id] = update;
    }
    for (final update in cachedRemoteUpdates) {
      // Remote updates take precedence (they may have updated image paths)
      allUpdates[update.id] = update;
    }

    final cachedList = allUpdates.values.toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

    // Show cached data immediately
    if (cachedList.isNotEmpty || cachedRemoteUpdates.isNotEmpty) {
      setState(() {
        _updates = cachedList;
        _isLoading = false;
        _isSyncing = true; // Show syncing indicator
      });
    }

    // Step 2: Fetch new updates from Supabase (only delta)
    try {
      final lastSyncTime = await UpdateHistoryService.loadLastSyncTimestamp();
      final syncStartTime = DateTime.now();

      List<Map<String, dynamic>> remoteUpdates;

      if (lastSyncTime == null) {
        // First time - fetch all
        debugPrint('First sync - fetching all updates from Supabase');
        remoteUpdates = await SupabaseService.fetchAllUpdates();
      } else {
        // Incremental sync - fetch only new updates
        debugPrint('Incremental sync - fetching updates since $lastSyncTime');
        remoteUpdates = await SupabaseService.fetchUpdatesSince(lastSyncTime);
      }

      // Process new remote updates
      if (remoteUpdates.isNotEmpty) {
        for (final remote in remoteUpdates) {
          final id = remote['id'] as String;
          final imageUrl = remote['image_url'] as String?;
          String? localImagePath;

          // Check if we already have this update with an image
          if (allUpdates.containsKey(id) && allUpdates[id]!.imagePath != null) {
            final existingPath = allUpdates[id]!.imagePath!;
            if (File(existingPath).existsSync()) {
              localImagePath = existingPath;
            }
          }

          // Download image if needed
          if (localImagePath == null &&
              imageUrl != null &&
              imageUrl.isNotEmpty) {
            localImagePath = await SupabaseService.downloadImage(imageUrl, id);
          }

          final update = UserUpdate(
            id: id,
            timestamp: DateTime.parse(remote['updated_at'] as String),
            userId: remote['user_id'] as String,
            userName: remote['user_name'] as String,
            text: remote['text'] as String?,
            imagePath: localImagePath,
            colorHex: remote['color_hex'] as String,
          );

          allUpdates[id] = update;
        }

        // Re-sort and update UI
        final mergedList = allUpdates.values.toList()
          ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

        // Save to cache for next time
        await UpdateHistoryService.saveCachedRemoteUpdates(mergedList);
        await UpdateHistoryService.saveLastSyncTimestamp(syncStartTime);

        setState(() {
          _updates = mergedList;
        });

        debugPrint('Synced ${remoteUpdates.length} new updates from Supabase');
      } else {
        // No new updates, just save the sync timestamp
        await UpdateHistoryService.saveLastSyncTimestamp(syncStartTime);
        debugPrint('No new updates from Supabase');
      }
    } catch (e) {
      debugPrint('Error syncing updates from Supabase: $e');
    }

    setState(() {
      _isLoading = false;
      _isSyncing = false;
    });
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

  Future<void> _deleteUpdate(UserUpdate update) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Update'),
        content: const Text(
          'Are you sure you want to delete this update from history?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await UpdateHistoryService.deleteUpdate(update.id);
      _loadPastUpdates();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Update deleted'),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    }
  }

  Future<void> _saveImageToGallery(UserUpdate update) async {
    if (update.imagePath == null || update.imagePath!.isEmpty) return;

    final file = File(update.imagePath!);
    if (!file.existsSync()) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Image not found'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Theme.of(context).colorScheme.error,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
      return;
    }

    try {
      // Save to gallery using Gal package
      await Gal.putImage(update.imagePath!, album: 'AanTan');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                const SizedBox(width: 12),
                Text('Saved to gallery'),
              ],
            ),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.green.shade600,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint('Failed to save image: $e');
      if (mounted) {
        // Check if it's a permission issue
        final hasAccess = await Gal.hasAccess(toAlbum: true);
        if (!hasAccess) {
          final granted = await Gal.requestAccess(toAlbum: true);
          if (granted) {
            // Retry after permission granted
            _saveImageToGallery(update);
            return;
          }
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save image: $e'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Theme.of(context).colorScheme.error,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
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
                          Row(
                            children: [
                              Text(
                                '${_updates.length} updates',
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(
                                      color: colorScheme.onSurface.withOpacity(
                                        0.6,
                                      ),
                                    ),
                              ),
                              if (_isSyncing) ...[
                                const SizedBox(width: 8),
                                SizedBox(
                                  width: 12,
                                  height: 12,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: colorScheme.primary.withOpacity(0.5),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'syncing...',
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(
                                        color: colorScheme.primary.withOpacity(
                                          0.6,
                                        ),
                                        fontStyle: FontStyle.italic,
                                      ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                    // Refresh button
                    IconButton(
                      onPressed: _loadPastUpdates,
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
              'Updates you share will appear here.\nTap "Update Widget" to save your first update!',
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
    UserUpdate update,
    ColorScheme colorScheme,
  ) {
    final hasImage =
        update.imagePath != null &&
        update.imagePath!.isNotEmpty &&
        File(update.imagePath!).existsSync();
    final hasText = update.text != null && update.text!.isNotEmpty;

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
          // User header with timestamp
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
                  width: 40,
                  height: 40,
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
                        fontSize: 18,
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
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 2),
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
                // Save to gallery button (only show if image exists)
                if (hasImage)
                  IconButton(
                    onPressed: () => _saveImageToGallery(update),
                    icon: Icon(
                      Icons.download_rounded,
                      color: Colors.white.withOpacity(0.8),
                      size: 20,
                    ),
                    tooltip: 'Save to gallery',
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.white.withOpacity(0.1),
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(32, 32),
                    ),
                  ),
                if (hasImage) const SizedBox(width: 8),
                // Delete button
                IconButton(
                  onPressed: () => _deleteUpdate(update),
                  icon: Icon(
                    Icons.close_rounded,
                    color: Colors.white.withOpacity(0.8),
                    size: 20,
                  ),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.white.withOpacity(0.1),
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(32, 32),
                  ),
                ),
              ],
            ),
          ),

          // Image content
          if (hasImage)
            ClipRRect(
              borderRadius: hasText
                  ? BorderRadius.zero
                  : const BorderRadius.only(
                      bottomLeft: Radius.circular(18),
                      bottomRight: Radius.circular(18),
                    ),
              child: AspectRatio(
                aspectRatio: 1.0,
                child: Image.file(
                  File(update.imagePath!),
                  fit: BoxFit.cover,
                  width: double.infinity,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
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

          // Text content
          if (hasText)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: update.color.withOpacity(0.05),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(18),
                  bottomRight: Radius.circular(18),
                ),
              ),
              child: Text(
                update.text!,
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(color: colorScheme.onSurface),
              ),
            ),

          // Show placeholder if no content
          if (!hasImage && !hasText)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: update.color.withOpacity(0.05),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(18),
                  bottomRight: Radius.circular(18),
                ),
              ),
              child: Center(
                child: Text(
                  'Updated color theme',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurface.withOpacity(0.5),
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
