import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/compression_settings.dart';
import '../../core/models/compression_result.dart';
import '../../core/models/selected_image.dart';
import '../../core/utils/image_processor.dart';

typedef CompressionAsyncState = AsyncValue<CompressionResult?>;

class EditorState {
  final CompressionSettings settings;
  final CompressionAsyncState compressionState;
  final int? estimatedSize;
  final bool isEstimating;

  const EditorState({
    required this.settings,
    required this.compressionState,
    this.estimatedSize,
    this.isEstimating = false,
  });

  EditorState copyWith({
    CompressionSettings? settings,
    CompressionAsyncState? compressionState,
    int? estimatedSize,
    bool? isEstimating,
    bool clearEstimatedSize = false,
  }) {
    return EditorState(
      settings: settings ?? this.settings,
      compressionState: compressionState ?? this.compressionState,
      estimatedSize: clearEstimatedSize ? null : (estimatedSize ?? this.estimatedSize),
      isEstimating: isEstimating ?? this.isEstimating,
    );
  }
}

class EditorNotifier extends Notifier<EditorState> {
  SelectedImage? _currentImage;
  Timer? _debounceTimer;
  CompressionSettings? _lastEstimatedSettings;

  @override
  EditorState build() => const EditorState(
        settings: CompressionSettings(),
        compressionState: AsyncData(null),
      );

  void initialize(SelectedImage image) {
    _debounceTimer?.cancel();
    _lastEstimatedSettings = null;
    _currentImage = image;
    state = const EditorState(
      settings: CompressionSettings(),
      compressionState: AsyncData(null),
    );
    _triggerEstimation();
  }

  void _triggerEstimation() {
    final image = _currentImage;
    if (image == null) return;

    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 350), () async {
      final currentSettings = state.settings;
      
      // Skip if settings haven't changed since last completed estimation
      if (currentSettings == _lastEstimatedSettings) return;

      state = state.copyWith(isEstimating: true);

      try {
        final result = await ImageProcessor.process(
          inputPath: image.path,
          settings: currentSettings,
          originalWidth: image.width,
          originalHeight: image.height,
        );

        // Only update if settings haven't changed during the async call
        if (state.settings == currentSettings) {
          state = state.copyWith(
            estimatedSize: result.newSize,
            isEstimating: false,
          );
          _lastEstimatedSettings = currentSettings;
        }
      } catch (_) {
        if (state.settings == currentSettings) {
          state = state.copyWith(
            isEstimating: false,
            clearEstimatedSize: true,
          );
        }
      }
    });
  }

  void setQuality(int q) {
    state = state.copyWith(settings: state.settings.copyWith(quality: q));
    _triggerEstimation();
  }

  void setWidth(int? w) {
    state = state.copyWith(
      settings: state.settings.copyWith(
        width: w,
        clearWidth: w == null,
      ),
    );
    _triggerEstimation();
  }

  void setHeight(int? h) {
    state = state.copyWith(
      settings: state.settings.copyWith(
        height: h,
        clearHeight: h == null,
      ),
    );
    _triggerEstimation();
  }

  void toggleAspectRatio() {
    state = state.copyWith(
      settings: state.settings.copyWith(
        keepAspectRatio: !state.settings.keepAspectRatio,
      ),
    );
    _triggerEstimation();
  }

  void setFormat(String format) {
    state = state.copyWith(settings: state.settings.copyWith(format: format));
    _triggerEstimation();
  }

  void setFitMode(ResizeFitMode mode) {
    state = state.copyWith(settings: state.settings.copyWith(fitMode: mode));
    _triggerEstimation();
  }

  void setTargetSizeKB(int? kb) {
    state = state.copyWith(
      settings: kb == null
          ? state.settings.copyWith(clearTargetSizeKB: true)
          : state.settings.copyWith(targetSizeKB: kb),
    );
    _triggerEstimation();
  }

  void setBackgroundColorHex(int? hex) {
    state = state.copyWith(
      settings: hex == null
          ? state.settings.copyWith(clearBackgroundColorHex: true)
          : state.settings.copyWith(backgroundColorHex: hex),
    );
    _triggerEstimation();
  }

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

  void reset() {
    _debounceTimer?.cancel();
    _currentImage = null;
    _lastEstimatedSettings = null;
    state = const EditorState(
      settings: CompressionSettings(),
      compressionState: AsyncData(null),
    );
  }
}

final editorProvider = NotifierProvider<EditorNotifier, EditorState>(
  EditorNotifier.new,
);
