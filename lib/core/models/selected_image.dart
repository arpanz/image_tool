class SelectedImage {
  final String path;
  final int originalSize;
  final int width;
  final int height;

  const SelectedImage({
    required this.path,
    required this.originalSize,
    required this.width,
    required this.height,
  });

  SelectedImage copyWith({
    String? path,
    int? originalSize,
    int? width,
    int? height,
  }) {
    return SelectedImage(
      path: path ?? this.path,
      originalSize: originalSize ?? this.originalSize,
      width: width ?? this.width,
      height: height ?? this.height,
    );
  }
}
