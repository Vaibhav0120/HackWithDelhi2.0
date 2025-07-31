import 'dart:io';
import 'dart:typed_data';
import 'dart:developer' as developer;
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:onnxruntime/onnxruntime.dart';
import 'package:path_provider/path_provider.dart';
import '../models/detection.dart';

class OnnxInference {
  OrtSession? _session;
  static const List<String> _classNames = [
    'FireExtinguisher',
    'ToolBox',
    'OxygenTank',
  ];

  Future<void> initialize() async {
    try {
      // Copy model from assets to temporary directory
      final modelData = await rootBundle.load('assets/best.onnx');
      final tempDir = await getTemporaryDirectory();
      final modelFile = File('${tempDir.path}/best.onnx');
      await modelFile.writeAsBytes(modelData.buffer.asUint8List());

      // Initialize ONNX Runtime session
      final sessionOptions = OrtSessionOptions();
      _session = OrtSession.fromFile(modelFile, sessionOptions);
    } catch (e) {
      developer.log('Error initializing ONNX model: $e');
      rethrow;
    }
  }

  Future<List<Detection>> runInference(String imagePath) async {
    if (_session == null) {
      throw Exception('Model not initialized');
    }

    try {
      // Load and preprocess image
      final imageBytes = await File(imagePath).readAsBytes();
      final image = img.decodeImage(imageBytes);
      if (image == null) {
        throw Exception('Failed to decode image');
      }

      // Resize to 640x640 and convert to RGB
      final resized = img.copyResize(image, width: 640, height: 640);
      final rgbImage = img.copyResize(resized, width: 640, height: 640);

      // Convert to float32 tensor [1, 3, 640, 640]
      final inputTensor = _imageToTensor(rgbImage);

      // Run inference
      final inputs = {'images': inputTensor};
      final outputs = _session!.run(OrtRunOptions(), inputs);
      
      // Process outputs
      final outputTensor = outputs[0]?.value as List<List<List<double>>>;
      final detections = _processOutputs(outputTensor, image.width, image.height);

      return detections;
    } catch (e) {
      developer.log('Error during inference: $e');
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

  List<Detection> _processOutputs(
    List<List<List<double>>> outputs,
    int originalWidth,
    int originalHeight,
  ) {
    final detections = <Detection>[];
    const double confidenceThreshold = 0.5;
    const double iouThreshold = 0.4;

    // Process each detection
    for (final detection in outputs[0]) {
      if (detection.length >= 6) {
        final x1 = detection[0];
        final y1 = detection[1];
        final x2 = detection[2];
        final y2 = detection[3];
        final confidence = detection[4];
        final classId = detection[5].toInt();

        if (confidence > confidenceThreshold && classId < _classNames.length) {
          // Scale coordinates back to original image size
          final scaledX1 = (x1 / 640.0) * originalWidth;
          final scaledY1 = (y1 / 640.0) * originalHeight;
          final scaledX2 = (x2 / 640.0) * originalWidth;
          final scaledY2 = (y2 / 640.0) * originalHeight;

          detections.add(Detection(
            x1: scaledX1,
            y1: scaledY1,
            x2: scaledX2,
            y2: scaledY2,
            confidence: confidence,
            classId: classId,
            className: _classNames[classId],
          ));
        }
      }
    }

    // Apply Non-Maximum Suppression
    return _applyNMS(detections, iouThreshold);
  }

  List<Detection> _applyNMS(List<Detection> detections, double iouThreshold) {
    // Sort by confidence (descending)
    detections.sort((a, b) => b.confidence.compareTo(a.confidence));

    final result = <Detection>[];
    final suppressed = <bool>[];

    for (int i = 0; i < detections.length; i++) {
      suppressed.add(false);
    }

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

    return intersectionArea / unionArea;
  }

  void dispose() {
    _session?.release();
    _session = null;
  }
}
