import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import '../models/detection.dart';

class RealtimeBoundingBoxOverlay extends StatelessWidget {
  final List<Detection> detections;
  final CameraController cameraController;

  const RealtimeBoundingBoxOverlay({
    super.key,
    required this.detections,
    required this.cameraController,
  });

  @override
  Widget build(BuildContext context) {
    if (!cameraController.value.isInitialized) {
      return const SizedBox.shrink();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final previewSize = cameraController.value.previewSize!;
        
        // Calculate scaling factors
        final scaleX = constraints.maxWidth / previewSize.height; // Note: swapped for rotation
        final scaleY = constraints.maxHeight / previewSize.width;  // Note: swapped for rotation

        return Stack(
          children: detections.map((detection) {
            return _buildBoundingBox(detection, scaleX, scaleY, constraints);
          }).toList(),
        );
      },
    );
  }

  Widget _buildBoundingBox(
    Detection detection,
    double scaleX,
    double scaleY,
    BoxConstraints constraints,
  ) {
    // FIXED: Proper scaling and clamping for real-time detection
    final left = (detection.x1 * scaleX).clamp(0.0, constraints.maxWidth);
    final top = (detection.y1 * scaleY).clamp(0.0, constraints.maxHeight);
    final right = (detection.x2 * scaleX).clamp(0.0, constraints.maxWidth);
    final bottom = (detection.y2 * scaleY).clamp(0.0, constraints.maxHeight);

    final width = (right - left).clamp(0.0, constraints.maxWidth - left);
    final height = (bottom - top).clamp(0.0, constraints.maxHeight - top);

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
            width: 3.0,
          ),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Stack(
          children: [
            // Animated corner indicators
            ..._buildCornerIndicators(color),
            
            // Label
            Positioned(
              top: -3,
              left: -3,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(6),
                    bottomRight: Radius.circular(6),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  '${detection.className} ${(detection.confidence * 100).toInt()}%',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    shadows: [
                      Shadow(
                        color: Colors.black54,
                        offset: Offset(1, 1),
                        blurRadius: 2,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildCornerIndicators(Color color) {
    const cornerSize = 20.0;
    const cornerThickness = 4.0;

    return [
      // Top-left corner
      Positioned(
        top: 0,
        left: 0,
        child: Container(
          width: cornerSize,
          height: cornerThickness,
          color: color,
        ),
      ),
      Positioned(
        top: 0,
        left: 0,
        child: Container(
          width: cornerThickness,
          height: cornerSize,
          color: color,
        ),
      ),
      
      // Top-right corner
      Positioned(
        top: 0,
        right: 0,
        child: Container(
          width: cornerSize,
          height: cornerThickness,
          color: color,
        ),
      ),
      Positioned(
        top: 0,
        right: 0,
        child: Container(
          width: cornerThickness,
          height: cornerSize,
          color: color,
        ),
      ),
      
      // Bottom-left corner
      Positioned(
        bottom: 0,
        left: 0,
        child: Container(
          width: cornerSize,
          height: cornerThickness,
          color: color,
        ),
      ),
      Positioned(
        bottom: 0,
        left: 0,
        child: Container(
          width: cornerThickness,
          height: cornerSize,
          color: color,
        ),
      ),
      
      // Bottom-right corner
      Positioned(
        bottom: 0,
        right: 0,
        child: Container(
          width: cornerSize,
          height: cornerThickness,
          color: color,
        ),
      ),
      Positioned(
        bottom: 0,
        right: 0,
        child: Container(
          width: cornerThickness,
          height: cornerSize,
          color: color,
        ),
      ),
    ];
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
