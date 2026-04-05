import 'package:editor_ant/editor_ant.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('StyledWrapper', () {
    testWidgets('get styled wrapper from context', (tester) async {
      late BuildContext context;

      await tester.pumpWidget(
        StyledWrapper(
          controller: StyledEditingController<StyledText>(),
          child: Builder(
            builder: (ctx) {
              context = ctx;
              return const SizedBox();
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      final wrapper = StyledWrapper.of<StyledText>(context);
      expect(wrapper, isNotNull);
    });
  });
}
