import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:heif_converter/heif_converter.dart';

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

/// Encodes an already-resized [ui.Image] canvas into the target format/quality.
///
/// IMPORTANT: minWidth/minHeight must match the canvas dimensions so that
/// flutter_image_compress preserves the exact pixel size. Passing 0 causes the
/// library to ignore or miscalculate scaling, effectively undoing the resize.
Future<Uint8List> _encodeImage(
  ui.Image image,
  String format,
  int quality,
) async {
  final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
  if (byteData == null) throw Exception('Failed to encode canvas to PNG');
  final pngBytes = byteData.buffer.asUint8List();
  return FlutterImageCompress.compressWithList(
    pngBytes,
    minWidth: image.width,
    minHeight: image.height,
    quality: quality,
    format: _formatToCompressFormat(format),
  );
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
      canvas.drawImageRect(
        src,
        ui.Rect.fromLTWH(0, 0, srcW, srcH),
        ui.Rect.fromLTWH(
            (dstW - scaledW) / 2, (dstH - scaledH) / 2, scaledW, scaledH),
        ui.Paint(),
      );
    case ResizeFitMode.fit:
      final scale = (dstW / srcW) < (dstH / srcH) ? dstW / srcW : dstH / srcH;
      final scaledW = srcW * scale;
      final scaledH = srcH * scale;
      canvas.drawImageRect(
        src,
        ui.Rect.fromLTWH(0, 0, srcW, srcH),
        ui.Rect.fromLTWH(
            (dstW - scaledW) / 2, (dstH - scaledH) / 2, scaledW, scaledH),
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
      canvas.drawImageRect(
        src,
        ui.Rect.fromLTWH(0, 0, srcW, srcH),
        ui.Rect.fromLTWH(
            (dstW - scaledW) / 2, (dstH - scaledH) / 2, scaledW, scaledH),
        ui.Paint(),
      );
  }

  return recorder.endRecording().toImage(targetW, targetH);
}

bool _isHeic(String path) {
  final lower = path.toLowerCase();
  return lower.endsWith('.heic') || lower.endsWith('.heif');
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
    String activeInputPath = inputPath;
    int activeOriginalWidth = originalWidth;
    int activeOriginalHeight = originalHeight;
    String? tempConvertedPath;

    try {
      if (_isHeic(inputPath)) {
        final targetFormat =
            settings.format.toLowerCase() == 'png' ? 'png' : 'jpg';
        final converted =
            await HeifConverter.convert(inputPath, format: targetFormat);
        if (converted == null) {
          throw Exception('Failed to convert HEIC/HEIF image.');
        }
        tempConvertedPath = converted;
        activeInputPath = converted;

        try {
          final decoded = await _decodeImage(File(converted));
          activeOriginalWidth = decoded.width;
          activeOriginalHeight = decoded.height;
          decoded.dispose();
        } catch (_) {}
      }

      final ext = _formatToExt(settings.format);
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final dir = await getTemporaryDirectory();
      final outputPath = '${dir.path}/pf_$timestamp.$ext';

      final bool hasResize = settings.width != null ||
          settings.height != null ||
          settings.resizePercentage != null;
      Uint8List resultBytes;
      int outW = activeOriginalWidth;
      int outH = activeOriginalHeight;

      if (!hasResize) {
        // Pure compression — no canvas resize needed
        final compressed = await FlutterImageCompress.compressWithFile(
          activeInputPath,
          quality: settings.quality,
          minWidth: activeOriginalWidth,
          minHeight: activeOriginalHeight,
          keepExif: false,
          format: _formatToCompressFormat(settings.format),
        );
        if (compressed == null || compressed.isEmpty) {
          throw Exception('Compression returned empty result.');
        }
        resultBytes = compressed;
      } else {
        final src = await _decodeImage(File(activeInputPath));

        int targetW = settings.width ?? activeOriginalWidth;
        int targetH = settings.height ?? activeOriginalHeight;

        if (settings.resizePercentage != null) {
          final pct = settings.resizePercentage! / 100.0;
          targetW = (activeOriginalWidth * pct).round();
          targetH = (activeOriginalHeight * pct).round();
        } else if (settings.keepAspectRatio) {
          if (settings.width != null && settings.height == null) {
            targetH =
                (activeOriginalHeight * targetW / activeOriginalWidth).round();
          } else if (settings.height != null && settings.width == null) {
            targetW =
                (activeOriginalWidth * targetH / activeOriginalHeight).round();
          } else {
            // Both provided — fit inside the box without cropping
            final scale = (targetW / activeOriginalWidth) <
                    (targetH / activeOriginalHeight)
                ? targetW / activeOriginalWidth
                : targetH / activeOriginalHeight;
            targetW = (activeOriginalWidth * scale).round();
            targetH = (activeOriginalHeight * scale).round();
          }
        }

        outW = targetW;
        outH = targetH;

        final resized =
            await _resizeCanvas(src, targetW, targetH, settings.fitMode);
        src.dispose();
        // _encodeImage uses minWidth/minHeight = 0 — no upscaling risk
        resultBytes =
            await _encodeImage(resized, settings.format, settings.quality);
        resized.dispose();
      }

      // ── Target-size binary search ──────────────────────────────────────────
      if (settings.targetSizeKB != null &&
          settings.format.toUpperCase() != 'PNG') {
        final targetBytes = settings.targetSizeKB! * 1024;
        if (resultBytes.length > targetBytes) {
          int lo = 1;
          int hi = settings.quality;
          Uint8List? bestUnder;
          int bestQuality = 1;

          while (lo <= hi) {
            final mid = (lo + hi) ~/ 2;
            Uint8List attempt;
            if (!hasResize) {
              final c = await FlutterImageCompress.compressWithFile(
                activeInputPath,
                quality: mid,
                minWidth: activeOriginalWidth,
                minHeight: activeOriginalHeight,
                keepExif: false,
                format: _formatToCompressFormat(settings.format),
              );
              if (c == null || c.isEmpty) break;
              attempt = c;
            } else {
              final src = await _decodeImage(File(activeInputPath));
              final resized =
                  await _resizeCanvas(src, outW, outH, settings.fitMode);
              src.dispose();
              attempt = await _encodeImage(resized, settings.format, mid);
              resized.dispose();
            }

            if (attempt.length <= targetBytes) {
              bestUnder = attempt;
              bestQuality = mid;
              lo = mid + 1;
            } else {
              hi = mid - 1;
            }
          }

          if (bestUnder != null) {
            resultBytes = bestUnder;
          } else {
            // Even quality=1 too large — progressively downscale dimensions
            int scaleW = outW;
            int scaleH = outH;
            Uint8List scaled = resultBytes;
            for (double factor = 0.9; factor >= 0.1; factor -= 0.1) {
              scaleW = (outW * factor).round().clamp(1, outW);
              scaleH = (outH * factor).round().clamp(1, outH);
              final src = await _decodeImage(File(activeInputPath));
              final resized =
                  await _resizeCanvas(src, scaleW, scaleH, settings.fitMode);
              src.dispose();
              scaled =
                  await _encodeImage(resized, settings.format, bestQuality);
              resized.dispose();
              if (scaled.length <= targetBytes) break;
            }
            resultBytes = scaled;
            outW = scaleW;
            outH = scaleH;
          }
        }
      }

      await File(outputPath).writeAsBytes(resultBytes);

      return CompressionResult.fromSizes(
        originalSize: originalSize,
        newSize: resultBytes.length,
        outputPath: outputPath,
        outWidth: outW,
        outHeight: outH,
      );
    } finally {
      if (tempConvertedPath != null) {
        try {
          final f = File(tempConvertedPath);
          if (f.existsSync()) {
            await f.delete();
          }
        } catch (_) {}
      }
    }
  }
}

String formatBytes(int bytes) {
  if (bytes < 1024) return '$bytes B';
  if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
  return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
}
