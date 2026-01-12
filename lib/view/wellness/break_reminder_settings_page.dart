import 'package:flutter/material.dart';
import 'package:the_news/constant/theme/default_theme.dart';
import 'package:the_news/utils/statusbar_helper_utils.dart';
import 'package:the_news/view/home/widget/home_app_bar.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BreakReminderSettingsPage extends StatefulWidget {
  const BreakReminderSettingsPage({super.key});

  @override
  State<BreakReminderSettingsPage> createState() => _BreakReminderSettingsPageState();
}

class _BreakReminderSettingsPageState extends State<BreakReminderSettingsPage> {
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
    setState(() {
      _breakRemindersEnabled = prefs.getBool('breakRemindersEnabled') ?? true;
      _firstReminderMinutes = prefs.getDouble('firstReminderMinutes') ?? 15;
      _secondReminderMinutes = prefs.getDouble('secondReminderMinutes') ?? 20;
      _urgentReminderMinutes = prefs.getDouble('urgentReminderMinutes') ?? 30;
      _vibrationEnabled = prefs.getBool('breakVibrationEnabled') ?? true;
      _soundEnabled = prefs.getBool('breakSoundEnabled') ?? false;
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('breakRemindersEnabled', _breakRemindersEnabled);
    await prefs.setDouble('firstReminderMinutes', _firstReminderMinutes);
    await prefs.setDouble('secondReminderMinutes', _secondReminderMinutes);
    await prefs.setDouble('urgentReminderMinutes', _urgentReminderMinutes);
    await prefs.setBool('breakVibrationEnabled', _vibrationEnabled);
    await prefs.setBool('breakSoundEnabled', _soundEnabled);

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
              // Header with back button
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: Row(
                    children: [
                      IconButton(
                        icon: Icon(
                          Icons.arrow_back,
                          color: KAppColors.getOnBackground(context),
                        ),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Break Reminders',
                        style: KAppTextStyles.headlineMedium.copyWith(
                          color: KAppColors.getOnBackground(context),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              SliverToBoxAdapter(
                child: HomeHeader(
                  title: '',
                  subtitle: 'Configure break reminder intervals for mindful reading',
                  showActions: false,
                  bottom: 20,
                ),
              ),

              // Enable/Disable Section
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: KAppColors.getOnBackground(context).withValues(alpha: 0.03),
                      borderRadius: BorderRadius.circular(16),
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
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.notifications_active,
                            color: KAppColors.getPrimary(context),
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),
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
                        color: const Color(0xFF4CAF50).withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: const Color(0xFF4CAF50).withValues(alpha: 0.1),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF4CAF50).withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.self_improvement_outlined,
                                  color: Color(0xFF4CAF50),
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'Gentle Reminder',
                                style: KAppTextStyles.titleMedium.copyWith(
                                  color: KAppColors.getOnBackground(context),
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
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
                                  color: const Color(0xFF4CAF50),
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
                            activeColor: const Color(0xFF4CAF50),
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
                        color: const Color(0xFFFFC107).withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: const Color(0xFFFFC107).withValues(alpha: 0.1),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFC107).withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.schedule_outlined,
                                  color: Color(0xFFFFC107),
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'Strong Reminder',
                                style: KAppTextStyles.titleMedium.copyWith(
                                  color: KAppColors.getOnBackground(context),
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
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
                                  color: const Color(0xFFFFC107),
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
                            activeColor: const Color(0xFFFFC107),
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
                        color: const Color(0xFFFF6B6B).withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: const Color(0xFFFF6B6B).withValues(alpha: 0.1),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFF6B6B).withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.warning_amber_rounded,
                                  color: Color(0xFFFF6B6B),
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'Urgent Reminder',
                                style: KAppTextStyles.titleMedium.copyWith(
                                  color: KAppColors.getOnBackground(context),
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
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
                                  color: const Color(0xFFFF6B6B),
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
                            activeColor: const Color(0xFFFF6B6B),
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
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: KAppColors.getOnBackground(context).withValues(alpha: 0.03),
                        borderRadius: BorderRadius.circular(12),
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
                          const SizedBox(width: 16),
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
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: KAppColors.getOnBackground(context).withValues(alpha: 0.03),
                        borderRadius: BorderRadius.circular(12),
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
                          const SizedBox(width: 16),
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
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: KAppColors.getPrimary(context).withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(16),
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
                          const SizedBox(width: 12),
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
                child: SizedBox(height: 40),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
