import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../models/trust_engine_models.dart';
import 'trust_engine_report_modal.dart';

class TrustEngineHistoryDialog extends StatefulWidget {
  final List<VerificationCase> history;
  final ValueChanged<VerificationCase> onSelectCase;

  const TrustEngineHistoryDialog({
    super.key,
    required this.history,
    required this.onSelectCase,
  });

  static Future<void> show(
    BuildContext context, {
    required List<VerificationCase> history,
    required ValueChanged<VerificationCase> onSelectCase,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: TrustEngineHistoryDialog(
          history: history,
          onSelectCase: onSelectCase,
        ),
      ),
    );
  }

  @override
  State<TrustEngineHistoryDialog> createState() => _TrustEngineHistoryDialogState();
}

class _TrustEngineHistoryDialogState extends State<TrustEngineHistoryDialog> {
  String _searchQuery = '';
  VerificationStatus? _selectedStatusFilter;

  @override
  Widget build(BuildContext context) {
    final filtered = widget.history.where((c) {
      if (_selectedStatusFilter != null && c.status != _selectedStatusFilter) {
        return false;
      }
      if (_searchQuery.trim().isNotEmpty) {
        final q = _searchQuery.toLowerCase().trim();
        final matchesId = c.id.toLowerCase().contains(q);
        final matchesProp = c.propertyTitle.toLowerCase().contains(q);
        final matchesOwner = c.ownerName.toLowerCase().contains(q);
        final matchesLoc = c.location.toLowerCase().contains(q);
        return matchesId || matchesProp || matchesOwner || matchesLoc;
      }
      return true;
    }).toList();

    return Container(
      width: 1000,
      height: 680,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: Color(0x24000000), blurRadius: 28, offset: Offset(0, 10)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              color: Colors.white,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF7C3AED).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(LucideIcons.history, size: 18, color: Color(0xFF7C3AED)),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Verification Case History',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF0F172A),
                            ),
                          ),
                          Text(
                            'Search and audit historical verification cases, certificates and evidence.',
                            style: GoogleFonts.inter(fontSize: 11.5, color: const Color(0xFF64748B)),
                          ),
                        ],
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(LucideIcons.x, size: 18),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: Color(0xFFE2E8F0)),

            // Search and Filters Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              color: const Color(0xFFF8FAFC),
              child: Row(
                children: [
                  // Search Box
                  Expanded(
                    child: Container(
                      height: 38,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFCBD5E1)),
                      ),
                      child: TextField(
                        onChanged: (val) => setState(() => _searchQuery = val),
                        style: GoogleFonts.inter(fontSize: 12.5),
                        decoration: InputDecoration(
                          hintText: 'Search verification by ID, property, or owner name...',
                          hintStyle: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF94A3B8)),
                          prefixIcon: const Icon(LucideIcons.search, size: 15, color: Color(0xFF64748B)),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(vertical: 8),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),

                  // Status Filter Dropdown
                  Container(
                    height: 38,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFCBD5E1)),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<VerificationStatus?>(
                        value: _selectedStatusFilter,
                        hint: Text('All Statuses', style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF475569))),
                        items: [
                          const DropdownMenuItem(value: null, child: Text('All Statuses')),
                          ...VerificationStatus.values.map((s) => DropdownMenuItem(
                            value: s,
                            child: Text(s.label),
                          )),
                        ],
                        onChanged: (val) => setState(() => _selectedStatusFilter = val),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: Color(0xFFE2E8F0)),

            // History Table
            Expanded(
              child: filtered.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(LucideIcons.inbox, size: 36, color: Colors.grey.shade400),
                          const SizedBox(height: 10),
                          Text(
                            'No verification cases yet.',
                            style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF475569)),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Completed or in-progress verification records will appear here.',
                            style: GoogleFonts.inter(fontSize: 11.5, color: const Color(0xFF94A3B8)),
                          ),
                        ],
                      ),
                    )
                  : SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: SingleChildScrollView(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(minWidth: 920),
                          child: DataTable(
                            headingRowColor: WidgetStateProperty.all(const Color(0xFFF8FAFC)),
                            dataRowMinHeight: 52,
                            dataRowMaxHeight: 58,
                            horizontalMargin: 20,
                            columnSpacing: 20,
                            columns: [
                              DataColumn(label: Text('Verification ID', style: GoogleFonts.inter(fontSize: 11.5, fontWeight: FontWeight.bold))),
                              DataColumn(label: Text('Property', style: GoogleFonts.inter(fontSize: 11.5, fontWeight: FontWeight.bold))),
                              DataColumn(label: Text('Owner', style: GoogleFonts.inter(fontSize: 11.5, fontWeight: FontWeight.bold))),
                              DataColumn(label: Text('Created', style: GoogleFonts.inter(fontSize: 11.5, fontWeight: FontWeight.bold))),
                              DataColumn(label: Text('Status', style: GoogleFonts.inter(fontSize: 11.5, fontWeight: FontWeight.bold))),
                              DataColumn(label: Text('Risk', style: GoogleFonts.inter(fontSize: 11.5, fontWeight: FontWeight.bold))),
                              DataColumn(label: Text('Documents', style: GoogleFonts.inter(fontSize: 11.5, fontWeight: FontWeight.bold))),
                              DataColumn(label: Text('Action', style: GoogleFonts.inter(fontSize: 11.5, fontWeight: FontWeight.bold))),
                            ],
                            rows: filtered.map((c) {
                              return DataRow(
                                cells: [
                                  DataCell(
                                    Text(c.id, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: const Color(0xFF7C3AED))),
                                  ),
                                  DataCell(
                                    Text(c.propertyTitle, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF0F172A))),
                                  ),
                                  DataCell(
                                    Text(c.ownerName, style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF334155))),
                                  ),
                                  DataCell(
                                    Text('${c.lastUpdated.day}/${c.lastUpdated.month}/${c.lastUpdated.year}', style: GoogleFonts.inter(fontSize: 11.5, color: const Color(0xFF64748B))),
                                  ),
                                  DataCell(
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: c.status.backgroundColor,
                                        borderRadius: BorderRadius.circular(4),
                                        border: Border.all(color: c.status.color.withOpacity(0.3)),
                                      ),
                                      child: Text(
                                        c.status.label,
                                        style: GoogleFonts.inter(fontSize: 10.5, fontWeight: FontWeight.bold, color: c.status.color),
                                      ),
                                    ),
                                  ),
                                  DataCell(
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: c.overallRiskLevel.backgroundColor,
                                        borderRadius: BorderRadius.circular(4),
                                        border: Border.all(color: c.overallRiskLevel.color.withOpacity(0.3)),
                                      ),
                                      child: Text(
                                        c.overallRiskLevel.label,
                                        style: GoogleFonts.inter(fontSize: 10.5, fontWeight: FontWeight.bold, color: c.overallRiskLevel.color),
                                      ),
                                    ),
                                  ),
                                  DataCell(
                                    Text('${c.documents.length} docs', style: GoogleFonts.inter(fontSize: 11.5, color: const Color(0xFF64748B))),
                                  ),
                                  DataCell(
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        TextButton(
                                          onPressed: () {
                                            Navigator.of(context).pop();
                                            widget.onSelectCase(c);
                                          },
                                          child: const Text('View / Continue'),
                                        ),
                                        IconButton(
                                          icon: const Icon(LucideIcons.fileText, size: 14, color: Color(0xFF7C3AED)),
                                          tooltip: 'View Report',
                                          onPressed: () {
                                            TrustEngineReportModal.show(context, c);
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
