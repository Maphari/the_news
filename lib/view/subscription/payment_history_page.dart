import 'package:flutter/material.dart';
import 'package:the_news/constant/theme/enhanced_typography.dart';
import 'package:the_news/service/payment_service.dart';
import 'package:the_news/service/auth_service.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';

class PaymentHistoryPage extends StatefulWidget {
  const PaymentHistoryPage({super.key});

  @override
  State<PaymentHistoryPage> createState() => _PaymentHistoryPageState();
}

class _PaymentHistoryPageState extends State<PaymentHistoryPage> {
  final _paymentService = PaymentService.instance;
  final _authService = AuthService();

  List<Map<String, dynamic>> _paymentHistory = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadPaymentHistory();
  }

  Future<void> _loadPaymentHistory() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final userData = await _authService.getCurrentUser();
      final userId = userData?['id'] as String?;

      if (userId == null) {
        setState(() {
          _error = 'Please sign in to view payment history';
          _isLoading = false;
        });
        return;
      }

      // Fetch payment history from backend
      final response = await http.get(
        Uri.parse('${_paymentService.backendBaseUrl}/subscriptions/history/$userId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success']) {
          setState(() {
            _paymentHistory = List<Map<String, dynamic>>.from(data['history'] ?? []);
            _isLoading = false;
          });
        } else {
          setState(() {
            _error = data['message'] ?? 'Failed to load payment history';
            _isLoading = false;
          });
        }
      } else {
        setState(() {
          _error = 'Failed to load payment history';
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
        title: const Text('Payment History'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadPaymentHistory,
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
                onPressed: _loadPaymentHistory,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_paymentHistory.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(Spacing.lg),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.receipt_long_outlined,
                size: 64,
                color: colorScheme.onSurfaceVariant,
              ),
              const SizedBox(height: Spacing.md),
              Text(
                'No Payment History',
                style: EnhancedTypography.headlineSmall.copyWith(
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: Spacing.sm),
              Text(
                'Your payment transactions will appear here',
                style: EnhancedTypography.bodyMedium.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadPaymentHistory,
      child: ListView.builder(
        padding: const EdgeInsets.all(Spacing.md),
        itemCount: _paymentHistory.length,
        itemBuilder: (context, index) {
          final payment = _paymentHistory[index];
          return _buildPaymentCard(payment, colorScheme);
        },
      ),
    );
  }

  Widget _buildPaymentCard(Map<String, dynamic> payment, ColorScheme colorScheme) {
    final plan = payment['plan'] as String?;
    final amount = payment['amount'] as num?;
    final currency = payment['currency'] as String? ?? 'ZAR';
    final status = payment['status'] as String? ?? 'unknown';
    final reference = payment['reference'] as String?;
    final paymentDateStr = payment['paymentDate'] as String?;
    final subscriptionEndDateStr = payment['subscriptionEndDate'] as String?;

    // Parse dates
    DateTime? paymentDate;
    DateTime? subscriptionEndDate;
    if (paymentDateStr != null) {
      paymentDate = DateTime.tryParse(paymentDateStr);
    }
    if (subscriptionEndDateStr != null) {
      subscriptionEndDate = DateTime.tryParse(subscriptionEndDateStr);
    }

    // Format amount (convert from kobo to currency)
    final displayAmount = amount != null ? (amount / 100).toStringAsFixed(2) : '0.00';

    // Status color
    Color statusColor;
    IconData statusIcon;
    switch (status.toLowerCase()) {
      case 'success':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      case 'failed':
        statusColor = Colors.red;
        statusIcon = Icons.cancel;
        break;
      case 'pending':
        statusColor = Colors.orange;
        statusIcon = Icons.pending;
        break;
      default:
        statusColor = colorScheme.onSurfaceVariant;
        statusIcon = Icons.help_outline;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: Spacing.md),
      child: InkWell(
        onTap: () => _showPaymentDetails(payment),
        borderRadius: AppRadius.radiusLg,
        child: Padding(
          padding: const EdgeInsets.all(Spacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Amount and Status
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '$currency $displayAmount',
                    style: EnhancedTypography.headlineSmall.copyWith(
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: Spacing.sm,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.2),
                      borderRadius: AppRadius.radiusSm,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          statusIcon,
                          size: 16,
                          color: statusColor,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          status.toUpperCase(),
                          style: EnhancedTypography.labelSmall.copyWith(
                            color: statusColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: Spacing.sm),

              // Plan type
              Row(
                children: [
                  Icon(
                    Icons.card_membership,
                    size: 20,
                    color: colorScheme.primary,
                  ),
                  const SizedBox(width: Spacing.xs),
                  Text(
                    _getPlanDisplayName(plan),
                    style: EnhancedTypography.titleMedium.copyWith(
                      color: colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: Spacing.xs),

              // Payment date
              if (paymentDate != null)
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      size: 16,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: Spacing.xs),
                    Text(
                      DateFormat('MMM dd, yyyy HH:mm').format(paymentDate),
                      style: EnhancedTypography.bodySmall.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),

              // Subscription end date
              if (subscriptionEndDate != null) ...[
                const SizedBox(height: Spacing.xs),
                Row(
                  children: [
                    Icon(
                      Icons.event,
                      size: 16,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: Spacing.xs),
                    Text(
                      'Active until ${DateFormat('MMM dd, yyyy').format(subscriptionEndDate)}',
                      style: EnhancedTypography.bodySmall.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ],

              // Reference
              if (reference != null) ...[
                const SizedBox(height: Spacing.xs),
                Row(
                  children: [
                    Icon(
                      Icons.tag,
                      size: 16,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: Spacing.xs),
                    Expanded(
                      child: Text(
                        reference,
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

  String _getPlanDisplayName(String? plan) {
    switch (plan?.toLowerCase()) {
      case 'monthly':
        return 'Monthly Premium';
      case 'yearly':
        return 'Yearly Premium';
      default:
        return plan ?? 'Premium Subscription';
    }
  }

  void _showPaymentDetails(Map<String, dynamic> payment) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) {
          return PaymentDetailsSheet(
            payment: payment,
            scrollController: scrollController,
          );
        },
      ),
    );
  }
}

/// Bottom sheet for detailed payment information
class PaymentDetailsSheet extends StatelessWidget {
  final Map<String, dynamic> payment;
  final ScrollController scrollController;

  const PaymentDetailsSheet({
    super.key,
    required this.payment,
    required this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: Spacing.sm),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Title
          Padding(
            padding: const EdgeInsets.all(Spacing.lg),
            child: Row(
              children: [
                Icon(
                  Icons.receipt_long,
                  color: colorScheme.primary,
                ),
                const SizedBox(width: Spacing.sm),
                Text(
                  'Payment Details',
                  style: EnhancedTypography.headlineSmall.copyWith(
                    color: colorScheme.onSurface,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          // Details list
          Expanded(
            child: ListView(
              controller: scrollController,
              padding: const EdgeInsets.symmetric(horizontal: Spacing.lg),
              children: [
                _buildDetailRow(
                  'Reference',
                  payment['reference']?.toString() ?? 'N/A',
                  colorScheme,
                ),
                _buildDetailRow(
                  'Plan',
                  payment['plan']?.toString().toUpperCase() ?? 'N/A',
                  colorScheme,
                ),
                _buildDetailRow(
                  'Amount',
                  '${payment['currency'] ?? 'ZAR'} ${((payment['amount'] ?? 0) / 100).toStringAsFixed(2)}',
                  colorScheme,
                ),
                _buildDetailRow(
                  'Status',
                  payment['status']?.toString().toUpperCase() ?? 'N/A',
                  colorScheme,
                ),
                if (payment['paymentDate'] != null)
                  _buildDetailRow(
                    'Payment Date',
                    DateFormat('MMM dd, yyyy HH:mm').format(
                      DateTime.parse(payment['paymentDate']),
                    ),
                    colorScheme,
                  ),
                if (payment['subscriptionStartDate'] != null)
                  _buildDetailRow(
                    'Subscription Start',
                    DateFormat('MMM dd, yyyy').format(
                      DateTime.parse(payment['subscriptionStartDate']),
                    ),
                    colorScheme,
                  ),
                if (payment['subscriptionEndDate'] != null)
                  _buildDetailRow(
                    'Subscription End',
                    DateFormat('MMM dd, yyyy').format(
                      DateTime.parse(payment['subscriptionEndDate']),
                    ),
                    colorScheme,
                  ),
                const SizedBox(height: Spacing.xl),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Spacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: EnhancedTypography.bodyMedium.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: EnhancedTypography.bodyMedium.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }
}
