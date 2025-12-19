import 'package:flet/flet.dart';
import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/gestures.dart';
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
  final ScrollController _toolbarScrollController = ScrollController();
  final ScrollController _editorScrollController = ScrollController();

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
    _toolbarScrollController.dispose();
    _editorScrollController.dispose();
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
    final double zF =
        zoomFactor * 0.8; // Gives us similar results to google docs and MS Word

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
        ? rawAspectRatio * zF
        : null;

    // If true, draw horizontal page-break dividers at each "page height".
    // Only applies when aspect_ratio is provided.
    final bool showPageBreaks =
        widget.control.attrBool("show_page_breaks", false) ?? false;

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
      aspectRatio: aspectRatio,
      showPageBreaks: showPageBreaks,
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
    required double? aspectRatio,
    required bool showPageBreaks,
  }) {
    final editor = MouseRegion(
      cursor: SystemMouseCursors.text,
      child: QuillEditor.basic(
        controller: _controller,
        focusNode: _focusNode,
        config: QuillEditorConfig(
          placeholder: 'Enter text',
          expands: true,
          scrollable: true,
          autoFocus: true,
          // NOTE: Most flutter_quill versions expose scrollController on the config.
          // If your version doesn't, we can switch to the non-basic constructor.
          //scrollController: _editorScrollController,
          padding: EdgeInsets.only(
            left: paddingLeft,
            top: paddingTop,
            right: paddingRight,
            bottom: paddingBottom,
          ),
        ),
      ),
    );

    Widget content = editor;

    // Draw page-break dividers only when:
    // - user opted in, and
    // - aspect_ratio is provided (paging model is defined)
    if (showPageBreaks && aspectRatio != null && aspectRatio > 0) {
      content = LayoutBuilder(
        builder: (context, constraints) {
          // Prefer actual laid-out height if finite (AspectRatio usually makes it exact).
          final double pageHeight =
              (constraints.maxHeight.isFinite && constraints.maxHeight > 0)
                  ? constraints.maxHeight
                  : (constraints.maxWidth / aspectRatio);

          final Color lineColor =
              baseTheme.colorScheme.outlineVariant.withOpacity(0.8);

          return AnimatedBuilder(
            animation: _editorScrollController,
            child: editor,
            builder: (context, child) {
              final double scrollOffset = _editorScrollController.hasClients
                  ? _editorScrollController.offset
                  : 0.0;

              return CustomPaint(
                foregroundPainter: _PageBreakPainter(
                  scrollOffset: scrollOffset,
                  pageHeight: pageHeight,
                  color: lineColor,
                  thickness: 1.0,
                ),
                child: child,
              );
            },
          );
        },
      );
    }

    return Container(
      decoration: BoxDecoration(
        border: widget.control.attrBool("border_visible", true) == true
            ? Border.all(
                color: baseTheme.colorScheme.outlineVariant,
                width: borderWidth,
              )
            : null,
      ),
      child: content,
    );
  }
}

class _PageBreakPainter extends CustomPainter {
  final double scrollOffset;
  final double pageHeight;
  final Color color;
  final double thickness;

  const _PageBreakPainter({
    required this.scrollOffset,
    required this.pageHeight,
    required this.color,
    required this.thickness,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (pageHeight <= 0 || !pageHeight.isFinite) return;
    if (size.height <= 0 || size.width <= 0) return;

    final paint = Paint()
      ..color = color
      ..strokeWidth = thickness;

    // Draw page breaks at y = N * pageHeight in document coordinates.
    // Convert to viewport coordinates by subtracting scrollOffset.
    final int startPage = math.max(0, (scrollOffset / pageHeight).floor());
    int pageIndex = startPage + 1;

    while (true) {
      final double y = (pageIndex * pageHeight) - scrollOffset;
      if (y >= size.height) break;
      if (y > 0) {
        canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
      }
      pageIndex++;
      // safety guard (shouldn't trigger in practice)
      if (pageIndex - startPage > 1000) break;
    }
  }

  @override
  bool shouldRepaint(covariant _PageBreakPainter oldDelegate) {
    return oldDelegate.scrollOffset != scrollOffset ||
        oldDelegate.pageHeight != pageHeight ||
        oldDelegate.color != color ||
        oldDelegate.thickness != thickness;
  }
}
