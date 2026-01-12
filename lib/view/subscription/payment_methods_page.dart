import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:the_news/constant/theme/enhanced_typography.dart';
import 'package:the_news/service/auth_service.dart';
import 'package:the_news/core/network/api_client.dart';

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
      final userId = userData?['id'] as String?;

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
        timeout: const Duration(seconds: 30),
      );

      if (_api.isSuccess(response)) {
        final data = _api.parseJson(response);
        if (data['success'] == true) {
          setState(() {
            _paymentMethods = List<Map<String, dynamic>>.from(
              data['paymentMethods'] ?? [],
            );
            _isLoading = false;
          });
        } else {
          setState(() {
            _error = data['message'] ?? 'Failed to load payment methods';
            _isLoading = false;
          });
        }
      } else if (response.statusCode == 404) {
        // Endpoint not implemented yet
        setState(() {
          _paymentMethods = [];
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
      appBar: AppBar(
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
      child: ListView.builder(
        padding: const EdgeInsets.all(Spacing.md),
        itemCount: _paymentMethods.length,
        itemBuilder: (context, index) {
          final method = _paymentMethods[index];
          return _buildPaymentMethodCard(method, colorScheme);
        },
      ),
    );
  }

  Widget _buildEmptyState(ColorScheme colorScheme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(Spacing.lg),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer.withValues(alpha: 0.3),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.credit_card_outlined,
                size: 60,
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(height: Spacing.xl),
            Text(
              'No Payment Methods',
              style: EnhancedTypography.headlineSmall.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: Spacing.sm),
            Text(
              'Your payment methods will be saved when you\nsubscribe to a premium plan',
              style: EnhancedTypography.bodyMedium.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: Spacing.xl),
            Container(
              padding: const EdgeInsets.all(Spacing.md),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                borderRadius: AppRadius.radiusMd,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 20,
                        color: colorScheme.primary,
                      ),
                      const SizedBox(width: Spacing.xs),
                      Text(
                        'How It Works',
                        style: EnhancedTypography.titleSmall.copyWith(
                          color: colorScheme.onSurface,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: Spacing.sm),
                  _buildInfoRow(
                    '1. Subscribe to a premium plan',
                    colorScheme,
                  ),
                  _buildInfoRow(
                    '2. Your payment details are securely saved',
                    colorScheme,
                  ),
                  _buildInfoRow(
                    '3. Manage or remove them anytime here',
                    colorScheme,
                  ),
                ],
              ),
            ),
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
    final authorizationCode = method['authorizationCode'] as String?;

    // Get card icon and color
    final cardIcon = _getCardIcon(cardType);
    final cardColor = _getCardColor(cardType, colorScheme);

    return Card(
      margin: const EdgeInsets.only(bottom: Spacing.md),
      child: InkWell(
        onTap: () => _showPaymentMethodOptions(method),
        borderRadius: AppRadius.radiusLg,
        child: Container(
          padding: const EdgeInsets.all(Spacing.md),
          decoration: BoxDecoration(
            borderRadius: AppRadius.radiusLg,
            border: isDefault
                ? Border.all(color: colorScheme.primary, width: 2)
                : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Card type and default badge
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(Spacing.sm),
                    decoration: BoxDecoration(
                      color: cardColor.withValues(alpha: 0.2),
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          cardType.toUpperCase(),
                          style: EnhancedTypography.labelSmall.copyWith(
                            color: colorScheme.onSurfaceVariant,
                            letterSpacing: 1.2,
                          ),
                        ),
                        Text(
                          '•••• $last4',
                          style: EnhancedTypography.titleMedium.copyWith(
                            color: colorScheme.onSurface,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isDefault)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: Spacing.sm,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: colorScheme.primary.withValues(alpha: 0.2),
                        borderRadius: AppRadius.radiusSm,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.check_circle,
                            size: 14,
                            color: colorScheme.primary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'DEFAULT',
                            style: EnhancedTypography.labelSmall.copyWith(
                              color: colorScheme.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: Spacing.sm),

              // Card details
              Row(
                children: [
                  if (expiryMonth != null && expiryYear != null) ...[
                    Icon(
                      Icons.calendar_today,
                      size: 14,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Expires $expiryMonth/$expiryYear',
                      style: EnhancedTypography.bodySmall.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                  if (bank != null) ...[
                    if (expiryMonth != null && expiryYear != null)
                      const SizedBox(width: Spacing.md),
                    Icon(
                      Icons.account_balance,
                      size: 14,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 4),
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

              // Authorization code (for debugging)
              if (authorizationCode != null) ...[
                const SizedBox(height: Spacing.xs),
                Row(
                  children: [
                    Icon(
                      Icons.verified_user,
                      size: 14,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        authorizationCode,
                        style: EnhancedTypography.bodySmall.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          fontFamily: 'monospace',
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ],
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
    // TODO: Implement set as default API call
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Set as default - Feature coming soon'),
          behavior: SnackBarBehavior.floating,
        ),
      );
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
    // TODO: Implement remove payment method API call
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Remove payment method - Feature coming soon'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}
