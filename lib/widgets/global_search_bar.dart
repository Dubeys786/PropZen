import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../models/global_search_item.dart';
import '../services/global_search_service.dart';

/// Interactive Global Search Bar for PropZen Top Navigation
class GlobalSearchBar extends StatefulWidget {
  final void Function(int tabIndex)? onNavigateTab;
  final double? width;
  final bool isCompact;

  const GlobalSearchBar({
    super.key,
    this.onNavigateTab,
    this.width,
    this.isCompact = false,
  });

  /// Opens full-screen or bottom-sheet Global Search Modal (for Mobile)
  static Future<void> showSearchModal(
    BuildContext context, {
    void Function(int tabIndex)? onNavigateTab,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _GlobalSearchModalSheet(onNavigateTab: onNavigateTab),
    );
  }

  @override
  State<GlobalSearchBar> createState() => GlobalSearchBarState();
}

class GlobalSearchBarState extends State<GlobalSearchBar> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final LayerLink _layerLink = LayerLink();

  OverlayEntry? _overlayEntry;
  int _selectedIndex = -1;
  List<GlobalSearchItem> _currentResults = [];

  bool get _isApplePlatform {
    if (kIsWeb) return false;
    try {
      return Platform.isMacOS || Platform.isIOS;
    } catch (_) {
      return false;
    }
  }

  String get _shortcutLabel => _isApplePlatform ? '⌘K' : 'Ctrl K';

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onQueryChanged);
    _focusNode.addListener(_onFocusChanged);
  }

  @override
  void dispose() {
    _removeOverlay();
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void focusSearch() {
    _focusNode.requestFocus();
    _showOverlay();
  }

  void clearSearch() {
    _controller.clear();
    _selectedIndex = -1;
  }

  void _onFocusChanged() {
    if (_focusNode.hasFocus) {
      _showOverlay();
    } else {
      // Delay removal slightly so taps on dropdown items can register smoothly
      Future.delayed(const Duration(milliseconds: 220), () {
        if (mounted && !_focusNode.hasFocus) {
          _removeOverlay();
        }
      });
    }
  }

  void _onQueryChanged() {
    final query = _controller.text;
    final results = GlobalSearchService.instance.search(query);
    setState(() {
      _currentResults = results;
      _selectedIndex = results.isNotEmpty ? 0 : -1;
    });
    _overlayEntry?.markNeedsBuild();
  }

  void _showOverlay() {
    if (_overlayEntry != null) return;

    final overlay = Overlay.of(context);
    _overlayEntry = OverlayEntry(
      builder: (context) => _buildOverlayContent(),
    );
    overlay.insert(_overlayEntry!);
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  void _handleSelect(GlobalSearchItem item) {
    GlobalSearchService.instance.addRecentSearch(item.title);
    _removeOverlay();
    _focusNode.unfocus();
    _controller.clear();

    item.navigate(context, onSwitchTab: widget.onNavigateTab);
  }

  void _handleKey(KeyEvent event) {
    if (event is! KeyDownEvent) return;

    if (event.logicalKey == LogicalKeyboardKey.escape) {
      _removeOverlay();
      _focusNode.unfocus();
      return;
    }

    if (_currentResults.isEmpty) return;

    if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
      setState(() {
        _selectedIndex = (_selectedIndex + 1).clamp(0, _currentResults.length - 1);
      });
      _overlayEntry?.markNeedsBuild();
    } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
      setState(() {
        _selectedIndex = (_selectedIndex - 1).clamp(0, _currentResults.length - 1);
      });
      _overlayEntry?.markNeedsBuild();
    } else if (event.logicalKey == LogicalKeyboardKey.enter) {
      if (_selectedIndex >= 0 && _selectedIndex < _currentResults.length) {
        _handleSelect(_currentResults[_selectedIndex]);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final barWidth = widget.width ?? (widget.isCompact ? 210.0 : 310.0);

    return CompositedTransformTarget(
      link: _layerLink,
      child: KeyboardListener(
        focusNode: FocusNode(skipTraversal: true),
        onKeyEvent: _handleKey,
        child: Container(
          width: barWidth,
          height: 42,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(13),
            border: Border.all(
              color: _focusNode.hasFocus ? const Color(0xFF7C3AED) : const Color(0xFFE2E8F0),
              width: _focusNode.hasFocus ? 1.5 : 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: _focusNode.hasFocus
                    ? const Color(0xFF7C3AED).withOpacity(0.14)
                    : const Color(0x0A0F172A),
                blurRadius: _focusNode.hasFocus ? 10 : 3,
                offset: const Offset(0, 1.5),
              ),
            ],
          ),
          child: TextField(
            controller: _controller,
            focusNode: _focusNode,
            style: GoogleFonts.inter(
              fontSize: 12.5,
              color: const Color(0xFF0F172A),
              fontWeight: FontWeight.w500,
            ),
            decoration: InputDecoration(
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 11),
              border: InputBorder.none,
              hintText: 'Search PropZen...',
              hintStyle: GoogleFonts.inter(
                fontSize: 12.5,
                color: const Color(0xFF94A3B8),
                fontWeight: FontWeight.w400,
              ),
              prefixIcon: const Padding(
                padding: EdgeInsets.only(left: 11, right: 8),
                child: Icon(LucideIcons.search, size: 16, color: Color(0xFF7C3AED)),
              ),
              prefixIconConstraints: const BoxConstraints(minWidth: 35, minHeight: 16),
              suffixIcon: _controller.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(LucideIcons.x, size: 14, color: Color(0xFF94A3B8)),
                      tooltip: 'Clear',
                      splashRadius: 14,
                      padding: EdgeInsets.zero,
                      onPressed: clearSearch,
                    )
                  : Padding(
                      padding: const EdgeInsets.only(right: 9),
                      child: Center(
                        widthFactor: 1.0,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(5),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: Text(
                            _shortcutLabel,
                            style: GoogleFonts.jetBrainsMono(
                              fontSize: 9.5,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF64748B),
                            ),
                          ),
                        ),
                      ),
                    ),
              suffixIconConstraints: const BoxConstraints(minWidth: 42, minHeight: 20),
            ),
          ),
        ),
      ),
    );
  }

  // =========================================================================
  // PREMIUM MEGA-DROPDOWN OVERLAY (FLOATING ABOVE PAGE, DOES NOT PUSH HERO)
  // =========================================================================

  Widget _buildOverlayContent() {
    final screenWidth = MediaQuery.of(context).size.width;

    // Responsive width: ~900–1180px, clamped to screen width
    final overlayWidth = (screenWidth * 0.78).clamp(900.0, 1180.0);

    // Position overlay directly beneath search bar, centered and clamped inside viewport
    final RenderBox? searchBarBox = context.findRenderObject() as RenderBox?;
    final searchBarGlobalPos = searchBarBox?.localToGlobal(Offset.zero) ?? Offset.zero;
    final searchBarWidth = searchBarBox?.size.width ?? 310;

    double idealLeft = searchBarGlobalPos.dx + (searchBarWidth / 2) - (overlayWidth / 2);
    idealLeft = idealLeft.clamp(16.0, screenWidth - overlayWidth - 16.0);

    final topOffset = searchBarGlobalPos.dy + (searchBarBox?.size.height ?? 42) + 8;

    return Stack(
      children: [
        // Full transparent backdrop to capture outside clicks and dismiss overlay
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: () {
              _removeOverlay();
              _focusNode.unfocus();
            },
          ),
        ),
        Positioned(
          left: idealLeft,
          top: topOffset,
          child: Material(
            elevation: 20,
            shadowColor: const Color(0x350F172A),
            borderRadius: BorderRadius.circular(20),
            color: Colors.white,
            child: Container(
              width: overlayWidth,
              constraints: const BoxConstraints(maxHeight: 570),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE2E8F0), width: 1.0),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: AnimatedBuilder(
                  animation: GlobalSearchService.instance,
                  builder: (context, _) {
                    final query = _controller.text.trim();
                    if (query.isNotEmpty) {
                      return _buildSearchResultsView(query);
                    }
                    return _buildMegaDropdownView();
                  },
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // =========================================================================
  // SEARCH RESULTS VIEW (when user types a query)
  // =========================================================================

  Widget _buildSearchResultsView(String query) {
    if (_currentResults.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: const BoxDecoration(
                color: Color(0xFFF3E8FF),
                shape: BoxShape.circle,
              ),
              child: const Icon(LucideIcons.searchX, size: 30, color: Color(0xFF7C3AED)),
            ),
            const SizedBox(height: 16),
            Text(
              'No results found for "$query"',
              style: GoogleFonts.poppins(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF0F172A),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              'Try searching for properties, loans, services, dealers or features.',
              style: GoogleFonts.inter(fontSize: 12.5, color: const Color(0xFF64748B)),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                _buildSearchSuggestionChip('Home Loan'),
                _buildSearchSuggestionChip('AI Match'),
                _buildSearchSuggestionChip('Properties'),
                _buildSearchSuggestionChip('Vastu Consultation'),
                _buildSearchSuggestionChip('Compare Properties'),
                _buildSearchSuggestionChip('Dealers Directory'),
              ],
            ),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 10),
      shrinkWrap: true,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'RESULTS (${_currentResults.length})',
                style: GoogleFonts.inter(
                  fontSize: 10.5,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF94A3B8),
                  letterSpacing: 0.9,
                ),
              ),
              Text(
                'Press Enter to open · Use ↑↓ to navigate',
                style: GoogleFonts.inter(fontSize: 10.5, color: const Color(0xFF94A3B8)),
              ),
            ],
          ),
        ),
        const Divider(height: 1, color: Color(0xFFF1F5F9)),
        for (int i = 0; i < _currentResults.length; i++)
          _buildResultTile(_currentResults[i], isSelected: i == _selectedIndex),
      ],
    );
  }

  // =========================================================================
  // PREMIUM MEGA-DROPDOWN VIEW (empty query — 4-column layout)
  // =========================================================================

  Widget _buildMegaDropdownView() {
    final searchService = GlobalSearchService.instance;
    final recent = searchService.recentSearches;
    final popular = searchService.popularSearchItems;
    final quick = searchService.quickAccessItems;
    final services = searchService.serviceItems;
    final discover = searchService.discoverItems;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // ─── 4 COLUMNS ─────────────────────────────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // SECTION 1: POPULAR SEARCHES
              Expanded(
                child: _buildMegaColumn(
                  title: 'POPULAR SEARCHES',
                  items: popular,
                ),
              ),
              const SizedBox(width: 18),

              // SECTION 2: QUICK ACCESS
              Expanded(
                child: _buildMegaColumn(
                  title: 'QUICK ACCESS',
                  items: quick,
                ),
              ),
              const SizedBox(width: 18),

              // SECTION 3: SERVICES
              Expanded(
                child: _buildMegaColumn(
                  title: 'SERVICES',
                  items: services,
                ),
              ),
              const SizedBox(width: 18),

              // SECTION 4: DISCOVER
              Expanded(
                child: _buildMegaColumn(
                  title: 'DISCOVER',
                  items: discover,
                ),
              ),
            ],
          ),

          // ─── RECENT SEARCHES ───────────────────────────────
          if (recent.isNotEmpty) ...[
            const Padding(
              padding: EdgeInsets.only(top: 16, bottom: 12),
              child: Divider(height: 1, color: Color(0xFFF1F5F9)),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'RECENT SEARCHES',
                  style: GoogleFonts.inter(
                    fontSize: 10.5,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF94A3B8),
                    letterSpacing: 0.9,
                  ),
                ),
                InkWell(
                  onTap: () {
                    searchService.clearRecentSearches();
                    _overlayEntry?.markNeedsBuild();
                  },
                  borderRadius: BorderRadius.circular(4),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    child: Text(
                      'Clear All',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF7C3AED),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: recent
                  .map(
                    (term) => InkWell(
                      onTap: () {
                        _controller.text = term;
                        _controller.selection = TextSelection.fromPosition(
                          TextPosition(offset: term.length),
                        );
                        _onQueryChanged();
                      },
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(LucideIcons.history, size: 12, color: Color(0xFF7C3AED)),
                            const SizedBox(width: 6),
                            Text(
                              term,
                              style: GoogleFonts.inter(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w500,
                                color: const Color(0xFF334155),
                              ),
                            ),
                            const SizedBox(width: 6),
                            InkWell(
                              onTap: () {
                                searchService.removeRecentSearch(term);
                                _overlayEntry?.markNeedsBuild();
                              },
                              borderRadius: BorderRadius.circular(10),
                              child: const Padding(
                                padding: EdgeInsets.all(2),
                                child: Icon(LucideIcons.x, size: 11, color: Color(0xFF94A3B8)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }

  // =========================================================================
  // MEGA-COLUMN BUILDER
  // =========================================================================

  Widget _buildMegaColumn({
    required String title,
    required List<GlobalSearchItem> items,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Section header
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF94A3B8),
              letterSpacing: 0.9,
            ),
          ),
        ),
        // Column Items
        for (final item in items) _buildMegaColumnItem(item),
      ],
    );
  }

  Widget _buildMegaColumnItem(GlobalSearchItem item) {
    return InkWell(
      onTap: () => _handleSelect(item),
      borderRadius: BorderRadius.circular(10),
      hoverColor: const Color(0xFFF5F3FF),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 5),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: item.effectiveColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(item.icon, size: 15, color: item.effectiveColor),
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
                          item.title,
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF0F172A),
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                      if (item.badgeText != null) ...[
                        const SizedBox(width: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                          decoration: BoxDecoration(
                            color: item.effectiveColor.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            item.badgeText!,
                            style: GoogleFonts.jetBrainsMono(
                              fontSize: 7.5,
                              fontWeight: FontWeight.bold,
                              color: item.effectiveColor,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  Text(
                    item.description,
                    style: GoogleFonts.inter(
                      fontSize: 10.5,
                      color: const Color(0xFF64748B),
                      height: 1.25,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =========================================================================
  // SHARED WIDGETS
  // =========================================================================

  Widget _buildResultTile(GlobalSearchItem item, {bool isSelected = false}) {
    return InkWell(
      onTap: () => _handleSelect(item),
      hoverColor: const Color(0xFFF5F3FF),
      child: Container(
        color: isSelected ? const Color(0xFFF5F3FF) : Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: item.effectiveColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(item.icon, size: 18, color: item.effectiveColor),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          item.title,
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF0F172A),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (item.badgeText != null) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                          decoration: BoxDecoration(
                            color: item.effectiveColor.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            item.badgeText!,
                            style: GoogleFonts.jetBrainsMono(
                              fontSize: 8.5,
                              fontWeight: FontWeight.bold,
                              color: item.effectiveColor,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item.description,
                    style: GoogleFonts.inter(
                      fontSize: 11.5,
                      color: const Color(0xFF64748B),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(5),
              ),
              child: Text(
                item.category.displayName,
                style: GoogleFonts.inter(
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF64748B),
                ),
              ),
            ),
            const SizedBox(width: 6),
            const Icon(LucideIcons.chevronRight, size: 14, color: Color(0xFFCBD5E1)),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchSuggestionChip(String text) {
    return ActionChip(
      label: Text(
        text,
        style: GoogleFonts.inter(
          fontSize: 11.5,
          fontWeight: FontWeight.w600,
          color: const Color(0xFF7C3AED),
        ),
      ),
      backgroundColor: const Color(0xFFFAF5FF),
      side: const BorderSide(color: Color(0xFFDDD6FE)),
      onPressed: () {
        _controller.text = text;
        _controller.selection = TextSelection.fromPosition(TextPosition(offset: text.length));
        _onQueryChanged();
      },
    );
  }
}

// =============================================================================
// MOBILE FULL-SCREEN SEARCH MODAL
// =============================================================================

/// Full modal search sheet for mobile devices
class _GlobalSearchModalSheet extends StatefulWidget {
  final void Function(int tabIndex)? onNavigateTab;

  const _GlobalSearchModalSheet({this.onNavigateTab});

  @override
  State<_GlobalSearchModalSheet> createState() => _GlobalSearchModalSheetState();
}

class _GlobalSearchModalSheetState extends State<_GlobalSearchModalSheet> {
  final TextEditingController _controller = TextEditingController();
  List<GlobalSearchItem> _results = [];
  bool _showAllPopularShortcuts = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      final q = _controller.text.trim();
      setState(() {
        _results = GlobalSearchService.instance.search(q);
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleSelect(GlobalSearchItem item) {
    GlobalSearchService.instance.addRecentSearch(item.title);
    Navigator.of(context).pop();
    item.navigate(context, onSwitchTab: widget.onNavigateTab);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.92,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Drag handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 10, bottom: 6),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFCBD5E1),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          // Search input bar: [ 🔍 Search PropZen... ] Cancel
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF7C3AED), width: 1.5),
                    ),
                    child: TextField(
                      controller: _controller,
                      autofocus: true,
                      style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF0F172A)),
                      decoration: InputDecoration(
                        isDense: true,
                        hintText: 'Search PropZen...',
                        hintStyle: GoogleFonts.inter(fontSize: 12.5, color: const Color(0xFF94A3B8)),
                        border: InputBorder.none,
                        prefixIcon: const Icon(LucideIcons.search, size: 18, color: Color(0xFF7C3AED)),
                        suffixIcon: _controller.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(LucideIcons.x, size: 16, color: Color(0xFF64748B)),
                                onPressed: () => _controller.clear(),
                              )
                            : null,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(
                    'Cancel',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFE2E8F0)),
          // Results or Suggestions list
          Expanded(
            child: AnimatedBuilder(
              animation: GlobalSearchService.instance,
              builder: (ctx, _) {
                final query = _controller.text.trim();
                if (query.isNotEmpty) {
                  if (_results.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(LucideIcons.searchX, size: 36, color: Color(0xFF7C3AED)),
                          const SizedBox(height: 12),
                          Text(
                            'No results found for "$query"',
                            style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Try searching for loans, vastu, interior, properties...',
                            style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B)),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    );
                  }
                  return ListView.builder(
                    itemCount: _results.length,
                    itemBuilder: (ctx, idx) => _buildModalTile(_results[idx]),
                  );
                }

                // Empty query: POPULAR SEARCHES grid + recent searches
                return _buildMobileEmptyQueryView();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileEmptyQueryView() {
    final searchService = GlobalSearchService.instance;

    // The primary 5 popular shortcuts requested in Section 10:
    // Properties, Dashboard, Home Loan, AI Match, Site Visits, More
    final primaryShortcuts = [
      const _MobileShortcutData(
        title: 'Properties',
        icon: LucideIcons.home,
        color: Color(0xFF7C3AED),
        itemId: 'popular_properties',
      ),
      const _MobileShortcutData(
        title: 'Dashboard',
        icon: LucideIcons.layoutDashboard,
        color: Color(0xFF2563EB),
        itemId: 'my_dashboard',
      ),
      const _MobileShortcutData(
        title: 'Home Loan',
        icon: LucideIcons.indianRupee,
        color: Color(0xFFF59E0B),
        itemId: 'home_loan',
      ),
      const _MobileShortcutData(
        title: 'AI Match',
        icon: LucideIcons.sparkles,
        color: Color(0xFF8B5CF6),
        itemId: 'ai_match',
      ),
      const _MobileShortcutData(
        title: 'Site Visits',
        icon: LucideIcons.calendarCheck,
        color: Color(0xFF10B981),
        itemId: 'site_visits',
      ),
      _MobileShortcutData(
        title: _showAllPopularShortcuts ? 'Less' : 'More',
        icon: _showAllPopularShortcuts ? LucideIcons.chevronUp : LucideIcons.moreHorizontal,
        color: const Color(0xFF64748B),
        isMoreToggle: true,
      ),
    ];

    const secondaryShortcuts = [
      _MobileShortcutData(
        title: 'Dealers',
        icon: LucideIcons.users,
        color: Color(0xFF0EA5E9),
        itemId: 'dealers_directory',
      ),
      _MobileShortcutData(
        title: 'Market Hub',
        icon: LucideIcons.trendingUp,
        color: Color(0xFF7C3AED),
        itemId: 'market_hub',
      ),
      _MobileShortcutData(
        title: 'Compare',
        icon: LucideIcons.columns,
        color: Color(0xFF6366F1),
        itemId: 'popular_compare',
      ),
    ];

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 12),
      children: [
        // Recent searches chips
        if (searchService.recentSearches.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'RECENT SEARCHES',
                  style: GoogleFonts.inter(
                    fontSize: 10.5,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF94A3B8),
                    letterSpacing: 0.8,
                  ),
                ),
                InkWell(
                  onTap: () => searchService.clearRecentSearches(),
                  child: Text(
                    'Clear All',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF7C3AED),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Wrap(
              spacing: 6,
              runSpacing: 6,
              children: searchService.recentSearches
                  .map(
                    (term) => Chip(
                      label: Text(term, style: GoogleFonts.inter(fontSize: 11.5)),
                      backgroundColor: const Color(0xFFF1F5F9),
                      onDeleted: () => searchService.removeRecentSearch(term),
                      deleteIcon: const Icon(LucideIcons.x, size: 12),
                      visualDensity: VisualDensity.compact,
                      side: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                  )
                  .toList(),
            ),
          ),
          const Divider(height: 20, color: Color(0xFFF1F5F9)),
        ],

        // POPULAR SEARCHES (Section 10 icon shortcuts)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: Text(
            'POPULAR SEARCHES',
            style: GoogleFonts.inter(
              fontSize: 10.5,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF94A3B8),
              letterSpacing: 0.8,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              childAspectRatio: 1.15,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
            ),
            itemCount: primaryShortcuts.length + (_showAllPopularShortcuts ? secondaryShortcuts.length : 0),
            itemBuilder: (ctx, idx) {
              final shortcut = idx < primaryShortcuts.length
                  ? primaryShortcuts[idx]
                  : secondaryShortcuts[idx - primaryShortcuts.length];

              return InkWell(
                onTap: () {
                  if (shortcut.isMoreToggle) {
                    setState(() {
                      _showAllPopularShortcuts = !_showAllPopularShortcuts;
                    });
                    return;
                  }
                  if (shortcut.itemId != null) {
                    final match = searchService.allItems.firstWhere(
                      (i) => i.id == shortcut.itemId,
                      orElse: () => searchService.allItems.first,
                    );
                    _handleSelect(match);
                  }
                },
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: shortcut.color.withOpacity(0.12),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(shortcut.icon, size: 20, color: shortcut.color),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        shortcut.title,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF1E293B),
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),

        const Divider(height: 24, color: Color(0xFFF1F5F9)),

        // SERVICES & TOOLS
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: Text(
            'SERVICES & TOOLS',
            style: GoogleFonts.inter(
              fontSize: 10.5,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF94A3B8),
              letterSpacing: 0.8,
            ),
          ),
        ),
        for (final item in searchService.serviceItems) _buildModalTile(item),

        const Divider(height: 24, color: Color(0xFFF1F5F9)),

        // DISCOVER
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: Text(
            'DISCOVER',
            style: GoogleFonts.inter(
              fontSize: 10.5,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF94A3B8),
              letterSpacing: 0.8,
            ),
          ),
        ),
        for (final item in searchService.discoverItems) _buildModalTile(item),
      ],
    );
  }

  Widget _buildModalTile(GlobalSearchItem item) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: item.effectiveColor.withOpacity(0.12),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(item.icon, size: 18, color: item.effectiveColor),
      ),
      title: Text(
        item.title,
        style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        item.description,
        style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF64748B)),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          item.category.displayName,
          style: GoogleFonts.inter(
            fontSize: 8.5,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF64748B),
          ),
        ),
      ),
      onTap: () => _handleSelect(item),
    );
  }
}

class _MobileShortcutData {
  final String title;
  final IconData icon;
  final Color color;
  final String? itemId;
  final bool isMoreToggle;

  const _MobileShortcutData({
    required this.title,
    required this.icon,
    required this.color,
    this.itemId,
    this.isMoreToggle = false,
  });
}
