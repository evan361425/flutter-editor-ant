import 'package:editor_ant/editor_ant.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('StyledWrapper', () {
    testWidgets('get styled wrapper from context', (tester) async {
      late BuildContext context;

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: StyledWrapper(
            controller: StyledEditingController<StyledText>(),
            canSizeOverlay: true,
            child: Builder(
              builder: (ctx) {
                context = ctx;
                return const SizedBox(width: 10, height: 10);
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final wrapper = StyledWrapper.of<StyledText>(context);
      expect(wrapper, isNotNull);
    });
  });
}
