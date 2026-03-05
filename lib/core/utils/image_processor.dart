import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';

import '../models/compression_result.dart';
import '../models/compression_settings.dart';

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

Future<ui.Image> _decodeImage(File file) async {
  final bytes = await file.readAsBytes();
  final codec = await ui.instantiateImageCodec(bytes);
  final frame = await codec.getNextFrame();
  return frame.image;
}

/// Encode a ui.Image to compressed bytes via PNG intermediate
Future<Uint8List> _encodeImage(
  ui.Image image,
  String format,
  int quality,
) async {
  // Export as raw PNG from canvas first
  final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
  if (byteData == null) throw Exception('Failed to encode canvas to PNG');
  final pngBytes = byteData.buffer.asUint8List();

  // Re-compress to target format + quality
  final result = await FlutterImageCompress.compressWithList(
    pngBytes,
    minWidth: image.width,
    minHeight: image.height,
    quality: quality,
    format: _formatToCompressFormat(format),
  );
  return result;
}

Future<ui.Image> _resizeCanvas(
  ui.Image src,
  int targetW,
  int targetH,
  ResizeFitMode mode,
) async {
  final srcW = src.width.toDouble();
  final srcH = src.height.toDouble();
  final dstW = targetW.toDouble();
  final dstH = targetH.toDouble();

  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder, ui.Rect.fromLTWH(0, 0, dstW, dstH));

  switch (mode) {
    case ResizeFitMode.stretch:
      canvas.drawImageRect(
        src,
        ui.Rect.fromLTWH(0, 0, srcW, srcH),
        ui.Rect.fromLTWH(0, 0, dstW, dstH),
        ui.Paint(),
      );

    case ResizeFitMode.crop:
      final scale = (dstW / srcW) > (dstH / srcH) ? dstW / srcW : dstH / srcH;
      final scaledW = srcW * scale;
      final scaledH = srcH * scale;
      final offsetX = (dstW - scaledW) / 2;
      final offsetY = (dstH - scaledH) / 2;
      canvas.drawImageRect(
        src,
        ui.Rect.fromLTWH(0, 0, srcW, srcH),
        ui.Rect.fromLTWH(offsetX, offsetY, scaledW, scaledH),
        ui.Paint(),
      );

    case ResizeFitMode.fit:
      final scale = (dstW / srcW) < (dstH / srcH) ? dstW / srcW : dstH / srcH;
      final scaledW = srcW * scale;
      final scaledH = srcH * scale;
      final offsetX = (dstW - scaledW) / 2;
      final offsetY = (dstH - scaledH) / 2;
      canvas.drawImageRect(
        src,
        ui.Rect.fromLTWH(0, 0, srcW, srcH),
        ui.Rect.fromLTWH(offsetX, offsetY, scaledW, scaledH),
        ui.Paint(),
      );

    case ResizeFitMode.background:
      canvas.drawRect(
        ui.Rect.fromLTWH(0, 0, dstW, dstH),
        ui.Paint()..color = const ui.Color(0xFFFFFFFF),
      );
      final scale = (dstW / srcW) < (dstH / srcH) ? dstW / srcW : dstH / srcH;
      final scaledW = srcW * scale;
      final scaledH = srcH * scale;
      final offsetX = (dstW - scaledW) / 2;
      final offsetY = (dstH - scaledH) / 2;
      canvas.drawImageRect(
        src,
        ui.Rect.fromLTWH(0, 0, srcW, srcH),
        ui.Rect.fromLTWH(offsetX, offsetY, scaledW, scaledH),
        ui.Paint(),
      );
  }

  final picture = recorder.endRecording();
  return picture.toImage(targetW, targetH);
}

class ImageProcessor {
  static Future<CompressionResult> process({
    required String inputPath,
    required CompressionSettings settings,
    required int originalWidth,
    required int originalHeight,
  }) async {
    final inputFile = File(inputPath);
    if (!inputFile.existsSync()) {
      throw Exception('Source file not found: $inputPath');
    }

    final originalSize = await inputFile.length();
    final ext = _formatToExt(settings.format);
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final dir = await getTemporaryDirectory();
    final outputPath = '${dir.path}/pf_$timestamp.$ext';

    final bool hasResize = settings.width != null || settings.height != null;
    Uint8List resultBytes;

    if (!hasResize) {
      // Compress only — pass original dims to prevent any upscale
      final compressed = await FlutterImageCompress.compressWithFile(
        inputPath,
        quality: settings.quality,
        minWidth: originalWidth,
        minHeight: originalHeight,
        keepExif: false,
        format: _formatToCompressFormat(settings.format),
      );
      if (compressed == null || compressed.isEmpty) {
        throw Exception('Compression returned empty result.');
      }
      resultBytes = compressed;
    } else {
      // Resize — pixel-perfect via dart:ui canvas
      final src = await _decodeImage(inputFile);

      int targetW = settings.width ?? originalWidth;
      int targetH = settings.height ?? originalHeight;

      if (settings.keepAspectRatio) {
        if (settings.width != null && settings.height == null) {
          targetH = (originalHeight * targetW / originalWidth).round();
        } else if (settings.height != null && settings.width == null) {
          targetW = (originalWidth * targetH / originalHeight).round();
        } else {
          final scaleW = targetW / originalWidth;
          final scaleH = targetH / originalHeight;
          final scale = scaleW < scaleH ? scaleW : scaleH;
          targetW = (originalWidth * scale).round();
          targetH = (originalHeight * scale).round();
        }
      }

      final resized = await _resizeCanvas(src, targetW, targetH, settings.fitMode);
      src.dispose();
      resultBytes = await _encodeImage(resized, settings.format, settings.quality);
      resized.dispose();
    }

    await File(outputPath).writeAsBytes(resultBytes);

    return CompressionResult.fromSizes(
      originalSize: originalSize,
      newSize: resultBytes.length,
      outputPath: outputPath,
    );
  }
}

String formatBytes(int bytes) {
  if (bytes < 1024) return '$bytes B';
  if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
  return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
}
