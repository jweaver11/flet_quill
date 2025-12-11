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

  @override
  void initState() {
    super.initState();

    final body_text = widget.control.attrString("body_text", "") ?? "";
    final doc = Document()..insert(0, body_text);

    _controller = QuillController(
      document: doc,
      selection: TextSelection.collapsed(offset: doc.length),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final myControl = Column(
      children: [
        // --- toolbar ---
        Container(
          height: 100,
          decoration: BoxDecoration(
            border: Border.all(
                color: const Color.fromARGB(255, 214, 241, 42), width: 2),
          ),
          child: QuillSimpleToolbar(
            controller: _controller,
            config: const QuillSimpleToolbarConfig(
              showSearchButton: false,
            ),
          ),
        ),

        const Divider(),
        Container(
          //height: 100,
          decoration: BoxDecoration(
            border: Border.all(color: const Color.fromARGB(255, 238, 7, 7)),
          ),
          child: QuillEditor.basic(
            controller: _controller,
            config: const QuillEditorConfig(
              placeholder: 'Enter text',
              expands: true,
              scrollable: true,
            ),
          ),
        ),
      ],
    );

    // Provide all localization delegates flutter_quill expects
    return Localizations(
      locale: const Locale('en'),
      delegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        FlutterQuillLocalizations
            .delegate, // exported from flutter_quill.dart import
      ],
      child: constrainedControl(
        context,
        myControl,
        widget.parent,
        widget.control,
      ),
    );
  }
}
