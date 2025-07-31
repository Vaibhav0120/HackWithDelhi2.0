import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import '../models/detection.dart';

class BoundingBoxOverlay extends StatefulWidget {
  final String imagePath;
  final List<Detection> detections;

  const BoundingBoxOverlay({
    super.key,
    required this.imagePath,
    required this.detections,
  });

  @override
  State<BoundingBoxOverlay> createState() => _BoundingBoxOverlayState();
}

class _BoundingBoxOverlayState extends State<BoundingBoxOverlay> {
  Size? _imageSize;

  @override
  void initState() {
    super.initState();
    _loadImageSize();
  }

  Future<void> _loadImageSize() async {
    final imageBytes = await File(widget.imagePath).readAsBytes();
    final image = img.decodeImage(imageBytes);
    if (image != null) {
      setState(() {
        _imageSize = Size(image.width.toDouble(), image.height.toDouble());
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_imageSize == null) {
      return const SizedBox.shrink();
    }

    return CustomPaint(
      painter: BoundingBoxPainter(
        detections: widget.detections,
        imageSize: _imageSize!,
      ),
      child: Container(),
    );
  }
}

class BoundingBoxPainter extends CustomPainter {
  final List<Detection> detections;
  final Size imageSize;

  BoundingBoxPainter({
    required this.detections,
    required this.imageSize,
  });

  static const List<Color> _classColors = [
    Color(0xFFFF6B6B), // FireExtinguisher - Red
    Color(0xFF4ECDC4), // ToolBox - Teal
    Color(0xFFFFE66D), // OxygenTank - Yellow
  ];

  @override
  void paint(Canvas canvas, Size size) {
    // Calculate scale factors
    final scaleX = size.width / imageSize.width;
    final scaleY = size.height / imageSize.height;
    final scale = scaleX < scaleY ? scaleX : scaleY;

    // Calculate offset to center the image
    final offsetX = (size.width - imageSize.width * scale) / 2;
    final offsetY = (size.height - imageSize.height * scale) / 2;

    for (final detection in detections) {
      final color = _classColors[detection.classId % _classColors.length];
      
      // Scale and offset coordinates
      final left = detection.x1 * scale + offsetX;
      final top = detection.y1 * scale + offsetY;
      final right = detection.x2 * scale + offsetX;
      final bottom = detection.y2 * scale + offsetY;

      // Draw bounding box
      final boxPaint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.0;

      final rect = Rect.fromLTRB(left, top, right, bottom);
      canvas.drawRect(rect, boxPaint);

      // Draw label background
      final labelText = '${detection.className} ${(detection.confidence * 100).toInt()}%';
      final textPainter = TextPainter(
        text: TextSpan(
          text: labelText,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();

      final labelRect = Rect.fromLTWH(
        left,
        top - textPainter.height - 8,
        textPainter.width + 8,
        textPainter.height + 4,
      );

      final labelPaint = Paint()..color = color;
      canvas.drawRect(labelRect, labelPaint);

      // Draw label text
      textPainter.paint(canvas, Offset(left + 4, top - textPainter.height - 6));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
