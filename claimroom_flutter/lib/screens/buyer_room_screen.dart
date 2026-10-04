import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:claimroom_client/claimroom_client.dart';
import '../client.dart';
import '../utils/storage_helper.dart';
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
  late String _buyerToken;
  List<Item> _items = [];
  bool _isLoading = true;
  bool _isReconnecting = false;
  String _buyerName = '';
  String _buyerContact = '';
  Map<int, int> _myWaitlistPositions = {};
  StreamSubscription<RoomEvent>? _streamSub;
  Timer? _reconnectTimer;
  Timer? _pollingTimer;

  static const _tokenChars =
      'ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz23456789';

  String _generateBuyerToken() {
    final rnd = Random.secure();
    return List.generate(
      24,
      (_) => _tokenChars[rnd.nextInt(_tokenChars.length)],
    ).join();
  }

  void _initBuyerToken() {
    final storageKey = 'claimroom_buyer_token_${_room.id}';
    String? token;
    try {
      token = getStorageItem(storageKey);
    } catch (_) {}

    if (token == null || token.length < 24) {
      token = _generateBuyerToken();
      try {
        setStorageItem(storageKey, token);
      } catch (_) {}
    }
    _buyerToken = token;
  }

  @override
  void initState() {
    super.initState();
    _room = widget.room;
    _buyerName = widget.initialBuyerName ?? '';
    _buyerContact = widget.initialBuyerContact ?? '';
    _initBuyerToken();

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

  Future<void> _pollWaitlist() async {
    if (_room.id == null || _buyerToken.isEmpty) return;
    try {
      final positions = await client.room.getMyWaitlist(_room.id!, _buyerToken);
      if (mounted) {
        setState(() {
          _myWaitlistPositions = {
            for (final p in positions) p.itemId: p.position,
          };
        });
      }
    } catch (_) {}
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
      await _pollWaitlist();
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

                if (event.type == 'item_claimed' && event.item != null) {
                  final heldBy = event.item!.heldBy;
                  final trimmed = _buyerName.trim();
                  if (heldBy != null &&
                      trimmed.isNotEmpty &&
                      heldBy == trimmed) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          "🎉 It's your turn for ${event.item!.name}! You have 60 seconds to confirm",
                        ),
                        backgroundColor: const Color(0xFF10B981),
                        duration: const Duration(seconds: 4),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  } else if (event.message != null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('⚡ ${event.message}'),
                        duration: const Duration(seconds: 2),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                }
                _pollWaitlist();
              } else if (event.type == 'waitlist_updated') {
                if (event.waitlistItemId != null) {
                  setState(() {
                    final idx = _items.indexWhere(
                      (i) => i.id == event.waitlistItemId,
                    );
                    if (idx != -1) {
                      _items[idx] = _items[idx].copyWith(
                        waitlistCount: event.waitlistCount ?? 0,
                      );
                    }
                  });
                }
                _pollWaitlist();
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
                hintText: 'Enter your name',
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
        _buyerToken,
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
      final result = await client.room.confirmClaim(item.id!, _buyerToken);
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
      await client.room.releaseClaim(item.id!, _buyerToken);
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

  Future<void> _joinWaitlist(Item item) async {
    if (_buyerName.isEmpty) {
      await _promptBuyerIdentity();
      if (_buyerName.isEmpty) return;
    }

    try {
      final pos = await client.room.joinWaitlist(
        _room.id!,
        item.id!,
        _buyerName.trim(),
        _buyerToken,
      );
      if (mounted) {
        setState(() {
          _myWaitlistPositions[item.id!] = pos;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Joined waitlist for ${item.name}! You are #$pos in line.',
            ),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
          ),
        );
        _loadItems(isBackground: true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error joining waitlist: $e'),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _leaveWaitlist(Item item) async {
    try {
      await client.room.leaveWaitlist(_room.id!, item.id!, _buyerToken);
      if (mounted) {
        setState(() {
          _myWaitlistPositions.remove(item.id!);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Left waitlist for ${item.name}.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        _loadItems(isBackground: true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error leaving waitlist: $e'),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  String _formatDateTime(DateTime dt) {
    final local = dt.toLocal();
    final hour = local.hour.toString().padLeft(2, '0');
    final min = local.minute.toString().padLeft(2, '0');
    final day = local.day.toString().padLeft(2, '0');
    final month = local.month.toString().padLeft(2, '0');
    final year = local.year;
    return '$day/$month/$year $hour:$min';
  }

  void _showReportRoomDialog() {
    final reasonCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.flag_outlined, color: Colors.redAccent),
            SizedBox(width: 8),
            Text('Report this Room'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Report room "${_room.title}" (Code: ${_room.code}) for suspicious activity, spam, or misleading claims.',
              style: const TextStyle(fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: reasonCtrl,
              maxLines: 3,
              maxLength: 500,
              decoration: const InputDecoration(
                hintText: 'Describe the issue (max 500 chars)...',
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
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              final reason = reasonCtrl.text.trim();
              if (reason.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please enter a reason for the report.'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
                return;
              }
              Navigator.pop(ctx);
              try {
                await client.room.reportRoom(_room.code, reason);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Report submitted. Thank you for helping keep ClaimRoom safe.',
                      ),
                      backgroundColor: Color(0xFF10B981),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to submit report: $e'),
                      backgroundColor: Colors.red.shade700,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              }
            },
            child: const Text('Submit Report'),
          ),
        ],
      ),
    );
  }

  void _showMyBagSheet() {
    final trimmedName = _buyerName.trim();
    final myHeld = _items
        .where((i) => i.status == 'held' && i.heldBy == trimmedName)
        .toList();
    final mySold = _items
        .where((i) => i.status == 'sold' && i.soldTo == trimmedName)
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
          Text(
            'The seller (${_room.sellerName}) has concluded this live sale. Room created: ${_formatDateTime(_room.createdAt)}. New claims are closed.',
            style: const TextStyle(color: Color(0xFF7F1D1D), fontSize: 13),
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
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  i.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                  ),
                                ),
                                Text(
                                  'Qty: ${i.quantity} × ₹${i.price.toStringAsFixed(0)}',
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            '₹${(i.price * i.quantity).toStringAsFixed(0)}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                const Divider(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Seller: ${_room.sellerName}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    Text(
                      'Created: ${_formatDateTime(_room.createdAt)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
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
    final trimmedBuyer = _buyerName.trim();
    final myHeldItems = _items
        .where((i) => i.status == 'held' && i.heldBy == trimmedBuyer)
        .toList();
    final mySoldItems = _items
        .where((i) => i.status == 'sold' && i.soldTo == trimmedBuyer)
        .toList();
    final myClaimCount = myHeldItems.length + mySoldItems.length;
    final myRunningTotal = [...myHeldItems, ...mySoldItems].fold<double>(
      0.0,
      (sum, i) => sum + (i.price * i.quantity),
    );

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_room.title),
            Text(
              'by ${_room.sellerName} • ${_formatDateTime(_room.createdAt)}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                fontSize: 11,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.flag_outlined, size: 20),
            onPressed: _showReportRoomDialog,
            tooltip: 'Report this room',
          ),
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

                      // Room Info Card: Seller name, creation time, and Report button
                      Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHighest
                              .withValues(alpha: 0.4),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.storefront,
                              size: 20,
                              color: Color(0xFF6366F1),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Seller: ${_room.sellerName}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                  Text(
                                    'Created: ${_formatDateTime(_room.createdAt)} • Code: ${_room.code}',
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            TextButton.icon(
                              icon: const Icon(
                                Icons.flag_outlined,
                                size: 14,
                                color: Colors.redAccent,
                              ),
                              label: const Text(
                                'Report',
                                style: TextStyle(
                                  color: Colors.redAccent,
                                  fontSize: 12,
                                ),
                              ),
                              onPressed: _showReportRoomDialog,
                            ),
                          ],
                        ),
                      ),

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

                      if (_items.isNotEmpty &&
                          !_items.any((i) => i.status == 'available'))
                        Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF3E8FF),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFD8B4FE)),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.check_circle,
                                color: Color(0xFF8B5CF6),
                                size: 20,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  _items.every((i) => i.status == 'sold')
                                      ? 'All items sold! Every product in this room has been purchased.'
                                      : 'All available items are currently held or sold.',
                                  style: const TextStyle(
                                    color: Color(0xFF6B21A8),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

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
      bottomNavigationBar: (trimmedBuyer.isNotEmpty && myClaimCount > 0)
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(20),
                    blurRadius: 8,
                    offset: const Offset(0, -2),
                  ),
                ],
                border: Border(
                  top: BorderSide(color: Colors.grey.shade200),
                ),
              ),
              child: SafeArea(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'My Items: $myClaimCount (${myHeldItems.length} held, ${mySoldItems.length} confirmed)',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade700,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          'Running Total: ₹${myRunningTotal.toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF10B981),
                          ),
                        ),
                      ],
                    ),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6366F1),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: _showMyBagSheet,
                      icon: const Icon(Icons.shopping_bag_outlined, size: 18),
                      label: const Text(
                        'View My Items',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildBuyerItemCard(Item item, ThemeData theme) {
    final trimmedBuyer = _buyerName.trim();
    final isHeldByMe =
        item.status == 'held' &&
        (item.heldBy == _buyerName ||
            (trimmedBuyer.isNotEmpty && item.heldBy == trimmedBuyer));
    final isSoldToMe =
        item.status == 'sold' &&
        (item.soldTo == _buyerName ||
            (trimmedBuyer.isNotEmpty && item.soldTo == trimmedBuyer));
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
                    Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFD1FAE5),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: const Color(0xFF10B981)),
                      ),
                      child: const Text(
                        "🎉 It's your turn! You have 60 seconds to confirm",
                        style: TextStyle(
                          color: Color(0xFF065F46),
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
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
            else if (item.status == 'held') ...[
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
              ),
              const SizedBox(height: 8),
              _buildWaitlistSection(item),
            ] else if (isSoldToMe)
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
            else ...[
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
              const SizedBox(height: 8),
              _buildWaitlistSection(item),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildWaitlistSection(Item item) {
    final myPos = _myWaitlistPositions[item.id];
    final waitCount = item.waitlistCount ?? 0;

    if (myPos != null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.blue.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.blue.shade200),
        ),
        child: Row(
          children: [
            const Icon(Icons.hourglass_top, size: 16, color: Color(0xFF1D4ED8)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'You are #$myPos in line${waitCount > 0 ? " ($waitCount waiting)" : ""}',
                style: const TextStyle(
                  color: Color(0xFF1D4ED8),
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red.shade700,
                side: BorderSide(color: Colors.red.shade300),
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              onPressed: () => _leaveWaitlist(item),
              child: const Text(
                'Leave waitlist',
                style: TextStyle(fontSize: 12),
              ),
            ),
          ],
        ),
      );
    }

    return Row(
      children: [
        if (waitCount > 0) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Text(
              '$waitCount waiting',
              style: TextStyle(
                color: Colors.blue.shade800,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
        Expanded(
          child: OutlinedButton.icon(
            icon: const Icon(Icons.queue, size: 16),
            label: const Text('Join waitlist'),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF4338CA),
              side: const BorderSide(color: Color(0xFF818CF8)),
              padding: const EdgeInsets.symmetric(vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: _room.isOpen ? () => _joinWaitlist(item) : null,
          ),
        ),
      ],
    );
  }
}
