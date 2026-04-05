import 'package:flutter/material.dart';

class TextPlaceholder {
  static const String char = '\uFFFC';
  static const int rune = 0xFFFC;

  final String id;

  final String text;

  final ValueNotifier<String>? textNotifier;

  final FocusNode? menuFocusNode;

  final List<Widget> Function(ValueNotifier<String>?)? menuChildrenBuilder;

  const TextPlaceholder({
    required this.id,
    required this.text,
    this.textNotifier,
    this.menuFocusNode,
    this.menuChildrenBuilder,
  });

  TextPlaceholder create() => this;

  bool get hasMenu => menuChildrenBuilder != null;

  InlineSpan buildSpan(TextStyle? style) {
    return WidgetSpan(
      alignment: PlaceholderAlignment.middle,
      child: hasMenu ? buildMenu() : buildWidget(),
      style: style,
    );
  }

  Widget buildWidget() {
    const textStyle = TextStyle(fontSize: 12, color: Color(0xFFD63384), fontFamily: 'monospace');
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Color(0x33B4AB33),
          borderRadius: BorderRadius.circular(1.6),
          border: Border.all(color: Colors.black.withAlpha(11), width: 0.5),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 3.1),
          child: textNotifier != null
              ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ValueListenableBuilder(
                      valueListenable: textNotifier!,
                      builder: (context, value, child) {
                        return Text(value, style: textStyle);
                      },
                    ),
                    const SizedBox(width: 2),
                    Icon(Icons.expand_more, size: 12, color: textStyle.color),
                  ],
                )
              : Text(text, style: textStyle),
        ),
      ),
    );
  }

  Widget buildMenu() {
    return MenuAnchor(
      style: MenuStyle(padding: WidgetStateProperty.all(EdgeInsets.zero)),
      childFocusNode: menuFocusNode,
      menuChildren: menuChildrenBuilder!(textNotifier),
      builder: (context, controller, child) {
        return GestureDetector(onTap: () => controller.isOpen ? controller.close() : controller.open(), child: child!);
      },
      child: buildWidget(),
    );
  }
}

class IndexPlaceholder extends TextPlaceholder {
  int index;

  IndexPlaceholder({
    required super.id,
    required super.text,
    required this.index,
    super.textNotifier,
    super.menuFocusNode,
    super.menuChildrenBuilder,
  });

  factory IndexPlaceholder.from(int index, TextPlaceholder placeholder) {
    return IndexPlaceholder(
      id: placeholder.id,
      text: placeholder.text,
      index: index,
      textNotifier: placeholder.textNotifier,
      menuFocusNode: placeholder.menuFocusNode,
      menuChildrenBuilder: placeholder.menuChildrenBuilder,
    );
  }
}

class DynamicPlaceholder extends TextPlaceholder {
  DynamicPlaceholder({required super.id, required super.text, super.menuFocusNode, super.menuChildrenBuilder});

  DynamicPlaceholder._({
    required super.id,
    required super.text,
    super.textNotifier,
    super.menuFocusNode,
    super.menuChildrenBuilder,
  });

  @override
  TextPlaceholder create() {
    final textNotifier = menuChildrenBuilder != null ? ValueNotifier(text) : null;
    return DynamicPlaceholder._(
      id: id,
      text: text,
      textNotifier: textNotifier,
      menuFocusNode: menuFocusNode,
      menuChildrenBuilder: menuChildrenBuilder,
    );
  }
}
