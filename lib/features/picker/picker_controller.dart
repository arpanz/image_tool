import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
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

      // Decode image to get width/height without extra packages
      int w = 0, h = 0;
      try {
        final data = await file.readAsBytes();
        final codec = await ui.instantiateImageCodec(data);
        final frame = await codec.getNextFrame();
        w = frame.image.width;
        h = frame.image.height;
        frame.image.dispose();
      } catch (_) {}

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

  void reset() => state = PickerIdle();
}

final pickerProvider = NotifierProvider<PickerNotifier, PickerState>(
  PickerNotifier.new,
);
