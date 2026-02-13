import 'dart:async';
import 'dart:developer';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:audio_session/audio_session.dart';
import 'package:the_news/model/podcast_model.dart';
import 'package:the_news/service/podcast_service.dart';

/// Playback state for the podcast player
enum PodcastPlaybackState {
  idle,
  loading,
  playing,
  paused,
  completed,
  error,
}

/// Service for managing podcast audio playback
/// Singleton pattern following GEMINI.md rules
class PodcastPlayerService extends ChangeNotifier {
  static final PodcastPlayerService instance = PodcastPlayerService._init();
  PodcastPlayerService._init() {
    _initPlayer();
  }

  final AudioPlayer _player = AudioPlayer();
  final PodcastService _podcastService = PodcastService.instance;

  // Current state
  Episode? _currentEpisode;
  Podcast? _currentPodcast;
  PodcastPlaybackState _playbackState = PodcastPlaybackState.idle;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  double _playbackSpeed = 1.0;
  bool _isBuffering = false;
  String? _error;

  // Sleep timer
  Timer? _sleepTimer;
  Duration? _sleepTimerRemaining;

  // Progress save timer
  Timer? _progressSaveTimer;

  // Stream subscriptions
  StreamSubscription<PlayerState>? _playerStateSubscription;
  StreamSubscription<Duration?>? _positionSubscription;
  StreamSubscription<Duration?>? _durationSubscription;
  StreamSubscription<bool>? _bufferingSubscription;

  // Getters
  Episode? get currentEpisode => _currentEpisode;
  Podcast? get currentPodcast => _currentPodcast;
  PodcastPlaybackState get playbackState => _playbackState;
  Duration get position => _position;
  Duration get duration => _duration;
  double get playbackSpeed => _playbackSpeed;
  bool get isBuffering => _isBuffering;
  String? get error => _error;
  bool get isPlaying => _playbackState == PodcastPlaybackState.playing;
  bool get hasEpisode => _currentEpisode != null;
  Duration? get sleepTimerRemaining => _sleepTimerRemaining;

  /// Progress as a value between 0.0 and 1.0
  double get progress {
    if (_duration.inMilliseconds == 0) return 0.0;
    return _position.inMilliseconds / _duration.inMilliseconds;
  }

  /// Initialize audio player
  Future<void> _initPlayer() async {
    try {
      // Configure audio session
      final session = await AudioSession.instance;
      await session.configure(const AudioSessionConfiguration.speech());

      // Listen to player state changes
      _playerStateSubscription = _player.playerStateStream.listen((state) {
        _handlePlayerState(state);
      });

      // Listen to position changes
      _positionSubscription = _player.positionStream.listen((position) {
        _position = position;
        notifyListeners();
      });

      // Listen to duration changes
      _durationSubscription = _player.durationStream.listen((duration) {
        _duration = duration ?? Duration.zero;
        notifyListeners();
      });

      // Listen to buffering state
      _bufferingSubscription = _player.bufferedPositionStream.map((buffered) {
        return buffered.inMilliseconds < _position.inMilliseconds + 5000;
      }).listen((isBuffering) {
        _isBuffering = isBuffering;
        notifyListeners();
      });

      log('✅ Podcast player initialized');
    } catch (e) {
      log('❌ Error initializing podcast player: $e');
      _error = e.toString();
    }
  }

  /// Handle player state changes
  void _handlePlayerState(PlayerState state) {
    if (state.processingState == ProcessingState.loading) {
      _playbackState = PodcastPlaybackState.loading;
    } else if (state.processingState == ProcessingState.buffering) {
      _isBuffering = true;
    } else if (state.processingState == ProcessingState.ready) {
      _isBuffering = false;
      if (state.playing) {
        _playbackState = PodcastPlaybackState.playing;
        _startProgressSaveTimer();
      } else {
        _playbackState = PodcastPlaybackState.paused;
        _stopProgressSaveTimer();
      }
    } else if (state.processingState == ProcessingState.completed) {
      _playbackState = PodcastPlaybackState.completed;
      _stopProgressSaveTimer();
      _saveProgress(completed: true);
    } else if (state.processingState == ProcessingState.idle) {
      _playbackState = PodcastPlaybackState.idle;
      _stopProgressSaveTimer();
    }
    notifyListeners();
  }

  /// Play an episode
  Future<bool> playEpisode(Episode episode, {Podcast? podcast}) async {
    try {
      if (episode.audioUrl.isEmpty) {
        _error = 'Audio source unavailable';
        _playbackState = PodcastPlaybackState.error;
        notifyListeners();
        return false;
      }
      _error = null;
      _playbackState = PodcastPlaybackState.loading;
      _currentEpisode = episode;
      _currentPodcast = podcast;
      notifyListeners();

      // Check for existing progress
      final progress = _podcastService.getProgress(episode.id);
      Duration startPosition = Duration.zero;
      if (progress != null && !progress.completed) {
        startPosition = Duration(seconds: progress.progressSeconds);
      }

      // Set audio source
      await _player.setUrl(episode.audioUrl);

      // Seek to last position if resuming
      if (startPosition > Duration.zero) {
        await _player.seek(startPosition);
      }

      // Start playback
      await _player.play();

      log('▶️ Playing: ${episode.title}');
      return true;
    } catch (e) {
      log('❌ Error playing episode: $e');
      _error = e.toString();
      _playbackState = PodcastPlaybackState.error;
      notifyListeners();
      return false;
    }
  }

  /// Pause playback
  Future<void> pause() async {
    try {
      await _player.pause();
      _saveProgress();
      log('⏸️ Paused');
    } catch (e) {
      log('❌ Error pausing: $e');
    }
  }

  /// Resume playback
  Future<void> resume() async {
    try {
      await _player.play();
      log('▶️ Resumed');
    } catch (e) {
      log('❌ Error resuming: $e');
    }
  }

  /// Toggle play/pause
  Future<void> togglePlayPause() async {
    if (isPlaying) {
      await pause();
    } else {
      await resume();
    }
  }

  /// Stop playback
  Future<void> stop() async {
    try {
      _saveProgress();
      await _player.stop();
      _currentEpisode = null;
      _currentPodcast = null;
      _playbackState = PodcastPlaybackState.idle;
      _position = Duration.zero;
      _duration = Duration.zero;
      _cancelSleepTimer();
      notifyListeners();
      log('⏹️ Stopped');
    } catch (e) {
      log('❌ Error stopping: $e');
    }
  }

  /// Seek to position
  Future<void> seek(Duration position) async {
    try {
      await _player.seek(position);
      log('⏩ Seeked to ${position.inSeconds}s');
    } catch (e) {
      log('❌ Error seeking: $e');
    }
  }

  /// Seek forward by seconds
  Future<void> seekForward({int seconds = 30}) async {
    final newPosition = _position + Duration(seconds: seconds);
    final maxPosition = _duration;
    await seek(newPosition > maxPosition ? maxPosition : newPosition);
  }

  /// Seek backward by seconds
  Future<void> seekBackward({int seconds = 10}) async {
    final newPosition = _position - Duration(seconds: seconds);
    await seek(newPosition < Duration.zero ? Duration.zero : newPosition);
  }

  /// Set playback speed
  Future<void> setSpeed(double speed) async {
    try {
      await _player.setSpeed(speed);
      _playbackSpeed = speed;
      notifyListeners();
      log('⏱️ Speed set to ${speed}x');
    } catch (e) {
      log('❌ Error setting speed: $e');
    }
  }

  /// Cycle through common playback speeds
  Future<void> cycleSpeed() async {
    const speeds = [0.5, 0.75, 1.0, 1.25, 1.5, 1.75, 2.0];
    final currentIndex = speeds.indexOf(_playbackSpeed);
    final nextIndex = (currentIndex + 1) % speeds.length;
    await setSpeed(speeds[nextIndex]);
  }

  // ==================== SLEEP TIMER ====================

  /// Set sleep timer
  void setSleepTimer(Duration duration) {
    _cancelSleepTimer();
    _sleepTimerRemaining = duration;
    notifyListeners();

    _sleepTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_sleepTimerRemaining != null) {
        _sleepTimerRemaining = _sleepTimerRemaining! - const Duration(seconds: 1);
        notifyListeners();

        if (_sleepTimerRemaining!.inSeconds <= 0) {
          pause();
          _cancelSleepTimer();
          log('😴 Sleep timer finished');
        }
      }
    });

    log('😴 Sleep timer set for ${duration.inMinutes} minutes');
  }

  /// Cancel sleep timer
  void _cancelSleepTimer() {
    _sleepTimer?.cancel();
    _sleepTimer = null;
    _sleepTimerRemaining = null;
    notifyListeners();
  }

  /// Cancel sleep timer (public)
  void cancelSleepTimer() {
    _cancelSleepTimer();
    log('😴 Sleep timer cancelled');
  }

  // ==================== PROGRESS SAVING ====================

  /// Start periodic progress saving
  void _startProgressSaveTimer() {
    _stopProgressSaveTimer();
    _progressSaveTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _saveProgress();
    });
  }

  /// Stop progress save timer
  void _stopProgressSaveTimer() {
    _progressSaveTimer?.cancel();
    _progressSaveTimer = null;
  }

  /// Save current progress
  Future<void> _saveProgress({bool completed = false}) async {
    if (_currentEpisode == null) return;

    final progress = ListeningProgress(
      episodeId: _currentEpisode!.id,
      podcastId: _currentEpisode!.podcastId,
      progressSeconds: _position.inSeconds,
      totalSeconds: _duration.inSeconds,
      lastListenedAt: DateTime.now(),
      completed: completed || _playbackState == PodcastPlaybackState.completed,
    );

    await _podcastService.saveProgress(progress);
  }

  // ==================== UTILITY ====================

  /// Format duration as MM:SS or HH:MM:SS
  String formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  /// Get formatted position string
  String get positionString => formatDuration(_position);

  /// Get formatted duration string
  String get durationString => formatDuration(_duration);

  /// Get formatted remaining time
  String get remainingString {
    final remaining = _duration - _position;
    return '-${formatDuration(remaining)}';
  }

  @override
  void dispose() {
    _playerStateSubscription?.cancel();
    _positionSubscription?.cancel();
    _durationSubscription?.cancel();
    _bufferingSubscription?.cancel();
    _stopProgressSaveTimer();
    _cancelSleepTimer();
    _player.dispose();
    super.dispose();
  }
}
