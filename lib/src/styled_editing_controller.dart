import 'package:editor_ant/src/styled_range.dart';
import 'package:editor_ant/src/util.dart';
import 'package:flutter/widgets.dart';

/// A [TextEditingController] that supports styled text ranges.
class StyledEditingController<T extends StyledRange<T>> extends TextEditingController {
  String _previousText = '';
  final List<T> styles = [];
  ValueNotifier<T?> activeStyle = ValueNotifier<T?>(null);

  StyledEditingController({super.text}) {
    _previousText = text;
    addListener(_onChanged);
  }

  @override
  TextSpan buildTextSpan({required BuildContext context, TextStyle? style, required bool withComposing}) {
    assert(!value.composing.isValid || !withComposing || value.isComposingRangeValid);
    // If the composing range is out of range for the current text, ignore it to
    // preserve the tree integrity, otherwise in release mode a RangeError will
    // be thrown and this EditableText will be built with a broken subtree.
    final bool composingRegionOutOfRange = !value.isComposingRangeValid || !withComposing;

    if (composingRegionOutOfRange) {
      return TextSpan(style: style, children: _buildStyledSpans(text, 0));
    }

    final TextStyle composingStyle =
        style?.merge(const TextStyle(decoration: TextDecoration.underline)) ??
        const TextStyle(decoration: TextDecoration.underline);

    return TextSpan(
      style: style,
      children: <TextSpan>[
        TextSpan(children: _buildStyledSpans(value.composing.textBefore(value.text), 0)),
        TextSpan(style: composingStyle, text: value.composing.textInside(value.text)),
        TextSpan(children: _buildStyledSpans(value.composing.textAfter(value.text), value.composing.start)),
      ],
    );
  }

  @override
  void dispose() {
    removeListener(_onChanged);
    super.dispose();
  }

  /// Add a new [StyledRange] to the existing styles.
  ///
  /// If the new style overlaps with existing styles, it will adjust the existing
  /// styles accordingly.
  ///
  /// - [inProcess] indicates whether this call is part of a larger operation,
  /// and if true, will not notify listeners after adding the style.
  void addStyle(T other, {bool inProcess = false}) {
    if (other.range.isCollapsed) {
      if (!other.range.isValid) {
        other = other.copyWith(start: 0, end: 0);
      }
      activeStyle.value = (activeStyle.value?.toggleWith(other) ?? other);
      if (!activeStyle.value!.range.isCollapsed) {
        activeStyle.value!.range = other.range;
      }
      if (EditorAntConfig.enableLogging) {
        logging(activeStyle.value!.toString(), 'Collapse');
      }
      return;
    }

    final range = _getOverlapRange(other.range);
    if (range[1] == -1) {
      styles.insert(range[0], other);
      if (EditorAntConfig.enableLogging) {
        logging('$other at ${range[0]}', 'Inserted');
      }
      if (!inProcess) {
        _mergeStyles();
        notifyListeners();
      }
      return;
    }

    final toggle = inProcess ? false : _isRangeToggleable(other, styles.sublist(range[0], range[1]));
    final result = _normalizeStyles(other, styles.sublist(range[0], range[1]), toggle);

    styles.removeRange(range[0], range[1]);
    styles.insertAll(range[0], result.where((span) => !span.range.isCollapsed));
    if (EditorAntConfig.enableLogging) {
      logging(styles.join(', '), 'Inserted');
    }
    if (!inProcess) {
      _mergeStyles();
      notifyListeners();
    }
  }

  /// Handle text or selection changes and update style ranges accordingly
  void _onChanged() {
    if (!selection.isValid) {
      return;
    }

    final int oldLength = _previousText.length;
    final int newLength = text.length;

    _previousText = text;

    if (newLength > oldLength) {
      // Text was inserted
      final int length = newLength - oldLength;
      final int start = selection.start - length;

      for (final style in styles.reversed) {
        // TODO: what if text direction is RTL?
        // Before, after, overlap
        if (style.range.end < start) {
          break;
        } else if (style.range.start >= start) {
          style.moveRange(length, length);
        } else {
          style.moveRange(0, length);
          break;
        }
      }

      if (activeStyle.value?.range.isCollapsed == true) {
        final style = activeStyle.value!.copyWith(start: start, end: start + length);
        addStyle(style, inProcess: true);
        // Let _mergeStyles reset the active style
        activeStyle.value = null;
      }
    } else if (newLength < oldLength) {
      // Text was deleted
      final int length = oldLength - newLength;
      final int start = selection.start;
      final int end = start + length;

      // Update all styles affected by deletion
      final List<T> result = [];
      for (final style in styles) {
        // Before, after, overlap
        if (style.range.end <= start) {
          result.add(style);
        } else if (style.range.start >= end) {
          result.add(style..moveRange(-length, -length));
        } else {
          final int newStart = style.range.start < start ? style.range.start : start;
          final int newEnd = style.range.end > end ? style.range.end - length : start;

          if (newEnd > newStart) {
            result.add(style..moveRange(newStart - style.range.start, newEnd - style.range.end));
          }
        }
      }
      styles.clear();
      styles.addAll(result);
    } else {
      _resetActiveStyle();
      // TODO: If text changed, we need to reset styles in the changed range,
      // for example copy/paste same size of text.
      // but this will check character by character every time when cursor moves,
      return;
    }

    _mergeStyles();
  }

  /// Build TextSpan with an offset
  ///
  /// The offset is used to adjust the indices of the styles when building
  /// the [TextSpan] for a substring of the full text.
  List<TextSpan> _buildStyledSpans(String text, int offset) {
    final List<TextSpan> children = [];
    int currentIndex = offset;

    for (final style in styles) {
      // Add unstyled text before this span
      if (currentIndex < style.range.start) {
        children.add(TextSpan(text: text.substring(currentIndex - offset, style.range.start - offset)));
      }

      children.add(
        TextSpan(
          style: style.toTextStyle(),
          text: text.substring(style.range.start - offset, style.range.end - offset),
        ),
      );

      currentIndex = style.range.end;
    }

    // Add remaining unstyled text
    if (currentIndex < text.length) {
      children.add(TextSpan(text: text.substring(currentIndex - offset)));
    }

    return children;
  }

  /// Split existing styles and apply the new style [target].
  List<T> _normalizeStyles(T target, List<T> others, bool toggle) {
    final result = <T>[];
    for (final style in others) {
      if (style.inclusiveOf(target)) {
        // left part
        result.add(style.copyWith(end: target.range.start));
        // overlap part
        result.add(style.toggleWith(target, start: target.range.start, end: target.range.end, toggle: toggle));
        // right part
        result.add(style.copyWith(start: target.range.end));
        target = target.copyWith(start: target.range.end); // mark as collapsed
        break;
      }

      if (style.leftOverlap(target)) {
        // left part
        result.add(style.copyWith(end: target.range.start));
        // overlap part
        result.add(style.toggleWith(target, start: target.range.start, toggle: toggle));
        // right part
        target = target.copyWith(start: style.range.end);
        continue;
      }

      if (style.rightOverlap(target)) {
        // left part
        result.add(target.copyWith(end: style.range.start));
        // overlap part
        result.add(style.toggleWith(target, end: target.range.end, toggle: toggle));
        // right part
        result.add(style.copyWith(start: target.range.end));
        target = target.copyWith(start: target.range.end); // mark as collapsed
        break;
      }

      // target inclusive of style
      if (EditorAntConfig.enableLogging) {
        logging('$target(new)[$style]', 'Position');
      }
      result.add(target.copyWith(end: style.range.start));
      result.add(style.toggleWith(target, toggle: toggle));
      target = target.copyWith(start: style.range.end);
    }

    if (!target.range.isCollapsed) {
      if (EditorAntConfig.enableLogging) {
        logging(target.toString(), 'Remained');
      }
      result.add(target);
    }

    return result;
  }

  /// Merge connected styles with the same style.
  void _mergeStyles() {
    for (int i = styles.length - 2; i >= 0; i--) {
      final style = styles[i];
      final next = styles[i + 1];
      if (style.inConnected(next) && next == style) {
        if (EditorAntConfig.enableLogging) {
          logging('$style + $next', 'Merging');
        }
        styles[i] = style.copyWith(end: next.range.end);
        styles.removeAt(i + 1);
      }
    }
    _resetActiveStyle();
  }

  /// Get the range of styles that overlap with [target].
  ///
  /// If no styles overlap, return the list containing the index where the target
  /// can be inserted and -1.
  ///
  /// Start index is inclusive, end index is exclusive.
  List<int> _getOverlapRange(TextRange target) {
    int start = -1;
    for (int i = 0; i < styles.length; i++) {
      final style = styles[i];
      if (style.range.start < target.end && style.range.end > target.start) {
        if (start == -1) {
          start = i;
        }
      } else if (start != -1) {
        return [start, i];
      }
    }
    if (start != -1) {
      return [start, styles.length];
    }

    final beforeAt = styles.indexWhere((sp) => sp.range.start >= target.end);
    return [beforeAt == -1 ? styles.length : beforeAt, -1];
  }

  /// Check if [target] is fully covered by existing [styles] with the same
  /// style.
  ///
  /// For example, if the target is bold from index 5 to 10, and there is an
  /// existing style that is bold from index 0 to 15,  then the target is fully
  /// styled.
  ///
  /// No need to consider connected styles here, as they are merged in [_mergeStyles].
  bool _isRangeToggleable(T target, List<T> styles) {
    if (target.range.isCollapsed) {
      return false;
    }

    int covered = target.range.start;
    for (final style in styles) {
      if (target.hasSameToggleState(style)) {
        if (covered < style.range.start) {
          return false;
        }
        covered = style.range.end;
      }
    }

    final result = covered >= target.range.end;
    if (result && EditorAntConfig.enableLogging) {
      logging('true', 'Toggling');
    }
    return result;
  }

  /// Find the current pointed style based on the cursor position.
  void _resetActiveStyle() {
    if (selection.isCollapsed &&
        activeStyle.value?.range.isCollapsed == true &&
        selection.start == activeStyle.value!.range.start) {
      return;
    }

    // Use the styles in the selected range to determine the active style.
    final start = selection.isCollapsed ? selection.start : selection.start + 1;

    final List<T> checkStyles = [];
    for (final style in styles) {
      // check connected styles
      if (checkStyles.isNotEmpty) {
        final last = checkStyles.last;
        if (style.range.start == last.range.end) {
          checkStyles.add(style);
          // finally setup active style from multiple connected styles
          if (selection.end <= style.range.end) {
            activeStyle.value = checkStyles.reduce((value, element) {
              return value.combine(element);
            });
            if (EditorAntConfig.enableLogging) {
              logging('Merged: ${activeStyle.value}', 'Active');
            }
            return;
          }
        } else {
          break;
        }
      }

      // we only use style before the cursor, if selection end is after style
      // end, then selection may cross multiple styles, we add [checkStyles].
      if (start > style.range.start && start <= style.range.end) {
        if (selection.end > style.range.end) {
          checkStyles.add(style);
        } else {
          activeStyle.value = style;
          if (EditorAntConfig.enableLogging) {
            logging(activeStyle.value.toString(), 'Active');
          }
          return;
        }
      }
      if (style.range.start > selection.end) {
        break;
      }
    }

    if (EditorAntConfig.enableLogging) {
      logging('Null', 'Active');
    }
    activeStyle.value = null;
  }
}
