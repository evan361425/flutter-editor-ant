import 'package:editor_ant/editor_ant.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('StyledText', () {
    test('toggle all properties', () {
      final style = StyledText(
        range: TextRange.empty,
        isBold: true,
        isItalic: true,
        isStrikethrough: true,
        isUnderline: true,
      );
      final result = style.toggleWith(
        StyledText(range: TextRange.empty, isBold: true, isItalic: true, isStrikethrough: true, isUnderline: true),
      );

      expect(result.isBold, isFalse);
      expect(result.isItalic, isFalse);
      expect(result.isStrikethrough, isFalse);
      expect(result.isUnderline, isFalse);
    });
    test('has same toggle state return fast if any property same', () {
      final style = StyledText(range: TextRange.empty);

      expect(style.copyWith(isBold: true).hasSameToggleState(StyledText(range: TextRange.empty, isBold: true)), isTrue);
      expect(
        style.copyWith(isItalic: true).hasSameToggleState(StyledText(range: TextRange.empty, isItalic: true)),
        isTrue,
      );
      expect(
        style
            .copyWith(isStrikethrough: true)
            .hasSameToggleState(StyledText(range: TextRange.empty, isStrikethrough: true)),
        isTrue,
      );
      expect(
        style.copyWith(isUnderline: true).hasSameToggleState(StyledText(range: TextRange.empty, isUnderline: true)),
        isTrue,
      );
    });
    test('hashCode', () {
      expect(
        StyledText(
              range: TextRange.empty,
              isBold: true,
              isItalic: true,
              isStrikethrough: true,
              isUnderline: true,
            ).hashCode !=
            StyledText(
              range: TextRange.empty,
              isBold: true,
              isItalic: true,
              isStrikethrough: true,
              isUnderline: false,
            ).hashCode,
        isTrue,
      );
    });
  });

  group('Buttons', () {
    testWidgets('ToggleableButton with onPressed', (tester) async {
      bool isPressed = false;
      bool onPressed() => isPressed = true;

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(splashFactory: InkRipple.splashFactory),
          home: Scaffold(
            body: SizedBox(
              width: 100,
              height: 100,
              child: BoldButton(onPressed: onPressed, value: ValueNotifier(null)),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.format_bold));
      await tester.pumpAndSettle();

      expect(isPressed, isTrue);
    });
    testWidgets('FondSizeField submit', (tester) async {
      final controller = TextEditingController(text: '16');
      final styledEditingController = StyledEditingController<StyledText>();
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(splashFactory: InkRipple.splashFactory),
          home: Scaffold(
            body: SizedBox(
              width: 100,
              height: 100,
              child: FontSizeField(
                key: const Key('font_size_field'),
                controller: controller,
                styledTextController: styledEditingController,
              ),
            ),
          ),
        ),
      );

      await tester.enterText(find.byKey(const Key('font_size_field')), '20');
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();

      expect(controller.value.text, equals('16'));

      await tester.enterText(find.byKey(const Key('font_size_field')), '22');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      expect(styledEditingController.activeStyle.value?.fontSize, equals(22));
    });
    testWidgets('FondSizeField change controller', (tester) async {
      final controller = TextEditingController(text: '16');
      final oldController = StyledEditingController<StyledText>(text: 'test');
      final newController = StyledEditingController<StyledText>(text: 'test2');
      final toggler = ValueNotifier(oldController);
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(splashFactory: InkRipple.splashFactory),
          home: Scaffold(
            body: ValueListenableBuilder(
              valueListenable: toggler,
              builder: (context, value, child) {
                return SizedBox(
                  width: 100,
                  height: 100,
                  child: FontSizeField(
                    key: const Key('font_size_field'),
                    controller: controller,
                    styledTextController: value,
                  ),
                );
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      toggler.value = newController;
      await tester.pumpAndSettle();

      expect(newController.activeStyle.value, isNull);
    });
    testWidgets('TextAlign', (tester) async {
      final value = ValueNotifier<TextAlign>(TextAlign.left);
      final controller = MenuController();

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(splashFactory: InkRipple.splashFactory),
          home: Scaffold(
            body: SizedBox.fromSize(
              size: const Size(300, 100),
              child: TextAlignSelector(
                value: value,
                controller: controller,
                alignments: const [TextAlign.left, TextAlign.center, TextAlign.right, TextAlign.justify],
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.format_align_left));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.format_align_right));
      await tester.pumpAndSettle();

      expect(value.value, TextAlign.right);
    });
    testWidgets('ColorSelector', (tester) async {
      final value = ValueNotifier<StyledText?>(null);
      final controller = MenuController();
      final styledEditingController = StyledEditingController<StyledText>();

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(splashFactory: InkRipple.splashFactory),
          home: Scaffold(
            body: SizedBox.fromSize(
              size: const Size(300, 100),
              child: ColorSelector(
                value: value,
                controller: controller,
                colors: [
                  [null, Colors.black87, Colors.white],
                ],
                styledEditingController: styledEditingController,
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.format_color_text));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.format_color_reset), findsOneWidget);
    });
  });

  group('AntPart', () {
    test('toParts with styles and placeholders', () {
      final text = 'Hello${TextPlaceholder.char}World';
      final placeholder = TextPlaceholder(id: 'p1', text: 'P1');
      final controller = StyledEditingController<StyledText>();
      controller.value = TextEditingValue(text: text);
      controller.styles.add(StyledText(range: const TextRange(start: 1, end: 10), isBold: true));
      controller.placeholders.add(IndexPlaceholder.from(5, placeholder));

      final parts = controller.toParts();
      // Should contain: StyledPart('Hello', bold), PlaceholderPart, StyledPart('World', bold)
      expect(parts.length, equals(5));
      // Find the sequence: StyledPart, PlaceholderPart, StyledPart
      final styledParts = parts.whereType<StyledPart>().toList();
      final placeholderParts = parts.whereType<PlaceholderPart>().toList();
      expect(styledParts.length, equals(4));
      expect(placeholderParts.length, equals(1));
      expect(styledParts[0].text, 'H');
      expect(styledParts[0].style, isNull);
      expect(styledParts[1].text, 'ello');
      expect(styledParts[1].style?.isBold, isTrue);
      expect(styledParts[2].text, 'Worl');
      expect(styledParts[2].style?.isBold, isTrue);
      expect(styledParts[3].text, 'd');
      expect(styledParts[3].style, isNull);

      expect(styledParts[0].buildSpan(), isNotNull);
      expect(placeholderParts[0].buildSpan('hi'), isNotNull);
    });
  });
}
