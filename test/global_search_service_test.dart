import 'package:flutter_test/flutter_test.dart';
import 'package:dealghar_ncr_10x/services/global_search_service.dart';
import 'package:dealghar_ncr_10x/screens/user_profile_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('GlobalSearchService Tests', () {
    final searchService = GlobalSearchService.instance;

    test('Contains curated 4-column categories', () {
      expect(searchService.popularSearchItems.isNotEmpty, isTrue);
      expect(searchService.quickAccessItems.isNotEmpty, isTrue);
      expect(searchService.serviceItems.isNotEmpty, isTrue);
      expect(searchService.discoverItems.isNotEmpty, isTrue);

      // Verify Popular Searches has 8 items
      expect(searchService.popularSearchItems.length, equals(8));
      // Verify Quick Access has 6 items
      expect(searchService.quickAccessItems.length, equals(6));
      // Verify Services has 8 items
      expect(searchService.serviceItems.length, equals(8));
      // Verify Discover has 6 items
      expect(searchService.discoverItems.length, equals(6));
    });

    test('Query "dashboard" returns Dashboard and My Profile', () {
      final results = searchService.search('dashboard');
      expect(results.isNotEmpty, isTrue);
      final titles = results.map((e) => e.title).toList();
      expect(titles.contains('Dashboard'), isTrue);
      expect(titles.contains('My Profile'), isTrue);
    });

    test('Query "loan" returns Home Loan, Property Loan, Loan Consultancy', () {
      final results = searchService.search('loan');
      expect(results.isNotEmpty, isTrue);
      final titles = results.map((e) => e.title).toList();
      expect(titles.contains('Home Loan'), isTrue);
      expect(titles.contains('Property Loan'), isTrue);
      expect(titles.contains('Loan Consultancy'), isTrue);
    });

    test('Query "site" returns Site Visits, Book a Site Visit', () {
      final results = searchService.search('site');
      expect(results.isNotEmpty, isTrue);
      final titles = results.map((e) => e.title).toList();
      expect(titles.contains('Site Visits'), isTrue);
      expect(titles.contains('Book a Site Visit'), isTrue);
    });

    test('Query "compare" returns Compare and Compare Properties', () {
      final results = searchService.search('compare');
      expect(results.isNotEmpty, isTrue);
      final titles = results.map((e) => e.title).toList();
      expect(titles.contains('Compare'), isTrue);
      expect(titles.contains('Compare Properties'), isTrue);
    });

    test('Query "property" returns Properties, Property Verification, List Your Property', () {
      final results = searchService.search('property');
      expect(results.isNotEmpty, isTrue);
      final titles = results.map((e) => e.title).toList();
      expect(titles.contains('Properties'), isTrue);
      expect(titles.contains('Property Verification'), isTrue);
      expect(titles.contains('List Your Property'), isTrue);
    });

    test('Query "dealer" for normal user returns Dealers Directory and Become a Dealer', () {
      UserSession.roleTierNotifier.value = 'Free User';
      final results = searchService.search('dealer');
      final titles = results.map((e) => e.title).toList();
      expect(titles.contains('Dealers Directory'), isTrue);
      expect(titles.contains('Become a Dealer / Partner'), isTrue);
      expect(titles.contains('Dealer Portal'), isFalse);
    });

    test('Query "dealer" for dealer user returns Dealer Portal', () {
      UserSession.roleTierNotifier.value = 'DEALER';
      final results = searchService.search('dealer');
      final titles = results.map((e) => e.title).toList();
      expect(titles.contains('Dealer Portal'), isTrue);
      // Reset
      UserSession.roleTierNotifier.value = 'Free User';
    });

    test('Query "admin" or "command center" hides Command Center for non-admin', () {
      UserSession.roleTierNotifier.value = 'Free User';
      final results = searchService.search('command center');
      final titles = results.map((e) => e.title).toList();
      expect(titles.contains('Command Center'), isFalse);
    });

    test('Query "ai" returns AI Match and Talk to PropZen AI', () {
      final results = searchService.search('ai');
      expect(results.isNotEmpty, isTrue);
      final titles = results.map((e) => e.title).toList();
      expect(titles.contains('AI Match'), isTrue);
      expect(titles.contains('Talk to PropZen AI'), isTrue);
    });

    test('Query "vastu" returns Vastu Consultation', () {
      final results = searchService.search('vastu');
      expect(results.isNotEmpty, isTrue);
      expect(results.any((e) => e.title == 'Vastu Consultation'), isTrue);
    });

    test('Query "interior" returns Interior Design', () {
      final results = searchService.search('interior');
      expect(results.isNotEmpty, isTrue);
      expect(results.any((e) => e.title == 'Interior Design'), isTrue);
    });

    test('Query "verification" returns Property Verification and Legal Verification', () {
      final results = searchService.search('verification');
      expect(results.isNotEmpty, isTrue);
      final titles = results.map((e) => e.title).toList();
      expect(titles.contains('Property Verification'), isTrue);
      expect(titles.contains('Legal Verification'), isTrue);
    });

    test('Query "drone" returns Drone Tour', () {
      final results = searchService.search('drone');
      expect(results.isNotEmpty, isTrue);
      expect(results.any((e) => e.title == 'Drone Tour'), isTrue);
    });

    test('Query "deal" returns Deals, Hot Deals, My Deals', () {
      final results = searchService.search('deal');
      expect(results.isNotEmpty, isTrue);
      final titles = results.map((e) => e.title).toList();
      expect(titles.contains('Deals'), isTrue);
      expect(titles.contains('Hot Deals'), isTrue);
      expect(titles.contains('My Deals'), isTrue);
    });

    test('Recent searches adding, deleting, and clearing', () {
      searchService.addRecentSearch('Test Search Query');
      expect(searchService.recentSearches.first, equals('Test Search Query'));

      searchService.removeRecentSearch('Test Search Query');
      expect(searchService.recentSearches.contains('Test Search Query'), isFalse);

      searchService.clearRecentSearches();
      expect(searchService.recentSearches.isEmpty, isTrue);
    });
  });
}
