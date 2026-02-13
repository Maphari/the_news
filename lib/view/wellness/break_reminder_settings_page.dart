import 'package:flutter/material.dart' hide MeasuredPinnedHeaderSliver;
import 'package:the_news/constant/design_constants.dart';
import 'package:the_news/constant/theme/default_theme.dart';
import 'package:the_news/utils/statusbar_helper_utils.dart';
import 'package:the_news/view/widgets/app_back_button.dart';
import 'package:the_news/view/home/widget/home_app_bar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:the_news/service/auth_service.dart';
import 'package:the_news/service/experience_service.dart';

class BreakReminderSettingsPage extends StatefulWidget {
  const BreakReminderSettingsPage({super.key});

  @override
  State<BreakReminderSettingsPage> createState() => _BreakReminderSettingsPageState();
}

class _BreakReminderSettingsPageState extends State<BreakReminderSettingsPage> {
  final ExperienceService _experienceService = ExperienceService.instance;
  final AuthService _authService = AuthService.instance;
  bool _breakRemindersEnabled = true;
  double _firstReminderMinutes = 15;
  double _secondReminderMinutes = 20;
  double _urgentReminderMinutes = 30;
  bool _vibrationEnabled = true;
  bool _soundEnabled = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final user = await _authService.getCurrentUser();
    setState(() {
      _breakRemindersEnabled = prefs.getBool('breakRemindersEnabled') ?? true;
      _firstReminderMinutes = prefs.getDouble('firstReminderMinutes') ?? 15;
      _secondReminderMinutes = prefs.getDouble('secondReminderMinutes') ?? 20;
      _urgentReminderMinutes = prefs.getDouble('urgentReminderMinutes') ?? 30;
      _vibrationEnabled = prefs.getBool('breakVibrationEnabled') ?? true;
      _soundEnabled = prefs.getBool('breakSoundEnabled') ?? false;
    });

    final userId = (user?['id'] ?? user?['userId'])?.toString();
    if (userId == null || userId.isEmpty) return;

    final remote = await _experienceService.fetchWellnessSettings(userId);
    if (remote == null || !mounted) return;

    final breakEnabled = remote['breakReminderEnabled'] == true;
    final breakMinutes = (remote['breakIntervalMinutes'] as num?)?.toDouble();
    setState(() {
      _breakRemindersEnabled = breakEnabled;
      if (breakMinutes != null && breakMinutes >= 5) {
        _firstReminderMinutes = breakMinutes.clamp(5, 30);
        _secondReminderMinutes = (_firstReminderMinutes + 5).clamp(6, 45);
        _urgentReminderMinutes = (_secondReminderMinutes + 5).clamp(10, 60);
      }
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final user = await _authService.getCurrentUser();
    await prefs.setBool('breakRemindersEnabled', _breakRemindersEnabled);
    await prefs.setDouble('firstReminderMinutes', _firstReminderMinutes);
    await prefs.setDouble('secondReminderMinutes', _secondReminderMinutes);
    await prefs.setDouble('urgentReminderMinutes', _urgentReminderMinutes);
    await prefs.setBool('breakVibrationEnabled', _vibrationEnabled);
    await prefs.setBool('breakSoundEnabled', _soundEnabled);

    final userId = (user?['id'] ?? user?['userId'])?.toString();
    if (userId != null && userId.isNotEmpty) {
      await _experienceService.updateWellnessSettings(userId, {
        'breakReminderEnabled': _breakRemindersEnabled,
        'breakIntervalMinutes': _firstReminderMinutes.round(),
      });
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Settings saved'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color screenBackgroundColor = KAppColors.getBackground(context);

    return StatusBarHelper.wrapWithStatusBar(
      backgroundColor: screenBackgroundColor,
      child: Scaffold(
        backgroundColor: screenBackgroundColor,
        body: SafeArea(
          child: CustomScrollView(
            slivers: [
              MeasuredPinnedHeaderSliver(
                height: HomeHeader.estimatedHeight(
                  title: 'Break Reminders',
                  subtitle:
                      'Configure break reminder intervals for mindful reading',
                  bottom: 20,
                  subtitleMaxLines: 1,
                ),
                child: HomeHeader(
                  title: 'Break Reminders',
                  subtitle: 'Configure break reminder intervals for mindful reading',
                  showActions: false,
                  bottom: 20,
                  subtitleMaxLines: 1,
                  leading: const AppBackButton(),
                  useSafeArea: false,
                ),
              ),

              // Enable/Disable Section
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Container(
                    padding: KDesignConstants.paddingMd,
                    decoration: BoxDecoration(
                      color: KAppColors.getOnBackground(context).withValues(alpha: 0.03),
                      borderRadius: KBorderRadius.lg,
                      border: Border.all(
                        color: KAppColors.getOnBackground(context).withValues(alpha: 0.08),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: KAppColors.getPrimary(context).withValues(alpha: 0.1),
                            borderRadius: KBorderRadius.md,
                          ),
                          child: Icon(
                            Icons.notifications_active,
                            color: KAppColors.getPrimary(context),
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: KDesignConstants.spacing16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Enable Break Reminders',
                                style: KAppTextStyles.titleMedium.copyWith(
                                  color: KAppColors.getOnBackground(context),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Get reminders to take breaks while reading',
                                style: KAppTextStyles.bodySmall.copyWith(
                                  color: KAppColors.getOnBackground(context).withValues(alpha: 0.6),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Switch(
                          value: _breakRemindersEnabled,
                          onChanged: (value) {
                            setState(() {
                              _breakRemindersEnabled = value;
                            });
                            _saveSettings();
                          },
                          activeTrackColor: KAppColors.getPrimary(context),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Reminder Intervals Section
              if (_breakRemindersEnabled) ...[
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                    child: Text(
                      'Reminder Intervals',
                      style: KAppTextStyles.titleSmall.copyWith(
                        color: KAppColors.getOnBackground(context).withValues(alpha: 0.6),
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),

                // First Reminder
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: KAppColors.success.withValues(alpha: 0.05),
                        borderRadius: KBorderRadius.lg,
                        border: Border.all(
                          color: KAppColors.success.withValues(alpha: 0.1),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: KDesignConstants.paddingSm,
                                decoration: BoxDecoration(
                                  color: KAppColors.success.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.self_improvement_outlined,
                                  color: KAppColors.success,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: KDesignConstants.spacing12),
                              Text(
                                'Gentle Reminder',
                                style: KAppTextStyles.titleMedium.copyWith(
                                  color: KAppColors.getOnBackground(context),
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: KDesignConstants.spacing16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'After',
                                style: KAppTextStyles.bodyMedium.copyWith(
                                  color: KAppColors.getOnBackground(context).withValues(alpha: 0.7),
                                ),
                              ),
                              Text(
                                '${_firstReminderMinutes.round()} minutes',
                                style: KAppTextStyles.titleMedium.copyWith(
                                  color: KAppColors.success,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                          Slider(
                            value: _firstReminderMinutes,
                            min: 5,
                            max: 30,
                            divisions: 25,
                            activeColor: KAppColors.success,
                            onChanged: (value) {
                              setState(() {
                                _firstReminderMinutes = value;
                                // Ensure subsequent reminders are after this one
                                if (_secondReminderMinutes <= value) {
                                  _secondReminderMinutes = value + 5;
                                }
                                if (_urgentReminderMinutes <= _secondReminderMinutes) {
                                  _urgentReminderMinutes = _secondReminderMinutes + 5;
                                }
                              });
                            },
                            onChangeEnd: (value) => _saveSettings(),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Second Reminder
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: KAppColors.warning.withValues(alpha: 0.05),
                        borderRadius: KBorderRadius.lg,
                        border: Border.all(
                          color: KAppColors.warning.withValues(alpha: 0.1),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: KDesignConstants.paddingSm,
                                decoration: BoxDecoration(
                                  color: KAppColors.warning.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.schedule_outlined,
                                  color: KAppColors.warning,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: KDesignConstants.spacing12),
                              Text(
                                'Strong Reminder',
                                style: KAppTextStyles.titleMedium.copyWith(
                                  color: KAppColors.getOnBackground(context),
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: KDesignConstants.spacing16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'After',
                                style: KAppTextStyles.bodyMedium.copyWith(
                                  color: KAppColors.getOnBackground(context).withValues(alpha: 0.7),
                                ),
                              ),
                              Text(
                                '${_secondReminderMinutes.round()} minutes',
                                style: KAppTextStyles.titleMedium.copyWith(
                                  color: KAppColors.warning,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                          Slider(
                            value: _secondReminderMinutes,
                            min: _firstReminderMinutes + 1,
                            max: 45,
                            divisions: (45 - (_firstReminderMinutes + 1)).round(),
                            activeColor: KAppColors.warning,
                            onChanged: (value) {
                              setState(() {
                                _secondReminderMinutes = value;
                                // Ensure urgent reminder is after this one
                                if (_urgentReminderMinutes <= value) {
                                  _urgentReminderMinutes = value + 5;
                                }
                              });
                            },
                            onChangeEnd: (value) => _saveSettings(),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Urgent Reminder
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: KAppColors.error.withValues(alpha: 0.05),
                        borderRadius: KBorderRadius.lg,
                        border: Border.all(
                          color: KAppColors.error.withValues(alpha: 0.1),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: KDesignConstants.paddingSm,
                                decoration: BoxDecoration(
                                  color: KAppColors.error.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.warning_amber_rounded,
                                  color: KAppColors.error,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: KDesignConstants.spacing12),
                              Text(
                                'Urgent Reminder',
                                style: KAppTextStyles.titleMedium.copyWith(
                                  color: KAppColors.getOnBackground(context),
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: KDesignConstants.spacing16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'After',
                                style: KAppTextStyles.bodyMedium.copyWith(
                                  color: KAppColors.getOnBackground(context).withValues(alpha: 0.7),
                                ),
                              ),
                              Text(
                                '${_urgentReminderMinutes.round()} minutes',
                                style: KAppTextStyles.titleMedium.copyWith(
                                  color: KAppColors.error,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                          Slider(
                            value: _urgentReminderMinutes,
                            min: _secondReminderMinutes + 1,
                            max: 60,
                            divisions: (60 - (_secondReminderMinutes + 1)).round(),
                            activeColor: KAppColors.error,
                            onChanged: (value) {
                              setState(() {
                                _urgentReminderMinutes = value;
                              });
                            },
                            onChangeEnd: (value) => _saveSettings(),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Notification Settings
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
                    child: Text(
                      'Notification Style',
                      style: KAppTextStyles.titleSmall.copyWith(
                        color: KAppColors.getOnBackground(context).withValues(alpha: 0.6),
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),

                // Vibration Toggle
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                    child: Container(
                      padding: KDesignConstants.paddingMd,
                      decoration: BoxDecoration(
                        color: KAppColors.getOnBackground(context).withValues(alpha: 0.03),
                        borderRadius: KBorderRadius.md,
                        border: Border.all(
                          color: KAppColors.getOnBackground(context).withValues(alpha: 0.08),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.vibration,
                            color: KAppColors.getOnBackground(context).withValues(alpha: 0.7),
                            size: 24,
                          ),
                          const SizedBox(width: KDesignConstants.spacing16),
                          Expanded(
                            child: Text(
                              'Vibration',
                              style: KAppTextStyles.bodyMedium.copyWith(
                                color: KAppColors.getOnBackground(context),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          Switch(
                            value: _vibrationEnabled,
                            onChanged: (value) {
                              setState(() {
                                _vibrationEnabled = value;
                              });
                              _saveSettings();
                            },
                            activeTrackColor: KAppColors.getPrimary(context),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Sound Toggle
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                    child: Container(
                      padding: KDesignConstants.paddingMd,
                      decoration: BoxDecoration(
                        color: KAppColors.getOnBackground(context).withValues(alpha: 0.03),
                        borderRadius: KBorderRadius.md,
                        border: Border.all(
                          color: KAppColors.getOnBackground(context).withValues(alpha: 0.08),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.volume_up,
                            color: KAppColors.getOnBackground(context).withValues(alpha: 0.7),
                            size: 24,
                          ),
                          const SizedBox(width: KDesignConstants.spacing16),
                          Expanded(
                            child: Text(
                              'Sound',
                              style: KAppTextStyles.bodyMedium.copyWith(
                                color: KAppColors.getOnBackground(context),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          Switch(
                            value: _soundEnabled,
                            onChanged: (value) {
                              setState(() {
                                _soundEnabled = value;
                              });
                              _saveSettings();
                            },
                            activeTrackColor: KAppColors.getPrimary(context),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Info Box
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Container(
                      padding: KDesignConstants.paddingMd,
                      decoration: BoxDecoration(
                        color: KAppColors.getPrimary(context).withValues(alpha: 0.05),
                        borderRadius: KBorderRadius.lg,
                        border: Border.all(
                          color: KAppColors.getPrimary(context).withValues(alpha: 0.1),
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: KAppColors.getPrimary(context),
                            size: 24,
                          ),
                          const SizedBox(width: KDesignConstants.spacing12),
                          Expanded(
                            child: Text(
                              'Break reminders help you maintain a healthy reading habit by encouraging regular pauses. Taking short breaks improves focus and reduces mental fatigue.',
                              style: KAppTextStyles.bodySmall.copyWith(
                                color: KAppColors.getOnBackground(context).withValues(alpha: 0.7),
                                height: 1.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],

              // Bottom spacing
              const SliverToBoxAdapter(
                child: SizedBox(height: KDesignConstants.spacing40),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
