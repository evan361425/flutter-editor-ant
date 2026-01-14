# Undo/Redo for Styling

This document demonstrates how to use the undo/redo functionality for text styling in EditorAnt.

## API Overview

The `StyledEditingController` now supports undo/redo for styling operations with the following methods:

- `bool canUndo()` - Check if undo is available
- `bool canRedo()` - Check if redo is available  
- `void undo()` - Undo the last styling change
- `void redo()` - Redo the last undone styling change

## Usage Example

```dart
import 'package:editor_ant/editor_ant.dart';
import 'package:flutter/material.dart';

class EditorWithUndoRedo extends StatefulWidget {
  @override
  State<EditorWithUndoRedo> createState() => _EditorWithUndoRedoState();
}

class _EditorWithUndoRedoState extends State<EditorWithUndoRedo> {
  late final StyledEditingController<StyledText> _controller;
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _controller = StyledEditingController<StyledText>();
    _focusNode = FocusNode();
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Toolbar with undo/redo buttons
        Row(
          children: [
            IconButton(
              icon: Icon(Icons.undo),
              onPressed: _controller.canUndo() ? () {
                setState(() {
                  _controller.undo();
                });
              } : null,
            ),
            IconButton(
              icon: Icon(Icons.redo),
              onPressed: _controller.canRedo() ? () {
                setState(() {
                  _controller.redo();
                });
              } : null,
            ),
            // Style buttons
            IconButton(
              icon: Icon(Icons.format_bold),
              onPressed: () {
                final selection = _controller.selection;
                if (!selection.isCollapsed) {
                  _controller.addStyle(
                    StyledText(range: selection, isBold: true),
                  );
                  setState(() {});
                }
              },
            ),
          ],
        ),
        // Editor
        Expanded(
          child: TextField(
            controller: _controller,
            focusNode: _focusNode,
            maxLines: null,
            decoration: InputDecoration(border: OutlineInputBorder()),
          ),
        ),
      ],
    );
  }
}
```

## How It Works

1. **History Tracking**: The controller maintains a history stack of style states
2. **Automatic Saving**: When you apply a style (via `addStyle()`), the current state is saved before the change
3. **Undo**: Restores the previous state from history
4. **Redo**: Restores the next state if available
5. **History Clearing**: When you make a new change after undoing, the redo history is cleared

## Important Notes

- Undo/redo only affects **styling changes**, not text content changes
- Text editing undo/redo is handled by Flutter's default `TextEditingController`
- The history is maintained in memory and cleared when the controller is disposed
- Collapsed styles (cursor position styling) don't trigger history saves

## Keyboard Shortcuts

You can combine undo/redo with keyboard shortcuts:

```dart
Shortcuts(
  shortcuts: {
    LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyZ): 
      UndoIntent(),
    LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyY): 
      RedoIntent(),
  },
  child: Actions(
    actions: {
      UndoIntent: CallbackAction<UndoIntent>(
        onInvoke: (_) => controller.undo(),
      ),
      RedoIntent: CallbackAction<RedoIntent>(
        onInvoke: (_) => controller.redo(),
      ),
    },
    child: TextField(controller: controller),
  ),
)
```

## Testing

The package includes comprehensive tests for undo/redo functionality. See `test/undo_redo_test.dart` for examples of:

- Single and multiple undo/redo operations
- Toggle behavior (applying and removing styles)
- History clearing when making new changes
- State consistency across complex operations
