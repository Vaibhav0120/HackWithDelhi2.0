import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import '../models/detection.dart';

class BoundingBoxOverlay extends StatelessWidget {
  final String imagePath;
  final List<Detection> detections;

  const BoundingBoxOverlay({
    super.key,
    required this.imagePath,
    required this.detections,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Size>(
      future: _getImageSize(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox.shrink();
        }

        final imageSize = snapshot.data!;
        
        return LayoutBuilder(
          builder: (context, constraints) {
            // Calculate the actual display size of the image
            final containerSize = Size(constraints.maxWidth, constraints.maxHeight);
            final displaySize = _calculateDisplaySize(imageSize, containerSize);
            final offset = _calculateOffset(displaySize, containerSize);

            return Stack(
              children: detections.map((detection) {
                return _buildBoundingBox(detection, imageSize, displaySize, offset, context);
              }).toList(),
            );
          },
        );
      },
    );
  }

  Future<Size> _getImageSize() async {
    final imageFile = File(imagePath);
    final imageBytes = await imageFile.readAsBytes();
    final image = img.decodeImage(imageBytes);
    
    if (image != null) {
      return Size(image.width.toDouble(), image.height.toDouble());
    }
    
    return const Size(1, 1);
  }

  Size _calculateDisplaySize(Size imageSize, Size containerSize) {
    final imageAspectRatio = imageSize.width / imageSize.height;
    final containerAspectRatio = containerSize.width / containerSize.height;

    if (imageAspectRatio > containerAspectRatio) {
      // Image is wider than container
      return Size(
        containerSize.width,
        containerSize.width / imageAspectRatio,
      );
    } else {
      // Image is taller than container
      return Size(
        containerSize.height * imageAspectRatio,
        containerSize.height,
      );
    }
  }

  Offset _calculateOffset(Size displaySize, Size containerSize) {
    return Offset(
      (containerSize.width - displaySize.width) / 2,
      (containerSize.height - displaySize.height) / 2,
    );
  }

  Widget _buildBoundingBox(
    Detection detection,
    Size imageSize,
    Size displaySize,
    Offset offset,
    BuildContext context,
  ) {
    // FIXED: Scale coordinates properly and clamp to prevent overflow
    final scaleX = displaySize.width / imageSize.width;
    final scaleY = displaySize.height / imageSize.height;

    final left = (detection.x1 * scaleX + offset.dx).clamp(0.0, displaySize.width + offset.dx);
    final top = (detection.y1 * scaleY + offset.dy).clamp(0.0, displaySize.height + offset.dy);
    final right = (detection.x2 * scaleX + offset.dx).clamp(0.0, displaySize.width + offset.dx);
    final bottom = (detection.y2 * scaleY + offset.dy).clamp(0.0, displaySize.height + offset.dy);

    final width = (right - left).clamp(0.0, displaySize.width);
    final height = (bottom - top).clamp(0.0, displaySize.height);

    // Skip invalid boxes
    if (width <= 0 || height <= 0) {
      return const SizedBox.shrink();
    }

    final color = _getClassColor(detection.classId);

    return Positioned(
      left: left,
      top: top,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          border: Border.all(
            color: color,
            width: 2.5,
          ),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Stack(
          children: [
            // Label background
            Positioned(
              top: -2,
              left: -2,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(4),
                    bottomRight: Radius.circular(4),
                  ),
                ),
                child: Text(
                  '${detection.className} ${(detection.confidence * 100).toInt()}%',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getClassColor(int classId) {
    const colors = [
      Color(0xFFFF7675), // FireExtinguisher - Mars red
      Color(0xFF6C5CE7), // ToolBox - Space purple  
      Color(0xFF00CEC9), // OxygenTank - Cosmic teal
    ];
    return colors[classId % colors.length];
  }
}
