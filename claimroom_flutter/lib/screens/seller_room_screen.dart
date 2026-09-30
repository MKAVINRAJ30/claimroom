import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:claimroom_client/claimroom_client.dart';
import '../client.dart';
import '../widgets/countdown_timer_widget.dart';
import 'order_sheet_screen.dart';

class SellerRoomScreen extends StatefulWidget {
  final Room room;

  const SellerRoomScreen({
    super.key,
    required this.room,
  });

  @override
  State<SellerRoomScreen> createState() => _SellerRoomScreenState();
}

class _SellerRoomScreenState extends State<SellerRoomScreen> {
  late Room _room;
  List<Item> _items = [];
  bool _isLoading = true;
  StreamSubscription<RoomEvent>? _streamSub;

  @override
  void initState() {
    super.initState();
    _room = widget.room;
    _loadItems();
    _subscribeToRoom();
  }

  @override
  void dispose() {
    _streamSub?.cancel();
    super.dispose();
  }

  Future<void> _loadItems() async {
    try {
      final items = await client.room.listItems(_room.id!);
      if (mounted) {
        setState(() {
          _items = items;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading items: $e')),
        );
      }
    }
  }

  void _subscribeToRoom() {
    try {
      _streamSub = client.room
          .streamRoom(_room.id!)
          .listen(
            (event) {
              if (!mounted) return;

              if (event.type == 'item_added' && event.item != null) {
                setState(() {
                  _items.add(event.item!);
                });
              } else if (event.type == 'item_deleted' && event.item != null) {
                setState(() {
                  _items.removeWhere((i) => i.id == event.item!.id);
                });
              } else if ((event.type == 'item_claimed' ||
                      event.type == 'item_confirmed' ||
                      event.type == 'item_released') &&
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
              } else if (event.type == 'room_status_changed') {
                _refreshRoomDetails();
              }
            },
            onError: (err) {
              // Stream error, fallback to periodic refresh if disconnected
            },
          );
    } catch (_) {}
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
        !_room.isOpen,
      );
      if (mounted) {
        setState(() => _room = updated);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update room: $e')),
        );
      }
    }
  }

  Future<void> _showAddItemDialog() async {
    final nameCtrl = TextEditingController();
    final priceCtrl = TextEditingController();

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Product to Room'),
        content: Column(
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
                labelText: 'Price (₹)',
                hintText: 'e.g. 1499',
                prefixText: '₹ ',
                border: OutlineInputBorder(),
              ),
            ),
          ],
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
              if (name.isEmpty || price == null) return;

              Navigator.pop(ctx);
              try {
                await client.room.addItem(_room.id!, name, price, 1);
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
    final demoItems = [
      ('Vintage Oversized Denim Jacket', 1499.0),
      ('Handmade Ceramic Coffee Mug', 399.0),
      ('Retro Aviator Sunglasses', 799.0),
      ('Pure Mulberry Silk Scarf', 649.0),
    ];

    for (final item in demoItems) {
      await client.room.addItem(_room.id!, item.$1, item.$2, 1);
    }
    _loadItems();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Added 4 demo products for live sale!'),
          backgroundColor: Color(0xFF10B981),
        ),
      );
    }
  }

  Future<void> _deleteItem(Item item) async {
    try {
      await client.room.deleteItem(item.id!);
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final availableCount = _items.where((i) => i.status == 'available').length;
    final heldCount = _items.where((i) => i.status == 'held').length;
    final soldCount = _items.where((i) => i.status == 'sold').length;
    final totalSoldRevenue = _items
        .where((i) => i.status == 'sold')
        .fold<double>(0.0, (sum, i) => sum + i.price);

    return Scaffold(
      appBar: AppBar(
        title: Text(_room.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadItems,
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
                      // Header Card with Room Code & Status
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
                                                .withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                            border: Border.all(
                                              color: theme.colorScheme.primary
                                                  .withOpacity(0.3),
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
                                              const Icon(
                                                Icons.copy,
                                                size: 16,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  ElevatedButton.icon(
                                    icon: Icon(
                                      _room.isOpen
                                          ? Icons.pause_circle_outline
                                          : Icons.play_circle_outline,
                                      color: Colors.white,
                                    ),
                                    label: Text(
                                      _room.isOpen
                                          ? 'Sale LIVE (Pause)'
                                          : 'Sale PAUSED (Open)',
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: _room.isOpen
                                          ? const Color(0xFF10B981)
                                          : Colors.grey.shade600,
                                      foregroundColor: Colors.white,
                                    ),
                                    onPressed: _toggleRoomStatus,
                                  ),
                                ],
                              ),
                              const Divider(height: 24),
                              // Live Stats Counter
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
                                    'In-Cart / Held',
                                    '$heldCount',
                                    const Color(0xFFF59E0B),
                                  ),
                                  _statItem(
                                    'Sold',
                                    '$soldCount',
                                    theme.colorScheme.primary,
                                  ),
                                  _statItem(
                                    'Revenue',
                                    '₹${totalSoldRevenue.toStringAsFixed(0)}',
                                    const Color(0xFF8B5CF6),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Action Bar
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              icon: const Icon(Icons.add_shopping_cart),
                              label: const Text('Add Product'),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
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
                          ),
                          const SizedBox(width: 10),
                          OutlinedButton.icon(
                            icon: const Icon(
                              Icons.flash_on,
                              color: Color(0xFFF59E0B),
                            ),
                            label: const Text('Seed 4 Demo Items'),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 14,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            onPressed: _seedDemoItems,
                          ),
                          const SizedBox(width: 10),
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
                          child: Padding(
                            padding: const EdgeInsets.all(32),
                            child: Center(
                              child: Column(
                                children: [
                                  const Icon(
                                    Icons.inventory_2_outlined,
                                    size: 48,
                                    color: Colors.grey,
                                  ),
                                  const SizedBox(height: 12),
                                  const Text(
                                    'No products added yet.',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  const Text(
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
    Widget? trailingWidget;

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
      trailingWidget = const Icon(Icons.check_circle, color: Color(0xFF8B5CF6));
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: badgeColor.withOpacity(0.12),
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
                    item.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        '₹${item.price.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF10B981),
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: badgeColor.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(6),
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
