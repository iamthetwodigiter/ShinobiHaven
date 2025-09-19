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
  final String? serverID; // Add optional serverID parameter

  const SourcesPage({
    super.key,
    required this.anime,
    required this.episodes,
    required this.currentEpisode,
    this.serverID, // Make it optional
  });

  @override
  ConsumerState<SourcesPage> createState() => _SourcesPageState();
}

class _SourcesPageState extends ConsumerState<SourcesPage> {
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

  @override
  void initState() {
    super.initState();
    _currentPlayingEpisode = widget.currentEpisode;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadServersAndStream();
    });
  }

  void _loadServersAndStream() async {
    setState(() {
      _isLoadingNewEpisode = true;
      _hasError = false;
      _isLoadingServers = true;
      _loadingMessage = 'Loading servers...';
    });

    try {
      // Load servers for the current episode
      await ref
          .read(serversViewModelProvider.notifier)
          .fetchServers(_currentPlayingEpisode!.episodeID);

      setState(() {
        _isLoadingServers = false;
        _loadingMessage = 'Finding compatible servers...';
      });

      final serversState = ref.read(serversViewModelProvider);

      if (serversState.hasValue) {
        final servers = serversState.value!;

        // Get all MegaCloud servers (both sub and dub)
        final filteredSubServers = servers.sub
            .where((server) => server.serverName == 'MegaCloud')
            .toList();
        final filteredDubServers = servers.dub
            .where((server) => server.serverName == 'MegaCloud')
            .toList();

        _availableServers = [...filteredSubServers, ...filteredDubServers];

        if (_availableServers.isNotEmpty) {
          // If serverID is provided, use that server, otherwise use the first one
          if (widget.serverID != null) {
            _currentServer = _availableServers.firstWhere(
              (server) => server.dataID == widget.serverID,
              orElse: () => _availableServers.first,
            );
          } else {
            _currentServer = _availableServers.first;
          }

          await _loadStreamForServer(_currentServer!);
        } else {
          setState(() {
            _hasError = true;
            _errorMessage = 'No compatible servers found';
            _isLoadingNewEpisode = false;
          });
        }
      }
    } catch (e) {
      setState(() {
        _hasError = true;
        _errorMessage = 'Failed to load servers: $e';
        _isLoadingNewEpisode = false;
        _isLoadingServers = false;
        _isLoadingSources = false;
        _isLoadingVidSrc = false;
      });
    }
  }

  Future<void> _loadStreamForServer(Server server) async {
    try {
      setState(() {
        _currentServer = server;
        _isLoadingSources = true;
        _loadingMessage = 'Loading video sources for ${server.serverName}...';
      });

      // Clear previous provider state
      ref.invalidate(vidSrcSourcesProvider);

      await ref
          .read(sourcesViewModelProvider.notifier)
          .getSources(server.dataID);

      setState(() {
        _isLoadingSources = false;
        _isLoadingVidSrc = true;
        _loadingMessage = 'Preparing video stream...';
      });

      final sourcesState = ref.read(sourcesViewModelProvider);

      if (sourcesState.hasError) {
        setState(() {
          _hasError = true;
          _errorMessage = 'Failed to load video sources for this server';
          _isLoadingNewEpisode = false;
          _isLoadingVidSrc = false;
        });
        return;
      }

      final sources = sourcesState.value;
      if (sources != null) {
        print(
          'DEBUG: Calling getVidSrcSources with dataID: ${sources.dataID}, key: ${sources.key}',
        );

        await ref
            .read(vidSrcSourcesProvider.notifier)
            .getVidSrcSources(sources.dataID, sources.key);

        // Add a small delay to ensure provider state updates
        await Future.delayed(Duration(milliseconds: 500));

        final vidSrcState = ref.read(vidSrcSourcesProvider);
        print(
          'DEBUG: VidSrc state after call - hasValue: ${vidSrcState.hasValue}, hasError: ${vidSrcState.hasError}',
        );
      } else {
        throw Exception('Sources data is null');
      }

      setState(() {
        _isLoadingVidSrc = false;
        _isLoadingNewEpisode = false;
        _loadingMessage = 'Initializing player...';
      });
    } catch (e) {
      setState(() {
        _hasError = true;
        _errorMessage = 'Network error: ${e.toString()}';
        _isLoadingNewEpisode = false;
        _isLoadingSources = false;
        _isLoadingVidSrc = false;
      });
    }
  }

  Future<void> _setupBetterPlayer(
    String videoUrl,
    List<Captions> captions,
  ) async {
    try {
      print('DEBUG: Setting up player with URL: $videoUrl');

      // Validate URL first
      if (!videoUrl.startsWith('http') || !videoUrl.contains('m3u8')) {
        throw Exception('Invalid video URL format');
      }

      _availableSubtitles = captions;

      // Dispose previous controller properly
      if (_betterPlayerController != null) {
        print('DEBUG: Disposing previous controller');
        await _betterPlayerController!.pause();
        _betterPlayerController!.dispose();
        _betterPlayerController = null;
        await Future.delayed(Duration(milliseconds: 300));
      }

      print('DEBUG: Creating new BetterPlayerController');

      // Simplified data source configuration
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
        // Remove resolutions for now to simplify
      );

      // Simplified BetterPlayer configuration
      _betterPlayerController = BetterPlayerController(
        BetterPlayerConfiguration(
          autoPlay: true,
          looping: false,
          fit: BoxFit.contain,
          aspectRatio: 16 / 9,
          handleLifecycle: true,
          autoDispose: false, // Disable auto dispose to prevent issues
          // Simplified buffering configuration
          // bufferingConfiguration: BetterPlayerBufferingConfiguration(
          //   minBufferMs: 15000,
          //   maxBufferMs: 50000,
          //   bufferForPlaybackMs: 2500,
          //   bufferForPlaybackAfterRebufferMs: 5000,
          // ),

          // Simplified controls
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

            // Styling
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
          ),

          // Simplified subtitles
          subtitlesConfiguration: BetterPlayerSubtitlesConfiguration(
            fontSize: 16,
            fontColor: AppTheme.whiteGradient,
            outlineEnabled: true,
            outlineColor: AppTheme.blackGradient,
            outlineSize: 2,
          ),

          // Enhanced event listener
          eventListener: (BetterPlayerEvent event) {
            print('DEBUG: BetterPlayer Event: ${event.betterPlayerEventType}');

            if (!mounted) return;

            switch (event.betterPlayerEventType) {
              case BetterPlayerEventType.initialized:
                print('DEBUG: Player initialized successfully');
                if (mounted) {
                  setState(() {
                    _videoReady = true;
                    _hasError = false;
                    _isLoadingNewEpisode = false;
                  });
                  _enableWakelock();
                }
                break;

              case BetterPlayerEventType.play:
                print('DEBUG: Player started playing');
                _enableWakelock();
                break;

              case BetterPlayerEventType.finished:
                print('DEBUG: Player finished');
                _disableWakelock();
                _playNextEpisode();
                break;

              case BetterPlayerEventType.exception:
                print('DEBUG: Player exception: ${event.parameters}');
                if (mounted) {
                  setState(() {
                    _hasError = true;
                    _errorMessage =
                        'Video playback error. Trying next server...';
                    _isLoadingNewEpisode = false;
                  });
                  _disableWakelock();
                  // Auto try next server on exception
                  _tryNextServerOnError();
                }
                break;

              case BetterPlayerEventType.bufferingStart:
                print('DEBUG: Buffering started');
                break;

              case BetterPlayerEventType.bufferingEnd:
                print('DEBUG: Buffering ended');
                break;

              default:
                break;
            }
          },
        ),
        betterPlayerDataSource: dataSource,
      );

      // Reduced timeout and add retry mechanism
      Timer(Duration(seconds: 15), () {
        if (mounted &&
            !_videoReady &&
            !_hasError &&
            _betterPlayerController != null) {
          print(
            'DEBUG: Player initialization timeout - trying alternative approach',
          );
          _handleInitializationTimeout();
        }
      });

      print('DEBUG: BetterPlayerController created successfully');
    } catch (e) {
      print('DEBUG: Error in _setupBetterPlayer: $e');
      if (mounted) {
        setState(() {
          _hasError = true;
          _errorMessage = 'Failed to setup video player. Trying next server...';
          _isLoadingNewEpisode = false;
        });
        _tryNextServerOnError();
      }
    }
  }

  // Add these helper methods:
  void _handleInitializationTimeout() {
    print('DEBUG: Handling initialization timeout');
    if (_betterPlayerController != null) {
      _betterPlayerController!.dispose();
      _betterPlayerController = null;
    }

    setState(() {
      _hasError = true;
      _errorMessage = 'Video initialization timed out. Trying next server...';
      _isLoadingNewEpisode = false;
    });

    _tryNextServerOnError();
  }

  void _tryNextServerOnError() {
    if (_availableServers.length > 1) {
      final currentIndex = _availableServers.indexOf(_currentServer!);
      final nextIndex = (currentIndex + 1) % _availableServers.length;

      // Don't try the same server again
      if (nextIndex != currentIndex) {
        print('DEBUG: Auto-switching to next server');
        Future.delayed(Duration(seconds: 2), () {
          if (mounted) {
            _switchServer(_availableServers[nextIndex]);
          }
        });
      }
    }
  }

  void _playNextEpisode() {
    final currentIndex = widget.episodes.indexOf(_currentPlayingEpisode!);
    if (currentIndex < widget.episodes.length - 1) {
      final nextEpisode = widget.episodes[currentIndex + 1];
      _playEpisode(nextEpisode);
    }
  }

  void _playEpisode(Episodes episode) {
    if (_currentPlayingEpisode?.episodeID == episode.episodeID) return;

    setState(() {
      _currentPlayingEpisode = episode;
      _videoReady = false;
      _videoURL = null;
    });

    // Add to library
    LibraryBoxFunction.addToLibrary(widget.anime, episode.episodeID);

    // Load servers and stream for new episode
    _loadServersAndStream();
  }

  void _switchServer(Server server) {
    if (_currentServer?.dataID == server.dataID) return;

    print(
      'DEBUG: Switching to server: ${server.serverName} (${server.dataID})',
    );

    setState(() {
      _videoReady = false;
      _videoURL = null;
      _hasError = false; // Reset error state
    });

    _loadStreamForServer(server);
  }

  void _enableWakelock() async {
    await WakelockPlus.enable();
  }

  void _disableWakelock() async {
    await WakelockPlus.disable();
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
        child: _betterPlayerController != null && _videoReady
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
          Container(
            height: 80, // Increased height to show server type
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
            height: 200,
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

  Future<void> _stopAndDisposePlayer() async {
    if (_betterPlayerController != null) {
      await _betterPlayerController!.pause();
      _betterPlayerController!.dispose();
      _betterPlayerController = null;
    }
    _disableWakelock();
  }

  @override
  void dispose() {
    _stopAndDisposePlayer();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vidSrcSource = ref.watch(vidSrcSourcesProvider);

    // Add debug logging for provider state
    print(
      'DEBUG: Provider state - hasValue: ${vidSrcSource.hasValue}, hasError: ${vidSrcSource.hasError}, isLoading: ${vidSrcSource.isLoading}',
    );

    if (vidSrcSource.hasValue) {
      print('DEBUG: Provider has value: ${vidSrcSource.value}');
    }

    if (vidSrcSource.hasError) {
      print('DEBUG: Provider has error: ${vidSrcSource.error}');
    }

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
              Navigator.pop(context);
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
                  });
                  // Clear the provider state
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
        if (!didPop) {
          _stopAndDisposePlayer();
          Navigator.pop(context);
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
            icon: Icon(Icons.arrow_back_ios, color: AppTheme.whiteGradient),
            onPressed: () {
              _stopAndDisposePlayer();
              Navigator.pop(context);
            },
          ),
          actions: [
            if (_videoReady)
              IconButton(
                icon: Icon(Icons.info_outline, color: AppTheme.whiteGradient),
                onPressed: _showEpisodeInfo,
              ),
            // Add debug info button
            if (_currentServer != null)
              IconButton(
                icon: Icon(Icons.bug_report, color: AppTheme.whiteGradient),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Current Server: ${_currentServer!.serverName} (${_currentServer!.type}) - ID: ${_currentServer!.dataID}\nProvider State: hasValue=${vidSrcSource.hasValue}, hasError=${vidSrcSource.hasError}, isLoading=${vidSrcSource.isLoading}',
                      ),
                      duration: Duration(seconds: 5),
                    ),
                  );
                },
              ),
            // Add force refresh button
            IconButton(
              icon: Icon(Icons.refresh, color: AppTheme.whiteGradient),
              onPressed: () {
                print('DEBUG: Force refreshing provider');
                ref.invalidate(vidSrcSourcesProvider);
                setState(() {
                  _videoReady = false;
                  _videoURL = null;
                });
              },
            ),
          ],
        ),
        body: SafeArea(
          child: _isLoadingNewEpisode
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Progress indicator with steps
                      Container(
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
                    // Use Builder to handle provider state properly
                    if (vidSrcSource.hasValue && vidSrcSource.value != null) {
                      final stream = vidSrcSource.value!;
                      print(
                        'DEBUG: Building UI with stream data: ${stream.sources.length} sources',
                      );

                      _availableQualities = stream.sources;

                      // Only setup player if URL changed and video is not ready
                      if (_videoURL != stream.sources.first.fileURL &&
                          !_videoReady) {
                        _videoURL = stream.sources.first.fileURL;
                        print(
                          'DEBUG: Setting up player with new URL: $_videoURL',
                        );
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          _setupBetterPlayer(_videoURL!, stream.captions);
                        });
                      }

                      // Show the UI
                      return SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
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
                      print('DEBUG: VidSrc error: ${vidSrcSource.error}');
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
                            SizedBox(height: 8),
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 32),
                              child: Text(
                                'Error: ${vidSrcSource.error.toString()}',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: AppTheme.whiteGradient,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            SizedBox(height: 8),
                            if (_currentServer != null)
                              Text(
                                'Server: ${_currentServer!.serverName} (${_currentServer!.dataID})',
                                style: TextStyle(
                                  color: AppTheme.whiteGradient.withValues(
                                    alpha: 0.7,
                                  ),
                                  fontSize: 12,
                                ),
                              ),
                            SizedBox(height: 24),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
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
                                if (_availableServers.length > 1) ...[
                                  SizedBox(width: 16),
                                  ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppTheme.gradient2,
                                      foregroundColor: AppTheme.whiteGradient,
                                    ),
                                    onPressed: () {
                                      // Try next server
                                      final currentIndex = _availableServers
                                          .indexOf(_currentServer!);
                                      final nextIndex =
                                          (currentIndex + 1) %
                                          _availableServers.length;
                                      _switchServer(
                                        _availableServers[nextIndex],
                                      );
                                    },
                                    icon: Icon(Icons.skip_next),
                                    label: Text('Try Next Server'),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      );
                    } else {
                      // Still loading or no data
                      print('DEBUG: VidSrc still loading or no data...');
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
                            SizedBox(height: 16),
                            Text(
                              'Provider State: ${vidSrcSource.isLoading ? "Loading" : "Unknown"}',
                              style: TextStyle(
                                color: AppTheme.whiteGradient.withValues(
                                  alpha: 0.7,
                                ),
                                fontSize: 12,
                              ),
                            ),
                            SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () {
                                print(
                                  'DEBUG: Manual provider refresh triggered',
                                );
                                ref.invalidate(vidSrcSourcesProvider);
                                setState(() {});
                              },
                              child: Text('Force Refresh'),
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

  Widget _buildLoadingStep(String label, bool isActive, bool isCompleted) {
    return Row(
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
}
