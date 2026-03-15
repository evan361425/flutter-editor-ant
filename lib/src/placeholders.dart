import 'package:flutter/material.dart';

class TextPlaceholder {
  static const String char = '\uFFFC';
  static const int rune = 0xFFFC;

  final String id;

  final String text;

  const TextPlaceholder({required this.id, required this.text});

  InlineSpan buildSpan(TextStyle? style) {
    return WidgetSpan(
      alignment: PlaceholderAlignment.middle,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.grey.withAlpha(38),
          borderRadius: BorderRadius.circular(1.6),
          border: Border.all(color: Colors.black.withAlpha(11), width: 0.5),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4.7),
          child: Text(text, style: const TextStyle(fontSize: 12, color: Color(0xFFF0F0F0))),
        ),
      ),
      style: style,
    );
  }
}

class IndexPlaceholder extends TextPlaceholder {
  int index;

  IndexPlaceholder({required super.id, required super.text, required this.index});

  factory IndexPlaceholder.from(int index, TextPlaceholder placeholder) {
    return IndexPlaceholder(id: placeholder.id, text: placeholder.text, index: index);
  }
}
