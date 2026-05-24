class HistoryEntry {
  final String id;
  final int timestamp;
  final int originalSize;
  final int newSize;
  final double savedPercent;
  final String outputPath;
  final int width;
  final int height;
  final int originalWidth;
  final int originalHeight;
  final String originalFormat;
  final String newFormat;
  final String mode;
  final bool isBatch;
  final List<Map<String, dynamic>>? batchItems;

  const HistoryEntry({
    required this.id,
    required this.timestamp,
    required this.originalSize,
    required this.newSize,
    required this.savedPercent,
    required this.outputPath,
    required this.width,
    required this.height,
    this.originalWidth = 0,
    this.originalHeight = 0,
    this.originalFormat = '',
    this.newFormat = '',
    required this.mode,
    this.isBatch = false,
    this.batchItems,
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
      'originalWidth': originalWidth,
      'originalHeight': originalHeight,
      'originalFormat': originalFormat,
      'newFormat': newFormat,
      'mode': mode,
      'isBatch': isBatch,
      'batchItems': batchItems,
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
      originalWidth: json['originalWidth'] != null ? json['originalWidth'] as int : 0,
      originalHeight: json['originalHeight'] != null ? json['originalHeight'] as int : 0,
      originalFormat: json['originalFormat'] != null ? json['originalFormat'] as String : '',
      newFormat: json['newFormat'] != null ? json['newFormat'] as String : '',
      mode: json['mode'] as String,
      isBatch: json['isBatch'] != null ? json['isBatch'] as bool : false,
      batchItems: json['batchItems'] != null
          ? (json['batchItems'] as List).map((e) => Map<String, dynamic>.from(e as Map)).toList()
          : null,
    );
  }
}
