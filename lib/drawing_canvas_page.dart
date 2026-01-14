import 'dart:io';
import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'models/canvas_element.dart';

/// A stroke represents a single drawing gesture with its points, color, and width
class DrawingStroke {
  final List<Offset> points;
  final Color color;
  final double strokeWidth;

  DrawingStroke({
    required this.points,
    required this.color,
    required this.strokeWidth,
  });
}

/// Available brush sizes
enum BrushSize {
  fine(3.0, 'Fine'),
  medium(8.0, 'Medium'),
  bold(15.0, 'Bold');

  final double width;
  final String label;
  const BrushSize(this.width, this.label);
}

/// Canvas editing mode
enum CanvasMode { draw, emoji, text }

/// Curated color palette for drawing
final List<Color> drawingColors = [
  Colors.black,
  const Color(0xFF6366F1), // Purple
  const Color(0xFF3B82F6), // Blue
  const Color(0xFF10B981), // Green
  const Color(0xFF14B8A6), // Teal
  const Color(0xFFF97316), // Orange
  const Color(0xFFEC4899), // Pink
  const Color(0xFFEF4444), // Red
  const Color(0xFFEAB308), // Yellow
  const Color(0xFF8B5CF6), // Violet
  const Color(0xFF78716C), // Stone
  Colors.white,
];

/// Background color options
final List<Color> backgroundColors = [
  Colors.white,
  const Color(0xFFF8FAFC), // Slate 50
  const Color(0xFFFEF3C7), // Amber 100
  const Color(0xFFDCFCE7), // Green 100
  const Color(0xFFDBEAFE), // Blue 100
  const Color(0xFFFCE7F3), // Pink 100
  const Color(0xFF1F2937), // Gray 800
  Colors.black,
];

class DrawingCanvasPage extends StatefulWidget {
  const DrawingCanvasPage({super.key});

  @override
  State<DrawingCanvasPage> createState() => _DrawingCanvasPageState();
}

class _DrawingCanvasPageState extends State<DrawingCanvasPage> {
  final GlobalKey _canvasKey = GlobalKey();
  final List<DrawingStroke> _strokes = [];
  List<Offset> _currentPoints = [];

  // Drawing state
  Color _selectedColor = Colors.black;
  BrushSize _selectedBrushSize = BrushSize.medium;
  Color _backgroundColor = Colors.white;
  bool _isEraser = false;
  bool _isSaving = false;

  // Canvas mode and elements
  CanvasMode _canvasMode = CanvasMode.draw;
  final List<CanvasElement> _elements = [];
  CanvasElement? _selectedElement;

  // Transform gesture state
  double _initialScale = 1.0;
  double _initialRotation = 0.0;
  Offset _initialFocalPoint = Offset.zero;
  Offset _initialElementPosition = Offset.zero;

  void _onScaleStart(ScaleStartDetails details) {
    if (_selectedElement != null) {
      _initialScale = _selectedElement!.scale;
      _initialRotation = _selectedElement!.rotation;
      _initialFocalPoint = details.focalPoint;
      _initialElementPosition = _selectedElement!.position;
    } else if (_canvasMode == CanvasMode.draw) {
      // Start drawing
      final localPosition = _getLocalPosition(details.focalPoint);
      setState(() {
        _currentPoints = [localPosition];
      });
    }
  }

  void _onScaleUpdate(ScaleUpdateDetails details) {
    if (_selectedElement != null && details.pointerCount >= 2) {
      setState(() {
        // Scale
        _selectedElement!.scale = (_initialScale * details.scale).clamp(
          0.3,
          4.0,
        );
        // Rotate
        _selectedElement!.rotation = _initialRotation + details.rotation;
      });
    } else if (_selectedElement != null && details.pointerCount == 1) {
      // Single finger move
      final delta = details.focalPoint - _initialFocalPoint;
      setState(() {
        _selectedElement!.position = _initialElementPosition + delta;
      });
    } else if (_canvasMode == CanvasMode.draw && details.pointerCount == 1) {
      final localPosition = _getLocalPosition(details.focalPoint);
      setState(() {
        _currentPoints = [..._currentPoints, localPosition];
      });
    }
  }

  void _onScaleEnd(ScaleEndDetails details) {
    if (_canvasMode == CanvasMode.draw && _currentPoints.isNotEmpty) {
      setState(() {
        _strokes.add(
          DrawingStroke(
            points: List.from(_currentPoints),
            color: _isEraser ? _backgroundColor : _selectedColor,
            strokeWidth: _selectedBrushSize.width,
          ),
        );
        _currentPoints = [];
      });
    }
  }

  Offset _getLocalPosition(Offset globalPosition) {
    final RenderBox? renderBox =
        _canvasKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox != null) {
      return renderBox.globalToLocal(globalPosition);
    }
    return globalPosition;
  }

  CanvasElement? _hitTestElements(Offset position) {
    // Check in reverse order (top elements first)
    for (int i = _elements.length - 1; i >= 0; i--) {
      final element = _elements[i];
      Size elementSize;
      if (element is EmojiElement) {
        elementSize = Size(EmojiElement.defaultSize, EmojiElement.defaultSize);
      } else if (element is TextElement) {
        // Approximate text size
        elementSize = Size(
          element.text.length * element.fontSize * 0.6,
          element.fontSize * 1.5,
        );
      } else {
        continue;
      }
      if (element.containsPoint(position, elementSize)) {
        return element;
      }
    }
    return null;
  }

  void _undo() {
    setState(() {
      if (_selectedElement != null) {
        // Delete selected element
        _elements.remove(_selectedElement);
        _selectedElement = null;
      } else if (_strokes.isNotEmpty) {
        _strokes.removeLast();
      } else if (_elements.isNotEmpty) {
        _elements.removeLast();
      }
    });
  }

  void _deleteSelectedElement() {
    if (_selectedElement != null) {
      setState(() {
        _elements.remove(_selectedElement);
        _selectedElement = null;
      });
    }
  }

  void _clearCanvas() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Canvas'),
        content: const Text(
          'Are you sure you want to clear the entire canvas?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              setState(() {
                _strokes.clear();
                _elements.clear();
                _selectedElement = null;
              });
              Navigator.pop(context);
            },
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }

  void _showEmojiPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.45,
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Add Emoji',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 8,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                ),
                itemCount: popularEmojis.length,
                itemBuilder: (context, index) {
                  final emoji = popularEmojis[index];
                  return GestureDetector(
                    onTap: () {
                      _addEmoji(emoji);
                      Navigator.pop(context);
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: Theme.of(
                          context,
                        ).colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      alignment: Alignment.center,
                      child: Text(emoji, style: const TextStyle(fontSize: 24)),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _addEmoji(String emoji) {
    // Get canvas center
    final RenderBox? renderBox =
        _canvasKey.currentContext?.findRenderObject() as RenderBox?;
    final center = renderBox != null
        ? Offset(renderBox.size.width / 2, renderBox.size.height / 2)
        : const Offset(150, 150);

    setState(() {
      if (_selectedElement != null) {
        _selectedElement!.isSelected = false;
      }
      final newEmoji = EmojiElement(
        position: center,
        emoji: emoji,
        isSelected: true,
      );
      _elements.add(newEmoji);
      _selectedElement = newEmoji;
    });
  }

  void _showTextEditor({TextElement? existingElement}) {
    final textController = TextEditingController(
      text: existingElement?.text ?? '',
    );
    String selectedFont = existingElement?.fontFamily ?? 'Roboto';
    double fontSize = existingElement?.fontSize ?? 24.0;
    Color textColor = existingElement?.textColor ?? Colors.black;
    Color? bgColor = existingElement?.backgroundColor;
    bool hasBorder = existingElement?.hasBorder ?? false;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(20),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Text(
                    existingElement != null ? 'Edit Text' : 'Add Text',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),

                  // Text input
                  TextField(
                    controller: textController,
                    autofocus: true,
                    maxLines: 2,
                    decoration: InputDecoration(
                      hintText: 'Enter your text...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Font selector
                  Row(
                    children: [
                      Text(
                        'Font:',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: availableFonts.map((font) {
                              final isSelected = font == selectedFont;
                              return Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: ChoiceChip(
                                  label: Text(
                                    font,
                                    style: TextStyle(fontFamily: font),
                                  ),
                                  selected: isSelected,
                                  onSelected: (selected) {
                                    setSheetState(() => selectedFont = font);
                                  },
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Font size slider
                  Row(
                    children: [
                      Text(
                        'Size:',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      Expanded(
                        child: Slider(
                          value: fontSize,
                          min: 12,
                          max: 72,
                          divisions: 15,
                          label: fontSize.round().toString(),
                          onChanged: (value) {
                            setSheetState(() => fontSize = value);
                          },
                        ),
                      ),
                      Text('${fontSize.round()}'),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Text color
                  Row(
                    children: [
                      Text(
                        'Color:',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: textColors.map((color) {
                              final isSelected = color == textColor;
                              return GestureDetector(
                                onTap: () =>
                                    setSheetState(() => textColor = color),
                                child: Container(
                                  width: 32,
                                  height: 32,
                                  margin: const EdgeInsets.only(right: 8),
                                  decoration: BoxDecoration(
                                    color: color,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: isSelected
                                          ? Theme.of(
                                              context,
                                            ).colorScheme.primary
                                          : (color == Colors.white
                                                ? Colors.grey.shade300
                                                : Colors.transparent),
                                      width: isSelected ? 3 : 1,
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Background color
                  Row(
                    children: [
                      Text(
                        'Background:',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: textBackgroundColors.map((color) {
                              final isSelected = color == bgColor;
                              return GestureDetector(
                                onTap: () =>
                                    setSheetState(() => bgColor = color),
                                child: Container(
                                  width: 32,
                                  height: 32,
                                  margin: const EdgeInsets.only(right: 8),
                                  decoration: BoxDecoration(
                                    color: color ?? Colors.transparent,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: isSelected
                                          ? Theme.of(
                                              context,
                                            ).colorScheme.primary
                                          : Colors.grey.shade300,
                                      width: isSelected ? 3 : 1,
                                    ),
                                  ),
                                  child: color == null
                                      ? Icon(
                                          Icons.block,
                                          size: 18,
                                          color: Colors.grey.shade400,
                                        )
                                      : null,
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Border toggle
                  Row(
                    children: [
                      Text(
                        'Border:',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(width: 12),
                      Switch(
                        value: hasBorder,
                        onChanged: (value) =>
                            setSheetState(() => hasBorder = value),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Buttons
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton(
                          onPressed: () {
                            final text = textController.text.trim();
                            if (text.isNotEmpty) {
                              if (existingElement != null) {
                                _updateTextElement(
                                  existingElement,
                                  text: text,
                                  fontFamily: selectedFont,
                                  fontSize: fontSize,
                                  textColor: textColor,
                                  backgroundColor: bgColor,
                                  hasBorder: hasBorder,
                                );
                              } else {
                                _addTextElement(
                                  text: text,
                                  fontFamily: selectedFont,
                                  fontSize: fontSize,
                                  textColor: textColor,
                                  backgroundColor: bgColor,
                                  hasBorder: hasBorder,
                                );
                              }
                              Navigator.pop(context);
                            }
                          },
                          child: Text(
                            existingElement != null ? 'Update' : 'Add',
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _addTextElement({
    required String text,
    required String fontFamily,
    required double fontSize,
    required Color textColor,
    Color? backgroundColor,
    required bool hasBorder,
  }) {
    // Get canvas center
    final RenderBox? renderBox =
        _canvasKey.currentContext?.findRenderObject() as RenderBox?;
    final center = renderBox != null
        ? Offset(renderBox.size.width / 2, renderBox.size.height / 2)
        : const Offset(150, 150);

    setState(() {
      if (_selectedElement != null) {
        _selectedElement!.isSelected = false;
      }
      final newText = TextElement(
        position: center,
        text: text,
        fontFamily: fontFamily,
        fontSize: fontSize,
        textColor: textColor,
        backgroundColor: backgroundColor,
        hasBorder: hasBorder,
        isSelected: true,
      );
      _elements.add(newText);
      _selectedElement = newText;
    });
  }

  void _updateTextElement(
    TextElement element, {
    required String text,
    required String fontFamily,
    required double fontSize,
    required Color textColor,
    Color? backgroundColor,
    required bool hasBorder,
  }) {
    setState(() {
      final index = _elements.indexOf(element);
      if (index != -1) {
        final updated = element.copyWith(
          text: text,
          fontFamily: fontFamily,
          fontSize: fontSize,
          textColor: textColor,
          backgroundColor: backgroundColor,
          clearBackground: backgroundColor == null,
          hasBorder: hasBorder,
        );
        _elements[index] = updated;
        _selectedElement = updated;
      }
    });
  }

  Future<void> _saveDrawing() async {
    if (_strokes.isEmpty && _elements.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Draw something first!'),
          backgroundColor: Theme.of(context).colorScheme.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
      return;
    }

    // Deselect any selected element before saving
    setState(() {
      if (_selectedElement != null) {
        _selectedElement!.isSelected = false;
        _selectedElement = null;
      }
    });

    // Wait for rebuild before capturing
    await Future.delayed(const Duration(milliseconds: 50));

    setState(() => _isSaving = true);

    try {
      final boundary =
          _canvasKey.currentContext!.findRenderObject()
              as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final Uint8List pngBytes = byteData!.buffer.asUint8List();

      final appDir = await getApplicationDocumentsDirectory();
      final fileName = 'drawing_${DateTime.now().millisecondsSinceEpoch}.png';
      final filePath = '${appDir.path}/$fileName';

      final file = File(filePath);
      await file.writeAsBytes(pngBytes);

      if (mounted) {
        Navigator.pop(context, filePath);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save drawing: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  void _showBackgroundColorPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Canvas Background',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: backgroundColors.map((color) {
                final isSelected = color == _backgroundColor;
                final isDark = color.computeLuminance() < 0.5;
                return GestureDetector(
                  onTap: () {
                    setState(() => _backgroundColor = color);
                    Navigator.pop(context);
                  },
                  child: Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected
                            ? Theme.of(context).colorScheme.primary
                            : Colors.grey.withOpacity(0.3),
                        width: isSelected ? 3 : 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: isSelected
                        ? Icon(
                            Icons.check,
                            color: isDark ? Colors.white : Colors.black,
                          )
                        : null,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
          tooltip: 'Discard',
        ),
        title: const Text('Draw Something'),
        centerTitle: true,
        actions: [
          if (_selectedElement != null)
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded),
              onPressed: _deleteSelectedElement,
              tooltip: 'Delete Element',
              color: colorScheme.error,
            ),
          IconButton(
            icon: const Icon(Icons.undo_rounded),
            onPressed: (_strokes.isEmpty && _elements.isEmpty) ? null : _undo,
            tooltip: 'Undo',
          ),
          IconButton(
            icon: const Icon(Icons.delete_sweep_outlined),
            onPressed: (_strokes.isEmpty && _elements.isEmpty)
                ? null
                : _clearCanvas,
            tooltip: 'Clear All',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // Mode Switcher
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  _buildModeButton(
                    icon: Icons.brush_rounded,
                    label: 'Draw',
                    mode: CanvasMode.draw,
                    colorScheme: colorScheme,
                  ),
                  _buildModeButton(
                    icon: Icons.emoji_emotions_rounded,
                    label: 'Emoji',
                    mode: CanvasMode.emoji,
                    colorScheme: colorScheme,
                  ),
                  _buildModeButton(
                    icon: Icons.text_fields_rounded,
                    label: 'Text',
                    mode: CanvasMode.text,
                    colorScheme: colorScheme,
                  ),
                ],
              ),
            ),
          ),

          // Canvas Area - Square aspect ratio
          Expanded(
            child: Center(
              child: AspectRatio(
                aspectRatio: 1.0,
                child: Container(
                  margin: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _backgroundColor,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: colorScheme.shadow.withOpacity(0.15),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: RepaintBoundary(
                      key: _canvasKey,
                      child: GestureDetector(
                        onScaleStart: _onScaleStart,
                        onScaleUpdate: _onScaleUpdate,
                        onScaleEnd: _onScaleEnd,
                        onTapUp: (details) {
                          if (_canvasMode != CanvasMode.draw) {
                            final tapped = _hitTestElements(
                              details.localPosition,
                            );
                            setState(() {
                              if (_selectedElement != null) {
                                _selectedElement!.isSelected = false;
                              }
                              _selectedElement = tapped;
                              if (tapped != null) {
                                tapped.isSelected = true;
                              }
                            });
                            // Double tap to edit text
                            if (tapped is TextElement) {
                              _showTextEditor(existingElement: tapped);
                            }
                          }
                        },
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            // Drawing layer
                            CustomPaint(
                              painter: _DrawingPainter(
                                strokes: _strokes,
                                currentPoints: _currentPoints,
                                currentColor: _isEraser
                                    ? _backgroundColor
                                    : _selectedColor,
                                currentStrokeWidth: _selectedBrushSize.width,
                                backgroundColor: _backgroundColor,
                              ),
                              size: Size.infinite,
                            ),
                            // Elements layer
                            ..._elements.map(
                              (element) => _buildElement(element),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Bottom Toolbar
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: colorScheme.shadow.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Mode-specific toolbar
                if (_canvasMode == CanvasMode.draw)
                  _buildDrawToolbar(colorScheme),
                if (_canvasMode == CanvasMode.emoji)
                  _buildEmojiToolbar(colorScheme),
                if (_canvasMode == CanvasMode.text)
                  _buildTextToolbar(colorScheme),

                const SizedBox(height: 16),

                // Save button row
                Row(
                  children: [
                    if (_canvasMode == CanvasMode.draw) ...[
                      // Brush size selector
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: BrushSize.values.map((size) {
                              final isSelected = size == _selectedBrushSize;
                              return Flexible(
                                child: GestureDetector(
                                  onTap: () =>
                                      setState(() => _selectedBrushSize = size),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? colorScheme.primary
                                          : Colors.transparent,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Container(
                                          width: size.width,
                                          height: size.width,
                                          decoration: BoxDecoration(
                                            color: isSelected
                                                ? Colors.white
                                                : colorScheme.onSurface,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        Flexible(
                                          child: Text(
                                            size.label,
                                            style: TextStyle(
                                              color: isSelected
                                                  ? Colors.white
                                                  : colorScheme.onSurface,
                                              fontWeight: isSelected
                                                  ? FontWeight.bold
                                                  : FontWeight.normal,
                                              fontSize: 11,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                    ] else ...[
                      Expanded(
                        child: Text(
                          _canvasMode == CanvasMode.emoji
                              ? 'Tap emoji to add, then drag to move'
                              : 'Tap Add Text, then drag to move',
                          style: TextStyle(
                            color: colorScheme.onSurfaceVariant,
                            fontSize: 13,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(width: 12),
                    ],

                    // Save button
                    FilledButton.icon(
                      onPressed: _isSaving ? null : _saveDrawing,
                      icon: _isSaving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.check_rounded, size: 20),
                      label: Text(_isSaving ? 'Saving...' : 'Done'),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModeButton({
    required IconData icon,
    required String label,
    required CanvasMode mode,
    required ColorScheme colorScheme,
  }) {
    final isSelected = _canvasMode == mode;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _canvasMode = mode;
            // Deselect element when switching to draw mode
            if (mode == CanvasMode.draw && _selectedElement != null) {
              _selectedElement!.isSelected = false;
              _selectedElement = null;
            }
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? colorScheme.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18,
                color: isSelected
                    ? colorScheme.onPrimary
                    : colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: isSelected
                      ? colorScheme.onPrimary
                      : colorScheme.onSurfaceVariant,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildElement(CanvasElement element) {
    if (element is EmojiElement) {
      return Positioned(
        left:
            element.position.dx -
            (EmojiElement.defaultSize * element.scale) / 2,
        top:
            element.position.dy -
            (EmojiElement.defaultSize * element.scale) / 2,
        child: Transform.rotate(
          angle: element.rotation,
          child: Container(
            decoration: element.isSelected
                ? BoxDecoration(
                    border: Border.all(
                      color: Theme.of(context).colorScheme.primary,
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  )
                : null,
            padding: element.isSelected ? const EdgeInsets.all(4) : null,
            child: Text(
              element.emoji,
              style: TextStyle(
                fontSize: EmojiElement.defaultSize * element.scale,
              ),
            ),
          ),
        ),
      );
    } else if (element is TextElement) {
      return Positioned(
        left: element.position.dx - 100,
        top: element.position.dy - 30,
        child: Transform.rotate(
          angle: element.rotation,
          child: Transform.scale(
            scale: element.scale,
            child: Container(
              constraints: const BoxConstraints(maxWidth: 200),
              decoration: BoxDecoration(
                color: element.backgroundColor,
                border: element.isSelected
                    ? Border.all(
                        color: Theme.of(context).colorScheme.primary,
                        width: 2,
                      )
                    : element.hasBorder
                    ? Border.all(color: element.textColor, width: 1)
                    : null,
                borderRadius: BorderRadius.circular(
                  element.hasBorder || element.isSelected ? 8 : 0,
                ),
              ),
              padding: EdgeInsets.all(
                element.backgroundColor != null ||
                        element.hasBorder ||
                        element.isSelected
                    ? 8
                    : 0,
              ),
              child: Text(
                element.text,
                style: TextStyle(
                  fontFamily: element.fontFamily,
                  fontSize: element.fontSize,
                  color: element.textColor,
                  fontWeight: element.fontWeight,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildDrawToolbar(ColorScheme colorScheme) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          // Background color button
          GestureDetector(
            onTap: _showBackgroundColorPicker,
            child: Container(
              width: 40,
              height: 40,
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                color: _backgroundColor,
                shape: BoxShape.circle,
                border: Border.all(color: colorScheme.outline, width: 1),
              ),
              child: Icon(
                Icons.format_color_fill_rounded,
                size: 20,
                color: _backgroundColor.computeLuminance() > 0.5
                    ? Colors.black54
                    : Colors.white70,
              ),
            ),
          ),
          Container(
            width: 1,
            height: 32,
            color: colorScheme.outline.withOpacity(0.3),
            margin: const EdgeInsets.only(right: 12),
          ),
          // Eraser button
          GestureDetector(
            onTap: () => setState(() => _isEraser = !_isEraser),
            child: Container(
              width: 40,
              height: 40,
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: _isEraser
                    ? colorScheme.primaryContainer
                    : colorScheme.surfaceContainerHighest,
                shape: BoxShape.circle,
                border: _isEraser
                    ? Border.all(color: colorScheme.primary, width: 2)
                    : null,
              ),
              child: Icon(
                Icons.auto_fix_normal_rounded,
                size: 20,
                color: _isEraser ? colorScheme.primary : colorScheme.onSurface,
              ),
            ),
          ),
          // Color buttons
          ...drawingColors.map((color) {
            final isSelected = color == _selectedColor && !_isEraser;
            return GestureDetector(
              onTap: () => setState(() {
                _selectedColor = color;
                _isEraser = false;
              }),
              child: Container(
                width: 36,
                height: 36,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected
                        ? colorScheme.primary
                        : (color == Colors.white
                              ? Colors.grey.shade300
                              : Colors.transparent),
                    width: isSelected ? 3 : 1,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: color.withOpacity(0.4),
                            blurRadius: 8,
                            spreadRadius: 1,
                          ),
                        ]
                      : null,
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildEmojiToolbar(ColorScheme colorScheme) {
    return Row(
      children: [
        Expanded(
          child: FilledButton.icon(
            onPressed: _showEmojiPicker,
            icon: const Icon(Icons.emoji_emotions_rounded),
            label: const Text('Add Emoji'),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
              backgroundColor: colorScheme.secondaryContainer,
              foregroundColor: colorScheme.onSecondaryContainer,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTextToolbar(ColorScheme colorScheme) {
    return Row(
      children: [
        Expanded(
          child: FilledButton.icon(
            onPressed: () => _showTextEditor(),
            icon: const Icon(Icons.text_fields_rounded),
            label: const Text('Add Text'),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
              backgroundColor: colorScheme.secondaryContainer,
              foregroundColor: colorScheme.onSecondaryContainer,
            ),
          ),
        ),
      ],
    );
  }
}

/// Custom painter that renders all drawing strokes
class _DrawingPainter extends CustomPainter {
  final List<DrawingStroke> strokes;
  final List<Offset> currentPoints;
  final Color currentColor;
  final double currentStrokeWidth;
  final Color backgroundColor;

  _DrawingPainter({
    required this.strokes,
    required this.currentPoints,
    required this.currentColor,
    required this.currentStrokeWidth,
    required this.backgroundColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Draw background
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = backgroundColor,
    );

    // Draw all completed strokes
    for (final stroke in strokes) {
      _drawStroke(canvas, stroke.points, stroke.color, stroke.strokeWidth);
    }

    // Draw current stroke being drawn
    if (currentPoints.isNotEmpty) {
      _drawStroke(canvas, currentPoints, currentColor, currentStrokeWidth);
    }
  }

  void _drawStroke(
    Canvas canvas,
    List<Offset> points,
    Color color,
    double width,
  ) {
    if (points.isEmpty) return;

    final paint = Paint()
      ..color = color
      ..strokeWidth = width
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    if (points.length == 1) {
      // Single point - draw a dot
      canvas.drawCircle(
        points.first,
        width / 2,
        paint..style = PaintingStyle.fill,
      );
    } else {
      // Multiple points - draw a smooth path
      final path = Path();
      path.moveTo(points.first.dx, points.first.dy);

      for (int i = 1; i < points.length - 1; i++) {
        final p0 = points[i];
        final p1 = points[i + 1];
        final midPoint = Offset((p0.dx + p1.dx) / 2, (p0.dy + p1.dy) / 2);
        path.quadraticBezierTo(p0.dx, p0.dy, midPoint.dx, midPoint.dy);
      }

      // Add the last point
      if (points.length > 1) {
        path.lineTo(points.last.dx, points.last.dy);
      }

      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _DrawingPainter oldDelegate) {
    return strokes != oldDelegate.strokes ||
        currentPoints != oldDelegate.currentPoints ||
        currentColor != oldDelegate.currentColor ||
        currentStrokeWidth != oldDelegate.currentStrokeWidth ||
        backgroundColor != oldDelegate.backgroundColor;
  }
}
