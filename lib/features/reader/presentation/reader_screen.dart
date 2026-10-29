import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/config/env_config.dart';
import '../../../app/theme/theme_provider.dart';
import '../../../core/storage/secure_storage.dart';
import '../data/reader_models.dart';
import '../providers/reader_provider.dart';
import 'widgets/book_drawing_layer.dart';

class ReaderScreen extends ConsumerStatefulWidget {
  final int bookId;
  final bool isSample;

  const ReaderScreen({
    super.key,
    required this.bookId,
    this.isSample = false,
  });

  @override
  ConsumerState<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends ConsumerState<ReaderScreen> {
  final TransformationController _transformController = TransformationController();
  bool _showControls = true;
  String? _authToken;

  // ── Transient Live Painting / Drawing State (In-Memory per page) ──────────
  bool _isDrawingMode = false;
  DrawingTool _activeTool = DrawingTool.pen;
  Color _activeColor = const Color(0xFFFFD600); // Vibrant yellow default
  double _activeStrokeWidth = 4.5;
  DrawingStroke? _currentActiveStroke;
  final Map<int, List<DrawingStroke>> _pageDrawings = {};

  void _onPanStart(DragStartDetails details, int currentPage) {
    if (!_isDrawingMode || _activeTool == DrawingTool.panZoom) return;

    if (_activeTool == DrawingTool.eraser) {
      _eraseAt(details.localPosition, currentPage);
      return;
    }

    setState(() {
      _currentActiveStroke = DrawingStroke(
        points: [details.localPosition],
        color: _activeColor,
        strokeWidth: _activeStrokeWidth,
        tool: _activeTool,
      );
    });
  }

  void _onPanUpdate(DragUpdateDetails details, int currentPage) {
    if (!_isDrawingMode || _activeTool == DrawingTool.panZoom) return;

    if (_activeTool == DrawingTool.eraser) {
      _eraseAt(details.localPosition, currentPage);
      return;
    }

    if (_currentActiveStroke != null) {
      final last = _currentActiveStroke!.points.last;
      if ((details.localPosition - last).distanceSquared > 1.0) {
        setState(() {
          _currentActiveStroke!.points.add(details.localPosition);
        });
      }
    }
  }

  void _onPanEnd(DragEndDetails details, int currentPage) {
    if (!_isDrawingMode || _activeTool == DrawingTool.panZoom) return;

    if (_currentActiveStroke != null) {
      setState(() {
        final strokes = _pageDrawings.putIfAbsent(currentPage, () => []);
        strokes.add(_currentActiveStroke!);
        _currentActiveStroke = null;
      });
    }
  }

  void _onTapUp(TapUpDetails details, int currentPage) {
    if (!_isDrawingMode || _activeTool == DrawingTool.panZoom) return;

    if (_activeTool == DrawingTool.eraser) {
      _eraseAt(details.localPosition, currentPage);
      return;
    }

    setState(() {
      final strokes = _pageDrawings.putIfAbsent(currentPage, () => []);
      strokes.add(DrawingStroke(
        points: [details.localPosition],
        color: _activeColor,
        strokeWidth: _activeStrokeWidth,
        tool: _activeTool,
      ));
    });
  }

  void _eraseAt(Offset touch, int currentPage) {
    final strokes = _pageDrawings[currentPage];
    if (strokes == null || strokes.isEmpty) return;

    const radius = 22.0;
    const radiusSq = radius * radius;

    setState(() {
      strokes.removeWhere((stroke) {
        for (final p in stroke.points) {
          if ((p - touch).distanceSquared <= radiusSq) {
            return true;
          }
        }
        return false;
      });
    });
  }

  void _undoCurrentPage(int currentPage) {
    final strokes = _pageDrawings[currentPage];
    if (strokes != null && strokes.isNotEmpty) {
      setState(() {
        strokes.removeLast();
      });
    }
  }

  void _clearCurrentPage(int currentPage) {
    if (_pageDrawings[currentPage]?.isNotEmpty ?? false) {
      setState(() {
        _pageDrawings[currentPage]?.clear();
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _loadAuthToken();
  }

  Future<void> _loadAuthToken() async {
    final storage = ref.read(secureStorageProvider);
    final token = await storage.getToken();
    if (mounted) {
      setState(() => _authToken = token);
    }
  }

  @override
  void dispose() {
    _transformController.dispose();
    super.dispose();
  }

  void _resetZoom() {
    _transformController.value = Matrix4.identity();
  }

  void _toggleControls() {
    setState(() => _showControls = !_showControls);
  }

  @override
  Widget build(BuildContext context) {
    final readerKey = (bookId: widget.bookId, isSample: widget.isSample);
    final readerState = ref.watch(readerProvider(readerKey));
    final notifier = ref.read(readerProvider(readerKey).notifier);

    if (readerState.isLoading) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(color: AppColors.primary),
              const SizedBox(height: 16),
              Text(
                widget.isSample ? 'جاري تحضير العينة المجانية...' : 'جاري فتح جلسة القراءة الآمنة...',
                style: const TextStyle(color: Colors.white70, fontSize: 14),
              ),
            ],
          ),
        ),
      );
    }

    if (readerState.errorMessage != null) {
      return Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.pop(),
          ),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.lock_clock_rounded, size: 64, color: Colors.orangeAccent),
                const SizedBox(height: 16),
                Text(
                  readerState.errorMessage!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: () => notifier.loadSession(),
                  icon: const Icon(Icons.refresh),
                  label: const Text('إعادة المحاولة'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final session = readerState.session;
    if (session == null) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: Text('لا توجد بيانات', style: TextStyle(color: Colors.white))),
      );
    }

    final pageUrl = session.getPageImageUrl(EnvConfig.apiBaseUrl, readerState.currentPage);
    final headers = <String, String>{};
    if (session.readToken.isNotEmpty) {
      headers['X-Read-Token'] = session.readToken;
    }
    if (_authToken != null) {
      headers['Authorization'] = 'Bearer $_authToken';
    }

    return Scaffold(
      backgroundColor: const Color(0xFF1E1E1E),
      body: Stack(
        children: [
          // ── Main Page View with Zoom & Pan & Paint ───────────────────────
          GestureDetector(
            onTap: _isDrawingMode ? null : _toggleControls,
            child: Center(
              child: InteractiveViewer(
                transformationController: _transformController,
                minScale: 1.0,
                maxScale: 4.0,
                panEnabled: !_isDrawingMode || _activeTool == DrawingTool.panZoom,
                scaleEnabled: !_isDrawingMode || _activeTool == DrawingTool.panZoom,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      color: Colors.white,
                      child: Image.network(
                        pageUrl,
                        headers: headers.isNotEmpty ? headers : null,
                        fit: BoxFit.contain,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          final total = loadingProgress.expectedTotalBytes;
                          final loaded = loadingProgress.cumulativeBytesLoaded;
                          final val = (total != null && total > 0) ? loaded / total : null;
                          return SizedBox(
                            height: 400,
                            child: Center(
                              child: CircularProgressIndicator(
                                value: val,
                                color: AppColors.primary,
                              ),
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          return SizedBox(
                            height: 300,
                            child: Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.broken_image_rounded, size: 48, color: Colors.grey),
                                  const SizedBox(height: 8),
                                  const Text(
                                    'تعذر تحميل الصفحة',
                                    style: TextStyle(color: Colors.grey),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      _resetZoom();
                                      setState(() {});
                                    },
                                    child: const Text('إعادة المحاولة'),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),

                    // ── Live Drawing Layer (In-memory strokes on book image) ──
                    Positioned.fill(
                      child: IgnorePointer(
                        child: CustomPaint(
                          painter: BookDrawingPainter(
                            strokes: _pageDrawings[readerState.currentPage] ?? const [],
                            activeStroke: _currentActiveStroke,
                          ),
                        ),
                      ),
                    ),

                    // ── Paint Touch Capture Overlay ──
                    if (_isDrawingMode && _activeTool != DrawingTool.panZoom)
                      Positioned.fill(
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onPanStart: (d) => _onPanStart(d, readerState.currentPage),
                          onPanUpdate: (d) => _onPanUpdate(d, readerState.currentPage),
                          onPanEnd: (d) => _onPanEnd(d, readerState.currentPage),
                          onTapUp: (d) => _onTapUp(d, readerState.currentPage),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),

          // ── Page Flip Hit Areas (active only when not in drawing mode) ───
          if (!_isDrawingMode) ...[
            Positioned(
              left: 0,
              top: 100,
              bottom: 100,
              width: 50,
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: () {
                  _resetZoom();
                  notifier.nextPage();
                },
              ),
            ),
            Positioned(
              right: 0,
              top: 100,
              bottom: 100,
              width: 50,
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: () {
                  _resetZoom();
                  notifier.prevPage();
                },
              ),
            ),
          ],

          // ── Top Navigation Bar ───────────────────────────────────────────
          AnimatedPositioned(
            duration: const Duration(milliseconds: 250),
            top: _showControls ? 0 : -100,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 8,
                bottom: 12,
                left: 12,
                right: 12,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.black.withValues(alpha: 0.85),
                    Colors.transparent,
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
                    onPressed: () => context.pop(),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          session.bookTitle,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (widget.isSample)
                          Container(
                            margin: const EdgeInsets.only(top: 2),
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                            decoration: BoxDecoration(
                              color: Colors.amber.shade700,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'معاينة عينة مجانية',
                              style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                          )
                        else
                          Text(
                            'متبقي ${session.daysRemaining} يوم في صلاحية الوصول',
                            style: const TextStyle(color: Colors.white70, fontSize: 11),
                          ),
                      ],
                    ),
                  ),

                  // ── Paint / Drawing Mode Toggle ──
                  IconButton(
                    icon: Container(
                      padding: const EdgeInsets.all(5),
                      decoration: _isDrawingMode
                          ? BoxDecoration(
                              color: Colors.amberAccent.withValues(alpha: 0.25),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.amberAccent, width: 1.5),
                            )
                          : null,
                      child: Icon(
                        _isDrawingMode ? Icons.brush_rounded : Icons.edit_rounded,
                        color: _isDrawingMode ? Colors.amberAccent : Colors.white,
                        size: 20,
                      ),
                    ),
                    tooltip: _isDrawingMode ? 'إغلاق وضع الرسم' : 'الكتابة والرسم على الصفحة',
                    onPressed: () {
                      setState(() {
                        _isDrawingMode = !_isDrawingMode;
                        if (_isDrawingMode) {
                          _showControls = true;
                        }
                      });
                    },
                  ),

                  if (session.units.isNotEmpty)
                    IconButton(
                      icon: const Icon(Icons.menu_book_rounded, color: Colors.white),
                      tooltip: 'فهرس الوحدات',
                      onPressed: () => _showUnitsSheet(context, session, notifier),
                    ),
                  if (!widget.isSample)
                    IconButton(
                      icon: Badge(
                        isLabelVisible: readerState.annotations.isNotEmpty,
                        label: Text('${readerState.annotations.length}'),
                        child: const Icon(Icons.sticky_note_2_outlined, color: Colors.white),
                      ),
                      tooltip: 'ملاحظات الصفحة',
                      onPressed: () => _showAnnotationsSheet(context, readerState, notifier),
                    ),
                ],
              ),
            ),
          ),

          // ── Floating Drawing Toolbar ─────────────────────────────────────
          if (_isDrawingMode)
            Positioned(
              top: MediaQuery.of(context).padding.top + 62,
              left: 12,
              right: 12,
              child: Center(
                child: BookDrawingToolbar(
                  activeTool: _activeTool,
                  activeColor: _activeColor,
                  activeStrokeWidth: _activeStrokeWidth,
                  canUndo: _pageDrawings[readerState.currentPage]?.isNotEmpty ?? false,
                  hasStrokes: _pageDrawings[readerState.currentPage]?.isNotEmpty ?? false,
                  onToolChanged: (tool) => setState(() => _activeTool = tool),
                  onColorChanged: (color) => setState(() => _activeColor = color),
                  onStrokeWidthChanged: (w) => setState(() => _activeStrokeWidth = w),
                  onUndo: () => _undoCurrentPage(readerState.currentPage),
                  onClear: () => _clearCurrentPage(readerState.currentPage),
                  onClose: () => setState(() => _isDrawingMode = false),
                ),
              ),
            ),

          // ── Bottom Navigation & Controls ─────────────────────────────────
          AnimatedPositioned(
            duration: const Duration(milliseconds: 250),
            bottom: _showControls ? 0 : -140,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).padding.bottom + 12,
                top: 12,
                left: 16,
                right: 16,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.9),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Page jump slider & counter
                  Row(
                    children: [
                      Text(
                        '${readerState.currentPage}',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                      Expanded(
                        child: SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            activeTrackColor: AppColors.primary,
                            inactiveTrackColor: Colors.white24,
                            thumbColor: AppColors.primary,
                          ),
                          child: Slider(
                            value: (readerState.totalPages > 0
                                    ? readerState.currentPage.toDouble()
                                    : 1.0)
                                .clamp(1.0, readerState.totalPages > 0 ? readerState.totalPages.toDouble() : 1.0),
                            min: 1,
                            max: readerState.totalPages > 0 ? readerState.totalPages.toDouble() : 1.0,
                            divisions: readerState.totalPages > 1 ? readerState.totalPages - 1 : 1,
                            onChanged: readerState.totalPages > 1
                                ? (val) {
                                    _resetZoom();
                                    notifier.jumpToPage(val.round());
                                  }
                                : null,
                          ),
                        ),
                      ),
                      Text(
                        '${readerState.totalPages}',
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  // Actions row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton.filledTonal(
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.white.withValues(alpha: 0.15),
                          foregroundColor: Colors.white,
                        ),
                        icon: const Icon(Icons.arrow_forward_ios_rounded, size: 18),
                        onPressed: readerState.currentPage > 1
                            ? () {
                                _resetZoom();
                                notifier.prevPage();
                              }
                            : null,
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'صفحة ${readerState.currentPage} من ${readerState.totalPages}',
                          style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                      ),
                      if (!widget.isSample)
                        IconButton.filledTonal(
                          style: IconButton.styleFrom(
                            backgroundColor: AppColors.primary.withValues(alpha: 0.25),
                            foregroundColor: AppColors.primary,
                          ),
                          icon: const Icon(Icons.edit_note_rounded, size: 20),
                          tooltip: 'إضافة ملاحظة',
                          onPressed: () => _showAddNoteDialog(context, notifier),
                        ),
                      IconButton.filledTonal(
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.white.withValues(alpha: 0.15),
                          foregroundColor: Colors.white,
                        ),
                        icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
                        onPressed: readerState.currentPage < readerState.totalPages
                            ? () {
                                _resetZoom();
                                notifier.nextPage();
                              }
                            : null,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showUnitsSheet(
    BuildContext context,
    ReaderSession session,
    ReaderNotifier notifier,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF242424),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'فهرس وحدات وفصول الكتاب',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Divider(color: Colors.white12, height: 1),
              Expanded(
                child: ListView.builder(
                  itemCount: session.units.length,
                  itemBuilder: (ctx, i) {
                    final unit = session.units[i];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: AppColors.primary.withValues(alpha: 0.2),
                        child: Text(
                          '${unit.order}',
                          style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
                        ),
                      ),
                      title: Text(
                        unit.title,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                      ),
                      subtitle: unit.description != null
                          ? Text(
                              unit.description!,
                              style: const TextStyle(color: Colors.white60, fontSize: 12),
                            )
                          : null,
                      trailing: const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white30, size: 14),
                      onTap: () {
                        Navigator.pop(ctx);
                        _resetZoom();
                        // If unit has order, we jump to unit approximate position or order
                        if (unit.order > 0) {
                          notifier.jumpToPage(unit.order);
                        }
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showAnnotationsSheet(
    BuildContext context,
    ReaderState readerState,
    ReaderNotifier notifier,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF242424),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'ملاحظات الصفحة (${readerState.currentPage})',
                      style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    if (readerState.annotations.isNotEmpty)
                      TextButton.icon(
                        icon: const Icon(Icons.delete_sweep_rounded, color: Colors.redAccent, size: 18),
                        label: const Text('مسح الكل', style: TextStyle(color: Colors.redAccent, fontSize: 13)),
                        onPressed: () async {
                          await notifier.clearCurrentPageAnnotations();
                          if (ctx.mounted) Navigator.pop(ctx);
                        },
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                if (readerState.annotations.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 32.0),
                    child: Column(
                      children: [
                        const Icon(Icons.note_alt_outlined, color: Colors.white30, size: 48),
                        const SizedBox(height: 8),
                        const Text(
                          'لا توجد ملاحظات على هذه الصفحة حالياً',
                          style: TextStyle(color: Colors.white60),
                        ),
                        const SizedBox(height: 16),
                        FilledButton.icon(
                          onPressed: () {
                            Navigator.pop(ctx);
                            _showAddNoteDialog(context, notifier);
                          },
                          icon: const Icon(Icons.add),
                          label: const Text('إضافة ملاحظة جديدة'),
                        ),
                      ],
                    ),
                  )
                else
                  Expanded(
                    child: ListView.builder(
                      itemCount: readerState.annotations.length,
                      itemBuilder: (c, idx) {
                        final ann = readerState.annotations[idx];
                        String noteText = ann.dataJson;
                        try {
                          final parsed = jsonDecode(ann.dataJson);
                          if (parsed is Map && parsed.containsKey('text')) {
                            noteText = parsed['text'].toString();
                          }
                        } catch (_) {}

                        return Card(
                          color: const Color(0xFF333333),
                          margin: const EdgeInsets.only(bottom: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          child: ListTile(
                            leading: const Icon(Icons.sticky_note_2_rounded, color: Colors.amberAccent),
                            title: Text(noteText, style: const TextStyle(color: Colors.white)),
                            subtitle: Text(
                              '${ann.createdAt.hour}:${ann.createdAt.minute.toString().padLeft(2, '0')}',
                              style: const TextStyle(color: Colors.white38, fontSize: 11),
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 18),
                              onPressed: () async {
                                await notifier.deleteAnnotation(ann.id);
                              },
                            ),
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showAddNoteDialog(BuildContext context, ReaderNotifier notifier) {
    final textController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF2C2C2C),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('إضافة ملاحظة على الصفحة', style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: textController,
          autofocus: true,
          maxLines: 4,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'اكتب ملاحظتك هنا...',
            hintStyle: const TextStyle(color: Colors.white38),
            filled: true,
            fillColor: const Color(0xFF1E1E1E),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء', style: TextStyle(color: Colors.white70)),
          ),
          FilledButton(
            onPressed: () async {
              if (textController.text.trim().isNotEmpty) {
                await notifier.addNote(textController.text);
              }
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
  }
}
