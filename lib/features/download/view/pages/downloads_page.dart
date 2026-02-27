import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shinobihaven/core/theme/app_theme.dart';
import 'package:path/path.dart' as p;
import 'package:shinobihaven/features/download/view/widgets/ongoing_downloads.dart';
import 'downloaded_episodes_page.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shinobihaven/features/download/dependency_injection/downloads_provider.dart';

class DownloadsPage extends ConsumerStatefulWidget {
  const DownloadsPage({super.key});
  @override
  ConsumerState<DownloadsPage> createState() => _DownloadsPageState();
}

class _DownloadsPageState extends ConsumerState<DownloadsPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(downloadsViewModelProvider.notifier).loadCompletedDownloads();
    });
  }

  Future<void> _refresh() async {
    await ref
        .read(downloadsViewModelProvider.notifier)
        .loadCompletedDownloads();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(downloadsViewModelProvider);
    final ongoingTasks = state.ongoingTasks;
    final completedList = state.completedTasks;
    final isLoading = state.isLoadingCompleted;

    return Scaffold(
      extendBodyBehindAppBar: true,
      body: isLoading && completedList.isEmpty
          ? Center(child: CircularProgressIndicator(color: AppTheme.gradient1))
          : RefreshIndicator(
              onRefresh: _refresh,
              child: CustomScrollView(
                slivers: [
                  SliverAppBar(
                    expandedHeight: 120,
                    backgroundColor: Colors.transparent,
                    elevation: 0,
                    flexibleSpace: FlexibleSpaceBar(
                      titlePadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 15,
                      ),
                      title: const Text(
                        'DOWNLOADS',
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.5,
                          fontSize: 24,
                        ),
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: ongoingTasks.isEmpty
                          ? const SizedBox.shrink()
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Ongoing downloads',
                                  style: TextStyle(
                                    color: AppTheme.gradient1,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                ...ongoingTasks.map((task) {
                                  final eta =
                                      task.totalBytes != null &&
                                          task.speedBytesPerSec > 0
                                      ? ((task.totalBytes! -
                                                    task.bytesReceived) /
                                                task.speedBytesPerSec)
                                            .toInt()
                                      : null;
                                  return OngoingDownloads(
                                    taskId: task.id,
                                    animeTitle: task.animeTitle,
                                    episodeNumber: task.episodeNumber,
                                    progress: (task.progress * 100).toInt(),
                                    received: task.bytesReceived,
                                    total: task.totalBytes,
                                    speed: task.speedBytesPerSec,
                                    displayedSpeedBytesPerSec: task
                                        .speedBytesPerSec
                                        .toInt(),
                                    etaSec: eta,
                                    status: task.status,
                                    error: task.error,
                                    onCancel: () {
                                      ref
                                          .read(
                                            downloadsViewModelProvider.notifier,
                                          )
                                          .cancelDownload(task.id);
                                    },
                                  );
                                }),
                              ],
                            ),
                    ),
                  ),
                  completedList.isEmpty && ongoingTasks.isEmpty
                      ? SliverFillRemaining(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 32),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.download,
                                  color: AppTheme.gradient1,
                                  size: 84,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No downloads yet',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.gradient1,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const Text(
                                  'Tap the download icon on any episodes to add it to your downloads',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        )
                      : _buildGroupsList(
                          completedList.where((e) {
                            // Filter out tasks that are still active (Ongoing)
                            final key =
                                '${e['animeTitle'] ?? ''}|${e['episodeNumber'] ?? ''}|${e['title'] ?? ''}';
                            final ongoingKeys = ongoingTasks
                                .map(
                                  (d) =>
                                      '${d.animeTitle}|${d.episodeNumber}|${d.title}',
                                )
                                .toSet();
                            if (ongoingKeys.contains(key)) return false;
                            return true;
                          }).toList(),
                        ),
                ],
              ),
            ),
    );
  }

  Widget _buildGroupsList(List<Map<String, dynamic>> list) {
    final Map<String, List<Map<String, dynamic>>> grouped = {};
    for (final e in list) {
      final title =
          (e['animeTitle'] as String?) ??
          p.basename(p.dirname(e['filePath'] as String));
      grouped.putIfAbsent(title, () => []).add(e);
    }

    final groups = grouped.entries.toList()
      ..sort((a, b) => a.key.toLowerCase().compareTo(b.key.toLowerCase()));

    return SliverPadding(
      padding: const EdgeInsets.all(12),
      sliver: MediaQuery.sizeOf(context).width > 900
          ? SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                childAspectRatio: 3,
                crossAxisSpacing: 16,
                mainAxisSpacing: 12,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final animeTitle = groups[index].key;
                  final episodes = groups[index].value;
                  final posterPath = episodes.first['posterPath'] as String?;
                  return Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => DownloadedEpisodesPage(
                              animeTitle: animeTitle,
                              episodes: episodes,
                            ),
                          ),
                        ).then((_) => _refresh());
                      },
                      borderRadius: BorderRadius.circular(15),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.blackGradient.withAlpha(150),
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(
                            color: Colors.white.withAlpha(20),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            posterPath != null && File(posterPath).existsSync()
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: Image.file(
                                      File(posterPath),
                                      width: 64,
                                      height: 64,
                                      fit: BoxFit.cover,
                                    ),
                                  )
                                : Container(
                                    width: 64,
                                    height: 64,
                                    decoration: BoxDecoration(
                                      color: AppTheme.gradient1.withAlpha(30),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Center(
                                      child: Icon(Icons.movie,
                                          color: AppTheme.gradient1),
                                    ),
                                  ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    animeTitle,
                                    style: const TextStyle(
                                      color: AppTheme.whiteGradient,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${episodes.length} episodes',
                                    style: TextStyle(
                                      color: AppTheme.whiteGradient
                                          .withAlpha(180),
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(Icons.chevron_right,
                                color: AppTheme.gradient1, size: 20),
                          ],
                        ),
                      ),
                    ),
                  );
                },
                childCount: groups.length,
              ),
            )
          : SliverList.separated(
              itemCount: groups.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final animeTitle = groups[index].key;
                final episodes = groups[index].value;
                final posterPath = episodes.first['posterPath'] as String?;
                return ListTile(
                  tileColor: AppTheme.blackGradient,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  leading: posterPath != null && File(posterPath).existsSync()
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.file(
                            File(posterPath),
                            width: 56,
                            height: 56,
                            fit: BoxFit.cover,
                          ),
                        )
                      : Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: AppTheme.gradient1.withAlpha(30),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            child: Icon(Icons.movie, color: AppTheme.gradient1),
                          ),
                        ),
                  title: Text(
                    animeTitle,
                    style: const TextStyle(
                      color: AppTheme.whiteGradient,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Text(
                    '${episodes.length} episode${episodes.length == 1 ? '' : 's'} downloaded',
                    style:
                        TextStyle(color: AppTheme.whiteGradient.withAlpha(180)),
                  ),
                  trailing: Icon(Icons.chevron_right, color: AppTheme.gradient1),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => DownloadedEpisodesPage(
                          animeTitle: animeTitle,
                          episodes: episodes,
                        ),
                      ),
                    ).then((_) => _refresh());
                  },
                );
              },
            ),
    );
  }
}
