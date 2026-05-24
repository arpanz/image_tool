class HistoryEntry {
  final String id;
  final int timestamp;
  final int originalSize;
  final int newSize;
  final double savedPercent;
  final String outputPath;
  final int width;
  final int height;
  final String mode; // 'compress', 'resize', 'convert'

  const HistoryEntry({
    required this.id,
    required this.timestamp,
    required this.originalSize,
    required this.newSize,
    required this.savedPercent,
    required this.outputPath,
    required this.width,
    required this.height,
    required this.mode,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'timestamp': timestamp,
      'originalSize': originalSize,
      'newSize': newSize,
      'savedPercent': savedPercent,
      'outputPath': outputPath,
      'width': width,
      'height': height,
      'mode': mode,
    };
  }

  factory HistoryEntry.fromJson(Map<dynamic, dynamic> json) {
    return HistoryEntry(
      id: json['id'] as String,
      timestamp: json['timestamp'] as int,
      originalSize: json['originalSize'] as int,
      newSize: json['newSize'] as int,
      savedPercent: (json['savedPercent'] as num).toDouble(),
      outputPath: json['outputPath'] as String,
      width: json['width'] as int,
      height: json['height'] as int,
      mode: json['mode'] as String,
    );
  }
}
