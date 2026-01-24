import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

import '../styled_editing_controller.dart';
import '../styled_range.dart';
import '../styled_wrapper.dart';
import 'intents.dart';
import 'styled_text.dart';

/// Simple button to toggle bold style in [StyledText]
class BoldButton extends StatelessWidget {
  final ValueNotifier<StyledText?> value;
  final VoidCallback? onPressed;
  final String tooltip;

  const BoldButton({super.key, required this.value, this.onPressed, this.tooltip = 'Bold'});

  @override
  Widget build(BuildContext context) {
    final intent = StyledWrapper.maybeOf(context)?.getIntent(BoldIntent);
    return ToggleableButton(
      value: value,
      icon: const Icon(Icons.format_bold),
      tooltip: intent?.formatTooltip(tooltip, MaterialLocalizations.of(context)) ?? tooltip,
      predicate: (style) => style.isBold,
      onPressed: () {
        StyledWrapper.maybeOf(context)?.getInvoker(BoldIntent)();
        onPressed?.call();
      },
    );
  }
}

/// Simple button to toggle italic style in [StyledText]
class ItalicButton extends StatelessWidget {
  final ValueNotifier<StyledText?> value;
  final VoidCallback? onPressed;
  final String tooltip;

  const ItalicButton({super.key, required this.value, this.onPressed, this.tooltip = 'Italic'});

  @override
  Widget build(BuildContext context) {
    final intent = StyledWrapper.maybeOf(context)?.getIntent(ItalicIntent);
    return ToggleableButton(
      value: value,
      icon: const Icon(Icons.format_italic),
      tooltip: intent?.formatTooltip(tooltip, MaterialLocalizations.of(context)) ?? tooltip,
      predicate: (style) => style.isItalic,
      onPressed: () {
        StyledWrapper.maybeOf(context)?.getInvoker(ItalicIntent)();
        onPressed?.call();
      },
    );
  }
}

/// Simple button to toggle strikethrough style in [StyledText]
class StrikethroughButton extends StatelessWidget {
  final ValueNotifier<StyledText?> value;
  final VoidCallback? onPressed;
  final String tooltip;

  const StrikethroughButton({super.key, required this.value, this.onPressed, this.tooltip = 'Strikethrough'});

  @override
  Widget build(BuildContext context) {
    final intent = StyledWrapper.maybeOf(context)?.getIntent(StrikethroughIntent);
    return ToggleableButton(
      value: value,
      icon: const Icon(Icons.strikethrough_s),
      tooltip: intent?.formatTooltip(tooltip, MaterialLocalizations.of(context)) ?? tooltip,
      predicate: (style) => style.isStrikethrough,
      onPressed: () {
        StyledWrapper.maybeOf(context)?.getInvoker(StrikethroughIntent)();
        onPressed?.call();
      },
    );
  }
}

/// Simple button to toggle underline style in [StyledText]
class UnderlineButton extends StatelessWidget {
  final ValueNotifier<StyledText?> value;
  final VoidCallback? onPressed;
  final String tooltip;

  const UnderlineButton({super.key, required this.value, this.onPressed, this.tooltip = 'Underline'});

  @override
  Widget build(BuildContext context) {
    final intent = StyledWrapper.maybeOf(context)?.getIntent(UnderlineIntent);
    return ToggleableButton(
      value: value,
      icon: const Icon(Icons.format_underline),
      tooltip: intent?.formatTooltip(tooltip, MaterialLocalizations.of(context)) ?? tooltip,
      predicate: (style) => style.isUnderline,
      onPressed: () {
        StyledWrapper.maybeOf(context)?.getInvoker(UnderlineIntent)();
        onPressed?.call();
      },
    );
  }
}

/// A simple text field to select font size for [StyledText]
class FontSizeField extends StatefulWidget {
  final TextEditingController controller;
  final StyledEditingController<StyledText> styledTextController;
  final FocusNode? styledTextFocusNode;
  final double width;

  const FontSizeField({
    super.key,
    required this.controller,
    required this.styledTextController,
    this.styledTextFocusNode,
    this.width = 52,
  });

  @override
  State<FontSizeField> createState() => _FontSizeFieldState();
}

class _FontSizeFieldState extends State<FontSizeField> {
  late final FocusNode _focusNode;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.width,
      child: Autocomplete<int>(
        textEditingController: widget.controller,
        focusNode: _focusNode,
        displayStringForOption: (int option) => option.toString(),
        onSelected: (int size) {
          widget.styledTextController.addStyle(
            StyledText(range: widget.styledTextController.selection).copyWith(fontSize: size),
          );
          widget.styledTextFocusNode?.requestFocus();
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

  @override
  void initState() {
    widget.styledTextController.activeStyle.addListener(_reset);
    _focusNode = FocusNode(
      onKeyEvent: (FocusNode node, KeyEvent event) {
        if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.escape) {
          _reset();
          widget.styledTextFocusNode?.requestFocus();
          return KeyEventResult.handled; // Prevent the event from bubbling up
        }
        return KeyEventResult.ignored;
      },
    );
    super.initState();
  }

  @override
  dispose() {
    widget.styledTextController.activeStyle.removeListener(_reset);
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant FontSizeField oldWidget) {
    if (oldWidget.styledTextController != widget.styledTextController) {
      oldWidget.styledTextController.activeStyle.removeListener(_reset);
      widget.styledTextController.activeStyle.addListener(_reset);
    }
    super.didUpdateWidget(oldWidget);
  }

  _reset() {
    widget.controller.text = (widget.styledTextController.activeStyle.value?.fontSize ?? defaultFontSize)
        .round()
        .toString();
  }
}

/// A simple color selector to select text color for [StyledText]
class ColorSelector extends StatelessWidget {
  final ValueNotifier<StyledText?> value;
  final MenuController controller;
  final List<List<Color?>> colors;
  final List<String?>? colorNames;
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
    final defaultColor = Theme.of(context).textTheme.bodyMedium?.color ?? Colors.black87;
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
                      color: value?.color ?? defaultColor,
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
                  icon: color == null ? Icon(Icons.format_color_reset) : Icon(Icons.circle, color: color),
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
                        StyledText(
                          range: styledEditingController.selection,
                        ).copyWith(color: color, resetColor: color == null),
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
