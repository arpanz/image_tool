enum ResizeFitMode { stretch, crop, fit, background }

class CompressionSettings {
  final int quality;
  final int? width;
  final int? height;
  final bool keepAspectRatio;
  final String format;
  final ResizeFitMode fitMode;
  final int? targetSizeKB;
  final int? resizePercentage;

  const CompressionSettings({
    this.quality = 80,
    this.width,
    this.height,
    this.keepAspectRatio = true,
    this.format = 'JPG',
    this.fitMode = ResizeFitMode.fit,
    this.targetSizeKB,
    this.resizePercentage,
  });

  CompressionSettings copyWith({
    int? quality,
    int? width,
    int? height,
    bool? keepAspectRatio,
    String? format,
    ResizeFitMode? fitMode,
    int? targetSizeKB,
    bool clearTargetSizeKB = false,
    int? resizePercentage,
    bool clearResizePercentage = false,
    bool clearWidth = false,
    bool clearHeight = false,
  }) {
    return CompressionSettings(
      quality: quality ?? this.quality,
      width: clearWidth ? null : (width ?? this.width),
      height: clearHeight ? null : (height ?? this.height),
      keepAspectRatio: keepAspectRatio ?? this.keepAspectRatio,
      format: format ?? this.format,
      fitMode: fitMode ?? this.fitMode,
      targetSizeKB:
          clearTargetSizeKB ? null : (targetSizeKB ?? this.targetSizeKB),
      resizePercentage:
          clearResizePercentage ? null : (resizePercentage ?? this.resizePercentage),
    );
  }
}
