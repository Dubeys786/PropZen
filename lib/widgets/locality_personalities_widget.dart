import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/property.dart';
import '../models/locality_personality.dart';
import '../theme/app_theme.dart';

/// Compact & Premium "Know Your Locality" Section
/// Displays property-specific nearby notable personalities, community RWA, and local governance.
class LocalityPersonalitiesWidget extends StatefulWidget {
  final Property property;

  const LocalityPersonalitiesWidget({super.key, required this.property});

  @override
  State<LocalityPersonalitiesWidget> createState() => _LocalityPersonalitiesWidgetState();
}

class _LocalityPersonalitiesWidgetState extends State<LocalityPersonalitiesWidget> {
  String _selectedFilter = 'All';
  bool _showAllCards = false;

  // All possible candidate filter categories
  static const List<String> _allCandidateFilters = [
    'Residents',
    'YouTubers',
    'Influencers',
    'Educators',
    'Entrepreneurs',
    'Sports & Social',
    'Public Representatives',
    'RWA & Community',
    'Local Governance',
  ];

  bool _matchesFilter(LocalityInfoItem item, String filter) {
    if (filter == 'All') return true;
    if (filter == 'Residents') {
      return item.associationType == LocalityAssociationType.resident ||
          item.category.toLowerCase().contains('resident');
    }
    if (filter == 'YouTubers') {
      return item.category.toLowerCase().contains('youtuber') ||
          item.associationType == LocalityAssociationType.youtuberCreator;
    }
    if (filter == 'Influencers') {
      return item.category.toLowerCase().contains('influencer') ||
          item.category.toLowerCase().contains('youtuber') ||
          item.associationType == LocalityAssociationType.influencer;
    }
    if (filter == 'Educators') {
      return item.category.toLowerCase().contains('educator') ||
          item.associationType == LocalityAssociationType.educator;
    }
    if (filter == 'Entrepreneurs') {
      return item.category.toLowerCase().contains('entrepreneur') ||
          item.associationType == LocalityAssociationType.founderInArea;
    }
    if (filter == 'Sports & Social') {
      return item.category.toLowerCase().contains('sport') ||
          item.category.toLowerCase().contains('social') ||
          item.associationType == LocalityAssociationType.sportsPersonality ||
          item.associationType == LocalityAssociationType.socialLeader;
    }
    if (filter == 'Public Representatives') {
      return item.associationType == LocalityAssociationType.publicRepresentative ||
          item.category.toLowerCase().contains('representative') ||
          item.category.toLowerCase().contains('mp') ||
          item.category.toLowerCase().contains('mla');
    }
    if (filter == 'RWA & Community') {
      return item.level == LocalityInfoLevel.communityRwa ||
          item.associationType == LocalityAssociationType.rwaPresident ||
          item.associationType == LocalityAssociationType.rwaSecretary;
    }
    if (filter == 'Local Governance') {
      return item.level == LocalityInfoLevel.localGovernance ||
          item.associationType == LocalityAssociationType.localCouncillor;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    // Resolve locality records specifically for this property
    final localityResult = LocalityPersonalityRegistry.getLocalInformationForProperty(
      widget.property,
      radiusKm: 5.0,
      maxResults: _showAllCards ? 30 : 6,
    );

    final allItems = localityResult.allCombined;

    // Dynamically calculate which filter pills have at least 1 record for this property
    final dynamicPills = <String>['All'];
    for (final filter in _allCandidateFilters) {
      final count = allItems.where((item) => _matchesFilter(item, filter)).length;
      if (count > 0) {
        dynamicPills.add(filter);
      }
    }

    final activeFilter = dynamicPills.contains(_selectedFilter) ? _selectedFilter : 'All';
    final filteredItems = allItems.where((item) => _matchesFilter(item, activeFilter)).toList();

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(color: Color(0x04000000), blurRadius: 8, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Header with Badge
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(6.5),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(LucideIcons.mapPin, color: Color(0xFF2563EB), size: 17),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            'Know Your Locality',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFDBEAFE),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '5 KM',
                            style: GoogleFonts.inter(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF1D4ED8),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 1),
                    Text(
                      'Notable people and community leaders around this property',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // 2. Small Privacy Disclaimer
          Text(
            'Locality information only. No property or PropZen affiliation is implied.',
            style: GoogleFonts.inter(
              fontSize: 11,
              color: const Color(0xFF64748B),
              height: 1.3,
            ),
          ),

          const SizedBox(height: 14),

          // 3. Compact Horizontally Scrollable Pill Filters (No horizontal page overflow)
          if (dynamicPills.length > 1)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: dynamicPills.map((filter) {
                  final isSelected = activeFilter == filter;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(
                        filter,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                          color: isSelected ? Colors.white : const Color(0xFF334155),
                        ),
                      ),
                      selected: isSelected,
                      selectedColor: const Color(0xFF2563EB),
                      backgroundColor: const Color(0xFFF8FAFC),
                      side: BorderSide(
                        color: isSelected ? const Color(0xFF2563EB) : const Color(0xFFE2E8F0),
                        width: 1,
                      ),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      onSelected: (selected) {
                        setState(() {
                          _selectedFilter = filter;
                        });
                      },
                    ),
                  );
                }).toList(),
              ),
            ),

          if (dynamicPills.length > 1) const SizedBox(height: 14),

          // 4. Compact Responsive Cards or Empty State
          if (filteredItems.isEmpty)
            _buildEmptyState(localityResult)
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildResponsiveGrid(filteredItems),
                if (allItems.length > 6 && !_showAllCards) ...[
                  const SizedBox(height: 14),
                  Center(
                    child: TextButton.icon(
                      onPressed: () {
                        setState(() {
                          _showAllCards = true;
                        });
                      },
                      icon: const Icon(LucideIcons.arrowDownCircle, size: 14, color: Color(0xFF2563EB)),
                      label: Text(
                        'View All Locality People →',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF2563EB),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(PropertyLocalityResult result) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          const Icon(LucideIcons.mapPinOff, size: 22, color: Color(0xFF94A3B8)),
          const SizedBox(height: 8),
          Text(
            'No verified notable people found within 5 KM.',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
          ),
          const SizedBox(height: 4),
          Text(
            'Explore Local Community & Governance',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(fontSize: 11.5, color: const Color(0xFF2563EB), fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildResponsiveGrid(List<LocalityInfoItem> items) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final isDesktop = width >= 960;
        final isTablet = width >= 600 && width < 960;

        int crossAxisCount = 1;
        double childAspectRatio = 1.65;

        if (isDesktop) {
          crossAxisCount = 3;
          childAspectRatio = 1.38; // ~235px height
        } else if (isTablet) {
          crossAxisCount = 2;
          childAspectRatio = 1.45; // ~230px height
        } else {
          crossAxisCount = 1;
          childAspectRatio = 1.68; // ~210px height
        }

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: childAspectRatio,
          ),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final item = items[index];
            return _buildCompactPersonalityCard(item, isDesktop);
          },
        );
      },
    );
  }

  Widget _buildCompactPersonalityCard(LocalityInfoItem item, bool isDesktop) {
    final photoSize = isDesktop ? 76.0 : 60.0;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _openDetailModal(context, item),
        borderRadius: BorderRadius.circular(16),
        hoverColor: const Color(0xFFF1F5F9),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFFAFAFA),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: const [
              BoxShadow(color: Color(0x03000000), blurRadius: 4, offset: Offset(0, 1)),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Top Row: Photo + Name + Category + Verified Badge
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipOval(
                    child: Container(
                      width: photoSize,
                      height: photoSize,
                      color: const Color(0xFFDBEAFE),
                      child: item.imageUrl.isNotEmpty
                          ? Image.network(
                              item.imageUrl,
                              width: photoSize,
                              height: photoSize,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Center(
                                child: Text(
                                  item.name.isNotEmpty ? item.name[0] : '?',
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF1D4ED8),
                                    fontSize: isDesktop ? 22 : 18,
                                  ),
                                ),
                              ),
                            )
                          : Center(
                              child: Text(
                                item.name.isNotEmpty ? item.name[0] : '?',
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF1D4ED8),
                                  fontSize: isDesktop ? 22 : 18,
                                ),
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.name,
                          style: GoogleFonts.poppins(
                            fontSize: 14.5,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 1),
                        Text(
                          item.role,
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF2563EB),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 3),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFDCFCE7),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            item.associationType == LocalityAssociationType.resident
                                ? '✓ Verified local resident'
                                : '✓ Verified local connection',
                            style: GoogleFonts.inter(
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF15803D),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              // Short 1-2 line description
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Text(
                  item.about,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: const Color(0xFF475569),
                    height: 1.3,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),

              // Notable Achievement
              if (item.notableWork.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Notable: ',
                        style: GoogleFonts.inter(fontSize: 10.5, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                      ),
                      Expanded(
                        child: Text(
                          '• ${item.notableWork.first}',
                          style: GoogleFonts.inter(fontSize: 10.5, color: const Color(0xFF64748B)),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),

              const Divider(height: 8, color: Color(0xFFE2E8F0)),

              // Bottom Bar: Source + "View Source →"
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      item.associationSource,
                      style: GoogleFonts.inter(fontSize: 9.5, color: const Color(0xFF94A3B8)),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (item.associationSourceUrl.isNotEmpty)
                    InkWell(
                      onTap: () async {
                        final uri = Uri.parse(item.associationSourceUrl);
                        if (await canLaunchUrl(uri)) {
                          await launchUrl(uri, mode: LaunchMode.externalApplication);
                        }
                      },
                      child: Text(
                        'View Source →',
                        style: GoogleFonts.inter(
                          fontSize: 10.5,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF2563EB),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Interactive Personality / Locality Detail Modal
  void _openDetailModal(BuildContext context, LocalityInfoItem item) {
    showDialog(
      context: context,
      builder: (ctx) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          backgroundColor: Colors.white,
          insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: Padding(
              padding: const EdgeInsets.all(22),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top Row: Avatar + Name + Role + Close Button
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipOval(
                        child: Container(
                          width: 60,
                          height: 60,
                          color: const Color(0xFFDBEAFE),
                          child: item.imageUrl.isNotEmpty
                              ? Image.network(
                                  item.imageUrl,
                                  width: 60,
                                  height: 60,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Center(
                                    child: Text(
                                      item.name.isNotEmpty ? item.name[0] : '?',
                                      style: GoogleFonts.poppins(
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                        color: const Color(0xFF1D4ED8),
                                      ),
                                    ),
                                  ),
                                )
                              : Center(
                                  child: Text(
                                    item.name.isNotEmpty ? item.name[0] : '?',
                                    style: GoogleFonts.poppins(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFF1D4ED8),
                                    ),
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.name,
                              style: GoogleFonts.poppins(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              item.role,
                              style: GoogleFonts.inter(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF2563EB),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFDCFCE7),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                '✓ Verified local connection',
                                style: GoogleFonts.inter(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF15803D),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(ctx).pop(),
                        icon: const Icon(LucideIcons.x, size: 20, color: Color(0xFF64748B)),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),
                  const Divider(height: 1, color: Color(0xFFE2E8F0)),
                  const SizedBox(height: 12),

                  // Locality / Society Label
                  Row(
                    children: [
                      const Icon(LucideIcons.mapPin, size: 13, color: Color(0xFF64748B)),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          item.societyOrArea,
                          style: GoogleFonts.inter(fontSize: 11.5, fontWeight: FontWeight.w600, color: const Color(0xFF334155)),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  // Description
                  Text(
                    item.about,
                    style: GoogleFonts.inter(fontSize: 12.5, color: const Color(0xFF475569), height: 1.4),
                  ),

                  // Notable Work Bullet Points
                  if (item.notableWork.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(
                      'Notable Achievements & Public Work:',
                      style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                    ),
                    const SizedBox(height: 6),
                    ...item.notableWork.map((nw) => Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('• ', style: TextStyle(fontSize: 11, color: Color(0xFF2563EB), fontWeight: FontWeight.bold)),
                              Expanded(
                                child: Text(
                                  nw,
                                  style: GoogleFonts.inter(fontSize: 11.5, color: const Color(0xFF64748B), height: 1.3),
                                ),
                              ),
                            ],
                          ),
                        )),
                  ],

                  const SizedBox(height: 16),
                  const Divider(height: 1, color: Color(0xFFE2E8F0)),
                  const SizedBox(height: 12),

                  // Bottom: Source info + Open External Link Button
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          'Source: ${item.associationSource}',
                          style: GoogleFonts.inter(fontSize: 10.5, color: const Color(0xFF94A3B8)),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (item.associationSourceUrl.isNotEmpty)
                        ElevatedButton.icon(
                          onPressed: () async {
                            final uri = Uri.parse(item.associationSourceUrl);
                            if (await canLaunchUrl(uri)) {
                              await launchUrl(uri, mode: LaunchMode.externalApplication);
                            }
                          },
                          icon: const Icon(LucideIcons.externalLink, size: 12),
                          label: const Text('View Source →'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2563EB),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            textStyle: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
