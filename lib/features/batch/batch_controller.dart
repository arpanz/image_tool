import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/models/compression_result.dart';
import '../../core/models/compression_settings.dart';
import '../../core/models/selected_image.dart';
import '../../core/utils/image_processor.dart';

// ─── Models ────────────────────────────────────────────────────────────────────

enum BatchItemStatus { pending, processing, done, failed }

class BatchItem {
  final SelectedImage image;
  final BatchItemStatus status;
  final CompressionResult? result;
  final String? error;

  const BatchItem({
    required this.image,
    this.status = BatchItemStatus.pending,
    this.result,
    this.error,
  });

  BatchItem copyWith({
    BatchItemStatus? status,
    CompressionResult? result,
    String? error,
  }) =>
      BatchItem(
        image: image,
        status: status ?? this.status,
        result: result ?? this.result,
        error: error ?? this.error,
      );
}

class BatchState {
  final List<BatchItem> items;
  final bool isProcessing;
  final bool isDone;
  final CompressionSettings settings;

  const BatchState({
    this.items = const [],
    this.isProcessing = false,
    this.isDone = false,
    this.settings = const CompressionSettings(),
  });

  BatchState copyWith({
    List<BatchItem>? items,
    bool? isProcessing,
    bool? isDone,
    CompressionSettings? settings,
  }) =>
      BatchState(
        items: items ?? this.items,
        isProcessing: isProcessing ?? this.isProcessing,
        isDone: isDone ?? this.isDone,
        settings: settings ?? this.settings,
      );

  int get doneCount =>
      items.where((i) => i.status == BatchItemStatus.done).length;
  int get failedCount =>
      items.where((i) => i.status == BatchItemStatus.failed).length;
  int get totalCount => items.length;
  double get progress =>
      totalCount == 0 ? 0 : (doneCount + failedCount) / totalCount;
}

// ─── Notifier ──────────────────────────────────────────────────────────────────

class BatchNotifier extends StateNotifier<BatchState> {
  BatchNotifier() : super(const BatchState());

  Future<void> pickImages() async {
    final picker = ImagePicker();
    final picked = await picker.pickMultiImage();
    if (picked.isEmpty) return;

    final newItems = <BatchItem>[];
    for (final xf in picked) {
      try {
        final file = File(xf.path);
        final bytes = await file.length();
        final size = await _decodeSize(file);
        newItems.add(BatchItem(
          image: SelectedImage(
            path: xf.path,
            width: size.$1,
            height: size.$2,
            originalSize: bytes,
          ),
        ));
      } catch (_) {
        // skip unreadable files
      }
    }

    state = state.copyWith(
      items: [...state.items, ...newItems],
      isDone: false,
    );
  }

  void removeItem(int index) {
    final updated = [...state.items]..removeAt(index);
    state = state.copyWith(items: updated);
  }

  void clearAll() => state = const BatchState();

  void updateSettings(CompressionSettings settings) =>
      state = state.copyWith(settings: settings);

  Future<void> processAll() async {
    if (state.items.isEmpty || state.isProcessing) return;

    // Reset all to pending
    state = state.copyWith(
      isProcessing: true,
      isDone: false,
      items: state.items
          .map((i) => i.copyWith(status: BatchItemStatus.pending))
          .toList(),
    );

    final updatedItems = [...state.items];

    for (int i = 0; i < updatedItems.length; i++) {
      updatedItems[i] =
          updatedItems[i].copyWith(status: BatchItemStatus.processing);
      state = state.copyWith(items: List.from(updatedItems));

      try {
        final result = await ImageProcessor.process(
          inputPath: updatedItems[i].image.path,
          settings: state.settings,
          originalWidth: updatedItems[i].image.width,
          originalHeight: updatedItems[i].image.height,
        );
        updatedItems[i] = updatedItems[i].copyWith(
          status: BatchItemStatus.done,
          result: result,
        );
      } catch (e) {
        updatedItems[i] = updatedItems[i].copyWith(
          status: BatchItemStatus.failed,
          error: e.toString(),
        );
      }

      state = state.copyWith(items: List.from(updatedItems));
    }

    state = state.copyWith(isProcessing: false, isDone: true);
  }
}

final batchProvider =
    StateNotifierProvider.autoDispose<BatchNotifier, BatchState>(
  (_) => BatchNotifier(),
);

// ─── Helper ────────────────────────────────────────────────────────────────────

Future<(int, int)> _decodeSize(File file) async {
  try {
    final bytes = await file.readAsBytes();
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    return (frame.image.width, frame.image.height);
  } catch (_) {
    return (800, 600);
  }
}
