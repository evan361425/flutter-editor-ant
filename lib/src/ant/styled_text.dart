import 'package:editor_ant/src/styled_range.dart';
import 'package:flutter/material.dart';

/// Default font size used in [StyledText]
const int defaultFontSize = 16;

/// StyledText represents a range of text with specific styles applied.
class StyledText extends StyledRange<StyledText> {
  /// Whether the text is bold.
  final bool isBold;

  /// Whether the text is italic.
  final bool isItalic;

  /// Whether the text is strikethrough.
  final bool isStrikethrough;

  /// Whether the text is underlined.
  final bool isUnderline;

  /// Font size of the text.
  final int? fontSize;

  /// Color of the text.
  final Color? color;

  StyledText({
    required super.range,
    this.isBold = false,
    this.isItalic = false,
    this.isStrikethrough = false,
    this.isUnderline = false,
    this.fontSize,
    this.color,
  });

  @override
  StyledText copyWith({
    int? start,
    int? end,
    bool isBold = false,
    bool isItalic = false,
    bool isStrikethrough = false,
    bool isUnderline = false,
    int? fontSize,
    Color? color,
  }) {
    return StyledText(
      range: TextRange(start: start ?? range.start, end: end ?? range.end),
      isBold: isBold ? true : this.isBold,
      isItalic: isItalic ? true : this.isItalic,
      isStrikethrough: isStrikethrough ? true : this.isStrikethrough,
      isUnderline: isUnderline ? true : this.isUnderline,
      fontSize: fontSize ?? this.fontSize,
      color: color ?? this.color,
    );
  }

  @override
  StyledText toggleWith(StyledText other, {int? start, int? end, bool toggle = true}) {
    return StyledText(
      range: TextRange(start: start ?? range.start, end: end ?? range.end),
      isBold: other.isBold ? !isBold || !toggle : isBold,
      isItalic: other.isItalic ? !isItalic || !toggle : isItalic,
      isStrikethrough: other.isStrikethrough ? !isStrikethrough || !toggle : isStrikethrough,
      isUnderline: other.isUnderline ? !isUnderline || !toggle : isUnderline,
      fontSize: fontSize ?? other.fontSize,
      color: color ?? other.color,
    );
  }

  @override
  StyledText combine(StyledText other) {
    return StyledText(
      range: TextRange(start: range.start, end: other.range.end),
      isBold: isBold && other.isBold,
      isItalic: isItalic && other.isItalic,
      isStrikethrough: isStrikethrough && other.isStrikethrough,
      isUnderline: isUnderline && other.isUnderline,
      fontSize: fontSize == other.fontSize && fontSize != null ? fontSize : null,
      color: color == other.color && color != null ? color : null,
    );
  }

  @override
  bool hasSameToggleState(StyledText other) {
    if (isBold) {
      return other.isBold;
    }
    if (isItalic) {
      return other.isItalic;
    }
    if (isStrikethrough) {
      return other.isStrikethrough;
    }
    if (isUnderline) {
      return other.isUnderline;
    }
    return false;
  }

  @override
  // use for change notifier
  bool operator ==(Object other) {
    return other is StyledText &&
        isBold == other.isBold &&
        isItalic == other.isItalic &&
        isStrikethrough == other.isStrikethrough &&
        isUnderline == other.isUnderline &&
        fontSize == other.fontSize &&
        color == other.color;
  }

  @override
  TextStyle toTextStyle() {
    return TextStyle(
      fontWeight: isBold ? FontWeight.bold : null,
      fontStyle: isItalic ? FontStyle.italic : null,
      decoration: TextDecoration.combine([
        if (isStrikethrough) TextDecoration.lineThrough,
        if (isUnderline) TextDecoration.underline,
      ]),
      decorationColor: color,
      fontSize: fontSize?.toDouble(),
      color: color,
    );
  }

  @override
  String toString() {
    final props = [
      '${range.start}~${range.end}',
      if (isBold) 'bold',
      if (isItalic) 'italic',
      if (isStrikethrough) 'strike',
      if (isUnderline) 'underline',
      if (fontSize != null) 'size:$fontSize',
      if (color != null) color!.toARGB32().toRadixString(16),
    ];
    return 'StyledText(${props.join(', ')})';
  }

  @override
  int get hashCode => Object.hash(range, isBold, isItalic, isStrikethrough, isUnderline, fontSize, color);
}
