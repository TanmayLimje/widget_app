import 'dart:io';
import 'package:flutter/material.dart';
import 'package:home_widget/home_widget.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'drawing_canvas_page.dart';
import 'update_history_service.dart';
import 'past_updates_page.dart';
import 'main.dart'; // For themeModeNotifier and availableThemes

/// User-specific home page that shows only the logged-in user's controls
class UserHomePage extends StatefulWidget {
  final int userNumber;

  const UserHomePage({super.key, required this.userNumber});

  @override
  State<UserHomePage> createState() => _UserHomePageState();
}

class _UserHomePageState extends State<UserHomePage> {
  final TextEditingController _textController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();

  String _userText = '';
  UserTheme _userTheme = availableThemes[0];
  String? _userImagePath;

  // Store both users' data for widget preview
  String _user1Text = '';
  String _user2Text = '';
  UserTheme _user1Theme = availableThemes[0];
  UserTheme _user2Theme = availableThemes[1];
  String? _user1ImagePath;
  String? _user2ImagePath;

  bool _isUpdating = false;

  String get _userName => widget.userNumber == 1 ? 'Tanmay' : 'Aanchal';

  @override
  void initState() {
    super.initState();
    _initHomeWidget();
  }

  Future<void> _initHomeWidget() async {
    await HomeWidget.setAppGroupId('group.com.example.aantan');

    // Load all saved data for preview
    final savedUser1Text = await HomeWidget.getWidgetData<String>('user1_text');
    final savedUser2Text = await HomeWidget.getWidgetData<String>('user2_text');
    final savedUser1Color = await HomeWidget.getWidgetData<String>(
      'user1_color',
    );
    final savedUser2Color = await HomeWidget.getWidgetData<String>(
      'user2_color',
    );
    final savedUser1Image = await HomeWidget.getWidgetData<String>(
      'user1_image',
    );
    final savedUser2Image = await HomeWidget.getWidgetData<String>(
      'user2_image',
    );

    setState(() {
      // Load User 1 data
      if (savedUser1Text != null) {
        _user1Text = savedUser1Text;
        // Don't load into _userText - user starts fresh each time
      }
      if (savedUser1Color != null) {
        _user1Theme = availableThemes.firstWhere(
          (t) => t.hexCode == savedUser1Color,
          orElse: () => availableThemes[0],
        );
        if (widget.userNumber == 1) {
          _userTheme = _user1Theme;
        }
      }
      if (savedUser1Image != null && File(savedUser1Image).existsSync()) {
        _user1ImagePath = savedUser1Image;
        // Don't load into _userImagePath - user starts fresh each time
      }

      // Load User 2 data
      if (savedUser2Text != null) {
        _user2Text = savedUser2Text;
        // Don't load into _userText - user starts fresh each time
      }
      if (savedUser2Color != null) {
        _user2Theme = availableThemes.firstWhere(
          (t) => t.hexCode == savedUser2Color,
          orElse: () => availableThemes[1],
        );
        if (widget.userNumber == 2) {
          _userTheme = _user2Theme;
        }
      }
      if (savedUser2Image != null && File(savedUser2Image).existsSync()) {
        _user2ImagePath = savedUser2Image;
        // Don't load into _userImagePath - user starts fresh each time
      }
    });
  }

  Future<String?> _saveImageLocally(XFile image, String userId) async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final fileName =
          '${userId}_update_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final savedPath = '${appDir.path}/$fileName';

      final bytes = await image.readAsBytes();
      final file = File(savedPath);
      await file.writeAsBytes(bytes);

      return savedPath;
    } catch (e) {
      debugPrint('Error saving image: $e');
      return null;
    }
  }

  Future<void> _pickImage() async {
    final result = await showModalBottomSheet<dynamic>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildImageSourceSheet(context),
    );

    if (result == null) return;

    // Handle drawing canvas result
    if (result == 'draw') {
      final drawingPath = await Navigator.push<String>(
        context,
        MaterialPageRoute(builder: (context) => const DrawingCanvasPage()),
      );
      if (drawingPath != null) {
        setState(() {
          _userImagePath = drawingPath;
          _syncUserData();
        });
      }
      return;
    }

    // Handle camera/gallery result
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: result as ImageSource,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (image != null) {
        final savedPath = await _saveImageLocally(
          image,
          'user${widget.userNumber}',
        );
        if (savedPath != null) {
          setState(() {
            _userImagePath = savedPath;
            _syncUserData();
          });
        }
      }
    } catch (e) {
      _showSnackBar('Failed to pick image: $e', isError: true);
    }
  }

  void _removeImage() {
    setState(() {
      _userImagePath = null;
      _userText = '';
      _textController.clear();
      _syncUserData();
    });
  }

  void _syncUserData() {
    // Sync current user's data with the appropriate user slot
    if (widget.userNumber == 1) {
      _user1ImagePath = _userImagePath;
      _user1Theme = _userTheme;
      _user1Text = _userText;
    } else {
      _user2ImagePath = _userImagePath;
      _user2Theme = _userTheme;
      _user2Text = _userText;
    }
  }

  Widget _buildImageSourceSheet(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: colorScheme.onSurface.withOpacity(0.2),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Text(
              'Add Update Image',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 8),
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.camera_alt_rounded, color: colorScheme.primary),
            ),
            title: const Text('Take Photo'),
            subtitle: const Text('Capture a new image'),
            onTap: () => Navigator.pop(context, ImageSource.camera),
          ),
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: colorScheme.secondaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.photo_library_rounded,
                color: colorScheme.secondary,
              ),
            ),
            title: const Text('Choose from Gallery'),
            subtitle: const Text('Pick an existing image'),
            onTap: () => Navigator.pop(context, ImageSource.gallery),
          ),
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: colorScheme.tertiaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.brush_rounded, color: colorScheme.tertiary),
            ),
            title: const Text('Draw Something'),
            subtitle: const Text('Create a doodle on canvas'),
            onTap: () => Navigator.pop(context, 'draw'),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Future<void> _updateWidget() async {
    setState(() => _isUpdating = true);

    try {
      final userText = _textController.text.trim();

      // Update saved data for widget preview
      setState(() {
        if (widget.userNumber == 1) {
          _user1Text = userText;
          _user1ImagePath = _userImagePath;
        } else {
          _user2Text = userText;
          _user2ImagePath = _userImagePath;
        }
        _syncUserData();
      });

      // Save data based on which user is logged in
      if (widget.userNumber == 1) {
        await HomeWidget.saveWidgetData<String>('user1_text', userText);
        await HomeWidget.saveWidgetData<String>(
          'user1_color',
          _userTheme.hexCode,
        );
        await HomeWidget.saveWidgetData<String>(
          'user1_image',
          _userImagePath ?? '',
        );
      } else {
        await HomeWidget.saveWidgetData<String>('user2_text', userText);
        await HomeWidget.saveWidgetData<String>(
          'user2_color',
          _userTheme.hexCode,
        );
        await HomeWidget.saveWidgetData<String>(
          'user2_image',
          _userImagePath ?? '',
        );
      }

      // Update the widget
      await HomeWidget.updateWidget(
        androidName: 'AanTanWidgetProvider',
        iOSName: 'AanTanWidget',
      );

      // Save to update history
      await UpdateHistoryService.saveUpdate(
        user1Text: widget.userNumber == 1
            ? (userText.isNotEmpty ? userText : null)
            : (_user1Text.isNotEmpty ? _user1Text : null),
        user1ImagePath: widget.userNumber == 1
            ? _userImagePath
            : _user1ImagePath,
        user1ColorHex: widget.userNumber == 1
            ? _userTheme.hexCode
            : _user1Theme.hexCode,
        user2Text: widget.userNumber == 2
            ? (userText.isNotEmpty ? userText : null)
            : (_user2Text.isNotEmpty ? _user2Text : null),
        user2ImagePath: widget.userNumber == 2
            ? _userImagePath
            : _user2ImagePath,
        user2ColorHex: widget.userNumber == 2
            ? _userTheme.hexCode
            : _user2Theme.hexCode,
      );

      // Reset form to show "Add New" again
      setState(() {
        _userImagePath = null;
        _userText = '';
        _textController.clear();
      });

      _showSnackBar('Widget updated successfully!');
    } catch (e) {
      _showSnackBar('Failed to update widget: $e', isError: true);
    } finally {
      setState(() => _isUpdating = false);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError
            ? Theme.of(context).colorScheme.error
            : Theme.of(context).colorScheme.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Widget _buildThemeToggleButton(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: IconButton(
        onPressed: () => _showThemeSelector(context),
        icon: Icon(
          isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
          color: colorScheme.primary,
        ),
        tooltip: 'Change theme',
      ),
    );
  }

  Future<void> _showThemeSelector(BuildContext context) async {
    final colorScheme = Theme.of(context).colorScheme;

    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: colorScheme.onSurface.withOpacity(0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Text(
                'Choose Theme',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 8),
            _buildThemeOption(
              context: context,
              icon: Icons.light_mode_rounded,
              title: 'Light',
              subtitle: 'Always use light theme',
              mode: ThemeMode.light,
              iconColor: Colors.orange,
            ),
            _buildThemeOption(
              context: context,
              icon: Icons.dark_mode_rounded,
              title: 'Dark',
              subtitle: 'Always use dark theme',
              mode: ThemeMode.dark,
              iconColor: Colors.indigo,
            ),
            _buildThemeOption(
              context: context,
              icon: Icons.settings_suggest_rounded,
              title: 'System',
              subtitle: 'Follow system settings',
              mode: ThemeMode.system,
              iconColor: colorScheme.primary,
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeOption({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required ThemeMode mode,
    required Color iconColor,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final isSelected = themeModeNotifier.value == mode;

    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isSelected
              ? iconColor.withOpacity(0.2)
              : colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: iconColor),
      ),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: isSelected
          ? Icon(Icons.check_circle_rounded, color: colorScheme.primary)
          : null,
      onTap: () async {
        themeModeNotifier.value = mode;
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('theme_mode', _themeModeToString(mode));
        if (context.mounted) Navigator.pop(context);
      },
    );
  }

  String _themeModeToString(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'light';
      case ThemeMode.dark:
        return 'dark';
      case ThemeMode.system:
        return 'system';
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
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
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 20),

                // Header with Theme Toggle and Logout
                Row(
                  children: [
                    // Logout button
                    Container(
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHighest.withOpacity(
                          0.5,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: IconButton(
                        onPressed: () {
                          Navigator.pushReplacementNamed(context, '/login');
                        },
                        icon: Icon(
                          Icons.logout_rounded,
                          color: colorScheme.primary,
                        ),
                        tooltip: 'Switch user',
                      ),
                    ),
                    Expanded(
                      child: Text(
                        'Hi, $_userName!',
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: colorScheme.primary,
                            ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    _buildThemeToggleButton(context),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Update your widget',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: colorScheme.onSurface.withOpacity(0.6),
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 30),

                // Widget Preview
                _buildWidgetPreview(context),

                const SizedBox(height: 24),

                // User Card
                _buildUserCard(context),

                const SizedBox(height: 24),

                // Update Button - only show when there's an image to save
                if (_userImagePath != null)
                  FilledButton.icon(
                    onPressed: _isUpdating ? null : _updateWidget,
                    icon: _isUpdating
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.sync_rounded),
                    label: Text(
                      _isUpdating ? 'Updating...' : 'Save & Update Widget',
                    ),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),

                const SizedBox(height: 16),

                // Past Updates Button
                OutlinedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const PastUpdatesPage(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.history_rounded),
                  label: const Text('View Past Updates'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    side: BorderSide(color: colorScheme.primary),
                  ),
                ),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWidgetPreview(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    // Get the correct theme and image for preview - always use SAVED data
    final user1Theme = widget.userNumber == 1 ? _userTheme : _user1Theme;
    final user2Theme = widget.userNumber == 2 ? _userTheme : _user2Theme;
    // Preview always shows the SAVED widget data, not the form being edited
    final user1Image = _user1ImagePath;
    final user2Image = _user2ImagePath;
    final user1Text = _user1Text;
    final user2Text = _user2Text;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'Widget Preview',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: colorScheme.onSurface.withOpacity(0.5),
            ),
          ),
          const SizedBox(height: 12),
          // Preview mimics the actual widget layout
          SizedBox(
            height: 240,
            child: Row(
              children: [
                // User 1 (Tanmay) Preview
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.only(right: 2),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: user1Theme.color,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(12),
                        bottomLeft: Radius.circular(12),
                      ),
                    ),
                    child: Column(
                      children: [
                        const Text(
                          'Tanmay',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),
                        AspectRatio(
                          aspectRatio: 1.0,
                          child: Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: user1Image != null
                                  ? Colors.white.withOpacity(0.9)
                                  : Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: user1Image != null
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.file(
                                      File(user1Image),
                                      fit: BoxFit.cover,
                                    ),
                                  )
                                : Icon(
                                    Icons.image_outlined,
                                    color: Colors.white.withOpacity(0.5),
                                    size: 40,
                                  ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        if (user1Text.isNotEmpty)
                          Text(
                            user1Text,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                          ),
                      ],
                    ),
                  ),
                ),
                // User 2 (Aanchal) Preview
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.only(left: 2),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: user2Theme.color,
                      borderRadius: const BorderRadius.only(
                        topRight: Radius.circular(12),
                        bottomRight: Radius.circular(12),
                      ),
                    ),
                    child: Column(
                      children: [
                        const Text(
                          'Aanchal',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),
                        AspectRatio(
                          aspectRatio: 1.0,
                          child: Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: user2Image != null
                                  ? Colors.white.withOpacity(0.9)
                                  : Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: user2Image != null
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.file(
                                      File(user2Image),
                                      fit: BoxFit.cover,
                                    ),
                                  )
                                : Icon(
                                    Icons.image_outlined,
                                    color: Colors.white.withOpacity(0.5),
                                    size: 40,
                                  ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        if (user2Text.isNotEmpty)
                          Text(
                            user2Text,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserCard(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _userTheme.color.withOpacity(0.3), width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: _userTheme.color,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _userName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Update Image Section
          Text(
            'Update Image',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 8),

          // Show image preview if exists, otherwise show Add New button
          if (_userImagePath != null) ...[
            Container(
              height: 150,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _userTheme.color.withOpacity(0.3),
                  width: 2,
                ),
                color: Colors.black.withOpacity(0.3),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.file(
                  File(_userImagePath!),
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _pickImage,
                    icon: const Icon(Icons.edit, size: 18),
                    label: const Text('Change'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _userTheme.color,
                      side: BorderSide(color: _userTheme.color),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _removeImage,
                    icon: const Icon(Icons.delete_outline, size: 18),
                    label: const Text('Remove'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: colorScheme.error,
                      side: BorderSide(color: colorScheme.error),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Text Input (optional) - only shown after image is added
            TextField(
              controller: _textController,
              decoration: InputDecoration(
                labelText: 'Caption (optional)',
                hintText: 'Add a message...',
                prefixIcon: const Icon(Icons.message_rounded),
                filled: true,
                fillColor: colorScheme.surfaceContainerHighest.withOpacity(0.3),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: _userTheme.color, width: 2),
                ),
              ),
            ),
          ] else ...[
            // Add New card when no image exists
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                height: 150,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _userTheme.color.withOpacity(0.5),
                    width: 2,
                    strokeAlign: BorderSide.strokeAlignInside,
                  ),
                  color: _userTheme.color.withOpacity(0.1),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.add_photo_alternate_rounded,
                      color: _userTheme.color,
                      size: 48,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Tap to add new update',
                      style: TextStyle(
                        color: _userTheme.color,
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],

          const SizedBox(height: 16),

          // Color Selection
          Text(
            'Background Color',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: availableThemes.map((theme) {
              final isSelected = theme.hexCode == _userTheme.hexCode;
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _userTheme = theme;
                    _syncUserData();
                  });
                },
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: theme.color,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected ? Colors.white : Colors.transparent,
                      width: 3,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: theme.color.withOpacity(0.5),
                              blurRadius: 8,
                              spreadRadius: 2,
                            ),
                          ]
                        : null,
                  ),
                  child: isSelected
                      ? const Icon(Icons.check, color: Colors.white, size: 20)
                      : null,
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
