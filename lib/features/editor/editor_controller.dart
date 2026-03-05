import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/compression_settings.dart';
import '../../core/models/compression_result.dart';
import '../../core/models/selected_image.dart';
import '../../core/utils/image_processor.dart';

typedef CompressionAsyncState = AsyncValue<CompressionResult?>;

class EditorState {
  final CompressionSettings settings;
  final CompressionAsyncState compressionState;

  const EditorState({
    required this.settings,
    required this.compressionState,
  });

  EditorState copyWith({
    CompressionSettings? settings,
    CompressionAsyncState? compressionState,
  }) {
    return EditorState(
      settings: settings ?? this.settings,
      compressionState: compressionState ?? this.compressionState,
    );
  }
}

class EditorNotifier extends Notifier<EditorState> {
  @override
  EditorState build() => EditorState(
        settings: const CompressionSettings(),
        compressionState: const AsyncData(null),
      );

  void setQuality(int q) =>
      state = state.copyWith(settings: state.settings.copyWith(quality: q));

  void setWidth(int? w) =>
      state = state.copyWith(settings: state.settings.copyWith(width: w));

  void setHeight(int? h) =>
      state = state.copyWith(settings: state.settings.copyWith(height: h));

  void toggleAspectRatio() => state = state.copyWith(
        settings: state.settings.copyWith(
          keepAspectRatio: !state.settings.keepAspectRatio,
        ),
      );

  void setFormat(String format) =>
      state = state.copyWith(settings: state.settings.copyWith(format: format));

  void setFitMode(ResizeFitMode mode) =>
      state = state.copyWith(settings: state.settings.copyWith(fitMode: mode));

  Future<CompressionResult?> compress(SelectedImage image) async {
    state = state.copyWith(compressionState: const AsyncLoading());
    try {
      final result = await ImageProcessor.process(
        inputPath: image.path,
        settings: state.settings,
        originalWidth: image.width,
        originalHeight: image.height,
      );
      state = state.copyWith(compressionState: AsyncData(result));
      return result;
    } on Exception catch (e, st) {
      state = state.copyWith(compressionState: AsyncError(e, st));
      return null;
    }
  }

  void reset() => state = EditorState(
        settings: const CompressionSettings(),
        compressionState: const AsyncData(null),
      );
}

final editorProvider = NotifierProvider<EditorNotifier, EditorState>(
  EditorNotifier.new,
);
