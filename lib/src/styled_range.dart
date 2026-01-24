import 'package:editor_ant/src/util.dart';
import 'package:flutter/widgets.dart';

/// An abstract class representing a styled range of text
abstract class StyledRange<T extends StyledRange<T>> {
  /// The text range represented by this styled range.
  TextRange range;

  StyledRange({required this.range});

  /// Check if this range overlaps with another range on the left side
  bool leftOverlap(StyledRange other) {
    final result = range.start < other.range.start && range.end > other.range.start && range.end < other.range.end;
    if (result && EditorAntConfig.enableLogging) {
      logging('$this --- $other(new)', 'Position');
    }
    return result;
  }

  /// Check if this range overlaps with another range on the right side
  bool rightOverlap(StyledRange other) {
    final result = range.start > other.range.start && range.start < other.range.end && range.end > other.range.end;
    if (result && EditorAntConfig.enableLogging) {
      logging('$other(new) --- $this', 'Position');
    }
    return result;
  }

  /// Check if this range fully includes another range
  bool inclusiveOf(StyledRange other) {
    final result = range.start <= other.range.start && range.end >= other.range.end;
    if (result && EditorAntConfig.enableLogging) {
      logging('$this[$other(new)]', 'Position');
    }

    return result;
  }

  /// Move the range by specified offsets
  void moveRange(int startOffset, int endOffset) {
    if (EditorAntConfig.enableLogging) {
      logging('$this ($startOffset, $endOffset)', 'Moving');
    }
    range = TextRange(start: range.start + startOffset, end: range.end + endOffset);
  }

  /// Check if this range is directly connected to another range
  bool inConnected(StyledRange other) {
    return range.end == other.range.start || range.start == other.range.end;
  }

  /// Create a copy of this range with modified properties
  ///
  /// - [start]: New start position
  /// - [end]: New end position
  T copyWith({int? start, int? end});

  /// If both this and [other] have the same toggle state, it will invert the state
  /// of this range based on [other]'s state.
  ///
  /// - [other]: The other styled range to compare with
  /// - [start]: Optional new start position for the returned range
  /// - [end]: Optional new end position for the returned range
  /// - [toggle]: Whether to toggle the state based on [other]'s state
  T toggleWith(T other, {int? start, int? end, bool toggle = true});

  /// Combine this range with another range, return true only if both ranges
  /// have the same toggle state
  T combine(T other);

  /// Check if this range has the same toggle state (e.g. bold) as another range
  bool hasSameToggleState(T other);

  /// Convert this range to a [TextStyle] representation
  TextStyle toTextStyle();
}
