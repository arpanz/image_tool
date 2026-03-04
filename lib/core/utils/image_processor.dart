import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import '../models/compression_settings.dart';
import '../models/compression_result.dart';

/// Payload passed into the isolate via compute()
class _ProcessPayload {
  final String inputPath;
  final CompressionSettings settings;
  final String outputDir;

  const _ProcessPayload({
    required this.inputPath,
    required this.settings,
    required this.outputDir,
  });
}

/// Convert format string to file extension
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

/// Convert format string to CompressFormat enum
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

/// Top-level function required by compute() – runs in a background isolate.
Future<CompressionResult> _compressInIsolate(_ProcessPayload payload) async {
  final inputFile = File(payload.inputPath);
  if (!inputFile.existsSync()) {
    throw Exception('Source file not found: ${payload.inputPath}');
  }

  final originalSize = await inputFile.length();

  final ext = _formatToExt(payload.settings.format);
  final timestamp = DateTime.now().millisecondsSinceEpoch;
  final outputPath = '${payload.outputDir}/pf_$timestamp.$ext';

  final CompressFormat compressFormat = _formatToCompressFormat(
    payload.settings.format,
  );

  final Uint8List? result = await FlutterImageCompress.compressWithFile(
    payload.inputPath,
    quality: payload.settings.quality,
    minWidth: payload.settings.width ?? 1920,
    minHeight: payload.settings.height ?? 1080,
    keepExif: false,
    format: compressFormat,
  );

  if (result == null || result.isEmpty) {
    throw Exception('Compression returned empty result.');
  }

  final outputFile = File(outputPath);
  await outputFile.writeAsBytes(result);

  final newSize = result.length;

  return CompressionResult.fromSizes(
    originalSize: originalSize,
    newSize: newSize,
    outputPath: outputPath,
  );
}

class ImageProcessor {
  /// Runs image compression in a background isolate via compute().
  /// UI thread is never blocked.
  static Future<CompressionResult> process({
    required String inputPath,
    required CompressionSettings settings,
  }) async {
    final dir = await getTemporaryDirectory();
    final payload = _ProcessPayload(
      inputPath: inputPath,
      settings: settings,
      outputDir: dir.path,
    );

    return compute(_compressInIsolate, payload);
  }
}

String formatBytes(int bytes) {
  if (bytes < 1024) return '$bytes B';
  if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
  return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
}
