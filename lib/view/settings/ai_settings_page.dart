import 'package:flutter/material.dart';
import 'package:the_news/constant/design_constants.dart';
import 'package:the_news/view/widgets/k_app_bar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:the_news/constant/theme/default_theme.dart';
import 'package:the_news/service/ai_service.dart';
import 'package:the_news/core/network/api_client.dart';
import 'package:the_news/view/widgets/app_back_button.dart';

/// Page for configuring AI integration settings
class AISettingsPage extends StatefulWidget {
  const AISettingsPage({super.key});

  @override
  State<AISettingsPage> createState() => _AISettingsPageState();
}

class _AISettingsPageState extends State<AISettingsPage> {
  final AIService _aiService = AIService.instance;
  final ApiClient _api = ApiClient.instance;
  final TextEditingController _githubController = TextEditingController();
  final TextEditingController _openaiController = TextEditingController();
  final TextEditingController _geminiController = TextEditingController();
  final TextEditingController _claudeController = TextEditingController();

  AIProvider _selectedProvider = AIProvider.none;
  bool _isLoading = true;
  bool _proxyEnabled = false;
  Map<String, dynamic>? _aiMetadata;
  bool _proxyHealthy = false;
  List<String> _proxyProviders = [];
  String? _proxyHealthMessage;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  void dispose() {
    _githubController.dispose();
    _openaiController.dispose();
    _geminiController.dispose();
    _claudeController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    setState(() => _isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();

      _githubController.text = prefs.getString('ai_github_pat') ?? '';
      _openaiController.text = prefs.getString('ai_openai_key') ?? '';
      _geminiController.text = prefs.getString('ai_gemini_key') ?? '';
      _claudeController.text = prefs.getString('ai_claude_key') ?? '';

      _proxyEnabled = prefs.getBool('ai_proxy_enabled') ?? false;

      final providerName = prefs.getString('ai_provider_name');
      if (providerName != null) {
        _selectedProvider = AIProvider.values.firstWhere(
          (p) => p.toString().split('.').last == providerName,
          orElse: () => AIProvider.none,
        );
      } else {
        final providerIndex = prefs.getInt('ai_provider') ?? 0;
        _selectedProvider = providerIndex < AIProvider.values.length
            ? AIProvider.values[providerIndex]
            : AIProvider.none;
      }

      await _loadHealth();
      if (_proxyEnabled && !_proxyHealthy) {
        _proxyEnabled = false;
        if (_selectedProvider == AIProvider.proxy) {
          _selectedProvider = AIProvider.none;
        }
      }
      await _loadMetadata();

      // Set the selected provider
      _aiService.setProxyEnabled(_proxyEnabled);
      _aiService.setProvider(_selectedProvider);
    } catch (e) {
      debugPrint('Error loading AI settings: $e');
    }

    setState(() => _isLoading = false);
  }

  Future<void> _loadMetadata() async {
    try {
      final response = await _api.get('ai/metadata');
      if (_api.isSuccess(response)) {
        final data = _api.parseJson(response);
        if (data['success'] == true) {
          _aiMetadata = Map<String, dynamic>.from(data);
        }
      }
    } catch (_) {
      _aiMetadata = null;
    }
  }

  Future<void> _loadHealth() async {
    try {
      final response = await _api.get('ai/health');
      if (_api.isSuccess(response)) {
        final data = _api.parseJson(response);
        _proxyHealthy = data['success'] == true;
        _proxyProviders =
            (data['providers'] as List?)?.map((e) => e.toString()).toList() ?? [];
        _proxyHealthMessage = null;
        return;
      }
      _proxyHealthy = false;
      _proxyHealthMessage = _api.getErrorMessage(response);
    } catch (e) {
      _proxyHealthy = false;
      _proxyHealthMessage = e.toString();
    }
  }

  Future<void> _saveSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      await prefs.setString('ai_github_pat', _githubController.text);
      await prefs.setString('ai_openai_key', _openaiController.text);
      await prefs.setString('ai_gemini_key', _geminiController.text);
      await prefs.setString('ai_claude_key', _claudeController.text);
      await prefs.setInt('ai_provider', _selectedProvider.index);
      await prefs.setString(
        'ai_provider_name',
        _selectedProvider.toString().split('.').last,
      );
      await prefs.setBool('ai_proxy_enabled', _proxyEnabled);

      if (_proxyEnabled && _selectedProvider == AIProvider.proxy) {
        final healthy = await _aiService.checkProxyHealth();
        if (!healthy) {
          _proxyEnabled = false;
          _selectedProvider = AIProvider.none;
          _aiService.setProxyEnabled(false);
          _aiService.setProvider(AIProvider.none);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('The News AI unavailable. Check backend configuration.'),
                backgroundColor: KAppColors.error,
              ),
            );
          }
          return;
        }
      }

      // Set the selected provider
      _aiService.setProxyEnabled(_proxyEnabled);
      _aiService.setProvider(_selectedProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('AI settings saved'),
            backgroundColor: KAppColors.getPrimary(context),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error saving settings'),
            backgroundColor: KAppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: KAppColors.getBackground(context),
      appBar: KAppBar(
        backgroundColor: KAppColors.getBackground(context),
        elevation: 0,
        leading: const AppBackButton(),
        title: Text(
          'AI Integration',
          style: KAppTextStyles.titleLarge.copyWith(
            color: KAppColors.getOnBackground(context),
            fontWeight: FontWeight.bold,
          ),
        ),
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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInfoCard(),
                  const SizedBox(height: KDesignConstants.spacing20),
                  _buildSectionHeader(
                    'Connect',
                    'Choose the simplest way to use AI.',
                    icon: Icons.cable_rounded,
                  ),
                  const SizedBox(height: KDesignConstants.spacing12),
                  _buildProxyCard(),
                  const SizedBox(height: KDesignConstants.spacing20),
                  _buildSectionHeader(
                    'Manage',
                    'Costs, cache, and health.',
                    icon: Icons.settings_suggest_rounded,
                  ),
                  const SizedBox(height: KDesignConstants.spacing12),
                  _buildCacheManager(),
                  const SizedBox(height: KDesignConstants.spacing16),
                  _buildProviderHealthSection(),
                ],
              ),
            ),
    );
  }

  Widget _buildSectionHeader(
    String title,
    String subtitle, {
    required IconData icon,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: KDesignConstants.paddingSm,
          decoration: BoxDecoration(
            color: KAppColors.getPrimary(context).withValues(alpha: 0.12),
            borderRadius: KBorderRadius.md,
          ),
          child: Icon(
            icon,
            color: KAppColors.getPrimary(context),
            size: 18,
          ),
        ),
        const SizedBox(width: KDesignConstants.spacing12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: KAppTextStyles.titleMedium.copyWith(
                  color: KAppColors.getOnBackground(context),
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: KDesignConstants.spacing4),
              Text(
                subtitle,
                style: KAppTextStyles.bodySmall.copyWith(
                  color: KAppColors.getOnBackground(context).withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: KDesignConstants.paddingMd,
      decoration: BoxDecoration(
        color: KAppColors.getPrimary(context).withValues(alpha: 0.08),
        borderRadius: KBorderRadius.md,
      ),
      child: Row(
        children: [
          Icon(
            Icons.auto_awesome,
            color: KAppColors.getPrimary(context),
            size: 32,
          ),
          const SizedBox(width: KDesignConstants.spacing16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AI-Powered Digests',
                  style: KAppTextStyles.titleMedium.copyWith(
                    color: KAppColors.getOnBackground(context),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: KDesignConstants.spacing4),
                Text(
                  'Get better summaries, key points, and insights using AI. Configure your preferred provider below.',
                  style: KAppTextStyles.bodySmall.copyWith(
                    color: KAppColors.getOnBackground(context).withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildProxyCard() {
    return Container(
      padding: KDesignConstants.paddingMd,
      decoration: BoxDecoration(
        color: KAppColors.getPrimary(context).withValues(alpha: 0.08),
        borderRadius: KBorderRadius.md,
        border: Border.all(
          color: KAppColors.getPrimary(context).withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.cloud_queue_rounded,
                color: KAppColors.getPrimary(context),
                size: 24,
              ),
              const SizedBox(width: KDesignConstants.spacing12),
              Expanded(
                child: Text(
                  'The News AI',
                  style: KAppTextStyles.titleMedium.copyWith(
                    color: KAppColors.getOnBackground(context),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _proxyEnabled
                      ? KAppColors.success.withValues(alpha: 0.15)
                      : KAppColors.warning.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  _proxyEnabled ? 'Connected' : 'Not connected',
                  style: KAppTextStyles.labelSmall.copyWith(
                    color: _proxyEnabled ? KAppColors.success : KAppColors.warning,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: KDesignConstants.spacing8),
          Text(
                  'Connect to use AI summaries and insights powered by The News.',
            style: KAppTextStyles.bodySmall.copyWith(
              color: KAppColors.getOnBackground(context).withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: KDesignConstants.spacing12),
          Row(
            children: [
              ElevatedButton(
                onPressed: () async {
                  if (_proxyEnabled) {
                    setState(() {
                      _proxyEnabled = false;
                      if (_selectedProvider == AIProvider.proxy) {
                        _selectedProvider = AIProvider.none;
                      }
                    });
                    _aiService.setProxyEnabled(false);
                    _aiService.setProvider(_selectedProvider);
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.setBool('ai_proxy_enabled', false);
                    await prefs.setInt('ai_provider', _selectedProvider.index);
                    await prefs.setString(
                      'ai_provider_name',
                      _selectedProvider.toString().split('.').last,
                    );
                    return;
                  }

                  final ok = await _aiService.checkProxyHealth();
                  if (!ok) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('The News AI unavailable. Check backend configuration.'),
                          backgroundColor: KAppColors.error,
                        ),
                      );
                    }
                    return;
                  }

                  setState(() {
                    _proxyEnabled = true;
                    _selectedProvider = AIProvider.proxy;
                  });
                  _aiService.setProxyEnabled(true);
                  _aiService.setProvider(AIProvider.proxy);
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setBool('ai_proxy_enabled', true);
                  await prefs.setInt('ai_provider', AIProvider.proxy.index);
                  await prefs.setString('ai_provider_name', 'proxy');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _proxyEnabled
                      ? KAppColors.getOnBackground(context).withValues(alpha: 0.08)
                      : KAppColors.getPrimary(context),
                  foregroundColor: _proxyEnabled
                      ? KAppColors.getOnBackground(context)
                      : KAppColors.getOnPrimary(context),
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: KBorderRadius.md,
                  ),
                ),
                child: Text(_proxyEnabled ? 'Disconnect' : 'Connect'),
              ),
              const SizedBox(width: KDesignConstants.spacing12),
              Text(
                    _proxyEnabled ? 'Using The News AI' : 'Tap connect to enable',
                style: KAppTextStyles.bodySmall.copyWith(
                  color: KAppColors.getOnBackground(context).withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCacheManager() {
    final cacheTtlDays = _aiMetadata?['cacheTtlDays'] as int? ?? 7;
    return Container(
      padding: KDesignConstants.paddingMd,
      decoration: BoxDecoration(
        color: KAppColors.getOnBackground(context).withValues(alpha: 0.05),
        borderRadius: KBorderRadius.md,
        border: Border.all(
          color: KAppColors.getOnBackground(context).withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.storage,
                color: KAppColors.getPrimary(context),
                size: 20,
              ),
              const SizedBox(width: KDesignConstants.spacing8),
              Text(
                'AI Response Cache',
                style: KAppTextStyles.titleSmall.copyWith(
                  color: KAppColors.getOnBackground(context),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: KDesignConstants.spacing12),
          Text(
            'Cached responses are stored for $cacheTtlDays days to reduce costs and improve speed.',
            style: KAppTextStyles.bodySmall.copyWith(
              color: KAppColors.getOnBackground(context).withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: KDesignConstants.spacing16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Cached Responses',
                    style: KAppTextStyles.labelSmall.copyWith(
                      color: KAppColors.getOnBackground(context).withValues(alpha: 0.6),
                    ),
                  ),
                  const SizedBox(height: KDesignConstants.spacing4),
                  Text(
                    '${_aiService.getCacheSize()}',
                    style: KAppTextStyles.titleLarge.copyWith(
                      color: KAppColors.getOnBackground(context),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              ElevatedButton.icon(
                onPressed: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Clear Cache'),
                      content: const Text(
                        'This will remove all cached AI responses. This action cannot be undone.',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text('Clear'),
                        ),
                      ],
                    ),
                  );

                  if (confirm == true) {
                    await _aiService.clearCache();
                    if (mounted) {
                      setState(() {});
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('Cache cleared successfully'),
                          backgroundColor: KAppColors.getPrimary(context),
                        ),
                      );
                    }
                  }
                },
                icon: const Icon(Icons.delete_sweep, size: 18),
                label: const Text('Clear Cache'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: KAppColors.error.withValues(alpha: 0.1),
                  foregroundColor: KAppColors.error,
                  elevation: 0,
                ),
              ),
            ],
          ),
          const SizedBox(height: KDesignConstants.spacing12),
          Container(
            padding: KDesignConstants.paddingSm,
            decoration: BoxDecoration(
              color: KAppColors.getPrimary(context).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 16,
                  color: KAppColors.getPrimary(context),
                ),
                const SizedBox(width: KDesignConstants.spacing8),
                Expanded(
                  child: Text(
                    'Cache reduces costs and improves speed for repeated queries',
                    style: KAppTextStyles.labelSmall.copyWith(
                      color: KAppColors.getPrimary(context),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProviderHealthSection() {
    final proxyAvailable = _proxyEnabled && (_proxyHealthy || _proxyProviders.isNotEmpty);
    return Container(
      padding: KDesignConstants.paddingMd,
      decoration: BoxDecoration(
        color: KAppColors.getOnBackground(context).withValues(alpha: 0.05),
        borderRadius: KBorderRadius.md,
        border: Border.all(
          color: KAppColors.getOnBackground(context).withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.health_and_safety,
                    color: KAppColors.getPrimary(context),
                    size: 20,
                  ),
                  const SizedBox(width: KDesignConstants.spacing8),
                  Text(
                    'Provider Health & Auto-Selection',
                    style: KAppTextStyles.titleSmall.copyWith(
                      color: KAppColors.getOnBackground(context),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Switch(
                value: _aiService.autoSelectEnabled,
                onChanged: (value) {
                  setState(() {
                    _aiService.setAutoSelection(value);
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: KDesignConstants.spacing8),
          Text(
            'Automatically switch to the best performing provider based on success rate and response time.',
            style: KAppTextStyles.bodySmall.copyWith(
              color: KAppColors.getOnBackground(context).withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: KDesignConstants.spacing16),
          if (_proxyEnabled)
            _buildProxyHealthCard(proxyAvailable),
          _buildBackendHealthCard(),
          ...AIProvider.values
              .where((p) => p != AIProvider.none)
              .map((provider) => _buildProviderHealthCard(provider)),
          const SizedBox(height: KDesignConstants.spacing12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                _aiService.resetAllProviderHealth();
                setState(() {});
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('All provider health stats reset'),
                    backgroundColor: KAppColors.getPrimary(context),
                  ),
                );
              },
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Reset All Stats'),
              style: OutlinedButton.styleFrom(
                foregroundColor: KAppColors.getPrimary(context),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackendHealthCard() {
    final available = _proxyHealthy;
    final providers = _proxyProviders.join(', ');
    final message = _proxyHealthMessage;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: KDesignConstants.paddingSm,
      decoration: BoxDecoration(
        color: available
            ? KAppColors.success.withValues(alpha: 0.1)
            : KAppColors.warning.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: available
              ? KAppColors.success.withValues(alpha: 0.3)
              : KAppColors.warning.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    available ? Icons.check_circle : Icons.warning,
                    color: available ? KAppColors.success : KAppColors.warning,
                    size: 20,
                  ),
                  const SizedBox(width: KDesignConstants.spacing8),
                  Text(
                    'Backend Health',
                    style: KAppTextStyles.titleSmall.copyWith(
                      color: KAppColors.getOnBackground(context),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Text(
                available ? 'Available' : 'Unavailable',
                style: KAppTextStyles.labelSmall.copyWith(
                  color: available ? KAppColors.success : KAppColors.warning,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: KDesignConstants.spacing8),
          if (providers.isNotEmpty)
            Text(
              'Providers: $providers',
              style: KAppTextStyles.bodySmall.copyWith(
                color: KAppColors.getOnBackground(context).withValues(alpha: 0.7),
              ),
            ),
          if (message != null && message.isNotEmpty) ...[
            const SizedBox(height: KDesignConstants.spacing6),
            Text(
              message,
              style: KAppTextStyles.labelSmall.copyWith(
                color: KAppColors.getOnBackground(context).withValues(alpha: 0.6),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildProviderHealthCard(AIProvider provider) {
    final health = _aiService.providerHealth[provider];
    if (health == null) return const SizedBox.shrink();

    final providerName = provider.toString().split('.').last.toUpperCase();
    final successRate = (health.successRate * 100).toStringAsFixed(1);
    final avgResponseTime = health.averageResponseTimeMs.toStringAsFixed(0);
    final healthScore = (health.healthScore * 100).toStringAsFixed(0);
    final isHealthy = health.isHealthy;
    final totalCalls = health.successCount + health.errorCount;

    if (totalCalls == 0) return const SizedBox.shrink(); // Don't show unused providers

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: KDesignConstants.paddingSm,
      decoration: BoxDecoration(
        color: isHealthy
            ? KAppColors.success.withValues(alpha: 0.1)
            : KAppColors.warning.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isHealthy
              ? KAppColors.success.withValues(alpha: 0.3)
              : KAppColors.warning.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    isHealthy ? Icons.check_circle : Icons.warning,
                    color: isHealthy ? KAppColors.success : KAppColors.warning,
                    size: 20,
                  ),
                  const SizedBox(width: KDesignConstants.spacing8),
                  Text(
                    providerName,
                    style: KAppTextStyles.titleSmall.copyWith(
                      color: KAppColors.getOnBackground(context),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: KAppColors.getPrimary(context).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'Score: $healthScore%',
                  style: KAppTextStyles.labelSmall.copyWith(
                    color: KAppColors.getPrimary(context),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: KDesignConstants.spacing8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildHealthStat('Success Rate', '$successRate%'),
              _buildHealthStat('Avg Response', '${avgResponseTime}ms'),
              _buildHealthStat('Total Calls', totalCalls.toString()),
            ],
          ),
          if (health.lastError != null) ...[
            const SizedBox(height: KDesignConstants.spacing8),
            Container(
              padding: KDesignConstants.paddingSm,
              decoration: BoxDecoration(
                color: KAppColors.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, size: 16, color: KAppColors.error),
                  const SizedBox(width: KDesignConstants.spacing8),
                  Expanded(
                    child: Text(
                      'Last error: ${_formatTimeSince(health.lastError!)}',
                      style: KAppTextStyles.labelSmall.copyWith(
                        color: KAppColors.error,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildProxyHealthCard(bool available) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: KDesignConstants.paddingSm,
      decoration: BoxDecoration(
        color: available
            ? KAppColors.success.withValues(alpha: 0.1)
            : KAppColors.warning.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: available
              ? KAppColors.success.withValues(alpha: 0.3)
              : KAppColors.warning.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(
                available ? Icons.check_circle : Icons.warning,
                color: available ? KAppColors.success : KAppColors.warning,
                size: 20,
              ),
              const SizedBox(width: KDesignConstants.spacing8),
              Text(
                'SERVER AI',
                style: KAppTextStyles.titleSmall.copyWith(
                  color: KAppColors.getOnBackground(context),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          Text(
            available ? 'Available' : 'Unavailable',
            style: KAppTextStyles.labelSmall.copyWith(
              color: available ? KAppColors.success : KAppColors.warning,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHealthStat(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: KAppTextStyles.labelSmall.copyWith(
            color: KAppColors.getOnBackground(context).withValues(alpha: 0.6),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: KAppTextStyles.bodyMedium.copyWith(
            color: KAppColors.getOnBackground(context),
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  String _formatTimeSince(DateTime dateTime) {
    final duration = DateTime.now().difference(dateTime);
    if (duration.inMinutes < 1) return 'just now';
    if (duration.inMinutes < 60) return '${duration.inMinutes}m ago';
    if (duration.inHours < 24) return '${duration.inHours}h ago';
    return '${duration.inDays}d ago';
  }
}
