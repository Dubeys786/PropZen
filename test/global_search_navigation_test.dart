import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dealghar_ncr_10x/models/global_search_item.dart';
import 'package:dealghar_ncr_10x/services/global_search_service.dart';
import 'package:dealghar_ncr_10x/widgets/global_search_bar.dart';
import 'package:dealghar_ncr_10x/screens/main_shell.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('GlobalSearchService Unit Tests', () {
    final searchService = GlobalSearchService.instance;

    setUp(() {
      searchService.clearRecentSearches();
    });

    test('All items catalog has comprehensive indexing', () {
      final catalog = searchService.allItems;
      expect(catalog.length, greaterThanOrEqualTo(20));
      expect(searchService.popularSearchItems.isNotEmpty, isTrue);
      expect(searchService.quickAccessItems.isNotEmpty, isTrue);
      expect(searchService.serviceItems.isNotEmpty, isTrue);
      expect(searchService.discoverItems.isNotEmpty, isTrue);
    });

    test('Search "loan" returns Home Loan, Property Loan, EMI Calculator', () {
      final results = searchService.search('loan');
      expect(results.isNotEmpty, isTrue);
      final titles = results.map((e) => e.title.toLowerCase()).toList();
      expect(titles.any((t) => t.contains('loan') || t.contains('emi')), isTrue);
    });

    test('Search "dashboard" returns Dashboard / Dealer Portal', () {
      final results = searchService.search('dashboard');
      expect(results.isNotEmpty, isTrue);
      final titles = results.map((e) => e.title.toLowerCase()).toList();
      expect(titles.any((t) => t.contains('dashboard') || t.contains('portal')), isTrue);
    });

    test('Search "property" returns Properties, List Property, Saved', () {
      final results = searchService.search('property');
      expect(results.isNotEmpty, isTrue);
      final titles = results.map((e) => e.title.toLowerCase()).toList();
      expect(titles.any((t) => t.contains('properties') || t.contains('property')), isTrue);
    });

    test('Search "visit" returns Site Visits & Book a Site Visit', () {
      final results = searchService.search('visit');
      expect(results.isNotEmpty, isTrue);
      final titles = results.map((e) => e.title.toLowerCase()).toList();
      expect(titles.any((t) => t.contains('visit')), isTrue);
    });

    test('Search "dealer" returns Dealers Directory, Become a Dealer', () {
      final results = searchService.search('dealer');
      expect(results.isNotEmpty, isTrue);
      final titles = results.map((e) => e.title.toLowerCase()).toList();
      expect(titles.any((t) => t.contains('dealer')), isTrue);
    });

    test('Search "vastu" returns Vastu Consultation', () {
      final results = searchService.search('vastu');
      expect(results.isNotEmpty, isTrue);
      expect(results.first.title.toLowerCase(), contains('vastu'));
    });

    test('Search "interior" returns Interior Design', () {
      final results = searchService.search('interior');
      expect(results.isNotEmpty, isTrue);
      expect(results.first.title.toLowerCase(), contains('interior'));
    });

    test('Search "compare" returns Compare Properties', () {
      final results = searchService.search('compare');
      expect(results.isNotEmpty, isTrue);
      expect(results.first.title.toLowerCase(), contains('compare'));
    });

    test('Search "deal" returns Deals & Partner items', () {
      final results = searchService.search('deal');
      expect(results.isNotEmpty, isTrue);
      final titles = results.map((e) => e.title.toLowerCase()).toList();
      expect(titles.any((t) => t.contains('deal')), isTrue);
    });

    test('Search "ai" returns AI Match and AI Voice / Designer tools', () {
      final results = searchService.search('ai');
      expect(results.isNotEmpty, isTrue);
      final titles = results.map((e) => e.title.toLowerCase()).toList();
      expect(titles.any((t) => t.contains('ai')), isTrue);
    });

    test('Search "market" returns Market Hub', () {
      final results = searchService.search('market');
      expect(results.isNotEmpty, isTrue);
      expect(results.first.title.toLowerCase(), contains('market'));
    });

    test('Search "saved" returns Saved Properties', () {
      final results = searchService.search('saved');
      expect(results.isNotEmpty, isTrue);
      expect(results.first.title.toLowerCase(), contains('saved'));
    });

    test('Case-insensitivity and partial matching work correctly', () {
      final rUpper = searchService.search('LOAN');
      final rLower = searchService.search('loan');
      expect(rUpper.length, equals(rLower.length));

      final rPartial = searchService.search('calcu');
      expect(rPartial.any((e) => e.title.contains('Calculator')), isTrue);
    });

    test('Recent searches management (add, remove, clear)', () {
      searchService.addRecentSearch('Home Loan');
      searchService.addRecentSearch('Vastu');
      expect(searchService.recentSearches, contains('Vastu'));
      expect(searchService.recentSearches, contains('Home Loan'));

      searchService.removeRecentSearch('Home Loan');
      expect(searchService.recentSearches.contains('Home Loan'), isFalse);
      expect(searchService.recentSearches.contains('Vastu'), isTrue);

      searchService.clearRecentSearches();
      expect(searchService.recentSearches.isEmpty, isTrue);
    });
  });

  group('GlobalSearchBar Widget Tests', () {
    testWidgets('Renders search input with placeholder and shortcut badge', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: GlobalSearchBar(width: 320),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('Search properties, services, loans & more...'), findsOneWidget);
      expect(find.byType(GlobalSearchBar), findsOneWidget);
    });

    testWidgets('Focusing search bar opens overlay dropdown', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: GlobalSearchBar(width: 320),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap on search bar to focus
      await tester.tap(find.byType(TextField));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Should show suggestions headers
      expect(find.text('POPULAR SEARCHES'), findsOneWidget);
      expect(find.text('QUICK ACCESS'), findsOneWidget);
    });

    testWidgets('Typing query displays live filtered results', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: GlobalSearchBar(width: 320),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'loan');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.textContaining('RESULTS ('), findsOneWidget);
      expect(find.text('Home Loan'), findsWidgets);
    });

    testWidgets('Mobile modal sheet renders successfully', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (ctx) => ElevatedButton(
                onPressed: () => GlobalSearchBar.showSearchModal(ctx),
                child: const Text('Open Search'),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open Search'));
      await tester.pumpAndSettle();

      expect(find.text('Search properties, services, loans...'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
    });
  });

  group('MainShell Navigation & Responsiveness Tests', () {
    testWidgets('Renders MainShell navigation bar across Desktop (1440px) without overflow', (tester) async {
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        const MaterialApp(
          home: MainShell(initialIndex: 1),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.byType(GlobalSearchBar), findsOneWidget);
      expect(find.text('Talk to PropZen AI'), findsOneWidget);
      expect(find.text('List Your Property'), findsOneWidget);
      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Properties'), findsWidgets);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Renders MainShell navigation bar across Tablet (768px) without overflow', (tester) async {
      tester.view.physicalSize = const Size(768, 1024);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        const MaterialApp(
          home: MainShell(initialIndex: 1),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.byType(GlobalSearchBar), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Renders MainShell navigation bar across Mobile (375px) without overflow', (tester) async {
      tester.view.physicalSize = const Size(375, 812);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        const MaterialApp(
          home: MainShell(initialIndex: 1),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.byType(GlobalSearchBar), findsNothing);
      expect(tester.takeException(), isNull);
    });
  });
}
