import 'dart:async';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:shinobihaven/core/theme/app_theme.dart';
import 'package:shinobihaven/features/anime/stream/model/sources.dart';

class LinuxVideoPlayer extends StatefulWidget {
  final String videoUrl;
  final List<Captions>? captions;
  final bool autoPlay;
  final double aspectRatio;
  final VoidCallback? onFinished;
  final Function(String)? onError;

  const LinuxVideoPlayer({
    super.key,
    required this.videoUrl,
    this.captions,
    this.autoPlay = true,
    this.aspectRatio = 16 / 9,
    this.onFinished,
    this.onError,
  });

  @override
  State<LinuxVideoPlayer> createState() => _LinuxVideoPlayerState();
}

class _LinuxVideoPlayerState extends State<LinuxVideoPlayer> {
  late final Player _player;
  late final VideoController _videoController;
  StreamSubscription<bool>? _playingSub;
  StreamSubscription<String?>? _errorSub;
  StreamSubscription<bool>? _completedSub;
  StreamSubscription<Duration>? _positionSub;

  bool _initialized = false;
  bool _showControls = true;
  bool _isPlaying = false;
  Timer? _hideControlsTimer;

  Duration _currentPosition = Duration.zero;
  Duration _totalDuration = Duration.zero;

  List<VideoTrack> _videoTracks = [];
  List<SubtitleTrack> _availableSubtitleTracks = [];
  SubtitleTrack _selectedSubtitleTrack = SubtitleTrack.no();

  @override
  void initState() {
    super.initState();
    _isPlaying = widget.autoPlay;
    _initPlayer();
  }

  Future<void> _initPlayer() async {
    try {
      _player = Player();
      _videoController = VideoController(_player);

      _playingSub = _player.stream.playing.listen((playing) {
        if (mounted) {
          setState(() => _isPlaying = playing);
        }
      });

      _positionSub = _player.stream.position.listen((position) {
        if (mounted) {
          setState(() => _currentPosition = position);
        }
      });

      _player.stream.duration.listen((duration) {
        if (mounted) {
          setState(() => _totalDuration = duration);
        }
      });

      _player.stream.tracks.listen((tracks) {
        if (mounted) {
          setState(() {
            _videoTracks = tracks.video;
          });
        }
      });

      _player.stream.track.listen((track) {
        if (mounted) {
          setState(() {
            _selectedSubtitleTrack = track.subtitle;
          });
        }
      });

      _completedSub = _player.stream.completed.listen((completed) {
        if (completed) {
          if (mounted) {
            setState(() => _isPlaying = false);
          }
          widget.onFinished?.call();
        }
      });

      _errorSub = _player.stream.error.listen((err) {
        if (err.isNotEmpty) {
          widget.onError?.call(err);
        }
      });

      await _player.open(Media(widget.videoUrl), play: widget.autoPlay);
      await _setupSubtitles();

      if (mounted) {
        setState(() => _initialized = true);
      }

      if (_isPlaying) {
        _resetHideControlsTimer();
      }
    } catch (e) {
      widget.onError?.call(e.toString());
    }
  }

  Future<void> _setupSubtitles() async {
    if (widget.captions == null || widget.captions!.isEmpty) return;

    _availableSubtitleTracks = [];

    for (final caption in widget.captions!) {
      try {
        final localFile = await _downloadSubtitleToTemp(caption.link);
        if (localFile != null) {
          final track = SubtitleTrack.uri(
            Uri.file(localFile.path).toString(),
            title: caption.language,
            language: caption.language.toLowerCase(),
          );
          _availableSubtitleTracks.add(track);
        }
      } catch (e) {
        debugPrint(
          '[LinuxVideoPlayer] Failed to load subtitle ${caption.language}: $e',
        );
      }
    }

    if (_availableSubtitleTracks.isNotEmpty) {
      try {
        await _player.setSubtitleTrack(_availableSubtitleTracks.first);
        if (mounted) {
          setState(() {
            _selectedSubtitleTrack = _availableSubtitleTracks.first;
          });
        }
      } catch (e) {
        debugPrint('[LinuxVideoPlayer] Failed to set default subtitle: $e');
      }
    }
  }

  Future<File?> _downloadSubtitleToTemp(String url) async {
    try {
      final resp = await http.get(Uri.parse(url));
      if (resp.statusCode != 200 || resp.body.isEmpty) return null;

      final tmpDir = Directory.systemTemp;
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final extension = url.toLowerCase().contains('.srt') ? 'srt' : 'vtt';
      final tmpFile = File(
        '${tmpDir.path}/shinobihaven_sub_$timestamp.$extension',
      );
      await tmpFile.writeAsBytes(resp.bodyBytes);
      return tmpFile;
    } catch (e) {
      debugPrint('[LinuxVideoPlayer] Subtitle download error: $e');
      return null;
    }
  }

  void _togglePlayPause() {
    if (_isPlaying) {
      _player.pause();
    } else {
      _player.play();
    }
    _resetHideControlsTimer();
  }

  void _seek(Duration position) {
    _player.seek(position);
    _resetHideControlsTimer();
  }

  void _showControlsOverlay() {
    if (mounted) {
      setState(() => _showControls = true);
      _resetHideControlsTimer();
    }
  }

  void _resetHideControlsTimer() {
    _hideControlsTimer?.cancel();
    if (_isPlaying) {
      _hideControlsTimer = Timer(Duration(seconds: 3), () {
        if (mounted && _isPlaying) {
          setState(() => _showControls = false);
        }
      });
    }
  }

  void _showQualityMenu() {
    if (_videoTracks.isEmpty) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.primaryBlack,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Quality',
              style: TextStyle(
                color: AppTheme.whiteGradient,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            ...(_videoTracks.map((track) {
              String displayText = 'Auto';
              if (track.w != null && track.h != null) {
                displayText = '${track.h}p';
              } else if (track.title != null && track.title!.isNotEmpty) {
                displayText = track.title!;
              } else if (track.id.isNotEmpty) {
                displayText = track.id;
              }

              return ListTile(
                leading: Icon(
                  Icons.video_settings,
                  color: AppTheme.whiteGradient,
                ),
                title: Text(
                  displayText,
                  style: TextStyle(color: AppTheme.whiteGradient),
                ),
                onTap: () {
                  _player.setVideoTrack(track);
                  Navigator.pop(context);
                },
              );
            }).toList()),
          ],
        ),
      ),
    );
  }

  void _showSubtitleMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.primaryBlack,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Subtitles',
              style: TextStyle(
                color: AppTheme.whiteGradient,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),

            ListTile(
              leading: Icon(
                _selectedSubtitleTrack == SubtitleTrack.no()
                    ? Icons.check_circle
                    : Icons.circle_outlined,
                color: _selectedSubtitleTrack == SubtitleTrack.no()
                    ? AppTheme.gradient1
                    : AppTheme.whiteGradient,
              ),
              title: Text(
                'Off',
                style: TextStyle(
                  color: _selectedSubtitleTrack == SubtitleTrack.no()
                      ? AppTheme.gradient1
                      : AppTheme.whiteGradient,
                  fontWeight: _selectedSubtitleTrack == SubtitleTrack.no()
                      ? FontWeight.bold
                      : FontWeight.normal,
                ),
              ),
              onTap: () async {
                try {
                  await _player.setSubtitleTrack(SubtitleTrack.no());
                  if (mounted) {
                    setState(() => _selectedSubtitleTrack = SubtitleTrack.no());
                  }
                } catch (e) {
                  debugPrint('[LinuxVideoPlayer] Failed to disable subtitle: $e');
                }
                if (mounted) {
                  // ignore: use_build_context_synchronously
                  Navigator.pop(context);
                }
              },
            ),

            ...(_availableSubtitleTracks.map((track) {
              final isSelected = _selectedSubtitleTrack.title == track.title &&
                  _selectedSubtitleTrack != SubtitleTrack.no();
              return ListTile(
                leading: Icon(
                  isSelected ? Icons.check_circle : Icons.circle_outlined,
                  color: isSelected ? AppTheme.gradient1 : AppTheme.whiteGradient,
                ),
                title: Text(
                  track.title ?? track.language ?? 'Unknown',
                  style: TextStyle(
                    color: isSelected ? AppTheme.gradient1 : AppTheme.whiteGradient,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                onTap: () async {
                  try {
                    await _player.setSubtitleTrack(track);
                    if (mounted) {
                      setState(() => _selectedSubtitleTrack = track);
                    }
                  } catch (e) {
                    debugPrint('[LinuxVideoPlayer] Failed to set subtitle: $e');
                  }
                  if (mounted) {
                    // ignore: use_build_context_synchronously
                    Navigator.pop(context);
                  }
                },
              );
            }).toList()),
          ],
        ),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(duration.inHours);
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return duration.inHours > 0
        ? '$hours:$minutes:$seconds'
        : '$minutes:$seconds';
  }

  @override
  void dispose() {
    _hideControlsTimer?.cancel();
    _playingSub?.cancel();
    _errorSub?.cancel();
    _completedSub?.cancel();
    _positionSub?.cancel();

    try {
      _videoController.player.dispose();
    } catch (_) {}

    try {
      _player.dispose();
    } catch (_) {}

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized) {
      return Container(
        height: 260,
        decoration: BoxDecoration(
          color: AppTheme.primaryBlack,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: CircularProgressIndicator(color: AppTheme.gradient1),
        ),
      );
    }

    final subtitleConfig = SubtitleViewConfiguration(
      style: TextStyle(
        color: AppTheme.whiteGradient,
        fontSize: 16,
        backgroundColor: AppTheme.primaryBlack.withValues(alpha: 0.7),
        fontWeight: FontWeight.bold,
      ),
      textAlign: TextAlign.center,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    );

    return AspectRatio(
      aspectRatio: widget.aspectRatio,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: MouseRegion(
          onHover: (_) => _showControlsOverlay(),
          child: GestureDetector(
            onTap: () {
              setState(() => _showControls = !_showControls);
              if (_showControls) _resetHideControlsTimer();
            },
            child: Stack(
              children: [
                Video(
                  controller: _videoController,
                  subtitleViewConfiguration: subtitleConfig,
                ),

                if (_showControls)
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withValues(alpha: 0.7),
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.7),
                          ],
                        ),
                      ),
                      child: Column(
                        children: [
                          Padding(
                            padding: EdgeInsets.all(8),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                if (_videoTracks.isNotEmpty)
                                  IconButton(
                                    icon: Icon(
                                      Icons.high_quality,
                                      color: AppTheme.whiteGradient,
                                    ),
                                    onPressed: _showQualityMenu,
                                  ),
                                if (_availableSubtitleTracks.isNotEmpty)
                                  IconButton(
                                    icon: Icon(
                                      Icons.subtitles,
                                      color: AppTheme.whiteGradient,
                                    ),
                                    onPressed: _showSubtitleMenu,
                                  ),
                              ],
                            ),
                          ),

                          Spacer(),

                          Center(
                            child: IconButton(
                              iconSize: 64,
                              icon: Icon(
                                _isPlaying
                                    ? Icons.pause_circle_filled
                                    : Icons.play_circle_filled,
                                color: AppTheme.whiteGradient,
                              ),
                              onPressed: _togglePlayPause,
                            ),
                          ),

                          Spacer(),

                          Padding(
                            padding: EdgeInsets.all(8),
                            child: Column(
                              children: [
                                SliderTheme(
                                  data: SliderThemeData(
                                    trackHeight: 3,
                                    thumbShape: RoundSliderThumbShape(
                                      enabledThumbRadius: 6,
                                    ),
                                    overlayShape: RoundSliderOverlayShape(
                                      overlayRadius: 12,
                                    ),
                                  ),
                                  child: Slider(
                                    value: _totalDuration.inMilliseconds > 0
                                        ? _currentPosition.inMilliseconds
                                            .clamp(
                                              0,
                                              _totalDuration.inMilliseconds,
                                            )
                                            .toDouble()
                                        : 0,
                                    max: _totalDuration.inMilliseconds > 0
                                        ? _totalDuration.inMilliseconds.toDouble()
                                        : 1,
                                    activeColor: AppTheme.gradient1,
                                    inactiveColor: AppTheme.whiteGradient
                                        .withValues(alpha: 0.3),
                                    onChanged: (value) {
                                      _seek(Duration(milliseconds: value.toInt()));
                                    },
                                  ),
                                ),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      _formatDuration(_currentPosition),
                                      style: TextStyle(
                                        color: AppTheme.whiteGradient,
                                        fontSize: 12,
                                      ),
                                    ),
                                    Text(
                                      _formatDuration(_totalDuration),
                                      style: TextStyle(
                                        color: AppTheme.whiteGradient,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}