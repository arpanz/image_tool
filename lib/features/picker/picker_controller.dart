import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/models/selected_image.dart';

/// State sealed class for the picker feature
sealed class PickerState {
  const PickerState();
}

final class PickerIdle extends PickerState {
  const PickerIdle();
}

final class PickerLoading extends PickerState {
  const PickerLoading();
}

final class PickerLoaded extends PickerState {
  final SelectedImage image;
  const PickerLoaded(this.image);
}

final class PickerError extends PickerState {
  final String message;
  const PickerError(this.message);
}

class PickerNotifier extends Notifier<PickerState> {
  final _picker = ImagePicker();

  @override
  PickerState build() => const PickerIdle();

  Future<SelectedImage?> pickImage() async {
    state = const PickerLoading();
    try {
      final XFile? xfile = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 100,
      );

      if (xfile == null) {
        state = const PickerIdle();
        return null;
      }

      final file = File(xfile.path);
      final bytes = await file.readAsBytes();
      final size = bytes.length;

      // Decode dimensions without blocking UI using basic file stat
      // For accurate dims we'd use image package; keeping dep-list lean:
      // fallback dims from flutter_image_compress are set at editor level.
      final selected = SelectedImage(
        path: xfile.path,
        originalSize: size,
        width: 0, // resolved in editor
        height: 0,
      );

      state = PickerLoaded(selected);
      return selected;
    } on Exception catch (e) {
      state = PickerError('Failed to pick image: $e');
      return null;
    }
  }

  void reset() => state = const PickerIdle();
}

final pickerProvider = NotifierProvider<PickerNotifier, PickerState>(
  PickerNotifier.new,
);
