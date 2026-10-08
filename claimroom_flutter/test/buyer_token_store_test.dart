import 'package:flutter_test/flutter_test.dart';
import 'package:claimroom_flutter/utils/buyer_token_store.dart';
import 'package:claimroom_flutter/utils/storage_helper.dart';

void main() {
  setUp(() {
    clearStorage();
  });

  test(
    'BuyerTokenStore: two names in the same room get two different tokens',
    () {
      const roomCode = 'DEMO1';

      final akashToken = BuyerTokenStore.getOrCreateToken(roomCode, 'Akash');
      final sanjayToken = BuyerTokenStore.getOrCreateToken(roomCode, 'Sanjay');

      expect(akashToken, isNotEmpty);
      expect(sanjayToken, isNotEmpty);
      expect(akashToken.length, equals(24));
      expect(sanjayToken.length, equals(24));
      expect(akashToken, isNot(equals(sanjayToken)));
    },
  );

  test(
    'BuyerTokenStore: the same name gets the same token again across calls and reloads',
    () {
      const roomCode = 'DEMO1';

      final token1 = BuyerTokenStore.getOrCreateToken(roomCode, 'Akash');
      // Calling again with exact name
      final token2 = BuyerTokenStore.getOrCreateToken(roomCode, 'Akash');
      expect(token2, equals(token1));

      // Calling with different casing and whitespace
      final token3 = BuyerTokenStore.getOrCreateToken(roomCode, '  akash  ');
      expect(token3, equals(token1));
    },
  );

  test(
    'BuyerTokenStore: same name in different rooms gets different tokens',
    () {
      final tokenRoom1 = BuyerTokenStore.getOrCreateToken('ROOM1', 'Akash');
      final tokenRoom2 = BuyerTokenStore.getOrCreateToken('ROOM2', 'Akash');

      expect(tokenRoom1, isNot(equals(tokenRoom2)));
    },
  );

  test(
    'BuyerTokenStore: empty name returns empty token',
    () {
      final emptyToken = BuyerTokenStore.getOrCreateToken('ROOM1', '   ');
      expect(emptyToken, isEmpty);
    },
  );
}
