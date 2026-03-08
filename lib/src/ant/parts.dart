import 'package:flutter/widgets.dart';

import '../placeholders.dart';
import '../styled_range.dart';
import 'styled_text.dart';

class AntPart {
  static List<Part> toParts(String text, List<StyledText> styles, List<PlaceholderIndex> placeholders) {
    final List<Part> parts = [];

    void addPart(int start, int end, [StyledText? style]) {
      if (placeholders.isNotEmpty) {
        for (final placeholder in placeholders) {
          if (placeholder.index >= start && placeholder.index < end) {
            final s = StyledPart(text.substring(start, placeholder.index - 1), style);
            parts.add(s);
            parts.add(PlaceholderPart(id: placeholder.placeholder.id, style: s));
            start = placeholder.index;
          }
        }
      }

      parts.add(StyledPart(text.substring(start, end), style));
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

    for (final placeholder in placeholders) {
      parts.insert(placeholder.index, PlaceholderPart(id: placeholder.placeholder.id));
    }

    return parts;
  }
}

class StyledPart extends Part<int> {
  /// The text content of this part.
  final String text;

  /// The style applied to this part, if any.
  final StyledText? style;

  TextStyle? _textStyle;

  StyledPart(this.text, [this.style]);

  TextStyle? get textStyle {
    if (style == null) return null;
    return _textStyle ??= style!.toTextStyle();
  }

  @override
  InlineSpan buildSpan([int? _]) {
    return TextSpan(text: text, style: textStyle);
  }
}

class PlaceholderPart extends Part<String> {
  final String id;
  final StyledPart? style;

  PlaceholderPart({required this.id, this.style});

  @override
  InlineSpan buildSpan(String text) {
    return TextSpan(text: text, style: style?.textStyle);
  }
}
