import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:claimroom_client/claimroom_client.dart';
import '../client.dart';
import '../widgets/countdown_timer_widget.dart';
import 'order_sheet_screen.dart';

class SellerRoomScreen extends StatefulWidget {
  final Room room;
  final String? sellerKey;

  const SellerRoomScreen({
    super.key,
    required this.room,
    this.sellerKey,
  });

  @override
  State<SellerRoomScreen> createState() => _SellerRoomScreenState();
}

class _SellerRoomScreenState extends State<SellerRoomScreen> {
  late Room _room;
  late String _sellerKey;
  List<Item> _items = [];
  bool _isLoading = true;
  bool _isReconnecting = false;
  StreamSubscription<RoomEvent>? _streamSub;
  Timer? _reconnectTimer;
  Timer? _pollingTimer;

  @override
  void initState() {
    super.initState();
    _room = widget.room;
    _sellerKey = widget.room.sellerKey ?? widget.sellerKey ?? '';
    _loadItems();
    _subscribeToRoom();

    // 10-second periodic refresh as a safety net
    _pollingTimer = Timer.periodic(
      const Duration(seconds: 10),
      (_) => _loadItems(isBackground: true),
    );
  }

  @override
  void dispose() {
    _streamSub?.cancel();
    _reconnectTimer?.cancel();
    _pollingTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadItems({bool isBackground = false}) async {
    try {
      final items = await client.room.listItems(_room.id!);
      if (mounted) {
        setState(() {
          _items = items;
          if (!isBackground) _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted && !isBackground) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading items: $e')),
        );
      }
    }
  }

  void _subscribeToRoom() {
    _streamSub?.cancel();
    try {
      _streamSub = client.room
          .streamRoom(_room.id!)
          .listen(
            (event) {
              if (!mounted) return;

              if (_isReconnecting) {
                setState(() => _isReconnecting = false);
              }

              if (event.type == 'item_added' && event.item != null) {
                setState(() {
                  // Guard against duplicate items
                  if (!_items.any((i) => i.id == event.item!.id)) {
                    _items.add(event.item!);
                  }
                });
              } else if (event.type == 'item_deleted' && event.item != null) {
                setState(() {
                  _items.removeWhere((i) => i.id == event.item!.id);
                });
              } else if ((event.type == 'item_claimed' ||
                      event.type == 'item_confirmed' ||
                      event.type == 'item_released' ||
                      event.type == 'item_paid') &&
                  event.item != null) {
                setState(() {
                  final idx = _items.indexWhere((i) => i.id == event.item!.id);
                  if (idx != -1) {
                    _items[idx] = event.item!;
                  } else {
                    _items.add(event.item!);
                  }
                });

                if (event.message != null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(event.message!),
                      duration: const Duration(seconds: 2),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              } else if (event.type == 'room_status_changed' ||
                  event.type == 'sale_ended') {
                _refreshRoomDetails();
              }
            },
            onError: (err) => _handleStreamDisconnect(),
            onDone: () => _handleStreamDisconnect(),
            cancelOnError: true,
          );

      if (mounted && _isReconnecting) {
        setState(() => _isReconnecting = false);
      }
    } catch (_) {
      _handleStreamDisconnect();
    }
  }

  void _handleStreamDisconnect() {
    if (!mounted) return;
    setState(() => _isReconnecting = true);
    _streamSub?.cancel();
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(const Duration(seconds: 2), () {
      if (mounted) {
        _subscribeToRoom();
        _loadItems(isBackground: true);
      }
    });
  }

  Future<void> _refreshRoomDetails() async {
    final updated = await client.room.getRoom(_room.id!);
    if (updated != null && mounted) {
      setState(() => _room = updated);
    }
  }

  Future<void> _toggleRoomStatus() async {
    try {
      final updated = await client.room.toggleRoomStatus(
        _room.id!,
        _sellerKey,
        !_room.isOpen,
      );
      if (mounted) {
        setState(() => _room = updated);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update room status: $e')),
        );
      }
    }
  }

  Future<void> _endSale() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('End Live Sale?'),
        content: const Text(
          'This will close the room to new claims, automatically release all unconfirmed holds back into inventory, and open your final order sheet.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('End Sale Now'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final updated = await client.room.endSale(_room.id!, _sellerKey);
      if (mounted) {
        setState(() => _room = updated);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => OrderSheetScreen(
              roomId: _room.id!,
              roomTitle: _room.title,
              sellerKey: _sellerKey,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to end sale: $e')),
        );
      }
    }
  }

  Future<void> _showAddItemDialog() async {
    final nameCtrl = TextEditingController();
    final priceCtrl = TextEditingController();
    final quantityCtrl = TextEditingController(text: '1');
    final imageUrlCtrl = TextEditingController();

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Product to Room'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'Product Name',
                  hintText: 'e.g. 90s Vintage Leather Jacket',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: priceCtrl,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Price per Unit (₹)',
                  hintText: 'e.g. 1499',
                  prefixText: '₹ ',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: quantityCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Quantity (1-99)',
                  hintText: '1',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: imageUrlCtrl,
                keyboardType: TextInputType.url,
                decoration: const InputDecoration(
                  labelText: 'Image URL (optional)',
                  hintText: 'https://images.unsplash.com/...',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final name = nameCtrl.text.trim();
              final price = double.tryParse(priceCtrl.text.trim());
              final quantity = int.tryParse(quantityCtrl.text.trim()) ?? 1;
              final imgUrl = imageUrlCtrl.text.trim();

              if (name.isEmpty ||
                  price == null ||
                  price <= 0 ||
                  quantity < 1 ||
                  quantity > 99) {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Please enter a valid name, price (>0), and quantity (1-99).',
                    ),
                  ),
                );
                return;
              }

              Navigator.pop(ctx);
              try {
                await client.room.addItem(
                  _room.id!,
                  _sellerKey,
                  name,
                  price,
                  quantity,
                  imageUrl: imgUrl.isEmpty ? null : imgUrl,
                );
                _loadItems();
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to add item: $e')),
                  );
                }
              }
            },
            child: const Text('Add Item'),
          ),
        ],
      ),
    );
  }

  Future<void> _seedDemoItems() async {
    try {
      final demoItems = [
        ('[Demo] Vintage Oversized Denim Jacket', 1499.0, 1),
        ('[Demo] Handmade Ceramic Coffee Mug', 399.0, 3),
        ('[Demo] Retro Aviator Sunglasses', 799.0, 1),
        ('[Demo] Pure Mulberry Silk Scarf', 649.0, 2),
      ];

      for (final item in demoItems) {
        await client.room.addItem(
          _room.id!,
          _sellerKey,
          item.$1,
          item.$2,
          item.$3,
        );
      }
      await _loadItems();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Added 4 demo products for live sale!'),
            backgroundColor: Color(0xFF10B981),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to seed demo items: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteItem(Item item) async {
    try {
      await client.room.deleteItem(item.id!, _sellerKey);
      _loadItems();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Cannot delete: $e')),
        );
      }
    }
  }

  void _copyRoomCode() {
    Clipboard.setData(ClipboardData(text: _room.code));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Room code "${_room.code}" copied to clipboard!'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _copyJoinLink() {
    final origin = Uri.base.origin.isNotEmpty && Uri.base.origin != 'null'
        ? Uri.base.origin
        : 'https://claimroom.app';
    final link = '$origin/?code=${_room.code}';
    Clipboard.setData(ClipboardData(text: link));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Join link copied: $link'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF10B981),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final availableCount = _items.where((i) => i.status == 'available').length;
    final heldCount = _items.where((i) => i.status == 'held').length;
    final soldCount = _items.where((i) => i.status == 'sold').length;
    final totalSoldRevenue = _items
        .where((i) => i.status == 'sold')
        .fold<double>(0.0, (sum, i) => sum + (i.price * i.quantity));

    return Scaffold(
      appBar: AppBar(
        title: Text(_room.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _loadItems(),
            tooltip: 'Refresh Items',
          ),
          IconButton(
            icon: const Icon(Icons.receipt_long),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => OrderSheetScreen(
                    roomId: _room.id!,
                    roomTitle: _room.title,
                    sellerKey: _sellerKey,
                  ),
                ),
              );
            },
            tooltip: 'View Order Sheet',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 850),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Reconnecting indicator if stream dropped
                      if (_isReconnecting)
                        Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.amber.shade100,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.amber.shade400),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.amber.shade900,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                'Reconnecting to live room stream...',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.amber.shade900,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),

                      // Seller Protection Secret Key Banner
                      if (_sellerKey.isNotEmpty)
                        Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          color: const Color(0xFFFEF3C7),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: const BorderSide(color: Color(0xFFFCD34D)),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 10,
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.vpn_key,
                                  color: Color(0xFFD97706),
                                  size: 20,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Save this Seller Key to manage your sale room:',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFF92400E),
                                        ),
                                      ),
                                      SelectableText(
                                        _sellerKey,
                                        style: const TextStyle(
                                          fontFamily: 'monospace',
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                          letterSpacing: 1.2,
                                          color: Color(0xFF78350F),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.copy,
                                    size: 18,
                                    color: Color(0xFF92400E),
                                  ),
                                  tooltip: 'Copy Seller Key',
                                  onPressed: () {
                                    Clipboard.setData(
                                      ClipboardData(text: _sellerKey),
                                    );
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Seller key copied to clipboard!',
                                        ),
                                        behavior: SnackBarBehavior.floating,
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),

                      // Header Card with Room Code, Status & Share link
                      Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Seller: ${_room.sellerName}',
                                        style: TextStyle(
                                          color: Colors.grey.shade600,
                                          fontSize: 14,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      InkWell(
                                        onTap: _copyRoomCode,
                                        borderRadius: BorderRadius.circular(8),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 6,
                                          ),
                                          decoration: BoxDecoration(
                                            color: theme.colorScheme.primary
                                                .withAlpha(25),
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                            border: Border.all(
                                              color: theme.colorScheme.primary
                                                  .withAlpha(70),
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Text(
                                                'CODE: ${_room.code}',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 18,
                                                  letterSpacing: 2,
                                                  color:
                                                      theme.colorScheme.primary,
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              const Icon(Icons.copy, size: 16),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      OutlinedButton.icon(
                                        icon: const Icon(Icons.link, size: 16),
                                        label: const Text('Copy Join Link'),
                                        style: OutlinedButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 8,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                        ),
                                        onPressed: _copyJoinLink,
                                      ),
                                      const SizedBox(height: 6),
                                      Row(
                                        children: [
                                          Container(
                                            width: 10,
                                            height: 10,
                                            decoration: BoxDecoration(
                                              color: _room.isOpen
                                                  ? const Color(0xFF10B981)
                                                  : Colors.red,
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            _room.isOpen
                                                ? 'LIVE OPEN'
                                                : 'CLOSED',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 13,
                                              color: _room.isOpen
                                                  ? const Color(0xFF10B981)
                                                  : Colors.red,
                                            ),
                                          ),
                                          Switch(
                                            value: _room.isOpen,
                                            onChanged: (_) =>
                                                _toggleRoomStatus(),
                                            activeThumbColor: const Color(
                                              0xFF10B981,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const Divider(height: 24),
                              // Live Counters
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceAround,
                                children: [
                                  _statItem(
                                    'Available',
                                    '$availableCount',
                                    const Color(0xFF10B981),
                                  ),
                                  _statItem(
                                    'Held (60s)',
                                    '$heldCount',
                                    const Color(0xFFF59E0B),
                                  ),
                                  _statItem(
                                    'Sold',
                                    '$soldCount',
                                    const Color(0xFF8B5CF6),
                                  ),
                                  _statItem(
                                    'Total Sales',
                                    '₹${totalSoldRevenue.toStringAsFixed(0)}',
                                    const Color(0xFF6366F1),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Action Toolbar: Add Product, Seed Demo, End Sale, Order Sheet
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        alignment: WrapAlignment.start,
                        children: [
                          ElevatedButton.icon(
                            icon: const Icon(Icons.add_shopping_cart, size: 18),
                            label: const Text('Add Product'),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 14,
                              ),
                              backgroundColor: theme.colorScheme.primary,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            onPressed: _showAddItemDialog,
                          ),
                          OutlinedButton.icon(
                            icon: const Icon(
                              Icons.flash_on,
                              color: Color(0xFFF59E0B),
                              size: 18,
                            ),
                            label: const Text('Seed 4 Demo Items'),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 14,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            onPressed: _seedDemoItems,
                          ),
                          ElevatedButton.icon(
                            icon: const Icon(
                              Icons.stop_circle_outlined,
                              size: 18,
                            ),
                            label: const Text('End Live Sale'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red.shade700,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 14,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            onPressed: _endSale,
                          ),
                          IconButton.filledTonal(
                            icon: const Icon(Icons.receipt_long),
                            tooltip: 'Order Sheet',
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => OrderSheetScreen(
                                    roomId: _room.id!,
                                    roomTitle: _room.title,
                                    sellerKey: _sellerKey,
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      Text(
                        'Live Sale Inventory (${_items.length} items)',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),

                      if (_items.isEmpty)
                        Card(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Padding(
                            padding: EdgeInsets.all(32),
                            child: Center(
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.inventory_2_outlined,
                                    size: 48,
                                    color: Colors.grey,
                                  ),
                                  SizedBox(height: 12),
                                  Text(
                                    'No products added yet.',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  SizedBox(height: 6),
                                  Text(
                                    'Tap "Add Product" or "Seed 4 Demo Items" to start your live sale!',
                                    style: TextStyle(color: Colors.grey),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        )
                      else
                        ..._items.map(
                          (item) => _buildSellerItemCard(item, theme),
                        ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _statItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
      ],
    );
  }

  Widget _buildSellerItemCard(Item item, ThemeData theme) {
    Color badgeColor;
    String badgeText;
    Widget trailingWidget;

    if (item.status == 'available') {
      badgeColor = const Color(0xFF10B981);
      badgeText = 'AVAILABLE';
      trailingWidget = IconButton(
        icon: const Icon(Icons.delete_outline, color: Colors.red),
        onPressed: () => _deleteItem(item),
        tooltip: 'Delete Product',
      );
    } else if (item.status == 'held') {
      badgeColor = const Color(0xFFF59E0B);
      badgeText = 'HELD BY ${item.heldBy?.toUpperCase() ?? "BUYER"}';
      trailingWidget = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.timer_outlined, size: 16, color: Color(0xFFD97706)),
          const SizedBox(width: 4),
          CountdownTimerWidget(
            expiresAt: item.holdExpiresAt,
            onExpired: () => _loadItems(),
          ),
        ],
      );
    } else {
      badgeColor = const Color(0xFF8B5CF6);
      badgeText = 'SOLD TO ${item.soldTo?.toUpperCase() ?? "BUYER"}';
      trailingWidget = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (item.paid)
            Container(
              margin: const EdgeInsets.only(right: 6),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.green.shade100,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'PAID',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Colors.green.shade800,
                ),
              ),
            ),
          const Icon(Icons.check_circle, color: Color(0xFF8B5CF6)),
        ],
      );
    }

    final totalPrice = item.price * item.quantity;
    final qtySuffix = item.quantity > 1 ? ' (x${item.quantity})' : '';

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            if (item.imageUrl != null && item.imageUrl!.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  item.imageUrl!,
                  width: 48,
                  height: 48,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: badgeColor.withAlpha(30),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.image_not_supported,
                      color: badgeColor,
                      size: 24,
                    ),
                  ),
                ),
              )
            else
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: badgeColor.withAlpha(30),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  item.status == 'sold'
                      ? Icons.shopping_bag
                      : (item.status == 'held' ? Icons.lock_clock : Icons.sell),
                  color: badgeColor,
                ),
              ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${item.name}$qtySuffix',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        '₹${totalPrice.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF10B981),
                          fontSize: 15,
                        ),
                      ),
                      if (item.quantity > 1) ...[
                        const SizedBox(width: 4),
                        Text(
                          '(₹${item.price.toStringAsFixed(0)}/ea)',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: badgeColor.withAlpha(25),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          badgeText,
                          style: TextStyle(
                            color: badgeColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            trailingWidget,
          ],
        ),
      ),
    );
  }
}
