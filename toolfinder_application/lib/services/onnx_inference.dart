import 'dart:io';
import 'dart:typed_data';
import 'dart:math' as math;
import 'dart:developer' as developer;
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:onnxruntime/onnxruntime.dart';
import 'package:path_provider/path_provider.dart';
import '../models/detection.dart';

class OnnxInference {
  OrtSession? _session;
  bool _isInitialized = false;
  String _initStatus = 'Not initialized';
  String? _initError;
  
  static const List<String> _classNames = [
    'FireExtinguisher',
    'ToolBox',
    'OxygenTank',
  ];

  bool get isInitialized => _isInitialized;
  String get initStatus => _initStatus;
  String? get initError => _initError;

  Future<void> initialize() async {
    if (_isInitialized) {
      developer.log('🔄 ONNX model already initialized');
      developer.log('🔄 ONNX model already initialized');
      return;
    }

    try {
      developer.log('🚀 Starting ONNX model initialization for opset 13...');
      developer.log('🚀 Starting ONNX model initialization for opset 13...');
      _initStatus = 'Loading model from assets...';
      _initError = null;
      
      // Load model from assets
      final modelData = await rootBundle.load('assets/best.onnx');
      developer.log('📦 Model loaded from assets, size: ${modelData.lengthInBytes} bytes');
      developer.log('📦 Model loaded from assets, size: ${modelData.lengthInBytes} bytes');
      
      if (modelData.lengthInBytes == 0) {
        throw Exception('Model file is empty. Please ensure best.onnx is in the assets folder.');
      }
      
      _initStatus = 'Copying model to temporary directory...';
      
      // Copy model to temporary directory
      final tempDir = await getTemporaryDirectory();
      final modelFile = File('${tempDir.path}/best.onnx');
      await modelFile.writeAsBytes(modelData.buffer.asUint8List());
      
      developer.log('📁 Model copied to: ${modelFile.path}');
      developer.log('📁 Model copied to: ${modelFile.path}');
      
      // Verify file exists and has content
      if (!await modelFile.exists()) {
        throw Exception('Model file was not created successfully');
      }
      
      final fileSize = await modelFile.length();
      if (fileSize == 0) {
        throw Exception('Model file is empty after copying');
      }
      
      developer.log('✅ Model file verified, size: $fileSize bytes');
      developer.log('✅ Model file verified, size: $fileSize bytes');
      _initStatus = 'Creating ONNX session...';
      
      // Initialize ONNX Runtime session with optimized options for opset 13
      final sessionOptions = OrtSessionOptions();
      
      // Set optimization level to basic for better compatibility with opset 13
      sessionOptions.setSessionGraphOptimizationLevel(GraphOptimizationLevel.ortEnableBasic);
      developer.log('⚙️ Set basic graph optimization for opset 13');
      developer.log('⚙️ Set basic graph optimization for opset 13');
      
      // Create session
      developer.log('🔧 Creating ONNX session...');
      developer.log('🔧 Creating ONNX session...');
      _session = OrtSession.fromFile(modelFile, sessionOptions);
      developer.log('✅ ONNX session created successfully');
      developer.log('✅ ONNX session created successfully');
      
      _initStatus = 'Testing model compatibility...';
      
      // Test the session with a dummy input to verify it works
      await _testSession();
      
      _isInitialized = true;
      _initStatus = 'Model ready! ✅';
      developer.log('🎉 ONNX model (opset 13) initialized successfully!');
      developer.log('🎉 ONNX model (opset 13) initialized successfully!');
      
    } catch (e, stackTrace) {
      developer.log('❌ Error initializing ONNX model: $e');
      developer.log('📋 Stack trace: $stackTrace');
      developer.log('❌ Error initializing ONNX model: $e');
      developer.log('📋 Stack trace: $stackTrace');
      _isInitialized = false;
      _initError = e.toString();
      _initStatus = 'Initialization failed ❌';
      rethrow;
    }
  }

  // Test session with dummy input to verify opset 13 compatibility
  Future<void> _testSession() async {
    try {
      developer.log('🧪 Testing ONNX session with dummy input...');
      developer.log('🧪 Testing ONNX session with dummy input...');
      
      // Create dummy input tensor [1, 3, 640, 640] with proper values
      final dummyPixels = Float32List(1 * 3 * 640 * 640);
      for (int i = 0; i < dummyPixels.length; i++) {
        dummyPixels[i] = 0.5; // Fill with normalized values
      }
      
      final dummyTensor = OrtValueTensor.createTensorWithDataList(
        dummyPixels,
        [1, 3, 640, 640],
      );
      
      developer.log('📊 Created dummy tensor with shape [1, 3, 640, 640]');
      developer.log('📊 Created dummy tensor with shape [1, 3, 640, 640]');
      
      // Run inference with dummy input
      final inputs = {'images': dummyTensor};
      final runOptions = OrtRunOptions();
      
      developer.log('🔍 Running test inference...');
      developer.log('🔍 Running test inference...');
      final outputs = _session!.run(runOptions, inputs);
      
      developer.log('✅ Session test successful! Output count: ${outputs.length}');
      developer.log('✅ Session test successful! Output count: ${outputs.length}');
      
      // Clean up test tensors
      dummyTensor.release();
      runOptions.release();
      for (final output in outputs) {
        output?.release();
      }
      
    } catch (e, stackTrace) {
      developer.log('❌ Session test failed: $e');
      developer.log('📋 Stack trace: $stackTrace');
      developer.log('❌ Session test failed: $e');
      developer.log('📋 Stack trace: $stackTrace');
      throw Exception('Model compatibility test failed. This may indicate an issue with the opset 13 model: $e');
    }
  }

  Future<List<Detection>> runInference(String imagePath) async {
    developer.log('🔍 Starting inference for image: $imagePath');
    developer.log('🔍 Starting inference for image: $imagePath');
    
    if (!_isInitialized || _session == null) {
      developer.log('❌ Model not initialized');
      developer.log('❌ Model not initialized');
      throw Exception('Model not initialized. Please wait for initialization to complete.');
    }

    try {
      // Load and preprocess image
      final imageFile = File(imagePath);
      if (!await imageFile.exists()) {
        throw Exception('Image file not found: $imagePath');
      }
      
      final imageBytes = await imageFile.readAsBytes();
      final image = img.decodeImage(imageBytes);
      if (image == null) {
        throw Exception('Failed to decode image');
      }

      developer.log('🖼️ Image loaded: ${image.width}x${image.height}');
      developer.log('🖼️ Image loaded: ${image.width}x${image.height}');

      // Resize to 640x640 and convert to RGB
      final resized = img.copyResize(image, width: 640, height: 640);
      developer.log('📏 Image resized to 640x640');
      developer.log('📏 Image resized to 640x640');

      // Convert to float32 tensor [1, 3, 640, 640]
      final inputTensor = _imageToTensor(resized);
      developer.log('🔢 Image converted to tensor');
      developer.log('🔢 Image converted to tensor');

      // Run inference
      final inputs = {'images': inputTensor};
      final runOptions = OrtRunOptions();
      
      developer.log('🧠 Running inference...');
      developer.log('🧠 Running inference...');
      final outputs = _session!.run(runOptions, inputs);
      developer.log('✅ Inference completed successfully');
      developer.log('✅ Inference completed successfully');
      
      // Process outputs - YOLOv8 with opset 13
      List<Detection> detections = [];
      
      if (outputs.isNotEmpty && outputs[0] != null) {
        final outputTensor = outputs[0]!.value;
        developer.log('📊 Output tensor type: ${outputTensor.runtimeType}');
        developer.log('📊 Output tensor type: ${outputTensor.runtimeType}');
        
        // Handle YOLOv8 output format
        if (outputTensor is List<List<List<double>>>) {
          developer.log('📋 Processing YOLOv8 format: [batch, features, anchors]');
          developer.log('📋 Processing YOLOv8 format: [batch, features, anchors]');
          detections = _processYOLOv8Output(outputTensor, image.width, image.height);
        } else {
          developer.log('❓ Unexpected output format: ${outputTensor.runtimeType}');
          developer.log('❓ Unexpected output format: ${outputTensor.runtimeType}');
          detections = [];
        }
      } else {
        developer.log('❌ No outputs received from model');
        developer.log('❌ No outputs received from model');
        detections = [];
      }

      developer.log('🎯 Found ${detections.length} high-confidence detections');
      developer.log('🎯 Found ${detections.length} high-confidence detections');
      
      // Log each detection for debugging
      for (int i = 0; i < detections.length; i++) {
        final det = detections[i];
        developer.log('🎯 Detection $i: ${det.className} (${(det.confidence * 100).toStringAsFixed(1)}%) at [${det.x1.toStringAsFixed(1)}, ${det.y1.toStringAsFixed(1)}, ${det.x2.toStringAsFixed(1)}, ${det.y2.toStringAsFixed(1)}]');
        developer.log('🎯 Detection $i: ${det.className} (${(det.confidence * 100).toStringAsFixed(1)}%) at [${det.x1.toStringAsFixed(1)}, ${det.y1.toStringAsFixed(1)}, ${det.x2.toStringAsFixed(1)}, ${det.y2.toStringAsFixed(1)}]');
      }
      
      // Clean up tensors
      inputTensor.release();
      runOptions.release();
      for (final output in outputs) {
        output?.release();
      }
      
      return detections;
      
    } catch (e, stackTrace) {
      developer.log('❌ Error during inference: $e');
      developer.log('📋 Stack trace: $stackTrace');
      developer.log('❌ Error during inference: $e');
      developer.log('📋 Stack trace: $stackTrace');
      rethrow;
    }
  }

  OrtValueTensor _imageToTensor(img.Image image) {
    final pixels = Float32List(1 * 3 * 640 * 640);
    int index = 0;

    // Convert to CHW format (channels first) and normalize to [0, 1]
    for (int c = 0; c < 3; c++) {
      for (int y = 0; y < 640; y++) {
        for (int x = 0; x < 640; x++) {
          final pixel = image.getPixel(x, y);
          double value;
          switch (c) {
            case 0: // Red
              value = pixel.r / 255.0;
              break;
            case 1: // Green
              value = pixel.g / 255.0;
              break;
            case 2: // Blue
              value = pixel.b / 255.0;
              break;
            default:
              value = 0.0;
          }
          pixels[index++] = value;
        }
      }
    }

    return OrtValueTensor.createTensorWithDataList(
      pixels,
      [1, 3, 640, 640],
    );
  }

  List<Detection> _processYOLOv8Output(
    List<List<List<double>>> outputs,
    int originalWidth,
    int originalHeight,
  ) {
    developer.log('📋 YOLOv8 Output Analysis:');
    developer.log('📋 Batch size: ${outputs.length}');
    if (outputs.isNotEmpty) {
      developer.log('📋 Features: ${outputs[0].length}');
      if (outputs[0].isNotEmpty) {
        developer.log('📋 Anchors: ${outputs[0][0].length}');
      }
    }
    
    final detections = <Detection>[];
    
    // OPTIMIZED PARAMETERS for better precision (mAP@0.5 = 0.942)
    const double confidenceThreshold = 0.6; // Increased from 0.5 to 0.6 (60%)
    const double minBoxArea = 400.0; // Minimum bounding box area (20x20 pixels)
    const double maxBoxArea = 640.0 * 640.0 * 0.8; // Maximum 80% of image area
    const int maxDetections = 8; // Reduced from 10 for better quality
    const double aspectRatioMin = 0.2; // Minimum width/height ratio
    const double aspectRatioMax = 5.0; // Maximum width/height ratio
    
    // YOLOv8 format: [1, 7, 8400] where 7 = 4 (bbox) + 3 (classes)
    final batch = outputs[0]; // Get first batch
    final numFeatures = batch.length; // Should be 7
    final numAnchors = batch[0].length; // Should be 8400
    
    developer.log('📋 Processing $numAnchors anchors with $numFeatures features each');
    developer.log('📋 Using OPTIMIZED confidence threshold: $confidenceThreshold (60%)');
    developer.log('📋 Minimum box area: $minBoxArea pixels');
    developer.log('📋 Maximum detections: $maxDetections');
    
    // Store all potential detections with enhanced filtering
    final potentialDetections = <Map<String, dynamic>>[];
    
    // Track confidence distribution for debugging
    int lowConfidenceCount = 0;
    int mediumConfidenceCount = 0;
    int highConfidenceCount = 0;
    
    // Process each anchor point with enhanced filtering
    for (int anchor = 0; anchor < numAnchors; anchor++) {
      // Extract values for this anchor
      final xCenter = batch[0][anchor];
      final yCenter = batch[1][anchor];
      final width = batch[2][anchor];
      final height = batch[3][anchor];
      
      // Get class scores (features 4, 5, 6 for our 3 classes)
      final class0Score = batch[4][anchor];
      final class1Score = batch[5][anchor];
      final class2Score = batch[6][anchor];
      
      // Find the class with highest score
      double maxScore = class0Score;
      int classId = 0;
      
      if (class1Score > maxScore) {
        maxScore = class1Score;
        classId = 1;
      }
      
      if (class2Score > maxScore) {
        maxScore = class2Score;
        classId = 2;
      }
      
      // Apply sigmoid to get confidence (0-1)
      final confidence = 1.0 / (1.0 + math.exp(-maxScore));
      
      // Track confidence distribution
      if (confidence < 0.3) {
        lowConfidenceCount++;
      } else if (confidence < 0.6) {
        mediumConfidenceCount++;
      } else {
        highConfidenceCount++;
      }
      
      // ENHANCED FILTERING CONDITIONS
      if (confidence > confidenceThreshold && 
          classId >= 0 && 
          classId < _classNames.length &&
          width > 0 && height > 0 && // Valid dimensions
          xCenter > 0 && yCenter > 0 && // Valid coordinates
          xCenter < 640 && yCenter < 640) {
        
        // Convert from center format to corner format
        final x1 = xCenter - width / 2;
        final y1 = yCenter - height / 2;
        final x2 = xCenter + width / 2;
        final y2 = yCenter + height / 2;
        
        // Calculate bounding box area and aspect ratio
        final boxArea = width * height;
        final aspectRatio = width / height;
        
        // ADVANCED FILTERING: Size, aspect ratio, and position validation
        if (x2 > x1 && y2 > y1 && 
            x1 >= 0 && y1 >= 0 && x2 <= 640 && y2 <= 640 && // Within bounds
            boxArea >= minBoxArea && boxArea <= maxBoxArea && // Reasonable size
            aspectRatio >= aspectRatioMin && aspectRatio <= aspectRatioMax && // Reasonable shape
            width >= 15 && height >= 15) { // Minimum dimensions (increased from 10)
          
          potentialDetections.add({
            'x1': x1,
            'y1': y1,
            'x2': x2,
            'y2': y2,
            'confidence': confidence,
            'classId': classId,
            'anchor': anchor,
            'area': boxArea,
            'aspectRatio': aspectRatio,
          });
        }
      }
    }

    developer.log('📊 Confidence Distribution:');
    developer.log('📊 Low confidence (<30%): $lowConfidenceCount');
    developer.log('📊 Medium confidence (30-60%): $mediumConfidenceCount');
    developer.log('📊 High confidence (>60%): $highConfidenceCount');
    developer.log('📋 Found ${potentialDetections.length} potential detections above 60% threshold');
    
    // Sort by confidence (descending) and take top detections
    potentialDetections.sort((a, b) => (b['confidence'] as double).compareTo(a['confidence'] as double));
    
    // Apply additional quality filtering based on confidence distribution
    final qualityFiltered = <Map<String, dynamic>>[];
    for (final det in potentialDetections) {
      final conf = det['confidence'] as double;
      final area = det['area'] as double;
      
      // Additional quality checks for very high confidence detections
      if (conf >= 0.8) {
        // Very high confidence - accept with minimal additional filtering
        qualityFiltered.add(det);
      } else if (conf >= 0.7) {
        // High confidence - require reasonable size
        if (area >= 800) { // Larger minimum area for medium confidence
          qualityFiltered.add(det);
        }
      } else if (conf >= 0.6) {
        // Medium-high confidence - stricter requirements
        if (area >= 1200) { // Even larger minimum area
          qualityFiltered.add(det);
        }
      }
    }
    
    // Limit to maximum detections
    final limitedDetections = qualityFiltered.take(maxDetections).toList();
    developer.log('📋 Quality filtered to ${qualityFiltered.length} detections');
    developer.log('📋 Limited to top ${limitedDetections.length} detections');
    
    // Convert to Detection objects
    for (final det in limitedDetections) {
      final detection = _createDetection(
        det['x1'] as double,
        det['y1'] as double, 
        det['x2'] as double,
        det['y2'] as double,
        det['confidence'] as double,
        det['classId'] as int,
        originalWidth,
        originalHeight
      );
      detections.add(detection);
      developer.log('✅ Added HIGH-QUALITY detection: ${_classNames[det['classId'] as int]} with confidence ${((det['confidence'] as double) * 100).toStringAsFixed(1)}% (area: ${(det['area'] as double).toStringAsFixed(0)}px²)');
    }

    developer.log('📋 Before NMS: ${detections.length} detections');
    final result = _applyEnhancedNMS(detections, 0.25); // More aggressive NMS (reduced from 0.3)
    developer.log('📋 After Enhanced NMS: ${result.length} final detections');
    
    return result;
  }

  Detection _createDetection(
    double x1, double y1, double x2, double y2, 
    double confidence, int classId, 
    int originalWidth, int originalHeight
  ) {
    // Scale coordinates back to original image size
    final scaledX1 = (x1 / 640.0) * originalWidth;
    final scaledY1 = (y1 / 640.0) * originalHeight;
    final scaledX2 = (x2 / 640.0) * originalWidth;
    final scaledY2 = (y2 / 640.0) * originalHeight;

    return Detection(
      x1: scaledX1.clamp(0.0, originalWidth.toDouble()),
      y1: scaledY1.clamp(0.0, originalHeight.toDouble()),
      x2: scaledX2.clamp(0.0, originalWidth.toDouble()),
      y2: scaledY2.clamp(0.0, originalHeight.toDouble()),
      confidence: confidence,
      classId: classId,
      className: _classNames[classId],
    );
  }

  List<Detection> _applyEnhancedNMS(List<Detection> detections, double iouThreshold) {
    if (detections.isEmpty) return detections;
    
    // Sort by confidence (descending)
    detections.sort((a, b) => b.confidence.compareTo(a.confidence));

    final result = <Detection>[];
    final suppressed = List<bool>.filled(detections.length, false);

    for (int i = 0; i < detections.length; i++) {
      if (suppressed[i]) continue;

      result.add(detections[i]);

      for (int j = i + 1; j < detections.length; j++) {
        if (suppressed[j]) continue;

        final iou = _calculateIoU(detections[i], detections[j]);
        
        // Enhanced NMS: Also consider class-specific suppression
        if (iou > iouThreshold) {
          // Same class: suppress lower confidence detection
          if (detections[i].classId == detections[j].classId) {
            suppressed[j] = true;
          }
          // Different classes: only suppress if IoU is very high (>0.5)
          else if (iou > 0.5) {
            suppressed[j] = true;
          }
        }
      }
    }

    developer.log('📋 Enhanced NMS: Kept ${result.length} out of ${detections.length} detections');
    return result;
  }

  double _calculateIoU(Detection a, Detection b) {
    final intersectionX1 = a.x1 > b.x1 ? a.x1 : b.x1;
    final intersectionY1 = a.y1 > b.y1 ? a.y1 : b.y1;
    final intersectionX2 = a.x2 < b.x2 ? a.x2 : b.x2;
    final intersectionY2 = a.y2 < b.y2 ? a.y2 : b.y2;

    if (intersectionX2 <= intersectionX1 || intersectionY2 <= intersectionY1) {
      return 0.0;
    }

    final intersectionArea = (intersectionX2 - intersectionX1) * (intersectionY2 - intersectionY1);
    final areaA = (a.x2 - a.x1) * (a.y2 - a.y1);
    final areaB = (b.x2 - b.x1) * (b.y2 - b.y1);
    final unionArea = areaA + areaB - intersectionArea;

    return unionArea > 0 ? intersectionArea / unionArea : 0.0;
  }

  void dispose() {
    _session?.release();
    _session = null;
    _isInitialized = false;
    _initStatus = 'Disposed';
    developer.log('🗑️ ONNX session disposed');
    developer.log('🗑️ ONNX session disposed');
  }
}
