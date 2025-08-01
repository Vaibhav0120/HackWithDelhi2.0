import 'dart:io';
import 'package:flutter/material.dart';
import '../services/onnx_inference.dart';
import '../widgets/glass_button.dart';
import 'result_screen.dart';

class ImagePreviewScreen extends StatefulWidget {
  final String imagePath;

  const ImagePreviewScreen({super.key, required this.imagePath});

  @override
  State<ImagePreviewScreen> createState() => _ImagePreviewScreenState();
}

class _ImagePreviewScreenState extends State<ImagePreviewScreen> {
  bool _isProcessing = false;
  bool _isInitializing = true;
  late final OnnxInference _inference;

  @override
  void initState() {
    super.initState();
    _inference = OnnxInference();
    _initializeModel();
  }

  @override
  void dispose() {
    _inference.dispose();
    super.dispose();
  }

  Future<void> _initializeModel() async {
    try {
      await _inference.initialize();
      if (mounted) {
        setState(() {
          _isInitializing = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isInitializing = false;
        });
      }
    }
  }

  Future<void> _detectObjects() async {
    if (_isInitializing) {
      _showSnackBar(
        'Neural network is still initializing...',
        Theme.of(context).colorScheme.secondary,
        Icons.hourglass_empty_rounded,
      );
      return;
    }

    if (_inference.initError != null) {
      _showSnackBar(
        'Neural network unavailable: ${_inference.initError!}',
        Theme.of(context).colorScheme.tertiary,
        Icons.error_rounded,
      );
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      final detections = await _inference.runInference(widget.imagePath);
      
      if (mounted) {
        Navigator.push(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                ResultScreen(
                  imagePath: widget.imagePath,
                  detections: detections,
                ),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(1.0, 0.0),
                  end: Offset.zero,
                ).animate(CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeOut,
                )),
                child: child,
              );
            },
            transitionDuration: const Duration(milliseconds: 250),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar(
          'Detection failed: $e',
          Theme.of(context).colorScheme.tertiary,
          Icons.error_rounded,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  void _showSnackBar(String message, Color color, IconData icon) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Image Analysis'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF0B0E1A),
              Color(0xFF1A1A2E),
              Color(0xFF16213E),
              Color(0xFF0F3460),
            ],
            stops: [0.0, 0.3, 0.7, 1.0],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                // Status Card (without rotation animation)
                if (_isInitializing || _inference.initError != null) ...[
                  _buildStatusCard(),
                  const SizedBox(height: 20),
                ],
                
                // Enhanced Image Preview
                Expanded(
                  child: Hero(
                    tag: 'image_${widget.imagePath}',
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.4),
                            blurRadius: 25,
                            offset: const Offset(0, 15),
                          ),
                          BoxShadow(
                            color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                            blurRadius: 40,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: Image.file(
                          File(widget.imagePath),
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              decoration: BoxDecoration(
                                color: Colors.grey[900],
                                borderRadius: BorderRadius.circular(24),
                              ),
                              child: Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.broken_image_rounded,
                                      color: Theme.of(context).colorScheme.tertiary,
                                      size: 64,
                                    ),
                                    const SizedBox(height: 16),
                                    const Text(
                                      'Image loading failed',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 18,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(height: 32),
                
                // Enhanced Detect Button
                SizedBox(
                  width: double.infinity,
                  child: _isProcessing
                      ? _buildProcessingCard()
                      : GlassButton(
                          onPressed: _detectObjects,
                          icon: Icons.radar_rounded,
                          title: 'Analyze Objects',
                          subtitle: _inference.initError != null 
                              ? 'Neural network unavailable' 
                              : _isInitializing 
                                  ? 'Initializing neural network...' 
                                  : 'Activate YOLOv8 Detection',
                          isFullWidth: true,
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusCard() {
    final isError = _inference.initError != null;
    final isLoading = _isInitializing;
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: isError 
            ? Theme.of(context).colorScheme.tertiary.withOpacity(0.1)
            : isLoading 
                ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
                : Theme.of(context).colorScheme.secondary.withOpacity(0.1),
        border: Border.all(
          color: isError 
              ? Theme.of(context).colorScheme.tertiary.withOpacity(0.3)
              : isLoading 
                  ? Theme.of(context).colorScheme.primary.withOpacity(0.3)
                  : Theme.of(context).colorScheme.secondary.withOpacity(0.3),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: (isError 
                ? Theme.of(context).colorScheme.tertiary
                : isLoading 
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.secondary).withOpacity(0.2),
            blurRadius: 15,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (isLoading) ...[
                Container(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
              ] else if (isError) ...[
                Icon(
                  Icons.error_rounded,
                  color: Theme.of(context).colorScheme.tertiary,
                  size: 24,
                ),
                const SizedBox(width: 16),
              ] else ...[
                Icon(
                  Icons.check_circle_rounded,
                  color: Theme.of(context).colorScheme.secondary,
                  size: 24,
                ),
                const SizedBox(width: 16),
              ],
              Expanded(
                child: Text(
                  _inference.initStatus,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          if (isError) ...[
            const SizedBox(height: 16),
            Text(
              'Error: ${_inference.initError!}',
              style: TextStyle(
                color: Theme.of(context).colorScheme.tertiary.withOpacity(0.8),
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Please ensure best.onnx (opset 13) is in the assets folder and properly configured.',
              style: TextStyle(
                color: Theme.of(context).colorScheme.tertiary.withOpacity(0.7),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _isInitializing = true;
                });
                _initializeModel();
              },
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry Initialization'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildProcessingCard() {
    return Container(
      height: 90,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primary.withOpacity(0.2),
            Theme.of(context).colorScheme.secondary.withOpacity(0.1),
          ],
        ),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 28,
            height: 28,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation<Color>(
                Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
          const SizedBox(width: 24),
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Neural Network Processing...',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Analyzing objects with YOLOv8',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white.withOpacity(0.7),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}