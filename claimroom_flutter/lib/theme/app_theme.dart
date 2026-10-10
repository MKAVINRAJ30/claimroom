import 'package:flutter/material.dart';

/// Central design system for ClaimRoom: consistent colours, spacing scale,
/// typography, and reusable item card visual components.
class AppColors {
  // Brand Gradients & Primary
  static const Color primary = Color(0xFF6366F1); // Indigo
  static const Color primaryDark = Color(0xFF4F46E5);
  static const Color violet = Color(0xFF7C3AED);
  static const Color purple = Color(0xFF8B5CF6);

  static const LinearGradient heroGradient = LinearGradient(
    colors: [primaryDark, violet],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Status Colours
  static const Color available = Color(0xFF10B981); // Emerald Green
  static const Color availableLight = Color(0xFFD1FAE5);
  static const Color availableText = Color(0xFF065F46);

  static const Color held = Color(0xFFF59E0B); // Amber
  static const Color heldDark = Color(0xFFD97706);
  static const Color heldLight = Color(0xFFFEF3C7);
  static const Color heldText = Color(0xFF78350F);

  static const Color sold = Color(0xFF6B7280); // Cool Grey
  static const Color soldLight = Color(0xFFF3F4F6);
  static const Color soldText = Color(0xFF374151);

  static const Color urgentRed = Color(0xFFDC2626);
  static const Color urgentRedLight = Color(0xFFFEE2E2);

  // Social & Actions
  static const Color whatsApp = Color(0xFF25D366);
}

class AppSpacing {
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 24.0;
  static const double xxl = 32.0;

  // Accessibility & touch target rules
  static const double minTouchTarget = 44.0;
  static const double ctaButtonHeight = 48.0;
}

class AppRadius {
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 20.0;
  static const double xxl = 24.0;
  static const double full = 999.0;
}

/// A tinted placeholder tile with a shopping-bag icon used whenever
/// an item has no image URL or fails to load.
class ItemImagePlaceholder extends StatelessWidget {
  final double size;

  const ItemImagePlaceholder({super.key, this.size = 64.0});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: const Color(0xFFEEF2FF),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: const Color(0xFFC7D2FE)),
      ),
      child: Icon(
        Icons.shopping_bag_outlined,
        size: size * 0.45,
        color: AppColors.primaryDark,
      ),
    );
  }
}

/// Reusable item image that renders network images with a rounded border,
/// gracefully falling back to [ItemImagePlaceholder].
class ItemImageTile extends StatelessWidget {
  final String? imageUrl;
  final double size;

  const ItemImageTile({super.key, this.imageUrl, this.size = 64.0});

  @override
  Widget build(BuildContext context) {
    if (imageUrl == null || imageUrl!.trim().isEmpty) {
      return ItemImagePlaceholder(size: size);
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Image.network(
        imageUrl!.trim(),
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder:
            (context, error, stackTrace) =>
                ItemImagePlaceholder(size: size),
      ),
    );
  }
}

/// A colour-coded status chip indicating Available (green), Held (amber), or Sold (grey).
class ItemStatusChip extends StatelessWidget {
  final String status;

  const ItemStatusChip({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    Color border;
    IconData icon;
    String label;

    switch (status.toLowerCase()) {
      case 'available':
        bg = AppColors.availableLight;
        fg = AppColors.availableText;
        border = AppColors.available;
        icon = Icons.check_circle_outline;
        label = 'Available';
        break;
      case 'held':
        bg = AppColors.heldLight;
        fg = AppColors.heldText;
        border = AppColors.held;
        icon = Icons.timer_outlined;
        label = 'Held';
        break;
      case 'sold':
      default:
        bg = AppColors.soldLight;
        fg = AppColors.soldText;
        border = AppColors.sold;
        icon = Icons.lock_outline;
        label = 'Sold';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadius.full),
        border: Border.all(color: border.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: fg),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }
}

/// A pill chip displaying item quantity (e.g., "Qty: 2").
class ItemQuantityChip extends StatelessWidget {
  final int quantity;

  const ItemQuantityChip({super.key, required this.quantity});

  @override
  Widget build(BuildContext context) {
    if (quantity <= 1) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(AppRadius.full),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Text(
        'Qty: $quantity',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: Colors.grey.shade800,
        ),
      ),
    );
  }
}
