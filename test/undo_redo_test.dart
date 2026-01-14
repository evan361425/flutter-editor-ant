import 'package:editor_ant/editor_ant.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// ignore: avoid_relative_lib_imports
import '../example/lib/main.dart';

void main() {
  List<InlineSpan> getTextSpans(WidgetTester tester) {
    final editor = tester.state<EditableTextState>(
      find.descendant(of: find.byKey(const Key('editor_ant.editor')), matching: find.byType(EditableText)),
    );
    final textSpan = editor.renderEditable.text;
    expect(textSpan, isA<TextSpan>());

    final textSpans = (textSpan as TextSpan).children;
    expect(textSpans, isNotNull);

    return textSpans!;
  }

  StyledEditingController getController(WidgetTester tester) {
    final editorWidget = tester.widget<EditableText>(
      find.descendant(of: find.byKey(const Key('editor_ant.editor')), matching: find.byType(EditableText)),
    );
    return editorWidget.controller as StyledEditingController;
  }

  void checkStyles(List<String> texts, List<TextStyle?> styles, List<InlineSpan> spans) {
    assert(spans.length == texts.length, 'spans length ${spans.length} not expected: $spans');
    for (var i = 0; i < texts.length; i++) {
      final span = spans[i] as TextSpan;
      expect(span.text, equals(texts[i]));
      if (styles[i] != null && styles[i]!.decoration == null) {
        styles[i] = styles[i]!.copyWith(decoration: TextDecoration.none);
      }
      expect(span.style, equals(styles[i]), reason: 'index $i style ${span.style} not expected: ${styles[i]}');
    }
  }

  EditorAntConfig.enableLogging = true;

  group('Undo/Redo functionality', () {
    testWidgets('Undo single bold style', (WidgetTester tester) async {
      await tester.pumpWidget(MyApp());
      await tester.enterText(find.byKey(const Key('editor_ant.editor')), 'HelloWorld');
      await tester.pumpAndSettle();

      final controller = getController(tester);

      // Select text and make it bold
      controller.selection = const TextSelection(baseOffset: 0, extentOffset: 5);
      await tester.tap(find.byIcon(Icons.format_bold));
      await tester.pumpAndSettle();

      // Verify bold is applied
      var textSpans = getTextSpans(tester);
      checkStyles(['Hello', 'World'], [const TextStyle(fontWeight: FontWeight.bold), null], textSpans);

      // Undo the bold
      expect(controller.canUndo(), isTrue);
      controller.undo();
      await tester.pumpAndSettle();

      // Verify bold is removed
      textSpans = getTextSpans(tester);
      checkStyles(['HelloWorld'], [null], textSpans);

      // Verify can't undo further
      expect(controller.canUndo(), isFalse);
    });

    testWidgets('Redo single bold style', (WidgetTester tester) async {
      await tester.pumpWidget(MyApp());
      await tester.enterText(find.byKey(const Key('editor_ant.editor')), 'HelloWorld');
      await tester.pumpAndSettle();

      final controller = getController(tester);

      // Select text and make it bold
      controller.selection = const TextSelection(baseOffset: 0, extentOffset: 5);
      await tester.tap(find.byIcon(Icons.format_bold));
      await tester.pumpAndSettle();

      // Undo the bold
      controller.undo();
      await tester.pumpAndSettle();

      // Redo the bold
      expect(controller.canRedo(), isTrue);
      controller.redo();
      await tester.pumpAndSettle();

      // Verify bold is reapplied
      var textSpans = getTextSpans(tester);
      checkStyles(['Hello', 'World'], [const TextStyle(fontWeight: FontWeight.bold), null], textSpans);

      // Verify can't redo further
      expect(controller.canRedo(), isFalse);
    });

    testWidgets('Undo multiple styling operations', (WidgetTester tester) async {
      await tester.pumpWidget(MyApp());
      await tester.enterText(find.byKey(const Key('editor_ant.editor')), 'HelloWorld');
      await tester.pumpAndSettle();

      final controller = getController(tester);

      // First operation: bold
      controller.selection = const TextSelection(baseOffset: 0, extentOffset: 5);
      await tester.tap(find.byIcon(Icons.format_bold));
      await tester.pumpAndSettle();

      // Second operation: italic on same text
      controller.selection = const TextSelection(baseOffset: 2, extentOffset: 5);
      await tester.tap(find.byIcon(Icons.format_italic));
      await tester.pumpAndSettle();

      // Verify both styles applied
      var textSpans = getTextSpans(tester);
      checkStyles(
        ['He', 'llo', 'World'],
        [
          const TextStyle(fontWeight: FontWeight.bold),
          const TextStyle(fontWeight: FontWeight.bold, fontStyle: FontStyle.italic),
          null,
        ],
        textSpans,
      );

      // Undo italic
      controller.undo();
      await tester.pumpAndSettle();

      textSpans = getTextSpans(tester);
      checkStyles(['Hello', 'World'], [const TextStyle(fontWeight: FontWeight.bold), null], textSpans);

      // Undo bold
      controller.undo();
      await tester.pumpAndSettle();

      textSpans = getTextSpans(tester);
      checkStyles(['HelloWorld'], [null], textSpans);
    });

    testWidgets('Redo clears forward history after new change', (WidgetTester tester) async {
      await tester.pumpWidget(MyApp());
      await tester.enterText(find.byKey(const Key('editor_ant.editor')), 'HelloWorld');
      await tester.pumpAndSettle();

      final controller = getController(tester);

      // Make text bold
      controller.selection = const TextSelection(baseOffset: 0, extentOffset: 5);
      await tester.tap(find.byIcon(Icons.format_bold));
      await tester.pumpAndSettle();

      // Undo
      controller.undo();
      await tester.pumpAndSettle();

      // Make text italic (new change should clear redo history)
      controller.selection = const TextSelection(baseOffset: 0, extentOffset: 5);
      await tester.tap(find.byIcon(Icons.format_italic));
      await tester.pumpAndSettle();

      // Verify can't redo bold anymore
      expect(controller.canRedo(), isFalse);

      // Verify italic is applied
      var textSpans = getTextSpans(tester);
      checkStyles(['Hello', 'World'], [const TextStyle(fontStyle: FontStyle.italic), null], textSpans);
    });

    testWidgets('Undo/redo with toggle behavior', (WidgetTester tester) async {
      await tester.pumpWidget(MyApp());
      await tester.enterText(find.byKey(const Key('editor_ant.editor')), 'HelloWorld');
      await tester.pumpAndSettle();

      final controller = getController(tester);

      // Make text bold
      controller.selection = const TextSelection(baseOffset: 0, extentOffset: 5);
      await tester.tap(find.byIcon(Icons.format_bold));
      await tester.pumpAndSettle();

      // Toggle bold off (same selection)
      await tester.tap(find.byIcon(Icons.format_bold));
      await tester.pumpAndSettle();

      // Verify bold is removed
      var textSpans = getTextSpans(tester);
      checkStyles(['HelloWorld'], [null], textSpans);

      // Undo the toggle (should restore bold)
      controller.undo();
      await tester.pumpAndSettle();

      textSpans = getTextSpans(tester);
      checkStyles(['Hello', 'World'], [const TextStyle(fontWeight: FontWeight.bold), null], textSpans);
    });

    testWidgets('Undo/redo maintains correct state across multiple operations', (WidgetTester tester) async {
      await tester.pumpWidget(MyApp());
      await tester.enterText(find.byKey(const Key('editor_ant.editor')), 'HelloWorld');
      await tester.pumpAndSettle();

      final controller = getController(tester);

      // Operation 1: Bold on "Hello"
      controller.selection = const TextSelection(baseOffset: 0, extentOffset: 5);
      await tester.tap(find.byIcon(Icons.format_bold));
      await tester.pumpAndSettle();

      // Operation 2: Underline on "World"
      controller.selection = const TextSelection(baseOffset: 5, extentOffset: 10);
      await tester.tap(find.byIcon(Icons.format_underline));
      await tester.pumpAndSettle();

      // Operation 3: Italic on "lo"
      controller.selection = const TextSelection(baseOffset: 3, extentOffset: 5);
      await tester.tap(find.byIcon(Icons.format_italic));
      await tester.pumpAndSettle();

      // Verify all styles
      var textSpans = getTextSpans(tester);
      checkStyles(
        ['Hel', 'lo', 'World'],
        [
          const TextStyle(fontWeight: FontWeight.bold),
          const TextStyle(fontWeight: FontWeight.bold, fontStyle: FontStyle.italic),
          const TextStyle(decoration: TextDecoration.underline),
        ],
        textSpans,
      );

      // Undo operation 3
      controller.undo();
      await tester.pumpAndSettle();
      textSpans = getTextSpans(tester);
      checkStyles(
        ['Hello', 'World'],
        [const TextStyle(fontWeight: FontWeight.bold), const TextStyle(decoration: TextDecoration.underline)],
        textSpans,
      );

      // Undo operation 2
      controller.undo();
      await tester.pumpAndSettle();
      textSpans = getTextSpans(tester);
      checkStyles(['Hello', 'World'], [const TextStyle(fontWeight: FontWeight.bold), null], textSpans);

      // Redo operation 2
      controller.redo();
      await tester.pumpAndSettle();
      textSpans = getTextSpans(tester);
      checkStyles(
        ['Hello', 'World'],
        [const TextStyle(fontWeight: FontWeight.bold), const TextStyle(decoration: TextDecoration.underline)],
        textSpans,
      );

      // Redo operation 3
      controller.redo();
      await tester.pumpAndSettle();
      textSpans = getTextSpans(tester);
      checkStyles(
        ['Hel', 'lo', 'World'],
        [
          const TextStyle(fontWeight: FontWeight.bold),
          const TextStyle(fontWeight: FontWeight.bold, fontStyle: FontStyle.italic),
          const TextStyle(decoration: TextDecoration.underline),
        ],
        textSpans,
      );
    });

    testWidgets('canUndo and canRedo return correct values', (WidgetTester tester) async {
      await tester.pumpWidget(MyApp());
      await tester.enterText(find.byKey(const Key('editor_ant.editor')), 'HelloWorld');
      await tester.pumpAndSettle();

      final controller = getController(tester);

      // Initially no undo/redo available
      expect(controller.canUndo(), isFalse);
      expect(controller.canRedo(), isFalse);

      // Make a change
      controller.selection = const TextSelection(baseOffset: 0, extentOffset: 5);
      await tester.tap(find.byIcon(Icons.format_bold));
      await tester.pumpAndSettle();

      // Can undo, but not redo
      expect(controller.canUndo(), isTrue);
      expect(controller.canRedo(), isFalse);

      // Undo
      controller.undo();
      await tester.pumpAndSettle();

      // Can't undo further, but can redo
      expect(controller.canUndo(), isFalse);
      expect(controller.canRedo(), isTrue);

      // Redo
      controller.redo();
      await tester.pumpAndSettle();

      // Can undo again, but not redo
      expect(controller.canUndo(), isTrue);
      expect(controller.canRedo(), isFalse);
    });
  });
}
