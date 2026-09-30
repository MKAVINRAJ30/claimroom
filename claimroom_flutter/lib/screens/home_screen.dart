import 'package:flutter/material.dart';
import '../client.dart';
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

  // Buyer form
  final _codeCtrl = TextEditingController();
  final _buyerNameCtrl = TextEditingController(text: 'Priya');
  bool _isJoiningRoom = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _titleCtrl.dispose();
    _sellerNameCtrl.dispose();
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
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => SellerRoomScreen(room: room),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isCreatingRoom = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to create room: $e')),
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
          SnackBar(content: Text('Error joining room: $e')),
        );
      }
    }
  }

  Future<void> _quickStartDemo() async {
    setState(() => _isCreatingRoom = true);
    try {
      final room = await client.room.createRoom(
        'Live Thrift Showcase',
        'Studio Retro',
      );
      await client.room.addItem(
        room.id!,
        '90s Vintage Leather Jacket',
        1999.0,
        1,
      );
      await client.room.addItem(
        room.id!,
        'Handmade Ceramic Matcha Bowl',
        499.0,
        1,
      );
      await client.room.addItem(
        room.id!,
        'Retro Polarized Sunglasses',
        799.0,
        1,
      );
      await client.room.addItem(room.id!, 'Boho Woven Tote Bag', 599.0, 1);

      if (mounted) {
        setState(() => _isCreatingRoom = false);
        _codeCtrl.text = room.code;

        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.bolt, color: Color(0xFFF59E0B)),
                SizedBox(width: 8),
                Text('Demo Room Ready!'),
              ],
            ),
            content: Text(
              'Created "${room.title}" with 4 products.\nRoom Code: ${room.code}\n\nChoose how you want to test:',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => BuyerRoomScreen(
                        room: room,
                        initialBuyerName: 'Priya',
                      ),
                    ),
                  );
                },
                child: const Text('Open as Buyer (Priya)'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => SellerRoomScreen(room: room),
                    ),
                  );
                },
                child: const Text('Open as Seller'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isCreatingRoom = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error creating demo room: $e')),
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
                        color: const Color(0xFF6366F1).withOpacity(0.12),
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
                    'Zero Double-Sells. Zero Lost Orders.\nReal-time claim sales for Instagram & WhatsApp sellers.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.grey.shade600,
                      height: 1.4,
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Quick Demo Button
                  OutlinedButton.icon(
                    icon: const Icon(
                      Icons.auto_awesome,
                      color: Color(0xFFF59E0B),
                    ),
                    label: const Text('⚡ Quick Start Instant Demo'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: const BorderSide(color: Color(0xFFF59E0B)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: _isCreatingRoom ? null : _quickStartDemo,
                  ),

                  const SizedBox(height: 20),

                  // Tab switcher: Seller vs Buyer
                  Container(
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceVariant.withOpacity(0.5),
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
                    height: 280,
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
    return Column(
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
        const SizedBox(height: 20),
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
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          onPressed: _isCreatingRoom ? null : _createRoom,
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
            hintText: 'e.g. Priya',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.person_outline),
          ),
        ),
        const SizedBox(height: 20),
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
    );
  }
}
