import 'package:web/web.dart' as web;

void openExternalUrl(String url) {
  try {
    web.window.open(url, '_blank');
  } catch (_) {}
}
