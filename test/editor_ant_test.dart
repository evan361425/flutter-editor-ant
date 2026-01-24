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

  group('Test case that actually cause error when startup', () {
    testWidgets('Press style button will focus on editor', (WidgetTester tester) async {
      await tester.pumpWidget(MyApp());
      await tester.pumpAndSettle();

      final field = tester.widget<TextField>(
        find.descendant(of: find.byKey(const Key('editor_ant.font_size_field')), matching: find.byType(TextField)),
      );
      final editorWidget = tester.widget<EditableText>(
        find.descendant(of: find.byKey(const Key('editor_ant.editor')), matching: find.byType(EditableText)),
      );

      field.focusNode!.requestFocus();
      await tester.pumpAndSettle();
      expect(field.focusNode!.hasFocus, isTrue);
      editorWidget.controller.selection = const TextSelection.collapsed(offset: -1);

      await tester.tap(find.byIcon(Icons.format_bold));
      await tester.pumpAndSettle();

      expect(editorWidget.focusNode.hasFocus, isTrue);
    });
    testWidgets('Should format text in collapsed selection', (WidgetTester tester) async {
      await tester.pumpWidget(MyApp());
      await tester.tap(find.byIcon(Icons.format_bold));
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('editor_ant.editor')), 'Hello World');
      await tester.pumpAndSettle();

      final textSpans = getTextSpans(tester);

      expect(textSpans.first.style?.fontWeight, equals(FontWeight.bold));
      expect((textSpans.first as TextSpan).text, equals('Hello World'));
    });
    testWidgets('Invalid selection should not cause errors', (WidgetTester tester) async {
      await tester.pumpWidget(MyApp());
      await tester.enterText(find.byKey(const Key('editor_ant.editor')), 'Hello');
      await tester.pumpAndSettle();

      final controller = getController(tester);
      controller.text = '${controller.text}World';
      await tester.pumpAndSettle();

      final textSpans = getTextSpans(tester);

      expect((textSpans.first as TextSpan).text, equals('HelloWorld'));
    });
    testWidgets('Use previous text as default style', (WidgetTester tester) async {
      await tester.pumpWidget(MyApp());
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('editor_ant.editor')), 'Hello');
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.format_bold));
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('editor_ant.editor')), 'HelloWorld');
      await tester.pumpAndSettle();

      expect(getTextSpans(tester).first.style?.fontWeight, isNull);
      expect(getTextSpans(tester)[1].style?.fontWeight, equals(FontWeight.bold));

      final controller = getController(tester);
      expect((controller.activeStyle.value as StyledText).isBold, isTrue);

      controller.selection = TextSelection.collapsed(offset: 6);
      await tester.pumpAndSettle();
      expect((controller.activeStyle.value as StyledText).isBold, isTrue);

      controller.selection = TextSelection.collapsed(offset: 5);
      await tester.pumpAndSettle();
      expect(controller.activeStyle.value, isNull);

      controller.selection = TextSelection.collapsed(offset: 4);
      await tester.pumpAndSettle();
      expect(controller.activeStyle.value, isNull);
    });
    group('Change style inside the styled text should merge styles', () {
      testWidgets('italic inside bold', (WidgetTester tester) async {
        await tester.pumpWidget(MyApp());
        await tester.tap(find.byIcon(Icons.format_bold));
        await tester.pumpAndSettle();

        await tester.enterText(find.byKey(const Key('editor_ant.editor')), 'HelloWorld');
        await tester.pumpAndSettle();

        final controller = getController(tester);
        controller.selection = const TextSelection(baseOffset: 2, extentOffset: 5);

        await tester.tap(find.byIcon(Icons.format_italic));
        await tester.pumpAndSettle();

        final textSpans = getTextSpans(tester);
        checkStyles(
          ['He', 'llo', 'World'],
          [
            const TextStyle(fontWeight: FontWeight.bold),
            const TextStyle(fontWeight: FontWeight.bold, fontStyle: FontStyle.italic),
            const TextStyle(fontWeight: FontWeight.bold),
          ],
          textSpans,
        );
      });
      testWidgets('font size left overwrite strikethrough', (WidgetTester tester) async {
        await tester.pumpWidget(MyApp());
        await tester.enterText(find.byKey(const Key('editor_ant.editor')), 'HelloWorld');
        await tester.pumpAndSettle();

        final controller = getController(tester);
        controller.selection = const TextSelection(baseOffset: 5, extentOffset: 10);

        await tester.tap(find.byIcon(Icons.strikethrough_s));
        await tester.pumpAndSettle();

        controller.selection = const TextSelection(baseOffset: 2, extentOffset: 7);

        final fontSizeField = find.descendant(
          of: find.byKey(const Key('editor_ant.font_size_field')),
          matching: find.byType(EditableText),
        );
        await tester.enterText(fontSizeField, '1');
        await tester.pumpAndSettle();
        await tester.enterText(fontSizeField, '12');
        await tester.pumpAndSettle();
        await tester.enterText(fontSizeField, '123');
        await tester.pumpAndSettle();
        await tester.tap(find.text('99'));
        await tester.pumpAndSettle();

        final textSpans = getTextSpans(tester);
        checkStyles(
          ['He', 'llo', 'Wo', 'rld'],
          [
            null,
            const TextStyle(fontSize: 99.0),
            const TextStyle(decoration: TextDecoration.lineThrough, fontSize: 99.0),
            const TextStyle(decoration: TextDecoration.lineThrough),
          ],
          textSpans,
        );
      });
      testWidgets('color right overwrite underline', (WidgetTester tester) async {
        await tester.pumpWidget(MyApp());
        await tester.enterText(find.byKey(const Key('editor_ant.editor')), 'HelloWorld');
        await tester.pumpAndSettle();

        final controller = getController(tester);
        controller.selection = const TextSelection(baseOffset: 2, extentOffset: 7);

        await tester.tap(find.byIcon(Icons.format_underline));
        await tester.pumpAndSettle();

        controller.selection = const TextSelection(baseOffset: 5, extentOffset: 10);

        await tester.tap(find.byIcon(Icons.format_color_text));
        await tester.pumpAndSettle();
        await tester.tap(find.byIcon(Icons.circle).first);
        await tester.pumpAndSettle();

        final textSpans = getTextSpans(tester);
        checkStyles(
          ['He', 'llo', 'Wo', 'rld'],
          [
            null,
            const TextStyle(decoration: TextDecoration.underline),
            const TextStyle(
              decoration: TextDecoration.underline,
              color: Colors.black87,
              decorationColor: Colors.black87,
            ),
            const TextStyle(color: Colors.black87, decorationColor: Colors.black87),
          ],
          textSpans,
        );
      });
    });
    testWidgets('Change same format (e.g. bold) will toggle it', (WidgetTester tester) async {
      await tester.pumpWidget(MyApp());
      await tester.tap(find.byIcon(Icons.format_bold));
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('editor_ant.editor')), 'HelloWorld');
      await tester.pumpAndSettle();

      final controller = getController(tester);
      controller.selection = const TextSelection(baseOffset: 2, extentOffset: 5);

      await tester.tap(find.byIcon(Icons.format_italic));
      await tester.pumpAndSettle();

      controller.selection = const TextSelection(baseOffset: 1, extentOffset: 9);

      await tester.tap(find.byIcon(Icons.format_bold));
      await tester.pumpAndSettle();

      final textSpans = getTextSpans(tester);
      checkStyles(
        ['H', 'e', 'llo', 'Worl', 'd'],
        [
          const TextStyle(fontWeight: FontWeight.bold),
          const TextStyle(),
          const TextStyle(fontStyle: FontStyle.italic),
          const TextStyle(),
          const TextStyle(fontWeight: FontWeight.bold),
        ],
        textSpans,
      );
    });
    testWidgets('Connected styles should be merged', (WidgetTester tester) async {
      await tester.pumpWidget(MyApp());
      await tester.tap(find.byIcon(Icons.format_bold));
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('editor_ant.editor')), 'HelloWorld');
      await tester.pumpAndSettle();

      final controller = getController(tester);
      controller.selection = const TextSelection(baseOffset: 2, extentOffset: 5);

      await tester.tap(find.byIcon(Icons.format_bold));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.format_bold));
      await tester.pumpAndSettle();

      final textSpans = getTextSpans(tester);
      checkStyles(['HelloWorld'], [const TextStyle(fontWeight: FontWeight.bold)], textSpans);
    });
    testWidgets('Use the styles in the selected range to determine the active style', (WidgetTester tester) async {
      await tester.pumpWidget(MyApp());
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('editor_ant.editor')), 'HelloWorld');
      await tester.pumpAndSettle();

      final controller = getController(tester);
      controller.selection = const TextSelection(baseOffset: 2, extentOffset: 5);

      await tester.tap(find.byIcon(Icons.format_bold));
      await tester.pumpAndSettle();

      final style = controller.activeStyle.value;
      expect(style, isA<StyledText>());
      expect((style as StyledText).isBold, isTrue);
      expect(controller.selection.start, equals(2));
      expect(controller.selection.end, equals(5));
    });
    testWidgets('Inside two styled text will be ok to toggle single style', (tester) async {
      await tester.pumpWidget(MyApp());
      await tester.tap(find.byIcon(Icons.format_bold));
      await tester.tap(find.byIcon(Icons.format_italic));
      await tester.enterText(find.byKey(const Key('editor_ant.editor')), 'HelloWorld');
      await tester.pumpAndSettle();

      final controller = getController(tester);
      controller.selection = const TextSelection(baseOffset: 3, extentOffset: 8);
      await tester.tap(find.byIcon(Icons.format_bold));
      await tester.pumpAndSettle();

      final textSpans = getTextSpans(tester);
      checkStyles(
        ['Hel', 'loWor', 'ld'],
        [
          const TextStyle(fontWeight: FontWeight.bold, fontStyle: FontStyle.italic),
          const TextStyle(fontStyle: FontStyle.italic),
          const TextStyle(fontWeight: FontWeight.bold, fontStyle: FontStyle.italic),
        ],
        textSpans,
      );
    });
  });

  group('Fulfill test coverage', () {
    testWidgets('Insert and delete text will move all styles', (WidgetTester tester) async {
      await tester.pumpWidget(MyApp());
      await tester.enterText(find.byKey(const Key('editor_ant.editor')), 'HelloWorld');
      await tester.pumpAndSettle();

      final controller = getController(tester);
      controller.selection = const TextSelection(baseOffset: 2, extentOffset: 3);
      await tester.tap(find.byIcon(Icons.format_bold));
      await tester.pumpAndSettle();
      controller.selection = const TextSelection(baseOffset: 4, extentOffset: 7);
      await tester.tap(find.byIcon(Icons.format_bold));
      await tester.pumpAndSettle();
      controller.selection = const TextSelection(baseOffset: 8, extentOffset: 9);
      await tester.tap(find.byIcon(Icons.format_bold));
      await tester.pumpAndSettle();

      await TestAsyncUtils.guard<void>(() async {
        await tester.showKeyboard(find.byKey(const Key('editor_ant.editor')));
        tester.testTextInput.updateEditingValue(
          TextEditingValue(text: 'Hello!World', selection: TextSelection.collapsed(offset: 6)),
        );
        await tester.idle();
      });
      await tester.pumpAndSettle();
      checkStyles(
        ['He', 'l', 'l', 'o!Wo', 'r', 'l', 'd'],
        [
          null,
          const TextStyle(fontWeight: FontWeight.bold),
          null,
          const TextStyle(fontWeight: FontWeight.bold),
          null,
          const TextStyle(fontWeight: FontWeight.bold),
          null,
        ],
        getTextSpans(tester),
      );

      await TestAsyncUtils.guard<void>(() async {
        await tester.showKeyboard(find.byKey(const Key('editor_ant.editor')));
        tester.testTextInput.updateEditingValue(
          TextEditingValue(text: 'Helloorld', selection: TextSelection.collapsed(offset: 5)),
        );
        await tester.idle();
      });
      await tester.pumpAndSettle();
      checkStyles(
        ['He', 'l', 'l', 'oo', 'r', 'l', 'd'],
        [
          null,
          const TextStyle(fontWeight: FontWeight.bold),
          null,
          const TextStyle(fontWeight: FontWeight.bold),
          null,
          const TextStyle(fontWeight: FontWeight.bold),
          null,
        ],
        getTextSpans(tester),
      );
    });
    testWidgets('Active style is in range and add collapsed style', (WidgetTester tester) async {
      await tester.pumpWidget(MyApp());
      await tester.enterText(find.byKey(const Key('editor_ant.editor')), 'HelloWorld');
      await tester.pumpAndSettle();

      final controller = getController(tester);
      controller.selection = const TextSelection(baseOffset: 2, extentOffset: 5);
      await tester.tap(find.byIcon(Icons.format_bold));
      await tester.pumpAndSettle();

      controller.addStyle(StyledText(range: TextRange.collapsed(5), isItalic: true));

      final textSpans = getTextSpans(tester);
      checkStyles(['He', 'llo', 'World'], [null, const TextStyle(fontWeight: FontWeight.bold), null], textSpans);
    });
    testWidgets('Should correctly render composing text', (WidgetTester tester) async {
      await tester.pumpWidget(MyApp());
      await tester.enterText(find.byKey(const Key('editor_ant.editor')), 'HelloWorld');
      await tester.pumpAndSettle();

      final controller = getController(tester);
      controller.value = TextEditingValue(
        text: 'HelloㄨㄛWorld',
        composing: const TextRange(start: 5, end: 7),
        selection: const TextSelection.collapsed(offset: 7),
      );
      await tester.pumpAndSettle();

      final textSpans = getTextSpans(tester);
      expect(textSpans[1].style?.decoration, equals(TextDecoration.underline));
    });
    testWidgets('Active style should combine both styles', (WidgetTester tester) async {
      await tester.pumpWidget(MyApp());
      await tester.tap(find.byIcon(Icons.format_bold));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('editor_ant.editor')), 'HelloWorld');
      await tester.pumpAndSettle();

      final controller = getController(tester);
      controller.selection = const TextSelection(baseOffset: 0, extentOffset: 5);
      await tester.tap(find.byIcon(Icons.format_italic));
      await tester.pumpAndSettle();

      controller.selection = const TextSelection(baseOffset: 0, extentOffset: 10);
      final style = controller.activeStyle.value;
      expect(style, isA<StyledText>());
      expect((style as StyledText).isBold, isTrue);
      expect(style.isItalic, isFalse);
    });
  });
}
