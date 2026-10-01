import 'dart:async';
import 'package:flutter/material.dart';
import 'package:claimroom_client/claimroom_client.dart';
import '../client.dart';
import '../widgets/countdown_timer_widget.dart';

class BuyerRoomScreen extends StatefulWidget {
  final Room room;
  final String? initialBuyerName;
  final String? initialBuyerContact;

  const BuyerRoomScreen({
    super.key,
    required this.room,
    this.initialBuyerName,
    this.initialBuyerContact,
  });

  @override
  State<BuyerRoomScreen> createState() => _BuyerRoomScreenState();
}

class _BuyerRoomScreenState extends State<BuyerRoomScreen> {
  late Room _room;
  List<Item> _items = [];
  bool _isLoading = true;
  bool _isReconnecting = false;
  String _buyerName = '';
  String _buyerContact = '';
  StreamSubscription<RoomEvent>? _streamSub;
  Timer? _reconnectTimer;
  Timer? _pollingTimer;

  @override
  void initState() {
    super.initState();
    _room = widget.room;
    _buyerName = widget.initialBuyerName ?? '';
    _buyerContact = widget.initialBuyerContact ?? '';

    _loadItems();
    _subscribeToRoom();

    // 10-second periodic refresh as a safety net
    _pollingTimer = Timer.periodic(
      const Duration(seconds: 10),
      (_) => _loadItems(isBackground: true),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_buyerName.isEmpty) {
        _promptBuyerIdentity();
      }
    });
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

                // If someone else claimed an item
                if (event.type == 'item_claimed' &&
                    event.item!.heldBy != _buyerName &&
                    event.message != null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('⚡ ${event.message}'),
                      duration: const Duration(seconds: 2),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              } else if (event.type == 'sale_ended') {
                setState(() {
                  _room.isOpen = false;
                });
                _loadItems(isBackground: true);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      '🔔 ${event.message ?? "The sale has ended! Thank you for participating."}',
                    ),
                    duration: const Duration(seconds: 4),
                    backgroundColor: Colors.indigo.shade800,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              } else if (event.type == 'room_status_changed') {
                _loadItems(isBackground: true);
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

  Future<void> _promptBuyerIdentity() async {
    final nameCtrl = TextEditingController(text: _buyerName);
    final contactCtrl = TextEditingController(text: _buyerContact);

    await showDialog(
      context: context,
      barrierDismissible: _buyerName.isNotEmpty,
      builder: (ctx) => AlertDialog(
        title: const Text('Enter Your Name to Claim'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Small sellers use this name to link your claims to your order.',
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: nameCtrl,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Your Name',
                hintText: 'e.g. Priya or Rahul',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: contactCtrl,
              decoration: const InputDecoration(
                labelText: 'WhatsApp / Phone (optional)',
                hintText: 'e.g. +91 98765 43210',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.phone),
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              final name = nameCtrl.text.trim();
              if (name.isNotEmpty) {
                setState(() {
                  _buyerName = name;
                  _buyerContact = contactCtrl.text.trim();
                });
                Navigator.pop(ctx);
              }
            },
            child: const Text('Save & Continue'),
          ),
        ],
      ),
    );
  }

  Future<void> _claimItem(Item item) async {
    if (_buyerName.isEmpty) {
      await _promptBuyerIdentity();
      if (_buyerName.isEmpty) return;
    }

    try {
      final result = await client.room.claimItem(
        item.id!,
        _buyerName,
        _buyerContact.isNotEmpty ? _buyerContact : null,
      );

      if (mounted) {
        if (result.success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '🎉 You claimed ${item.name}! Confirm within 60s.',
              ),
              backgroundColor: const Color(0xFF10B981),
              behavior: SnackBarBehavior.floating,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('⚠️ ${result.message}'),
              backgroundColor: Colors.red.shade700,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        _loadItems();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error claiming item: $e')),
        );
      }
    }
  }

  Future<void> _confirmClaim(Item item) async {
    try {
      final result = await client.room.confirmClaim(item.id!, _buyerName);
      if (mounted) {
        if (result.success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✅ Confirmed! ${item.name} is yours.'),
              backgroundColor: const Color(0xFF10B981),
              behavior: SnackBarBehavior.floating,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('⚠️ ${result.message}')),
          );
        }
        _loadItems();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error confirming: $e')),
        );
      }
    }
  }

  Future<void> _releaseClaim(Item item) async {
    try {
      await client.room.releaseClaim(item.id!, _buyerName);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Released item back to room.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        _loadItems();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error releasing: $e')),
        );
      }
    }
  }

  void _showMyBagSheet() {
    final myHeld = _items
        .where((i) => i.status == 'held' && i.heldBy == _buyerName)
        .toList();
    final mySold = _items
        .where((i) => i.status == 'sold' && i.soldTo == _buyerName)
        .toList();
    final total = [...myHeld, ...mySold].fold<double>(
      0.0,
      (sum, i) => sum + (i.price * i.quantity),
    );

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'My Claims & Orders',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Total: ₹${total.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Color(0xFF10B981),
                  ),
                ),
              ],
            ),
            const Divider(height: 20),
            if (myHeld.isEmpty && mySold.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: Text(
                    'You have not claimed any items yet.',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              )
            else ...[
              if (myHeld.isNotEmpty) ...[
                const Text(
                  'Pending Confirmation (Held for you):',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFD97706),
                  ),
                ),
                const SizedBox(height: 8),
                ...myHeld.map(
                  (item) => ListTile(
                    dense: true,
                    leading: const Icon(Icons.timer, color: Color(0xFFF59E0B)),
                    title: Text(
                      '${item.name}${item.quantity > 1 ? " (x${item.quantity})" : ""}',
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '₹${(item.price * item.quantity).toStringAsFixed(0)}',
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF10B981),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                          ),
                          onPressed: () {
                            Navigator.pop(ctx);
                            _confirmClaim(item);
                          },
                          child: const Text('Confirm'),
                        ),
                      ],
                    ),
                  ),
                ),
                const Divider(),
              ],
              if (mySold.isNotEmpty) ...[
                const Text(
                  'Confirmed Purchases:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF10B981),
                  ),
                ),
                const SizedBox(height: 8),
                ...mySold.map(
                  (item) => ListTile(
                    dense: true,
                    leading: const Icon(
                      Icons.check_circle,
                      color: Color(0xFF10B981),
                    ),
                    title: Text(
                      '${item.name}${item.quantity > 1 ? " (x${item.quantity})" : ""}',
                    ),
                    trailing: Text(
                      '₹${(item.price * item.quantity).toStringAsFixed(0)}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSaleEndedBanner(ThemeData theme) {
    final myPurchases = _items
        .where((i) => i.status == 'sold' && i.soldTo == _buyerName.trim())
        .toList();
    final myTotal = myPurchases.fold<double>(
      0.0,
      (sum, i) => sum + (i.price * i.quantity),
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFCA5A5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.storefront_outlined,
                color: Color(0xFFDC2626),
                size: 24,
              ),
              const SizedBox(width: 10),
              Text(
                'Sale Ended',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF991B1B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'The seller has concluded this live sale. New claims are closed.',
            style: TextStyle(color: Color(0xFF7F1D1D), fontSize: 13),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFFECACA)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Your Confirmed Purchases (${myPurchases.length})',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      'Total: ₹${myTotal.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF10B981),
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (myPurchases.isEmpty)
                  const Text(
                    'You did not purchase any items during this sale. Thank you for joining!',
                    style: TextStyle(color: Colors.grey, fontSize: 13),
                  )
                else
                  ...myPurchases.map(
                    (i) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 3),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              '• ${i.name}${i.quantity > 1 ? " (x${i.quantity})" : ""}',
                              style: const TextStyle(fontSize: 13),
                            ),
                          ),
                          Text(
                            '₹${(i.price * i.quantity).toStringAsFixed(0)}',
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ],
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final myClaimCount = _items
        .where(
          (i) =>
              (i.status == 'held' && i.heldBy == _buyerName) ||
              (i.status == 'sold' && i.soldTo == _buyerName),
        )
        .length;

    return Scaffold(
      appBar: AppBar(
        title: Text(_room.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _loadItems(),
            tooltip: 'Refresh',
          ),
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.shopping_bag_outlined),
                onPressed: _showMyBagSheet,
                tooltip: 'My Bag',
              ),
              if (myClaimCount > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Color(0xFF10B981),
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      '$myClaimCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 800),
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

                      // Feature E: Prominent Sale Ended Banner
                      if (!_room.isOpen) _buildSaleEndedBanner(theme),

                      // Buyer identity bar
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHighest
                              .withAlpha(128),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.account_circle,
                              color: Color(0xFF6366F1),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                _buyerName.isNotEmpty
                                    ? 'Claiming as: $_buyerName ${_buyerContact.isNotEmpty ? "($_buyerContact)" : ""}'
                                    : 'Set your name before claiming',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            TextButton(
                              onPressed: _promptBuyerIdentity,
                              child: Text(
                                _buyerName.isNotEmpty ? 'Edit' : 'Set Name',
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Live Products (${_items.length})',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: _room.isOpen
                                  ? const Color(0xFF10B981).withAlpha(38)
                                  : Colors.red.withAlpha(38),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: _room.isOpen
                                        ? const Color(0xFF10B981)
                                        : Colors.red,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  _room.isOpen ? 'LIVE SALE' : 'SALE ENDED',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                    color: _room.isOpen
                                        ? const Color(0xFF10B981)
                                        : Colors.red.shade700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      if (_items.isEmpty)
                        Card(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Padding(
                            padding: EdgeInsets.all(40),
                            child: Center(
                              child: Text(
                                'The seller hasn\'t dropped any items yet.\nStay tuned, items will appear live here!',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.grey),
                              ),
                            ),
                          ),
                        )
                      else
                        ..._items.map(
                          (item) => _buildBuyerItemCard(item, theme),
                        ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildBuyerItemCard(Item item, ThemeData theme) {
    final isHeldByMe = item.status == 'held' && item.heldBy == _buyerName;
    final isSoldToMe = item.status == 'sold' && item.soldTo == _buyerName;
    final totalPrice = item.price * item.quantity;
    final qtySuffix = item.quantity > 1 ? ' (x${item.quantity})' : '';

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: isHeldByMe
            ? const BorderSide(color: Color(0xFFF59E0B), width: 2)
            : (isSoldToMe
                  ? const BorderSide(color: Color(0xFF10B981), width: 2)
                  : BorderSide.none),
      ),
      elevation: isHeldByMe ? 4 : 1,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (item.imageUrl != null && item.imageUrl!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        item.imageUrl!,
                        width: 54,
                        height: 54,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => Container(
                          width: 54,
                          height: 54,
                          color: Colors.grey.shade200,
                          child: const Icon(
                            Icons.image_not_supported,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                    ),
                  ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${item.name}$qtySuffix',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (item.quantity > 1)
                        Text(
                          '₹${item.price.toStringAsFixed(0)} each',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                    ],
                  ),
                ),
                Text(
                  '₹${totalPrice.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF10B981),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Item Status & Actions
            if (item.status == 'available')
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.flash_on),
                  label: Text(
                    _room.isOpen ? 'CLAIM NOW' : 'SALE CLOSED',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _room.isOpen
                        ? const Color(0xFF6366F1)
                        : Colors.grey,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: _room.isOpen ? () => _claimItem(item) : null,
                ),
              )
            else if (isHeldByMe)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.timer,
                          color: Color(0xFFD97706),
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'HELD FOR YOU: ',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFD97706),
                          ),
                        ),
                        CountdownTimerWidget(
                          expiresAt: item.holdExpiresAt,
                          onExpired: () => _loadItems(),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Color(0xFFD97706),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF10B981),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                vertical: 12,
                              ),
                            ),
                            onPressed: () => _confirmClaim(item),
                            child: const Text('CONFIRM CLAIM'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                            side: const BorderSide(color: Colors.red),
                            padding: const EdgeInsets.symmetric(
                              vertical: 12,
                            ),
                          ),
                          onPressed: () => _releaseClaim(item),
                          child: const Text('RELEASE'),
                        ),
                      ],
                    ),
                  ],
                ),
              )
            else if (item.status == 'held')
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.lock_clock,
                      size: 18,
                      color: Color(0xFFD97706),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Held by ${item.heldBy ?? "another buyer"} (',
                      style: const TextStyle(
                        color: Color(0xFFD97706),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    CountdownTimerWidget(
                      expiresAt: item.holdExpiresAt,
                      onExpired: () => _loadItems(),
                      style: const TextStyle(
                        color: Color(0xFFD97706),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Text(
                      ')',
                      style: TextStyle(
                        color: Color(0xFFD97706),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              )
            else if (isSoldToMe)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFD1FAE5),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.check_circle, color: Color(0xFF10B981)),
                    SizedBox(width: 8),
                    Text(
                      'YOU BOUGHT THIS ITEM! 🎉',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF065F46),
                      ),
                    ),
                  ],
                ),
              )
            else
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(
                    'SOLD to ${item.soldTo ?? "buyer"}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
