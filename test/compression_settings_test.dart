import 'package:flutter_test/flutter_test.dart';
import 'package:image_resizer/core/models/compression_settings.dart';

void main() {
  group('CompressionSettings Tests', () {
    test('default settings', () {
      const settings = CompressionSettings();
      expect(settings.quality, 80);
      expect(settings.width, isNull);
      expect(settings.height, isNull);
      expect(settings.keepAspectRatio, isTrue);
      expect(settings.format, 'JPG');
      expect(settings.fitMode, ResizeFitMode.fit);
      expect(settings.targetSizeKB, isNull);
      expect(settings.resizePercentage, isNull);
      expect(settings.keepMetadata, isTrue);
    });

    test('copyWith keeps existing and updates fields', () {
      const settings = CompressionSettings(
        quality: 70,
        width: 100,
        height: 200,
        resizePercentage: 50,
        targetSizeKB: 500,
        keepMetadata: true,
      );

      final updated = settings.copyWith(quality: 90, keepMetadata: false);
      expect(updated.quality, 90);
      expect(updated.width, 100);
      expect(updated.height, 200);
      expect(updated.resizePercentage, 50);
      expect(updated.targetSizeKB, 500);
      expect(updated.keepMetadata, isFalse);
    });

    test('copyWith clears fields correctly', () {
      const settings = CompressionSettings(
        quality: 70,
        width: 100,
        height: 200,
        resizePercentage: 50,
        targetSizeKB: 500,
      );

      final updated = settings.copyWith(
        clearWidth: true,
        clearHeight: true,
        clearResizePercentage: true,
        clearTargetSizeKB: true,
      );

      expect(updated.width, isNull);
      expect(updated.height, isNull);
      expect(updated.resizePercentage, isNull);
      expect(updated.targetSizeKB, isNull);
      expect(updated.keepMetadata, isTrue);
    });
  });
}
