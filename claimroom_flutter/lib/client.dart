import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:claimroom_client/claimroom_client.dart';
import 'package:serverpod_auth_idp_flutter/serverpod_auth_idp_flutter.dart';
import 'package:serverpod_flutter/serverpod_flutter.dart';

/// Resolves the Serverpod backend URL with priority:
/// 1. Compile-time flag: `--dart-define=SERVER_URL=https://api.your-project.serverpod.cloud/`
///    (Recommended for Serverpod Cloud deployment)
/// 2. Configuration file: assets/config.json ("apiUrl" key)
/// 3. Default local development server: http://localhost:8080/
Future<String> resolveServerUrl() async {
  // Check for compile-time environment variable override
  const serverUrlFromEnv = String.fromEnvironment('SERVER_URL');
  if (serverUrlFromEnv.isNotEmpty) {
    return serverUrlFromEnv.endsWith('/')
        ? serverUrlFromEnv
        : '$serverUrlFromEnv/';
  }

  // Check assets/config.json
  try {
    final data = await rootBundle.loadString('assets/config.json');
    final config = jsonDecode(data) as Map<String, dynamic>;
    final apiUrl = config['apiUrl'] as String?;
    if (apiUrl != null && apiUrl.isNotEmpty) {
      return apiUrl.endsWith('/') ? apiUrl : '$apiUrl/';
    }
  } catch (e) {
    if (kDebugMode) {
      debugPrint(
        'Notice: assets/config.json not loaded, using local default ($e)',
      );
    }
  }

  // Default to localhost
  return 'http://localhost:8080/';
}

final serverUrl = resolveServerUrl();

late final Client client;

Future<void> initializeClient() async {
  final url = await serverUrl;
  client = Client(url)
    ..connectivityMonitor = FlutterConnectivityMonitor()
    ..authSessionManager = FlutterAuthSessionManager();
  unawaited(client.auth.initialize());
}
