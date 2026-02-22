import 'package:shinobihaven/features/download/model/download_task.dart';

class DownloadsState {
  final List<DownloadTask> ongoingTasks;
  final List<Map<String, dynamic>> completedTasks;
  final bool isLoadingCompleted;

  DownloadsState({
    required this.ongoingTasks,
    required this.completedTasks,
    this.isLoadingCompleted = false,
  });

  factory DownloadsState.initial() => DownloadsState(
    ongoingTasks: [],
    completedTasks: [],
    isLoadingCompleted: true,
  );

  DownloadsState copyWith({
    List<DownloadTask>? ongoingTasks,
    List<Map<String, dynamic>>? completedTasks,
    bool? isLoadingCompleted,
  }) {
    return DownloadsState(
      ongoingTasks: ongoingTasks ?? this.ongoingTasks,
      completedTasks: completedTasks ?? this.completedTasks,
      isLoadingCompleted: isLoadingCompleted ?? this.isLoadingCompleted,
    );
  }
}
