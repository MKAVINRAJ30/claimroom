import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:claimroom_client/claimroom_client.dart';
import '../client.dart';

class OrderSheetScreen extends StatefulWidget {
  final int roomId;
  final String roomTitle;

  const OrderSheetScreen({
    super.key,
    required this.roomId,
    required this.roomTitle,
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
      final sheet = await client.room.getOrderSheet(widget.roomId);
      setState(() {
        _orderSheet = sheet;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
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
    buffer.writeln('-----------------------------------');

    for (final buyer in sheet.buyers) {
      buffer.writeln();
      final contact =
          buyer.buyerContact != null && buyer.buyerContact!.isNotEmpty
          ? ' (${buyer.buyerContact})'
          : '';
      buffer.writeln('👤 *${buyer.buyerName}*$contact');
      for (final item in buyer.items) {
        buffer.writeln('  • ${item.name} - ₹${item.price.toStringAsFixed(0)}');
      }
      buffer.writeln('  *Subtotal: ₹${buyer.totalAmount.toStringAsFixed(0)}*');
    }

    buffer.writeln();
    buffer.writeln('Generated via ClaimRoom ⚡');
    return buffer.toString();
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

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Summary Banner Card
              Card(
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                color: theme.colorScheme.primaryContainer,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                sheet.roomTitle,
                                style: theme.textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.onPrimaryContainer,
                                ),
                              ),
                              Text(
                                'Seller: ${sheet.sellerName}',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.onPrimaryContainer
                                      .withOpacity(0.8),
                                ),
                              ),
                            ],
                          ),
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
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _statTile('Sold Items', '${sheet.totalItemsSold}'),
                          _statTile('Buyers', '${sheet.buyers.length}'),
                          _statTile('Total Products', '${sheet.totalItems}'),
                        ],
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.share),
                        label: const Text('Copy WhatsApp Summary'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF25D366),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 14,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () =>
                            _copyToClipboard(_generateWhatsAppSummary(sheet)),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),
              Text(
                'Buyers & Claimed Items',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
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

  Widget _statTile(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
        ),
      ],
    );
  }

  Widget _buildBuyerCard(BuyerOrderSummary buyer, ThemeData theme) {
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
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: theme.colorScheme.primary.withOpacity(
                        0.15,
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
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          buyer.buyerName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        if (buyer.buyerContact != null &&
                            buyer.buyerContact!.isNotEmpty)
                          Text(
                            buyer.buyerContact!,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade600,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
                Text(
                  '₹${buyer.totalAmount.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 17,
                    color: Color(0xFF10B981),
                  ),
                ),
              ],
            ),
            const Divider(height: 20),
            ...buyer.items.map(
              (item) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '• ${item.name}',
                      style: const TextStyle(fontSize: 14),
                    ),
                    Text(
                      '₹${item.price.toStringAsFixed(0)}',
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
