import 'package:flutter/material.dart';
import 'package:the_news/view/widgets/k_app_bar.dart';
import 'package:flutter/services.dart';
import 'package:the_news/constant/enhanced_typography.dart';
import 'package:the_news/service/auth_service.dart';
import 'package:the_news/core/network/api_client.dart';
import 'package:webview_flutter/webview_flutter.dart';

/// Payment Methods Page - Displays user's saved payment methods
/// Uses ApiClient for all network requests following clean architecture
class PaymentMethodsPage extends StatefulWidget {
  const PaymentMethodsPage({super.key});

  @override
  State<PaymentMethodsPage> createState() => _PaymentMethodsPageState();
}

class _PaymentMethodsPageState extends State<PaymentMethodsPage> {
  final _authService = AuthService();
  final _api = ApiClient.instance;

  List<Map<String, dynamic>> _paymentMethods = [];
  bool _isLoading = true;
  String? _error;
  String? _addPaymentMethodUrl;
  bool _endpointAvailable = true;

  @override
  void initState() {
    super.initState();
    _loadPaymentMethods();
  }

  Future<void> _loadPaymentMethods() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final userData = await _authService.getCurrentUser();
      final userId = userData?['id'] as String? ?? userData?['userId'] as String?;

      if (userId == null) {
        setState(() {
          _error = 'Please sign in to view payment methods';
          _isLoading = false;
        });
        return;
      }

      // Fetch payment methods from backend
      final response = await _api.get(
        'subscriptions/payment-methods/$userId',
        requiresAuth: true,
        timeout: const Duration(seconds: 30),
      );

      if (_api.isSuccess(response)) {
        final data = _api.parseJson(response);
        if (data['success'] == true) {
          setState(() {
            _paymentMethods = List<Map<String, dynamic>>.from(
              data['paymentMethods'] ?? [],
            );
            _addPaymentMethodUrl =
                data['addPaymentMethodUrl'] ?? data['addCardUrl'];
            _endpointAvailable = true;
            _isLoading = false;
          });
        } else {
          setState(() {
            _error = data['message'] ?? 'Failed to load payment methods';
            _isLoading = false;
          });
        }
      } else if (response.statusCode == 404) {
        setState(() {
          _paymentMethods = [];
          _addPaymentMethodUrl = null;
          _endpointAvailable = false;
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = _api.getErrorMessage(response);
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Error: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: KAppBar(
        title: const Text('Payment Methods'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadPaymentMethods,
          ),
        ],
      ),
      body: _buildBody(colorScheme),
    );
  }

  Widget _buildBody(ColorScheme colorScheme) {
    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(
          color: colorScheme.primary,
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(Spacing.lg),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: colorScheme.error,
              ),
              const SizedBox(height: Spacing.md),
              Text(
                _error!,
                style: EnhancedTypography.bodyLarge.copyWith(
                  color: colorScheme.onSurface,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: Spacing.lg),
              ElevatedButton(
                onPressed: _loadPaymentMethods,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_paymentMethods.isEmpty) {
      return _buildEmptyState(colorScheme);
    }

    return RefreshIndicator(
      onRefresh: _loadPaymentMethods,
      child: ListView(
        padding: const EdgeInsets.all(Spacing.md),
        children: [
          _buildHeader(colorScheme),
          if (_addPaymentMethodUrl != null) ...[
            const SizedBox(height: Spacing.md),
            _buildAddCardCTA(colorScheme),
          ],
          const SizedBox(height: Spacing.md),
          ..._paymentMethods.map(
            (method) => _buildPaymentMethodCard(method, colorScheme),
          ),
          const SizedBox(height: Spacing.lg),
          _buildSecurityNote(colorScheme),
        ],
      ),
    );
  }

  Widget _buildEmptyState(ColorScheme colorScheme) {
    if (!_endpointAvailable) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(Spacing.lg),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.credit_card_off_outlined,
                size: 64,
                color: colorScheme.onSurface.withValues(alpha: 0.6),
              ),
              const SizedBox(height: Spacing.md),
              Text(
                'Payment methods are unavailable',
                style: EnhancedTypography.bodyLarge.copyWith(
                  color: colorScheme.onSurface,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: Spacing.sm),
              Text(
                'Please try again later.',
                style: EnhancedTypography.bodyMedium.copyWith(
                  color: colorScheme.onSurface.withValues(alpha: 0.7),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(Spacing.lg),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                shape: BoxShape.circle,
                border: Border.all(
                  color: colorScheme.outline.withValues(alpha: 0.2),
                ),
              ),
              child: Icon(
                Icons.credit_card_outlined,
                size: 48,
                color: colorScheme.primary.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: Spacing.lg),
            Text(
              'No saved payment methods',
              style: EnhancedTypography.headlineSmall.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: Spacing.sm),
            Text(
              'Your card is saved securely after your first subscription payment.',
              style: EnhancedTypography.bodyMedium.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            if (_addPaymentMethodUrl != null) ...[
              const SizedBox(height: Spacing.lg),
              _buildAddCardCTA(colorScheme),
            ],
            const SizedBox(height: Spacing.lg),
            _buildSecurityNote(colorScheme),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String text, ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.only(top: Spacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.check_circle,
            size: 16,
            color: colorScheme.primary,
          ),
          const SizedBox(width: Spacing.xs),
          Expanded(
            child: Text(
              text,
              style: EnhancedTypography.bodySmall.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodCard(
    Map<String, dynamic> method,
    ColorScheme colorScheme,
  ) {
    final isDefault = method['isDefault'] as bool? ?? false;
    final cardType = method['cardType'] as String? ?? 'card';
    final last4 = method['last4'] as String? ?? '****';
    final expiryMonth = method['expiryMonth'] as String?;
    final expiryYear = method['expiryYear'] as String?;
    final bank = method['bank'] as String?;
    final lastUsed = method['lastUsed'] ??
        method['lastUsedAt'] ??
        method['last_used'] ??
        method['last_used_at'];

    // Get card icon and color
    final cardIcon = _getCardIcon(cardType);
    final cardColor = _getCardColor(cardType, colorScheme);

    return Container(
      margin: const EdgeInsets.only(bottom: Spacing.md),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: AppRadius.radiusLg,
        border: Border.all(
          color: isDefault
              ? colorScheme.primary
              : colorScheme.outline.withValues(alpha: 0.2),
          width: isDefault ? 1.6 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => _showPaymentMethodOptions(method),
        borderRadius: AppRadius.radiusLg,
        child: Padding(
          padding: const EdgeInsets.all(Spacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(Spacing.sm),
                    decoration: BoxDecoration(
                      color: cardColor.withValues(alpha: 0.15),
                      borderRadius: AppRadius.radiusSm,
                    ),
                    child: Icon(
                      cardIcon,
                      color: cardColor,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: Spacing.sm),
                  Expanded(
                    child: Text(
                      '•••• $last4',
                      style: EnhancedTypography.titleMedium.copyWith(
                        color: colorScheme.onSurface,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                  if (isDefault)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: Spacing.sm,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: colorScheme.primary.withValues(alpha: 0.15),
                        borderRadius: AppRadius.radiusSm,
                      ),
                      child: Text(
                        'DEFAULT',
                        style: EnhancedTypography.labelSmall.copyWith(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  if (!isDefault)
                    TextButton(
                      onPressed: () => _setAsDefault(method),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: Spacing.sm,
                          vertical: 4,
                        ),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        foregroundColor: colorScheme.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: AppRadius.radiusSm,
                          side: BorderSide(
                            color: colorScheme.primary.withValues(alpha: 0.4),
                          ),
                        ),
                      ),
                      child: Text(
                        'Set default',
                        style: EnhancedTypography.labelSmall.copyWith(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: Spacing.sm),
              Row(
                children: [
                  Text(
                    cardType.toUpperCase(),
                    style: EnhancedTypography.labelSmall.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      letterSpacing: 1.2,
                    ),
                  ),
                  if (bank != null) ...[
                    const SizedBox(width: Spacing.sm),
                    Container(
                      width: 4,
                      height: 4,
                      decoration: BoxDecoration(
                        color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: Spacing.sm),
                    Expanded(
                      child: Text(
                        bank,
                        style: EnhancedTypography.bodySmall.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ],
              ),
              if (expiryMonth != null && expiryYear != null) ...[
                const SizedBox(height: Spacing.xs),
                Text(
                  'Expires $expiryMonth/$expiryYear',
                  style: EnhancedTypography.bodySmall.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
              if (lastUsed != null) ...[
                const SizedBox(height: Spacing.xs),
                Text(
                  'Last used ${_formatLastUsed(lastUsed)}',
                  style: EnhancedTypography.bodySmall.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(Spacing.md),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: AppRadius.radiusLg,
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: colorScheme.primary.withValues(alpha: 0.12),
              borderRadius: AppRadius.radiusMd,
            ),
            child: Icon(
              Icons.credit_card,
              color: colorScheme.primary,
            ),
          ),
          const SizedBox(width: Spacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your saved payment methods',
                  style: EnhancedTypography.titleSmall.copyWith(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Manage defaults or remove cards anytime.',
                  style: EnhancedTypography.bodySmall.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSecurityNote(ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(Spacing.md),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: AppRadius.radiusLg,
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.lock,
            color: colorScheme.primary,
          ),
          const SizedBox(width: Spacing.sm),
          Expanded(
            child: Text(
              'Your payment info is encrypted and stored securely by our processor.',
              style: EnhancedTypography.bodySmall.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddCardCTA(ColorScheme colorScheme) {
    return SizedBox(
      height: 48,
      child: OutlinedButton.icon(
        onPressed: _openAddCardFlow,
        icon: const Icon(Icons.add),
        label: Text(
          'Add new card',
          style: EnhancedTypography.labelLarge.copyWith(
            color: colorScheme.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: colorScheme.primary,
          side: BorderSide(color: colorScheme.primary.withValues(alpha: 0.4)),
          shape: RoundedRectangleBorder(borderRadius: AppRadius.radiusMd),
        ),
      ),
    );
  }

  String _formatLastUsed(dynamic value) {
    DateTime? parsed;
    if (value is String) {
      parsed = DateTime.tryParse(value);
    } else if (value is int) {
      parsed = DateTime.fromMillisecondsSinceEpoch(value);
    }
    if (parsed == null) return value.toString();

    final now = DateTime.now();
    final diff = now.difference(parsed);
    if (diff.inDays == 0) return 'today';
    if (diff.inDays == 1) return 'yesterday';
    if (diff.inDays < 7) return '${diff.inDays} days ago';
    return '${parsed.day}/${parsed.month}/${parsed.year}';
  }

  void _openAddCardFlow() {
    final url = _addPaymentMethodUrl;
    if (url == null) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: KAppBar(title: const Text('Add Payment Method')),
          body: WebViewWidget(
            controller: WebViewController()..loadRequest(Uri.parse(url)),
          ),
        ),
      ),
    );
  }

  IconData _getCardIcon(String cardType) {
    switch (cardType.toLowerCase()) {
      case 'visa':
        return Icons.credit_card;
      case 'mastercard':
        return Icons.credit_card;
      case 'verve':
        return Icons.credit_card;
      default:
        return Icons.payment;
    }
  }

  Color _getCardColor(String cardType, ColorScheme colorScheme) {
    switch (cardType.toLowerCase()) {
      case 'visa':
        return Colors.blue;
      case 'mastercard':
        return Colors.red;
      case 'verve':
        return Colors.green;
      default:
        return colorScheme.primary;
    }
  }

  void _showPaymentMethodOptions(Map<String, dynamic> method) {
    final isDefault = method['isDefault'] as bool? ?? false;

    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: Spacing.sm),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(context)
                    .colorScheme
                    .onSurfaceVariant
                    .withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: Spacing.md),
            if (!isDefault)
              ListTile(
                leading: const Icon(Icons.check_circle_outline),
                title: const Text('Set as Default'),
                onTap: () {
                  Navigator.pop(context);
                  _setAsDefault(method);
                },
              ),
            ListTile(
              leading: const Icon(Icons.content_copy),
              title: const Text('Copy Authorization Code'),
              onTap: () {
                Navigator.pop(context);
                _copyAuthorizationCode(method);
              },
            ),
            const Divider(height: 1),
            ListTile(
              leading: Icon(
                Icons.delete_outline,
                color: Theme.of(context).colorScheme.error,
              ),
              title: Text(
                'Remove Payment Method',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                _confirmRemovePaymentMethod(method);
              },
            ),
            const SizedBox(height: Spacing.sm),
          ],
        ),
      ),
    );
  }

  Future<void> _setAsDefault(Map<String, dynamic> method) async {
    try {
      final userData = await _authService.getCurrentUser();
      final userId = userData?['id'] as String? ?? userData?['userId'] as String?;
      if (userId == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please sign in to update payment methods'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        return;
      }

      final authorizationCode = method['authorizationCode'] as String?;
      if (authorizationCode == null) return;

      final response = await _api.put(
        'subscriptions/payment-methods/$userId/default',
        body: {'authorizationCode': authorizationCode},
        requiresAuth: true,
        timeout: const Duration(seconds: 20),
      );

      if (_api.isSuccess(response)) {
        await _loadPaymentMethods();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Default payment method updated'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(_api.getErrorMessage(response)),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update default: ${e.toString()}'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _copyAuthorizationCode(Map<String, dynamic> method) {
    final authCode = method['authorizationCode'] as String?;
    if (authCode != null) {
      Clipboard.setData(ClipboardData(text: authCode));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Authorization code copied'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _confirmRemovePaymentMethod(Map<String, dynamic> method) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Payment Method?'),
        content: const Text(
          'Are you sure you want to remove this payment method? This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _removePaymentMethod(method);
            },
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }

  Future<void> _removePaymentMethod(Map<String, dynamic> method) async {
    try {
      final userData = await _authService.getCurrentUser();
      final userId = userData?['id'] as String? ?? userData?['userId'] as String?;
      if (userId == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please sign in to update payment methods'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        return;
      }

      final authorizationCode = method['authorizationCode'] as String?;
      if (authorizationCode == null) return;

      final response = await _api.delete(
        'subscriptions/payment-methods/$userId',
        body: {'authorizationCode': authorizationCode},
        requiresAuth: true,
        timeout: const Duration(seconds: 20),
      );

      if (_api.isSuccess(response)) {
        await _loadPaymentMethods();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Payment method removed'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(_api.getErrorMessage(response)),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to remove method: ${e.toString()}'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}
