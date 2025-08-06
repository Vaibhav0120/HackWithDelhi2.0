import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import '../widgets/glass_button.dart';
import '../main.dart';
import 'result_screen.dart';

class ImagePreviewScreen extends StatefulWidget {
  final String imagePath;

  const ImagePreviewScreen({
    super.key,
    required this.imagePath,
  });

  @override
  State<ImagePreviewScreen> createState() => _ImagePreviewScreenState();
}

class _ImagePreviewScreenState extends State<ImagePreviewScreen> {
  bool _isAnalyzing = false;
  String _statusMessage = 'Ready to analyze';

  Future<void> _analyzeImage() async {
    if (!ModelManager.instance.isPreloaded) {
      _showSnackBar(
        'Neural network not ready. Please wait for model to load.',
        Theme.of(context).colorScheme.tertiary,
        Icons.warning_rounded,
      );
      return;
    }

    setState(() {
      _isAnalyzing = true;
      _statusMessage = 'Analyzing image...';
    });

    try {
      // FUNCTIONAL: Use settings-aware inference
      final detections = await ModelManager.instance.getInference().runInference(widget.imagePath);
      
      if (mounted) {
        Navigator.pushReplacement(
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
            transitionDuration: const Duration(milliseconds: 300),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isAnalyzing = false;
          _statusMessage = 'Analysis failed';
        });
        
        _showSnackBar(
          'Analysis failed: ${e.toString()}',
          Theme.of(context).colorScheme.tertiary,
          Icons.error_rounded,
        );
      }
    }
  }

  void _showSnackBar(String message, Color color, IconData icon) {
    if (!mounted) return;
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
        title: const Text('Image Preview'),
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
            padding: const EdgeInsets.all(20.0),
            child: Column(
              children: [
                // Status Card
                _buildStatusCard(),
                
                const SizedBox(height: 20),
                
                // Image Preview
                Expanded(
                  child: Hero(
                    tag: 'image_${widget.imagePath}',
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.4),
                            blurRadius: 25,
                            offset: const Offset(0, 15),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: Image.file(
                          File(widget.imagePath),
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: GlassButton(
                        onPressed: () => Navigator.pop(context),
                        icon: Icons.arrow_back_rounded,
                        title: 'Back',
                        subtitle: 'Choose different',
                        isCompactMode: true,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 2,
                      child: GlassButton(
                        onPressed: _isAnalyzing ? () {} : _analyzeImage,
                        icon: _isAnalyzing ? Icons.hourglass_empty_rounded : Icons.search_rounded,
                        title: _isAnalyzing ? 'Analyzing...' : 'Detect Objects',
                        subtitle: _isAnalyzing ? 'Please wait' : 'Start analysis',
                        isCompactMode: true,
                        isPrimary: true,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusCard() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.2),
            ),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withValues(alpha: 0.15),
                Colors.white.withValues(alpha: 0.05),
              ],
            ),
          ),
          child: Row(
            children: [
              // Status Icon
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      _isAnalyzing
                          ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.3)
                          : ModelManager.instance.isPreloaded
                              ? Theme.of(context).colorScheme.secondary.withValues(alpha: 0.3)
                              : Colors.grey.withValues(alpha: 0.3),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: _isAnalyzing
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 3,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                    : Icon(
                        ModelManager.instance.isPreloaded
                            ? Icons.check_circle_rounded
                            : Icons.hourglass_empty_rounded,
                        color: ModelManager.instance.isPreloaded
                            ? Theme.of(context).colorScheme.secondary
                            : Colors.grey,
                        size: 24,
                      ),
              ),
              
              const SizedBox(width: 16),
              
              // Status Text
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _statusMessage,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      ModelManager.instance.isPreloaded
                          ? 'Neural network ready for analysis'
                          : 'Waiting for neural network...',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
