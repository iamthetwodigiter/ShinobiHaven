import 'package:better_player_plus/better_player_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shinobihaven/core/theme/app_theme.dart';
import 'package:shinobihaven/features/anime/stream/dependency_injection/sources_provider.dart';
import 'package:shinobihaven/features/anime/stream/model/sources.dart';
import 'package:shimmer/shimmer.dart';

class SourcesPage extends ConsumerStatefulWidget {
  final String title;
  final String serverID;
  const SourcesPage({super.key, required this.serverID, required this.title});

  @override
  ConsumerState<SourcesPage> createState() => _SourcesPageState();
}

class _SourcesPageState extends ConsumerState<SourcesPage> {
  bool _sourcesLoaded = false;
  BetterPlayerController? _betterPlayerController;
  String? _videoURL;
  bool _videoReady = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _betterPlayerController?.dispose();
      _loadStreams();
    });
  }

  Future<void> _setupBetterPlayer(
    String videoUrl,
    List<Captions> captions,
  ) async {
    final dataSource = BetterPlayerDataSource(
      BetterPlayerDataSourceType.network,
      videoUrl,
      subtitles: captions.map((caption) {
        return BetterPlayerSubtitlesSource(
          type: BetterPlayerSubtitlesSourceType.network,
          urls: [caption.link],
          name: caption.language,
        );
      }).toList(),
      videoFormat: BetterPlayerVideoFormat.hls,
    );
    _betterPlayerController?.dispose();
    _betterPlayerController = BetterPlayerController(
      BetterPlayerConfiguration(
        autoPlay: true,
        looping: false,
        expandToFill: false,
        autoDetectFullscreenDeviceOrientation: true,
        fit: BoxFit.cover,
        // controlsConfiguration: BetterPlayerControlsConfiguration(
        //   playerTheme: BetterPlayerTheme.custom,
        //   backgroundColor: AppTheme.blackGradient.withAlpha(220),
        //   controlsHideTime: const Duration(seconds: 4),
        //   enableFullscreen: true,
        //   enableMute: true,
        //   enableProgressBar: true,
        //   enablePlayPause: true,
        //   enableSkips: true,
        //   enablePlaybackSpeed: true,
        //   enableSubtitles: true,
        //   enableRetry: true,
        //   enableAudioTracks: false,
        //   enableOverflowMenu: false,
        //   iconsColor: AppTheme.gradient1,
        //   progressBarPlayedColor: AppTheme.gradient1,
        //   progressBarHandleColor: AppTheme.gradient1,
        //   progressBarBufferedColor: AppTheme.gradient2.withAlpha(120),
        //   progressBarBackgroundColor: AppTheme.whiteGradient.withAlpha(51),
        //   controlBarHeight: 56,
        //   // controlBarPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        //   // controlBarDecoration: BoxDecoration(
        //   //   color: AppTheme.blackGradient.withAlpha(220),
        //   //   borderRadius: BorderRadius.circular(16),
        //   //   boxShadow: [
        //   //     BoxShadow(
        //   //       color: AppTheme.gradient1.withAlpha(51),
        //   //       blurRadius: 8,
        //   //       offset: Offset(0, 2),
        //   //     ),
        //   //   ],
        //   // ),
        //   playIcon: Icons.play_arrow_rounded,
        //   pauseIcon: Icons.pause_rounded,
        //   fullscreenEnableIcon: Icons.fullscreen_rounded,
        //   fullscreenDisableIcon: Icons.fullscreen_exit_rounded,
        //   muteIcon: Icons.volume_off_rounded,
        //   unMuteIcon: Icons.volume_up_rounded,
        //   skipForwardIcon: Icons.forward_10_rounded,
        //   skipBackIcon: Icons.replay_10_rounded,
        //   playbackSpeedIcon: Icons.speed_rounded,
        //   subtitlesIcon: Icons.subtitles_rounded,
        //   // retryIcon: Icons.refresh_rounded,
        //   overflowMenuIcon: Icons.more_vert_rounded,
        //   loadingColor: AppTheme.gradient1,
        // ),
      ),
      betterPlayerDataSource: dataSource,
    );

    _betterPlayerController!.addEventsListener((event) {
      if (event.betterPlayerEventType == BetterPlayerEventType.initialized) {
        setState(() {
          _videoReady = true;
        });
      }
    });
  }

  void _loadStreams() async {
    if (_sourcesLoaded) return;
    _sourcesLoaded = true;

    await ref
        .read(sourcesViewModelProvider.notifier)
        .getSources(widget.serverID);
    final sourcesState = ref.read(sourcesViewModelProvider);

    if (sourcesState.hasError) {
      return;
    }
    final sources = sourcesState.value;
    if (sources != null) {
      await ref
          .read(vidSrcSourcesProvider.notifier)
          .getVidSrcSources(sources.dataID, sources.key);
    }
  }

  @override
  void dispose() {
    _betterPlayerController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vidSrcSource = ref.watch(vidSrcSourcesProvider);

    return Scaffold(
      appBar: AppBar(
        leading: InkWell(
          onTap: () {
            Navigator.pop(context, true);
            _betterPlayerController?.dispose();
          },
          child: Icon(Icons.arrow_back_ios),
        ),
        title: Text(
          widget.title,
          style: TextStyle(fontSize: 18),
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: vidSrcSource.when(
        data: (stream) {
          if (_videoURL != stream.sources.first.fileURL) {
            _videoURL = stream.sources.first.fileURL;
            _videoReady = false;
            _betterPlayerController?.dispose();
            _betterPlayerController = null;
            _setupBetterPlayer(_videoURL!, vidSrcSource.value!.captions);
            return Center(child: CircularProgressIndicator());
          }

          if (!_videoReady) {
            return Center(child: CircularProgressIndicator());
          }

          return Center(
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: BetterPlayer(controller: _betterPlayerController!),
            ),
          );
        },
        error: (err, stack) => Container(
          alignment: Alignment.center,
          padding: EdgeInsets.symmetric(horizontal: 15),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error, color: AppTheme.gradient1, size: 48),
              SizedBox(height: 16),
              Text(
                'Error occured while fetching the data.\nPlease check your internet connection or try again later.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppTheme.gradient1, fontSize: 16),
              ),
              SizedBox(height: 8),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.gradient1,
                ),
                onPressed: () {
                  _sourcesLoaded = false;
                  _videoURL = null;
                  _videoReady = false;
                  _betterPlayerController?.dispose();
                  _betterPlayerController = null;
                  _loadStreams();
                },
                child: Text(
                  'Retry',
                  style: TextStyle(color: AppTheme.whiteGradient),
                ),
              ),
            ],
          ),
        ),
        loading: () => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Shimmer.fromColors(
                baseColor: AppTheme.blackGradient,
                highlightColor: AppTheme.gradient1.withAlpha(77),
                child: Icon(
                  Icons.movie,
                  size: 72,
                  color: AppTheme.whiteGradient,
                ),
              ),
              SizedBox(height: 18),
              Shimmer.fromColors(
                baseColor: AppTheme.blackGradient,
                highlightColor: AppTheme.gradient1.withAlpha(77),
                child: Text(
                  'Loading...',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.whiteGradient,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
