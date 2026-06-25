import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../domain/models/text_layer.dart';
import 'curved_text_painter.dart';

class CanvasGestureDetector extends StatefulWidget {
  final TextLayer layer;
  final bool isSelected;
  final Size canvasSize;
  final VoidCallback onTap;
  final Function(double x, double y) onPositionChanged;
  final Function(double scale, double rotation, double curvature) onTransformChanged;
  final VoidCallback? onGestureStart;

  const CanvasGestureDetector({
    super.key,
    required this.layer,
    required this.isSelected,
    required this.canvasSize,
    required this.onTap,
    required this.onPositionChanged,
    required this.onTransformChanged,
    this.onGestureStart,
  });

  @override
  State<CanvasGestureDetector> createState() => _CanvasGestureDetectorState();
}

class _CanvasGestureDetectorState extends State<CanvasGestureDetector> {
  // Bounding box size before scaling/rotation
  final double baseWidth = 320.0;
  final double baseHeight = 180.0;
  final GlobalKey _containerKey = GlobalKey();

  // Variables for tracking gesture status
  late Offset _startNormalizedPosition;
  late double _startScale;
  late double _startRotation;
  late double _startCurvature;

  // Track initial angles and distances for rotate/scale gestures
  late double _initialTouchAngle;
  late double _initialTouchDistance;

  @override
  Widget build(BuildContext context) {
    // Convert relative coordinates (0.0 to 1.0) to absolute canvas coordinates
    final double left = widget.layer.x * widget.canvasSize.width;
    final double top = widget.layer.y * widget.canvasSize.height;

    // The text layer widget
    final Widget textContent = CustomPaint(
      size: Size(baseWidth, baseHeight),
      painter: CurvedTextPainter(
        text: widget.layer.text,
        fontFamily: widget.layer.fontFamily,
        fontSize: widget.layer.fontSize,
        color: Color(widget.layer.colorValue),
        strokeColor: widget.layer.strokeColorValue != null
            ? Color(widget.layer.strokeColorValue!)
            : null,
        strokeWidth: widget.layer.strokeWidth,
        letterSpacing: widget.layer.letterSpacing,
        curvature: widget.layer.curvature,
        opacity: widget.layer.opacity,
        shadowColor: widget.layer.shadowColorValue != null
            ? Color(widget.layer.shadowColorValue!)
            : null,
        shadowBlur: widget.layer.shadowBlur,
        shadowOffsetX: widget.layer.shadowOffsetX,
        shadowOffsetY: widget.layer.shadowOffsetY,
        glowColor: widget.layer.glowColorValue != null
            ? Color(widget.layer.glowColorValue!)
            : null,
        glowRadius: widget.layer.glowRadius,
        gradientColors: widget.layer.gradientColors != null
            ? widget.layer.gradientColors!.map((c) => Color(c)).toList()
            : null,
      ),
    );

    return Positioned(
      // Position the center of the widget at (left, top)
      left: left - (baseWidth / 2),
      top: top - (baseHeight / 2),
      child: Transform(
        alignment: Alignment.center,
        transform: Matrix4.identity()
          ..scale(widget.layer.scale)
          ..rotateZ(widget.layer.rotation),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            GestureDetector(
              onTap: widget.onTap,
              onScaleStart: (details) {
                if (!widget.isSelected) {
                  widget.onTap();
                }
                widget.onGestureStart?.call();
                _startNormalizedPosition = Offset(widget.layer.x, widget.layer.y);
                _startScale = widget.layer.scale;
                _startRotation = widget.layer.rotation;
              },
              onScaleUpdate: (details) {
                if (details.pointerCount > 1) {
                  // Two-finger pinch: scale and rotate
                  final double newScale = (_startScale * details.scale).clamp(0.2, 5.0);
                  final double newRotation = _startRotation + details.rotation;
                  widget.onTransformChanged(newScale, newRotation, widget.layer.curvature);
                } else {
                  // One-finger drag: move position
                  final double dx = details.focalPointDelta.dx / widget.canvasSize.width;
                  final double dy = details.focalPointDelta.dy / widget.canvasSize.height;
                  
                  final double newX = (_startNormalizedPosition.dx + dx).clamp(0.0, 1.0);
                  final double newY = (_startNormalizedPosition.dy + dy).clamp(0.0, 1.0);

                  widget.onPositionChanged(newX, newY);
                  _startNormalizedPosition = Offset(newX, newY);
                }
              },
              child: Container(
                key: _containerKey,
                width: baseWidth,
                height: baseHeight,
                decoration: const BoxDecoration(
                  color: Colors.transparent,
                ),
                child: CustomPaint(
                  painter: widget.isSelected
                      ? DashedBorderPainter(
                          color: const Color(0xFFE2D1C3),
                          strokeWidth: 1.5,
                          gap: 4.0,
                          dashLength: 6.0,
                        )
                      : null,
                  child: textContent,
                ),
              ),
            ),

          // 2. Interaction Handles (only when selected)
          if (widget.isSelected) ...[
            // Corner handles (top-left, top-right, bottom-left, bottom-right)
            _buildCornerHandle(
              top: -8.0,
              left: -8.0,
              cursor: SystemMouseCursors.resizeUpLeftDownRight,
            ),
            _buildCornerHandle(
              top: -8.0,
              right: -8.0,
              cursor: SystemMouseCursors.resizeUpRightDownLeft,
            ),
            _buildCornerHandle(
              bottom: -8.0,
              left: -8.0,
              cursor: SystemMouseCursors.resizeUpRightDownLeft,
            ),
            _buildCornerHandle(
              bottom: -8.0,
              right: -8.0,
              cursor: SystemMouseCursors.resizeUpLeftDownRight,
            ),

            // Curvature control handle (bottom-center)
            Positioned(
              left: (baseWidth / 2) - 12.0,
              bottom: -14.0,
              child: GestureDetector(
                onPanStart: (details) {
                  widget.onGestureStart?.call();
                  _startCurvature = widget.layer.curvature;
                  _startRotation = widget.layer.rotation;
                },
                onPanUpdate: (details) {
                  final double rotation = widget.layer.rotation;
                  final double scale = widget.layer.scale;
                  final double dx = details.delta.dx;
                  final double dy = details.delta.dy;

                  // Project screen delta onto the local coordinate axes:
                  final double deltaYLocal = -dx * math.sin(rotation) + dy * math.cos(rotation);
                  final double deltaXLocal = dx * math.cos(rotation) + dy * math.sin(rotation);

                  // Update curvature (radial direction)
                  final double curvatureSensitivity = 0.8;
                  final double deltaCurvature = (deltaYLocal / scale) * curvatureSensitivity;
                  final double newCurvature = (_startCurvature + deltaCurvature).clamp(-100.0, 100.0);
                  _startCurvature = newCurvature;

                  // Update rotation (tangential direction)
                  final double R = (baseHeight / 2) + 12.0;
                  final double deltaRotation = -deltaXLocal / (R * scale);
                  final double newRotation = _startRotation + deltaRotation;
                  _startRotation = newRotation;

                  double finalRotation = newRotation;
                  while (finalRotation > math.pi) {
                    finalRotation -= 2 * math.pi;
                  }
                  while (finalRotation < -math.pi) {
                    finalRotation += 2 * math.pi;
                  }

                  final double snapThreshold = 8 * math.pi / 180;
                  final double piOver2 = math.pi / 2;

                  if ((finalRotation - 0).abs() < snapThreshold) {
                    finalRotation = 0.0;
                  } else if ((finalRotation - piOver2).abs() < snapThreshold) {
                    finalRotation = piOver2;
                  } else if ((finalRotation - (-piOver2)).abs() < snapThreshold) {
                    finalRotation = -piOver2;
                  } else if ((finalRotation - math.pi).abs() < snapThreshold || (finalRotation + math.pi).abs() < snapThreshold) {
                    finalRotation = math.pi;
                  }

                  widget.onTransformChanged(scale, finalRotation, newCurvature);
                },
                child: MouseRegion(
                  cursor: SystemMouseCursors.grab,
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE2D1C3), // Warm Taupe
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2.5),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF3A3530).withOpacity(0.15),
                          blurRadius: 10,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.unfold_more,
                        size: 12,
                        color: Color(0xFF3A3530),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    ),
  );
}

  Widget _buildCornerHandle({
    double? top,
    double? bottom,
    double? left,
    double? right,
    required MouseCursor cursor,
  }) {
    final double? adjustedTop = top != null ? -20.0 : null;
    final double? adjustedBottom = bottom != null ? -20.0 : null;
    final double? adjustedLeft = left != null ? -20.0 : null;
    final double? adjustedRight = right != null ? -20.0 : null;

    return Positioned(
      top: adjustedTop,
      bottom: adjustedBottom,
      left: adjustedLeft,
      right: adjustedRight,
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onPanStart: (details) {
          widget.onGestureStart?.call();
          _startScale = widget.layer.scale;
          _startRotation = widget.layer.rotation;

          final RenderBox? renderBox = _containerKey.currentContext?.findRenderObject() as RenderBox?;
          if (renderBox == null) return;
          final Offset center = renderBox.localToGlobal(Offset(baseWidth / 2, baseHeight / 2));

          final double dx = details.globalPosition.dx - center.dx;
          final double dy = details.globalPosition.dy - center.dy;

          _initialTouchAngle = math.atan2(dy, dx);
          _initialTouchDistance = math.sqrt(dx * dx + dy * dy);
        },
        onPanUpdate: (details) {
          final RenderBox? renderBox = _containerKey.currentContext?.findRenderObject() as RenderBox?;
          if (renderBox == null) return;
          final Offset center = renderBox.localToGlobal(Offset(baseWidth / 2, baseHeight / 2));

          final double dx = details.globalPosition.dx - center.dx;
          final double dy = details.globalPosition.dy - center.dy;

          final double currentDistance = math.sqrt(dx * dx + dy * dy);
          final double currentAngle = math.atan2(dy, dx);

          final double scaleDelta = currentDistance / _initialTouchDistance;
          final double newScale = (_startScale * scaleDelta).clamp(0.2, 5.0);

          final double angleDelta = currentAngle - _initialTouchAngle;
          final double newRotation = _startRotation + angleDelta;

          widget.onTransformChanged(newScale, newRotation, widget.layer.curvature);
        },
        child: MouseRegion(
          cursor: cursor,
          child: Container(
            width: 40,
            height: 40,
            color: Colors.transparent,
            child: Center(
              child: Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  color: Colors.white, // Glowing white core
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFF3A3530), width: 2.0), // Deep Charcoal-Taupe stroke
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF3A3530).withOpacity(0.15),
                      blurRadius: 8,
                      spreadRadius: 1.5,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class DashedBorderPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double gap;
  final double dashLength;

  DashedBorderPainter({
    required this.color,
    this.strokeWidth = 1.2,
    this.gap = 4.0,
    this.dashLength = 6.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    // Draw top edge
    _drawDashedLine(canvas, paint, const Offset(0, 0), Offset(size.width, 0));
    // Draw right edge
    _drawDashedLine(canvas, paint, Offset(size.width, 0), Offset(size.width, size.height));
    // Draw bottom edge
    _drawDashedLine(canvas, paint, Offset(size.width, size.height), Offset(0, size.height));
    // Draw left edge
    _drawDashedLine(canvas, paint, Offset(0, size.height), const Offset(0, 0));
  }

  void _drawDashedLine(Canvas canvas, Paint paint, Offset start, Offset end) {
    final double dx = end.dx - start.dx;
    final double dy = end.dy - start.dy;
    final double distance = math.sqrt(dx * dx + dy * dy);
    final double angle = math.atan2(dy, dx);

    double drawn = 0.0;
    while (drawn < distance) {
      final double length = math.min(dashLength, distance - drawn);
      final Offset segmentStart = Offset(
        start.dx + drawn * math.cos(angle),
        start.dy + drawn * math.sin(angle),
      );
      final Offset segmentEnd = Offset(
        start.dx + (drawn + length) * math.cos(angle),
        start.dy + (drawn + length) * math.sin(angle),
      );
      canvas.drawLine(segmentStart, segmentEnd, paint);
      drawn += length + gap;
    }
  }

  @override
  bool shouldRepaint(covariant DashedBorderPainter oldDelegate) => false;
}
