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
      final result = style.copyWith(
        other: StyledText(
          range: TextRange.empty,
          isBold: true,
          isItalic: true,
          isStrikethrough: true,
          isUnderline: true,
        ),
        toggle: true,
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
      final shortcut = BoldButton.createShortcut(
        onPressed: () {
          isPressed = true;
        },
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(useMaterial3: false),
          home: Scaffold(
            body: SizedBox(
              width: 100,
              height: 100,
              child: BoldButton(shortcut: shortcut, value: ValueNotifier(null)),
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
      bool isEscaped = false;
      final controller = TextEditingController(text: '16');
      final propagateTo = FocusNode();
      final focusNode = FontSizeField.createFocusNode(onEscape: () => isEscaped = true, propagateTo: propagateTo);
      final styledEditingController = StyledEditingController<StyledText>();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 100,
              height: 100,
              child: FontSizeField(
                key: const Key('font_size_field'),
                controller: controller,
                focusNode: focusNode,
                styledEditingController: styledEditingController,
              ),
            ),
          ),
        ),
      );

      await tester.enterText(find.byKey(const Key('font_size_field')), '20');
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();

      expect(isEscaped, isTrue);

      await tester.enterText(find.byKey(const Key('font_size_field')), '22');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      expect(styledEditingController.activeStyle.value?.fontSize, equals(22));
    });
    testWidgets('TextAlign', (tester) async {
      final value = ValueNotifier<TextAlign>(TextAlign.left);
      final controller = MenuController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox.fromSize(
              size: const Size(300, 100),
              child: TextAlignSelector(value: value, controller: controller),
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
  });
}
