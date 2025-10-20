import 'dart:async';
import 'package:better_player_plus/better_player_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shinobihaven/core/theme/app_theme.dart';
import 'package:shinobihaven/features/anime/common/model/anime.dart';
import 'package:shinobihaven/features/anime/episodes/dependency_injection/servers_provider.dart';
import 'package:shinobihaven/features/anime/episodes/model/episodes.dart';
import 'package:shinobihaven/features/anime/episodes/model/servers.dart';
import 'package:shinobihaven/features/anime/stream/dependency_injection/sources_provider.dart';
import 'package:shinobihaven/features/anime/stream/model/sources.dart';
import 'package:shinobihaven/core/utils/library_box_functions.dart';
import 'package:shimmer/shimmer.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

class SourcesPage extends ConsumerStatefulWidget {
  final Anime anime;
  final List<Episodes> episodes;
  final Episodes currentEpisode;
  final String? serverID;

  const SourcesPage({
    super.key,
    required this.anime,
    required this.episodes,
    required this.currentEpisode,
    this.serverID,
  });

  @override
  ConsumerState<SourcesPage> createState() => _SourcesPageState();
}

class _SourcesPageState extends ConsumerState<SourcesPage>
    with WidgetsBindingObserver {
  String? _lastSectionKey;
  BetterPlayerController? _betterPlayerController;
  String? _videoURL;
  bool _videoReady = false;
  bool _hasError = false;
  String? _errorMessage;
  List<SourceFile>? _availableQualities;
  List<Captions>? _availableSubtitles;
  Episodes? _currentPlayingEpisode;
  List<Server> _availableServers = [];
  Server? _currentServer;
  bool _isLoadingNewEpisode = false;
  bool _isLoadingServers = false;
  bool _isLoadingSources = false;
  bool _isLoadingVidSrc = false;
  String _loadingMessage = '';
  bool _isDisposing = false;
  Timer? _initializationTimer;

  String get _stableCacheKey =>
      '${widget.anime.slug}-${_currentPlayingEpisode?.episodeID ?? ''}';

  String _getSectionKey() {
    return '${widget.anime.slug}-${widget.anime.type}-${widget.anime.image}';
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    final currentSectionKey = _getSectionKey();
    final isDifferentSection =
        _lastSectionKey != null && _lastSectionKey != currentSectionKey;
    _lastSectionKey = currentSectionKey;

    _forceDisposePlayer();
    _resetPlayerState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !_isDisposing) {
        final delay = isDifferentSection ? 500 : 300;

        _clearAnimeSpecificProviders();
        _currentPlayingEpisode = widget.currentEpisode;
        _isLoadingServers = true;
        _isLoadingSources = true;
        _isLoadingVidSrc = true;

        Future.delayed(Duration(milliseconds: delay), () {
          if (mounted && !_isDisposing) {
            _loadServersAndStream();
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _isDisposing = true;
    WidgetsBinding.instance.removeObserver(this);

    _forceDisposePlayer();
    _disableWakelock();

    try {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    } catch (_) {}

    super.dispose();
  }

  void _clearAnimeSpecificProviders() {
    if (_isDisposing || !mounted) return;

    try {
      ref.invalidate(serversViewModelProvider);
      ref.invalidate(sourcesViewModelProvider);
      ref.invalidate(vidSrcSourcesProvider);
    } catch (_) {}
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_betterPlayerController != null) {
      switch (state) {
        case AppLifecycleState.paused:
        case AppLifecycleState.inactive:
          _betterPlayerController?.pause();
          break;
        case AppLifecycleState.detached:
          _forceDisposePlayer();
          break;
        default:
          break;
      }
    }
  }

  void _resetPlayerState() {
    _videoReady = false;
    _videoURL = null;
    _hasError = false;
    _errorMessage = '';
    _isLoadingNewEpisode = true;
    _currentServer = null;
    _availableServers.clear();
    _availableQualities = null;
    _availableSubtitles = null;
    _isLoadingServers = false;
    _isLoadingSources = false;
    _isLoadingVidSrc = false;
    _loadingMessage = '';
  }

  void _loadServersAndStream() async {
    if (_isDisposing || _currentPlayingEpisode == null || !mounted) return;

    _forceDisposePlayer();
    _videoURL = null;

    if (!_isDisposing && mounted) {
      try {
        ref.invalidate(serversViewModelProvider);
        ref.invalidate(sourcesViewModelProvider);
        ref.invalidate(vidSrcSourcesProvider);
        await Future.delayed(Duration(milliseconds: 200));
      } catch (_) {}
    }

    if (!mounted || _isDisposing) return;

    setState(() {
      _isLoadingNewEpisode = true;
      _hasError = false;
      _isLoadingServers = true;
      _loadingMessage = 'Loading servers...';
      _videoURL = null;
    });

    try {
      if (_isDisposing || !mounted) return;

      await ref
          .read(serversViewModelProvider(widget.anime.slug).notifier)
          .fetchServers(_currentPlayingEpisode!.episodeID);

      if (_isDisposing || !mounted) return;

      setState(() {
        _isLoadingServers = false;
        _loadingMessage = 'Finding compatible servers...';
      });

      final serversState = ref.read(
        serversViewModelProvider(widget.anime.slug),
      );

      if (serversState.hasValue) {
        final servers = serversState.value!;

        final filteredSubServers = servers.sub
            .where((server) => server.serverName == 'MegaCloud')
            .toList();
        final filteredDubServers = servers.dub
            .where((server) => server.serverName == 'MegaCloud')
            .toList();

        _availableServers = [...filteredSubServers, ...filteredDubServers];

        if (_availableServers.isNotEmpty) {
          if (widget.serverID != null) {
            _currentServer = _availableServers.firstWhere(
              (server) => server.dataID == widget.serverID,
              orElse: () => _availableServers.first,
            );
          } else {
            _currentServer = _availableServers.first;
          }

          if (!_isDisposing && mounted) {
            await _loadStreamForServer(_currentServer!);
          }
        } else {
          if (mounted && !_isDisposing) {
            setState(() {
              _hasError = true;
              _errorMessage = 'No compatible servers found';
              _isLoadingNewEpisode = false;
            });
          }
        }
      }
    } catch (e) {
      if (mounted && !_isDisposing) {
        setState(() {
          _hasError = true;
          _errorMessage = 'Failed to load servers: $e';
          _isLoadingNewEpisode = false;
          _isLoadingServers = false;
        });
      }
    }
  }

  Future<void> _loadStreamForServer(Server server) async {
    if (_isDisposing || !mounted) return;

    try {
      setState(() {
        _currentServer = server;
        _isLoadingSources = true;
        _loadingMessage = 'Loading video sources...';
      });

      if (!_isDisposing && mounted) {
        try {
          ref.invalidate(sourcesViewModelProvider);
          ref.invalidate(vidSrcSourcesProvider);
        } catch (_) {}
        await Future.delayed(Duration(milliseconds: 100));
      }

      if (_isDisposing || !mounted) return;

      await ref
          .read(sourcesViewModelProvider.notifier)
          .getSources(server.dataID);

      if (_isDisposing || !mounted) return;

      setState(() {
        _isLoadingSources = false;
        _isLoadingVidSrc = true;
        _loadingMessage = 'Preparing video stream...';
      });

      final sourcesState = ref.read(sourcesViewModelProvider);

      if (sourcesState.hasError) {
        throw Exception('Failed to load video sources for this server');
      }

      final sources = sourcesState.value;
      if (sources != null) {
        if (!_isDisposing && mounted) {
          try {
            ref.invalidate(vidSrcSourcesProvider);
          } catch (_) {}
          await Future.delayed(Duration(milliseconds: 100));
        }

        if (_isDisposing || !mounted) return;

        await ref
            .read(vidSrcSourcesProvider(_stableCacheKey).notifier)
            .getVidSrcSources(sources.dataID, sources.key);

        if (!_isDisposing && mounted) {
          await Future.delayed(Duration(milliseconds: 500));
        }
      } else {
        throw Exception('Sources data is null');
      }

      if (mounted && !_isDisposing) {
        setState(() {
          _isLoadingVidSrc = false;
          _isLoadingNewEpisode = false;
          _loadingMessage = 'Starting playback...';
        });
      }
    } catch (e) {
      if (mounted && !_isDisposing) {
        setState(() {
          _hasError = true;
          _errorMessage = 'Failed to load stream: ${e.toString()}';
          _isLoadingNewEpisode = false;
          _isLoadingSources = false;
          _isLoadingVidSrc = false;
        });
      }
    }
  }

  Future<void> _setupBetterPlayer(
    String videoUrl,
    List<Captions> captions,
  ) async {
    if (_isDisposing) return;

    try {
      if (!videoUrl.startsWith('http') || !videoUrl.contains('m3u8')) {
        throw Exception('Invalid video URL format');
      }

      _forceDisposePlayer();
      await Future.delayed(Duration(milliseconds: 300));

      if (_isDisposing) return;

      _availableSubtitles = captions;
      _videoURL = videoUrl;

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
        useAsmsSubtitles: true,
        useAsmsTracks: true,
      );

      _betterPlayerController = BetterPlayerController(
        BetterPlayerConfiguration(
          autoPlay: true,
          looping: false,
          fit: BoxFit.contain,
          aspectRatio: 16 / 9,
          handleLifecycle: false,
          autoDispose: false,

          controlsConfiguration: BetterPlayerControlsConfiguration(
            playerTheme: BetterPlayerTheme.cupertino,
            showControls: true,
            showControlsOnInitialize: true,
            enableFullscreen: true,
            enablePlayPause: true,
            enableProgressBar: true,
            enableProgressBarDrag: true,
            enableMute: true,
            enableSubtitles: true,
            enableRetry: true,

            progressBarPlayedColor: AppTheme.gradient1,
            progressBarHandleColor: AppTheme.gradient1,
            progressBarBufferedColor: AppTheme.gradient1.withValues(alpha: 0.3),
            progressBarBackgroundColor: AppTheme.whiteGradient.withValues(
              alpha: 0.2,
            ),
            iconsColor: AppTheme.whiteGradient,
            loadingColor: AppTheme.gradient1,
            backgroundColor: AppTheme.primaryBlack,

            forwardSkipTimeInMilliseconds: 10000,
            backwardSkipTimeInMilliseconds: 10000,

            playIcon: Icons.play_arrow_rounded,
            pauseIcon: Icons.pause,
            muteIcon: Icons.volume_up_rounded,
            unMuteIcon: Icons.volume_off_rounded,
            pipMenuIcon: Icons.picture_in_picture_rounded,
            skipBackIcon: Icons.fast_rewind_rounded,
            skipForwardIcon: Icons.fast_forward_rounded,
            qualitiesIcon: Icons.high_quality_rounded,
            subtitlesIcon: Icons.subtitles,
            audioTracksIcon: Icons.music_note_rounded,
            playbackSpeedIcon: Icons.speed_rounded,
            fullscreenEnableIcon: Icons.fullscreen_rounded,
            fullscreenDisableIcon: Icons.fullscreen_exit_rounded,

            overflowMenuIconsColor: AppTheme.gradient1,
            overflowModalTextColor: AppTheme.gradient1,
            overflowModalColor: AppTheme.blackGradient,
          ),

          subtitlesConfiguration: BetterPlayerSubtitlesConfiguration(
            fontSize: 16,
            fontColor: AppTheme.whiteGradient,
            outlineEnabled: true,
            outlineColor: AppTheme.blackGradient,
            outlineSize: 2,
          ),

          eventListener: (BetterPlayerEvent event) {
            if (_isDisposing) return;
            if (!mounted) return;

            switch (event.betterPlayerEventType) {
              case BetterPlayerEventType.initialized:
                _cancelInitializationTimer();
                if (mounted && !_isDisposing) {
                  setState(() {
                    _videoReady = true;
                    _hasError = false;
                    _isLoadingNewEpisode = false;
                  });
                  _enableWakelock();
                }
                break;

              case BetterPlayerEventType.play:
                _enableWakelock();
                if (_currentPlayingEpisode != null) {
                  LibraryBoxFunction.markLastWatchedEpisode(
                    widget.anime.slug,
                    _currentPlayingEpisode!.episodeNumber,
                  );
                }
                break;

              case BetterPlayerEventType.finished:
                _disableWakelock();
                _playNextEpisode();
                break;

              case BetterPlayerEventType.exception:
                if (mounted && !_isDisposing) {
                  setState(() {
                    _hasError = true;
                    _errorMessage =
                        'Video playback error. Trying next server...';
                    _isLoadingNewEpisode = false;
                  });
                  _disableWakelock();
                  _tryNextServerOnError();
                }
                break;

              default:
                break;
            }
          },
        ),
        betterPlayerDataSource: dataSource,
      );

      _setInitializationTimer();
    } catch (e) {
      if (mounted && !_isDisposing) {
        setState(() {
          _hasError = true;
          _errorMessage = 'Failed to setup video player. Trying next server...';
          _isLoadingNewEpisode = false;
        });
        _tryNextServerOnError();
      }
    }
  }

  void _setInitializationTimer() {
    _cancelInitializationTimer();
    _initializationTimer = Timer(Duration(seconds: 15), () {
      if (mounted && !_videoReady && !_hasError && !_isDisposing) {
        _handleInitializationTimeout();
      }
    });
  }

  void _cancelInitializationTimer() {
    _initializationTimer?.cancel();
    _initializationTimer = null;
  }

  void _handleInitializationTimeout() {
    _forceDisposePlayer();

    if (mounted && !_isDisposing) {
      setState(() {
        _hasError = true;
        _errorMessage = 'Video initialization timed out. Trying next server...';
        _isLoadingNewEpisode = false;
      });
      _tryNextServerOnError();
    }
  }

  void _tryNextServerOnError() {
    if (_availableServers.length > 1 && !_isDisposing) {
      final currentIndex = _availableServers.indexOf(_currentServer!);
      final nextIndex = (currentIndex + 1) % _availableServers.length;

      if (nextIndex != currentIndex) {
        Future.delayed(Duration(seconds: 2), () {
          if (mounted && !_isDisposing) {
            _switchServer(_availableServers[nextIndex]);
          }
        });
      }
    }
  }

  void _playNextEpisode() {
    if (_isDisposing) return;

    final currentIndex = widget.episodes.indexOf(_currentPlayingEpisode!);
    if (currentIndex < widget.episodes.length - 1) {
      final nextEpisode = widget.episodes[currentIndex + 1];
      _playEpisode(nextEpisode);
    }
  }

  void _playEpisode(Episodes episode) {
    if (_currentPlayingEpisode?.episodeID == episode.episodeID ||
        _isDisposing) {
      return;
    }

    _forceDisposePlayer();
    _resetPlayerState();

    if (!_isDisposing && mounted) {
      _clearAnimeSpecificProviders();
    }

    setState(() {
      _currentPlayingEpisode = episode;
      _videoReady = false;
      _videoURL = null;
      _hasError = false;
      _errorMessage = null;
    });

    LibraryBoxFunction.addToLibrary(widget.anime, episode.episodeID);
    LibraryBoxFunction.markLastWatchedEpisode(
      widget.anime.slug,
      episode.episodeNumber,
    );

    Future.delayed(Duration(milliseconds: 300), () {
      if (mounted && !_isDisposing) {
        _loadServersAndStream();
      }
    });
  }

  void _switchServer(Server server) {
    if (_currentServer?.dataID == server.dataID || _isDisposing) return;

    setState(() {
      _videoReady = false;
      _videoURL = null;
      _hasError = false;
    });

    _loadStreamForServer(server);
  }

  void _enableWakelock() async {
    try {
      await WakelockPlus.enable();
    } catch (_) {}
  }

  void _disableWakelock() async {
    try {
      await WakelockPlus.disable();
    } catch (_) {}
  }

  void _forceDisposePlayer() {
    if (_betterPlayerController != null) {
      try {
        _betterPlayerController!.pause();
        _betterPlayerController!.setVolume(0.0);
        _betterPlayerController!.dispose();
      } catch (_) {
      } finally {
        _betterPlayerController = null;
      }
    }
    _disableWakelock();
    _videoURL = null;
    _cancelInitializationTimer();
  }

  Future<void> _stopAndDisposePlayer() async {
    if (_isDisposing) return;
    _isDisposing = true;
    try {
      _cancelInitializationTimer();

      if (_betterPlayerController != null) {
        try {
          await _betterPlayerController!.pause();
          _betterPlayerController!.setVolume(0.0);
        } catch (_) {}

        await Future.delayed(Duration(milliseconds: 100));

        try {
          _betterPlayerController!.dispose();
        } catch (_) {}

        _betterPlayerController = null;
      }

      _disableWakelock();

      if (mounted) {
        setState(() {
          _videoReady = false;
          _videoURL = null;
        });
      }
    } catch (_) {}
  }

  void _showEpisodeInfo() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.blackGradient,
      isScrollControlled: true,
      builder: (context) => Container(
        width: double.infinity,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.4,
        ),
        decoration: BoxDecoration(
          color: AppTheme.blackGradient,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: EdgeInsets.only(top: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.greyGradient,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Episode Information',
                style: TextStyle(
                  color: AppTheme.whiteGradient,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Title: ${_currentPlayingEpisode?.title ?? 'Unknown'}',
                    style: TextStyle(
                      color: AppTheme.whiteGradient,
                      fontSize: 16,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Episode: ${_currentPlayingEpisode?.episodeNumber ?? 'Unknown'}',
                    style: TextStyle(
                      color: AppTheme.whiteGradient,
                      fontSize: 14,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Available Qualities: ${_availableQualities?.length ?? 0}',
                    style: TextStyle(
                      color: AppTheme.whiteGradient,
                      fontSize: 14,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Available Subtitles: ${_availableSubtitles?.length ?? 0}',
                    style: TextStyle(
                      color: AppTheme.whiteGradient,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoPlayer() {
    return Container(
      width: double.infinity,
      height: 250,
      decoration: BoxDecoration(
        color: AppTheme.primaryBlack,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppTheme.gradient1.withValues(alpha: 0.1),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: _betterPlayerController != null && _videoReady && !_isDisposing
            ? BetterPlayer(controller: _betterPlayerController!)
            : Container(
                color: AppTheme.primaryBlack,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(color: AppTheme.gradient1),
                      SizedBox(height: 16),
                      Text(
                        _betterPlayerController != null
                            ? 'Initializing player...'
                            : 'Loading video...',
                        style: TextStyle(
                          color: AppTheme.whiteGradient,
                          fontSize: 14,
                        ),
                      ),
                      if (_currentServer != null) ...[
                        SizedBox(height: 8),
                        Text(
                          'Server: ${_currentServer!.serverName}',
                          style: TextStyle(
                            color: AppTheme.whiteGradient.withValues(
                              alpha: 0.7,
                            ),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildServersList() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(left: 15, bottom: 10),
            child: Text(
              'Available Servers',
              style: TextStyle(
                color: AppTheme.gradient1,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          SizedBox(
            height: 80,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _availableServers.length,
              itemBuilder: (context, index) {
                final server = _availableServers[index];
                final isSelected = _currentServer?.dataID == server.dataID;

                return Container(
                  margin: EdgeInsets.only(right: 10),
                  child: InkWell(
                    onTap: () => _switchServer(server),
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppTheme.gradient1
                            : AppTheme.primaryBlack,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isSelected
                              ? AppTheme.gradient1
                              : AppTheme.gradient1.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.play_circle_fill_rounded,
                            color: isSelected
                                ? AppTheme.whiteGradient
                                : AppTheme.gradient1,
                            size: 20,
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Server ${index + 1}',
                            style: TextStyle(
                              color: isSelected
                                  ? AppTheme.whiteGradient
                                  : AppTheme.gradient1,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            server.type.toUpperCase(),
                            style: TextStyle(
                              color: isSelected
                                  ? AppTheme.whiteGradient.withValues(
                                      alpha: 0.8,
                                    )
                                  : AppTheme.gradient1.withValues(alpha: 0.7),
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEpisodesList() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 15),
      padding: EdgeInsets.only(top: 10),
      decoration: BoxDecoration(
        border: Border.all(color: AppTheme.gradient1, width: 0.5),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(left: 15, bottom: 10),
            child: Text(
              'All Episodes',
              style: TextStyle(
                color: AppTheme.gradient1,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Container(
            height: 225,
            padding: EdgeInsets.all(10),
            child: GridView.builder(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                childAspectRatio: 2,
              ),
              itemCount: widget.episodes.length,
              itemBuilder: (context, index) {
                final episode = widget.episodes[index];
                final isCurrentEpisode =
                    _currentPlayingEpisode?.episodeID == episode.episodeID;

                return InkWell(
                  onTap: () => _playEpisode(episode),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isCurrentEpisode
                          ? AppTheme.gradient1
                          : AppTheme.whiteGradient,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isCurrentEpisode
                            ? AppTheme.gradient1
                            : AppTheme.gradient1.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Center(
                      child: Text(
                        'EP ${episode.episodeNumber}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isCurrentEpisode
                              ? AppTheme.whiteGradient
                              : AppTheme.primaryBlack,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingStep(String label, bool isActive, bool isCompleted) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isCompleted
                ? AppTheme.primaryGreen
                : isActive
                ? AppTheme.gradient1
                : AppTheme.whiteGradient.withValues(alpha: 0.3),
          ),
          child: isCompleted
              ? Icon(Icons.check, color: AppTheme.whiteGradient, size: 14)
              : isActive
              ? SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(
                    color: AppTheme.whiteGradient,
                    strokeWidth: 2,
                  ),
                )
              : null,
        ),
        SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: isCompleted || isActive
                  ? AppTheme.whiteGradient
                  : AppTheme.whiteGradient.withValues(alpha: 0.5),
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isDisposing) {
      return Scaffold(
        backgroundColor: AppTheme.primaryBlack,
        body: Center(
          child: CircularProgressIndicator(color: AppTheme.gradient1),
        ),
      );
    }

    ref.watch(serversViewModelProvider(widget.anime.slug));
    ref.watch(sourcesViewModelProvider);
    final vidSrcSource = ref.watch(vidSrcSourcesProvider(_stableCacheKey));

    if (_hasError) {
      return Scaffold(
        backgroundColor: AppTheme.primaryBlack,
        appBar: AppBar(
          backgroundColor: AppTheme.primaryBlack,
          title: Text(
            'Video Player',
            style: TextStyle(color: AppTheme.gradient1),
          ),
          leading: IconButton(
            icon: Icon(Icons.arrow_back_ios, color: AppTheme.gradient1),
            onPressed: () {
              _stopAndDisposePlayer();
              if (mounted) {
                Navigator.pop(context);
              }
            },
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, color: AppTheme.gradient1, size: 64),
              SizedBox(height: 16),
              Text(
                'Video Error',
                style: TextStyle(
                  color: AppTheme.gradient1,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  _errorMessage ?? 'An unknown error occurred',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppTheme.gradient1, fontSize: 16),
                ),
              ),
              SizedBox(height: 24),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.gradient1,
                  foregroundColor: AppTheme.whiteGradient,
                ),
                onPressed: () {
                  setState(() {
                    _hasError = false;
                    _errorMessage = null;
                    _videoReady = false;
                    _isDisposing = false;
                  });
                  ref.invalidate(vidSrcSourcesProvider);
                  _loadServersAndStream();
                },
                icon: Icon(Icons.refresh),
                label: Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, Object? result) {
        if (!didPop && !_isDisposing) {
          _stopAndDisposePlayer();
          if (mounted) {
            Navigator.pop(context);
          }
        }
      },
      child: Scaffold(
        backgroundColor: AppTheme.primaryBlack,
        appBar: AppBar(
          backgroundColor: AppTheme.primaryBlack,
          title: Text(
            _currentPlayingEpisode?.title ?? 'Video Player',
            style: TextStyle(color: AppTheme.whiteGradient),
            overflow: TextOverflow.ellipsis,
          ),
          leading: IconButton(
            icon: Icon(Icons.arrow_back_ios, color: AppTheme.gradient1),
            onPressed: () {
              if (!_isDisposing) {
                _stopAndDisposePlayer();
                if (mounted) {
                  Navigator.pop(context);
                }
              }
            },
          ),
          actions: [
            IconButton(
              icon: Icon(Icons.info_outline, color: AppTheme.whiteGradient),
              onPressed: _showEpisodeInfo,
            ),
          ],
        ),
        body: SafeArea(
          child: _isLoadingNewEpisode
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 250,
                        child: Column(
                          children: [
                            _buildLoadingStep(
                              'Loading servers',
                              _isLoadingServers,
                              !_isLoadingServers,
                            ),
                            SizedBox(height: 8),
                            _buildLoadingStep(
                              'Loading sources',
                              _isLoadingSources,
                              !_isLoadingSources && !_isLoadingServers,
                            ),
                            SizedBox(height: 8),
                            _buildLoadingStep(
                              'Preparing stream',
                              _isLoadingVidSrc,
                              !_isLoadingVidSrc &&
                                  !_isLoadingSources &&
                                  !_isLoadingServers,
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 24),
                      CircularProgressIndicator(color: AppTheme.gradient1),
                      SizedBox(height: 16),
                      Text(
                        _loadingMessage,
                        style: TextStyle(
                          color: AppTheme.whiteGradient,
                          fontSize: 16,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 8),
                      if (_currentServer != null)
                        Text(
                          'Server: ${_currentServer!.serverName} (${_currentServer!.type})',
                          style: TextStyle(
                            color: AppTheme.whiteGradient.withValues(
                              alpha: 0.7,
                            ),
                            fontSize: 12,
                          ),
                        ),
                      SizedBox(height: 4),
                      Text(
                        'Episode ${_currentPlayingEpisode?.episodeNumber ?? ''}',
                        style: TextStyle(
                          color: AppTheme.whiteGradient.withValues(alpha: 0.7),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                )
              : Builder(
                  builder: (context) {
                    if (vidSrcSource.hasValue && vidSrcSource.value != null) {
                      final stream = vidSrcSource.value!;
                      _availableQualities = stream.sources;

                      if (stream.sources.isNotEmpty &&
                          !_videoReady &&
                          !_isDisposing) {
                        final newVideoURL = stream.sources.first.fileURL;
                        if (_videoURL != newVideoURL) {
                          _videoURL = newVideoURL;
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            if (!_isDisposing) {
                              _setupBetterPlayer(_videoURL!, stream.captions);
                            }
                          });
                        }
                      }

                      return SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Padding(
                              padding: EdgeInsets.all(15),
                              child: _buildVideoPlayer(),
                            ),
                            SizedBox(height: 20),
                            _buildServersList(),
                            SizedBox(height: 20),
                            _buildEpisodesList(),
                            SizedBox(height: 100),
                          ],
                        ),
                      );
                    } else if (vidSrcSource.hasError) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.error_outline,
                              color: AppTheme.gradient1,
                              size: 64,
                            ),
                            SizedBox(height: 16),
                            Text(
                              'Failed to load video',
                              style: TextStyle(
                                color: AppTheme.whiteGradient,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 24),
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.gradient1,
                                foregroundColor: AppTheme.whiteGradient,
                              ),
                              onPressed: () {
                                ref.invalidate(vidSrcSourcesProvider);
                                _loadServersAndStream();
                              },
                              icon: Icon(Icons.refresh),
                              label: Text('Retry'),
                            ),
                          ],
                        ),
                      );
                    } else {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Shimmer.fromColors(
                              baseColor: Colors.grey[800]!,
                              highlightColor: AppTheme.gradient1.withValues(
                                alpha: 0.3,
                              ),
                              child: Icon(
                                Icons.movie,
                                size: 80,
                                color: AppTheme.whiteGradient,
                              ),
                            ),
                            SizedBox(height: 24),
                            Shimmer.fromColors(
                              baseColor: Colors.grey[800]!,
                              highlightColor: AppTheme.gradient1.withValues(
                                alpha: 0.3,
                              ),
                              child: Text(
                                'Loading video sources...',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.whiteGradient,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }
                  },
                ),
        ),
      ),
    );
  }
}
