import 'dart:async';
import 'package:shinobihaven/features/anime/common/model/anime.dart';
import 'package:shinobihaven/features/anime/episodes/model/episodes.dart';

class PlayerState {
  final Anime anime;
  final List<Episodes> episodes;
  final Episodes currentEpisode;
  final String? serverId;

  PlayerState({
    required this.anime,
    required this.episodes,
    required this.currentEpisode,
    this.serverId,
  });
}

class PlayerService {
  static final PlayerService _instance = PlayerService._internal();
  factory PlayerService() => _instance;
  PlayerService._internal();

  PlayerState? _currentState;
  PlayerState? get currentState => _currentState;

  final _stopController = StreamController<void>.broadcast();
  final _playController = StreamController<void>.broadcast();
  final _pauseController = StreamController<void>.broadcast();
  final _seekController = StreamController<Duration>.broadcast();

  Stream<void> get onStopRequested => _stopController.stream;
  Stream<void> get onPlayRequested => _playController.stream;
  Stream<void> get onPauseRequested => _pauseController.stream;
  Stream<Duration> get onSeekRequested => _seekController.stream;

  void setActivePlayer(PlayerState state) {
    _currentState = state;
  }

  void clearActivePlayer() {
    _currentState = null;
  }

  void requestStop() {
    _stopController.add(null);
    clearActivePlayer();
  }

  void requestPlay() => _playController.add(null);
  void requestPause() => _pauseController.add(null);
  void requestSeek(Duration offset) => _seekController.add(offset);
}
