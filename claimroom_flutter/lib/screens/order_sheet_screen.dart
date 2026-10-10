import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:claimroom_client/claimroom_client.dart';
import '../client.dart';
import '../utils/error_helper.dart';

class OrderSheetScreen extends StatefulWidget {
  final int roomId;
  final String roomTitle;
  final String sellerKey;

  const OrderSheetScreen({
    super.key,
    required this.roomId,
    required this.roomTitle,
    required this.sellerKey,
  });

  @override
  State<OrderSheetScreen> createState() => _OrderSheetScreenState();
}

class _OrderSheetScreenState extends State<OrderSheetScreen> {
  OrderSheet? _orderSheet;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadOrderSheet();
  }

  Future<void> _loadOrderSheet() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final sheet = await client.room.getOrderSheet(
        widget.roomId,
        widget.sellerKey,
      );
      setState(() {
        _orderSheet = sheet;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = friendlyErrorMessage(e);
        _isLoading = false;
      });
    }
  }

  Future<void> _togglePaid(Item item) async {
    try {
      final updated = await client.room.markPaid(
        item.id!,
        widget.sellerKey,
        !item.paid,
      );

      setState(() {
        if (_orderSheet != null) {
          for (final buyer in _orderSheet!.buyers) {
            final idx = buyer.items.indexWhere((i) => i.id == updated.id);
            if (idx != -1) {
              buyer.items[idx] = updated;
            }
          }
          // Recalculate paid and unpaid sums
          double paidSum = 0;
          double unpaidSum = 0;
          for (final buyer in _orderSheet!.buyers) {
            for (final i in buyer.items) {
              final t = i.price * i.quantity;
              if (i.paid) {
                paidSum += t;
              } else {
                unpaidSum += t;
              }
            }
          }
          _orderSheet!.totalPaid = paidSum;
          _orderSheet!.totalUnpaid = unpaidSum;
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(friendlyErrorMessage(e)),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    }
  }

  String _generateWhatsAppSummary(OrderSheet sheet) {
    final buffer = StringBuffer();
    buffer.writeln('🎉 *Order Summary: ${sheet.roomTitle}*');
    buffer.writeln('Seller: ${sheet.sellerName}');
    buffer.writeln(
      'Items Sold: ${sheet.totalItemsSold} of ${sheet.totalItems}',
    );
    buffer.writeln('Grand Total: ₹${sheet.grandTotal.toStringAsFixed(0)}');
    final paidVal = sheet.totalPaid;
    final unpaidVal = sheet.totalUnpaid;
    buffer.writeln(
      'Paid: ₹${paidVal.toStringAsFixed(0)} | Unpaid: ₹${unpaidVal.toStringAsFixed(0)}',
    );
    buffer.writeln('-----------------------------------');

    for (final buyer in sheet.buyers) {
      buffer.writeln();
      final contact =
          buyer.buyerContact != null && buyer.buyerContact!.isNotEmpty
          ? ' (${buyer.buyerContact})'
          : '';
      buffer.writeln('👤 *${buyer.buyerName}*$contact');
      for (final item in buyer.items) {
        final qtyStr = item.quantity > 1 ? ' (x${item.quantity})' : '';
        final lineTotal = item.price * item.quantity;
        final paidTag = item.paid ? ' [PAID]' : ' [UNPAID]';
        buffer.writeln(
          '  • ${item.name}$qtyStr - ₹${lineTotal.toStringAsFixed(0)}$paidTag',
        );
      }
      buffer.writeln('  *Subtotal: ₹${buyer.totalAmount.toStringAsFixed(0)}*');
    }

    buffer.writeln();
    buffer.writeln('Generated via ClaimRoom ⚡');
    return buffer.toString();
  }

  void _copyCsv() {
    if (_orderSheet == null) return;
    final buffer = StringBuffer();
    buffer.writeln('Buyer,Items,Quantity,Total,Paid');
    for (final buyer in _orderSheet!.buyers) {
      for (final item in buyer.items) {
        final itemTotal = (item.price * item.quantity).toStringAsFixed(2);
        final isPaid = item.paid ? 'Paid' : 'Unpaid';
        final bName = buyer.buyerName.replaceAll('"', '""');
        final iName = item.name.replaceAll('"', '""');
        buffer.writeln('"$bName","$iName",${item.quantity},$itemTotal,$isPaid');
      }
    }
    Clipboard.setData(ClipboardData(text: buffer.toString()));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Order sheet copied as CSV to clipboard!'),
        backgroundColor: Color(0xFF10B981),
      ),
    );
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('WhatsApp summary copied to clipboard!'),
        backgroundColor: Color(0xFF10B981),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.roomTitle} - Order Sheet'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadOrderSheet,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _buildBody(theme),
    );
  }

  Widget _buildBody(ThemeData theme) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 12),
            Text('Failed to load order sheet: $_error'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadOrderSheet,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    final sheet = _orderSheet!;
    final totalPaid = sheet.totalPaid;
    final totalUnpaid = sheet.totalUnpaid;
    final isDark = theme.brightness == Brightness.dark;
    final paidStatColor = isDark
        ? const Color(0xFF34D399)
        : const Color(0xFF047857);
    final unpaidStatColor = isDark
        ? const Color(0xFFFBBF24)
        : const Color(0xFFB45309);

    DateTime? earliestSoldAt;
    for (final buyer in sheet.buyers) {
      for (final item in buyer.items) {
        if (item.soldAt != null) {
          if (earliestSoldAt == null || item.soldAt!.isBefore(earliestSoldAt)) {
            earliestSoldAt = item.soldAt;
          }
        }
      }
    }

    String durationStr = '< 1 min';
    if (earliestSoldAt != null) {
      final diff = sheet.generatedAt.difference(earliestSoldAt);
      if (diff.inHours >= 1) {
        durationStr = '${diff.inHours}h ${diff.inMinutes.remainder(60)}m';
      } else if (diff.inMinutes >= 1) {
        durationStr = '${diff.inMinutes}m';
      } else {
        durationStr = '${diff.inSeconds}s';
      }
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Top Recap Card
              Card(
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                color: theme.colorScheme.primaryContainer,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  sheet.roomTitle,
                                  style: theme.textTheme.headlineSmall
                                      ?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: theme
                                            .colorScheme
                                            .onPrimaryContainer,
                                      ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Seller: ${sheet.sellerName}',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: theme.colorScheme.onPrimaryContainer
                                        .withValues(alpha: 0.8),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF10B981),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '₹${sheet.grandTotal.toStringAsFixed(0)} Total',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 28),
                      // Recap Metrics Grid
                      Wrap(
                        spacing: 16,
                        runSpacing: 16,
                        alignment: WrapAlignment.spaceAround,
                        children: [
                          _statTile(
                            'Items Sold',
                            '${sheet.totalItemsSold} of ${sheet.totalItems}',
                            isDark: isDark,
                          ),
                          _statTile(
                            'Total Revenue',
                            '₹${sheet.grandTotal.toStringAsFixed(0)}',
                            color: const Color(0xFF10B981),
                            isDark: isDark,
                          ),
                          _statTile(
                            'Paid vs Unpaid',
                            '₹${totalPaid.toStringAsFixed(0)} / ₹${totalUnpaid.toStringAsFixed(0)}',
                            color: totalUnpaid > 0
                                ? unpaidStatColor
                                : paidStatColor,
                            isDark: isDark,
                          ),
                          _statTile(
                            'Sale Duration',
                            durationStr,
                            color: isDark
                                ? const Color(0xFF818CF8)
                                : const Color(0xFF4F46E5),
                            isDark: isDark,
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      // Export Action Buttons: WhatsApp & CSV
                      Wrap(
                        spacing: 12,
                        runSpacing: 8,
                        alignment: WrapAlignment.center,
                        children: [
                          ElevatedButton.icon(
                            icon: const Icon(Icons.share, size: 18),
                            label: const Text('Copy WhatsApp Summary'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF25D366),
                              foregroundColor: Colors.white,
                              minimumSize: const Size(0, 44),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 18,
                                vertical: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: () => _copyToClipboard(
                              _generateWhatsAppSummary(sheet),
                            ),
                          ),
                          ElevatedButton.icon(
                            icon: const Icon(
                              Icons.table_chart_outlined,
                              size: 18,
                            ),
                            label: const Text('Copy as CSV'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0284C7),
                              foregroundColor: Colors.white,
                              minimumSize: const Size(0, 44),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 18,
                                vertical: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: _copyCsv,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Buyers & Claimed Items',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Tap PAID/UNPAID badge to toggle',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              if (sheet.buyers.isEmpty)
                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(
                      child: Text(
                        'No confirmed sales yet in this room.\nWhen buyers confirm their claims, orders will show up here.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  ),
                )
              else
                ...sheet.buyers.map((buyer) => _buildBuyerCard(buyer, theme)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statTile(
    String label,
    String value, {
    Color? color,
    required bool isDark,
  }) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color ?? (isDark ? Colors.white : Colors.black87),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
          ),
        ),
      ],
    );
  }

  Widget _buildBuyerCard(BuyerOrderSummary buyer, ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: theme.colorScheme.primary.withValues(
                          alpha: 0.15,
                        ),
                        child: Text(
                          buyer.buyerName.isNotEmpty
                              ? buyer.buyerName[0].toUpperCase()
                              : '?',
                          style: TextStyle(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              buyer.buyerName,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: isDark
                                    ? Colors.white
                                    : const Color(0xFF111827),
                              ),
                            ),
                            if (buyer.buyerContact != null &&
                                buyer.buyerContact!.isNotEmpty)
                              Text(
                                buyer.buyerContact!,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: isDark
                                      ? Colors.grey.shade300
                                      : const Color(0xFF4B5563),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '₹${buyer.totalAmount.toStringAsFixed(0)}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 17,
                    color: isDark
                        ? const Color(0xFF34D399)
                        : const Color(0xFF059669),
                  ),
                ),
              ],
            ),
            const Divider(height: 20),
            ...buyer.items.map(
              (item) {
                final isPaid = item.paid;
                // High contrast badge colors for both dark room (dark mode) and bright room (light mode)
                final badgeBg = isPaid
                    ? (isDark
                          ? const Color(0xFF064E3B)
                          : const Color(0xFFD1FAE5))
                    : (isDark
                          ? const Color(0xFF451A03)
                          : const Color(0xFFFEF3C7));
                final badgeBorder = isPaid
                    ? (isDark
                          ? const Color(0xFF10B981)
                          : const Color(0xFF059669))
                    : (isDark
                          ? const Color(0xFFF59E0B)
                          : const Color(0xFFD97706));
                final badgeContent = isPaid
                    ? (isDark
                          ? const Color(0xFF6EE7B7)
                          : const Color(0xFF065F46))
                    : (isDark
                          ? const Color(0xFFFCD34D)
                          : const Color(0xFF92400E));

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          '• ${item.name}${item.quantity > 1 ? "  (x${item.quantity})" : ""}',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? Colors.white
                                : const Color(0xFF1F2937),
                          ),
                        ),
                      ),
                      Text(
                        '₹${(item.price * item.quantity).toStringAsFixed(0)}',
                        style: TextStyle(
                          color: isDark
                              ? Colors.grey.shade100
                              : const Color(0xFF111827),
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Clickable Paid/Unpaid badge (Green check vs Amber hourglass)
                      InkWell(
                        onTap: () => _togglePaid(item),
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: badgeBg,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: badgeBorder,
                              width: 1.5,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                isPaid
                                    ? Icons.check_circle_rounded
                                    : Icons.hourglass_top_rounded,
                                size: 15,
                                color: badgeContent,
                              ),
                              const SizedBox(width: 5),
                              Text(
                                isPaid ? 'PAID' : 'UNPAID',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.8,
                                  color: badgeContent,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
