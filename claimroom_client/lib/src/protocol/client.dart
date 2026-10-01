/* AUTOMATICALLY GENERATED CODE DO NOT MODIFY */
/*   To generate run: "serverpod generate"    */

// ignore_for_file: implementation_imports
// ignore_for_file: library_private_types_in_public_api
// ignore_for_file: non_constant_identifier_names
// ignore_for_file: public_member_api_docs
// ignore_for_file: type_literal_in_constant_pattern
// ignore_for_file: use_super_parameters
// ignore_for_file: invalid_use_of_internal_member

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'dart:async' as _ida;
import 'package:claimroom_client/src/protocol/claimroom/claim_result.dart'
    as _i64ozq20;
import 'package:claimroom_client/src/protocol/claimroom/order_sheet.dart'
    as _i9f5dsxj;
import 'package:claimroom_client/src/protocol/claimroom/report.dart'
    as _i824jgjh;
import 'package:claimroom_client/src/protocol/claimroom/room_event.dart'
    as _i0ir7zxv;
import 'package:claimroom_client/src/protocol/greetings/greeting.dart'
    as _i264i9oz;
import 'package:claimroom_client/src/protocol/greetings/item.dart' as _idtbr1ys;
import 'package:claimroom_client/src/protocol/greetings/room.dart' as _ilfa8wl2;
import 'package:http/http.dart' as _i85jenna;
import 'package:serverpod_auth_core_client/serverpod_auth_core_client.dart'
    as _iacc;
import 'package:serverpod_auth_idp_client/serverpod_auth_idp_client.dart'
    as _iaic;
import 'package:serverpod_client/serverpod_client.dart' as _isc;
import 'protocol.dart' as _il2as5qe;

/// By extending [EmailIdpBaseEndpoint], the email identity provider endpoints
/// are made available on the server and enable the corresponding sign-in widget
/// on the client.
/// {@category Endpoint}
class EndpointEmailIdp extends _iaic.EndpointEmailIdpBase {
  EndpointEmailIdp(_isc.EndpointCaller caller) : super(caller);

  @override
  String get name => 'emailIdp';

  /// Logs in the user and returns a new session.
  ///
  /// Throws an [EmailAccountLoginException] in case of errors, with reason:
  /// - [EmailAccountLoginExceptionReason.invalidCredentials] if the email or
  ///   password is incorrect.
  /// - [EmailAccountLoginExceptionReason.tooManyAttempts] if there have been
  ///   too many failed login attempts.
  ///
  /// Throws an [AuthUserBlockedException] if the auth user is blocked.
  @override
  _ida.Future<_iacc.AuthSuccess> login({
    required String email,
    required String password,
  }) => caller.callServerEndpoint<_iacc.AuthSuccess>(
    'emailIdp',
    'login',
    {
      'email': email,
      'password': password,
    },
  );

  /// Starts the registration for a new user account with an email-based login
  /// associated to it.
  ///
  /// Upon successful completion of this method, an email will have been
  /// sent to [email] with a verification link, which the user must open to
  /// complete the registration.
  ///
  /// Always returns a account request ID, which can be used to complete the
  /// registration. If the email is already registered, the returned ID will not
  /// be valid.
  @override
  _ida.Future<_isc.UuidValue> startRegistration({required String email}) =>
      caller.callServerEndpoint<_isc.UuidValue>(
        'emailIdp',
        'startRegistration',
        {'email': email},
      );

  /// Verifies an account request code and returns a token
  /// that can be used to complete the account creation.
  ///
  /// Throws an [EmailAccountRequestException] in case of errors, with reason:
  /// - [EmailAccountRequestExceptionReason.expired] if the account request has
  ///   already expired.
  /// - [EmailAccountRequestExceptionReason.policyViolation] if the password
  ///   does not comply with the password policy.
  /// - [EmailAccountRequestExceptionReason.invalid] if no request exists
  ///   for the given [accountRequestId] or [verificationCode] is invalid.
  @override
  _ida.Future<String> verifyRegistrationCode({
    required _isc.UuidValue accountRequestId,
    required String verificationCode,
  }) => caller.callServerEndpoint<String>(
    'emailIdp',
    'verifyRegistrationCode',
    {
      'accountRequestId': accountRequestId,
      'verificationCode': verificationCode,
    },
  );

  /// Completes a new account registration, creating a new auth user with a
  /// profile and attaching the given email account to it.
  ///
  /// Throws an [EmailAccountRequestException] in case of errors, with reason:
  /// - [EmailAccountRequestExceptionReason.expired] if the account request has
  ///   already expired.
  /// - [EmailAccountRequestExceptionReason.policyViolation] if the password
  ///   does not comply with the password policy.
  /// - [EmailAccountRequestExceptionReason.invalid] if the [registrationToken]
  ///   is invalid.
  ///
  /// Throws an [AuthUserBlockedException] if the auth user is blocked.
  ///
  /// Returns a session for the newly created user.
  @override
  _ida.Future<_iacc.AuthSuccess> finishRegistration({
    required String registrationToken,
    required String password,
  }) => caller.callServerEndpoint<_iacc.AuthSuccess>(
    'emailIdp',
    'finishRegistration',
    {
      'registrationToken': registrationToken,
      'password': password,
    },
  );

  /// Requests a password reset for [email].
  ///
  /// If the email address is registered, an email with reset instructions will
  /// be send out. If the email is unknown, this method will have no effect.
  ///
  /// Always returns a password reset request ID, which can be used to complete
  /// the reset. If the email is not registered, the returned ID will not be
  /// valid.
  ///
  /// Throws an [EmailAccountPasswordResetException] in case of errors, with reason:
  /// - [EmailAccountPasswordResetExceptionReason.tooManyAttempts] if the user has
  ///   made too many attempts trying to request a password reset.
  ///
  @override
  _ida.Future<_isc.UuidValue> startPasswordReset({required String email}) =>
      caller.callServerEndpoint<_isc.UuidValue>(
        'emailIdp',
        'startPasswordReset',
        {'email': email},
      );

  /// Verifies a password reset code and returns a finishPasswordResetToken
  /// that can be used to finish the password reset.
  ///
  /// Throws an [EmailAccountPasswordResetException] in case of errors, with reason:
  /// - [EmailAccountPasswordResetExceptionReason.expired] if the password reset
  ///   request has already expired.
  /// - [EmailAccountPasswordResetExceptionReason.tooManyAttempts] if the user has
  ///   made too many attempts trying to verify the password reset.
  /// - [EmailAccountPasswordResetExceptionReason.invalid] if no request exists
  ///   for the given [passwordResetRequestId] or [verificationCode] is invalid.
  ///
  /// If multiple steps are required to complete the password reset, this endpoint
  /// should be overridden to return credentials for the next step instead
  /// of the credentials for setting the password.
  @override
  _ida.Future<String> verifyPasswordResetCode({
    required _isc.UuidValue passwordResetRequestId,
    required String verificationCode,
  }) => caller.callServerEndpoint<String>(
    'emailIdp',
    'verifyPasswordResetCode',
    {
      'passwordResetRequestId': passwordResetRequestId,
      'verificationCode': verificationCode,
    },
  );

  /// Completes a password reset request by setting a new password.
  ///
  /// The [verificationCode] returned from [verifyPasswordResetCode] is used to
  /// validate the password reset request.
  ///
  /// Throws an [EmailAccountPasswordResetException] in case of errors, with reason:
  /// - [EmailAccountPasswordResetExceptionReason.expired] if the password reset
  ///   request has already expired.
  /// - [EmailAccountPasswordResetExceptionReason.policyViolation] if the new
  ///   password does not comply with the password policy.
  /// - [EmailAccountPasswordResetExceptionReason.invalid] if no request exists
  ///   for the given [passwordResetRequestId] or [verificationCode] is invalid.
  ///
  /// Throws an [AuthUserBlockedException] if the auth user is blocked.
  @override
  _ida.Future<void> finishPasswordReset({
    required String finishPasswordResetToken,
    required String newPassword,
  }) => caller.callServerEndpoint<void>(
    'emailIdp',
    'finishPasswordReset',
    {
      'finishPasswordResetToken': finishPasswordResetToken,
      'newPassword': newPassword,
    },
  );

  @override
  _ida.Future<bool> hasAccount() => caller.callServerEndpoint<bool>(
    'emailIdp',
    'hasAccount',
    {},
  );
}

/// By extending [RefreshJwtTokensEndpoint], the JWT token refresh endpoint
/// is made available on the server and enables automatic token refresh on the client.
/// {@category Endpoint}
class EndpointJwtRefresh extends _iacc.EndpointRefreshJwtTokens {
  EndpointJwtRefresh(_isc.EndpointCaller caller) : super(caller);

  @override
  String get name => 'jwtRefresh';

  /// Creates a new token pair for the given [refreshToken].
  ///
  /// If [refreshToken] is omitted, cookie-mode web clients fall back to the
  /// configured HttpOnly refresh cookie. When neither source is present this
  /// throws [RefreshTokenNotFoundException], the same public "no usable refresh
  /// credential" exception used for unknown refresh tokens.
  ///
  /// Can throw the following exceptions:
  /// -[RefreshTokenMalformedException]: refresh token is malformed and could
  ///   not be parsed. Not expected to happen for tokens issued by the server.
  /// -[RefreshTokenNotFoundException]: refresh token is unknown to the server.
  ///   Either the token was deleted or generated by a different server.
  /// -[RefreshTokenExpiredException]: refresh token has expired. Will happen
  ///   only if it has not been used within configured `refreshTokenLifetime`.
  /// -[RefreshTokenInvalidSecretException]: refresh token is incorrect, meaning
  ///   it does not refer to the current secret refresh token. This indicates
  ///   either a malfunctioning client or a malicious attempt by someone who has
  ///   obtained the refresh token. In this case the underlying refresh token
  ///   will be deleted, and access to it will expire fully when the last access
  ///   token is elapsed.
  ///
  /// This endpoint is unauthenticated, meaning the client won't include any
  /// authentication information with the call.
  @override
  _ida.Future<_iacc.AuthSuccess> refreshAccessToken({String? refreshToken}) =>
      caller.callServerEndpoint<_iacc.AuthSuccess>(
        'jwtRefresh',
        'refreshAccessToken',
        {'refreshToken': refreshToken},
        authenticated: false,
      );
}

/// {@category Endpoint}
class EndpointRoom extends _isc.EndpointRef {
  EndpointRoom(_isc.EndpointCaller caller) : super(caller);

  @override
  String get name => 'room';

  /// Seller creates a room and gets back its join code and unique sellerKey.
  _ida.Future<_ilfa8wl2.Room> createRoom(
    String title,
    String sellerName,
  ) => caller.callServerEndpoint<_ilfa8wl2.Room>(
    'room',
    'createRoom',
    {
      'title': title,
      'sellerName': sellerName,
    },
  );

  /// Buyers use this to join with a code.
  /// sellerKey is stripped to ensure buyers never receive it.
  _ida.Future<_ilfa8wl2.Room?> getRoomByCode(String code) =>
      caller.callServerEndpoint<_ilfa8wl2.Room?>(
        'room',
        'getRoomByCode',
        {'code': code},
      );

  /// Returning sellers use this to verify their sellerKey and rejoin the room.
  _ida.Future<_ilfa8wl2.Room?> verifySellerKey(
    String code,
    String sellerKey,
  ) => caller.callServerEndpoint<_ilfa8wl2.Room?>(
    'room',
    'verifySellerKey',
    {
      'code': code,
      'sellerKey': sellerKey,
    },
  );

  /// Get room by its ID. sellerKey is stripped for safety.
  _ida.Future<_ilfa8wl2.Room?> getRoom(int roomId) =>
      caller.callServerEndpoint<_ilfa8wl2.Room?>(
        'room',
        'getRoom',
        {'roomId': roomId},
      );

  /// Seller can open or close claiming in the room. Requires sellerKey.
  _ida.Future<_ilfa8wl2.Room> toggleRoomStatus(
    int roomId,
    String sellerKey,
    bool isOpen,
  ) => caller.callServerEndpoint<_ilfa8wl2.Room>(
    'room',
    'toggleRoomStatus',
    {
      'roomId': roomId,
      'sellerKey': sellerKey,
      'isOpen': isOpen,
    },
  );

  /// Seller adds one product to a room. Requires sellerKey.
  _ida.Future<_idtbr1ys.Item> addItem(
    int roomId,
    String sellerKey,
    String name,
    double price,
    int quantity, {
    String? imageUrl,
  }) => caller.callServerEndpoint<_idtbr1ys.Item>(
    'room',
    'addItem',
    {
      'roomId': roomId,
      'sellerKey': sellerKey,
      'name': name,
      'price': price,
      'quantity': quantity,
      'imageUrl': imageUrl,
    },
  );

  /// Seller removes an available item. Requires sellerKey.
  /// Wrapped in a transaction with LockMode.forUpdate to prevent race conditions.
  _ida.Future<bool> deleteItem(
    int itemId,
    String sellerKey,
  ) => caller.callServerEndpoint<bool>(
    'room',
    'deleteItem',
    {
      'itemId': itemId,
      'sellerKey': sellerKey,
    },
  );

  /// Seller marks an item as paid/unpaid in the order sheet. Requires sellerKey.
  _ida.Future<_idtbr1ys.Item> markPaid(
    int itemId,
    String sellerKey,
    bool paid,
  ) => caller.callServerEndpoint<_idtbr1ys.Item>(
    'room',
    'markPaid',
    {
      'itemId': itemId,
      'sellerKey': sellerKey,
      'paid': paid,
    },
  );

  /// Seller ends the live sale: closes the room, automatically releases any
  /// unconfirmed holds, and broadcasts sale_ended. Requires sellerKey.
  /// Performed inside a single database transaction with LockMode.forUpdate on held items.
  _ida.Future<_ilfa8wl2.Room> endSale(
    int roomId,
    String sellerKey,
  ) => caller.callServerEndpoint<_ilfa8wl2.Room>(
    'room',
    'endSale',
    {
      'roomId': roomId,
      'sellerKey': sellerKey,
    },
  );

  /// Everyone in the room reads the current items.
  /// Private contact fields are sanitized.
  _ida.Future<List<_idtbr1ys.Item>> listItems(int roomId) =>
      caller.callServerEndpoint<List<_idtbr1ys.Item>>(
        'room',
        'listItems',
        {'roomId': roomId},
      );

  /// Real-time event stream for the room.
  /// Clients subscribe to this stream to receive instant updates when
  /// items are added, claimed, held, confirmed, released, or paid.
  _ida.Stream<_i0ir7zxv.RoomEvent> streamRoom(int roomId) =>
      caller.callStreamingServerEndpoint<
        _ida.Stream<_i0ir7zxv.RoomEvent>,
        _i0ir7zxv.RoomEvent
      >(
        'room',
        'streamRoom',
        {'roomId': roomId},
        {},
      );

  /// Atomic claim: Buyer taps "Claim".
  /// Uses a database transaction with LockMode.forUpdate to eliminate race conditions.
  /// If two buyers claim simultaneously, PostgreSQL row-level locks ensure only
  /// one succeeds.
  /// Expired holds are treated as available and reset automatically.
  /// Enforces a maximum of 3 simultaneously active holds per buyer token in this room.
  _ida.Future<_i64ozq20.ClaimResult> claimItem(
    int itemId,
    String buyerName,
    String? buyerContact,
    String buyerToken,
  ) => caller.callServerEndpoint<_i64ozq20.ClaimResult>(
    'room',
    'claimItem',
    {
      'itemId': itemId,
      'buyerName': buyerName,
      'buyerContact': buyerContact,
      'buyerToken': buyerToken,
    },
  );

  /// Buyer confirms their claim within the 60-second hold period.
  /// Converts hold state to permanent sold state.
  /// Enforces token match so only the buyer session that held the item can confirm it.
  _ida.Future<_i64ozq20.ClaimResult> confirmClaim(
    int itemId,
    String buyerToken,
  ) => caller.callServerEndpoint<_i64ozq20.ClaimResult>(
    'room',
    'confirmClaim',
    {
      'itemId': itemId,
      'buyerToken': buyerToken,
    },
  );

  /// Buyer cancels or releases a held item back to the room before expiry.
  /// Enforces token match so only the buyer session that held the item can release it.
  _ida.Future<_i64ozq20.ClaimResult> releaseClaim(
    int itemId,
    String buyerToken,
  ) => caller.callServerEndpoint<_i64ozq20.ClaimResult>(
    'room',
    'releaseClaim',
    {
      'itemId': itemId,
      'buyerToken': buyerToken,
    },
  );

  /// Seller forces the release of an abandoned hold back to the room before the 60s timer expires.
  /// Requires a valid sellerKey.
  /// Wrapped in a database transaction with LockMode.forUpdate to prevent race conditions.
  _ida.Future<_idtbr1ys.Item> releaseHoldAsSeller(
    int itemId,
    String sellerKey,
  ) => caller.callServerEndpoint<_idtbr1ys.Item>(
    'room',
    'releaseHoldAsSeller',
    {
      'itemId': itemId,
      'sellerKey': sellerKey,
    },
  );

  /// Generates the complete order sheet for the seller. Requires sellerKey.
  /// Aggregates all confirmed (sold) items grouped by buyer name.
  /// Quantity math: price is per unit, total = price * quantity.
  /// Computes grandTotal, totalPaid, and totalUnpaid.
  _ida.Future<_i9f5dsxj.OrderSheet> getOrderSheet(
    int roomId,
    String sellerKey,
  ) => caller.callServerEndpoint<_i9f5dsxj.OrderSheet>(
    'room',
    'getOrderSheet',
    {
      'roomId': roomId,
      'sellerKey': sellerKey,
    },
  );

  /// Buyer reports a room for suspicious activity, scams, or abuse.
  /// Requires a valid room code and non-empty reason of maximum 500 characters.
  _ida.Future<_i824jgjh.Report> reportRoom(
    String roomCode,
    String reason,
  ) => caller.callServerEndpoint<_i824jgjh.Report>(
    'room',
    'reportRoom',
    {
      'roomCode': roomCode,
      'reason': reason,
    },
  );
}

/// This is an example endpoint that returns a greeting message through
/// its [hello] method.
/// {@category Endpoint}
class EndpointGreeting extends _isc.EndpointRef {
  EndpointGreeting(_isc.EndpointCaller caller) : super(caller);

  @override
  String get name => 'greeting';

  /// Returns a personalized greeting message: "Hello {name}".
  _ida.Future<_i264i9oz.Greeting> hello(String name) =>
      caller.callServerEndpoint<_i264i9oz.Greeting>(
        'greeting',
        'hello',
        {'name': name},
      );
}

class Modules {
  Modules(Client client) {
    serverpod_auth_idp = _iaic.Caller(client);
    serverpod_auth_core = _iacc.Caller(client);
  }

  late final _iaic.Caller serverpod_auth_idp;

  late final _iacc.Caller serverpod_auth_core;
}

class Client extends _isc.ServerpodClientShared {
  Client(
    String host, {
    dynamic securityContext,
    Duration? streamingConnectionTimeout,
    Duration? connectionTimeout,
    Function(
      _isc.MethodCallContext,
      Object,
      StackTrace,
    )?
    onFailedCall,
    Function(_isc.MethodCallContext)? onSucceededCall,
    bool? disconnectStreamsOnLostInternetConnection,
    _i85jenna.Client? httpClientOverride,
  }) : super(
         host,
         _il2as5qe.Protocol(),
         securityContext: securityContext,
         streamingConnectionTimeout: streamingConnectionTimeout,
         connectionTimeout: connectionTimeout,
         onFailedCall: onFailedCall,
         onSucceededCall: onSucceededCall,
         disconnectStreamsOnLostInternetConnection:
             disconnectStreamsOnLostInternetConnection,
         httpClientOverride: httpClientOverride,
       ) {
    emailIdp = EndpointEmailIdp(this);
    jwtRefresh = EndpointJwtRefresh(this);
    room = EndpointRoom(this);
    greeting = EndpointGreeting(this);
    modules = Modules(this);
  }

  late final EndpointEmailIdp emailIdp;

  late final EndpointJwtRefresh jwtRefresh;

  late final EndpointRoom room;

  late final EndpointGreeting greeting;

  late final Modules modules;

  @override
  Map<String, _isc.EndpointRef> get endpointRefLookup => {
    'emailIdp': emailIdp,
    'jwtRefresh': jwtRefresh,
    'room': room,
    'greeting': greeting,
  };

  @override
  Map<String, _isc.ModuleEndpointCaller> get moduleLookup => {
    'serverpod_auth_idp': modules.serverpod_auth_idp,
    'serverpod_auth_core': modules.serverpod_auth_core,
  };
}
