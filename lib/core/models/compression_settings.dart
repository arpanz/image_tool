class CompressionSettings {
  final int quality;
  final int? width;
  final int? height;
  final bool keepAspectRatio;
  final String format;

  const CompressionSettings({
    this.quality = 80,
    this.width,
    this.height,
    this.keepAspectRatio = true,
    this.format = 'JPG',
  });

  CompressionSettings copyWith({
    int? quality,
    int? width,
    int? height,
    bool? keepAspectRatio,
    String? format,
  }) {
    return CompressionSettings(
      quality: quality ?? this.quality,
      width: width ?? this.width,
      height: height ?? this.height,
      keepAspectRatio: keepAspectRatio ?? this.keepAspectRatio,
      format: format ?? this.format,
    );
  }
}
