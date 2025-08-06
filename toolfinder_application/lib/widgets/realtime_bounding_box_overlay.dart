import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import '../models/detection.dart';

class RealtimeBoundingBoxOverlay extends StatefulWidget {
  final List<Detection> detections;
  final CameraController cameraController;

  const RealtimeBoundingBoxOverlay({
    super.key,
    required this.detections,
    required this.cameraController,
  });

  @override
  State<RealtimeBoundingBoxOverlay> createState() => _RealtimeBoundingBoxOverlayState();
}

class _RealtimeBoundingBoxOverlayState extends State<RealtimeBoundingBoxOverlay>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);
    
    _pulseAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.cameraController.value.isInitialized) {
      return const SizedBox.shrink();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final previewSize = widget.cameraController.value.previewSize!;
        
        // Calculate scaling factors
        final scaleX = constraints.maxWidth / previewSize.height;
        final scaleY = constraints.maxHeight / previewSize.width;

        return Stack(
          children: widget.detections.map((detection) {
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
    final left = (detection.x1 * scaleX).clamp(0.0, constraints.maxWidth);
    final top = (detection.y1 * scaleY).clamp(0.0, constraints.maxHeight);
    final right = (detection.x2 * scaleX).clamp(0.0, constraints.maxWidth);
    final bottom = (detection.y2 * scaleY).clamp(0.0, constraints.maxHeight);

    final width = (right - left).clamp(0.0, constraints.maxWidth - left);
    final height = (bottom - top).clamp(0.0, constraints.maxHeight - top);

    if (width <= 0 || height <= 0) {
      return const SizedBox.shrink();
    }

    final color = _getClassColor(detection.classId);

    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Positioned(
          left: left,
          top: top,
          child: Container(
            width: width,
            height: height,
            decoration: BoxDecoration(
              border: Border.all(
                color: color.withValues(alpha: _pulseAnimation.value),
                width: 3.0,
              ),
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.3 * _pulseAnimation.value),
                  blurRadius: 8,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Stack(
              children: [
                // Modern corner indicators
                ..._buildModernCornerIndicators(color),
                
                // Enhanced label with glassmorphism
                Positioned(
                  top: -4,
                  left: -4,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.8),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: color.withValues(alpha: 0.6),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.5),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      '${detection.className} ${(detection.confidence * 100).toInt()}%',
                      style: TextStyle(
                        color: color,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        shadows: [
                          Shadow(
                            color: Colors.black.withValues(alpha: 0.8),
                            offset: const Offset(1, 1),
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
      },
    );
  }

  List<Widget> _buildModernCornerIndicators(Color color) {
    const cornerSize = 24.0;
    const cornerThickness = 3.0;

    return [
      // Top-left corner with glow
      Positioned(
        top: -2,
        left: -2,
        child: Container(
          width: cornerSize,
          height: cornerThickness,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.6),
                blurRadius: 4,
                spreadRadius: 1,
              ),
            ],
          ),
        ),
      ),
      Positioned(
        top: -2,
        left: -2,
        child: Container(
          width: cornerThickness,
          height: cornerSize,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.6),
                blurRadius: 4,
                spreadRadius: 1,
              ),
            ],
          ),
        ),
      ),
      
      // Top-right corner
      Positioned(
        top: -2,
        right: -2,
        child: Container(
          width: cornerSize,
          height: cornerThickness,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.6),
                blurRadius: 4,
                spreadRadius: 1,
              ),
            ],
          ),
        ),
      ),
      Positioned(
        top: -2,
        right: -2,
        child: Container(
          width: cornerThickness,
          height: cornerSize,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.6),
                blurRadius: 4,
                spreadRadius: 1,
              ),
            ],
          ),
        ),
      ),
      
      // Bottom-left corner
      Positioned(
        bottom: -2,
        left: -2,
        child: Container(
          width: cornerSize,
          height: cornerThickness,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.6),
                blurRadius: 4,
                spreadRadius: 1,
              ),
            ],
          ),
        ),
      ),
      Positioned(
        bottom: -2,
        left: -2,
        child: Container(
          width: cornerThickness,
          height: cornerSize,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.6),
                blurRadius: 4,
                spreadRadius: 1,
              ),
            ],
          ),
        ),
      ),
      
      // Bottom-right corner
      Positioned(
        bottom: -2,
        right: -2,
        child: Container(
          width: cornerSize,
          height: cornerThickness,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.6),
                blurRadius: 4,
                spreadRadius: 1,
              ),
            ],
          ),
        ),
      ),
      Positioned(
        bottom: -2,
        right: -2,
        child: Container(
          width: cornerThickness,
          height: cornerSize,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.6),
                blurRadius: 4,
                spreadRadius: 1,
              ),
            ],
          ),
        ),
      ),
    ];
  }

  Color _getClassColor(int classId) {
    const colors = [
      Color(0xFFFF6B6B), // FireExtinguisher - Bright red
      Color(0xFF4ECDC4), // ToolBox - Cyan
      Color(0xFF45B7D1), // OxygenTank - Blue
    ];
    return colors[classId % colors.length];
  }
}