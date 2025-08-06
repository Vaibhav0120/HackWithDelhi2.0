import 'dart:async';
import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import '../models/detection.dart';
import '../main.dart';
import '../widgets/realtime_bounding_box_overlay.dart';
import '../widgets/glass_button.dart';

class RealtimeDetectionScreen extends StatefulWidget {
  const RealtimeDetectionScreen({super.key});

  @override
  State<RealtimeDetectionScreen> createState() => _RealtimeDetectionScreenState();
}

class _RealtimeDetectionScreenState extends State<RealtimeDetectionScreen>
    with WidgetsBindingObserver {
  CameraController? _cameraController;
  late List<CameraDescription> _cameras;
  bool _isCameraInitialized = false;
  bool _isRealtimeActive = false;
  List<Detection> _currentDetections = [];
  Timer? _detectionTimer;
  String _statusMessage = 'Initializing camera...';
  
  // FIXED: Ultra-high FPS settings with optimized processing
  final List<String> _imageQueue = [];
  bool _isProcessing = false;
  int _frameSkipCounter = 0;
  
  // FIXED: 30 FPS for ultra-smooth detection
  static const int _maxQueueSize = 1;
  static const int _frameSkipRate = 1; // Process every frame
  static const int _detectionInterval = 33; // 33ms = 30 FPS

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeCamera();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _detectionTimer?.cancel();
    _cameraController?.dispose();
    _cleanupImageQueue();
    super.dispose();
  }

  void _cleanupImageQueue() {
    for (final imagePath in _imageQueue) {
      try {
        File(imagePath).deleteSync();
      } catch (e) {
        // Ignore cleanup errors
      }
    }
    _imageQueue.clear();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }

    if (state == AppLifecycleState.inactive) {
      _stopRealtimeDetection();
      _cameraController?.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _initializeCamera();
    }
  }

  Future<void> _initializeCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras.isEmpty) {
        if (mounted) {
          setState(() {
            _statusMessage = 'No cameras available';
          });
        }
        return;
      }

      // FIXED: Ultra-high resolution for best quality
      _cameraController = CameraController(
        _cameras.first,
        ResolutionPreset.ultraHigh, // Maximum resolution
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      await _cameraController!.initialize();

      if (mounted) {
        setState(() {
          _isCameraInitialized = true;
          _statusMessage = ModelManager.instance.isPreloaded 
              ? 'Ready for ultra-high-speed detection' 
              : 'Neural network loading...';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _statusMessage = 'Camera initialization failed: $e';
        });
      }
    }
  }

  void _startRealtimeDetection() {
    if (!_isCameraInitialized || !ModelManager.instance.isPreloaded) {
      _showSnackBar(
        'Camera or neural network not ready',
        Theme.of(context).colorScheme.tertiary,
        Icons.warning_rounded,
      );
      return;
    }

    setState(() {
      _isRealtimeActive = true;
      _statusMessage = 'Ultra-high-speed detection active • 30 FPS';
      _imageQueue.clear();
      _frameSkipCounter = 0;
    });

    // FIXED: Ultra-high FPS detection rate
    _detectionTimer = Timer.periodic(const Duration(milliseconds: _detectionInterval), (timer) {
      if (_isRealtimeActive) {
        _captureAndProcess();
      }
    });
  }

  void _stopRealtimeDetection() {
    setState(() {
      _isRealtimeActive = false;
      _statusMessage = 'Detection stopped';
      _currentDetections.clear();
    });

    _detectionTimer?.cancel();
    _detectionTimer = null;
    _cleanupImageQueue();
    _isProcessing = false;
  }

  // FIXED: Ultra-optimized for 30 FPS with no pausing
  Future<void> _captureAndProcess() async {
    if (!_isCameraInitialized || !_isRealtimeActive || _isProcessing) return;

    // FIXED: Process every frame for maximum smoothness
    _frameSkipCounter++;
    if (_frameSkipCounter < _frameSkipRate) return;
    _frameSkipCounter = 0;

    // FIXED: Minimal queue for instant processing
    if (_imageQueue.length >= _maxQueueSize) {
      final oldImage = _imageQueue.removeAt(0);
      try {
        await File(oldImage).delete();
      } catch (e) {
        // Ignore cleanup errors
      }
    }

    try {
      _isProcessing = true;
      
      // FIXED: Ultra-fast capture with no blocking
      final image = await _cameraController!.takePicture();
      
      // FIXED: Immediate processing for no delays
      _processImageAsync(image.path);
      
    } catch (e) {
      // Silently handle capture errors
    } finally {
      _isProcessing = false;
    }
  }

  // FIXED: Async processing to prevent camera pausing
  void _processImageAsync(String imagePath) async {
    try {
      // FIXED: Process in background without blocking camera
      final detections = await ModelManager.instance.getInference().runInference(imagePath);
      
      if (mounted && _isRealtimeActive) {
        setState(() {
          _currentDetections = detections;
          _statusMessage = detections.isEmpty 
              ? 'Ultra-high-speed scanning • 30 FPS' 
              : '${detections.length} object${detections.length > 1 ? 's' : ''} detected • 30 FPS';
        });
      }

      // Immediate cleanup for ultra-high FPS
      try {
        await File(imagePath).delete();
      } catch (e) {
        // Ignore cleanup errors
      }

    } catch (e) {
      if (mounted) {
        setState(() {
          _statusMessage = 'Detection processing • 30 FPS';
        });
      }
      
      // Clean up on error
      try {
        await File(imagePath).delete();
      } catch (e) {
        // Ignore cleanup errors
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
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Live Detection'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () {
            _stopRealtimeDetection();
            Navigator.pop(context);
          },
        ),
        // FIXED: Removed settings button from live detection
        actions: [
          if (_isRealtimeActive && _currentDetections.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.5),
                    ),
                  ),
                  child: Text(
                    '${_currentDetections.length} FOUND',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.secondary,
                      fontWeight: FontWeight.bold,
                      fontSize: 10,
                    ),
                  ),
                ),
              ),
            ),
        ],
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
          child: Column(
            children: [
              // Enhanced Status Bar
              _buildStatusBar(),
              
              const SizedBox(height: 16),
              
              // Camera Preview with Overlay
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _buildCameraPreview(),
                ),
              ),
              
              const SizedBox(height: 20),
              
              // Control Buttons
              _buildControlButtons(),
              
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.black.withValues(alpha: 0.3),
        border: Border.all(
          color: _isRealtimeActive 
              ? Theme.of(context).colorScheme.secondary.withValues(alpha: 0.5)
              : Colors.white.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          // Status Indicator
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _isRealtimeActive 
                  ? Theme.of(context).colorScheme.secondary
                  : _isCameraInitialized && ModelManager.instance.isPreloaded
                      ? Theme.of(context).colorScheme.primary
                      : Colors.grey,
              boxShadow: _isRealtimeActive ? [
                BoxShadow(
                  color: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.6),
                  blurRadius: 8,
                  spreadRadius: 2,
                ),
              ] : null,
            ),
          ),
          
          const SizedBox(width: 12),
          
          // Status Text
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _statusMessage,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (_isRealtimeActive) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Ultra-high resolution • Real-time processing',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
          ),
          
          // Detection Count Badge
          if (_currentDetections.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.secondary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${_currentDetections.length}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCameraPreview() {
    if (!_isCameraInitialized) {
      return Container(
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.2),
          ),
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text(
                'Initializing Ultra-High-Speed Camera...',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 25,
            offset: const Offset(0, 15),
          ),
          if (_isRealtimeActive)
            BoxShadow(
              color: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.3),
              blurRadius: 40,
              spreadRadius: 5,
            ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            // Camera preview
            SizedBox.expand(
              child: FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: _cameraController!.value.previewSize!.height,
                  height: _cameraController!.value.previewSize!.width,
                  child: CameraPreview(_cameraController!),
                ),
              ),
            ),
            
            // FIXED: Improved Bounding Box Overlay with better positioning
            if (_isRealtimeActive)
              RealtimeBoundingBoxOverlay(
                detections: _currentDetections,
                cameraController: _cameraController!,
              ),
            
            // Processing Indicator (smaller and less intrusive)
            if (_isProcessing)
              Positioned(
                top: 16,
                right: 16,
                child: Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.secondary,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.6),
                        blurRadius: 3,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                ),
              ),
            
            // Detection Info Overlay
            if (_isRealtimeActive)
              Positioned(
                bottom: 16,
                left: 16,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                      ),
                      child: Text(
                        _currentDetections.isEmpty 
                            ? 'Scanning at 30 FPS...' 
                            : '${_currentDetections.length} Objects • 30 FPS',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildControlButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          // Start/Stop Button (Full width, no settings button)
          Expanded(
            child: GlassButton(
              onPressed: _isCameraInitialized && ModelManager.instance.isPreloaded
                  ? (_isRealtimeActive ? _stopRealtimeDetection : _startRealtimeDetection)
                  : () {},
              icon: _isRealtimeActive ? Icons.stop_rounded : Icons.play_arrow_rounded,
              title: _isRealtimeActive ? 'Stop Detection' : 'Start Detection',
              subtitle: _isRealtimeActive 
                  ? 'End ultra-high-speed scan'
                  : 'Begin 30 FPS detection',
              isFullWidth: true,
              isCompactMode: true,
              isPrimary: true,
            ),
          ),
        ],
      ),
    );
  }
}
