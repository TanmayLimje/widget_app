import 'package:flutter/material.dart';
import 'dart:math' as math;

/// Base class for all canvas elements (emoji, text)
abstract class CanvasElement {
  final String id;
  Offset position;
  double scale;
  double rotation; // in radians
  bool isSelected;

  CanvasElement({
    String? id,
    required this.position,
    this.scale = 1.0,
    this.rotation = 0.0,
    this.isSelected = false,
  }) : id = id ?? _generateId();

  static String _generateId() {
    return '${DateTime.now().millisecondsSinceEpoch}_${math.Random().nextInt(10000)}';
  }

  /// Get the bounding box for hit testing
  Rect getBounds(Size elementSize) {
    final width = elementSize.width * scale;
    final height = elementSize.height * scale;
    return Rect.fromCenter(center: position, width: width, height: height);
  }

  /// Check if a point hits this element
  bool containsPoint(Offset point, Size elementSize) {
    final bounds = getBounds(elementSize);
    // For rotated elements, we need to transform the point
    if (rotation != 0) {
      final center = position;
      final cos = math.cos(-rotation);
      final sin = math.sin(-rotation);
      final dx = point.dx - center.dx;
      final dy = point.dy - center.dy;
      final rotatedPoint = Offset(
        dx * cos - dy * sin + center.dx,
        dx * sin + dy * cos + center.dy,
      );
      return bounds.contains(rotatedPoint);
    }
    return bounds.contains(point);
  }

  CanvasElement copyWith();
}

/// Emoji element for the canvas
class EmojiElement extends CanvasElement {
  final String emoji;

  EmojiElement({
    super.id,
    required super.position,
    super.scale = 1.0,
    super.rotation = 0.0,
    super.isSelected = false,
    required this.emoji,
  });

  /// Default size for emoji rendering
  static const double defaultSize = 48.0;

  Size get size => Size(defaultSize * scale, defaultSize * scale);

  @override
  EmojiElement copyWith({
    String? id,
    Offset? position,
    double? scale,
    double? rotation,
    bool? isSelected,
    String? emoji,
  }) {
    return EmojiElement(
      id: id ?? this.id,
      position: position ?? this.position,
      scale: scale ?? this.scale,
      rotation: rotation ?? this.rotation,
      isSelected: isSelected ?? this.isSelected,
      emoji: emoji ?? this.emoji,
    );
  }
}

/// Text element with styling options
class TextElement extends CanvasElement {
  final String text;
  final String fontFamily;
  final double fontSize;
  final Color textColor;
  final Color? backgroundColor;
  final bool hasBorder;
  final FontWeight fontWeight;

  TextElement({
    super.id,
    required super.position,
    super.scale = 1.0,
    super.rotation = 0.0,
    super.isSelected = false,
    required this.text,
    this.fontFamily = 'Roboto',
    this.fontSize = 24.0,
    this.textColor = Colors.black,
    this.backgroundColor,
    this.hasBorder = false,
    this.fontWeight = FontWeight.normal,
  });

  @override
  TextElement copyWith({
    String? id,
    Offset? position,
    double? scale,
    double? rotation,
    bool? isSelected,
    String? text,
    String? fontFamily,
    double? fontSize,
    Color? textColor,
    Color? backgroundColor,
    bool? clearBackground,
    bool? hasBorder,
    FontWeight? fontWeight,
  }) {
    return TextElement(
      id: id ?? this.id,
      position: position ?? this.position,
      scale: scale ?? this.scale,
      rotation: rotation ?? this.rotation,
      isSelected: isSelected ?? this.isSelected,
      text: text ?? this.text,
      fontFamily: fontFamily ?? this.fontFamily,
      fontSize: fontSize ?? this.fontSize,
      textColor: textColor ?? this.textColor,
      backgroundColor: clearBackground == true
          ? null
          : (backgroundColor ?? this.backgroundColor),
      hasBorder: hasBorder ?? this.hasBorder,
      fontWeight: fontWeight ?? this.fontWeight,
    );
  }
}

/// Available font families for text elements
const List<String> availableFonts = [
  'Roboto',
  'serif',
  'monospace',
  'cursive',
  'sans-serif',
];

/// Popular emojis for the picker
const List<String> popularEmojis = [
  // Smileys & Emotion
  '😀', '😃', '😄', '😁', '😆', '😅', '🤣', '😂',
  '🙂', '😊', '😇', '🥰', '😍', '🤩', '😘', '😗',
  '😜', '😝', '😛', '🤑', '🤗', '🤭', '🤔', '🤐',
  // Hearts & Symbols
  '❤️', '🧡', '💛', '💚', '💙', '💜', '🖤', '🤍',
  '💕', '💞', '💓', '💗', '💖', '💘', '💝', '✨',
  // Gestures
  '👍', '👎', '👌', '✌️', '🤞', '🤟', '🤘', '🤙',
  '👋', '🙌', '👏', '🤝', '🙏', '💪', '🎉', '🔥',
];

/// Text colors palette
const List<Color> textColors = [
  Colors.black,
  Colors.white,
  Color(0xFF6366F1), // Purple
  Color(0xFF3B82F6), // Blue
  Color(0xFF10B981), // Green
  Color(0xFFF97316), // Orange
  Color(0xFFEC4899), // Pink
  Color(0xFFEF4444), // Red
];

/// Background colors for text (with null = no background)
const List<Color?> textBackgroundColors = [
  null, // No background
  Colors.white,
  Colors.black,
  Color(0xFFFEF3C7), // Amber
  Color(0xFFDCFCE7), // Green
  Color(0xFFDBEAFE), // Blue
  Color(0xFFFCE7F3), // Pink
];
