import 'dart:io';
import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';

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

  Color _selectedColor = Colors.black;
  BrushSize _selectedBrushSize = BrushSize.medium;
  Color _backgroundColor = Colors.white;
  bool _isEraser = false;
  bool _isSaving = false;

  void _onPanStart(DragStartDetails details) {
    setState(() {
      _currentPoints = [details.localPosition];
    });
  }

  void _onPanUpdate(DragUpdateDetails details) {
    setState(() {
      _currentPoints = [..._currentPoints, details.localPosition];
    });
  }

  void _onPanEnd(DragEndDetails details) {
    if (_currentPoints.isNotEmpty) {
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

  void _undo() {
    if (_strokes.isNotEmpty) {
      setState(() {
        _strokes.removeLast();
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
              });
              Navigator.pop(context);
            },
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }

  Future<void> _saveDrawing() async {
    if (_strokes.isEmpty) {
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
          IconButton(
            icon: const Icon(Icons.undo_rounded),
            onPressed: _strokes.isEmpty ? null : _undo,
            tooltip: 'Undo',
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded),
            onPressed: _strokes.isEmpty ? null : _clearCanvas,
            tooltip: 'Clear All',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // Canvas Area
          Expanded(
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
                    onPanStart: _onPanStart,
                    onPanUpdate: _onPanUpdate,
                    onPanEnd: _onPanEnd,
                    child: CustomPaint(
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
                // Color Palette Row
                SingleChildScrollView(
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
                            border: Border.all(
                              color: colorScheme.outline,
                              width: 1,
                            ),
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
                                ? Border.all(
                                    color: colorScheme.primary,
                                    width: 2,
                                  )
                                : null,
                          ),
                          child: Icon(
                            Icons.auto_fix_normal_rounded,
                            size: 20,
                            color: _isEraser
                                ? colorScheme.primary
                                : colorScheme.onSurface,
                          ),
                        ),
                      ),
                      // Color buttons
                      ...drawingColors.map((color) {
                        final isSelected =
                            color == _selectedColor && !_isEraser;
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
                ),

                const SizedBox(height: 16),

                // Brush Size and Save Row
                Row(
                  children: [
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
                            return GestureDetector(
                              onTap: () =>
                                  setState(() => _selectedBrushSize = size),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
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
                                    const SizedBox(width: 6),
                                    Text(
                                      size.label,
                                      style: TextStyle(
                                        color: isSelected
                                            ? Colors.white
                                            : colorScheme.onSurface,
                                        fontWeight: isSelected
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),

                    const SizedBox(width: 12),

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
