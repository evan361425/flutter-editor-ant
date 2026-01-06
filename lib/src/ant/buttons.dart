import 'package:editor_ant/src/ant/shortcut.dart';
import 'package:editor_ant/src/ant/styled_text.dart';
import 'package:editor_ant/src/styled_editing_controller.dart';
import 'package:editor_ant/src/styled_range.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

/// Simple button to toggle bold style in [StyledText]
class BoldButton extends StatelessWidget {
  final ValueNotifier<StyledText?> value;
  final Shortcut? shortcut;
  final VoidCallback? onPressed;
  final String tooltip;

  const BoldButton({super.key, required this.value, this.shortcut, this.onPressed, this.tooltip = 'Bold'});

  /// Create a [Shortcut] for bold action
  static Shortcut createShortcut({
    VoidCallback? onPressed,
    StyledEditingController<StyledText>? controller,
    FocusNode? propagateTo,
  }) {
    return Shortcut.withCmdOrCtrl(
      intent: const BoldIntent(),
      onInvoke: _getShortcutCallback(
        onPressed: onPressed,
        controller: controller,
        propagateTo: propagateTo,
        styler: (style) => style.copyWith(isBold: true),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ToggleableButton(
      value: value,
      icon: const Icon(Icons.format_bold),
      tooltip: shortcut?.formatTooltip(tooltip, MaterialLocalizations.of(context)) ?? tooltip,
      predicate: (style) => style.isBold,
      onPressed: shortcut?.onInvoke ?? onPressed!,
    );
  }
}

/// Simple button to toggle italic style in [StyledText]
class ItalicButton extends StatelessWidget {
  final ValueNotifier<StyledText?> value;
  final Shortcut? shortcut;
  final VoidCallback? onPressed;
  final String tooltip;

  const ItalicButton({super.key, required this.value, this.shortcut, this.onPressed, this.tooltip = 'Italic'});

  /// Create a [Shortcut] for italic action
  static Shortcut createShortcut({
    VoidCallback? onPressed,
    StyledEditingController<StyledText>? controller,
    FocusNode? propagateTo,
  }) {
    return Shortcut.withCmdOrCtrl(
      intent: const ItalicIntent(),
      onInvoke: _getShortcutCallback(
        onPressed: onPressed,
        controller: controller,
        propagateTo: propagateTo,
        styler: (style) => style.copyWith(isItalic: true),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ToggleableButton(
      value: value,
      icon: const Icon(Icons.format_italic),
      tooltip: shortcut?.formatTooltip(tooltip, MaterialLocalizations.of(context)) ?? tooltip,
      predicate: (style) => style.isItalic,
      onPressed: shortcut?.onInvoke ?? onPressed!,
    );
  }
}

/// Simple button to toggle strikethrough style in [StyledText]
class StrikethroughButton extends StatelessWidget {
  final ValueNotifier<StyledText?> value;
  final Shortcut? shortcut;
  final VoidCallback? onPressed;
  final String tooltip;

  const StrikethroughButton({
    super.key,
    required this.value,
    this.shortcut,
    this.onPressed,
    this.tooltip = 'Strikethrough',
  });

  /// Create a [Shortcut] for strikethrough action
  static Shortcut createShortcut({
    VoidCallback? onPressed,
    StyledEditingController<StyledText>? controller,
    FocusNode? propagateTo,
  }) {
    return Shortcut.withCmdOrCtrl(
      intent: const StrikethroughIntent(),
      onInvoke: _getShortcutCallback(
        onPressed: onPressed,
        controller: controller,
        propagateTo: propagateTo,
        styler: (style) => style.copyWith(isStrikethrough: true),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ToggleableButton(
      value: value,
      icon: const Icon(Icons.strikethrough_s),
      tooltip: shortcut?.formatTooltip(tooltip, MaterialLocalizations.of(context)) ?? tooltip,
      predicate: (style) => style.isStrikethrough,
      onPressed: shortcut?.onInvoke ?? onPressed!,
    );
  }
}

/// Simple button to toggle underline style in [StyledText]
class UnderlineButton extends StatelessWidget {
  final ValueNotifier<StyledText?> value;
  final Shortcut? shortcut;
  final VoidCallback? onPressed;
  final String tooltip;

  const UnderlineButton({super.key, required this.value, this.shortcut, this.onPressed, this.tooltip = 'Underline'});

  /// Create a [Shortcut] for underline action
  static Shortcut createShortcut({
    VoidCallback? onPressed,
    StyledEditingController<StyledText>? controller,
    FocusNode? propagateTo,
  }) {
    return Shortcut.withCmdOrCtrl(
      intent: const UnderlineIntent(),
      onInvoke: _getShortcutCallback(
        onPressed: onPressed,
        controller: controller,
        propagateTo: propagateTo,
        styler: (style) => style.copyWith(isUnderline: true),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ToggleableButton(
      value: value,
      icon: const Icon(Icons.format_underline),
      tooltip: shortcut?.formatTooltip(tooltip, MaterialLocalizations.of(context)) ?? tooltip,
      predicate: (style) => style.isUnderline,
      onPressed: shortcut?.onInvoke ?? onPressed!,
    );
  }
}

/// A simple text field to select font size for [StyledText]
class FontSizeField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final StyledEditingController<StyledText> styledEditingController;
  final FocusNode? propagateTo;
  final double width;

  const FontSizeField({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.styledEditingController,
    this.propagateTo,
    this.width = 52,
  });

  /// Create a [FocusNode] that listens for Escape key to propagate focus
  static FocusNode createFocusNode({required VoidCallback onEscape, FocusNode? propagateTo}) {
    return FocusNode(
      onKeyEvent: (FocusNode node, KeyEvent event) {
        if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.escape) {
          onEscape();
          propagateTo?.requestFocus();
          return KeyEventResult.handled; // Prevent the event from bubbling up
        }
        return KeyEventResult.ignored;
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Autocomplete<int>(
        textEditingController: controller,
        focusNode: focusNode,
        displayStringForOption: (int option) => option.toString(),
        onSelected: (int size) {
          styledEditingController.addStyle(
            StyledText(range: styledEditingController.selection).copyWith(fontSize: size),
          );
          propagateTo?.requestFocus();
        },
        fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
          return TextFormField(
            controller: controller,
            focusNode: focusNode,
            keyboardType: TextInputType.number,
            maxLines: 1,
            textAlign: TextAlign.center,
            textInputAction: TextInputAction.done,
            decoration: InputDecoration(
              isDense: true,
              border: OutlineInputBorder(),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(width: 1.0),
                borderRadius: BorderRadius.circular(6.0),
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 2.0),
            ),
            onFieldSubmitted: (String value) {
              onFieldSubmitted();
            },
          );
        },
        optionsBuilder: (value) {
          int size = double.tryParse(value.text)?.toInt() ?? defaultFontSize;
          if (size >= 100) return [99];
          if (size > 10) {
            final target = (size ~/ 10 + 1) * 10;
            return [for (int i = size; i < target; i++) i];
          }
          if (size < 1) size = 1;
          return [size, for (int i = size * 10; i < (size + 1) * 10; i++) i];
        },
      ),
    );
  }
}

/// A simple color selector to select text color for [StyledText]
class ColorSelector extends StatelessWidget {
  final ValueNotifier<StyledText?> value;
  final MenuController controller;
  final List<List<Color?>> colors;
  final List<String>? colorNames;
  final StyledEditingController<StyledText> styledEditingController;
  final FocusNode? propagateTo;
  final String tooltip;

  const ColorSelector({
    super.key,
    required this.value,
    required this.controller,
    required this.colors,
    this.colorNames,
    required this.styledEditingController,
    this.propagateTo,
    this.tooltip = 'Text Color',
  });

  @override
  Widget build(BuildContext context) {
    int i = 0;
    return MenuAnchor(
      controller: controller,
      builder: (context, controller, child) => ValueListenableBuilder(
        valueListenable: value,
        builder: (context, value, child) {
          return IconButton(
            icon: Stack(
              children: [
                const Icon(Icons.format_color_text),
                Positioned(
                  bottom: 0,
                  right: 1,
                  left: 1,
                  child: ColoredBox(
                    color: Colors.grey[200]!,
                    child: ColoredBox(
                      color: value?.color ?? defaultFontColor,
                      child: SizedBox(height: 5, width: double.infinity),
                    ),
                  ),
                ),
              ],
            ),
            tooltip: tooltip,
            style: IconButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6.0))),
            onPressed: controller.open,
          );
        },
      ),
      menuChildren: [
        for (final row in colors)
          Row(
            children: [
              for (final color in row)
                IconButton(
                  icon: color == null ? Icon(Icons.circle_outlined) : Icon(Icons.circle, color: color),
                  tooltip:
                      colorNames?.elementAtOrNull(i++) ??
                      (color == null ? 'Reset' : '0x${color.toARGB32().toRadixString(16)}'),
                  onPressed: () {
                    // Delay the call to onPressed until post-frame so that the focus is
                    // restored to what it was before the menu was opened before the action is
                    // executed.
                    SchedulerBinding.instance.addPostFrameCallback((Duration _) {
                      FocusManager.instance.applyFocusChangesIfNeeded();
                      styledEditingController.addStyle(
                        StyledText(range: styledEditingController.selection).copyWith(color: color),
                      );
                      propagateTo?.requestFocus();
                    });
                    controller.close();
                  },
                ),
            ],
          ),
      ],
    );
  }
}

/// A button to select text alignment for [StyledText]
class TextAlignSelector extends StatelessWidget {
  final ValueNotifier<TextAlign> value;
  final MenuController controller;
  final String tooltip;
  final void Function(TextAlign)? onSelected;

  const TextAlignSelector({
    super.key,
    required this.value,
    required this.controller,
    this.onSelected,
    this.tooltip = 'Text Alignment',
  });

  @override
  Widget build(BuildContext context) {
    return MenuAnchor(
      controller: controller,
      builder: (context, controller, child) => ValueListenableBuilder(
        valueListenable: value,
        builder: (context, value, child) {
          return IconButton(
            icon: _textAlignToIcon(value),
            tooltip: tooltip,
            style: IconButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6.0))),
            onPressed: controller.open,
          );
        },
      ),
      menuChildren: [
        Row(
          children: [
            for (final alignment in [TextAlign.left, TextAlign.center, TextAlign.right])
              IconButton(
                icon: _textAlignToIcon(alignment),
                tooltip: alignment.toString(),
                onPressed: () {
                  // Delay the call to onPressed until post-frame so that the focus is
                  // restored to what it was before the menu was opened before the action is
                  // executed.
                  SchedulerBinding.instance.addPostFrameCallback((Duration _) {
                    FocusManager.instance.applyFocusChangesIfNeeded();
                    value.value = alignment;
                    onSelected?.call(alignment);
                  });
                  controller.close();
                },
              ),
          ],
        ),
      ],
    );
  }
}

/// A button that can be toggled on or off based on a predicate applied to a [StyledRange] value.
class ToggleableButton<T> extends StatefulWidget {
  /// [IconButton]'s icon
  final Widget icon;

  /// [IconButton]'s tooltip
  final String? tooltip;

  /// [IconButton]'s text color when toggled on, default [ThemeData.colorScheme.onPrimaryContainer]
  final Color? color;

  /// [IconButton]'s background color when toggled on, default [ThemeData.colorScheme.primaryContainer]
  final Color? backgroundColor;

  /// Callback when button is pressed
  final VoidCallback onPressed;

  /// Predicate to determine if the button is toggled on
  final bool Function(T) predicate;

  /// ValueNotifier to listen for changes
  final ValueNotifier<T?> value;

  const ToggleableButton({
    super.key,
    required this.value,
    required this.icon,
    this.tooltip,
    this.color,
    this.backgroundColor,
    required this.onPressed,
    required this.predicate,
  });

  @override
  State<ToggleableButton<T>> createState() => _ToggleableButtonState<T>();
}

class _ToggleableButtonState<T> extends State<ToggleableButton<T>> {
  late bool _toggleOn;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return IconButton(
      icon: widget.icon,
      tooltip: widget.tooltip,
      onPressed: widget.onPressed,
      color: _toggleOn ? (widget.color ?? scheme.onSecondaryContainer) : null,
      isSelected: _toggleOn,
      style: IconButton.styleFrom(
        backgroundColor: _toggleOn ? (widget.backgroundColor ?? scheme.secondaryContainer) : null,
        shape: RoundedRectangleBorder(
          side: _toggleOn ? BorderSide(color: scheme.secondary, width: 1.0) : BorderSide.none,
          borderRadius: BorderRadius.circular(6.0),
        ),
      ),
    );
  }

  @override
  void initState() {
    _toggleOn = _isToggledOn(widget.value.value);
    widget.value.addListener(_onValueChanged);
    super.initState();
  }

  @override
  void dispose() {
    widget.value.removeListener(_onValueChanged);
    super.dispose();
  }

  void _onValueChanged() {
    final result = _isToggledOn(widget.value.value);
    if (mounted && result != _toggleOn) {
      _toggleOn = result;
      setState(() {});
    }
  }

  bool _isToggledOn(T? value) {
    if (value == null) {
      return false;
    }
    return widget.predicate(value);
  }
}

Icon _textAlignToIcon(TextAlign align) {
  switch (align) {
    case TextAlign.left:
      return const Icon(Icons.format_align_left);
    case TextAlign.center:
      return const Icon(Icons.format_align_center);
    default:
      return const Icon(Icons.format_align_right);
  }
}

void Function([Intent?]) _getShortcutCallback({
  VoidCallback? onPressed,
  StyledEditingController<StyledText>? controller,
  FocusNode? propagateTo,
  required StyledText Function(StyledText) styler,
}) {
  return onPressed != null
      ? ([_]) => onPressed()
      : ([_]) {
          controller!.addStyle(styler(StyledText(range: controller.selection)));
          propagateTo?.requestFocus();
        };
}
