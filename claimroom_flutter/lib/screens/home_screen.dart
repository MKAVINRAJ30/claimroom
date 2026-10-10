import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../client.dart';
import '../theme/app_theme.dart';
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
    _tabController.addListener(() {
      if (mounted) setState(() {});
    });

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
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 540),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Gradient Hero Header (Indigo to Violet)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 28,
                    ),
                    decoration: BoxDecoration(
                      gradient: AppColors.heroGradient,
                      borderRadius: BorderRadius.circular(AppRadius.xxl),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primaryDark.withValues(alpha: 0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.18),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.35),
                              width: 1.5,
                            ),
                          ),
                          child: const Icon(
                            Icons.bolt,
                            size: 40,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 14),
                        const Text(
                          'ClaimRoom',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 30,
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          "Stop losing sales to 'mine!' comments.",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontSize: 15,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        const SizedBox(height: 22),
                        // Two Clear Primary Buttons
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                icon: const Icon(Icons.storefront, size: 18),
                                label: const Text("I'm a Seller"),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _tabController.index == 0
                                      ? Colors.white
                                      : Colors.white.withValues(alpha: 0.18),
                                  foregroundColor: _tabController.index == 0
                                      ? AppColors.primaryDark
                                      : Colors.white,
                                  minimumSize: const Size(
                                    0,
                                    AppSpacing.ctaButtonHeight,
                                  ),
                                  elevation: _tabController.index == 0 ? 3 : 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(
                                      AppRadius.md,
                                    ),
                                  ),
                                ),
                                onPressed: () {
                                  setState(() => _tabController.index = 0);
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton.icon(
                                icon: const Icon(
                                  Icons.shopping_bag_outlined,
                                  size: 18,
                                ),
                                label: const Text("Join a Sale"),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _tabController.index == 1
                                      ? Colors.white
                                      : Colors.white.withValues(alpha: 0.18),
                                  foregroundColor: _tabController.index == 1
                                      ? AppColors.primaryDark
                                      : Colors.white,
                                  minimumSize: const Size(
                                    0,
                                    AppSpacing.ctaButtonHeight,
                                  ),
                                  elevation: _tabController.index == 1 ? 3 : 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(
                                      AppRadius.md,
                                    ),
                                  ),
                                ),
                                onPressed: () {
                                  setState(() => _tabController.index = 1);
                                },
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Rounded Form Card
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.xl),
                      side: BorderSide(
                        color: theme.colorScheme.outlineVariant.withValues(
                          alpha: 0.4,
                        ),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 250),
                        switchInCurve: Curves.easeInOut,
                        switchOutCurve: Curves.easeInOut,
                        child: KeyedSubtree(
                          key: ValueKey<int>(_tabController.index),
                          child: _tabController.index == 0
                              ? _buildSellerTab(theme)
                              : _buildBuyerTab(theme),
                        ),
                      ),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _titleCtrl,
          decoration: InputDecoration(
            labelText: 'Live Sale Title',
            hintText: 'e.g. Friday Thrift Drop',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            prefixIcon: const Icon(Icons.title),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        TextField(
          controller: _sellerNameCtrl,
          decoration: InputDecoration(
            labelText: 'Seller / Brand Name',
            hintText: 'e.g. Vintage Club',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            prefixIcon: const Icon(Icons.badge_outlined),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
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
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            minimumSize: const Size(0, AppSpacing.ctaButtonHeight),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
          ),
          onPressed: _isCreatingRoom ? null : _createRoom,
        ),
        const SizedBox(height: AppSpacing.lg),
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
              const SizedBox(height: 6),
              TextField(
                controller: _existingCodeCtrl,
                textCapitalization: TextCapitalization.characters,
                maxLength: 5,
                decoration: InputDecoration(
                  labelText: 'Room Code',
                  hintText: 'e.g. K9X2P',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  counterText: '',
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _existingSellerKeyCtrl,
                decoration: InputDecoration(
                  labelText: '16-Character Seller Key',
                  hintText: 'e.g. aB3xK9...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                icon: _isRejoiningAsSeller
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.login, size: 16),
                label: const Text('Access My Seller Dashboard'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(0, AppSpacing.minTouchTarget),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                ),
                onPressed: _isRejoiningAsSeller ? null : _rejoinAsSeller,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBuyerTab(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _codeCtrl,
          textCapitalization: TextCapitalization.characters,
          maxLength: 5,
          decoration: InputDecoration(
            labelText: '5-Character Room Code',
            hintText: 'e.g. K9X2P',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            prefixIcon: const Icon(Icons.vpn_key_outlined),
            counterText: '',
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        TextField(
          controller: _buyerNameCtrl,
          decoration: InputDecoration(
            labelText: 'Your Name',
            hintText: 'Enter your name',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            prefixIcon: const Icon(Icons.person_outline),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        // Trust & Safety Notice
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: Colors.amber.shade50,
            borderRadius: BorderRadius.circular(AppRadius.md),
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
              const SizedBox(width: AppSpacing.sm),
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
        const SizedBox(height: AppSpacing.lg),
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
          label: Text(
            _isJoiningRoom ? 'Joining...' : 'Join Sale Room',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.available,
            foregroundColor: Colors.white,
            minimumSize: const Size(0, AppSpacing.ctaButtonHeight),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
          ),
          onPressed: _isJoiningRoom ? null : _joinRoom,
        ),
      ],
    );
  }
}
