<a href="https://evan361425.github.io/flutter-editor-ant/">
  <h1 align="center">
    <img alt="EditorAnt" src="https://raw.githubusercontent.com/evan361425/flutter-editor-ant/master/doc/editor-ant.png">
  </h1>
</a>

[![codecov](https://codecov.io/gh/evan361425/flutter-editor-ant/branch/master/graph/badge.svg?token=kLLR8QWK9l)](https://codecov.io/gh/evan361425/flutter-editor-ant)
[![Codacy Badge](https://app.codacy.com/project/badge/Grade/003d6ab544314dee887aa57631e856c9)](https://www.codacy.com/gh/evan361425/flutter-editor-ant/dashboard?utm_source=github.com&amp;utm_medium=referral&amp;utm_content=evan361425/flutter-editor-ant&amp;utm_campaign=Badge_Grade)
[![Pub Version](https://img.shields.io/pub/v/editor_ant)](https://pub.dev/packages/editor_ant)

`EditorAnt` provide simple interface and demo widgets to create rich text editor.

> This package is separated from my project [POS-System](https://github.com/evan361425/flutter-pos-system).

Play it yourself by visiting the [online demo page](https://evan361425.github.io/flutter-editor-ant/)!

> See more details in [example](example/README.md).

## Installation

```bash
flutter pub add editor_ant
```

## Usage

The main widget `StyledEditingController` provide a method `addStyle` to apply
custom style in editing text.

```dart
_controller = StyledEditingController<StyledText>();
TextField(
  controller: _controller,
  decoration: const InputDecoration.collapsed(hintText: 'Start typing...'),
);
```

Above `StyledText` is a demo styling instructor, below is a simplified implements:

```dart
class StyledText extends StyledRange<StyledText> {
  final bool isBold;

  StyledText({
    required super.range,
    this.isBold = false,
  });

  @override
  StyledText copyWith({
    int? start,
    int? end,
    StyledText? other,
    bool toggle = false,
    bool isBold = false,
  }) {
    return StyledText(
      range: TextRange(start: start ?? range.start, end: end ?? range.end),
      isBold: isBold
          ? true
          : other?.isBold == true
          ? (!this.isBold || !toggle)
          : this.isBold,
    );
  }

  @override
  bool hasSameToggleState(StyledText other) {
    if (other.isBold) {
      return isBold;
    }
    return false;
  }

  @override
  // use for change notifier
  bool operator ==(Object other) {
    return other is StyledText &&
        isBold == other.isBold;
  }

  @override
  TextStyle toTextStyle() {
    return TextStyle(
      fontWeight: isBold ? FontWeight.bold : null,
    );
  }

  @override
  int get hashCode => Object.hash(range, isBold);
}
```

And now you can use the toggled bold style in the menu bar.

```dart
IconButton(
  icon: const Icon(Icons.format_bold),
  onPressed: () {
    _controller.addStyle(StyledText(range: _controller.selection, isBold: true));
  },
)
```
