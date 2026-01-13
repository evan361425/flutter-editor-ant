# EditorAnt Copilot Instructions

## Project Overview

EditorAnt is a Flutter package providing a rich text editor with styled text ranges. Core architecture:

- **`StyledEditingController<T>`**: Main controller extending `TextEditingController` that manages styled text ranges
- **`StyledRange<T>`**: Abstract base class for defining custom text styles (position + style attributes)
- **`StyledText`**: Default implementation supporting bold, italic, underline, strikethrough, font size, and color
- **`ant/`**: Pre-built UI components (buttons, shortcuts, color pickers) for common editor operations

## Architecture Patterns

### Generic Style System
The package uses a generic type parameter `<T extends StyledRange<T>>` pattern throughout. Users implement custom `StyledRange` subclasses with their own style properties. Key methods:
- `copyWith()`: Creates modified copies, handles toggle logic when applying styles
- `hasSameToggleState()`: Determines if a style should be toggled off when reapplied
- `toTextStyle()`: Converts the range to Flutter `TextStyle` for rendering

### Style Range Management
Styles are stored as non-overlapping ranges in `StyledEditingController.styles`. When adding styles:
1. Find overlapping existing ranges via `_getOverlapRange()`
2. Normalize overlaps via `_normalizeStyles()` - splits, merges, or adjusts ranges
3. Merge adjacent ranges with identical styles via `_mergeStyles()`
4. Notify listeners to trigger re-render

Active style tracking: When selection is collapsed, `activeStyle` holds the style to apply to new text.

## Development Workflow

### Testing
```bash
make test                # Run all tests
make test-coverage       # Generate coverage report in coverage/html/
```

Tests use the example app (`example/lib/main.dart`) as test harness. Import with:
```dart
import '../example/lib/main.dart';
```

Enable debug logging in tests: `EditorAntConfig.enableLogging = true;`

### Code Style
- Line length: 120 characters (enforced by `make format`)
- Uses `flutter_lints` package for linting
- Format before committing: `make format`

### Building Example
```bash
make build-example       # Builds web version for GitHub Pages (base-href: /flutter-editor-ant/)
make serve-example       # Serves locally at http://localhost:8000
```

## Key Conventions

### Range Operations
Text positions use Flutter's `TextRange` (0-indexed, end-exclusive). Range relationship methods:
- `leftOverlap()`, `rightOverlap()`, `inclusiveOf()`: Detect overlap patterns
- `inConnected()`: Check if ranges are adjacent
- `moveRange(startOffset, endOffset)`: Shift range positions

### Controller Lifecycle
`StyledEditingController` listens to text changes via `_onChanged()`:
- On text insertion/deletion: adjusts style range positions
- On selection change: updates `activeStyle` if selection is collapsed
- Always call `notifyListeners()` after style modifications (unless `inProcess=true`)

### Toggle Behavior
When applying a style over a fully-styled range, it toggles OFF by default. Override via `_isRangeToggleable()` checks. The `copyWith(toggle: true)` parameter implements this logic.

## Common Tasks

### Adding New Style Attributes
1. Extend `StyledRange<YourStyle>` in new class
2. Add properties and implement required methods
3. Handle in `copyWith()` with toggle logic
4. Convert to `TextStyle` in `toTextStyle()`

### Testing Style Operations
Helper functions in tests:
- `getTextSpans(tester)`: Extract rendered spans
- `getController(tester)`: Get controller instance
- `checkStyles(texts, styles, spans)`: Assert span properties

### Version Bumping
```bash
make bump               # Uses @evan361425/version-bumper to update pubspec.yaml
```

## Integration Points

- Package name: `editor_ant`
- Example app tests import from package using relative path
- GitHub Pages deployment at `/flutter-editor-ant/` base path
- Coverage reporting via `genhtml` (outputs to `coverage/html/`)
