import 'dart:ui' as ui;
import 'package:flutter/material.dart';

/// Available tools in the book drawing/paint mode
enum DrawingTool {
  pen,
  highlighter,
  eraser,
  panZoom,
}

/// Represents an individual drawing stroke made of multiple offset points
class DrawingStroke {
  final List<Offset> points;
  final Color color;
  final double strokeWidth;
  final DrawingTool tool;

  DrawingStroke({
    required List<Offset> points,
    required this.color,
    required this.strokeWidth,
    required this.tool,
  }) : points = List<Offset>.from(points);

  bool get isHighlighter => tool == DrawingTool.highlighter;
}

/// CustomPainter that renders strokes over the book page image
class BookDrawingPainter extends CustomPainter {
  final List<DrawingStroke> strokes;
  final DrawingStroke? activeStroke;

  BookDrawingPainter({
    required this.strokes,
    this.activeStroke,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (strokes.isEmpty && activeStroke == null) return;

    // Draw completed strokes
    for (final stroke in strokes) {
      _drawStroke(canvas, stroke);
    }

    // Draw stroke currently being drawn
    if (activeStroke != null) {
      _drawStroke(canvas, activeStroke!);
    }
  }

  void _drawStroke(Canvas canvas, DrawingStroke stroke) {
    if (stroke.points.isEmpty) return;

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    if (stroke.isHighlighter) {
      // Semi-transparent wide highlighter stroke
      paint.color = stroke.color.withValues(alpha: 0.38);
      paint.strokeWidth = stroke.strokeWidth * 3.5;
    } else {
      paint.color = stroke.color;
      paint.strokeWidth = stroke.strokeWidth;
    }

    // If only a single tap/point was registered, draw a small circle
    if (stroke.points.length == 1) {
      final dotPaint = Paint()
        ..style = PaintingStyle.fill
        ..color = paint.color;
      final radius = (stroke.isHighlighter ? stroke.strokeWidth * 1.5 : stroke.strokeWidth) / 2;
      canvas.drawCircle(stroke.points.first, radius, dotPaint);
      return;
    }

    final path = Path();
    path.moveTo(stroke.points.first.dx, stroke.points.first.dy);

    for (int i = 1; i < stroke.points.length; i++) {
      final p0 = stroke.points[i - 1];
      final p1 = stroke.points[i];
      // Quadratic bezier curve smoothing between midpoints for natural ink flow
      final mid = Offset((p0.dx + p1.dx) / 2, (p0.dy + p1.dy) / 2);
      path.quadraticBezierTo(p0.dx, p0.dy, mid.dx, mid.dy);
    }
    path.lineTo(stroke.points.last.dx, stroke.points.last.dy);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant BookDrawingPainter oldDelegate) => true;
}

/// Floating modern glassmorphic toolbar for paint controls in reader
class BookDrawingToolbar extends StatefulWidget {
  final DrawingTool activeTool;
  final Color activeColor;
  final double activeStrokeWidth;
  final bool canUndo;
  final bool hasStrokes;
  final ValueChanged<DrawingTool> onToolChanged;
  final ValueChanged<Color> onColorChanged;
  final ValueChanged<double> onStrokeWidthChanged;
  final VoidCallback onUndo;
  final VoidCallback onClear;
  final VoidCallback onClose;

  const BookDrawingToolbar({
    super.key,
    required this.activeTool,
    required this.activeColor,
    required this.activeStrokeWidth,
    required this.canUndo,
    required this.hasStrokes,
    required this.onToolChanged,
    required this.onColorChanged,
    required this.onStrokeWidthChanged,
    required this.onUndo,
    required this.onClear,
    required this.onClose,
  });

  @override
  State<BookDrawingToolbar> createState() => _BookDrawingToolbarState();
}

class _BookDrawingToolbarState extends State<BookDrawingToolbar> {
  bool _showColorPicker = false;
  bool _showWidthPicker = false;

  static const List<Color> _presetColors = [
    Color(0xFFFFD600), // Yellow (Classic highlighter)
    Color(0xFFE53935), // Red
    Color(0xFF1E88E5), // Blue
    Color(0xFF43A047), // Green
    Color(0xFF8E24AA), // Purple
    Color(0xFFFB8C00), // Orange
    Color(0xFF212121), // Black
    Color(0xFFFFFFFF), // White
  ];

  static const List<double> _presetWidths = [
    2.5, // Thin
    4.5, // Medium
    8.0, // Thick
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // ── Secondary popup for Colors ──────────────────────────────────────
        if (_showColorPicker)
          Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF1F1F1F).withValues(alpha: 0.95),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.4),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: _presetColors.map((color) {
                final isSelected = widget.activeColor == color;
                return GestureDetector(
                  onTap: () {
                    widget.onColorChanged(color);
                    setState(() => _showColorPicker = false);
                  },
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected ? Colors.amberAccent : Colors.white30,
                        width: isSelected ? 3 : 1.5,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: color.withValues(alpha: 0.6),
                                blurRadius: 6,
                              ),
                            ]
                          : null,
                    ),
                    child: isSelected
                        ? Icon(
                            Icons.check,
                            size: 16,
                            color: color.computeLuminance() > 0.5 ? Colors.black : Colors.white,
                          )
                        : null,
                  ),
                );
              }).toList(),
            ),
          ),

        // ── Secondary popup for Stroke Width ────────────────────────────────
        if (_showWidthPicker)
          Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF1F1F1F).withValues(alpha: 0.95),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.4),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: _presetWidths.map((w) {
                final isSelected = widget.activeStrokeWidth == w;
                return GestureDetector(
                  onTap: () {
                    widget.onStrokeWidthChanged(w);
                    setState(() => _showWidthPicker = false);
                  },
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.white24 : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Container(
                        width: w * 2.5 + 4,
                        height: w * 2.5 + 4,
                        decoration: BoxDecoration(
                          color: widget.activeColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

        // ── Main Glassmorphic Drawing Toolbar ───────────────────────────────
        ClipRRect(
          borderRadius: BorderRadius.circular(26),
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF141414).withValues(alpha: 0.88),
                borderRadius: BorderRadius.circular(26),
                border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.5),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Pen Tool
                  _toolButton(
                    icon: Icons.edit_rounded,
                    tooltip: 'قلم الكتابة',
                    isSelected: widget.activeTool == DrawingTool.pen,
                    onTap: () {
                      setState(() {
                        _showColorPicker = false;
                        _showWidthPicker = false;
                      });
                      widget.onToolChanged(DrawingTool.pen);
                    },
                  ),

                  // Highlighter Tool
                  _toolButton(
                    icon: Icons.border_color_rounded,
                    tooltip: 'قلم التظليل',
                    isSelected: widget.activeTool == DrawingTool.highlighter,
                    onTap: () {
                      setState(() {
                        _showColorPicker = false;
                        _showWidthPicker = false;
                      });
                      widget.onToolChanged(DrawingTool.highlighter);
                    },
                  ),

                  // Eraser Tool
                  _toolButton(
                    icon: Icons.auto_fix_high_rounded,
                    tooltip: 'ممحاة المسح',
                    isSelected: widget.activeTool == DrawingTool.eraser,
                    onTap: () {
                      setState(() {
                        _showColorPicker = false;
                        _showWidthPicker = false;
                      });
                      widget.onToolChanged(DrawingTool.eraser);
                    },
                  ),

                  // Pan & Zoom mode
                  _toolButton(
                    icon: Icons.pan_tool_rounded,
                    tooltip: 'تكبير وتحريك الصفحة',
                    isSelected: widget.activeTool == DrawingTool.panZoom,
                    onTap: () {
                      setState(() {
                        _showColorPicker = false;
                        _showWidthPicker = false;
                      });
                      widget.onToolChanged(DrawingTool.panZoom);
                    },
                  ),

                  const _Divider(),

                  // Color Picker Toggle
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _showColorPicker = !_showColorPicker;
                        _showWidthPicker = false;
                      });
                    },
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(
                        color: widget.activeColor,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                  ),

                  // Width Picker Toggle
                  IconButton(
                    icon: const Icon(Icons.line_weight_rounded, size: 20),
                    color: _showWidthPicker ? Colors.amberAccent : Colors.white70,
                    tooltip: 'سُمك الخط',
                    onPressed: () {
                      setState(() {
                        _showWidthPicker = !_showWidthPicker;
                        _showColorPicker = false;
                      });
                    },
                  ),

                  const _Divider(),

                  // Undo Action
                  IconButton(
                    icon: const Icon(Icons.undo_rounded, size: 20),
                    color: widget.canUndo ? Colors.white : Colors.white24,
                    tooltip: 'تراجع',
                    onPressed: widget.canUndo ? widget.onUndo : null,
                  ),

                  // Clear Page Action
                  IconButton(
                    icon: const Icon(Icons.delete_outline_rounded, size: 20),
                    color: widget.hasStrokes ? Colors.redAccent.shade100 : Colors.white24,
                    tooltip: 'مسح رسم الصفحة',
                    onPressed: widget.hasStrokes ? widget.onClear : null,
                  ),

                  const _Divider(),

                  // Close / Exit Paint Mode
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20),
                    color: Colors.white,
                    tooltip: 'إغلاق وضع الرسم',
                    onPressed: widget.onClose,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _toolButton({
    required IconData icon,
    required String tooltip,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(7),
          margin: const EdgeInsets.symmetric(horizontal: 2),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white.withValues(alpha: 0.22) : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(
            icon,
            size: 20,
            color: isSelected ? Colors.amberAccent : Colors.white70,
          ),
        ),
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 22,
      margin: const EdgeInsets.symmetric(horizontal: 6),
      color: Colors.white24,
    );
  }
}
