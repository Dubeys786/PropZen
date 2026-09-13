import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('All Tools Mega Modal Navigation & Direct Route Tests', () {
    final toolRoutes = [
      {'name': '3D Video', 'route': '/tools/3d-video', 'paneId': 'view-tool-3d-video'},
      {'name': 'Property Visualization', 'route': '/tools/property-visualization', 'paneId': 'view-tool-property-visualization'},
      {'name': 'Drone Tour', 'route': '/tools/drone-tour', 'paneId': 'view-tool-drone-tour'},
      {'name': 'Vastu Consultancy', 'route': '/tools/vastu-consultancy', 'paneId': 'view-tool-vastu-consultancy'},
      {'name': 'Loan Consultancy', 'route': '/tools/loan-consultancy', 'paneId': 'view-tool-loan-consultancy'},
      {'name': 'Documentation Consultancy', 'route': '/tools/documentation-consultancy', 'paneId': 'view-tool-documentation-consultancy'},
      {'name': 'Project Real Video', 'route': '/tools/project-real-video', 'paneId': 'view-tool-project-real-video'},
      {'name': 'Interior Design', 'route': '/tools/interior-design', 'paneId': 'view-tool-interior-design'},
      {'name': 'Exterior Design', 'route': '/tools/exterior-design', 'paneId': 'view-tool-exterior-design'},
      {'name': 'Customer Discussion Forum', 'route': '/tools/customer-forum', 'paneId': 'view-tool-customer-forum'},
      {'name': 'Construction Consultancy', 'route': '/tools/construction-consultancy', 'paneId': 'view-tool-construction-consultancy'},
      {'name': 'All Tools Hub', 'route': '/tools', 'paneId': 'view-tools'}
    ];

    test('index.html contains PropZen Platform & Professional Services modal matching exact screenshot', () {
      final indexFile = File('index.html');
      expect(indexFile.existsSync(), isTrue);
      final body = indexFile.readAsStringSync();

      // Verify Mega Modal container & copy
      expect(body.contains('id="propzen-services-modal"'), isTrue, reason: 'Mega Modal container must exist');
      expect(body.contains('PropZen Platform &amp; Professional Services'), isTrue, reason: 'Exact title must exist');
      expect(body.contains('End-to-End Real Estate, Visualization, Finance, Legal &amp; Community Services across NCR'), isTrue,
          reason: 'Exact subtitle must exist');

      // Verify 3 Column Category Headings
      expect(body.contains('DESIGN &amp; VISUALIZATION'), isTrue, reason: 'DESIGN & VISUALIZATION category heading must exist');
      expect(body.contains('CONSULTANCY'), isTrue, reason: 'CONSULTANCY category heading must exist');
      expect(body.contains('PROPERTY SERVICES'), isTrue, reason: 'PROPERTY SERVICES category heading must exist');
      expect(body.contains('COMMUNITY'), isTrue, reason: 'COMMUNITY category heading must exist');
      expect(body.contains('PLATFORM INTELLIGENCE'), isTrue, reason: 'PLATFORM INTELLIGENCE category heading must exist');

      // Verify specific items
      expect(body.contains('Home Design'), isTrue);
      expect(body.contains('3D Video'), isTrue);
      expect(body.contains('Property Visualization'), isTrue);
      expect(body.contains('Drone Tour'), isTrue);
      expect(body.contains('Interior Designing'), isTrue);
      expect(body.contains('Exterior Designing'), isTrue);
      expect(body.contains('Vastu Consultancy'), isTrue);
      expect(body.contains('Loan Consultancy'), isTrue);
      expect(body.contains('Document Verification'), isTrue);
      expect(body.contains('Construction Support'), isTrue);
      expect(body.contains('Customer Discussion Forum'), isTrue);
      expect(body.contains('10X Intelligence Report'), isTrue);
      expect(body.contains('Market Signals Hub'), isTrue);
      expect(body.contains('EMI Calculator'), isTrue);
      expect(body.contains('Legal &amp; Appreciation Audit'), isTrue);

      // Verify each tool pane container exists
      for (final tool in toolRoutes) {
        expect(body.contains('id="${tool['paneId']}"'), isTrue,
            reason: 'Dedicated view pane container for ${tool['name']} (${tool['paneId']}) must exist');
      }
    });

    test('app.js router maps every tool route to its dedicated view pane and closes modal', () {
      final appJsFile = File('app.js');
      expect(appJsFile.existsSync(), isTrue);
      final jsContent = appJsFile.readAsStringSync();

      expect(jsContent.contains('function handleToolDropdownClick('), isTrue);
      expect(jsContent.contains('function openAllToolsModal('), isTrue);
      expect(jsContent.contains('function closeAllToolsModal('), isTrue);
      expect(jsContent.contains('function toggleAllToolsDropdown('), isTrue);
      expect(jsContent.contains('tool-loan-consultancy'), isTrue);
      expect(jsContent.contains('calculateLoanConsultancyEmi'), isTrue);
    });

    test('Server serves every individual tool direct URL with 200 OK for direct refresh support', () async {
      final client = HttpClient();

      for (final tool in toolRoutes) {
        final request = await client.getUrl(Uri.parse('http://localhost:8080${tool['route']}'));
        final response = await request.close();
        final body = await response.transform(SystemEncoding().decoder).join();

        expect(response.statusCode, equals(200), reason: 'Route ${tool['route']} must return HTTP 200 OK');
        expect(response.headers.contentType?.mimeType, equals('text/html'));
        expect(body.contains('id="${tool['paneId']}"'), isTrue,
            reason: 'HTML response for direct visit to ${tool['route']} must include the corresponding view container');
      }

      client.close();
    });
  });
}
