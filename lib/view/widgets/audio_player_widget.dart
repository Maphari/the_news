import 'package:flutter/material.dart';
import 'package:the_news/constant/design_constants.dart';
import 'package:the_news/constant/theme/default_theme.dart';
import 'package:the_news/model/news_article_model.dart';
import 'package:the_news/service/text_to_speech_service.dart';

/// Audio player widget for article narration
/// Provides play/pause/stop controls and playback speed adjustment
class AudioPlayerWidget extends StatefulWidget {
  const AudioPlayerWidget({
    super.key,
    required this.article,
  });

  final ArticleModel article;

  @override
  State<AudioPlayerWidget> createState() => _AudioPlayerWidgetState();
}

class _AudioPlayerWidgetState extends State<AudioPlayerWidget> {
  final TextToSpeechService _ttsService = TextToSpeechService.instance;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeTts();
    _ttsService.addListener(_onTtsStateChanged);
  }

  @override
  void dispose() {
    _ttsService.removeListener(_onTtsStateChanged);
    super.dispose();
  }

  void _onTtsStateChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _initializeTts() async {
    await _ttsService.initialize();
    if (mounted) {
      setState(() => _isInitialized = true);
    }
  }

  Future<void> _handlePlayPause() async {
    if (_ttsService.isPlaying) {
      await _ttsService.stop();
    } else if (_ttsService.isPaused) {
      await _ttsService.resume();
    } else {
      // Prepare article text for narration
      final articleText = _prepareArticleText();
      await _ttsService.speak(
        articleText,
        articleId: widget.article.articleId,
      );
    }
  }

  String _prepareArticleText() {
    // Combine title, description, and content
    final buffer = StringBuffer();

    buffer.writeln(widget.article.title);
    buffer.writeln();

    if (widget.article.description.isNotEmpty) {
      buffer.writeln(widget.article.description);
      buffer.writeln();
    }

    buffer.write(widget.article.content);

    return buffer.toString();
  }

  Future<void> _handleStop() async {
    await _ttsService.stop();
  }

  void _showSpeedDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: KAppColors.getBackground(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _SpeedControlSheet(
        initialSpeed: _ttsService.speechRate,
        onSpeedChanged: (speed) async {
          await _ttsService.setSpeechRate(speed);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: KAppColors.getPrimary(context).withValues(alpha: 0.1),
        borderRadius: KBorderRadius.lg,
        border: Border.all(
          color: KAppColors.getPrimary(context).withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          // Play/Pause button
          _buildPlayPauseButton(),
          const SizedBox(width: KDesignConstants.spacing12),

          // Stop button (only show when playing/paused)
          if (!_ttsService.isStopped) ...[
            _buildStopButton(),
            const SizedBox(width: KDesignConstants.spacing12),
          ],

          // Info text
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _ttsService.isPlaying
                      ? 'Playing article...'
                      : _ttsService.isPaused
                          ? 'Paused'
                          : 'Listen to article',
                  style: KAppTextStyles.titleSmall.copyWith(
                    color: KAppColors.getOnBackground(context),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _getSpeedText(),
                  style: KAppTextStyles.bodySmall.copyWith(
                    color: KAppColors.getOnBackground(context).withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),

          // Speed control button
          _buildSpeedButton(),
        ],
      ),
    );
  }

  Widget _buildPlayPauseButton() {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: KAppColors.getPrimary(context),
        shape: BoxShape.circle,
      ),
      child: IconButton(
        onPressed: _handlePlayPause,
        icon: Icon(
          _ttsService.isPlaying
              ? Icons.pause_rounded
              : Icons.play_arrow_rounded,
          color: KAppColors.darkOnBackground,
          size: 28,
        ),
        padding: EdgeInsets.zero,
      ),
    );
  }

  Widget _buildStopButton() {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: KAppColors.getOnBackground(context).withValues(alpha: 0.1),
        shape: BoxShape.circle,
      ),
      child: IconButton(
        onPressed: _handleStop,
        icon: Icon(
          Icons.stop_rounded,
          color: KAppColors.getOnBackground(context),
          size: 20,
        ),
        padding: EdgeInsets.zero,
      ),
    );
  }

  Widget _buildSpeedButton() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: KAppColors.getOnBackground(context).withValues(alpha: 0.1),
        borderRadius: KBorderRadius.xl,
      ),
      child: InkWell(
        onTap: _showSpeedDialog,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.speed_rounded,
              size: 16,
              color: KAppColors.getOnBackground(context).withValues(alpha: 0.7),
            ),
            const SizedBox(width: KDesignConstants.spacing4),
            Text(
              _getSpeedText(),
              style: KAppTextStyles.labelSmall.copyWith(
                color: KAppColors.getOnBackground(context).withValues(alpha: 0.7),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getSpeedText() {
    // Convert 0.0-1.0 range to 0.5x-2.0x display
    final displaySpeed = 0.5 + (_ttsService.speechRate * 1.5);
    return '${displaySpeed.toStringAsFixed(1)}x';
  }
}

/// Speed control bottom sheet
class _SpeedControlSheet extends StatefulWidget {
  const _SpeedControlSheet({
    required this.initialSpeed,
    required this.onSpeedChanged,
  });

  final double initialSpeed;
  final Function(double) onSpeedChanged;

  @override
  State<_SpeedControlSheet> createState() => _SpeedControlSheetState();
}

class _SpeedControlSheetState extends State<_SpeedControlSheet> {
  late double _currentSpeed;

  @override
  void initState() {
    super.initState();
    _currentSpeed = widget.initialSpeed;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: KDesignConstants.paddingLg,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: KAppColors.getOnBackground(context).withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: KDesignConstants.spacing24),

          // Title
          Text(
            'Playback Speed',
            style: KAppTextStyles.titleLarge.copyWith(
              color: KAppColors.getOnBackground(context),
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: KDesignConstants.spacing8),

          // Current speed display
          Text(
            '${(0.5 + (_currentSpeed * 1.5)).toStringAsFixed(1)}x',
            style: KAppTextStyles.displayMedium.copyWith(
              color: KAppColors.getPrimary(context),
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: KDesignConstants.spacing24),

          // Speed slider
          Row(
            children: [
              Text(
                '0.5x',
                style: KAppTextStyles.bodySmall.copyWith(
                  color: KAppColors.getOnBackground(context).withValues(alpha: 0.6),
                ),
              ),
              Expanded(
                child: Slider(
                  value: _currentSpeed,
                  min: 0.0,
                  max: 1.0,
                  divisions: 10,
                  activeColor: KAppColors.getPrimary(context),
                  inactiveColor: KAppColors.getOnBackground(context).withValues(alpha: 0.2),
                  onChanged: (value) {
                    setState(() => _currentSpeed = value);
                    widget.onSpeedChanged(value);
                  },
                ),
              ),
              Text(
                '2.0x',
                style: KAppTextStyles.bodySmall.copyWith(
                  color: KAppColors.getOnBackground(context).withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
          const SizedBox(height: KDesignConstants.spacing16),

          // Preset speed buttons
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              _buildPresetButton(context, '0.5x', 0.0),
              _buildPresetButton(context, '0.75x', 0.167),
              _buildPresetButton(context, '1.0x', 0.333),
              _buildPresetButton(context, '1.25x', 0.5),
              _buildPresetButton(context, '1.5x', 0.667),
              _buildPresetButton(context, '2.0x', 1.0),
            ],
          ),
          const SizedBox(height: KDesignConstants.spacing24),
        ],
      ),
    );
  }

  Widget _buildPresetButton(BuildContext context, String label, double speed) {
    final isSelected = (_currentSpeed - speed).abs() < 0.05;

    return InkWell(
      onTap: () {
        setState(() => _currentSpeed = speed);
        widget.onSpeedChanged(speed);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? KAppColors.getPrimary(context)
              : KAppColors.getOnBackground(context).withValues(alpha: 0.1),
          borderRadius: KBorderRadius.xl,
        ),
        child: Text(
          label,
          style: KAppTextStyles.labelMedium.copyWith(
            color: isSelected
                ? KAppColors.darkOnBackground
                : KAppColors.getOnBackground(context).withValues(alpha: 0.7),
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

/// Compact audio player for mini player or persistent controls
class CompactAudioPlayer extends StatelessWidget {
  const CompactAudioPlayer({
    super.key,
    required this.article,
  });

  final ArticleModel article;

  @override
  Widget build(BuildContext context) {
    final ttsService = TextToSpeechService.instance;

    return ListenableBuilder(
      listenable: ttsService,
      builder: (context, _) {
        if (ttsService.isStopped) {
          return const SizedBox.shrink();
        }

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: KAppColors.getPrimary(context),
            boxShadow: [
              BoxShadow(
                color: KAppColors.darkBackground.withValues(alpha: 0.1),
                blurRadius: 8,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(
                Icons.headphones_rounded,
                color: KAppColors.darkOnBackground.withValues(alpha: 0.9),
                size: 20,
              ),
              const SizedBox(width: KDesignConstants.spacing12),
              Expanded(
                child: Text(
                  ttsService.isPlaying ? 'Playing article...' : 'Paused',
                  style: KAppTextStyles.bodyMedium.copyWith(
                    color: KAppColors.darkOnBackground,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              IconButton(
                onPressed: () async {
                  if (ttsService.isPlaying) {
                    await ttsService.stop();
                  } else {
                    await ttsService.resume();
                  }
                },
                icon: Icon(
                  ttsService.isPlaying
                      ? Icons.pause_rounded
                      : Icons.play_arrow_rounded,
                  color: KAppColors.darkOnBackground,
                ),
              ),
              IconButton(
                onPressed: () async {
                  await ttsService.stop();
                },
                icon: const Icon(
                  Icons.close_rounded,
                  color: KAppColors.darkOnBackground,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
