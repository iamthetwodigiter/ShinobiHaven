import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shinobihaven/core/theme/app_theme.dart';
import 'package:shinobihaven/features/download/repository/downloads_repository.dart';
import 'package:path/path.dart' as p;
import 'package:shinobihaven/features/download/view/widgets/ongoing_downloads.dart';
import 'downloaded_episodes_page.dart';

class DownloadsPage extends StatefulWidget {
  const DownloadsPage({super.key});
  @override
  State<DownloadsPage> createState() => _DownloadsPageState();
}

class _DownloadsPageState extends State<DownloadsPage> {
  late final DownloadsRepository _repo;

  List<Map<String, dynamic>> _completedList = [];
  bool _loadingCompleted = true;

  Set<String> _lastActiveIds = {};

  @override
  void initState() {
    super.initState();
    _repo = DownloadsRepository();
    _lastActiveIds = _repo.activeDownloads.value
        .map((d) => d['id'] as String?)
        .whereType<String>()
        .toSet();
    _loadCompleted();
    _repo.activeDownloads.addListener(_onActiveChanged);
  }

  void _onActiveChanged() {
    if (!mounted) return;

    final newIds = _repo.activeDownloads.value
        .map((d) => d['id'] as String?)
        .whereType<String>()
        .toSet();

    if (!setEquals(_lastActiveIds, newIds)) {
      _lastActiveIds = newIds;
      _loadCompleted();
    }
  }

  @override
  void dispose() {
    _repo.activeDownloads.removeListener(_onActiveChanged);
    super.dispose();
  }

  Future<void> _loadCompleted() async {
    setState(() {
      _loadingCompleted = true;
    });
    try {
      final list = await _repo.loadDownloadsIndex();
      if (!mounted) return;
      setState(() {
        _completedList = list;
        _loadingCompleted = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _completedList = [];
        _loadingCompleted = false;
      });
    }
  }

  Future<void> _refresh() async {
    await _loadCompleted();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryBlack,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryBlack,
        title: Text('Downloads', style: TextStyle(color: AppTheme.gradient1)),
      ),
      body: _loadingCompleted
          ? Center(child: CircularProgressIndicator(color: AppTheme.gradient1))
          : Column(
              children: [
                Padding(
                  padding: EdgeInsets.all(12),
                  child: ValueListenableBuilder<List<Map<String, dynamic>>>(
                    valueListenable: _repo.activeDownloads,
                    builder: (context, ongoing, _) {
                      if (ongoing.isEmpty) return SizedBox.shrink();

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Ongoing downloads',
                            style: TextStyle(
                              color: AppTheme.gradient1,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 8),
                          ...ongoing.map((d) {
                            final prog = (d['progress'] as int?) ?? 0;
                            final received = d['received'] as int? ?? 0;
                            final total = d['total'] as int?;
                            final speed = (d['speed'] as double?) ?? 0.0;
                            final etaSec = (d['eta'] as double?)?.toInt();
                            final displayedSpeedBytesPerSec = (speed * 8)
                                .toInt();
                            return OngoingDownloads(
                              animeTitle: d['animeTitle'],
                              episodeNumber: d['episodeNumber'],
                              progress: prog,
                              received: received,
                              total: total,
                              speed: speed,
                              displayedSpeedBytesPerSec:
                                  displayedSpeedBytesPerSec,
                              etaSec: etaSec,
                            );
                          }),
                        ],
                      );
                    },
                  ),
                ),

                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _refresh,
                    child: _completedList.isEmpty
                        ? Center(
                            child: Padding(
                              padding: EdgeInsets.symmetric(horizontal: 32),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.download,
                                    color: AppTheme.gradient1,
                                    size: 84,
                                  ),
                                  SizedBox(height: 16),
                                  Text(
                                    'No downloads yet',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.gradient1,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  Text(
                                    'Tap the download icon on any episodes to add it to your downloads',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                          )
                        : _buildGroupsList(
                            _completedList.where((e) {
                              final ongoingPaths = _lastActiveIds.isEmpty
                                  ? <String>{}
                                  : _repo.activeDownloads.value
                                        .map((d) => d['filePath'] as String?)
                                        .whereType<String>()
                                        .toSet();
                              final fp = e['filePath'] as String?;
                              if (fp != null && ongoingPaths.contains(fp)) {
                                return false;
                              }
                              final key =
                                  '${e['animeTitle'] ?? ''}|${e['episodeNumber'] ?? ''}|${e['title'] ?? ''}';
                              final ongoingKeys = _repo.activeDownloads.value
                                  .map(
                                    (d) =>
                                        '${d['animeTitle'] ?? ''}|${d['episodeNumber'] ?? ''}|${d['title'] ?? ''}',
                                  )
                                  .toSet();
                              if (ongoingKeys.contains(key)) return false;
                              return true;
                            }).toList(),
                          ),
                  ),
                ),
              ],
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

    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView.separated(
        padding: EdgeInsets.all(12),
        itemCount: groups.length,
        separatorBuilder: (_, __) => SizedBox(height: 8),
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
                      color: AppTheme.gradient1.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Icon(Icons.movie, color: AppTheme.gradient1),
                    ),
                  ),
            title: Text(
              animeTitle,
              style: TextStyle(
                color: AppTheme.whiteGradient,
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Text(
              '${episodes.length} episode${episodes.length == 1 ? '' : 's'} downloaded',
              style: TextStyle(
                color: AppTheme.whiteGradient.withValues(alpha: 0.7),
              ),
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
