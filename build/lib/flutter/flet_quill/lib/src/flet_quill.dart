import 'package:flet/flet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_localizations/flutter_localizations.dart'; // <-- use this

class FletQuillControl extends StatefulWidget {
  final Control? parent;
  final Control control;

  const FletQuillControl({
    super.key,
    required this.parent,
    required this.control,
  });

  @override
  State<FletQuillControl> createState() => _FletQuillControlState();
}

class _FletQuillControlState extends State<FletQuillControl> {
  late final QuillController _controller;
  final FocusNode _focusNode = FocusNode();

  void _handleControllerChanged() {
    // When toolbar changes the document, make sure editor regains focus.
    if (!_focusNode.hasFocus) {
      _focusNode.requestFocus();
    }
  }

  @override
  void initState() {
    super.initState();

    final body_text = widget.control.attrString("body_text", "") ?? "";
    final doc = Document()..insert(0, body_text);

    _controller = QuillController(
      document: doc,
      selection: TextSelection.collapsed(offset: doc.length),
    );

    _controller.addListener(_handleControllerChanged);
  }

  @override
  void dispose() {
    _controller.removeListener(_handleControllerChanged);
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final baseTheme = Theme.of(context);

    final myControl = Localizations(
      locale: const Locale('en'),
      delegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        FlutterQuillLocalizations.delegate,
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- toolbar ---
          Theme(
            data: baseTheme.copyWith(
              colorScheme: baseTheme.colorScheme.copyWith(
                // selected button background color
                primary: baseTheme.colorScheme.onSurfaceVariant,
              ),
            ),
            child: QuillSimpleToolbar(
              controller: _controller,
              // ⬇ NOT const – uses runtime theme values
              config: QuillSimpleToolbarConfig(
                // Broken buttons
                //afterButtonPressed: _focusNode.requestFocus,
                showSearchButton: false,
                showColorButton: false,
                showBackgroundColorButton: false,
                showLink: false,
              ),
            ),
          ),
          //const Divider(),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                //color: Colors.white,
                border: Border.all(color: baseTheme.colorScheme.outlineVariant),
              ),
              padding: const EdgeInsets.only(
                left: 64.0,
                top: 80,
                right: 64.0,
                bottom: 80.0,
              ),
              child: QuillEditor.basic(
                controller: _controller,
                focusNode: _focusNode,
                config: const QuillEditorConfig(
                  placeholder: 'Enter text',
                  expands: true,
                  scrollable: true,
                ),
              ),
            ),
          ),
        ],
      ),
    );

    return constrainedControl(
      context,
      myControl,
      widget.parent,
      widget.control,
    );
  }
}
