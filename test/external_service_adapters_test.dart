import 'package:flutter_test/flutter_test.dart';
import 'package:dealghar_ncr_10x/services/property_visualization_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PropZen 9 Pillars External Service Adapters Tests', () {
    test('PropertyVisualizationService formats Matterport and Kuula URLs securely', () {
      final service = PropertyVisualizationService.instance;

      const rawMatterport = 'https://my.matterport.com/show/?m=SxZ9XG8zR1A';
      final formattedMatterport = service.format360TourEmbedUrl(rawMatterport);
      expect(formattedMatterport, contains('play=1'));
      expect(formattedMatterport, contains('brand=0'));

      const rawKuula = 'https://kuula.co/share/collection/7YXXX';
      final formattedKuula = service.format360TourEmbedUrl(rawKuula);
      expect(formattedKuula, contains('logo=1'));
      expect(formattedKuula, contains('fs=1'));
    });

    test('Visualization analytics event recording records timestamps and metadata', () {
      final service = PropertyVisualizationService.instance;
      service.logVisualizationEvent(
        eventName: '3D_TOUR_EXPLORED',
        propertyId: 'prop_mahagun',
        propertyTitle: 'Mahagun Manorialle',
        extraData: {'duration_seconds': 45},
      );

      expect(service.analyticsEvents, isNotEmpty);
      expect(service.analyticsEvents.first['event_name'], equals('3D_TOUR_EXPLORED'));
      expect(service.analyticsEvents.first['property_id'], equals('prop_mahagun'));
    });
  });
}
