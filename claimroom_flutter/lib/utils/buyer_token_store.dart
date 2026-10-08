import 'dart:math';
import 'storage_helper.dart';

class BuyerTokenStore {
  static const _tokenChars =
      'ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz23456789';

  /// Generates a random 24-character session token.
  static String generateBuyerToken() {
    final rnd = Random.secure();
    return List.generate(
      24,
      (_) => _tokenChars[rnd.nextInt(_tokenChars.length)],
    ).join();
  }

  /// Builds the persistent storage key scoped by room code and normalized buyer name.
  /// Format: `claimroom_buyer_token_<ROOMCODE>_<name lowercased and trimmed>`
  static String storageKey(String roomCode, String buyerName) {
    final normalizedCode = roomCode.trim().toUpperCase();
    final normalizedName = buyerName.trim().toLowerCase();
    return 'claimroom_buyer_token_${normalizedCode}_$normalizedName';
  }

  /// Retrieves an existing token for this room and buyer name, or generates and stores a fresh one.
  /// If the normalized buyer name is empty, returns an empty string.
  static String getOrCreateToken(String roomCode, String buyerName) {
    final normalizedName = buyerName.trim().toLowerCase();
    if (normalizedName.isEmpty) {
      return '';
    }
    final key = storageKey(roomCode, buyerName);
    String? token;
    try {
      token = getStorageItem(key);
    } catch (_) {}

    if (token == null || token.length < 24) {
      token = generateBuyerToken();
      try {
        setStorageItem(key, token);
      } catch (_) {}
    }
    return token;
  }
}
