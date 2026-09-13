import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../services/property_state_service.dart';
import '../theme/app_theme.dart';
import '../widgets/empty_state_view.dart';
import '../widgets/property_card.dart';

class WishlistScreen extends StatelessWidget {
  final Function(int)? onNavigateTab;

  const WishlistScreen({super.key, this.onNavigateTab});

  @override
  Widget build(BuildContext context) {
    final stateService = PropertyStateService.instance;

    return AnimatedBuilder(
      animation: stateService,
      builder: (context, _) {
        final saved = stateService.savedProperties;

        return Scaffold(
          backgroundColor: AppTheme.pageBackground,
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            iconTheme: const IconThemeData(color: AppTheme.textPrimary),
            title: Text(
              'Saved Properties (${saved.length})',
              style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
            ),
            bottom: const PreferredSize(
              preferredSize: Size.fromHeight(1),
              child: Divider(height: 1, color: AppTheme.borderLight),
            ),
          ),
          body: saved.isEmpty
              ? Center(
                  child: EmptyStateView(
                    title: 'No saved properties yet',
                    message: 'Explore properties and tap the heart icon to shortlist your favorite deals.',
                    icon: LucideIcons.heart,
                    actionLabel: 'Explore Properties',
                    onAction: () => onNavigateTab?.call(1),
                  ),
                )
              : LayoutBuilder(
                  builder: (context, constraints) {
                    int crossAxisCount = constraints.maxWidth >= 1000 ? 3 : (constraints.maxWidth >= 600 ? 2 : 1);
                    return GridView.builder(
                      padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 90),
                      physics: const AlwaysScrollableScrollPhysics(),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: crossAxisCount == 1
                            ? (constraints.maxWidth < 360 ? 0.65 : 0.72)
                            : (crossAxisCount == 2 ? 0.72 : 0.78),
                      ),
                      itemCount: saved.length,
                      itemBuilder: (ctx, i) => PropertyCard(property: saved[i]),
                    );
                  },
                ),
        );
      },
    );
  }
}
