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
import 'package:claimroom_server/src/generated/future_calls.dart' as _ibfxidep;
import 'package:serverpod/serverpod.dart' as _is;
import 'package:serverpod_auth_core_server/serverpod_auth_core_server.dart'
    as _iacs;
import 'package:serverpod_auth_idp_server/serverpod_auth_idp_server.dart'
    as _iais;
import '../claimroom/room_endpoint.dart' as _iwlj7kd2;
export 'future_calls.dart' show ServerpodFutureCallsGetter;

class Endpoints extends _is.EndpointDispatch {
  @override
  void initializeEndpoints(_is.Server server) {
    var endpoints = <String, _is.Endpoint>{
      'room': _iwlj7kd2.RoomEndpoint()
        ..initialize(
          server,
          'room',
          null,
        ),
    };
    connectors['room'] = _is.EndpointConnector(
      name: 'room',
      endpoint: endpoints['room']!,
      methodConnectors: {
        'createRoom': _is.MethodConnector(
          name: 'createRoom',
          params: {
            'title': _is.ParameterDescription(
              name: 'title',
              type: _is.getType<String>(),
              nullable: false,
            ),
            'sellerName': _is.ParameterDescription(
              name: 'sellerName',
              type: _is.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['room'] as _iwlj7kd2.RoomEndpoint).createRoom(
                    session,
                    params['title'],
                    params['sellerName'],
                  ),
        ),
        'getRoomByCode': _is.MethodConnector(
          name: 'getRoomByCode',
          params: {
            'code': _is.ParameterDescription(
              name: 'code',
              type: _is.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['room'] as _iwlj7kd2.RoomEndpoint).getRoomByCode(
                    session,
                    params['code'],
                  ),
        ),
        'verifySellerKey': _is.MethodConnector(
          name: 'verifySellerKey',
          params: {
            'code': _is.ParameterDescription(
              name: 'code',
              type: _is.getType<String>(),
              nullable: false,
            ),
            'sellerKey': _is.ParameterDescription(
              name: 'sellerKey',
              type: _is.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['room'] as _iwlj7kd2.RoomEndpoint).verifySellerKey(
                    session,
                    params['code'],
                    params['sellerKey'],
                  ),
        ),
        'getRoom': _is.MethodConnector(
          name: 'getRoom',
          params: {
            'roomId': _is.ParameterDescription(
              name: 'roomId',
              type: _is.getType<int>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['room'] as _iwlj7kd2.RoomEndpoint).getRoom(
                session,
                params['roomId'],
              ),
        ),
        'toggleRoomStatus': _is.MethodConnector(
          name: 'toggleRoomStatus',
          params: {
            'roomId': _is.ParameterDescription(
              name: 'roomId',
              type: _is.getType<int>(),
              nullable: false,
            ),
            'sellerKey': _is.ParameterDescription(
              name: 'sellerKey',
              type: _is.getType<String>(),
              nullable: false,
            ),
            'isOpen': _is.ParameterDescription(
              name: 'isOpen',
              type: _is.getType<bool>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['room'] as _iwlj7kd2.RoomEndpoint)
                  .toggleRoomStatus(
                    session,
                    params['roomId'],
                    params['sellerKey'],
                    params['isOpen'],
                  ),
        ),
        'addItem': _is.MethodConnector(
          name: 'addItem',
          params: {
            'roomId': _is.ParameterDescription(
              name: 'roomId',
              type: _is.getType<int>(),
              nullable: false,
            ),
            'sellerKey': _is.ParameterDescription(
              name: 'sellerKey',
              type: _is.getType<String>(),
              nullable: false,
            ),
            'name': _is.ParameterDescription(
              name: 'name',
              type: _is.getType<String>(),
              nullable: false,
            ),
            'price': _is.ParameterDescription(
              name: 'price',
              type: _is.getType<double>(),
              nullable: false,
            ),
            'quantity': _is.ParameterDescription(
              name: 'quantity',
              type: _is.getType<int>(),
              nullable: false,
            ),
            'imageUrl': _is.ParameterDescription(
              name: 'imageUrl',
              type: _is.getType<String?>(),
              nullable: true,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['room'] as _iwlj7kd2.RoomEndpoint).addItem(
                session,
                params['roomId'],
                params['sellerKey'],
                params['name'],
                params['price'],
                params['quantity'],
                imageUrl: params['imageUrl'],
              ),
        ),
        'deleteItem': _is.MethodConnector(
          name: 'deleteItem',
          params: {
            'itemId': _is.ParameterDescription(
              name: 'itemId',
              type: _is.getType<int>(),
              nullable: false,
            ),
            'sellerKey': _is.ParameterDescription(
              name: 'sellerKey',
              type: _is.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['room'] as _iwlj7kd2.RoomEndpoint).deleteItem(
                    session,
                    params['itemId'],
                    params['sellerKey'],
                  ),
        ),
        'markPaid': _is.MethodConnector(
          name: 'markPaid',
          params: {
            'itemId': _is.ParameterDescription(
              name: 'itemId',
              type: _is.getType<int>(),
              nullable: false,
            ),
            'sellerKey': _is.ParameterDescription(
              name: 'sellerKey',
              type: _is.getType<String>(),
              nullable: false,
            ),
            'paid': _is.ParameterDescription(
              name: 'paid',
              type: _is.getType<bool>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['room'] as _iwlj7kd2.RoomEndpoint).markPaid(
                session,
                params['itemId'],
                params['sellerKey'],
                params['paid'],
              ),
        ),
        'endSale': _is.MethodConnector(
          name: 'endSale',
          params: {
            'roomId': _is.ParameterDescription(
              name: 'roomId',
              type: _is.getType<int>(),
              nullable: false,
            ),
            'sellerKey': _is.ParameterDescription(
              name: 'sellerKey',
              type: _is.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['room'] as _iwlj7kd2.RoomEndpoint).endSale(
                session,
                params['roomId'],
                params['sellerKey'],
              ),
        ),
        'listItems': _is.MethodConnector(
          name: 'listItems',
          params: {
            'roomId': _is.ParameterDescription(
              name: 'roomId',
              type: _is.getType<int>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['room'] as _iwlj7kd2.RoomEndpoint).listItems(
                    session,
                    params['roomId'],
                  ),
        ),
        'claimItem': _is.MethodConnector(
          name: 'claimItem',
          params: {
            'itemId': _is.ParameterDescription(
              name: 'itemId',
              type: _is.getType<int>(),
              nullable: false,
            ),
            'buyerName': _is.ParameterDescription(
              name: 'buyerName',
              type: _is.getType<String>(),
              nullable: false,
            ),
            'buyerContact': _is.ParameterDescription(
              name: 'buyerContact',
              type: _is.getType<String?>(),
              nullable: true,
            ),
            'buyerToken': _is.ParameterDescription(
              name: 'buyerToken',
              type: _is.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['room'] as _iwlj7kd2.RoomEndpoint).claimItem(
                    session,
                    params['itemId'],
                    params['buyerName'],
                    params['buyerContact'],
                    params['buyerToken'],
                  ),
        ),
        'confirmClaim': _is.MethodConnector(
          name: 'confirmClaim',
          params: {
            'itemId': _is.ParameterDescription(
              name: 'itemId',
              type: _is.getType<int>(),
              nullable: false,
            ),
            'buyerToken': _is.ParameterDescription(
              name: 'buyerToken',
              type: _is.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['room'] as _iwlj7kd2.RoomEndpoint).confirmClaim(
                    session,
                    params['itemId'],
                    params['buyerToken'],
                  ),
        ),
        'releaseClaim': _is.MethodConnector(
          name: 'releaseClaim',
          params: {
            'itemId': _is.ParameterDescription(
              name: 'itemId',
              type: _is.getType<int>(),
              nullable: false,
            ),
            'buyerToken': _is.ParameterDescription(
              name: 'buyerToken',
              type: _is.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['room'] as _iwlj7kd2.RoomEndpoint).releaseClaim(
                    session,
                    params['itemId'],
                    params['buyerToken'],
                  ),
        ),
        'releaseHoldAsSeller': _is.MethodConnector(
          name: 'releaseHoldAsSeller',
          params: {
            'itemId': _is.ParameterDescription(
              name: 'itemId',
              type: _is.getType<int>(),
              nullable: false,
            ),
            'sellerKey': _is.ParameterDescription(
              name: 'sellerKey',
              type: _is.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['room'] as _iwlj7kd2.RoomEndpoint)
                  .releaseHoldAsSeller(
                    session,
                    params['itemId'],
                    params['sellerKey'],
                  ),
        ),
        'getOrderSheet': _is.MethodConnector(
          name: 'getOrderSheet',
          params: {
            'roomId': _is.ParameterDescription(
              name: 'roomId',
              type: _is.getType<int>(),
              nullable: false,
            ),
            'sellerKey': _is.ParameterDescription(
              name: 'sellerKey',
              type: _is.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['room'] as _iwlj7kd2.RoomEndpoint).getOrderSheet(
                    session,
                    params['roomId'],
                    params['sellerKey'],
                  ),
        ),
        'reportRoom': _is.MethodConnector(
          name: 'reportRoom',
          params: {
            'roomCode': _is.ParameterDescription(
              name: 'roomCode',
              type: _is.getType<String>(),
              nullable: false,
            ),
            'reason': _is.ParameterDescription(
              name: 'reason',
              type: _is.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['room'] as _iwlj7kd2.RoomEndpoint).reportRoom(
                    session,
                    params['roomCode'],
                    params['reason'],
                  ),
        ),
        'streamRoom': _is.MethodStreamConnector(
          name: 'streamRoom',
          params: {
            'roomId': _is.ParameterDescription(
              name: 'roomId',
              type: _is.getType<int>(),
              nullable: false,
            ),
          },
          streamParams: {},
          returnType: _is.MethodStreamReturnType.streamType,
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
                Map<String, Stream> streamParams,
              ) => (endpoints['room'] as _iwlj7kd2.RoomEndpoint).streamRoom(
                session,
                params['roomId'],
              ),
        ),
      },
    );
    modules['serverpod_auth_idp'] = _iais.Endpoints()
      ..initializeEndpoints(server);
    modules['serverpod_auth_core'] = _iacs.Endpoints()
      ..initializeEndpoints(server);
  }

  @override
  _is.FutureCallDispatch? get futureCalls {
    return _ibfxidep.FutureCalls();
  }
}
