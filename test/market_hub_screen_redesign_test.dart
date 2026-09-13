import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dealghar_ncr_10x/screens/market_hub_screen.dart';

void main() {
  group('NCR Market Signals Hub Redesigned UI Tests', () {
    testWidgets('1. Header renders with Live Market status, title, subtitle, and refresh button', (tester) async {
      tester.view.physicalSize = const Size(1200, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const MaterialApp(
          home: MarketHubScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('NCR Market Signals Hub'), findsOneWidget);
      expect(find.textContaining('Real-time price velocity & infrastructure catalysts'), findsOneWidget);
      expect(find.text('Live Market'), findsOneWidget);
      expect(find.textContaining('Updated Today'), findsOneWidget);
    });

    testWidgets('2. 4 KPI cards render with accurate metrics and labels', (tester) async {
      tester.view.physicalSize = const Size(1200, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const MaterialApp(
          home: MarketHubScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Average Price Growth'), findsOneWidget);
      expect(find.text('+18.2%'), findsOneWidget);

      expect(find.text('Top Growth Zone'), findsOneWidget);
      expect(find.text('Yamuna Exp.'), findsOneWidget);

      expect(find.text('Infrastructure Catalysts'), findsOneWidget);
      expect(find.text('12 Active'), findsOneWidget);

      expect(find.text('Market Sentiment'), findsOneWidget);
      expect(find.text('Bullish'), findsOneWidget);
    });

    testWidgets('3. Top NCR Growth Sectors renders with price range, infra score, demand, and progress bars', (tester) async {
      tester.view.physicalSize = const Size(1200, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const MaterialApp(
          home: MarketHubScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Top NCR Growth Sectors'), findsOneWidget);
      expect(find.text('Yamuna Expressway'), findsOneWidget);
      expect(find.text('+28.4% YoY'), findsOneWidget);
      expect(find.text('₹6,500 – ₹9,500 / sq.ft.'), findsOneWidget);
      expect(find.text('92/100'), findsOneWidget);
      expect(find.text('Growth Momentum'), findsWidgets);
      expect(find.byType(LinearProgressIndicator), findsWidgets);
    });

    testWidgets('4. Filter chips filter micro-market corridors correctly', (tester) async {
      tester.view.physicalSize = const Size(1200, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const MaterialApp(
          home: MarketHubScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Tap Gurgaon chip
      await tester.tap(find.text('Gurgaon'));
      await tester.pumpAndSettle();

      expect(find.text('Golf Course Ext Gurgaon'), findsOneWidget);
      expect(find.text('Yamuna Expressway'), findsNothing);

      // Tap All NCR Corridors chip
      await tester.tap(find.text('All NCR Corridors'));
      await tester.pumpAndSettle();

      expect(find.text('Yamuna Expressway'), findsOneWidget);
    });

    testWidgets('5. Infrastructure Catalyst Timeline displays all upcoming milestones with status badges', (tester) async {
      tester.view.physicalSize = const Size(1200, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const MaterialApp(
          home: MarketHubScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Infrastructure Catalyst Timeline'), findsOneWidget);
      expect(find.text('Q4 2026'), findsOneWidget);
      expect(find.text('Noida International Airport Operational Runways'), findsOneWidget);
      expect(find.text('On Track'), findsOneWidget);

      expect(find.text('Q1 2027'), findsOneWidget);
      expect(find.text('Aqua Line Metro Extension to Greater Noida West'), findsOneWidget);
      expect(find.text('Planned'), findsNWidgets(2));

      expect(find.text('Q3 2027'), findsOneWidget);
      expect(find.text('Cyber City 2 Tech Hub Opening in Gurgaon'), findsOneWidget);
    });

    testWidgets('6. AI Market Insight & 3 Infrastructure Impact Pillars render properly', (tester) async {
      tester.view.physicalSize = const Size(1200, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const MaterialApp(
          home: MarketHubScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('AI Market Insight'), findsOneWidget);
      expect(find.text('PropZen AI v2.4'), findsOneWidget);
      expect(find.textContaining('Very Positive'), findsOneWidget);
      expect(find.textContaining('Long-term Investors'), findsOneWidget);
      expect(find.textContaining('Moderate'), findsOneWidget);

      expect(find.text('Airport Connectivity'), findsOneWidget);
      expect(find.text('Metro Expansion'), findsOneWidget);
      expect(find.text('Commercial Development'), findsOneWidget);
    });

    testWidgets('7. Mobile responsive layout renders seamlessly without overflow', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const MaterialApp(
          home: MarketHubScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('NCR Market Signals Hub'), findsOneWidget);
      expect(find.text('Average Price Growth'), findsOneWidget);
      expect(find.text('Top NCR Growth Sectors'), findsOneWidget);
      expect(find.text('AI Market Insight'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
