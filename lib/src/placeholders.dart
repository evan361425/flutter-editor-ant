import 'package:flutter/material.dart';

const _defaultPlaceholderStyle = TextStyle(fontSize: 12, color: Color(0xFFD63384), fontFamily: 'monospace');

/// A placeholder that can be embedded in the text and can build a widget for display.
class TextPlaceholder {
  /// The Unicode object replacement character, used to represent the placeholder in the text.
  static const String char = '\uFFFC';

  /// The char for this placeholder.
  static const int rune = 0xFFFC;

  /// The unique identifier for this placeholder.
  /// It can be used to identify the placeholder when converting between parts and text.
  /// Usually it should be a name from enum.
  final String id;

  /// The text to display for this placeholder.
  final String text;

  const TextPlaceholder({required this.id, required this.text});

  /// Called when added to the editor, should return a new instance of the placeholder.
  /// This is useful for placeholders that need to maintain state, such as menu placeholders.
  TextPlaceholder create() => this;

  /// Builds the inline span to display for this placeholder.
  InlineSpan buildSpan(TextStyle? style) {
    return WidgetSpan(alignment: PlaceholderAlignment.middle, child: buildWidget(), style: style);
  }

  /// Underlying method to build the widget for this placeholder.
  Widget buildWidget() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Color(0x33B4AB33),
          borderRadius: BorderRadius.circular(1.6),
          border: Border.all(color: Colors.black.withAlpha(11), width: 0.5),
        ),
        child: Padding(padding: const EdgeInsets.symmetric(horizontal: 3.1), child: buildText()),
      ),
    );
  }

  /// Actual text widget for the placeholder, separated from the decoration for easier customization.
  Widget buildText() {
    return Text(text, style: _defaultPlaceholderStyle);
  }
}

/// A placeholder with an index, used internally to keep track of the position of placeholders in the text.
class IndexPlaceholder {
  /// The index of the placeholder in the text.
  int index;

  /// The actual placeholder object.
  final TextPlaceholder placeholder;

  IndexPlaceholder(this.index, this.placeholder);

  /// Helper method for accessing.
  String get text => placeholder.text;

  /// Helper method for accessing.
  String get id => placeholder.id;
}

typedef MenuChildBuilder<T> = List<Widget> Function(MenuPlaceholder<T> placeholder);

/// A placeholder that can open a menu when tapped.
class MenuPlaceholder<T> extends TextPlaceholder {
  /// A builder function that takes a [ValueNotifier] of the placeholder's text
  /// and returns a list of menu children for the [MenuAnchor].
  MenuChildBuilder<T> menuChildrenBuilder;

  /// A [ValueNotifier] that holds the current text of the placeholder. This can be
  /// used to update the placeholder's text dynamically when menu items are selected.
  final ValueNotifier<String> textNotifier;

  /// An optional [FocusNode] for the menu.
  final FocusNode? menuFocusNode;

  /// Additional metadata for this placeholder.
  /// For example a format for a date placeholder.
  T? meta;

  MenuPlaceholder({
    required super.id,
    required super.text,
    MenuChildBuilder<T>? menuChildrenBuilder,
    Future<T?> Function(MenuPlaceholder<T>)? onMenuSelected,
    this.menuFocusNode,
    this.meta,
  }) : assert(
         menuChildrenBuilder != null || onMenuSelected != null,
         'Must have menuChildrenBuilder or onMenuSelected set',
       ),
       textNotifier = ValueNotifier(''),
       menuChildrenBuilder =
           menuChildrenBuilder ??
           ((MenuPlaceholder<T> placeholder) => [
             MenuItemButton(
               onPressed: () async {
                 final result = await onMenuSelected!(placeholder);
                 if (result != null) {
                   placeholder.meta = result;
                 }
               },
               child: Text(meta.toString()),
             ),
           ]);

  MenuPlaceholder._({
    required super.id,
    required super.text,
    required this.menuChildrenBuilder,
    required this.textNotifier,
    this.menuFocusNode,
    this.meta,
  });

  @override
  MenuPlaceholder<T> create() {
    return MenuPlaceholder._(
      id: id,
      text: text,
      textNotifier: ValueNotifier(text),
      menuFocusNode: menuFocusNode,
      menuChildrenBuilder: menuChildrenBuilder,
      meta: meta,
    );
  }

  @override
  Widget buildWidget() {
    return MenuAnchor(
      style: MenuStyle(padding: WidgetStateProperty.all(EdgeInsets.zero)),
      childFocusNode: menuFocusNode,
      menuChildren: buildMenuChildren(this),
      builder: (context, controller, child) {
        return GestureDetector(onTap: () => controller.isOpen ? controller.close() : controller.open(), child: child!);
      },
      child: super.buildWidget(),
    );
  }

  @override
  Widget buildText() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ValueListenableBuilder(
          valueListenable: textNotifier,
          builder: (context, value, child) {
            return Text(value, style: _defaultPlaceholderStyle);
          },
        ),
        const SizedBox(width: 2),
        Icon(Icons.expand_more, size: 12, color: _defaultPlaceholderStyle.color),
      ],
    );
  }

  List<Widget> buildMenuChildren(MenuPlaceholder v) {
    return menuChildrenBuilder(this);
  }
}
