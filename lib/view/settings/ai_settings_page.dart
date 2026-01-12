import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:the_news/constant/theme/default_theme.dart';
import 'package:the_news/service/ai_service.dart';

/// Page for configuring AI integration settings
class AISettingsPage extends StatefulWidget {
  const AISettingsPage({super.key});

  @override
  State<AISettingsPage> createState() => _AISettingsPageState();
}

class _AISettingsPageState extends State<AISettingsPage> {
  final AIService _aiService = AIService.instance;
  final TextEditingController _githubController = TextEditingController();
  final TextEditingController _openaiController = TextEditingController();
  final TextEditingController _geminiController = TextEditingController();
  final TextEditingController _claudeController = TextEditingController();

  AIProvider _selectedProvider = AIProvider.none;
  bool _isLoading = true;

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

      final providerIndex = prefs.getInt('ai_provider') ?? 0;
      _selectedProvider = AIProvider.values[providerIndex];

      // Set the selected provider
      _aiService.setProvider(_selectedProvider);
    } catch (e) {
      debugPrint('Error loading AI settings: $e');
    }

    setState(() => _isLoading = false);
  }

  Future<void> _saveSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      await prefs.setString('ai_github_pat', _githubController.text);
      await prefs.setString('ai_openai_key', _openaiController.text);
      await prefs.setString('ai_gemini_key', _geminiController.text);
      await prefs.setString('ai_claude_key', _claudeController.text);
      await prefs.setInt('ai_provider', _selectedProvider.index);

      // Set the selected provider
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
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: KAppColors.getBackground(context),
      appBar: AppBar(
        backgroundColor: KAppColors.getBackground(context),
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Icon(
            Icons.arrow_back_ios_new,
            color: KAppColors.getOnBackground(context),
          ),
        ),
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
                  const SizedBox(height: 24),
                  _buildProviderSelector(),
                  const SizedBox(height: 24),
                  // GitHub Models Section
                  Text(
                    'Free AI Models (GitHub)',
                    style: KAppTextStyles.titleMedium.copyWith(
                      color: KAppColors.getOnBackground(context),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildApiKeySection(
                    'GitHub Personal Access Token',
                    _githubController,
                    AIProvider.githubGpt4o,
                    'Cost: FREE - Access to GPT-4o-mini, DeepSeek, Llama, Grok',
                    'Get your PAT from github.com/settings/tokens',
                  ),
                  const SizedBox(height: 24),
                  // Paid AI Models Section
                  Text(
                    'Paid AI Models',
                    style: KAppTextStyles.titleMedium.copyWith(
                      color: KAppColors.getOnBackground(context),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildApiKeySection(
                    'OpenAI (GPT-4)',
                    _openaiController,
                    AIProvider.openai,
                    'Cost: ~\$0.0003 per article',
                    'Get your API key from platform.openai.com',
                  ),
                  const SizedBox(height: 16),
                  _buildApiKeySection(
                    'Google Gemini',
                    _geminiController,
                    AIProvider.gemini,
                    'Cost: ~\$0.0001 per article',
                    'Get your API key from makersuite.google.com',
                  ),
                  const SizedBox(height: 16),
                  _buildApiKeySection(
                    'Anthropic Claude',
                    _claudeController,
                    AIProvider.claude,
                    'Cost: ~\$0.0004 per article',
                    'Get your API key from console.anthropic.com',
                  ),
                  const SizedBox(height: 24),
                  _buildCostEstimator(),
                  const SizedBox(height: 24),
                  _buildCacheManager(),
                  const SizedBox(height: 24),
                  _buildProviderHealthSection(),
                ],
              ),
            ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            KAppColors.getPrimary(context).withValues(alpha: 0.1),
            KAppColors.getPrimary(context).withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            Icons.auto_awesome,
            color: KAppColors.getPrimary(context),
            size: 32,
          ),
          const SizedBox(width: 16),
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
                const SizedBox(height: 4),
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

  Widget _buildProviderSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Active Provider',
          style: KAppTextStyles.titleMedium.copyWith(
            color: KAppColors.getOnBackground(context),
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: KAppColors.getBackground(context),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: KAppColors.getOnBackground(context).withValues(alpha: 0.1),
            ),
          ),
          child: Column(
            children: [
              _buildProviderOption(AIProvider.none, 'None (Algorithm Only)', 'Free'),
              _buildDivider(),
              _buildProviderOption(AIProvider.githubGpt4o, 'GitHub GPT-4o-mini', 'Free - Recommended'),
              _buildDivider(),
              _buildProviderOption(AIProvider.githubDeepseek, 'GitHub DeepSeek', 'Free'),
              _buildDivider(),
              _buildProviderOption(AIProvider.githubLlama, 'GitHub Llama 3.1', 'Free'),
              _buildDivider(),
              _buildProviderOption(AIProvider.githubGrok, 'GitHub Grok', 'Free'),
              _buildDivider(),
              _buildProviderOption(AIProvider.openai, 'OpenAI GPT-4', 'Paid'),
              _buildDivider(),
              _buildProviderOption(AIProvider.gemini, 'Google Gemini', 'Paid'),
              _buildDivider(),
              _buildProviderOption(AIProvider.claude, 'Anthropic Claude', 'Paid'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProviderOption(AIProvider provider, String name, String badge) {
    final isSelected = _selectedProvider == provider;
    return InkWell(
      onTap: () => setState(() => _selectedProvider = provider),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
              color: isSelected
                  ? KAppColors.getPrimary(context)
                  : KAppColors.getOnBackground(context).withValues(alpha: 0.3),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                name,
                style: KAppTextStyles.bodyMedium.copyWith(
                  color: KAppColors.getOnBackground(context),
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: isSelected
                    ? KAppColors.getPrimary(context).withValues(alpha: 0.2)
                    : KAppColors.getOnBackground(context).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                badge,
                style: KAppTextStyles.labelSmall.copyWith(
                  color: isSelected
                      ? KAppColors.getPrimary(context)
                      : KAppColors.getOnBackground(context).withValues(alpha: 0.6),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(
      height: 1,
      color: KAppColors.getOnBackground(context).withValues(alpha: 0.1),
    );
  }

  Widget _buildApiKeySection(
    String title,
    TextEditingController controller,
    AIProvider provider,
    String costInfo,
    String helpText,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: KAppTextStyles.titleSmall.copyWith(
            color: KAppColors.getOnBackground(context),
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          obscureText: true,
          style: KAppTextStyles.bodyMedium.copyWith(
            color: KAppColors.getOnBackground(context),
          ),
          decoration: InputDecoration(
            hintText: 'Enter API key',
            hintStyle: KAppTextStyles.bodyMedium.copyWith(
              color: KAppColors.getOnBackground(context).withValues(alpha: 0.4),
            ),
            filled: true,
            fillColor: KAppColors.getBackground(context),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: KAppColors.getOnBackground(context).withValues(alpha: 0.1),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: KAppColors.getOnBackground(context).withValues(alpha: 0.1),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: KAppColors.getPrimary(context),
                width: 2,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          costInfo,
          style: KAppTextStyles.labelSmall.copyWith(
            color: KAppColors.getOnBackground(context).withValues(alpha: 0.6),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          helpText,
          style: KAppTextStyles.labelSmall.copyWith(
            color: KAppColors.getOnBackground(context).withValues(alpha: 0.5),
          ),
        ),
      ],
    );
  }

  Widget _buildCostEstimator() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: KAppColors.getOnBackground(context).withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
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
                Icons.calculate_outlined,
                color: KAppColors.getPrimary(context),
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Cost Estimator',
                style: KAppTextStyles.titleSmall.copyWith(
                  color: KAppColors.getOnBackground(context),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildCostRow('Daily digest (5 stories)', '\$0.0015 - \$0.0020'),
          _buildCostRow('Daily digest (10 stories)', '\$0.0030 - \$0.0040'),
          _buildCostRow('Monthly (30 digests, 5 stories each)', '\$0.045 - \$0.060'),
          const SizedBox(height: 12),
          Text(
            'Note: Costs are estimates. Without AI, the app uses algorithm-based summaries for free.',
            style: KAppTextStyles.labelSmall.copyWith(
              color: KAppColors.getOnBackground(context).withValues(alpha: 0.6),
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCostRow(String description, String cost) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            description,
            style: KAppTextStyles.bodySmall.copyWith(
              color: KAppColors.getOnBackground(context).withValues(alpha: 0.8),
            ),
          ),
          Text(
            cost,
            style: KAppTextStyles.bodySmall.copyWith(
              color: KAppColors.getOnBackground(context),
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCacheManager() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: KAppColors.getOnBackground(context).withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
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
              const SizedBox(width: 8),
              Text(
                'AI Response Cache',
                style: KAppTextStyles.titleSmall.copyWith(
                  color: KAppColors.getOnBackground(context),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Cached responses are stored for 7 days to reduce costs and improve speed.',
            style: KAppTextStyles.bodySmall.copyWith(
              color: KAppColors.getOnBackground(context).withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 16),
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
                  const SizedBox(height: 4),
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
                  backgroundColor: Colors.red.withValues(alpha: 0.1),
                  foregroundColor: Colors.red,
                  elevation: 0,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
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
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Cache helps reduce API costs by up to 80% for repeated queries',
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
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: KAppColors.getOnBackground(context).withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
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
                  const SizedBox(width: 8),
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
          const SizedBox(height: 8),
          Text(
            'Automatically switch to the best performing provider based on success rate and response time.',
            style: KAppTextStyles.bodySmall.copyWith(
              color: KAppColors.getOnBackground(context).withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 16),
          ...AIProvider.values
              .where((p) => p != AIProvider.none)
              .map((provider) => _buildProviderHealthCard(provider)),
          const SizedBox(height: 12),
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
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isHealthy
            ? Colors.green.withValues(alpha: 0.1)
            : Colors.orange.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isHealthy
              ? Colors.green.withValues(alpha: 0.3)
              : Colors.orange.withValues(alpha: 0.3),
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
                    color: isHealthy ? Colors.green : Colors.orange,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
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
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildHealthStat('Success Rate', '$successRate%'),
              _buildHealthStat('Avg Response', '${avgResponseTime}ms'),
              _buildHealthStat('Total Calls', totalCalls.toString()),
            ],
          ),
          if (health.lastError != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, size: 16, color: Colors.red),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Last error: ${_formatTimeSince(health.lastError!)}',
                      style: KAppTextStyles.labelSmall.copyWith(
                        color: Colors.red,
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
