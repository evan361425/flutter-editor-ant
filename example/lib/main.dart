import 'package:editor_ant/editor_ant.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

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
        final lightText = ThemeData(brightness: Brightness.light).textTheme;
        final darkText = ThemeData(brightness: Brightness.dark).textTheme;
        return MaterialApp(
          // use material 2 to fix `'shaders/ink_sparkle.frag' not found` error on Github Actions
          theme: ThemeData(
            useMaterial3: !fromTest,
            brightness: Brightness.light,
            textTheme: fromTest ? lightText : GoogleFonts.notoSansTcTextTheme(lightText),
            tooltipTheme: TooltipThemeData(preferBelow: false),
          ),
          darkTheme: ThemeData(
            useMaterial3: !fromTest,
            brightness: Brightness.dark,
            textTheme: fromTest ? darkText : GoogleFonts.notoSansTcTextTheme(darkText),
            tooltipTheme: TooltipThemeData(preferBelow: false),
          ),
          themeMode: value,
          home: Scaffold(body: SafeArea(child: _buildBody(context))),
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
  late final MenuController _colorController;

  final ValueNotifier<TextAlign> _textAlign = ValueNotifier(TextAlign.left);
  final MenuController _textAlignController = MenuController();
  final MenuController _placeholderController = MenuController();

  late final DynamicDatePlaceholder _datePlaceholder;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return StyledWrapper(
      controller: _controller,
      focusNode: _focusNode,
      intents: [BoldIntent.basic(), ItalicIntent.basic(), StrikethroughIntent.basic(), UnderlineIntent.basic()],
      child: Column(
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
      ),
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
              FontSizeField(key: const Key('editor_ant.font_size_field'), controller: _fontSizeController),
              ColorSelector(
                controller: _colorController,
                colors: [
                  [null, Colors.black87, Colors.white, Colors.grey],
                  [Colors.red, Colors.orange, Colors.amber, Colors.yellow],
                  [Colors.lime, Colors.green, Colors.blue, Colors.purple],
                ],
                colorNames: [
                  null,
                  'Black',
                  'White',
                  'Grey',
                  'Red',
                  'Orange',
                  'Amber',
                  'Yellow',
                  'Lime',
                  'Green',
                  'Blue',
                  'Purple',
                ],
              ),
              // Style buttons
              VerticalDivider(width: 1, thickness: 1, indent: 6, endIndent: 6),
              BoldButton(),
              ItalicButton(),
              StrikethroughButton(),
              UnderlineButton(),
              // Paragraph styles
              VerticalDivider(width: 1, thickness: 1, indent: 6, endIndent: 6),
              TextAlignSelector(value: _textAlign, controller: _textAlignController),
              PlaceholderSelector(
                controller: _placeholderController,
                placeholders: [
                  _datePlaceholder.placeholder,
                  TextPlaceholder(id: 'b', text: 'TemplateB'),
                  TextPlaceholder(id: 'c', text: 'TemplateC'),
                ],
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
    return ValueListenableBuilder(
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
    );
  }

  @override
  void initState() {
    super.initState();
    _controller = StyledEditingController<StyledText>();
    _focusNode = FocusNode();
    _colorController = MenuController();
    _fontSizeController = TextEditingController(text: defaultFontSize.toString());
    _datePlaceholder = DynamicDatePlaceholder('yyyy-MM-dd', getContext: () => context);
  }

  @override
  void dispose() {
    _controller.activeStyle.dispose();
    _controller.dispose();
    _focusNode.dispose();
    _fontSizeController.dispose();
    super.dispose();
  }
}

class DynamicDatePlaceholder {
  String format;

  DynamicPlaceholder? _placeholder;
  late final FocusNode _focusNode;
  final BuildContext Function() getContext;

  DynamicDatePlaceholder(this.format, {required this.getContext});

  DynamicPlaceholder get placeholder {
    if (_placeholder == null) {
      _focusNode = FocusNode();
      _placeholder = DynamicPlaceholder(
        id: 'date',
        text: 'Date',
        menuFocusNode: _focusNode,
        menuChildrenBuilder: (text) => [MenuItemButton(child: Text(format), onPressed: () => _activate())],
      );
    }

    return _placeholder!;
  }

  void _activate() async {
    final result = await showDialog<String>(context: getContext(), builder: singleTextDialog(format));

    if (result != null) {
      format = result;
    }
  }
}

WidgetBuilder singleTextDialog(String init) {
  final textController = TextEditingController(text: init);
  final form = GlobalKey<FormState>();

  return (context) {
    void onSubmit(String? value) {
      if (form.currentState!.validate()) {
        Navigator.of(context).pop(value);
      }
    }

    final local = MaterialLocalizations.of(context);
    final textField = TextFormField(
      key: const Key('text_dialog.text'),
      controller: textController,
      autofillHints: ['yyyy MM dd'],
      onSaved: onSubmit,
      onFieldSubmitted: onSubmit,
      keyboardType: TextInputType.text,
      decoration: InputDecoration.collapsed(hintText: 'hello world'),
      textInputAction: TextInputAction.done,
    );

    return AlertDialog(
      scrollable: true,
      content: Form(key: form, child: textField),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: Text(local.cancelButtonLabel)),
        FilledButton(onPressed: () => onSubmit(textController.text), child: Text(local.okButtonLabel)),
      ],
    );
  };
}
