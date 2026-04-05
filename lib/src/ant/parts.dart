import '../styled_editing_controller.dart';
import '../styled_range.dart';
import 'styled_text.dart';

extension AntPart on StyledEditingController<StyledText> {
  List<Part> toParts() {
    final text = value.text;
    final List<Part> parts = [];

    void addPart(int start, int end, [StyledText? style]) {
      for (final placeholder in placeholders) {
        if (placeholder.index >= start && placeholder.index < end) {
          if (placeholder.index != start) {
            parts.add(StyledPart(text.substring(start, placeholder.index), style));
          }
          parts.add(PlaceholderPart(id: placeholder.id, style: style));

          start = placeholder.index + 1;
        }
      }

      if (start < end) {
        parts.add(StyledPart(text.substring(start, end), style));
      }
    }

    int currentIndex = 0;
    for (final style in styles) {
      if (currentIndex < style.range.start) {
        addPart(currentIndex, style.range.start);
      }
      addPart(style.range.start, style.range.end, style);
      currentIndex = style.range.end;
    }

    if (currentIndex < text.length) {
      addPart(currentIndex, text.length);
    }

    return parts;
  }
}

class StyledPart extends Part {
  /// The text content of this part.
  final String text;

  /// The style applied to this part, if any.
  final StyledText? style;

  const StyledPart(this.text, [this.style]);
}

class PlaceholderPart extends Part {
  /// The unique identifier for this placeholder.
  final String id;

  /// The style applied to this placeholder, if any.
  final StyledText? style;

  const PlaceholderPart({required this.id, this.style});
}
