import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';

import '../models/compression_result.dart';
import '../models/compression_settings.dart';

/// Convert format string to file extension.
String _formatToExt(String format) {
  switch (format.toUpperCase()) {
    case 'PNG':
      return 'png';
    case 'WEBP':
      return 'webp';
    default:
      return 'jpg';
  }
}

/// Convert format string to CompressFormat enum.
CompressFormat _formatToCompressFormat(String format) {
  switch (format.toUpperCase()) {
    case 'PNG':
      return CompressFormat.png;
    case 'WEBP':
      return CompressFormat.webp;
    default:
      return CompressFormat.jpeg;
  }
}

Future<CompressionResult> _compressFile({
  required String inputPath,
  required CompressionSettings settings,
  required String outputDir,
}) async {
  final inputFile = File(inputPath);
  if (!inputFile.existsSync()) {
    throw Exception('Source file not found: $inputPath');
  }

  final originalSize = await inputFile.length();

  final ext = _formatToExt(settings.format);
  final timestamp = DateTime.now().millisecondsSinceEpoch;
  final outputPath = '$outputDir/pf_$timestamp.$ext';

  final compressFormat = _formatToCompressFormat(settings.format);

  final Uint8List? result = await FlutterImageCompress.compressWithFile(
    inputPath,
    quality: settings.quality,
    minWidth: settings.width ?? 1920,
    minHeight: settings.height ?? 1080,
    keepExif: false,
    format: compressFormat,
  );

  if (result == null || result.isEmpty) {
    throw Exception('Compression returned empty result.');
  }

  final outputFile = File(outputPath);
  await outputFile.writeAsBytes(result);

  return CompressionResult.fromSizes(
    originalSize: originalSize,
    newSize: result.length,
    outputPath: outputPath,
  );
}

class ImageProcessor {
  /// Compress image using flutter_image_compress.
  /// Plugin calls should run on the main isolate.
  static Future<CompressionResult> process({
    required String inputPath,
    required CompressionSettings settings,
  }) async {
    final dir = await getTemporaryDirectory();
    return _compressFile(
      inputPath: inputPath,
      settings: settings,
      outputDir: dir.path,
    );
  }
}

String formatBytes(int bytes) {
  if (bytes < 1024) return '$bytes B';
  if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
  return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
}
