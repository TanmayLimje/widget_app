import 'dart:io';
import 'package:flutter/material.dart';
import 'package:home_widget/home_widget.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image/image.dart' as img;
import 'main.dart';
import 'past_updates_page.dart';
import 'drawing_canvas_page.dart';
import 'update_history_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController _user1Controller = TextEditingController();
  final TextEditingController _user2Controller = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();

  String _user1Text = '';
  String _user2Text = '';

  UserTheme _user1Theme = availableThemes[0]; // Purple
  UserTheme _user2Theme = availableThemes[1]; // Blue

  String? _user1ImagePath;
  String? _user2ImagePath;

  bool _isUpdating = false;

  @override
  void initState() {
    super.initState();
    _initHomeWidget();
  }

  Future<void> _initHomeWidget() async {
    await HomeWidget.setAppGroupId('group.com.example.aantan');

    // Load saved data
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
      if (savedUser1Text != null) {
        _user1Text = savedUser1Text;
        _user1Controller.text = savedUser1Text;
      }
      if (savedUser2Text != null) {
        _user2Text = savedUser2Text;
        _user2Controller.text = savedUser2Text;
      }
      if (savedUser1Color != null) {
        _user1Theme = availableThemes.firstWhere(
          (t) => t.hexCode == savedUser1Color,
          orElse: () => availableThemes[0],
        );
      }
      if (savedUser2Color != null) {
        _user2Theme = availableThemes.firstWhere(
          (t) => t.hexCode == savedUser2Color,
          orElse: () => availableThemes[1],
        );
      }
      if (savedUser1Image != null && File(savedUser1Image).existsSync()) {
        _user1ImagePath = savedUser1Image;
      }
      if (savedUser2Image != null && File(savedUser2Image).existsSync()) {
        _user2ImagePath = savedUser2Image;
      }
    });
  }

  Future<String?> _saveImageLocally(
    XFile image,
    String userId, {
    bool flipHorizontally = false,
  }) async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final fileName =
          '${userId}_update_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final savedPath = '${appDir.path}/$fileName';

      var bytes = await image.readAsBytes();

      // Flip the image horizontally if from front camera (to fix mirror effect)
      if (flipHorizontally) {
        final decodedImage = img.decodeImage(bytes);
        if (decodedImage != null) {
          final flippedImage = img.flipHorizontal(decodedImage);
          bytes = img.encodeJpg(flippedImage, quality: 85);
        }
      }

      final file = File(savedPath);
      await file.writeAsBytes(bytes);

      return savedPath;
    } catch (e) {
      debugPrint('Error saving image: $e');
      return null;
    }
  }

  Future<void> _pickImage(int userNumber) async {
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
          if (userNumber == 1) {
            _user1ImagePath = drawingPath;
          } else {
            _user2ImagePath = drawingPath;
          }
        });
      }
      return;
    }

    // Handle camera/gallery result
    final imageSource = result as ImageSource;
    final isFromCamera = imageSource == ImageSource.camera;

    try {
      final XFile? image = await _imagePicker.pickImage(
        source: imageSource,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
        preferredCameraDevice: CameraDevice.front,
      );

      if (image != null) {
        // Flip horizontally if taken from camera (front camera produces mirrored image)
        final savedPath = await _saveImageLocally(
          image,
          'user$userNumber',
          flipHorizontally: isFromCamera,
        );
        if (savedPath != null) {
          setState(() {
            if (userNumber == 1) {
              _user1ImagePath = savedPath;
            } else {
              _user2ImagePath = savedPath;
            }
          });
        }
      }
    } catch (e) {
      _showSnackBar('Failed to pick image: $e', isError: true);
    }
  }

  void _removeImage(int userNumber) {
    setState(() {
      if (userNumber == 1) {
        _user1ImagePath = null;
      } else {
        _user2ImagePath = null;
      }
    });
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
      final user1Text = _user1Controller.text.trim();
      final user2Text = _user2Controller.text.trim();

      // Save data for both users
      await HomeWidget.saveWidgetData<String>('user1_text', user1Text);
      await HomeWidget.saveWidgetData<String>('user2_text', user2Text);
      await HomeWidget.saveWidgetData<String>(
        'user1_color',
        _user1Theme.hexCode,
      );
      await HomeWidget.saveWidgetData<String>(
        'user2_color',
        _user2Theme.hexCode,
      );

      // Save image paths (or empty string if no image)
      await HomeWidget.saveWidgetData<String>(
        'user1_image',
        _user1ImagePath ?? '',
      );
      await HomeWidget.saveWidgetData<String>(
        'user2_image',
        _user2ImagePath ?? '',
      );

      // Update the widget
      await HomeWidget.updateWidget(
        androidName: 'AanTanWidgetProvider',
        iOSName: 'AanTanWidget',
      );

      // Save to update history
      await UpdateHistoryService.saveUpdate(
        user1Text: user1Text.isNotEmpty ? user1Text : null,
        user1ImagePath: _user1ImagePath,
        user1ColorHex: _user1Theme.hexCode,
        user2Text: user2Text.isNotEmpty ? user2Text : null,
        user2ImagePath: _user2ImagePath,
        user2ColorHex: _user2Theme.hexCode,
      );

      setState(() {
        _user1Text = user1Text;
        _user2Text = user2Text;
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
        await prefs.setString('theme_mode', themeModeToString(mode));
        if (context.mounted) Navigator.pop(context);
      },
    );
  }

  @override
  void dispose() {
    _user1Controller.dispose();
    _user2Controller.dispose();
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

                // Header with Theme Toggle
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Spacer(),
                    Text(
                      'AanTan',
                      style: Theme.of(context).textTheme.displaySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.primary,
                      ),
                    ),
                    Expanded(
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: _buildThemeToggleButton(context),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Share Updates Widget',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: colorScheme.onSurface.withOpacity(0.6),
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 30),

                // Widget Preview
                Container(
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
                            // User 1 Preview
                            Expanded(
                              child: Container(
                                margin: const EdgeInsets.only(right: 2),
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: _user1Theme.color,
                                  borderRadius: const BorderRadius.only(
                                    topLeft: Radius.circular(12),
                                    bottomLeft: Radius.circular(12),
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    // Username
                                    Text(
                                      'User 1',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    // Update Image
                                    AspectRatio(
                                      aspectRatio: 1.0,
                                      child: Container(
                                        width: double.infinity,
                                        decoration: BoxDecoration(
                                          color: _user1ImagePath != null
                                              ? Colors.white.withOpacity(0.9)
                                              : Colors.white.withOpacity(0.2),
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: _user1ImagePath != null
                                            ? ClipRRect(
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                                child: Image.file(
                                                  File(_user1ImagePath!),
                                                  fit: BoxFit.cover,
                                                ),
                                              )
                                            : Icon(
                                                Icons.image_outlined,
                                                color: Colors.white.withOpacity(
                                                  0.5,
                                                ),
                                                size: 40,
                                              ),
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    // Text
                                    if (_user1Text.isNotEmpty)
                                      Text(
                                        _user1Text,
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
                            // User 2 Preview
                            Expanded(
                              child: Container(
                                margin: const EdgeInsets.only(left: 2),
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: _user2Theme.color,
                                  borderRadius: const BorderRadius.only(
                                    topRight: Radius.circular(12),
                                    bottomRight: Radius.circular(12),
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    // Username
                                    Text(
                                      'User 2',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    // Update Image
                                    AspectRatio(
                                      aspectRatio: 1.0,
                                      child: Container(
                                        width: double.infinity,
                                        decoration: BoxDecoration(
                                          color: _user2ImagePath != null
                                              ? Colors.white.withOpacity(0.9)
                                              : Colors.white.withOpacity(0.2),
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: _user2ImagePath != null
                                            ? ClipRRect(
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                                child: Image.file(
                                                  File(_user2ImagePath!),
                                                  fit: BoxFit.cover,
                                                ),
                                              )
                                            : Icon(
                                                Icons.image_outlined,
                                                color: Colors.white.withOpacity(
                                                  0.5,
                                                ),
                                                size: 40,
                                              ),
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    // Text
                                    if (_user2Text.isNotEmpty)
                                      Text(
                                        _user2Text,
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
                ),

                const SizedBox(height: 24),

                // User 1 Card
                _buildUserCard(
                  context: context,
                  title: 'User 1',
                  userNumber: 1,
                  controller: _user1Controller,
                  selectedTheme: _user1Theme,
                  imagePath: _user1ImagePath,
                  onThemeChanged: (theme) =>
                      setState(() => _user1Theme = theme),
                  onPickImage: () => _pickImage(1),
                  onRemoveImage: () => _removeImage(1),
                ),

                const SizedBox(height: 16),

                // User 2 Card
                _buildUserCard(
                  context: context,
                  title: 'User 2',
                  userNumber: 2,
                  controller: _user2Controller,
                  selectedTheme: _user2Theme,
                  imagePath: _user2ImagePath,
                  onThemeChanged: (theme) =>
                      setState(() => _user2Theme = theme),
                  onPickImage: () => _pickImage(2),
                  onRemoveImage: () => _removeImage(2),
                ),

                const SizedBox(height: 24),

                // Update Button
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
                  label: Text(_isUpdating ? 'Updating...' : 'Update Widget'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Instructions
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline_rounded,
                        color: colorScheme.primary,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Long-press your home screen → Widgets → AanTan',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: colorScheme.onSurface.withOpacity(0.7),
                              ),
                        ),
                      ),
                    ],
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
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUserCard({
    required BuildContext context,
    required String title,
    required int userNumber,
    required TextEditingController controller,
    required UserTheme selectedTheme,
    required String? imagePath,
    required ValueChanged<UserTheme> onThemeChanged,
    required VoidCallback onPickImage,
    required VoidCallback onRemoveImage,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: selectedTheme.color.withOpacity(0.3),
          width: 2,
        ),
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
                  color: selectedTheme.color,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  title,
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

          GestureDetector(
            onTap: onPickImage,
            child: Container(
              height: 150,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: selectedTheme.color.withOpacity(0.3),
                  width: 2,
                ),
                image: imagePath != null
                    ? DecorationImage(
                        image: FileImage(File(imagePath)),
                        fit: BoxFit.cover,
                      )
                    : null,
                color: imagePath == null
                    ? selectedTheme.color.withOpacity(0.1)
                    : null,
              ),
              child: imagePath == null
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.add_photo_alternate_rounded,
                          color: selectedTheme.color,
                          size: 40,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Tap to add image',
                          style: TextStyle(
                            color: selectedTheme.color,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    )
                  : null,
            ),
          ),

          if (imagePath != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onPickImage,
                    icon: const Icon(Icons.edit, size: 18),
                    label: const Text('Change'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: selectedTheme.color,
                      side: BorderSide(color: selectedTheme.color),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onRemoveImage,
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
          ],

          const SizedBox(height: 16),

          // Text Input (optional)
          TextField(
            controller: controller,
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
                borderSide: BorderSide(color: selectedTheme.color, width: 2),
              ),
            ),
          ),

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
              final isSelected = theme.hexCode == selectedTheme.hexCode;
              return GestureDetector(
                onTap: () => onThemeChanged(theme),
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
