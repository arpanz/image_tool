import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:heif_converter/heif_converter.dart';
import '../../core/models/selected_image.dart';

sealed class PickerState {}

class PickerIdle extends PickerState {}

class PickerLoading extends PickerState {}

class PickerLoaded extends PickerState {
  final SelectedImage image;
  PickerLoaded(this.image);
}

class PickerError extends PickerState {
  final String message;
  PickerError(this.message);
}

class PickerNotifier extends Notifier<PickerState> {
  @override
  PickerState build() => PickerIdle();

  Future<void> pickImage() async {
    state = PickerLoading();
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(source: ImageSource.gallery);
      if (picked == null) {
        state = PickerIdle();
        return;
      }

      final file = File(picked.path);
      final bytes = await file.length();

      // Decode image to get width/height
      int w = 0, h = 0;
      final pathLower = picked.path.toLowerCase();
      final isHeic = pathLower.endsWith('.heic') || pathLower.endsWith('.heif');

      if (isHeic) {
        try {
          final tempJpg =
              await HeifConverter.convert(picked.path, format: 'jpg');
          if (tempJpg != null) {
            final tempFile = File(tempJpg);
            final data = await tempFile.readAsBytes();
            final codec = await ui.instantiateImageCodec(data);
            final frame = await codec.getNextFrame();
            w = frame.image.width;
            h = frame.image.height;
            frame.image.dispose();
            if (tempFile.existsSync()) {
              await tempFile.delete();
            }
          }
        } catch (_) {}
      } else {
        try {
          final data = await file.readAsBytes();
          final codec = await ui.instantiateImageCodec(data);
          final frame = await codec.getNextFrame();
          w = frame.image.width;
          h = frame.image.height;
          frame.image.dispose();
        } catch (_) {}
      }

      state = PickerLoaded(
        SelectedImage(
          path: picked.path,
          originalSize: bytes,
          width: w,
          height: h,
        ),
      );
    } catch (e) {
      state = PickerError('Could not load image: $e');
    }
  }

  Future<void> pickImageWithFilePicker() async {
    state = PickerLoading();
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'webp', 'heic', 'heif'],
      );
      if (result == null ||
          result.files.isEmpty ||
          result.files.first.path == null) {
        state = PickerIdle();
        return;
      }

      final pickedPath = result.files.first.path!;
      final file = File(pickedPath);
      final bytes = await file.length();

      // Decode image to get width/height
      int w = 0, h = 0;
      final pathLower = pickedPath.toLowerCase();
      final isHeic = pathLower.endsWith('.heic') || pathLower.endsWith('.heif');

      if (isHeic) {
        try {
          final tempJpg =
              await HeifConverter.convert(pickedPath, format: 'jpg');
          if (tempJpg != null) {
            final tempFile = File(tempJpg);
            final data = await tempFile.readAsBytes();
            final codec = await ui.instantiateImageCodec(data);
            final frame = await codec.getNextFrame();
            w = frame.image.width;
            h = frame.image.height;
            frame.image.dispose();
            if (tempFile.existsSync()) {
              await tempFile.delete();
            }
          }
        } catch (_) {}
      } else {
        try {
          final data = await file.readAsBytes();
          final codec = await ui.instantiateImageCodec(data);
          final frame = await codec.getNextFrame();
          w = frame.image.width;
          h = frame.image.height;
          frame.image.dispose();
        } catch (_) {}
      }

      state = PickerLoaded(
        SelectedImage(
          path: pickedPath,
          originalSize: bytes,
          width: w,
          height: h,
        ),
      );
    } catch (e) {
      state = PickerError('Could not load image: $e');
    }
  }

  void reset() => state = PickerIdle();

  void setImage(SelectedImage image) => state = PickerLoaded(image);
}

final pickerProvider = NotifierProvider<PickerNotifier, PickerState>(
  PickerNotifier.new,
);
