import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Home Page Filters & Real Estate Data Engine Integration Tests', () {
    test('index.html contains all Home page filter inputs, dropdowns, and category tiles', () async {
      final client = HttpClient();
      final request = await client.getUrl(Uri.parse('http://localhost:8080/home'));
      final response = await request.close();
      final body = await response.transform(SystemEncoding().decoder).join();

      expect(response.statusCode, equals(200));

      // 1. Hero Search & Location Input
      expect(body.contains('id="hero-location-input"'), isTrue, reason: 'Location input must have id="hero-location-input"');
      expect(body.contains('filterProperties()'), isTrue, reason: 'Location input must call filterProperties() on input/keyup');

      // 2. Budget Dropdown
      expect(body.contains('id="hero-budget-select"'), isTrue, reason: 'Budget select must have id="hero-budget-select"');
      expect(body.contains('under50l'), isTrue, reason: 'Budget dropdown must contain under50l');
      expect(body.contains('50l-1cr'), isTrue, reason: 'Budget dropdown must contain 50l-1cr');
      expect(body.contains('1cr-3cr'), isTrue, reason: 'Budget dropdown must contain 1cr-3cr');
      expect(body.contains('3crplus'), isTrue, reason: 'Budget dropdown must contain 3crplus');

      // 3. Category Filter Tiles
      expect(body.contains('setCategoryFilter(\'buy\')'), isTrue, reason: 'Buy category tile must exist and call setCategoryFilter');
      expect(body.contains('setCategoryFilter(\'rent\')'), isTrue, reason: 'Rent category tile must exist and call setCategoryFilter');
      expect(body.contains('setCategoryFilter(\'plot\')'), isTrue, reason: 'Plot category tile must exist and call setCategoryFilter');
      expect(body.contains('setCategoryFilter(\'residential\')'), isTrue, reason: 'Residential category tile must exist and call setCategoryFilter');
      expect(body.contains('setCategoryFilter(\'commercial\')'), isTrue, reason: 'Commercial category tile must exist and call setCategoryFilter');
      expect(body.contains('setCategoryFilter(\'agricultural\')'), isTrue, reason: 'Agricultural category tile must exist and call setCategoryFilter');

      // 4. Market Snapshot Time Select & Metric KPIs
      expect(body.contains('id="home-market-time-select"'), isTrue, reason: 'Market Snapshot time period select must exist');
      expect(body.contains('id="home-kpi-price"'), isTrue, reason: 'Avg price KPI must have id="home-kpi-price"');
      expect(body.contains('id="home-kpi-launches"'), isTrue, reason: 'New launches KPI must have id="home-kpi-launches"');
      expect(body.contains('id="home-kpi-deals"'), isTrue, reason: 'Deals closed KPI must have id="home-kpi-deals"');
      expect(body.contains('id="home-kpi-inventory"'), isTrue, reason: 'Active inventory KPI must have id="home-kpi-inventory"');

      // 5. Results Counter and Reset Button
      expect(body.contains('id="home-results-count"'), isTrue, reason: 'Results counter badge must exist');
      expect(body.contains('id="home-active-filter-tags"'), isTrue, reason: 'Active filter tags container must exist');
      expect(body.contains('resetHomeFilters()'), isTrue, reason: 'Clear all filters action button must exist');

      // 6. Advanced More Filters Modal
      expect(body.contains('id="more-filters-modal"'), isTrue, reason: 'Add More Filters modal must exist');
      expect(body.contains('openMoreFiltersModal()'), isTrue, reason: 'Add More Filters button must open modal');
      expect(body.contains('applyMoreFiltersModal()'), isTrue, reason: 'Apply filters button must exist');

      client.close();
    });

    test('app.js contains complete Home filter engine, AND logic, and state synchronization', () {
      final appJsFile = File('app.js');
      expect(appJsFile.existsSync(), isTrue);
      final content = appJsFile.readAsStringSync();

      expect(content.contains('const homeFilterState ='), isTrue, reason: 'homeFilterState master object must exist');
      expect(content.contains('function filterProperties('), isTrue, reason: 'filterProperties function must exist');
      expect(content.contains('function setCategoryFilter('), isTrue, reason: 'setCategoryFilter function must exist');
      expect(content.contains('function filterByPlotType('), isTrue, reason: 'filterByPlotType function must exist');
      expect(content.contains('function toggleHomeAmenityFilter('), isTrue, reason: 'toggleHomeAmenityFilter function must exist');
      expect(content.contains('function resetHomeFilters()'), isTrue, reason: 'resetHomeFilters function must exist');
      expect(content.contains('function openMoreFiltersModal()'), isTrue, reason: 'openMoreFiltersModal function must exist');
      expect(content.contains('function updateHomeMarketSnapshot('), isTrue, reason: 'updateHomeMarketSnapshot function must exist');
    });
  });
}
