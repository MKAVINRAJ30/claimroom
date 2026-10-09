import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../client.dart';
import '../utils/error_helper.dart';
import '../utils/storage_helper.dart';
import 'seller_room_screen.dart';
import 'buyer_room_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Seller form
  final _titleCtrl = TextEditingController(text: 'Vintage Thrift Drop #1');
  final _sellerNameCtrl = TextEditingController(text: 'Ananya Thrift');
  bool _isCreatingRoom = false;

  // Returning seller form
  final _existingCodeCtrl = TextEditingController();
  final _existingSellerKeyCtrl = TextEditingController();
  bool _isRejoiningAsSeller = false;

  // Buyer form
  final _codeCtrl = TextEditingController();
  final _buyerNameCtrl = TextEditingController();
  bool _isJoiningRoom = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    // Feature D: Support opening the Flutter web app at /?code=K9X2P to pre-fill join code
    final codeFromUrl = Uri.base.queryParameters['code'];
    if (codeFromUrl != null && codeFromUrl.isNotEmpty) {
      _codeCtrl.text = codeFromUrl.trim().toUpperCase();
      _tabController.index = 1; // Auto-switch to Buyer tab
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _titleCtrl.dispose();
    _sellerNameCtrl.dispose();
    _existingCodeCtrl.dispose();
    _existingSellerKeyCtrl.dispose();
    _codeCtrl.dispose();
    _buyerNameCtrl.dispose();
    super.dispose();
  }

  Future<void> _createRoom() async {
    final title = _titleCtrl.text.trim();
    final sellerName = _sellerNameCtrl.text.trim();
    if (title.isEmpty || sellerName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter both room title and seller name.'),
        ),
      );
      return;
    }

    setState(() => _isCreatingRoom = true);
    try {
      final room = await client.room.createRoom(title, sellerName);
      if (mounted) {
        setState(() => _isCreatingRoom = false);
        final sellerKey = room.sellerKey ?? '';
        if (sellerKey.isNotEmpty) {
          try {
            setStorageItem('seller_key_${room.id}', sellerKey);
            setStorageItem('seller_key_code_${room.code}', sellerKey);
          } catch (_) {}
        }

        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.check_circle, color: Color(0xFF10B981)),
                SizedBox(width: 8),
                Text('Room Created!'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Room "${room.title}" is ready.'),
                const SizedBox(height: 8),
                Text(
                  'Room Code: ${room.code}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  'Seller Key (Private):',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF3C7),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFFCD34D)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: SelectableText(
                          sellerKey,
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: Color(0xFF78350F),
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.copy, size: 18),
                        tooltip: 'Copy Seller Key',
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: sellerKey));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Seller key copied to clipboard!'),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.warning_amber_rounded,
                        size: 18,
                        color: Colors.red.shade800,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Save this key to manage your sale later. It cannot be recovered.',
                          style: TextStyle(
                            color: Colors.red.shade900,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              OutlinedButton.icon(
                icon: const Icon(Icons.copy, size: 16),
                label: const Text('Copy Key'),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: sellerKey));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Seller key copied to clipboard!'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => SellerRoomScreen(
                        room: room,
                        sellerKey: sellerKey,
                      ),
                    ),
                  );
                },
                child: const Text('Open Seller Dashboard'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isCreatingRoom = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(friendlyErrorMessage(e)),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    }
  }

  Future<void> _rejoinAsSeller() async {
    final code = _existingCodeCtrl.text.trim().toUpperCase();
    var sellerKey = _existingSellerKeyCtrl.text.trim();

    if (sellerKey.isEmpty && code.isNotEmpty) {
      try {
        final saved = getStorageItem('seller_key_code_$code');
        if (saved != null && saved.isNotEmpty) {
          sellerKey = saved;
          _existingSellerKeyCtrl.text = saved;
        }
      } catch (_) {}
    }

    if (code.isEmpty || sellerKey.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter both the Room Code and your Seller Key.'),
        ),
      );
      return;
    }

    setState(() => _isRejoiningAsSeller = true);
    try {
      final room = await client.room.verifySellerKey(code, sellerKey);
      if (mounted) {
        setState(() => _isRejoiningAsSeller = false);
        if (room == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Room not found.'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }

        try {
          setStorageItem('seller_key_${room.id}', sellerKey);
          setStorageItem('seller_key_code_${room.code}', sellerKey);
        } catch (_) {}

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => SellerRoomScreen(
              room: room,
              sellerKey: sellerKey,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isRejoiningAsSeller = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(friendlyErrorMessage(e)),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _joinRoom() async {
    final code = _codeCtrl.text.trim().toUpperCase();
    if (code.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a 5-letter room code.')),
      );
      return;
    }

    setState(() => _isJoiningRoom = true);
    try {
      final room = await client.room.getRoomByCode(code);
      if (mounted) {
        setState(() => _isJoiningRoom = false);
        if (room == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Room not found. Check the code and try again.'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => BuyerRoomScreen(
              room: room,
              initialBuyerName: _buyerNameCtrl.text.trim(),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isJoiningRoom = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(friendlyErrorMessage(e)),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // App Branding Header
                  Center(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF6366F1).withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.bolt,
                        size: 48,
                        color: Color(0xFF6366F1),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'ClaimRoom',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "Stop losing sales to 'mine!' comments.",
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.grey.shade600,
                      height: 1.4,
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Tab switcher: Seller vs Buyer
                  Container(
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest
                          .withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: TabBar(
                      controller: _tabController,
                      indicatorSize: TabBarIndicatorSize.tab,
                      indicator: BoxDecoration(
                        color: theme.colorScheme.primary,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      labelColor: Colors.white,
                      unselectedLabelColor: Colors.grey.shade700,
                      labelStyle: const TextStyle(fontWeight: FontWeight.bold),
                      tabs: const [
                        Tab(
                          text: "I'm a Seller",
                          icon: Icon(Icons.storefront, size: 20),
                        ),
                        Tab(
                          text: "I'm a Buyer",
                          icon: Icon(Icons.shopping_bag_outlined, size: 20),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Tab views
                  SizedBox(
                    height: 390,
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        // Seller View
                        _buildSellerTab(theme),
                        // Buyer View
                        _buildBuyerTab(theme),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSellerTab(ThemeData theme) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _titleCtrl,
            decoration: const InputDecoration(
              labelText: 'Live Sale Title',
              hintText: 'e.g. Friday Thrift Drop',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.title),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _sellerNameCtrl,
            decoration: const InputDecoration(
              labelText: 'Seller / Brand Name',
              hintText: 'e.g. Vintage Club',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.badge_outlined),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            icon: _isCreatingRoom
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.add_circle_outline),
            label: Text(
              _isCreatingRoom ? 'Creating...' : 'Create Live Sale Room',
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6366F1),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: _isCreatingRoom ? null : _createRoom,
          ),
          const SizedBox(height: 14),
          // Returning seller accordion
          Theme(
            data: theme.copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              tilePadding: EdgeInsets.zero,
              leading: const Icon(Icons.vpn_key, size: 18),
              title: const Text(
                'Rejoin with Seller Key',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
              ),
              children: [
                const SizedBox(height: 4),
                TextField(
                  controller: _existingCodeCtrl,
                  textCapitalization: TextCapitalization.characters,
                  maxLength: 5,
                  decoration: const InputDecoration(
                    labelText: 'Room Code',
                    hintText: 'e.g. K9X2P',
                    border: OutlineInputBorder(),
                    counterText: '',
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _existingSellerKeyCtrl,
                  decoration: const InputDecoration(
                    labelText: '16-Character Seller Key',
                    hintText: 'e.g. aB3xK9...',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  icon: _isRejoiningAsSeller
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.login, size: 16),
                  label: const Text('Access My Seller Dashboard'),
                  onPressed: _isRejoiningAsSeller ? null : _rejoinAsSeller,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBuyerTab(ThemeData theme) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _codeCtrl,
            textCapitalization: TextCapitalization.characters,
            maxLength: 5,
            decoration: const InputDecoration(
              labelText: '5-Character Room Code',
              hintText: 'e.g. K9X2P',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.vpn_key_outlined),
              counterText: '',
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _buyerNameCtrl,
            decoration: const InputDecoration(
              labelText: 'Your Name',
              hintText: 'Enter your name',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.person_outline),
            ),
          ),
          const SizedBox(height: 16),
          // Trust & Safety Notice
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.amber.shade50,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.amber.shade200),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.shield_outlined,
                  size: 18,
                  color: Colors.amber.shade900,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'ClaimRoom does not process payments or verify products. Pay and inspect at your own discretion.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.amber.shade900,
                      height: 1.3,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            icon: _isJoiningRoom
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.login),
            label: Text(_isJoiningRoom ? 'Joining...' : 'Join Sale Room'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: _isJoiningRoom ? null : _joinRoom,
          ),
        ],
      ),
    );
  }
}
