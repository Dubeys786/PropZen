import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dealghar_ncr_10x/services/property_state_service.dart';
import 'package:dealghar_ncr_10x/theme/responsive_layout.dart';
import 'package:dealghar_ncr_10x/screens/site_visit_booking_screen.dart';
import 'package:dealghar_ncr_10x/screens/ai_home_designer_landing_screen.dart';
import 'package:dealghar_ncr_10x/screens/dual_auth_screen.dart';
import 'package:dealghar_ncr_10x/widgets/property_card.dart';

void main() {
  final sampleProperty = PropertyStateService.instance.allProperties.first;

  const testViewports = [
    Size(360, 800),   // Compact Mobile
    Size(375, 667),   // iPhone SE
    Size(390, 844),   // iPhone 14
    Size(414, 896),   // iPhone 11
    Size(430, 932),   // iPhone 15 Pro Max
    Size(600, 960),   // Small Tablet
    Size(768, 1024),  // iPad Portrait
    Size(820, 1180),  // iPad Air
    Size(1024, 768),  // Tablet Landscape / Small Laptop
    Size(1280, 800),  // Standard Desktop
    Size(1440, 900),  // Large Desktop
    Size(1920, 1080), // 4K / Ultra-wide Desktop
  ];

  group('Centralized Responsive System - Viewport Breakpoint Tests', () {
    for (final size in testViewports) {
      test('ResponsiveLayout correctly classifies ${size.width}x${size.height}', () {
        final w = size.width;
        if (w < 600) {
          expect(ResponsiveLayout.isMobileWidth(w), isTrue);
          expect(ResponsiveLayout.isTabletWidth(w), isFalse);
          expect(ResponsiveLayout.isDesktopWidth(w), isFalse);
        } else if (w <= 1024) {
          expect(ResponsiveLayout.isMobileWidth(w), isFalse);
          expect(ResponsiveLayout.isTabletWidth(w), isTrue);
          expect(ResponsiveLayout.isDesktopWidth(w), isFalse);
        } else if (w <= 1440) {
          expect(ResponsiveLayout.isMobileWidth(w), isFalse);
          expect(ResponsiveLayout.isTabletWidth(w), isFalse);
          expect(ResponsiveLayout.isDesktopWidth(w), isTrue);
        } else {
          expect(ResponsiveLayout.isLargeDesktopWidth(w), isTrue);
        }
      });
    }
  });

  group('Property Card - Responsive Multi-Viewport Rendering', () {
    for (final size in testViewports) {
      testWidgets('PropertyCard renders without overflow at ${size.width}px', (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Center(
                child: SizedBox(
                  width: size.width < 600 ? size.width - 32 : (size.width < 1024 ? (size.width - 48) / 2 : 380),
                  child: PropertyCard(property: sampleProperty),
                ),
              ),
            ),
          ),
        );

        await tester.pump();
        expect(find.text(sampleProperty.title), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  });

  group('Key Screens - Responsive Rendering Across All Breakpoints', () {
    for (final size in [
      const Size(360, 800),
      const Size(768, 1024),
      const Size(1280, 800),
      const Size(1920, 1080),
    ]) {
      testWidgets('SiteVisitBookingScreen renders cleanly at ${size.width}px', (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        await tester.pumpWidget(
          MaterialApp(
            home: SiteVisitBookingScreen(property: sampleProperty),
          ),
        );

        await tester.pump();
        expect(find.text('Book a Site Visit'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });

      testWidgets('DualAuthScreen renders cleanly at ${size.width}px', (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        await tester.pumpWidget(
          const MaterialApp(
            home: DualAuthScreen(),
          ),
        );

        await tester.pump();
        expect(find.text('Welcome to PropZen'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });

      testWidgets('AiHomeDesignerLandingScreen renders cleanly at ${size.width}px', (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() async {
          tester.view.resetPhysicalSize();
          await tester.pumpWidget(const SizedBox.shrink());
        });

        await tester.pumpWidget(
          const MaterialApp(
            home: AiHomeDesignerLandingScreen(),
          ),
        );

        await tester.pump(const Duration(milliseconds: 100));
        expect(find.text('AI Home & Vastu Designer'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  });
}
