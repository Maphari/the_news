import 'dart:developer';
import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:the_news/service/auth_service.dart';
import 'package:the_news/service/experience_service.dart';

/// Service for managing Text-to-Speech functionality
/// Provides article narration with playback controls
class TextToSpeechService extends ChangeNotifier {
  static final TextToSpeechService instance = TextToSpeechService._init();
  TextToSpeechService._init();

  final FlutterTts _flutterTts = FlutterTts();
  final AuthService _authService = AuthService.instance;
  final ExperienceService _experienceService = ExperienceService.instance;

  // Playback state
  TtsState _ttsState = TtsState.stopped;
  double _speechRate = 0.52; // Slightly faster than normal for natural feel
  double _pitch = 1.05; // Slightly higher pitch for clarity
  double _volume = 0.95; // Slightly lower to avoid harshness

  // Progress tracking
  int _currentWordStart = 0;
  int _currentWordEnd = 0;
  String _currentText = '';

  // Getters
  TtsState get ttsState => _ttsState;
  bool get isPlaying => _ttsState == TtsState.playing;
  bool get isPaused => _ttsState == TtsState.paused;
  bool get isStopped => _ttsState == TtsState.stopped;
  double get speechRate => _speechRate;
  double get pitch => _pitch;
  double get volume => _volume;
  int get currentWordStart => _currentWordStart;
  int get currentWordEnd => _currentWordEnd;
  String get currentText => _currentText;

  /// Initialize TTS engine with callbacks
  Future<void> initialize() async {
    try {
      log('🔊 Initializing TTS service...');

      // Set up handlers
      _flutterTts.setStartHandler(() {
        log('🔊 TTS started');
        _ttsState = TtsState.playing;
        notifyListeners();
      });

      _flutterTts.setCompletionHandler(() {
        log('🔊 TTS completed');
        _ttsState = TtsState.stopped;
        _currentWordStart = 0;
        _currentWordEnd = 0;
        notifyListeners();
      });

      _flutterTts.setCancelHandler(() {
        log('🔊 TTS cancelled');
        _ttsState = TtsState.stopped;
        _currentWordStart = 0;
        _currentWordEnd = 0;
        notifyListeners();
      });

      _flutterTts.setPauseHandler(() {
        log('🔊 TTS paused');
        _ttsState = TtsState.paused;
        notifyListeners();
      });

      _flutterTts.setContinueHandler(() {
        log('🔊 TTS continued');
        _ttsState = TtsState.playing;
        notifyListeners();
      });

      _flutterTts.setErrorHandler((msg) {
        log('🔊 TTS error: $msg');
        _ttsState = TtsState.stopped;
        notifyListeners();
      });

      // Set progress handler for word-by-word tracking
      _flutterTts.setProgressHandler((text, start, end, word) {
        _currentWordStart = start;
        _currentWordEnd = end;
        notifyListeners();
      });

      // Configure default settings
      await _flutterTts.setVolume(_volume);
      await _flutterTts.setSpeechRate(_speechRate);
      await _flutterTts.setPitch(_pitch);

      // Set language to English
      await _flutterTts.setLanguage('en-US');

      // Try to set a natural-sounding voice
      await _selectBestVoice();

      // iOS specific settings
      if (!kIsWeb) {
        await _flutterTts.setSharedInstance(true);
        await _flutterTts.setIosAudioCategory(
          IosTextToSpeechAudioCategory.playback,
          [
            IosTextToSpeechAudioCategoryOptions.allowBluetooth,
            IosTextToSpeechAudioCategoryOptions.allowBluetoothA2DP,
            IosTextToSpeechAudioCategoryOptions.mixWithOthers,
            IosTextToSpeechAudioCategoryOptions.defaultToSpeaker,
          ],
          IosTextToSpeechAudioMode.voicePrompt,
        );
      }

      log('✅ TTS service initialized');
    } catch (e) {
      log('⚠️ Error initializing TTS: $e');
    }
  }

  /// Speak the given text
  Future<void> speak(
    String text, {
    String? articleId,
    String? voice,
    String? language,
  }) async {
    if (text.isEmpty) return;

    try {
      _currentText = text;
      final normalizedArticleId = articleId?.trim() ?? '';
      if (normalizedArticleId.isNotEmpty) {
        final userData = await _authService.getCurrentUser();
        final userId = (userData?['id'] ?? userData?['userId'])?.toString();
        if (userId != null && userId.isNotEmpty) {
          await _experienceService
              .createTtsPresign(
                userId: userId,
                articleId: normalizedArticleId,
                voice: voice,
                language: language,
              )
              .timeout(const Duration(seconds: 2));
        }
      }

      // Clean the text for better speech
      final cleanedText = _cleanTextForSpeech(text);

      await _flutterTts.speak(cleanedText);
      log('🔊 Speaking: ${cleanedText.substring(0, cleanedText.length > 50 ? 50 : cleanedText.length)}...');
    } catch (e) {
      log('⚠️ Error speaking: $e');
    }
  }

  /// Pause playback
  Future<void> pause() async {
    try {
      await _flutterTts.pause();
    } catch (e) {
      log('⚠️ Error pausing TTS: $e');
    }
  }

  /// Resume playback
  Future<void> resume() async {
    try {
      // Note: On iOS, pause/resume might not work as expected
      // We may need to use stop/speak instead
      await _flutterTts.speak(_currentText);
    } catch (e) {
      log('⚠️ Error resuming TTS: $e');
    }
  }

  /// Stop playback
  Future<void> stop() async {
    try {
      await _flutterTts.stop();
      _ttsState = TtsState.stopped;
      _currentWordStart = 0;
      _currentWordEnd = 0;
      notifyListeners();
    } catch (e) {
      log('⚠️ Error stopping TTS: $e');
    }
  }

  /// Set speech rate (0.0 - 1.0)
  Future<void> setSpeechRate(double rate) async {
    try {
      _speechRate = rate.clamp(0.0, 1.0);
      await _flutterTts.setSpeechRate(_speechRate);
      notifyListeners();
      log('🔊 Speech rate set to: $_speechRate');
    } catch (e) {
      log('⚠️ Error setting speech rate: $e');
    }
  }

  /// Set pitch (0.5 - 2.0)
  Future<void> setPitch(double pitch) async {
    try {
      _pitch = pitch.clamp(0.5, 2.0);
      await _flutterTts.setPitch(_pitch);
      notifyListeners();
      log('🔊 Pitch set to: $_pitch');
    } catch (e) {
      log('⚠️ Error setting pitch: $e');
    }
  }

  /// Set volume (0.0 - 1.0)
  Future<void> setVolume(double volume) async {
    try {
      _volume = volume.clamp(0.0, 1.0);
      await _flutterTts.setVolume(_volume);
      notifyListeners();
      log('🔊 Volume set to: $_volume');
    } catch (e) {
      log('⚠️ Error setting volume: $e');
    }
  }

  /// Get available languages
  Future<List<String>> getLanguages() async {
    try {
      final languages = await _flutterTts.getLanguages;
      return List<String>.from(languages);
    } catch (e) {
      log('⚠️ Error getting languages: $e');
      return [];
    }
  }

  /// Get available voices
  Future<List<Map>> getVoices() async {
    try {
      final voices = await _flutterTts.getVoices;
      return List<Map>.from(voices);
    } catch (e) {
      log('⚠️ Error getting voices: $e');
      return [];
    }
  }

  /// Set voice
  Future<void> setVoice(Map<String, String> voice) async {
    try {
      await _flutterTts.setVoice(voice);
      notifyListeners();
      log('🔊 Voice set to: ${voice['name']}');
    } catch (e) {
      log('⚠️ Error setting voice: $e');
    }
  }

  /// Select the best available voice for natural speech
  Future<void> _selectBestVoice() async {
    try {
      final voices = await getVoices();

      if (voices.isEmpty) {
        log('⚠️ No voices available');
        return;
      }

      // Preferred voice names (in order of preference)
      // These are high-quality neural voices available on iOS/Android
      final preferredVoices = [
        'Samantha', // iOS - Natural female voice
        'Alex', // iOS - Natural male voice
        'Karen', // iOS - Australian female
        'en-us-x-sfg-network', // Android - Female
        'en-us-x-tpd-network', // Android - Male
        'en-US-language', // Fallback
      ];

      // Try to find a preferred voice
      for (final preferredName in preferredVoices) {
        for (final voice in voices) {
          final voiceName = voice['name']?.toString().toLowerCase() ?? '';

          if (voiceName.contains(preferredName.toLowerCase())) {
            await setVoice(Map<String, String>.from(voice));
            log('✅ Selected voice: ${voice['name']}');
            return;
          }
        }
      }

      // If no preferred voice found, use the first English voice with "enhanced" or "premium"
      for (final voice in voices) {
        final voiceName = voice['name']?.toString().toLowerCase() ?? '';
        final locale = voice['locale']?.toString().toLowerCase() ?? '';

        if (locale.startsWith('en') &&
            (voiceName.contains('enhanced') ||
             voiceName.contains('premium') ||
             voiceName.contains('neural'))) {
          await setVoice(Map<String, String>.from(voice));
          log('✅ Selected enhanced voice: ${voice['name']}');
          return;
        }
      }

      log('ℹ️ Using default system voice');
    } catch (e) {
      log('⚠️ Error selecting voice: $e');
    }
  }

  /// Clean text for better speech synthesis
  String _cleanTextForSpeech(String text) {
    // Remove URLs
    String cleaned = text.replaceAll(RegExp(r'https?://\S+'), '');

    // Remove excessive newlines
    cleaned = cleaned.replaceAll(RegExp(r'\n{3,}'), '\n\n');

    // Remove common article metadata patterns
    cleaned = cleaned.replaceAll(RegExp(r'Published \d{4}-\d{2}-\d{2}'), '');
    cleaned = cleaned.replaceAll(RegExp(r'Updated \d{4}-\d{2}-\d{2}'), '');
    cleaned = cleaned.replaceAll(RegExp(r'\d+ min read'), '');

    // Replace special characters with pauses
    cleaned = cleaned.replaceAll('—', ' - ');
    cleaned = cleaned.replaceAll('–', ' - ');

    // Remove extra whitespace
    cleaned = cleaned.replaceAll(RegExp(r'\s+'), ' ').trim();

    return cleaned;
  }

  /// Dispose resources
  @override
  void dispose() {
    _flutterTts.stop();
    super.dispose();
  }
}

/// TTS playback state
enum TtsState {
  playing,
  paused,
  stopped,
}
