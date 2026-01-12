import 'package:flutter/material.dart';
import 'package:the_news/constant/theme/default_theme.dart';
import 'package:the_news/model/daily_digest_model.dart';
import 'package:the_news/service/daily_digest_service.dart';
import 'package:the_news/view/settings/ai_settings_page.dart';

/// Settings page for daily digest customization
class DigestSettingsPage extends StatefulWidget {
  const DigestSettingsPage({super.key});

  @override
  State<DigestSettingsPage> createState() => _DigestSettingsPageState();
}

class _DigestSettingsPageState extends State<DigestSettingsPage> {
  final DailyDigestService _digestService = DailyDigestService.instance;
  late DigestSettings _settings;

  @override
  void initState() {
    super.initState();
    _settings = _digestService.settings;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: KAppColors.getBackground(context),
      appBar: AppBar(
        backgroundColor: KAppColors.getBackground(context),
        title: const Text('Digest Settings'),
        actions: [
          TextButton(
            onPressed: _saveSettings,
            child: Text(
              'Save',
              style: TextStyle(
                color: KAppColors.getPrimary(context),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildSection(
            'Frequency',
            [
              ...DigestFrequency.values.map((freq) {
                return RadioListTile<DigestFrequency>(
                  title: Text(freq.label),
                  subtitle: Text(freq.description),
                  value: freq,
                  // ignore: deprecated_member_use
                  groupValue: _settings.frequency,
                  // ignore: deprecated_member_use
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _settings = _settings.copyWith(frequency: value);
                      });
                    }
                  },
                  activeColor: KAppColors.getPrimary(context),
                );
              }),
            ],
          ),
          const SizedBox(height: 24),

          _buildSection(
            'Content',
            [
              ListTile(
                title: const Text('Max Stories'),
                subtitle: Text('${_settings.maxItems} stories per digest'),
                trailing: SizedBox(
                  width: 100,
                  child: Slider(
                    value: _settings.maxItems.toDouble(),
                    min: 3,
                    max: 10,
                    divisions: 7,
                    label: _settings.maxItems.toString(),
                    activeColor: KAppColors.getPrimary(context),
                    onChanged: (value) {
                      setState(() {
                        _settings = _settings.copyWith(maxItems: value.toInt());
                      });
                    },
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          _buildSection(
            'Tone',
            [
              ...DigestTone.values.map((tone) {
                return RadioListTile<DigestTone>(
                  title: Text(tone.label),
                  subtitle: Text(tone.description),
                  value: tone,
                  // ignore: deprecated_member_use
                  groupValue: _settings.tone,
                  // ignore: deprecated_member_use
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _settings = _settings.copyWith(tone: value);
                      });
                    }
                  },
                  activeColor: KAppColors.getPrimary(context),
                );
              }),
            ],
          ),
          const SizedBox(height: 24),

          _buildSection(
            'Notifications',
            [
              SwitchListTile(
                title: const Text('Enable Notifications'),
                subtitle: const Text('Get notified when digest is ready'),
                value: _settings.enableNotifications,
                activeThumbColor: KAppColors.getPrimary(context),
                onChanged: (value) {
                  setState(() {
                    _settings = _settings.copyWith(enableNotifications: value);
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 24),

          _buildSection(
            'AI Integration',
            [
              ListTile(
                leading: Icon(
                  Icons.auto_awesome,
                  color: KAppColors.getPrimary(context),
                ),
                title: const Text('AI Settings'),
                subtitle: const Text('Configure AI for better summaries'),
                trailing: Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: KAppColors.getOnBackground(context).withValues(alpha: 0.4),
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AISettingsPage(),
                    ),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 16, bottom: 8),
          child: Text(
            title,
            style: KAppTextStyles.titleSmall.copyWith(
              color: KAppColors.getOnBackground(context),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: KAppColors.getBackground(context),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: KAppColors.getOnBackground(context).withValues(alpha: 0.1),
            ),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  Future<void> _saveSettings() async {
    await _digestService.updateSettings(_settings);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Settings saved')),
      );
      Navigator.pop(context);
    }
  }
}
