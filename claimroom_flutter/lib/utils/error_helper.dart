import 'package:flutter/foundation.dart';

/// Formats raw error objects into concise, human-friendly user-facing messages.
/// Technical details and stack traces are directed to debug logs only.
String friendlyErrorMessage(Object error) {
  debugPrint('ClaimRoom error: $error');
  final raw = error.toString();

  // Internal server error
  if (raw.contains('ServerpodClientInternalServerError') ||
      raw.contains('InternalServerError') ||
      raw.contains('StatusCode: 500')) {
    return 'Something went wrong, please try again.';
  }

  // Network / connection error
  if (raw.contains('SocketException') ||
      raw.contains('Connection refused') ||
      raw.contains('NetworkError') ||
      raw.contains('Failed host lookup') ||
      raw.contains('ClientException')) {
    return 'Unable to connect to server. Please check your internet connection.';
  }

  // Double claim / already held
  if (raw.contains('Already held') || raw.contains('Already sold')) {
    return 'Someone else just claimed this item.';
  }

  // Clean common Dart exception prefixes
  String cleaned = raw;
  if (cleaned.startsWith('Invalid argument(s): ')) {
    cleaned = cleaned.substring('Invalid argument(s): '.length).trim();
  } else if (cleaned.startsWith('Exception: ')) {
    cleaned = cleaned.substring('Exception: '.length).trim();
  } else if (cleaned.startsWith('Error: ')) {
    cleaned = cleaned.substring('Error: '.length).trim();
  }

  // Strip unhandled stack traces or technical dumps
  if (cleaned.contains('NoSuchMethodError') ||
      cleaned.contains('TypeError') ||
      cleaned.contains('RangeError') ||
      cleaned.length > 200) {
    return 'Something went wrong, please try again.';
  }

  return cleaned.isNotEmpty
      ? cleaned
      : 'Something went wrong, please try again.';
}
