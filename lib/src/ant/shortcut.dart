import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Helper class to define a keyboard shortcut
class Shortcut {
  final ShortcutIntent intent;
  final ShortcutActivator activator;
  final void Function([Intent?]) onInvoke;

  const Shortcut({required this.intent, required this.activator, required this.onInvoke});

  factory Shortcut.withCmdOrCtrl({required ShortcutIntent intent, required void Function([Intent?]) onInvoke}) {
    final ios = defaultTargetPlatform == TargetPlatform.macOS || defaultTargetPlatform == TargetPlatform.iOS;
    return Shortcut(
      intent: intent,
      activator: SingleActivator(intent.key, meta: ios, control: !ios),
      onInvoke: onInvoke,
    );
  }

  String formatTooltip(String tooltip, MaterialLocalizations localizations) {
    // TODO: should follow MenuAnchor's LocalizedShortcutLabeler
    final ios = defaultTargetPlatform == TargetPlatform.macOS || defaultTargetPlatform == TargetPlatform.iOS;
    final modifier = ios ? '⌘' : localizations.keyboardKeyControl;
    return '$tooltip ($modifier+${intent.key.keyLabel.toUpperCase()})';
  }
}

/// Intent has an [key] to define which key triggers the shortcut
abstract class ShortcutIntent extends Intent {
  final LogicalKeyboardKey key;

  const ShortcutIntent(this.key);
}

/// Intent for bold style, use `b`
class BoldIntent extends ShortcutIntent {
  const BoldIntent() : super(LogicalKeyboardKey.keyB);
}

/// Intent for italic style, use `i`
class ItalicIntent extends ShortcutIntent {
  const ItalicIntent() : super(LogicalKeyboardKey.keyI);
}

/// Intent for strikethrough style, use `s`
class StrikethroughIntent extends ShortcutIntent {
  const StrikethroughIntent() : super(LogicalKeyboardKey.keyS);
}

/// Intent for underline style, use `u`
class UnderlineIntent extends ShortcutIntent {
  const UnderlineIntent() : super(LogicalKeyboardKey.keyU);
}
