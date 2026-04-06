import 'package:editor_ant/editor_ant.dart';
import 'package:flutter/widgets.dart';

typedef OutPlaceholderParser = PlaceholderPart Function(TextPlaceholder placeholder, StyledText? style);
typedef InPlaceholderParser = TextPlaceholder Function(PlaceholderPart placeholder);

PlaceholderPart _defaultOutPlaceholderParser(TextPlaceholder placeholder, StyledText? style) =>
    placeholder is MenuPlaceholder
    ? MenuPlaceholderPart(text: placeholder.id, meta: placeholder.meta, style: style)
    : PlaceholderPart(text: placeholder.id, style: style);

TextPlaceholder _defaultInPlaceholderParser(PlaceholderPart placeholder) => placeholder is MenuPlaceholderPart
    ? MenuPlaceholder(
        id: placeholder.text,
        text: placeholder.text,
        meta: placeholder.meta,
        onMenuSelected: (_) async => null,
      )
    : TextPlaceholder(id: placeholder.text, text: placeholder.text);

extension AntPart on StyledEditingController<StyledText> {
  /// Converts the current text, styles, and placeholders in the controller to a list of [Part]s.
  List<Part> toParts({OutPlaceholderParser placeholderParser = _defaultOutPlaceholderParser}) {
    final text = value.text;
    final List<Part> parts = [];

    void addPart(int start, int end, [StyledText? style]) {
      for (final placeholder in placeholders) {
        if (placeholder.index >= start && placeholder.index < end) {
          if (placeholder.index != start) {
            parts.add(StyledPart(text: text.substring(start, placeholder.index), style: style));
          }
          parts.add(placeholderParser(placeholder.placeholder, style));

          start = placeholder.index + 1;
        }
      }

      if (start < end) {
        parts.add(StyledPart(text: text.substring(start, end), style: style));
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

  /// Updates the controller's text, styles, and placeholders based on a list of [Part]s.
  void fromParts({required List<Part> parts, InPlaceholderParser placeholderParser = _defaultInPlaceholderParser}) {
    final StringBuffer textBuffer = StringBuffer();
    final styles = <StyledText>[];
    final placeholders = <IndexPlaceholder>[];

    StyledText? currentStyle;
    for (final part in parts) {
      final start = textBuffer.length;

      StyledText? partStyle;
      if (part is PlaceholderPart) {
        textBuffer.write(TextPlaceholder.char);
        partStyle = part.style;
        placeholders.add(IndexPlaceholder(start, placeholderParser(part)));
      } else if (part is StyledPart) {
        textBuffer.write(part.text);
        partStyle = part.style;
      }

      if (partStyle == null) {
        if (currentStyle != null) {
          styles.add(currentStyle);
          currentStyle = null;
        }
        continue;
      }

      if (currentStyle == null) {
        currentStyle = partStyle.copyWith(start: start, end: textBuffer.length);
        continue;
      }

      if (currentStyle == partStyle && currentStyle.range.end == start) {
        currentStyle = currentStyle.copyWith(end: textBuffer.length);
        continue;
      }

      styles.add(currentStyle);
      currentStyle = partStyle.copyWith(start: start, end: textBuffer.length);
    }

    if (currentStyle != null) {
      styles.add(currentStyle);
    }

    resetText(text: textBuffer.toString(), styles: styles, placeholders: placeholders);
  }
}

Part<StyledText> partFromJson(Map<String, dynamic> json) {
  final type = json['type'] as String? ?? 'styled';
  switch (type) {
    case 'placeholder':
      return PlaceholderPart.fromJson(json);
    case 'meta_placeholder':
      return MenuPlaceholderPart.fromJson(json);
    default:
      return StyledPart.fromJson(json);
  }
}

/// A part representing a segment of text with an optional style.
class StyledPart extends Part<StyledText> {
  /// The text content of this part.
  final String text;

  const StyledPart({required this.text, required super.style});

  factory StyledPart.fromJson(Map<String, dynamic> json) {
    final text = json['text'] as String? ?? '';
    final isBold = json['isBold'] as bool?;
    final isItalic = json['isItalic'] as bool?;
    final isUnderline = json['isUnderline'] as bool?;
    final isStrikethrough = json['isStrikethrough'] as bool?;
    final fontSize = (json['fontSize'] as num?)?.toInt();
    final color = (json['color'] as num?)?.toInt();
    final hasStyle =
        isBold != null ||
        isItalic != null ||
        isUnderline != null ||
        isStrikethrough != null ||
        fontSize != null ||
        color != null;

    return StyledPart(
      text: text,
      style: hasStyle
          ? StyledText(
              range: TextRange.empty,
              isBold: isBold ?? false,
              isItalic: isItalic ?? false,
              isUnderline: isUnderline ?? false,
              isStrikethrough: isStrikethrough ?? false,
              fontSize: fontSize,
              color: color != null ? Color(color) : null,
            )
          : null,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    final s = style;
    if (s == null) {
      return {'type': 'styled', 'text': text};
    }

    return {
      'type': 'styled',
      'text': text,
      if (s.isBold) 'isBold': s.isBold,
      if (s.isItalic) 'isItalic': s.isItalic,
      if (s.isStrikethrough) 'isStrikethrough': s.isStrikethrough,
      if (s.isUnderline) 'isUnderline': s.isUnderline,
      if (s.fontSize != null) 'fontSize': s.fontSize,
      if (s.color != null) 'color': s.color!.toARGB32(),
    };
  }
}

/// A part representing a placeholder in the text, which can be rendered as a widget.
class PlaceholderPart extends StyledPart {
  const PlaceholderPart({required super.text, required super.style});

  factory PlaceholderPart.fromJson(Map<String, dynamic> json) {
    final part = StyledPart.fromJson(json);
    return PlaceholderPart(text: part.text, style: part.style);
  }

  @override
  Map<String, dynamic> toJson() {
    final base = super.toJson();
    base['type'] = 'placeholder';
    return base;
  }
}

/// A part representing a meta placeholder, which includes additional meta information.
class MenuPlaceholderPart extends PlaceholderPart {
  /// The additional meta information for this placeholder.
  final String meta;

  const MenuPlaceholderPart({required super.text, required super.style, required this.meta});

  factory MenuPlaceholderPart.fromJson(Map<String, dynamic> json) {
    final part = StyledPart.fromJson(json);
    final meta = json['meta'] as String? ?? '';
    return MenuPlaceholderPart(text: part.text, style: part.style, meta: meta);
  }

  @override
  Map<String, dynamic> toJson() {
    final base = super.toJson();
    base['type'] = 'meta_placeholder';
    base['meta'] = meta;
    return base;
  }
}
