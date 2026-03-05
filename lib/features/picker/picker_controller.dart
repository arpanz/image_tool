import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_size_getter/image_size_getter.dart';
import 'package:image_size_getter/file_input.dart';
import 'dart:io';
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

      int w = 0, h = 0;
      try {
        final size = ImageSizeGetter.getSize(FileInput(file));
        w = size.width;
        h = size.height;
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
