import 'package:flet/flet.dart';
import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_localizations/flutter_localizations.dart'; // <-- use this

class FletQuillControl extends StatefulWidget {
  final Control? parent;
  final Control control;
  final FletControlBackend backend;

  const FletQuillControl({
    super.key,
    required this.parent,
    required this.control,
    required this.backend,
  });

  @override
  State<FletQuillControl> createState() => _FletQuillControlState();
}

class _FletQuillControlState extends State<FletQuillControl>
    with WidgetsBindingObserver {
  late final QuillController _controller;
  final FocusNode _focusNode = FocusNode();
  final ScrollController _toolbarScrollController = ScrollController();
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
    _saveDocument();
  }

  void _saveDocument() {
    final deltaJson = _controller.document.toDelta().toJson();
    final jsonString = jsonEncode(deltaJson);

    // Prefer Python callback (event) if enabled
    final bool saveToEvent =
        widget.control.attrBool("save_to_event", false) ?? false;
    if (saveToEvent) {
      try {
        widget.backend.triggerControlEvent(
          widget.control.id,
          "save",
          jsonString,
        );
      } catch (_) {
        // ignore
      }
      return;
    }

    // Fallback to file_path
    final filePath = widget.control.attrString("file_path", "") ?? "";
    if (filePath.isEmpty) return;

    try {
      File(filePath).writeAsStringSync(jsonString);
    } catch (_) {
      // ignore
    }
  }

  void _handleControllerChanged() {
    if (!_focusNode.hasFocus) {
      _focusNode.requestFocus();
    }
    _scheduleSave();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    final String initialTextData =
        widget.control.attrString("text_data", "") ?? "";
    final filePath = widget.control.attrString("file_path", "") ?? "";

    Document doc;

    // 1) Prefer loading from passed-in data
    if (initialTextData.isNotEmpty) {
      try {
        final deltaJson = jsonDecode(initialTextData);
        doc = Document.fromJson(deltaJson);
      } catch (_) {
        doc = Document();
      }
    }
    // 2) Fallback to file_path
    else if (filePath.isNotEmpty) {
      try {
        final file = File(filePath);
        if (file.existsSync()) {
          final jsonString = file.readAsStringSync();
          final deltaJson = jsonDecode(jsonString);
          doc = Document.fromJson(deltaJson);
        } else {
          doc = Document();
        }
      } catch (_) {
        doc = Document();
      }
    } else {
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
    _flushPendingSave();
    _controller.removeListener(_handleControllerChanged);
    _controller.dispose();
    _focusNode.dispose();
    _toolbarScrollController.dispose();
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

    // NEW: allow disabling zoom-factor scaling so aspect_ratio is exact.
    final bool useZoomFactor =
        widget.control.attrBool("use_zoom_factor", true) ?? true;

    final double zF = useZoomFactor
        ? zoomFactor * 0.8 // current behavior (docs/word-like)
        : 1.0; // exact aspect_ratio, no scaling

    double borderWidth = widget.control.attrDouble("border_width", 1.0) ?? 1.0;

    double paddingLeft = widget.control.attrDouble("padding_left", 0.0) ?? 0.0;
    double paddingTop = widget.control.attrDouble("padding_top", 0.0) ?? 0.0;
    double paddingRight =
        widget.control.attrDouble("padding_right", 0.0) ?? 0.0;
    double paddingBottom =
        widget.control.attrDouble("padding_bottom", 0.0) ?? 0.0;

    // If aspect_ratio is not provided, don't constrain with AspectRatio at all.
    // When provided, apply zoom scaling only when use_zoom_factor == true.
    final double? rawAspectRatio = widget.control.attrDouble("aspect_ratio");
    final double? aspectRatio = (rawAspectRatio != null && rawAspectRatio > 0)
        ? rawAspectRatio * zF
        : null;

    // If we are gonna center the toolbar or not
    final bool centerToolbar =
        widget.control.attrBool("center_toolbar", false) ?? false;

    // If true, the toolbar will scroll horizontally instead of wrapping.
    final bool scrollToolbar =
        widget.control.attrBool("scroll_toolbar", false) ?? false;

    final bool showToolbarDivider =
        widget.control.attrBool("show_toolbar_divider", false) ?? false;

    // Optional custom font sizes for the toolbar (JSON list or map).
    Map<String, String>? fontSizeItems;
    final String? fontSizesJson = widget.control.attrString("font_sizes");
    if (fontSizesJson != null && fontSizesJson.isNotEmpty) {
      try {
        final decoded = jsonDecode(fontSizesJson);
        if (decoded is List) {
          final items = <String, String>{};
          for (final v in decoded) {
            final s = v.toString();
            if (s.isEmpty) continue;
            items[s] = s;
          }
          if (items.isNotEmpty) {
            fontSizeItems = items;
          }
        } else if (decoded is Map) {
          final items = <String, String>{};
          decoded.forEach((k, v) {
            if (k == null || v == null) return;
            final ks = k.toString();
            final vs = v.toString();
            if (ks.isEmpty || vs.isEmpty) return;
            items[ks] = vs;
          });
          if (items.isNotEmpty) {
            fontSizeItems = items;
          }
        }
      } catch (_) {
        // ignore invalid JSON and fall back to defaults
      }
    }

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
    if (aspectRatio != null && aspectRatio > 0) {
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
          Builder(
            builder: (context) {
              Widget toolbar = Theme(
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
                    buttonOptions: fontSizeItems != null
                        ? QuillSimpleToolbarButtonOptions(
                            fontSize: QuillToolbarFontSizeButtonOptions(
                              items: fontSizeItems,
                            ),
                          )
                        : const QuillSimpleToolbarButtonOptions(),
                  ),
                ),
              );

              if (scrollToolbar) {
                final scrollBehavior = ScrollConfiguration.of(context).copyWith(
                  dragDevices: {
                    PointerDeviceKind.touch,
                    PointerDeviceKind.mouse,
                    PointerDeviceKind.trackpad,
                    PointerDeviceKind.stylus,
                    PointerDeviceKind.unknown,
                  },
                );

                toolbar = ScrollConfiguration(
                  behavior: scrollBehavior,
                  child: Scrollbar(
                    controller: _toolbarScrollController,
                    thumbVisibility: true,
                    child: SingleChildScrollView(
                      controller: _toolbarScrollController,
                      scrollDirection: Axis.horizontal,
                      primary: false,
                      child: toolbar,
                    ),
                  ),
                );
              }

              return toolbar;
            },
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
