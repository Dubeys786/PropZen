import 'package:flutter/material.dart';

/// Categories for PropZen Global Search items
enum GlobalSearchCategory {
  page,
  service,
  feature,
  property,
  account,
  financial,
  verification,
}

extension GlobalSearchCategoryExtension on GlobalSearchCategory {
  String get displayName {
    switch (this) {
      case GlobalSearchCategory.page:
        return 'PAGE';
      case GlobalSearchCategory.service:
        return 'SERVICE';
      case GlobalSearchCategory.feature:
        return 'FEATURE';
      case GlobalSearchCategory.property:
        return 'PROPERTY';
      case GlobalSearchCategory.account:
        return 'ACCOUNT';
      case GlobalSearchCategory.financial:
        return 'FINANCIAL';
      case GlobalSearchCategory.verification:
        return 'VERIFICATION';
    }
  }

  Color get defaultColor {
    switch (this) {
      case GlobalSearchCategory.page:
        return const Color(0xFF6366F1); // Indigo
      case GlobalSearchCategory.service:
        return const Color(0xFF7C3AED); // PropZen Violet
      case GlobalSearchCategory.feature:
        return const Color(0xFF0EA5E9); // Sky
      case GlobalSearchCategory.property:
        return const Color(0xFF10B981); // Emerald
      case GlobalSearchCategory.account:
        return const Color(0xFF64748B); // Slate
      case GlobalSearchCategory.financial:
        return const Color(0xFFF59E0B); // Amber
      case GlobalSearchCategory.verification:
        return const Color(0xFF059669); // Teal
    }
  }
}

/// Represents a searchable destination, tool, service, or feature in PropZen
class GlobalSearchItem {
  final String id;
  final String title;
  final String description;
  final GlobalSearchCategory category;
  final List<String> keywords;
  final IconData icon;
  final Color? accentColor;
  final String? badgeText;
  final String? route;
  final int? tabIndex;
  final void Function(BuildContext context)? onNavigate;

  const GlobalSearchItem({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.keywords,
    required this.icon,
    this.accentColor,
    this.badgeText,
    this.route,
    this.tabIndex,
    this.onNavigate,
  });

  Color get effectiveColor => accentColor ?? category.defaultColor;

  /// Trigger navigation for this item
  void navigate(BuildContext context, {void Function(int tabIndex)? onSwitchTab}) {
    if (onNavigate != null) {
      onNavigate!(context);
      return;
    }

    if (tabIndex != null && onSwitchTab != null) {
      onSwitchTab(tabIndex!);
      return;
    }

    if (route != null && route!.isNotEmpty) {
      Navigator.of(context).pushNamed(route!);
    }
  }
}
