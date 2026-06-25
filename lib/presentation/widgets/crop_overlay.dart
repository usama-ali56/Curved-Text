import 'package:flutter/material.dart';
import '../../domain/models/image_settings.dart';

class CropOverlay extends StatelessWidget {
  final Size canvasSize;
  final ImageSettings imageSettings;
  final ValueChanged<ImageSettings> onChanged;
  final VoidCallback? onGestureStart;

  const CropOverlay({
    Key? key,
    required this.canvasSize,
    required this.imageSettings,
    required this.onChanged,
    this.onGestureStart,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final double left = imageSettings.cropLeft * canvasSize.width;
    final double top = imageSettings.cropTop * canvasSize.height;
    final double right = imageSettings.cropRight * canvasSize.width;
    final double bottom = imageSettings.cropBottom * canvasSize.height;
    final Rect cropRect = Rect.fromLTRB(left, top, right, bottom);

    const double handleSize = 36.0;
    const double halfSize = handleSize / 2;

    return Stack(
      children: [
        // 1. Scrim overlay outside crop boundaries
        Positioned.fill(
          child: CustomPaint(
            painter: CropScrimPainter(cropRect: cropRect),
          ),
        ),

        // 2. Corner Handles
        // Top-Left Corner
        Positioned(
          left: left - halfSize,
          top: top - halfSize,
          child: GestureDetector(
            onPanStart: (_) => onGestureStart?.call(),
            onPanUpdate: (details) {
              final double dx = details.delta.dx / canvasSize.width;
              final double dy = details.delta.dy / canvasSize.height;
              onChanged(imageSettings.copyWith(
                cropLeft: (imageSettings.cropLeft + dx).clamp(0.0, 0.45),
                cropTop: (imageSettings.cropTop + dy).clamp(0.0, 0.45),
              ));
            },
            child: Container(
              width: handleSize,
              height: handleSize,
              color: Colors.transparent,
              child: CustomPaint(
                painter: CropCornerPainter(isTop: true, isLeft: true),
              ),
            ),
          ),
        ),

        // Top-Right Corner
        Positioned(
          left: right - halfSize,
          top: top - halfSize,
          child: GestureDetector(
            onPanStart: (_) => onGestureStart?.call(),
            onPanUpdate: (details) {
              final double dx = details.delta.dx / canvasSize.width;
              final double dy = details.delta.dy / canvasSize.height;
              onChanged(imageSettings.copyWith(
                cropRight: (imageSettings.cropRight + dx).clamp(0.55, 1.0),
                cropTop: (imageSettings.cropTop + dy).clamp(0.0, 0.45),
              ));
            },
            child: Container(
              width: handleSize,
              height: handleSize,
              color: Colors.transparent,
              child: CustomPaint(
                painter: CropCornerPainter(isTop: true, isLeft: false),
              ),
            ),
          ),
        ),

        // Bottom-Left Corner
        Positioned(
          left: left - halfSize,
          top: bottom - halfSize,
          child: GestureDetector(
            onPanStart: (_) => onGestureStart?.call(),
            onPanUpdate: (details) {
              final double dx = details.delta.dx / canvasSize.width;
              final double dy = details.delta.dy / canvasSize.height;
              onChanged(imageSettings.copyWith(
                cropLeft: (imageSettings.cropLeft + dx).clamp(0.0, 0.45),
                cropBottom: (imageSettings.cropBottom + dy).clamp(0.55, 1.0),
              ));
            },
            child: Container(
              width: handleSize,
              height: handleSize,
              color: Colors.transparent,
              child: CustomPaint(
                painter: CropCornerPainter(isTop: false, isLeft: true),
              ),
            ),
          ),
        ),

        // Bottom-Right Corner
        Positioned(
          left: right - halfSize,
          top: bottom - halfSize,
          child: GestureDetector(
            onPanStart: (_) => onGestureStart?.call(),
            onPanUpdate: (details) {
              final double dx = details.delta.dx / canvasSize.width;
              final double dy = details.delta.dy / canvasSize.height;
              onChanged(imageSettings.copyWith(
                cropRight: (imageSettings.cropRight + dx).clamp(0.55, 1.0),
                cropBottom: (imageSettings.cropBottom + dy).clamp(0.55, 1.0),
              ));
            },
            child: Container(
              width: handleSize,
              height: handleSize,
              color: Colors.transparent,
              child: CustomPaint(
                painter: CropCornerPainter(isTop: false, isLeft: false),
              ),
            ),
          ),
        ),

        // 3. Edge Handles
        // Left Edge
        Positioned(
          left: left - halfSize,
          top: top + (bottom - top) / 2 - halfSize,
          child: GestureDetector(
            onPanStart: (_) => onGestureStart?.call(),
            onPanUpdate: (details) {
              final double dx = details.delta.dx / canvasSize.width;
              onChanged(imageSettings.copyWith(
                cropLeft: (imageSettings.cropLeft + dx).clamp(0.0, 0.45),
              ));
            },
            child: Container(
              width: handleSize,
              height: handleSize,
              color: Colors.transparent,
              child: Center(
                child: Container(
                  width: 4.0,
                  height: 16.0,
                  decoration: BoxDecoration(
                    color: const Color(0xFF3A3530),
                    borderRadius: BorderRadius.circular(2.0),
                  ),
                ),
              ),
            ),
          ),
        ),

        // Right Edge
        Positioned(
          left: right - halfSize,
          top: top + (bottom - top) / 2 - halfSize,
          child: GestureDetector(
            onPanStart: (_) => onGestureStart?.call(),
            onPanUpdate: (details) {
              final double dx = details.delta.dx / canvasSize.width;
              onChanged(imageSettings.copyWith(
                cropRight: (imageSettings.cropRight + dx).clamp(0.55, 1.0),
              ));
            },
            child: Container(
              width: handleSize,
              height: handleSize,
              color: Colors.transparent,
              child: Center(
                child: Container(
                  width: 4.0,
                  height: 16.0,
                  decoration: BoxDecoration(
                    color: const Color(0xFF3A3530),
                    borderRadius: BorderRadius.circular(2.0),
                  ),
                ),
              ),
            ),
          ),
        ),

        // Top Edge
        Positioned(
          left: left + (right - left) / 2 - halfSize,
          top: top - halfSize,
          child: GestureDetector(
            onPanStart: (_) => onGestureStart?.call(),
            onPanUpdate: (details) {
              final double dy = details.delta.dy / canvasSize.height;
              onChanged(imageSettings.copyWith(
                cropTop: (imageSettings.cropTop + dy).clamp(0.0, 0.45),
              ));
            },
            child: Container(
              width: handleSize,
              height: handleSize,
              color: Colors.transparent,
              child: Center(
                child: Container(
                  width: 16.0,
                  height: 4.0,
                  decoration: BoxDecoration(
                    color: const Color(0xFF3A3530),
                    borderRadius: BorderRadius.circular(2.0),
                  ),
                ),
              ),
            ),
          ),
        ),

        // Bottom Edge
        Positioned(
          left: left + (right - left) / 2 - halfSize,
          top: bottom - halfSize,
          child: GestureDetector(
            onPanStart: (_) => onGestureStart?.call(),
            onPanUpdate: (details) {
              final double dy = details.delta.dy / canvasSize.height;
              onChanged(imageSettings.copyWith(
                cropBottom: (imageSettings.cropBottom + dy).clamp(0.55, 1.0),
              ));
            },
            child: Container(
              width: handleSize,
              height: handleSize,
              color: Colors.transparent,
              child: Center(
                child: Container(
                  width: 16.0,
                  height: 4.0,
                  decoration: BoxDecoration(
                    color: const Color(0xFF3A3530),
                    borderRadius: BorderRadius.circular(2.0),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class CropScrimPainter extends CustomPainter {
  final Rect cropRect;

  CropScrimPainter({required this.cropRect});

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Draw solid dark background outside the cropped region
    final Paint scrimPaint = Paint()
      ..color = Colors.black.withOpacity(0.65)
      ..style = PaintingStyle.fill;

    final Path outerPath = Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height));
    final Path innerPath = Path()..addRect(cropRect);
    final Path scrimPath = Path.combine(PathOperation.difference, outerPath, innerPath);

    canvas.drawPath(scrimPath, scrimPaint);

    // 2. Draw active crop area border outline
    final Paint borderPaint = Paint()
      ..color = const Color(0xFFE2D1C3)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    canvas.drawRect(cropRect, borderPaint);
  }

  @override
  bool shouldRepaint(covariant CropScrimPainter oldDelegate) {
    return oldDelegate.cropRect != cropRect;
  }
}

class CropCornerPainter extends CustomPainter {
  final bool isTop;
  final bool isLeft;

  CropCornerPainter({required this.isTop, required this.isLeft});

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = const Color(0xFF3A3530)
      ..strokeWidth = 4.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final double len = 14.0; // corner line segment length

    final Path path = Path();
    if (isTop && isLeft) {
      path.moveTo(len, 0);
      path.lineTo(0, 0);
      path.lineTo(0, len);
    } else if (isTop && !isLeft) {
      path.moveTo(size.width - len, 0);
      path.lineTo(size.width, 0);
      path.lineTo(size.width, len);
    } else if (!isTop && isLeft) {
      path.moveTo(0, size.height - len);
      path.lineTo(0, size.height);
      path.lineTo(len, size.height);
    } else if (!isTop && !isLeft) {
      path.moveTo(size.width - len, size.height);
      path.lineTo(size.width, size.height);
      path.lineTo(size.width, size.height - len);
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
