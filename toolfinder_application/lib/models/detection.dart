class Detection {
  final double x1;
  final double y1;
  final double x2;
  final double y2;
  final double confidence;
  final int classId;
  final String className;

  Detection({
    required this.x1,
    required this.y1,
    required this.x2,
    required this.y2,
    required this.confidence,
    required this.classId,
    required this.className,
  });

  double get width => x2 - x1;
  double get height => y2 - y1;
  double get centerX => x1 + width / 2;
  double get centerY => y1 + height / 2;

  @override
  String toString() {
    return 'Detection(class: $className, confidence: ${(confidence * 100).toStringAsFixed(1)}%, bbox: [${x1.toStringAsFixed(1)}, ${y1.toStringAsFixed(1)}, ${x2.toStringAsFixed(1)}, ${y2.toStringAsFixed(1)}])';
  }
}
