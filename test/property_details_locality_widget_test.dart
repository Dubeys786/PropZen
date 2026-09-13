import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:dealghar_ncr_10x/models/property.dart';
import 'package:dealghar_ncr_10x/widgets/locality_personalities_widget.dart';

void main() {
  testWidgets('LocalityPersonalitiesWidget renders compact header, subtitle, 5 KM badge, privacy note, and clickable cards', (WidgetTester tester) async {
    final property = Property.sampleDeals.first; // ATS HomeKraft Happy Trails, Sector 10 Noida Extension

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: LocalityPersonalitiesWidget(property: property),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // 1. Verify Header & Subtitle
    expect(find.text('Know Your Locality'), findsOneWidget);
    expect(find.text('5 KM'), findsWidgets);
    expect(find.text('Notable people and community leaders around this property'), findsOneWidget);

    // 2. Verify Small Privacy Note
    expect(find.text('Locality information only. No property or PropZen affiliation is implied.'), findsOneWidget);

    // 3. Verify Pill Filters
    expect(find.widgetWithText(ChoiceChip, 'All'), findsOneWidget);
    expect(find.widgetWithText(ChoiceChip, 'Public Representatives'), findsOneWidget);
    expect(find.widgetWithText(ChoiceChip, 'Sports & Social'), findsOneWidget);

    // 4. Verify Matched Card Content
    expect(find.text('Tejpal Singh Nagar'), findsOneWidget);
    expect(find.text('Notable: '), findsWidgets);
    expect(find.text('View Source →'), findsWidgets);

    // 5. Verify Clickable Card Interaction (Opens Detail Modal)
    await tester.tap(find.text('Tejpal Singh Nagar'));
    await tester.pumpAndSettle();

    // Modal dialog is open
    expect(find.byType(Dialog), findsOneWidget);
    expect(find.text('Notable Achievements & Public Work:'), findsOneWidget);

    // Close Modal
    await tester.tap(find.byIcon(LucideIcons.x).first);
    await tester.pumpAndSettle();
  });

  testWidgets('LocalityPersonalitiesWidget renders empty state for remote coordinates without verified records', (WidgetTester tester) async {
    const remoteProp = Property(
      id: 'prop_remote_99',
      title: 'Remote Outlying Land',
      sector: 'Outlying Sector',
      city: 'Remote Region',
      latitude: 29.8000,
      longitude: 78.9000,
      askingPriceCr: 1.0,
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: LocalityPersonalitiesWidget(property: remoteProp),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify Empty State is displayed cleanly
    expect(find.text('No verified notable people found within 5 KM.'), findsOneWidget);
    expect(find.text('Explore Local Community & Governance'), findsOneWidget);
  });
}
