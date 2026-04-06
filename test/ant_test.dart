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
              child: StyledWrapper(
                controller: styledEditingController,
                focusNode: FocusNode(),
                intents: <StyledIntent<StyledText>>[],
                child: FontSizeField(key: const Key('font_size_field'), controller: controller),
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
              child: StyledWrapper(
                controller: styledEditingController,
                focusNode: FocusNode(),
                intents: <StyledIntent<StyledText>>[],
                child: ColorSelector(
                  value: value,
                  controller: controller,
                  colors: [
                    [null, Colors.black87, Colors.white],
                  ],
                ),
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

  testWidgets('didUpdateWidget', (tester) async {
    var controller = StyledEditingController<StyledText>();
    final notifier = ValueNotifier(FocusNode());
    ValueNotifier<StyledText?>? style;
    await tester.pumpWidget(
      MaterialApp(
        // use material 2 to fix `'shaders/ink_sparkle.frag' not found` error on Github Actions
        theme: ThemeData(useMaterial3: false, brightness: Brightness.light),
        home: Scaffold(
          body: ValueListenableBuilder(
            valueListenable: notifier,
            builder: (context, value, child) {
              return Column(
                children: [
                  TextButton(
                    onPressed: () {
                      notifier.value = FocusNode();
                      controller = StyledEditingController<StyledText>();
                      style = style == null ? ValueNotifier(null) : null;
                    },
                    child: Text('swap'),
                  ),
                  StyledWrapper(
                    controller: controller,
                    focusNode: value,
                    child: BoldButton(value: style),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('swap'));
    await tester.pumpAndSettle();

    expect(style, isNotNull);

    await tester.tap(find.text('swap'));
    await tester.pumpAndSettle();

    expect(style, isNull);
  });

  group('AntPart', () {
    test('toParts and fromParts', () {
      final text = 'Hello${TextPlaceholder.char}${TextPlaceholder.char}WorldEvan';
      final styles = [
        StyledText(range: const TextRange(start: 1, end: 11), isBold: true),
        StyledText(range: const TextRange(start: 12, end: 14), isBold: true),
        StyledText(range: const TextRange(start: 14, end: 16), color: Colors.red),
      ];
      final placeholders = [
        IndexPlaceholder(5, TextPlaceholder(id: 'p1', text: 'p1')),
        IndexPlaceholder(6, MenuPlaceholder(id: 'p2', text: 'p2', meta: 'meta', onMenuSelected: (_) async => null)),
      ];
      final expectedResult = [
        ['H', null],
        ['ello', StyledText(isBold: true, range: TextRange.empty)],
        ['Worl', StyledText(isBold: true, range: TextRange.empty)],
        ['d', null],
        ['Ev', StyledText(isBold: true, range: TextRange.empty)],
        ['an', StyledText(color: Colors.red, range: TextRange.empty)],
      ];
      final controller = StyledEditingController<StyledText>();
      controller.resetText(text: text, styles: styles, placeholders: placeholders);

      final parts = controller.toParts();
      final styledParts = parts.where((e) => e is! PlaceholderPart).cast<StyledPart>().toList();
      final placeholderParts = parts.whereType<PlaceholderPart>().toList();
      expect(styledParts.length, equals(6));
      expect(placeholderParts.length, equals(2));
      for (int i = 0; i < 6; i++) {
        expect(styledParts[i].text, expectedResult[i][0]);
        expect(styledParts[i].style, expectedResult[i][1]);
      }

      final list = parts.map((e) => e.toJson()).toList();
      final newParts = list.map(partFromJson).toList();

      for (int i = 0; i < parts.length; i++) {
        expect(newParts[i].toJson(), equals(parts[i].toJson()));
      }

      controller.fromParts(parts: newParts);

      for (int i = 0; i < controller.styles.length; i++) {
        expect(controller.styles[i], styles[i]);
        expect(controller.styles[i].range, styles[i].range);
      }
      for (int i = 0; i < controller.placeholders.length; i++) {
        expect(controller.placeholders[i].index, placeholders[i].index);
        expect(controller.placeholders[i].text, placeholders[i].text);
        expect(controller.placeholders[i].id, placeholders[i].id);
        if (i == 1) {
          final p1 = controller.placeholders[i].placeholder;
          final p2 = placeholders[i].placeholder;
          expect(p1, isA<MenuPlaceholder>());
          expect(p2, isA<MenuPlaceholder>());
          expect((p1 as MenuPlaceholder).meta, (p2 as MenuPlaceholder).meta);
        }
      }
    });
  });
}
