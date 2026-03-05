class CompressionResult {
  final int originalSize;
  final int newSize;
  final double savedPercent;
  final String outputPath;
  final int outWidth;
  final int outHeight;

  const CompressionResult({
    required this.originalSize,
    required this.newSize,
    required this.savedPercent,
    required this.outputPath,
    this.outWidth = 0,
    this.outHeight = 0,
  });

  factory CompressionResult.fromSizes({
    required int originalSize,
    required int newSize,
    required String outputPath,
    int outWidth = 0,
    int outHeight = 0,
  }) {
    final saved = originalSize > 0
        ? ((originalSize - newSize) / originalSize * 100)
        : 0.0;
    return CompressionResult(
      originalSize: originalSize,
      newSize: newSize,
      savedPercent: saved,
      outputPath: outputPath,
      outWidth: outWidth,
      outHeight: outHeight,
    );
  }
}
