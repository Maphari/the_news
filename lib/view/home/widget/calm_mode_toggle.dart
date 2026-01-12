import 'package:flutter/material.dart';
import 'package:the_news/constant/theme/default_theme.dart';
import 'package:the_news/service/calm_mode_service.dart';

class CalmModeToggle extends StatefulWidget {
  const CalmModeToggle({
    super.key,
    required this.onToggle,
  });

  final VoidCallback onToggle;

  @override
  State<CalmModeToggle> createState() => _CalmModeToggleState();
}

class _CalmModeToggleState extends State<CalmModeToggle> {
  final CalmModeService _calmMode = CalmModeService.instance;
  bool _isEnabled = false;

  @override
  void initState() {
    super.initState();
    _loadCalmModeState();
  }

  Future<void> _loadCalmModeState() async {
    await _calmMode.initialize();
    if (mounted) {
      setState(() {
        _isEnabled = _calmMode.isCalmModeEnabled;
      });
    }
  }

  Future<void> _toggleCalmMode() async {
    await _calmMode.toggleCalmMode();
    setState(() {
      _isEnabled = _calmMode.isCalmModeEnabled;
    });
    widget.onToggle();
  }

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: _isEnabled ? 'Calm Mode On' : 'Calm Mode Off',
      child: GestureDetector(
        onTap: _toggleCalmMode,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            gradient: _isEnabled
                ? LinearGradient(
                    colors: [
                      const Color(0xFF4CAF50).withValues(alpha: 0.3),
                      const Color(0xFF8BC34A).withValues(alpha: 0.3),
                    ],
                  )
                : null,
            color: _isEnabled
                ? null
                : KAppColors.getOnBackground(context).withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(35),
            border: Border.all(
              color: _isEnabled
                  ? const Color(0xFF4CAF50).withValues(alpha: 0.5)
                  : KAppColors.getOnBackground(context).withValues(alpha: 0.2),
              width: 1.5,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _isEnabled ? Icons.wb_sunny : Icons.wb_sunny_outlined,
                size: 18,
                color: _isEnabled
                    ? const Color(0xFF4CAF50)
                    : KAppColors.getOnBackground(context).withValues(alpha: 0.6),
              ),
              const SizedBox(width: 6),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 300),
                style: KAppTextStyles.labelSmall.copyWith(
                  color: _isEnabled
                      ? const Color(0xFF4CAF50)
                      : KAppColors.getOnBackground(context).withValues(alpha: 0.6),
                  fontWeight: FontWeight.w600,
                  fontSize: 11,
                ),
                child: const Text('Calm'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
