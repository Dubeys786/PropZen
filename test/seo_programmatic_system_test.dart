import 'package:flutter_test/flutter_test.dart';
import 'package:dealghar_ncr_10x/models/seo_content_model.dart';
import 'package:dealghar_ncr_10x/services/seo_content_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PropZen Programmatic SEO & Content System Tests', () {
    test('SeoContentService retrieves published articles and verified fallback models', () async {
      final articles = await SeoContentService.instance.fetchPublishedArticles();
      expect(articles, isNotEmpty);
      expect(articles.first.slug, startsWith('/insights/'));
      expect(articles.first.qualityScore, greaterThanOrEqualTo(90));
      expect(articles.first.faq, isNotEmpty);
      expect(articles.first.internalLinks, isNotEmpty);
    });

    test('SeoContentService retrieves structured programmatic location page data', () async {
      final page = await SeoContentService.instance.fetchLocationPageData('Sector 150', city: 'Noida');
      expect(page.slug, equals('/property-rates/noida/sector-150'));
      expect(page.avgPriceSqft, greaterThan(0));
      expect(page.faqs, isNotEmpty);
      expect(page.metaTitle, contains('Sector 150'));
    });
  });
}
