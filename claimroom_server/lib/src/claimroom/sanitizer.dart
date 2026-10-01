import '../generated/protocol.dart';

/// Sanitizes an [Item] so that private buyer data (such as contact information
/// and session tokens) is never exposed over public streams or to other buyers.
Item sanitizeItem(Item item) {
  return item.copyWith(
    heldByContact: null,
    soldToContact: null,
    heldByToken: null,
    soldToToken: null,
  );
}
