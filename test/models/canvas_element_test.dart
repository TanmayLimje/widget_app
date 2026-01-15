import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'dart:math' as math;
import 'package:aantan/models/canvas_element.dart';

void main() {
  group('EmojiElement', () {
    test('creates with required parameters', () {
      final element = EmojiElement(
        position: const Offset(100, 100),
        emoji: '😀',
      );

      expect(element.position, const Offset(100, 100));
      expect(element.emoji, '😀');
      expect(element.scale, 1.0);
      expect(element.rotation, 0.0);
      expect(element.isSelected, false);
      expect(element.id, isNotEmpty);
    });

    test('creates with all parameters', () {
      final element = EmojiElement(
        id: 'test-id',
        position: const Offset(200, 300),
        emoji: '❤️',
        scale: 2.0,
        rotation: math.pi / 4,
        isSelected: true,
      );

      expect(element.id, 'test-id');
      expect(element.position, const Offset(200, 300));
      expect(element.emoji, '❤️');
      expect(element.scale, 2.0);
      expect(element.rotation, math.pi / 4);
      expect(element.isSelected, true);
    });

    test('size scales correctly', () {
      final element = EmojiElement(
        position: const Offset(0, 0),
        emoji: '😀',
        scale: 2.0,
      );

      expect(element.size, const Size(96.0, 96.0)); // 48 * 2
    });

    test('copyWith creates new instance with overridden values', () {
      final original = EmojiElement(
        id: 'original-id',
        position: const Offset(100, 100),
        emoji: '😀',
        scale: 1.0,
      );

      final copied = original.copyWith(
        position: const Offset(200, 200),
        emoji: '🎉',
        scale: 1.5,
      );

      // Original unchanged
      expect(original.position, const Offset(100, 100));
      expect(original.emoji, '😀');
      expect(original.scale, 1.0);

      // Copy has new values
      expect(copied.id, 'original-id'); // ID preserved
      expect(copied.position, const Offset(200, 200));
      expect(copied.emoji, '🎉');
      expect(copied.scale, 1.5);
    });

    test('copyWith with no arguments returns identical values', () {
      final original = EmojiElement(
        id: 'test-id',
        position: const Offset(50, 50),
        emoji: '👍',
        scale: 1.2,
        rotation: 0.5,
        isSelected: true,
      );

      final copied = original.copyWith();

      expect(copied.id, original.id);
      expect(copied.position, original.position);
      expect(copied.emoji, original.emoji);
      expect(copied.scale, original.scale);
      expect(copied.rotation, original.rotation);
      expect(copied.isSelected, original.isSelected);
    });
  });

  group('TextElement', () {
    test('creates with required parameters', () {
      final element = TextElement(
        position: const Offset(100, 100),
        text: 'Hello World',
      );

      expect(element.position, const Offset(100, 100));
      expect(element.text, 'Hello World');
      expect(element.fontFamily, 'Roboto');
      expect(element.fontSize, 24.0);
      expect(element.textColor, Colors.black);
      expect(element.backgroundColor, isNull);
      expect(element.hasBorder, false);
      expect(element.fontWeight, FontWeight.normal);
    });

    test('creates with all parameters', () {
      final element = TextElement(
        id: 'text-id',
        position: const Offset(150, 150),
        text: 'Styled Text',
        fontFamily: 'serif',
        fontSize: 32.0,
        textColor: Colors.red,
        backgroundColor: Colors.yellow,
        hasBorder: true,
        fontWeight: FontWeight.bold,
        scale: 1.5,
        rotation: math.pi / 6,
        isSelected: true,
      );

      expect(element.id, 'text-id');
      expect(element.text, 'Styled Text');
      expect(element.fontFamily, 'serif');
      expect(element.fontSize, 32.0);
      expect(element.textColor, Colors.red);
      expect(element.backgroundColor, Colors.yellow);
      expect(element.hasBorder, true);
      expect(element.fontWeight, FontWeight.bold);
      expect(element.scale, 1.5);
      expect(element.rotation, math.pi / 6);
      expect(element.isSelected, true);
    });

    test('copyWith creates new instance with overridden values', () {
      final original = TextElement(
        position: const Offset(0, 0),
        text: 'Original',
        textColor: Colors.black,
      );

      final copied = original.copyWith(
        text: 'Modified',
        textColor: Colors.blue,
        backgroundColor: Colors.white,
      );

      // Original unchanged
      expect(original.text, 'Original');
      expect(original.textColor, Colors.black);
      expect(original.backgroundColor, isNull);

      // Copy has new values
      expect(copied.text, 'Modified');
      expect(copied.textColor, Colors.blue);
      expect(copied.backgroundColor, Colors.white);
    });

    test('copyWith with clearBackground removes background', () {
      final original = TextElement(
        position: const Offset(0, 0),
        text: 'With Background',
        backgroundColor: Colors.yellow,
      );

      final copied = original.copyWith(clearBackground: true);

      expect(original.backgroundColor, Colors.yellow);
      expect(copied.backgroundColor, isNull);
    });
  });

  group('CanvasElement hit testing', () {
    test('getBounds returns correct bounding box', () {
      final element = EmojiElement(
        position: const Offset(100, 100),
        emoji: '😀',
        scale: 1.0,
      );

      final bounds = element.getBounds(const Size(48, 48));

      // Centered at (100, 100) with size 48x48
      expect(bounds.left, 76.0); // 100 - 24
      expect(bounds.top, 76.0);
      expect(bounds.right, 124.0); // 100 + 24
      expect(bounds.bottom, 124.0);
    });

    test('getBounds scales correctly', () {
      final element = EmojiElement(
        position: const Offset(100, 100),
        emoji: '😀',
        scale: 2.0,
      );

      final bounds = element.getBounds(const Size(48, 48));

      // Centered at (100, 100) with scaled size 96x96
      expect(bounds.left, 52.0); // 100 - 48
      expect(bounds.top, 52.0);
      expect(bounds.right, 148.0); // 100 + 48
      expect(bounds.bottom, 148.0);
    });

    test('containsPoint returns true for point inside element', () {
      final element = EmojiElement(
        position: const Offset(100, 100),
        emoji: '😀',
        scale: 1.0,
      );

      expect(
        element.containsPoint(const Offset(100, 100), const Size(48, 48)),
        isTrue,
      );
      expect(
        element.containsPoint(const Offset(80, 80), const Size(48, 48)),
        isTrue,
      );
      expect(
        element.containsPoint(const Offset(120, 120), const Size(48, 48)),
        isTrue,
      );
    });

    test('containsPoint returns false for point outside element', () {
      final element = EmojiElement(
        position: const Offset(100, 100),
        emoji: '😀',
        scale: 1.0,
      );

      expect(
        element.containsPoint(const Offset(0, 0), const Size(48, 48)),
        isFalse,
      );
      expect(
        element.containsPoint(const Offset(200, 200), const Size(48, 48)),
        isFalse,
      );
      expect(
        element.containsPoint(const Offset(150, 100), const Size(48, 48)),
        isFalse,
      );
    });

    test('containsPoint handles rotation correctly', () {
      final element = EmojiElement(
        position: const Offset(100, 100),
        emoji: '😀',
        scale: 1.0,
        rotation: math.pi / 4, // 45 degrees
      );

      // Center should always be inside regardless of rotation
      expect(
        element.containsPoint(const Offset(100, 100), const Size(48, 48)),
        isTrue,
      );
    });
  });

  group('Canvas constants', () {
    test('availableFonts contains expected fonts', () {
      expect(availableFonts, contains('Roboto'));
      expect(availableFonts, contains('serif'));
      expect(availableFonts, contains('monospace'));
      expect(availableFonts.length, greaterThan(0));
    });

    test('popularEmojis is not empty', () {
      expect(popularEmojis, isNotEmpty);
      expect(popularEmojis, contains('😀'));
      expect(popularEmojis, contains('❤️'));
    });

    test('textColors contains expected colors', () {
      expect(textColors, contains(Colors.black));
      expect(textColors, contains(Colors.white));
      expect(textColors.length, greaterThan(0));
    });

    test('textBackgroundColors contains null for transparent option', () {
      expect(textBackgroundColors, contains(null));
      expect(textBackgroundColors, contains(Colors.white));
    });
  });
}
