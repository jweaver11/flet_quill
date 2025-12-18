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

    // Use devicePixelRatio to approximate OS display scale and derive
    // a zoom factor for the editor's minimum width.
    final mediaQuery = MediaQuery.of(context);
    final double devicePixelRatio = mediaQuery.devicePixelRatio;
    const double _baselineDpr = 1.0; // treat 100% scale as baseline
    final double zoomFactor = (devicePixelRatio / _baselineDpr).clamp(1.0, 2.5);

    double borderWidth = widget.control.attrDouble("border_width", 1.0) ?? 1.0;

    double paddingLeft = widget.control.attrDouble("padding_left", 0.0) ?? 0.0;
    double paddingTop = widget.control.attrDouble("padding_top", 0.0) ?? 0.0;
    double paddingRight =
        widget.control.attrDouble("padding_right", 0.0) ?? 0.0;
    double paddingBottom =
        widget.control.attrDouble("padding_bottom", 0.0) ?? 0.0;

    // If aspect_ratio is not provided, don't constrain with AspectRatio at all.
    // When provided (for example 8.5/11.0 for a paper-like page), we
    // effectively multiply the "width" part (8.5) by the zoom factor by
    // scaling the ratio itself.
    final double? rawAspectRatio = widget.control.attrDouble("aspect_ratio");
    final double? aspectRatio = (rawAspectRatio != null && rawAspectRatio > 0)
        ? rawAspectRatio * zoomFactor
        : null;

    // Whether we are showing a border around the editor
    final bool borderVisible =
        widget.control.attrBool("border_visible", true) == true;

    // Optional minimum width for the bordered container. When provided and
    // border is visible, it takes precedence over the aspect ratio.
    final double? rawMinWidth =
        borderVisible ? widget.control.attrDouble("min_width") : null;
    final double? minWidth = (rawMinWidth != null && rawMinWidth > 0)
        ? rawMinWidth * zoomFactor
        : null;

    // If we are gonna center the toolbar or not
    final bool centerToolbar =
        widget.control.attrBool("center_toolbar", false) ?? false;

    final bool showToolbarDivider =
        widget.control.attrBool("show_toolbar_divider", false) ?? false;

    // Build the editor container once, then wrap it with either a min-width
    // constraint or an aspect ratio, giving priority to min-width.
    Widget editorChild = _buildEditorContainer(
      baseTheme: baseTheme,
      borderWidth: borderWidth,
      paddingLeft: paddingLeft,
      paddingTop: paddingTop,
      paddingRight: paddingRight,
      paddingBottom: paddingBottom,
    );

    Widget sizedEditor;
    if (minWidth != null && minWidth > 0) {
      sizedEditor = ConstrainedBox(
        constraints: BoxConstraints(minWidth: minWidth),
        child: editorChild,
      );
    } else if (aspectRatio != null && aspectRatio > 0) {
      sizedEditor = AspectRatio(
        aspectRatio: aspectRatio,
        child: editorChild,
      );
    } else {
      sizedEditor = editorChild;
    }

    final myControl = Localizations(
      locale: const Locale('en'),
      delegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        FlutterQuillLocalizations.delegate,
      ],
      child: Column(
        crossAxisAlignment: centerToolbar
            ? CrossAxisAlignment.center
            : CrossAxisAlignment.start,
        children: [
          Theme(
            data: baseTheme.copyWith(
              colorScheme: baseTheme.colorScheme.copyWith(
                primary: baseTheme.colorScheme.onSurfaceVariant,
              ),
            ),
            child: QuillSimpleToolbar(
              controller: _controller,
              config: QuillSimpleToolbarConfig(
                showSearchButton: false,
                showFontFamily: false,
                showColorButton: false,
                showBackgroundColorButton: false,
                showLink: false,
              ),
            ),
          ),
          if (showToolbarDivider)
            Divider(
              height: 1,
              thickness: 1,
              color: baseTheme.colorScheme.outlineVariant,
            ),
          Expanded(
            child: Center(
              child: sizedEditor,
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

  Widget _buildEditorContainer({
    required ThemeData baseTheme,
    required double borderWidth,
    required double paddingLeft,
    required double paddingTop,
    required double paddingRight,
    required double paddingBottom,
  }) {
    return Container(
      decoration: BoxDecoration(
        border: widget.control.attrBool("border_visible", true) == true
            ? Border.all(
                color: baseTheme.colorScheme.outlineVariant,
                width: borderWidth,
              )
            : null,
      ),
      child: MouseRegion(
        cursor: SystemMouseCursors.text,
        child: QuillEditor.basic(
          controller: _controller,
          focusNode: _focusNode,
          config: QuillEditorConfig(
            placeholder: 'Enter text',
            expands: true,
            scrollable: true,
            autoFocus: true,
            padding: EdgeInsets.only(
              left: paddingLeft,
              top: paddingTop,
              right: paddingRight,
              bottom: paddingBottom,
            ),
          ),
        ),
      ),
    );
  }
}
