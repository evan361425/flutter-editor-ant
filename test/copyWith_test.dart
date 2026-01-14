import 'package:editor_ant/editor_ant.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('copyWith() without parameters creates proper deep copy', () {
    // Create a style
    final original = StyledText(
      range: const TextRange(start: 0, end: 5),
      isBold: true,
      isItalic: false,
      fontSize: 16,
      color: Colors.red,
    );

    // Copy without parameters
    final copy = original.copyWith();

    // Verify properties are preserved
    expect(copy.range.start, equals(original.range.start));
    expect(copy.range.end, equals(original.range.end));
    expect(copy.isBold, equals(original.isBold));
    expect(copy.isItalic, equals(original.isItalic));
    expect(copy.fontSize, equals(original.fontSize));
    expect(copy.color, equals(original.color));

    // Verify they are different objects
    expect(identical(copy, original), isFalse);
    expect(identical(copy.range, original.range), isFalse);
  });

  test('undo/redo maintains style properties correctly', () {
    final controller = StyledEditingController<StyledText>();
    controller.text = 'Hello World';

    // Add bold style
    controller.addStyle(StyledText(
      range: const TextRange(start: 0, end: 5),
      isBold: true,
    ));

    // Verify style is applied
    expect(controller.styles.length, equals(1));
    expect(controller.styles[0].isBold, isTrue);
    expect(controller.styles[0].range.start, equals(0));
    expect(controller.styles[0].range.end, equals(5));

    // Add italic style
    controller.addStyle(StyledText(
      range: const TextRange(start: 2, end: 7),
      isItalic: true,
    ));

    // Verify both styles exist
    expect(controller.styles.length, equals(3)); // Bold (0-2), Bold+Italic (2-5), Italic (5-7)

    // Undo italic
    controller.undo();

    // Verify we're back to just bold
    expect(controller.styles.length, equals(1));
    expect(controller.styles[0].isBold, isTrue);
    expect(controller.styles[0].isItalic, isFalse);
    expect(controller.styles[0].range.start, equals(0));
    expect(controller.styles[0].range.end, equals(5));

    // Redo italic
    controller.redo();

    // Verify both styles are back
    expect(controller.styles.length, equals(3));

    controller.dispose();
  });

  test('history does not share references with current styles', () {
    final controller = StyledEditingController<StyledText>();
    controller.text = 'Hello World';

    // Add a style
    controller.addStyle(StyledText(
      range: const TextRange(start: 0, end: 5),
      isBold: true,
    ));

    // Get reference to the style
    final currentStyle = controller.styles[0];

    // Modify the range directly (simulate mutation)
    currentStyle.range = const TextRange(start: 0, end: 10);

    // Undo should restore the original range, not the mutated one
    controller.undo();
    controller.redo();

    // The restored style should have the original range
    expect(controller.styles[0].range.end, equals(5), 
      reason: 'History should preserve original values, not mutations');

    controller.dispose();
  });
}
