import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../models/trust_engine_models.dart';

class TrustEngineConsistencyMatrix extends StatelessWidget {
  final List<ConsistencyRow> consistencyRows;

  const TrustEngineConsistencyMatrix({super.key, required this.consistencyRows});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(color: Color(0x04000000), blurRadius: 10, offset: Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(LucideIcons.gitCompare, size: 16, color: Color(0xFF10B981)),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Cross-Document Consistency Matrix',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),
              if (consistencyRows.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDCFCE7),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(LucideIcons.checkCheck, size: 12, color: Color(0xFF15803D)),
                      const SizedBox(width: 4),
                      Text(
                        'Validated',
                        style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFF15803D)),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Multi-way comparison across submitted deed records, revenue maps, and property tax slips.',
            style: GoogleFonts.inter(fontSize: 12.5, color: const Color(0xFF64748B)),
          ),
          const SizedBox(height: 18),

          if (consistencyRows.isEmpty) ...[
            Container(
              padding: const EdgeInsets.symmetric(vertical: 32),
              alignment: Alignment.center,
              child: Column(
                children: [
                  Icon(LucideIcons.gitPullRequest, size: 32, color: Colors.grey.shade400),
                  const SizedBox(height: 10),
                  Text(
                    'No cross-document comparison available yet',
                    style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF475569)),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Consistency check triggers automatically upon uploading at least 2 case documents.',
                    style: GoogleFonts.inter(fontSize: 11.5, color: const Color(0xFF94A3B8)),
                  ),
                ],
              ),
            ),
          ] else ...[
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: ConstrainedBox(
                constraints: const BoxConstraints(minWidth: 720),
                child: DataTable(
                  headingRowColor: WidgetStateProperty.all(const Color(0xFFF8FAFC)),
                  dataRowMinHeight: 48,
                  dataRowMaxHeight: 56,
                  horizontalMargin: 16,
                  columnSpacing: 24,
                  columns: [
                    DataColumn(
                      label: Text('Attribute', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: const Color(0xFF334155))),
                    ),
                    DataColumn(
                      label: Text('Document A (Sale Deed)', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: const Color(0xFF334155))),
                    ),
                    DataColumn(
                      label: Text('Document B (Mutation)', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: const Color(0xFF334155))),
                    ),
                    DataColumn(
                      label: Text('Match Status', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: const Color(0xFF334155))),
                    ),
                    DataColumn(
                      label: Text('Difference Analysis', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: const Color(0xFF334155))),
                    ),
                  ],
                  rows: consistencyRows.map((row) {
                    return DataRow(
                      cells: [
                        DataCell(
                          Text(row.attributeName, style: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.w600, color: const Color(0xFF0F172A))),
                        ),
                        DataCell(
                          Text(row.documentAValue, style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF334155))),
                        ),
                        DataCell(
                          Text(row.documentBValue, style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF334155))),
                        ),
                        DataCell(
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: row.matchStatus.backgroundColor,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: row.matchStatus.color.withOpacity(0.3)),
                            ),
                            child: Text(
                              row.matchStatus.label,
                              style: GoogleFonts.inter(
                                fontSize: 10.5,
                                fontWeight: FontWeight.bold,
                                color: row.matchStatus.color,
                              ),
                            ),
                          ),
                        ),
                        DataCell(
                          Text(
                            row.differenceNotes,
                            style: GoogleFonts.inter(fontSize: 11.5, color: const Color(0xFF64748B)),
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
