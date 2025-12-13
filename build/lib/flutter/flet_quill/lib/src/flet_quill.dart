import 'package:flet/flet.dart';
import 'dart:io';
import 'dart:async';
import 'dart:convert';
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

class _FletQuillControlState extends State<FletQuillControl>
    with WidgetsBindingObserver {
  late final QuillController _controller;
  final FocusNode _focusNode = FocusNode();
  Timer? _saveTimer;
  bool _pendingSave = false;

  void _scheduleSave() {
    _pendingSave = true;
    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(seconds: 2), _flushPendingSave);
  }

  void _flushPendingSave() {
    _saveTimer?.cancel();
    if (!_pendingSave) return;
    _pendingSave = false;
    _saveToFile();
  }

  void _saveToFile() {
    final filePath = widget.control.attrString("file_path", "") ?? "";
    if (filePath.isEmpty) return;

    try {
      final deltaJson = _controller.document.toDelta().toJson();
      final jsonString = jsonEncode(deltaJson);
      File(filePath).writeAsStringSync(jsonString);
    } catch (_) {
      // handle/log error if you want
    }
  }

  void _handleControllerChanged() {
    // When toolbar changes the document, make sure editor regains focus.
    if (!_focusNode.hasFocus) {
      _focusNode.requestFocus();
    }
    _scheduleSave();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    final filePath = widget.control.attrString("file_path", "") ?? "";
    Document doc;

    // Load our existing document
    if (filePath.isNotEmpty) {
      try {
        final file = File(filePath);
        if (file.existsSync()) {
          final jsonString = file.readAsStringSync();
          final deltaJson = jsonDecode(jsonString);
          doc = Document.fromJson(deltaJson);
        } else {
          // File doesn’t exist yet – start with empty document
          doc = Document();
        }
      } catch (_) {
        // Bad/empty file or JSON – fall back to empty document
        doc = Document();
      }
    } else {
      // No file_path provided – start empty
      doc = Document();
    }

    _controller = QuillController(
      document: doc,
      selection: TextSelection.collapsed(offset: doc.length),
    );

    _controller.addListener(_handleControllerChanged);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _flushPendingSave(); // ensure last changes are written
    _controller.removeListener(_handleControllerChanged);
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      _flushPendingSave();
    }
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
