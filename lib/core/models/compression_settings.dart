enum ResizeFitMode { stretch, crop, fit, background }

class CompressionSettings {
  final int quality;
  final int? width;
  final int? height;
  final bool keepAspectRatio;
  final String format;
  final ResizeFitMode fitMode;
  final int? targetSizeKB;

  const CompressionSettings({
    this.quality = 80,
    this.width,
    this.height,
    this.keepAspectRatio = true,
    this.format = 'JPG',
    this.fitMode = ResizeFitMode.fit,
    this.targetSizeKB,
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
  }) {
    return CompressionSettings(
      quality: quality ?? this.quality,
      width: width ?? this.width,
      height: height ?? this.height,
      keepAspectRatio: keepAspectRatio ?? this.keepAspectRatio,
      format: format ?? this.format,
      fitMode: fitMode ?? this.fitMode,
      targetSizeKB:
          clearTargetSizeKB ? null : (targetSizeKB ?? this.targetSizeKB),
    );
  }
}
