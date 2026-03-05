import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
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

/// Decode a file into a ui.Image
Future<ui.Image> _decodeImage(File file) async {
  final bytes = await file.readAsBytes();
  final codec = await ui.instantiateImageCodec(bytes);
  final frame = await codec.getNextFrame();
  return frame.image;
}

/// Encode a ui.Image to bytes using flutter_image_compress for quality control
Future<Uint8List> _encodeImage(
  ui.Image image,
  String format,
  int quality,
) async {
  final byteData = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
  if (byteData == null) throw Exception('Failed to read image pixel data');

  // Write raw RGBA to a temp PNG first, then compress with quality
  final tempDir = await getTemporaryDirectory();
  final rawPath = '${tempDir.path}/pf_raw_${DateTime.now().millisecondsSinceEpoch}.png';

  // Re-encode via flutter_image_compress from raw bytes
  final result = await FlutterImageCompress.compressWithList(
    byteData.buffer.asUint8List(),
    minWidth: image.width,
    minHeight: image.height,
    quality: quality,
    format: _formatToCompressFormat(format),
  );
  return result;
}

/// Core resize logic using dart:ui canvas
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
  final canvas = Canvas(recorder, Rect.fromLTWH(0, 0, dstW, dstH));

  switch (mode) {
    case ResizeFitMode.stretch:
      // Stretch to fill exactly — ignores aspect ratio
      canvas.drawImageRect(
        src,
        Rect.fromLTWH(0, 0, srcW, srcH),
        Rect.fromLTWH(0, 0, dstW, dstH),
        Paint(),
      );
      break;

    case ResizeFitMode.crop:
      // Scale up so image COVERS the target, then center-crop
      final scale = (dstW / srcW) > (dstH / srcH)
          ? dstW / srcW
          : dstH / srcH;
      final scaledW = srcW * scale;
      final scaledH = srcH * scale;
      final offsetX = (dstW - scaledW) / 2;
      final offsetY = (dstH - scaledH) / 2;
      canvas.drawImageRect(
        src,
        Rect.fromLTWH(0, 0, srcW, srcH),
        Rect.fromLTWH(offsetX, offsetY, scaledW, scaledH),
        Paint(),
      );
      break;

    case ResizeFitMode.fit:
      // Scale down so image FITS inside target, centered, transparent padding
      final scale = (dstW / srcW) < (dstH / srcH)
          ? dstW / srcW
          : dstH / srcH;
      final scaledW = srcW * scale;
      final scaledH = srcH * scale;
      final offsetX = (dstW - scaledW) / 2;
      final offsetY = (dstH - scaledH) / 2;
      canvas.drawImageRect(
        src,
        Rect.fromLTWH(0, 0, srcW, srcH),
        Rect.fromLTWH(offsetX, offsetY, scaledW, scaledH),
        Paint(),
      );
      break;

    case ResizeFitMode.background:
      // Same as fit but with a white background fill
      canvas.drawRect(
        Rect.fromLTWH(0, 0, dstW, dstH),
        Paint()..color = const Color(0xFFFFFFFF),
      );
      final scale = (dstW / srcW) < (dstH / srcH)
          ? dstW / srcW
          : dstH / srcH;
      final scaledW = srcW * scale;
      final scaledH = srcH * scale;
      final offsetX = (dstW - scaledW) / 2;
      final offsetY = (dstH - scaledH) / 2;
      canvas.drawImageRect(
        src,
        Rect.fromLTWH(0, 0, srcW, srcH),
        Rect.fromLTWH(offsetX, offsetY, scaledW, scaledH),
        Paint(),
      );
      break;
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
      // ---- Compress only: pass original dims to avoid any upscale/distortion ----
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
      // ---- Resize: use dart:ui canvas for pixel-perfect output ----
      final src = await _decodeImage(inputFile);

      // Resolve target dimensions
      int targetW = settings.width ?? originalWidth;
      int targetH = settings.height ?? originalHeight;

      if (settings.keepAspectRatio) {
        // Scale proportionally based on whichever axis was specified
        if (settings.width != null && settings.height == null) {
          targetH = (originalHeight * targetW / originalWidth).round();
        } else if (settings.height != null && settings.width == null) {
          targetW = (originalWidth * targetH / originalHeight).round();
        }
        // Both specified + keepAspectRatio: fit inside box
        else {
          final scaleW = targetW / originalWidth;
          final scaleH = targetH / originalHeight;
          final scale = scaleW < scaleH ? scaleW : scaleH;
          targetW = (originalWidth * scale).round();
          targetH = (originalHeight * scale).round();
        }
      }

      // Draw to canvas with chosen fit mode
      final resized = await _resizeCanvas(src, targetW, targetH, settings.fitMode);
      src.dispose();

      resultBytes = await _encodeImage(resized, settings.format, settings.quality);
      resized.dispose();
    }

    final outputFile = File(outputPath);
    await outputFile.writeAsBytes(resultBytes);

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
