// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:convert';

class SearchStorage {
  static const String _key = 'propzen_recent_searches';

  static List<String> loadRecentSearches() {
    try {
      final raw = html.window.localStorage[_key];
      if (raw != null && raw.isNotEmpty) {
        final decoded = jsonDecode(raw);
        if (decoded is List) {
          return decoded.map((e) => e.toString().trim()).where((e) => e.isNotEmpty).toList();
        }
      }
    } catch (_) {}
    return [];
  }

  static void saveRecentSearches(List<String> searches) {
    try {
      html.window.localStorage[_key] = jsonEncode(searches);
    } catch (_) {}
  }
}
