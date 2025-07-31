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
      print('🔄 ONNX model already initialized');
      developer.log('🔄 ONNX model already initialized');
      return;
    }

    try {
      print('🚀 Starting ONNX model initialization for opset 13...');
      developer.log('🚀 Starting ONNX model initialization for opset 13...');
      _initStatus = 'Loading model from assets...';
      _initError = null;
      
      // Load model from assets
      final modelData = await rootBundle.load('assets/best.onnx');
      print('📦 Model loaded from assets, size: ${modelData.lengthInBytes} bytes');
      developer.log('📦 Model loaded from assets, size: ${modelData.lengthInBytes} bytes');
      
      if (modelData.lengthInBytes == 0) {
        throw Exception('Model file is empty. Please ensure best.onnx is in the assets folder.');
      }
      
      _initStatus = 'Copying model to temporary directory...';
      
      // Copy model to temporary directory
      final tempDir = await getTemporaryDirectory();
      final modelFile = File('${tempDir.path}/best.onnx');
      await modelFile.writeAsBytes(modelData.buffer.asUint8List());
      
      print('📁 Model copied to: ${modelFile.path}');
      developer.log('📁 Model copied to: ${modelFile.path}');
      
      // Verify file exists and has content
      if (!await modelFile.exists()) {
        throw Exception('Model file was not created successfully');
      }
      
      final fileSize = await modelFile.length();
      if (fileSize == 0) {
        throw Exception('Model file is empty after copying');
      }
      
      print('✅ Model file verified, size: $fileSize bytes');
      developer.log('✅ Model file verified, size: $fileSize bytes');
      _initStatus = 'Creating ONNX session...';
      
      // Initialize ONNX Runtime session with basic options for opset 13
      final sessionOptions = OrtSessionOptions();
      
      // Set optimization level to basic for better compatibility with opset 13
      sessionOptions.setSessionGraphOptimizationLevel(GraphOptimizationLevel.ortEnableBasic);
      print('⚙️ Set basic graph optimization for opset 13');
      developer.log('⚙️ Set basic graph optimization for opset 13');
      
      // Create session
      print('🔧 Creating ONNX session...');
      developer.log('🔧 Creating ONNX session...');
      _session = OrtSession.fromFile(modelFile, sessionOptions);
      print('✅ ONNX session created successfully');
      developer.log('✅ ONNX session created successfully');
      
      _initStatus = 'Testing model compatibility...';
      
      // Test the session with a dummy input to verify it works
      await _testSession();
      
      _isInitialized = true;
      _initStatus = 'Model ready! ✅';
      print('🎉 ONNX model (opset 13) initialized successfully!');
      developer.log('🎉 ONNX model (opset 13) initialized successfully!');
      
    } catch (e, stackTrace) {
      print('❌ Error initializing ONNX model: $e');
      print('📋 Stack trace: $stackTrace');
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
      print('🧪 Testing ONNX session with dummy input...');
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
      
      print('📊 Created dummy tensor with shape [1, 3, 640, 640]');
      developer.log('📊 Created dummy tensor with shape [1, 3, 640, 640]');
      
      // Run inference with dummy input
      final inputs = {'images': dummyTensor};
      final runOptions = OrtRunOptions();
      
      print('🔍 Running test inference...');
      developer.log('🔍 Running test inference...');
      final outputs = _session!.run(runOptions, inputs);
      
      print('✅ Session test successful! Output count: ${outputs.length}');
      developer.log('✅ Session test successful! Output count: ${outputs.length}');
      
      // Log basic output info for debugging
      for (int i = 0; i < outputs.length; i++) {
        final output = outputs[i];
        if (output != null) {
          print('📈 Output $i: ${output.runtimeType}');
          developer.log('📈 Output $i: ${output.runtimeType}');
          
          // Try to get more info about the output
          try {
            final value = output.value;
            print('📊 Output $i value type: ${value.runtimeType}');
            developer.log('📊 Output $i value type: ${value.runtimeType}');
            
            if (value is List) {
              print('📊 Output $i is List with length: ${value.length}');
              developer.log('📊 Output $i is List with length: ${value.length}');
            }
          } catch (e) {
            print('⚠️ Could not get output value info: $e');
            developer.log('⚠️ Could not get output value info: $e');
          }
        }
      }
      
      // Clean up test tensors
      dummyTensor.release();
      runOptions.release();
      for (final output in outputs) {
        output?.release();
      }
      
    } catch (e, stackTrace) {
      print('❌ Session test failed: $e');
      print('📋 Stack trace: $stackTrace');
      developer.log('❌ Session test failed: $e');
      developer.log('📋 Stack trace: $stackTrace');
      throw Exception('Model compatibility test failed. This may indicate an issue with the opset 13 model: $e');
    }
  }

  Future<List<Detection>> runInference(String imagePath) async {
    print('🔍 Starting inference for image: $imagePath');
    developer.log('🔍 Starting inference for image: $imagePath');
    
    if (!_isInitialized || _session == null) {
      print('❌ Model not initialized');
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

      print('🖼️ Image loaded: ${image.width}x${image.height}');
      developer.log('🖼️ Image loaded: ${image.width}x${image.height}');

      // Resize to 640x640 and convert to RGB
      final resized = img.copyResize(image, width: 640, height: 640);
      print('📏 Image resized to 640x640');
      developer.log('📏 Image resized to 640x640');

      // Convert to float32 tensor [1, 3, 640, 640]
      final inputTensor = _imageToTensor(resized);
      print('🔢 Image converted to tensor');
      developer.log('🔢 Image converted to tensor');

      // Run inference
      final inputs = {'images': inputTensor};
      final runOptions = OrtRunOptions();
      
      print('🧠 Running inference...');
      developer.log('🧠 Running inference...');
      final outputs = _session!.run(runOptions, inputs);
      print('✅ Inference completed successfully');
      developer.log('✅ Inference completed successfully');
      
      // Process outputs - YOLOv8 with opset 13
      List<Detection> detections = [];
      
      if (outputs.isNotEmpty && outputs[0] != null) {
        final outputTensor = outputs[0]!.value;
        print('📊 Output tensor type: ${outputTensor.runtimeType}');
        developer.log('📊 Output tensor type: ${outputTensor.runtimeType}');
        
        // Handle YOLOv8 output format
        if (outputTensor is List<List<List<double>>>) {
          print('📋 Processing YOLOv8 format: [batch, features, anchors]');
          developer.log('📋 Processing YOLOv8 format: [batch, features, anchors]');
          detections = _processYOLOv8Output(outputTensor, image.width, image.height);
        } else {
          print('❓ Unexpected output format: ${outputTensor.runtimeType}');
          developer.log('❓ Unexpected output format: ${outputTensor.runtimeType}');
          detections = [];
        }
      } else {
        print('❌ No outputs received from model');
        developer.log('❌ No outputs received from model');
        detections = [];
      }

      print('🎯 Found ${detections.length} detections');
      developer.log('🎯 Found ${detections.length} detections');
      
      // Log each detection for debugging
      for (int i = 0; i < detections.length; i++) {
        final det = detections[i];
        print('🎯 Detection $i: ${det.className} (${(det.confidence * 100).toStringAsFixed(1)}%) at [${det.x1.toStringAsFixed(1)}, ${det.y1.toStringAsFixed(1)}, ${det.x2.toStringAsFixed(1)}, ${det.y2.toStringAsFixed(1)}]');
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
      print('❌ Error during inference: $e');
      print('📋 Stack trace: $stackTrace');
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
  print('📋 YOLOv8 Output Analysis:');
  print('📋 Batch size: ${outputs.length}');
  if (outputs.isNotEmpty) {
    print('📋 Features: ${outputs[0].length}');
    if (outputs[0].isNotEmpty) {
      print('📋 Anchors: ${outputs[0][0].length}');
    }
  }
  
  final detections = <Detection>[];
  const double confidenceThreshold = 0.5; // Increased confidence threshold
  const int maxDetections = 10; // Limit maximum detections
  
  // YOLOv8 format: [1, 7, 8400] where 7 = 4 (bbox) + 3 (classes)
  final batch = outputs[0]; // Get first batch
  final numFeatures = batch.length; // Should be 7
  final numAnchors = batch[0].length; // Should be 8400
  
  print('📋 Processing $numAnchors anchors with $numFeatures features each');
  print('📋 Using confidence threshold: $confidenceThreshold');
  
  // Store all potential detections with their confidence
  final potentialDetections = <Map<String, dynamic>>[];
  
  // Process each anchor point
  for (int anchor = 0; anchor < numAnchors; anchor++) {
    // Extract values for this anchor
    final x_center = batch[0][anchor];
    final y_center = batch[1][anchor];
    final width = batch[2][anchor];
    final height = batch[3][anchor];
    
    // Get class scores (features 4, 5, 6 for our 3 classes)
    final class0_score = batch[4][anchor];
    final class1_score = batch[5][anchor];
    final class2_score = batch[6][anchor];
    
    // Find the class with highest score
    double maxScore = class0_score;
    int classId = 0;
    
    if (class1_score > maxScore) {
      maxScore = class1_score;
      classId = 1;
    }
    
    if (class2_score > maxScore) {
      maxScore = class2_score;
      classId = 2;
    }
    
    // Apply sigmoid to get confidence (0-1)
    final confidence = 1.0 / (1.0 + math.exp(-maxScore));
    
    // Only process high-confidence detections
    if (confidence > confidenceThreshold && 
        classId >= 0 && 
        classId < _classNames.length &&
        width > 10 && height > 10 && // Minimum size filter
        x_center > 0 && y_center > 0 && // Valid coordinates
        x_center < 640 && y_center < 640) {
      
      // Convert from center format to corner format
      final x1 = x_center - width / 2;
      final y1 = y_center - height / 2;
      final x2 = x_center + width / 2;
      final y2 = y_center + height / 2;
      
      // Ensure valid bounding box
      if (x2 > x1 && y2 > y1 && 
          x1 >= 0 && y1 >= 0 && x2 <= 640 && y2 <= 640) {
        
        potentialDetections.add({
          'x1': x1,
          'y1': y1,
          'x2': x2,
          'y2': y2,
          'confidence': confidence,
          'classId': classId,
          'anchor': anchor,
        });
      }
    }
  }

  print('📋 Found ${potentialDetections.length} potential detections above threshold');
  
  // Sort by confidence (descending) and take top detections
  potentialDetections.sort((a, b) => (b['confidence'] as double).compareTo(a['confidence'] as double));
  
  // Limit to maximum detections
  final limitedDetections = potentialDetections.take(maxDetections).toList();
  print('📋 Limited to top ${limitedDetections.length} detections');
  
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
    print('✅ Added detection: ${_classNames[det['classId'] as int]} with confidence ${((det['confidence'] as double) * 100).toStringAsFixed(1)}% (anchor ${det['anchor']})');
  }

  print('📋 Before NMS: ${detections.length} detections');
  final result = _applyNMS(detections, 0.3); // More aggressive NMS
  print('📋 After NMS: ${result.length} final detections');
  
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

  List<Detection> _applyNMS(List<Detection> detections, double iouThreshold) {
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
        if (iou > iouThreshold) {
          suppressed[j] = true;
        }
      }
    }

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
    print('🗑️ ONNX session disposed');
    developer.log('🗑️ ONNX session disposed');
  }
}
