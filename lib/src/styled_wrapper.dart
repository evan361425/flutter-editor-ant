import 'package:editor_ant/editor_ant.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// [StyledWrapper] facilitates button styling (e.g., bold, italic) and shortcut support with minimal code.
class StyledWrapper<T extends StyledRange<T>> extends StatefulWidget {
  /// Controller managing the styled text.
  final StyledEditingController<T> controller;

  /// Focus node for the styled text editor.
  final FocusNode? focusNode;

  /// List of styling intents (e.g., bold, italic).
  final List<StyledIntent<T>> intents;

  /// Child widget to be wrapped.
  final Widget child;

  const StyledWrapper({
    super.key,
    required this.controller,
    this.focusNode,
    this.intents = const [],
    required this.child,
  });

  /// Retrieve the nearest [StyledWrapperState] from the widget tree.
  static StyledWrapperState<U>? maybeOf<U extends StyledRange<U>>(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<_StyledScope<U>>();
    return scope?._styledState;
  }

  /// Retrieve the nearest [StyledWrapperState] from the widget tree, asserting its existence.
  static StyledWrapperState<U> of<U extends StyledRange<U>>(BuildContext context) {
    final StyledWrapperState<U>? state = maybeOf<U>(context);
    assert(
      state != null,
      'StyledWrapper.of() was called with a context '
      'that does not contain a StyledWrapper widget.\n'
      'No StyledWrapper widget ancestor could be found '
      'starting from the context that was passed to StyledWrapper.of(). '
      'This can happen because you are using a widget '
      'that looks for a StyledWrapper ancestor, but no such ancestor exists.\n'
      'The context used was:\n'
      '  $context',
    );
    return state!;
  }

  @override
  StyledWrapperState<T> createState() => StyledWrapperState<T>();
}

/// State class for [StyledWrapper].
class StyledWrapperState<T extends StyledRange<T>> extends State<StyledWrapper<T>> {
  late StyledEditingController<T> controller;

  late FocusNode? focusNode;

  late final Map<Type, Object? Function([Intent?])> _invoker;

  @override
  Widget build(BuildContext context) {
    return Shortcuts(
      shortcuts: <ShortcutActivator, Intent>{for (final intent in widget.intents) intent.activator: intent},
      child: Actions(
        actions: <Type, Action<Intent>>{
          for (final intent in widget.intents)
            intent.runtimeType: CallbackAction<Intent>(onInvoke: _invoker[intent.runtimeType]!),
        },
        child: _StyledScope(styledState: this, child: widget.child),
      ),
    );
  }

  @override
  void didUpdateWidget(covariant StyledWrapper<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.dispose();
      controller = widget.controller;
    }
    if (oldWidget.focusNode != widget.focusNode) {
      oldWidget.focusNode?.dispose();
      focusNode = widget.focusNode;
    }
  }

  @override
  void initState() {
    controller = widget.controller;
    focusNode = widget.focusNode;
    _invoker = {
      for (final intent in widget.intents)
        intent.runtimeType: ([Intent? i]) {
          controller.addStyle(intent.styler(controller.selection));
          widget.focusNode?.requestFocus();
          return null;
        },
    };
    super.initState();
  }

  /// Retrieve the [StyledIntent] of a specific type which can be used to create buttons like tooltips.
  StyledIntent? getIntent(Type intentType) {
    final idx = widget.intents.indexWhere((intent) => intent.runtimeType == intentType);
    return idx != -1 ? widget.intents[idx] : null;
  }

  /// Retrieve the invoker function for a specific intent type.
  ///
  /// This function can be used to trigger the associated action.
  VoidCallback getInvoker(Type intentType) {
    return _invoker[intentType]!;
  }
}

/// Represents an intent for styling text with a keyboard shortcut.
class StyledIntent<T extends StyledRange<T>> extends Intent {
  /// The keyboard shortcut activator for this intent.
  final SingleActivator activator;

  /// The function that applies the styling to a given text range.
  ///
  /// For example, it could apply bold or italic styles.
  /// ```dart
  /// (range) => StyledText(range: range, isBold: true);
  /// ```
  final T Function(TextRange) styler;

  const StyledIntent({required this.activator, required this.styler});

  /// Format the tooltip to include the keyboard shortcut.
  String formatTooltip(String tooltip, MaterialLocalizations localizations) {
    // TODO: should follow MenuAnchor's LocalizedShortcutLabeler
    // https://github.com/flutter/flutter/blob/flutter-3.41-candidate.0/packages/flutter/lib/src/material/menu_anchor.dart#L2113
    final ios = defaultTargetPlatform == TargetPlatform.macOS || defaultTargetPlatform == TargetPlatform.iOS;
    String modifier = ios ? '⌘ ' : '${localizations.keyboardKeyControl}+';
    if (activator.shift) {
      modifier += ios ? '⇧ ' : '${localizations.keyboardKeyShift}+';
    }
    return '$tooltip ($modifier${activator.trigger.keyLabel.toUpperCase()})';
  }
}

class _StyledScope<T extends StyledRange<T>> extends InheritedWidget {
  const _StyledScope({required super.child, required StyledWrapperState<T> styledState}) : _styledState = styledState;

  final StyledWrapperState<T> _styledState;

  @override // coverage:ignore-line
  bool updateShouldNotify(_StyledScope old) => false;
}
