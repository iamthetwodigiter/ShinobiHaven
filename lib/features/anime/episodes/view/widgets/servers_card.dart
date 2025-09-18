import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shinobihaven/core/theme/app_theme.dart';
import 'package:shinobihaven/core/utils/library_box_functions.dart';
import 'package:shinobihaven/features/anime/common/model/anime.dart';
import 'package:shinobihaven/features/anime/episodes/dependency_injection/servers_provider.dart';
import 'package:shinobihaven/features/anime/stream/view/pages/sources_page.dart';
import 'package:shimmer/shimmer.dart';

class ServersCard extends ConsumerStatefulWidget {
  final String episodeID;
  final Anime anime;
  final String title;
  const ServersCard({
    super.key,
    required this.episodeID,
    required this.anime,
    required this.title,
  });

  @override
  ConsumerState<ServersCard> createState() => _ServersCardState();
}

class _ServersCardState extends ConsumerState<ServersCard> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadServers();
    });
  }

  void _loadServers() {
    ref.read(serversViewModelProvider.notifier).fetchServers(widget.episodeID);
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final serversData = ref.watch(serversViewModelProvider);
    return SafeArea(
      child: Container(
        decoration: BoxDecoration(
          color: Theme.brightnessOf(context) == Brightness.dark
              ? AppTheme.blackGradient
              : AppTheme.whiteGradient,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: EdgeInsets.symmetric(horizontal: 15),
        width: size.width,
        child: serversData.when(
          data: (servers) {
            final filteredSubServers = servers.sub
                .where((server) => server.serverName == 'MegaCloud')
                .toList();
            final filteredDubServers = servers.dub
                .where((server) => server.serverName == 'MegaCloud')
                .toList();
            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 20),
                  Text(
                    'Available Servers',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.gradient1,
                    ),
                  ),
                  SizedBox(height: 20),
                  ...List.generate(filteredSubServers.length, (index) {
                    final server = filteredSubServers[index];
                    return Card(
                      color: Theme.brightnessOf(context) == Brightness.dark
                          ? AppTheme.primaryBlack
                          : AppTheme.whiteGradient,
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                        side: BorderSide(
                          color: AppTheme.gradient1.withAlpha(51),
                        ),
                      ),
                      margin: EdgeInsets.only(bottom: 10),
                      child: ListTile(
                        onTap: () {
                          LibraryBoxFunction.addToLibrary(
                            widget.anime,
                            widget.episodeID,
                          );
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) {
                                return SourcesPage(
                                  serverID: server.dataID,
                                  title: widget.title,
                                );
                              },
                            ),
                          );
                        },
                        leading: Icon(
                          Icons.play_circle_fill_rounded,
                          size: 28,
                          color: AppTheme.gradient1,
                        ),
                        title: Text(
                          'Server ${index + 1}',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            // color: AppTheme.whiteGradient,
                          ),
                        ),
                        subtitle: Text(
                          '${server.type.toUpperCase()}  [Data ID: ${server.dataID}]',
                          style: TextStyle(
                            color: AppTheme.gradient1,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        trailing: Icon(
                          Icons.arrow_forward_ios,
                          size: 18,
                          color: AppTheme.gradient1,
                        ),
                      ),
                    );
                  }),
                  ...List.generate(filteredDubServers.length, (index) {
                    final server = filteredDubServers[index];
                    return Card(
                      color: Theme.brightnessOf(context) == Brightness.dark
                          ? AppTheme.primaryBlack
                          : AppTheme.whiteGradient,
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                        side: BorderSide(
                          color: AppTheme.gradient2.withAlpha(51),
                        ),
                      ),
                      margin: EdgeInsets.only(bottom: 10),
                      child: ListTile(
                        onTap: () {
                          LibraryBoxFunction.addToLibrary(
                            widget.anime,
                            widget.episodeID,
                          );
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) {
                                return SourcesPage(
                                  serverID: server.dataID,
                                  title: widget.title,
                                );
                              },
                            ),
                          );
                        },
                        leading: Icon(
                          Icons.play_circle_fill_rounded,
                          size: 28,
                          color: AppTheme.gradient2,
                        ),
                        title: Text(
                          'Server ${index + 1}',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            // color: AppTheme.whiteGradient,
                          ),
                        ),
                        subtitle: Text(
                          '${server.type.toUpperCase()}  [Data ID: ${server.dataID}]',
                          style: TextStyle(
                            color: AppTheme.gradient2,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        trailing: Icon(
                          Icons.arrow_forward_ios,
                          size: 18,
                          color: AppTheme.gradient2,
                        ),
                      ),
                    );
                  }),
                  SizedBox(height: 12),
                  Container(
                    padding: EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                    decoration: BoxDecoration(
                      color: Theme.brightnessOf(context) == Brightness.dark
                          ? AppTheme.primaryBlack
                          : AppTheme.whiteGradient,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.info, size: 18, color: AppTheme.gradient1),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Currently, only the most compatible server is supported.',
                            style: TextStyle(
                              // color: AppTheme.whiteGradient,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 2,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 8),
                ],
              ),
            );
          },
          error: (err, stack) => Center(
            child: Container(
              padding: EdgeInsets.all(24),
              margin: EdgeInsets.symmetric(horizontal: 24),
              decoration: BoxDecoration(
                color: AppTheme.gradient1,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.error, color: AppTheme.gradient1, size: 48),
                  SizedBox(height: 16),
                  Text(
                    'Error occured while fetching the data.\nPlease check your internet connection or try again later.',
                    style: TextStyle(
                      color: AppTheme.gradient1,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 8),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.gradient1,
                      foregroundColor: AppTheme.whiteGradient,
                      padding: EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: () {
                      ref
                          .read(serversViewModelProvider.notifier)
                          .fetchServers(widget.episodeID);
                    },
                    child: Text(
                      'Retry',
                      style: TextStyle(color: AppTheme.whiteGradient),
                    ),
                  ),
                ],
              ),
            ),
          ),
          loading: () => Padding(
            padding: EdgeInsets.symmetric(vertical: 40),
            child: Shimmer.fromColors(
              baseColor: AppTheme.blackGradient,
              highlightColor: AppTheme.gradient1.withAlpha(77),
              child: Column(
                children: List.generate(3, (index) {
                  return Container(
                    margin: EdgeInsets.symmetric(vertical: 10),
                    width: double.infinity,
                    height: 60,
                    decoration: BoxDecoration(
                      color: AppTheme.blackGradient.withAlpha(51),
                      borderRadius: BorderRadius.circular(15),
                    ),
                  );
                }),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
