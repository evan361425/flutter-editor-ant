import 'package:editor_ant/editor_ant.dart';
import 'package:flutter/material.dart';

void main() async {
  EditorAntConfig.enableLogging = true;
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp(fromTest: false));
}

class MyApp extends StatelessWidget {
  final bool fromTest;

  static final ValueNotifier<ThemeMode> themeMode = ValueNotifier(ThemeMode.system);

  const MyApp({super.key, this.fromTest = true});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: themeMode,
      builder: (context, value, child) {
        return MaterialApp(
          // use material 2 to fix `'shaders/ink_sparkle.frag' not found` error on Github Actions
          theme: ThemeData(useMaterial3: !fromTest, brightness: Brightness.light, fontFamily: 'Noto Sans TC'),
          darkTheme: ThemeData(useMaterial3: !fromTest, brightness: Brightness.dark, fontFamily: 'Noto Sans TC'),
          themeMode: value,
          home: Scaffold(body: _buildBody(context)),
        );
      },
    );
  }

  Widget _buildBody(BuildContext context) {
    if (fromTest) return _Editor();

    return Center(
      child: SizedBox(
        width: 600,
        height: 650,
        child: Stack(
          children: [
            Card(child: _Editor()),
            Positioned(
              bottom: 32,
              left: 0,
              right: 0,
              child: Opacity(
                opacity: 0.8,
                child: IgnorePointer(
                  ignoring: true,
                  child: SizedBox.square(dimension: 200, child: Image.asset('assets/editor-ant.png')),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Editor extends StatefulWidget {
  const _Editor();

  @override
  State<_Editor> createState() => _EditorState();
}

class _EditorState extends State<_Editor> {
  late final StyledEditingController<StyledText> _controller;
  late final FocusNode _focusNode;

  late final TextEditingController _fontSizeController;
  late final FocusNode _fontSizeFocusNode;
  late final MenuController _colorController;

  late final Shortcut _bold;
  late final Shortcut _italic;
  late final Shortcut _strikethrough;
  late final Shortcut _underline;

  final ValueNotifier<TextAlign> _textAlign = ValueNotifier(TextAlign.left);
  final MenuController _textAlignController = MenuController();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      children: [
        // Toolbar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHigh,
            border: Border(bottom: BorderSide(color: colorScheme.outlineVariant)),
            borderRadius: BorderRadius.only(topLeft: Radius.circular(8), topRight: Radius.circular(8)),
          ),
          height: 49,
          width: double.infinity,
          child: Row(children: _buildToolbarButtons()),
        ),
        // Editor
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            width: double.infinity,
            height: double.infinity,
            child: _buildTextField(),
          ),
        ),
      ],
    );
  }

  List<Widget> _buildToolbarButtons() {
    return [
      Expanded(
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            spacing: 2.0,
            children: [
              FontSizeField(
                key: const Key('editor_ant.font_size_field'),
                controller: _fontSizeController,
                focusNode: _fontSizeFocusNode,
                styledEditingController: _controller,
                propagateTo: _focusNode,
              ),
              ColorSelector(
                value: _controller.activeStyle,
                controller: _colorController,
                colors: [
                  [Colors.black87, Colors.white, Colors.red, Colors.orange],
                  [Colors.yellow, Colors.green, Colors.blue, Colors.purple],
                ],
                styledEditingController: _controller,
                propagateTo: _focusNode,
              ),
              // Style buttons
              VerticalDivider(width: 1, thickness: 1, indent: 6, endIndent: 6),
              BoldButton(value: _controller.activeStyle, shortcut: _bold),
              ItalicButton(value: _controller.activeStyle, shortcut: _italic),
              StrikethroughButton(value: _controller.activeStyle, shortcut: _strikethrough),
              UnderlineButton(value: _controller.activeStyle, shortcut: _underline),
              // Paragraph styles
              VerticalDivider(width: 1, thickness: 1, indent: 6, endIndent: 6),
              TextAlignSelector(
                value: _textAlign,
                controller: _textAlignController,
                onSelected: (align) {
                  _focusNode.requestFocus();
                },
              ),
            ],
          ),
        ),
      ),
      VerticalDivider(width: 2, thickness: 2, indent: 2, endIndent: 2),
      ToggleableButton(
        value: MyApp.themeMode,
        icon: Icon(Icons.dark_mode_outlined),
        onPressed: () {
          MyApp.themeMode.value = MyApp.themeMode.value == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
        },
        predicate: (themeMode) => themeMode == ThemeMode.dark,
      ),
    ];
  }

  Widget _buildTextField() {
    return Shortcuts(
      shortcuts: <ShortcutActivator, Intent>{
        _bold.activator: _bold.intent,
        _italic.activator: _italic.intent,
        _strikethrough.activator: _strikethrough.intent,
        _underline.activator: _underline.intent,
      },
      child: Actions(
        actions: <Type, Action<Intent>>{
          BoldIntent: CallbackAction<BoldIntent>(onInvoke: _bold.onInvoke),
          ItalicIntent: CallbackAction<ItalicIntent>(onInvoke: _italic.onInvoke),
          StrikethroughIntent: CallbackAction<StrikethroughIntent>(onInvoke: _strikethrough.onInvoke),
          UnderlineIntent: CallbackAction<UnderlineIntent>(onInvoke: _underline.onInvoke),
        },
        child: ValueListenableBuilder(
          valueListenable: _textAlign,
          builder: (context, value, child) {
            return TextField(
              key: const Key('editor_ant.editor'),
              controller: _controller,
              focusNode: _focusNode,
              textAlign: value,
              autofocus: true,
              maxLines: null,
              minLines: null,
              decoration: const InputDecoration.collapsed(hintText: 'Start typing...'),
            );
          },
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _controller = StyledEditingController<StyledText>();
    _controller.activeStyle.addListener(_resetFontSizeField);
    _focusNode = FocusNode();

    _colorController = MenuController();
    _fontSizeController = TextEditingController(text: defaultFontSize.toString());
    _fontSizeFocusNode = FontSizeField.createFocusNode(onEscape: _resetFontSizeField, propagateTo: _focusNode);

    _bold = BoldButton.createShortcut(controller: _controller, propagateTo: _focusNode);
    _italic = ItalicButton.createShortcut(controller: _controller, propagateTo: _focusNode);
    _strikethrough = StrikethroughButton.createShortcut(controller: _controller, propagateTo: _focusNode);
    _underline = UnderlineButton.createShortcut(controller: _controller, propagateTo: _focusNode);
  }

  @override
  void dispose() {
    _controller.activeStyle.removeListener(_resetFontSizeField);
    _controller.activeStyle.dispose();
    _controller.dispose();
    _focusNode.dispose();

    _fontSizeController.dispose();
    _fontSizeFocusNode.dispose();
    super.dispose();
  }

  void _resetFontSizeField() {
    _fontSizeController.text = (_controller.activeStyle.value?.fontSize ?? defaultFontSize).round().toString();
  }
}
