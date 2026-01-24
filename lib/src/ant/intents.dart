import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../styled_wrapper.dart';
import 'styled_text.dart';

/// Intent for bold style, use `b`
class BoldIntent extends StyledIntent<StyledText> {
  const BoldIntent({required super.activator, required super.styler});

  factory BoldIntent.basic() {
    return BoldIntent(
      activator: _activatorWithCmdOrCtrl(LogicalKeyboardKey.keyB),
      styler: (range) => StyledText(range: range).copyWith(isBold: true),
    );
  }
}

/// Intent for italic style, use `i`
class ItalicIntent extends StyledIntent<StyledText> {
  const ItalicIntent({required super.activator, required super.styler});

  factory ItalicIntent.basic() {
    return ItalicIntent(
      activator: _activatorWithCmdOrCtrl(LogicalKeyboardKey.keyI),
      styler: (range) => StyledText(range: range).copyWith(isItalic: true),
    );
  }
}

/// Intent for strikethrough style, use `shift + s`
class StrikethroughIntent extends StyledIntent<StyledText> {
  const StrikethroughIntent({required super.activator, required super.styler});

  factory StrikethroughIntent.basic() {
    return StrikethroughIntent(
      activator: _activatorWithCmdOrCtrl(LogicalKeyboardKey.keyS, shift: true),
      styler: (range) => StyledText(range: range).copyWith(isStrikethrough: true),
    );
  }
}

/// Intent for underline style, use `u`
class UnderlineIntent extends StyledIntent<StyledText> {
  const UnderlineIntent({required super.activator, required super.styler});

  factory UnderlineIntent.basic() {
    return UnderlineIntent(
      activator: _activatorWithCmdOrCtrl(LogicalKeyboardKey.keyU),
      styler: (range) => StyledText(range: range).copyWith(isUnderline: true),
    );
  }
}

SingleActivator _activatorWithCmdOrCtrl(LogicalKeyboardKey key, {bool shift = false}) {
  final ios = defaultTargetPlatform == TargetPlatform.macOS || defaultTargetPlatform == TargetPlatform.iOS;
  return SingleActivator(key, meta: ios, control: !ios, shift: shift);
}
