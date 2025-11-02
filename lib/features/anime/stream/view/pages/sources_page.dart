import 'dart:async';
import 'dart:io';
import 'package:better_player_plus/better_player_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shinobihaven/core/theme/app_theme.dart';
import 'package:shinobihaven/core/utils/toast.dart';
import 'package:shinobihaven/features/anime/common/model/anime.dart';
import 'package:shinobihaven/features/anime/episodes/dependency_injection/servers_provider.dart';
import 'package:shinobihaven/features/anime/episodes/model/episodes.dart';
import 'package:shinobihaven/features/anime/episodes/model/servers.dart';
import 'package:shinobihaven/features/anime/stream/dependency_injection/sources_provider.dart';
import 'package:shinobihaven/features/anime/stream/model/sources.dart';
import 'package:shinobihaven/core/utils/library_box_functions.dart';
import 'package:shimmer/shimmer.dart';
import 'package:shinobihaven/features/anime/stream/view/pages/linux_video_player.dart';
import 'package:shinobihaven/features/download/dependency_injection/downloads_provider.dart';
import 'package:shinobihaven/features/download/repository/downloads_repository.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:toastification/toastification.dart';

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
  static const Duration _seekDuration = Duration(seconds: 5);
  bool _showSeekOverlay = false;
  String _seekOverlayText = '';
  Timer? _seekOverlayTimer;
  Timer? _skipOverlayTimer;
  bool _showSkipIntro = false;
  bool _showSkipOutro = false;
  TimeStamps? _currentIntro;
  TimeStamps? _currentOutro;

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
    _cancelSeekOverlay();
    _cancelSkipOverlay();

    try {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    } catch (e, st) {
      debugPrint('[SourcesPage.dispose] SystemChrome error: $e');
      debugPrintStack(stackTrace: st);
    }

    super.dispose();
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

  void _clearAnimeSpecificProviders() {
    if (_isDisposing || !mounted) return;

    try {
      ref.invalidate(serversViewModelProvider);
      ref.invalidate(sourcesViewModelProvider);
      ref.invalidate(vidSrcSourcesProvider);
    } catch (e, st) {
      debugPrint('[SourcesPage._clearAnimeSpecificProviders] error: $e');
      debugPrintStack(stackTrace: st);
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
      } catch (e, st) {
        debugPrint('[SourcesPage._loadServersAndStream] invalidate error: $e');
        debugPrintStack(stackTrace: st);
      }
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

        _availableServers = [...filteredDubServers, ...filteredSubServers];

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
    } catch (e, st) {
      if (mounted && !_isDisposing) {
        setState(() {
          _hasError = true;
          _errorMessage =
              'Unable to load servers. Please check your connection and try again.';
          _isLoadingNewEpisode = false;
          _isLoadingServers = false;
        });
        debugPrint('[_loadServersAndStream] error: $e');
        debugPrintStack(stackTrace: st);
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
        } catch (e, st) {
          debugPrint('[SourcesPage._loadStreamForServer] invalidate error: $e');
          debugPrintStack(stackTrace: st);
        }
        await Future.delayed(Duration(milliseconds: 100));
      }

      if (_isDisposing) return;
      if (mounted) {
        await ref
            .read(sourcesViewModelProvider.notifier)
            .getSources(server.dataID);
      }

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
          } catch (e, st) {
            debugPrint(
              '[SourcesPage._loadStreamForServer] vidSrc invalidate error: $e',
            );
            debugPrintStack(stackTrace: st);
          }
          await Future.delayed(Duration(milliseconds: 100));
        }

        if (_isDisposing || !mounted) return;

        try {
          await ref
              .read(vidSrcSourcesProvider(_stableCacheKey).notifier)
              .getVidSrcSources(sources.dataID, sources.key);
        } catch (e, st) {
          debugPrint(
            '[SourcesPage._loadStreamForServer] getVidSrcSources error: $e',
          );
          debugPrintStack(stackTrace: st);
          rethrow;
        }

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
    } catch (e, st) {
      if (mounted && !_isDisposing) {
        setState(() {
          _hasError = true;
          _errorMessage =
              'Unable to prepare the video stream. Try switching servers or retrying.';
          _isLoadingNewEpisode = false;
          _isLoadingSources = false;
          _isLoadingVidSrc = false;
        });
      }
      debugPrint('[_loadStreamForServer] error: $e');
      debugPrintStack(stackTrace: st);
    }
  }

  void _startSkipOverlayTimer(TimeStamps? intro, TimeStamps? outro) {
    _cancelSkipOverlay();
    _currentIntro = intro;
    _currentOutro = outro;
    if (_betterPlayerController == null) return;

    _skipOverlayTimer = Timer.periodic(Duration(milliseconds: 500), (timer) {
      if (_isDisposing || !mounted || _betterPlayerController == null) {
        timer.cancel();
        return;
      }

      final controller = _betterPlayerController!.videoPlayerController;
      if (controller == null || !controller.value.initialized) return;

      final currentPosition = controller.value.position.inSeconds;
      bool shouldShowIntro = false;
      bool shouldShowOutro = false;

      if (_currentIntro != null &&
          currentPosition >= _currentIntro!.start &&
          currentPosition < _currentIntro!.end) {
        shouldShowIntro = true;
      }

      if (_currentOutro != null &&
          currentPosition >= _currentOutro!.start &&
          currentPosition < _currentOutro!.end) {
        shouldShowOutro = true;
      }

      if (_showSkipIntro != shouldShowIntro ||
          _showSkipOutro != shouldShowOutro) {
        setState(() {
          _showSkipIntro = shouldShowIntro;
          _showSkipOutro = shouldShowOutro;
        });
      }
    });
  }

  Future<void> _handleSkipIntro() async {
    if (_currentIntro == null || _betterPlayerController == null) return;
    try {
      await _betterPlayerController!.seekTo(
        Duration(seconds: _currentIntro!.end),
      );
      setState(() => _showSkipIntro = false);
    } catch (e, st) {
      debugPrint('[SourcesPage._handleSkipIntro] error: $e');
      debugPrintStack(stackTrace: st);
    }
  }

  Future<void> _handleSkipOutro() async {
    if (_currentOutro == null || _betterPlayerController == null) return;
    try {
      await _betterPlayerController!.seekTo(
        Duration(seconds: _currentOutro!.end),
      );
      setState(() => _showSkipOutro = false);
    } catch (e, st) {
      debugPrint('[SourcesPage._handleSkipOutro] error: $e');
      debugPrintStack(stackTrace: st);
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
        notificationConfiguration: BetterPlayerNotificationConfiguration(
          showNotification: true,
          title: widget.anime.title,
          author: _currentPlayingEpisode?.title,
          imageUrl: widget.anime.image,
        ),
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
          allowedScreenSleep: false,

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

            forwardSkipTimeInMilliseconds: _seekDuration.inMilliseconds,
            backwardSkipTimeInMilliseconds: _seekDuration.inMilliseconds,

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
                  final vidSrcState = ref.read(
                    vidSrcSourcesProvider(_stableCacheKey),
                  );
                  if (vidSrcState.hasValue && vidSrcState.value != null) {
                    _startSkipOverlayTimer(
                      vidSrcState.value!.intro,
                      vidSrcState.value!.outro,
                    );
                  }
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
                _cancelSkipOverlay();
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
                  _cancelSkipOverlay();
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
    } catch (e, st) {
      if (mounted && !_isDisposing) {
        setState(() {
          _hasError = true;
          _errorMessage =
              'Video player failed to start. Trying another server.';
          _isLoadingNewEpisode = false;
        });
        debugPrint(
          '[_setupBetterPlayer] error setting up player for $videoUrl: $e',
        );
        debugPrintStack(stackTrace: st);
        _tryNextServerOnError();
      } else {
        debugPrint('[_setupBetterPlayer] non-mounted error: $e');
        debugPrintStack(stackTrace: st);
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
        _errorMessage =
            'Video initialization timed out. Trying another server.';
        _isLoadingNewEpisode = false;
      });
      debugPrint(
        '[_handleInitializationTimeout] initialization timed out for $_videoURL',
      );
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
    } catch (e, st) {
      debugPrint('[SourcesPage._enableWakelock] error: $e');
      debugPrintStack(stackTrace: st);
    }
  }

  void _disableWakelock() async {
    try {
      await WakelockPlus.disable();
    } catch (e, st) {
      debugPrint('[SourcesPage._disableWakelock] error: $e');
      debugPrintStack(stackTrace: st);
    }
  }

  void _forceDisposePlayer() {
    if (_betterPlayerController != null) {
      try {
        _betterPlayerController!.pause();
        _betterPlayerController!.setVolume(0.0);
        _betterPlayerController!.dispose();
      } catch (e, st) {
        debugPrint('[SourcesPage._forceDisposePlayer] dispose error: $e');
        debugPrintStack(stackTrace: st);
      } finally {
        _betterPlayerController = null;
      }
    }
    _disableWakelock();
    _videoURL = null;
    _cancelInitializationTimer();
    _cancelSeekOverlay();
    _cancelSkipOverlay();
  }

  void _cancelSeekOverlay() {
    _seekOverlayTimer?.cancel();
    _seekOverlayTimer = null;
    if (_showSeekOverlay) {
      _showSeekOverlay = false;
      if (mounted) setState(() {});
    }
  }

  void _cancelSkipOverlay() {
    _skipOverlayTimer?.cancel();
    _skipOverlayTimer = null;
    if (_showSkipIntro || _showSkipOutro) {
      _showSkipIntro = false;
      _showSkipOutro = false;
      if (mounted) setState(() {});
    }
  }

  Future<void> _handleDoubleTapSeek(bool forward) async {
    if (_isDisposing || _betterPlayerController == null) return;
    try {
      final videoController = _betterPlayerController!.videoPlayerController;
      final current = videoController?.value.position ?? Duration.zero;
      final total = videoController?.value.duration;

      Duration target = forward
          ? current + _seekDuration
          : current - _seekDuration;
      if (target.isNegative) target = Duration.zero;
      if (total != null && target > total) target = total;

      try {
        await _betterPlayerController!.seekTo(target);
      } catch (e, st) {
        debugPrint('[SourcesPage._handleDoubleTapSeek] seek error: $e');
        debugPrintStack(stackTrace: st);
        try {
          await videoController?.seekTo(target);
        } catch (e2, st2) {
          debugPrint(
            '[SourcesPage._handleDoubleTapSeek] fallback seek error: $e2',
          );
          debugPrintStack(stackTrace: st2);
        }
      }

      _seekOverlayText = (forward
          ? '+${_seekDuration.inSeconds}s'
          : '-${_seekDuration.inSeconds}s');
      _showSeekOverlay = true;
      if (mounted) setState(() {});

      _seekOverlayTimer?.cancel();
      _seekOverlayTimer = Timer(Duration(milliseconds: 900), () {
        _showSeekOverlay = false;
        if (mounted) setState(() {});
      });
    } catch (e, st) {
      debugPrint('[SourcesPage._handleDoubleTapSeek] unexpected error: $e');
      debugPrintStack(stackTrace: st);
    }
  }

  Future<void> _stopAndDisposePlayer() async {
    if (_isDisposing) return;
    _isDisposing = true;
    try {
      _cancelInitializationTimer();
      _cancelSeekOverlay();

      if (_betterPlayerController != null) {
        try {
          await _betterPlayerController!.pause();
          _betterPlayerController!.setVolume(0.0);
        } catch (e, st) {
          debugPrint('[SourcesPage._stopAndDisposePlayer] pause error: $e');
          debugPrintStack(stackTrace: st);
        }

        await Future.delayed(Duration(milliseconds: 100));

        try {
          _betterPlayerController!.dispose();
        } catch (e, st) {
          debugPrint('[SourcesPage._stopAndDisposePlayer] dispose error: $e');
          debugPrintStack(stackTrace: st);
        }

        _betterPlayerController = null;
      }

      _disableWakelock();

      if (mounted) {
        setState(() {
          _videoReady = false;
          _videoURL = null;
        });
      }
    } catch (e, st) {
      debugPrint('[SourcesPage._stopAndDisposePlayer] unexpected error: $e');
      debugPrintStack(stackTrace: st);
    }
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
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                margin: EdgeInsets.only(top: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.greyGradient,
                  borderRadius: BorderRadius.circular(2),
                ),
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
    final size = MediaQuery.sizeOf(context);
    return Container(
      width: Platform.isAndroid || Platform.isIOS
          ? double.infinity
          : size.width * 0.5,
      height: Platform.isAndroid || Platform.isIOS ? 250 : size.height * 0.5,
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
        child: (_videoReady && !_isDisposing)
            ? (Platform.isAndroid || Platform.isIOS)
                  ? (_betterPlayerController != null
                        ? Stack(
                            fit: StackFit.expand,
                            children: [
                              GestureDetector(
                                onDoubleTapDown: (details) {
                                  final box =
                                      context.findRenderObject() as RenderBox;
                                  final localPosition = box.globalToLocal(
                                    details.globalPosition,
                                  );
                                  final boxWidth = box.size.width;

                                  final isLeftSide =
                                      localPosition.dx < boxWidth / 2.5;

                                  _handleDoubleTapSeek(!isLeftSide);
                                },
                                child: BetterPlayer(
                                  controller: _betterPlayerController!,
                                ),
                              ),

                              if (_showSeekOverlay)
                                Positioned.fill(
                                  child: IgnorePointer(
                                    child: Center(
                                      child: Container(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 24,
                                          vertical: 12,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.black87,
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        child: Text(
                                          _seekOverlayText,
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                            decoration: TextDecoration.none,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),

                              // Skip Intro button
                              if (_showSkipIntro)
                                Positioned(
                                  bottom: 80,
                                  right: 16,
                                  child: Material(
                                    color: Colors.transparent,
                                    child: ElevatedButton.icon(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppTheme.gradient1,
                                        foregroundColor: Colors.white,
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 20,
                                          vertical: 12,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                      ),
                                      onPressed: _handleSkipIntro,
                                      icon: Icon(Icons.fast_forward, size: 20),
                                      label: Text(
                                        'Skip Intro',
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),

                              // Skip Outro button
                              if (_showSkipOutro)
                                Positioned(
                                  bottom: 80,
                                  right: 16,
                                  child: Material(
                                    color: Colors.transparent,
                                    child: ElevatedButton.icon(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppTheme.gradient1,
                                        foregroundColor: Colors.white,
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 20,
                                          vertical: 12,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                      ),
                                      onPressed: _handleSkipOutro,
                                      icon: Icon(Icons.fast_forward, size: 20),
                                      label: Text(
                                        'Skip Outro',
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          )
                        : Container(
                            color: AppTheme.primaryBlack,
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  CircularProgressIndicator(
                                    color: AppTheme.gradient1,
                                  ),
                                  SizedBox(height: 16),
                                  Text(
                                    'Initializing player...',
                                    style: TextStyle(
                                      color: AppTheme.whiteGradient,
                                      fontSize: 14,
                                    ),
                                  ),
                                  if (_currentServer != null) ...[
                                    SizedBox(height: 8),
                                    Text(
                                      'Server: ${_currentServer!.serverName} (${_currentServer!.type})',
                                      style: TextStyle(
                                        color: AppTheme.whiteGradient
                                            .withValues(alpha: 0.7),
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ))
                  : LinuxVideoPlayer(
                      videoUrl: _videoURL ?? '',
                      captions: _availableSubtitles,
                      autoPlay: true,
                      aspectRatio: 16 / 9,
                      onFinished: _playNextEpisode,
                      onError: (err) {
                        if (mounted) {
                          setState(() {
                            _hasError = true;
                            _errorMessage =
                                'Video playback error (desktop): $err';
                            _isLoadingNewEpisode = false;
                          });
                        }
                      },
                    )
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
                          'Server: ${_currentServer!.serverName} (${_currentServer!.type})',
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
    final size = MediaQuery.sizeOf(context);
    return Container(
      width: Platform.isAndroid || Platform.isIOS
          ? double.infinity
          : size.width * 0.5,
      margin: EdgeInsets.symmetric(horizontal: 15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(left: 15, bottom: 10, right: 15),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Available Servers',
                  style: TextStyle(
                    color: AppTheme.gradient1,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (_videoReady)
                  if (Platform.isLinux || Platform.isWindows)
                    Container(
                      width: 150,
                      padding: EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppTheme.gradient1),
                      ),
                      child: Wrap(
                        children: [
                          Row(
                            spacing: 5,
                            children: [
                              Icon(
                                Icons.info,
                                color: AppTheme.primaryAmber,
                                size: 15,
                              ),
                              Text(
                                'NOTE',
                                style: TextStyle(
                                  color: AppTheme.primaryAmber,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          Text(
                            'Download feature is not supported on Linux / Windows platforms.',
                            style: TextStyle(
                              color: AppTheme.whiteGradient,
                              fontSize: 12,
                            ),
                            softWrap: true,
                          ),
                        ],
                      ),
                    )
                  else
                    IconButton(
                      icon: Icon(Icons.download, color: AppTheme.gradient1),
                      onPressed: () async {
                        final vidState = ref.read(
                          vidSrcSourcesProvider(_stableCacheKey),
                        );
                        if (!vidState.hasValue || vidState.value == null) {
                          Toast(
                            context: context,
                            title: 'No stream',
                            description: 'Final stream not ready yet',
                            type: ToastificationType.error,
                          );
                          return;
                        }

                        final megaCloudServers = _availableServers
                            .where((s) => s.serverName == 'MegaCloud')
                            .toList();

                        if (megaCloudServers.isEmpty) {
                          Toast(
                            context: context,
                            title: 'No MegaCloud servers',
                            description: 'No downloadable servers available',
                            type: ToastificationType.error,
                          );
                          return;
                        }

                        final selectedServer =
                            await showModalBottomSheet<Server>(
                              context: context,
                              isScrollControlled: true,
                              backgroundColor: AppTheme.blackGradient,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.vertical(
                                  top: Radius.circular(16),
                                ),
                              ),
                              builder: (ctx) {
                                return SafeArea(
                                  child: Container(
                                    width: double.infinity,
                                    padding: EdgeInsets.only(
                                      top: 12,
                                      left: 12,
                                      right: 12,
                                      bottom: 18,
                                    ),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Container(
                                          width: 40,
                                          height: 4,
                                          decoration: BoxDecoration(
                                            color: AppTheme.greyGradient,
                                            borderRadius: BorderRadius.circular(
                                              2,
                                            ),
                                          ),
                                        ),
                                        SizedBox(height: 12),
                                        Align(
                                          alignment: Alignment.centerLeft,
                                          child: Text(
                                            'Choose from a server',
                                            style: TextStyle(
                                              color: AppTheme.gradient1,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                          ),
                                        ),
                                        SizedBox(height: 12),
                                        Row(
                                          children: megaCloudServers.map((s) {
                                            return Expanded(
                                              child: Padding(
                                                padding: EdgeInsets.symmetric(
                                                  horizontal: 6,
                                                ),
                                                child: ElevatedButton(
                                                  style:
                                                      ElevatedButton.styleFrom(
                                                        backgroundColor:
                                                            AppTheme
                                                                .primaryBlack,
                                                        side: BorderSide(
                                                          color: AppTheme
                                                              .gradient1,
                                                        ),
                                                        padding:
                                                            EdgeInsets.symmetric(
                                                              vertical: 12,
                                                            ),
                                                      ),
                                                  onPressed: () =>
                                                      Navigator.of(ctx).pop(s),
                                                  child: Column(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    children: [
                                                      Text(
                                                        s.type.toUpperCase(),
                                                        style: TextStyle(
                                                          color: AppTheme
                                                              .gradient1,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                        ),
                                                      ),
                                                      SizedBox(height: 4),
                                                      Text(
                                                        s.serverName,
                                                        style: TextStyle(
                                                          color: AppTheme
                                                              .whiteGradient
                                                              .withValues(
                                                                alpha: 0.7,
                                                              ),
                                                          fontSize: 12,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            );
                                          }).toList(),
                                        ),
                                        SizedBox(height: 12),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            );

                        if (selectedServer == null) return;

                        showModalBottomSheet<void>(
                          // ignore: use_build_context_synchronously
                          context: context,
                          isDismissible: false,
                          backgroundColor: AppTheme.blackGradient,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.vertical(
                              top: Radius.circular(16),
                            ),
                          ),
                          builder: (ctx) {
                            return SafeArea(
                              child: Container(
                                width: double.infinity,
                                padding: EdgeInsets.symmetric(vertical: 24),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    CircularProgressIndicator(
                                      color: AppTheme.gradient1,
                                    ),
                                    SizedBox(height: 12),
                                    Text(
                                      'Loading qualities...',
                                      style: TextStyle(
                                        color: AppTheme.whiteGradient,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        );

                        final sourcesRepo = ref.read(sourcesRepositoryProvider);
                        List<SourceFile> qualitySources = [];
                        List<HlsVariant> hlsVariants = [];
                        bool isHlsMaster = false;

                        try {
                          final sourcesObj = await sourcesRepo.getSources(
                            selectedServer.dataID,
                          );
                          final vidSrc = await sourcesRepo.getVidSrcSources(
                            sourcesObj.dataID,
                            sourcesObj.key,
                          );

                          if (vidSrc.sources.isNotEmpty) {
                            final master = vidSrc.sources.firstWhere(
                              (s) =>
                                  s.fileURL.toLowerCase().contains('.m3u8') ||
                                  s.type.toLowerCase().contains('hls'),
                              orElse: () => vidSrc.sources.first,
                            );

                            if (master.fileURL.toLowerCase().contains(
                                  '.m3u8',
                                ) ||
                                master.type.toLowerCase().contains('hls')) {
                              isHlsMaster = true;
                              try {
                                hlsVariants = await DownloadsRepository()
                                    .listHlsVariants(master.fileURL);
                              } catch (e, st) {
                                debugPrint(
                                  '[SourcesPage.downloads] listHlsVariants error: $e',
                                );
                                debugPrintStack(stackTrace: st);
                                hlsVariants = [];
                              }
                            } else {
                              qualitySources = vidSrc.sources.toList();
                              qualitySources.sort(
                                (a, b) => _qualityScore(
                                  a,
                                ).compareTo(_qualityScore(b)),
                              );
                            }
                          } else {
                            debugPrint(
                              '[SourcesPage.downloads] vidSrc.sources is empty for server ${selectedServer.dataID}',
                            );
                          }
                        } catch (e, st) {
                          debugPrint(
                            '[SourcesPage.downloads] error fetching sources for server ${selectedServer.dataID}: $e',
                          );
                          debugPrintStack(stackTrace: st);
                        } finally {
                          // ignore: use_build_context_synchronously
                          Navigator.pop(context);
                        }

                        if (isHlsMaster) {
                          final selectedVariant =
                              await showModalBottomSheet<HlsVariant>(
                                // ignore: use_build_context_synchronously
                                context: context,
                                isScrollControlled: true,
                                backgroundColor: AppTheme.blackGradient,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.vertical(
                                    top: Radius.circular(16),
                                  ),
                                ),
                                builder: (ctx) {
                                  final maxHeight =
                                      MediaQuery.of(ctx).size.height * 0.6;
                                  return SafeArea(
                                    child: Container(
                                      width: double.infinity,
                                      constraints: BoxConstraints(
                                        maxHeight: maxHeight,
                                      ),
                                      padding: EdgeInsets.only(
                                        top: 12,
                                        left: 12,
                                        right: 12,
                                        bottom: 12,
                                      ),
                                      child: Column(
                                        children: [
                                          Container(
                                            width: 40,
                                            height: 4,
                                            decoration: BoxDecoration(
                                              color: AppTheme.greyGradient,
                                              borderRadius:
                                                  BorderRadius.circular(2),
                                            ),
                                          ),
                                          SizedBox(height: 12),
                                          Align(
                                            alignment: Alignment.centerLeft,
                                            child: Text(
                                              'Select Quality',
                                              style: TextStyle(
                                                color: AppTheme.gradient1,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                              ),
                                            ),
                                          ),
                                          SizedBox(height: 8),
                                          Expanded(
                                            child: hlsVariants.isEmpty
                                                ? _emptyFormatsWidget(ctx)
                                                : ListView.separated(
                                                    itemCount:
                                                        hlsVariants.length,
                                                    separatorBuilder: (_, __) =>
                                                        Divider(
                                                          color: AppTheme
                                                              .gradient1
                                                              .withValues(
                                                                alpha: 0.12,
                                                              ),
                                                        ),
                                                    itemBuilder: (ctx2, i) {
                                                      final v = hlsVariants[i];
                                                      final title =
                                                          v.resolution ??
                                                          (v.bandwidth != null
                                                              ? '${(v.bandwidth! / 1000).toStringAsFixed(0)} kbps'
                                                              : 'Variant ${i + 1}');
                                                      return ListTile(
                                                        title: Text(
                                                          title,
                                                          style: TextStyle(
                                                            color: AppTheme
                                                                .whiteGradient,
                                                          ),
                                                        ),
                                                        subtitle: Text(
                                                          'HLS media',
                                                          style: TextStyle(
                                                            color: AppTheme
                                                                .whiteGradient
                                                                .withValues(
                                                                  alpha: 0.6,
                                                                ),
                                                          ),
                                                        ),
                                                        onTap: () =>
                                                            Navigator.of(
                                                              ctx,
                                                            ).pop(v),
                                                      );
                                                    },
                                                  ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              );
                          if (selectedVariant == null) return;

                          ref
                              .read(downloadsProvider.notifier)
                              .startDownload(
                                animeSlug: widget.anime.slug,
                                animeTitle: widget.anime.title,
                                episodeId:
                                    _currentPlayingEpisode?.episodeID ?? '',
                                episodeNumber:
                                    _currentPlayingEpisode?.episodeNumber ?? '',
                                title:
                                    _currentPlayingEpisode?.title ??
                                    widget.anime.title,
                                serverId: selectedServer.dataID,
                                url: selectedVariant.uri,
                                posterUrl: widget.anime.image,
                                captions: vidState.value!.captions,
                              );
                        } else {
                          final selectedSource =
                              await showModalBottomSheet<SourceFile>(
                                // ignore: use_build_context_synchronously
                                context: context,
                                isScrollControlled: true,
                                backgroundColor: AppTheme.blackGradient,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.vertical(
                                    top: Radius.circular(16),
                                  ),
                                ),
                                builder: (ctx) {
                                  final maxHeight =
                                      MediaQuery.of(ctx).size.height * 0.6;
                                  return SafeArea(
                                    child: Container(
                                      width: double.infinity,
                                      constraints: BoxConstraints(
                                        maxHeight: maxHeight,
                                      ),
                                      padding: EdgeInsets.only(
                                        top: 12,
                                        left: 12,
                                        right: 12,
                                        bottom: 12,
                                      ),
                                      child: Column(
                                        children: [
                                          Container(
                                            width: 40,
                                            height: 4,
                                            decoration: BoxDecoration(
                                              color: AppTheme.greyGradient,
                                              borderRadius:
                                                  BorderRadius.circular(2),
                                            ),
                                          ),
                                          SizedBox(height: 12),
                                          Align(
                                            alignment: Alignment.centerLeft,
                                            child: Text(
                                              'Select Quality',
                                              style: TextStyle(
                                                color: AppTheme.gradient1,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                              ),
                                            ),
                                          ),
                                          SizedBox(height: 8),
                                          Expanded(
                                            child: qualitySources.isEmpty
                                                ? _emptyFormatsWidget(ctx)
                                                : ListView.separated(
                                                    itemCount:
                                                        qualitySources.length,
                                                    separatorBuilder: (_, __) =>
                                                        Divider(
                                                          color: AppTheme
                                                              .gradient1
                                                              .withValues(
                                                                alpha: 0.12,
                                                              ),
                                                        ),
                                                    itemBuilder: (ctx2, i) {
                                                      final s =
                                                          qualitySources[i];
                                                      final label =
                                                          s.type.isNotEmpty
                                                          ? s.type
                                                          : s.fileURL
                                                                .split('/')
                                                                .last;
                                                      final subtitle =
                                                          s.fileURL.contains(
                                                            '.m3u8',
                                                          )
                                                          ? 'HLS media'
                                                          : s.fileURL;
                                                      return ListTile(
                                                        title: Text(
                                                          label,
                                                          style: TextStyle(
                                                            color: AppTheme
                                                                .whiteGradient,
                                                          ),
                                                        ),
                                                        subtitle: Text(
                                                          subtitle,
                                                          maxLines: 1,
                                                          overflow: TextOverflow
                                                              .ellipsis,
                                                          style: TextStyle(
                                                            color: AppTheme
                                                                .whiteGradient
                                                                .withValues(
                                                                  alpha: 0.6,
                                                                ),
                                                          ),
                                                        ),
                                                        onTap: () =>
                                                            Navigator.of(
                                                              ctx,
                                                            ).pop(s),
                                                      );
                                                    },
                                                  ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              );

                          if (selectedSource == null) return;
                          ref
                              .read(downloadsProvider.notifier)
                              .startDownload(
                                animeSlug: widget.anime.slug,
                                animeTitle: widget.anime.title,
                                episodeId:
                                    _currentPlayingEpisode?.episodeID ?? '',
                                episodeNumber:
                                    _currentPlayingEpisode?.episodeNumber ?? '',
                                title:
                                    _currentPlayingEpisode?.title ??
                                    widget.anime.title,
                                serverId: selectedServer.dataID,
                                url: selectedSource.fileURL,
                                posterUrl: widget.anime.image,
                                captions: vidState.value!.captions,
                              );
                        }
                        Toast(
                          // ignore: use_build_context_synchronously
                          context: context,
                          title: 'Download queued',
                          description:
                              'Episode ${_currentPlayingEpisode?.episodeNumber ?? ''} added to downloads',
                          type: ToastificationType.success,
                        );
                      },
                    ),
              ],
            ),
          ),
          SizedBox(
            height: 80,
            width: 200,
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

  int _qualityScore(SourceFile s) {
    try {
      final t = s.type.toLowerCase();
      final match = RegExp(r'(\d{3,4})p?').firstMatch(t);
      if (match != null) return int.tryParse(match.group(1) ?? '0') ?? 0;
      final resMatch = RegExp(r'(\d{3,4})x(\d{3,4})').firstMatch(s.type);
      if (resMatch != null) return int.tryParse(resMatch.group(2) ?? '0') ?? 0;
      final urlMatch = RegExp(r'(\d{3,4})p').firstMatch(s.fileURL);
      if (urlMatch != null) return int.tryParse(urlMatch.group(1) ?? '0') ?? 0;
    } catch (e, st) {
      debugPrint('[SourcesPage._qualityScore] parse error: $e');
      debugPrintStack(stackTrace: st);
    }
    return 0;
  }

  Widget _emptyFormatsWidget(BuildContext ctx) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.wifi_off, color: AppTheme.gradient1, size: 42),
          SizedBox(height: 8),
          Text(
            'No formats found',
            style: TextStyle(color: AppTheme.whiteGradient),
          ),
          SizedBox(height: 8),
          Text(
            'No downloadable formats could be loaded from this server.',
            style: TextStyle(
              color: AppTheme.whiteGradient.withValues(alpha: 0.6),
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 12),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('Close', style: TextStyle(color: AppTheme.gradient1)),
          ),
        ],
      ),
    );
  }

  Widget _buildEpisodesList() {
    return Container(
      height: Platform.isAndroid || Platform.isIOS ? 200 : null,
      width: Platform.isAndroid || Platform.isIOS ? double.infinity : 400,
      margin: EdgeInsets.fromLTRB(15, 30, 30, 30),
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
          Expanded(
            child: GridView.builder(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: Platform.isAndroid || Platform.isIOS ? 4 : 8,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                childAspectRatio: 2,
              ),
              padding: EdgeInsets.symmetric(horizontal: 10),
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
                          _availableSubtitles = stream.captions;

                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            if (_isDisposing) return;
                            if (Platform.isAndroid || Platform.isIOS) {
                              _setupBetterPlayer(_videoURL!, stream.captions);
                              return;
                            }
                            if (mounted) {
                              setState(() {
                                _videoReady = true;
                                _hasError = false;
                                _isLoadingNewEpisode = false;
                              });
                            }
                          });
                        }
                      }

                      return Platform.isAndroid || Platform.isIOS
                          ? SingleChildScrollView(
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
                            )
                          : Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Column(
                                  children: [
                                    Padding(
                                      padding: EdgeInsets.all(15),
                                      child: _buildVideoPlayer(),
                                    ),
                                    SizedBox(height: 20),
                                    Expanded(child: _buildServersList()),
                                  ],
                                ),
                                SizedBox(height: 20),
                                Expanded(child: _buildEpisodesList()),
                                SizedBox(height: 100),
                              ],
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
