class CompressionResult {
  final int originalSize;
  final int newSize;
  final double savedPercent;
  final String outputPath;

  const CompressionResult({
    required this.originalSize,
    required this.newSize,
    required this.savedPercent,
    required this.outputPath,
  });

  factory CompressionResult.fromSizes({
    required int originalSize,
    required int newSize,
    required String outputPath,
  }) {
    final saved = originalSize > 0
        ? ((originalSize - newSize) / originalSize * 100)
        : 0.0;
    return CompressionResult(
      originalSize: originalSize,
      newSize: newSize,
      savedPercent: saved.clamp(0.0, 100.0),
      outputPath: outputPath,
    );
  }
}
