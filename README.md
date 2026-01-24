<a href="https://evan361425.github.io/flutter-editor-ant/">
  <h1 align="center">
    <img alt="EditorAnt" src="https://raw.githubusercontent.com/evan361425/flutter-editor-ant/master/doc/editor-ant.png">
  </h1>
</a>

[![codecov](https://codecov.io/gh/evan361425/flutter-editor-ant/branch/master/graph/badge.svg?token=kLLR8QWK9l)](https://codecov.io/gh/evan361425/flutter-editor-ant)
[![Codacy Badge](https://app.codacy.com/project/badge/Grade/003d6ab544314dee887aa57631e856c9)](https://www.codacy.com/gh/evan361425/flutter-editor-ant/dashboard?utm_source=github.com&amp;utm_medium=referral&amp;utm_content=evan361425/flutter-editor-ant&amp;utm_campaign=Badge_Grade)
[![Pub Version](https://img.shields.io/pub/v/editor_ant)](https://pub.dev/packages/editor_ant)

`EditorAnt` simplifies rich text editing by providing a clean interface and essential pre-built widgets.

> This package is separated from my project [POS-System](https://github.com/evan361425/flutter-pos-system).

Play it yourself by visiting the [online demo page](https://evan361425.github.io/flutter-editor-ant/)!

> See more details in [example](example/README.md).

## Why Another Rich Text Editor

<details>
<summary>Known Packages</summary>

Only for rich text, not coding or markdown:

- [flutter_quill](https://pub.dev/packages/flutter_quill)
- [fleather](https://pub.dev/packages/fleather)
- [appflowy_editor](https://pub.dev/packages/appflowy_editor)
- [super_editor](https://pub.dev/packages/super_editor)

</details>

This dependency-free editor leverages the native Flutter editor functionality
without the need for extensive widget customization.
Our goal is to keep it lightweight and developer-friendly.

The core components include:

- **Controller**: An extension of `TextEditingController` that can be passed directly to a `TextField`.
- **Wrapper**: Facilitates button styling (e.g., bold, italic) and shortcut support with minimal code.
- **Abstract Classes**: Provides styling interfaces such as `StyledRange`.
- **Demo Implementation**: Includes pre-built support for `StyledText` features like bold, italic, underline, font size, and colors.

## Installation

```bash
flutter pub add editor_ant
```

## Usage

The main widget `StyledEditingController` that can be pass directly to a `TextField`.

```dart
_controller = StyledEditingController<StyledText>();
TextField(
  controller: _controller,
  decoration: const InputDecoration.collapsed(hintText: 'Start typing...'),
);
```

Above [`StyledText`](lib/src/ant/styled_text.dart) is a built-in styling instructor,
below simplified its implementation:

```dart
class StyledText extends StyledRange<StyledText> {
  final bool isBold;

  StyledText({
    required super.range,
    this.isBold = false,
  });

  @override
  StyledText copyWith({int? start, int? end, bool isBold = false}) => StyledText(
      range: TextRange(start: start ?? range.start, end: end ?? range.end),
      isBold: isBold ? true : this.isBold,
    );

  @override
  StyledText toggleWith(StyledText other, {int? start, int? end, bool toggle = true}) => StyledText(
      range: TextRange(start: start ?? range.start, end: end ?? range.end),
      isBold: other.isBold ? !isBold || !toggle : isBold,
    );

  @override
  StyledText combine(StyledText other) => StyledText(
      range: TextRange(start: range.start, end: other.range.end),
      isBold: isBold && other.isBold,
    );

  @override
  bool hasSameToggleState(StyledText other) {
    if (other.isBold) {
      return isBold;
    }
    return false;
  }

  @override
  // use for change notifier
  bool operator ==(Object other) => other is StyledText &&
        isBold == other.isBold;

  @override
  TextStyle toTextStyle() => TextStyle(
      fontWeight: isBold ? FontWeight.bold : null,
    );

  @override
  int get hashCode => Object.hash(range, isBold);
}
```

And now you can use the method `addStyle` to toggled bold style in the menu bar.

```dart
IconButton(
  icon: const Icon(Icons.format_bold),
  onPressed: () {
    _controller.addStyle(StyledText(range: _controller.selection, isBold: true));
  },
)
```

## Known Issues

- Not support undo/redo, see [issue #3](https://github.com/evan361425/flutter-editor-ant/issues/3)
