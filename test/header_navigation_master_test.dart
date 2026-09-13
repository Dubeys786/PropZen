import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Header Navigation Master Suite (All Buttons, Dropdown & Routes)', () {
    final navItems = [
      {'name': 'PropZen Logo', 'route': '/home', 'paneId': 'view-home', 'navAttr': 'home'},
      {'name': 'Home', 'route': '/home', 'paneId': 'view-home', 'navAttr': 'home'},
      {'name': 'Properties', 'route': '/properties', 'paneId': 'view-properties', 'navAttr': 'properties'},
      {'name': 'Dealers', 'route': '/dealers', 'paneId': 'view-dealers', 'navAttr': 'dealers'},
      {'name': 'Market Intelligence', 'route': '/market-intelligence', 'paneId': 'view-market-intelligence', 'navAttr': 'market-intelligence'},
      {'name': 'AI Advisor', 'route': '/ai-advisor', 'paneId': 'view-ai-advisor', 'navAttr': 'ai-advisor'},
      {'name': 'Compare', 'route': '/compare', 'paneId': 'view-compare', 'navAttr': 'compare'},
      {'name': 'All Tools Hub', 'route': '/tools', 'paneId': 'view-tools', 'navAttr': 'tools'},
      {'name': 'Favorites', 'route': '/favorites', 'paneId': 'view-favorites', 'navAttr': 'favorites'},
      {'name': 'Notifications', 'route': '/notifications', 'paneId': 'view-notifications', 'navAttr': 'notifications'},
      {'name': 'Profile', 'route': '/profile', 'paneId': 'view-profile', 'navAttr': 'profile'}
    ];

    test('index.html contains every header nav link, logo link, and closed-by-default dropdown', () {
      final indexFile = File('index.html');
      expect(indexFile.existsSync(), isTrue);
      final body = indexFile.readAsStringSync();

      // 1. Logo Navigation
      expect(body.contains('data-nav="home"'), isTrue);
      expect(body.contains('navigateToRoute(\'/home\')'), isTrue);

      // 2. Dropdown starts hidden and triggers toggleAllToolsDropdown
      expect(body.contains('id="all-tools-dropdown-menu" class="absolute left-1/2 -translate-x-1/2 top-full mt-2 w-72 bg-white rounded-2xl shadow-xl border border-slate-200 py-2 hidden z-50 animate-fadeIn"'), isTrue,
          reason: 'All Tools dropdown must have class "hidden" by default and not open on hover');
      expect(body.contains('toggleAllToolsDropdown(event)'), isTrue);

      // 3. Every Navigation item container and view pane exists
      for (final item in navItems) {
        expect(body.contains('id="${item['paneId']}"'), isTrue,
            reason: 'Dedicated view pane container ${item['paneId']} for ${item['name']} must exist');
      }
    });

    test('Server serves all 11 header direct URLs with HTTP 200 OK without blank page or 404', () async {
      final client = HttpClient();

      for (final item in navItems) {
        final request = await client.getUrl(Uri.parse('http://localhost:8080${item['route']}'));
        final response = await request.close();
        final body = await response.transform(SystemEncoding().decoder).join();

        expect(response.statusCode, equals(200), reason: 'Route ${item['route']} must return HTTP 200');
        expect(response.headers.contentType?.mimeType, equals('text/html'));
        expect(body.contains('id="${item['paneId']}"'), isTrue,
            reason: 'Response for ${item['route']} must contain ${item['paneId']}');
      }

      client.close();
    });

    test('app.js handles active indicators, history pushState, popstate back/forward, and click-outside dismissal', () {
      final appJsFile = File('app.js');
      expect(appJsFile.existsSync(), isTrue);
      final js = appJsFile.readAsStringSync();

      expect(js.contains('function navigateToRoute('), isTrue);
      expect(js.contains('window.history.pushState('), isTrue);
      expect(js.contains('window.addEventListener(\'popstate\''), isTrue);
      expect(js.contains('function toggleAllToolsDropdown('), isTrue);
      expect(js.contains('function closeAllToolsDropdown('), isTrue);
      expect(js.contains('nav-indicator'), isTrue);
    });
  });
}
