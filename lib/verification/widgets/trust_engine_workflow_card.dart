import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';

class TrustEngineWorkflowCard extends StatelessWidget {
  final int activeStep; // 1 to 8
  final double overallProgress; // 0.0 to 1.0
  final bool isRunning;

  const TrustEngineWorkflowCard({
    super.key,
    required this.activeStep,
    required this.overallProgress,
    required this.isRunning,
  });

  static const List<_StepDef> _steps = [
    _StepDef(1, 'Document Upload', 'Secure hashing & ingestion', LucideIcons.uploadCloud),
    _StepDef(2, 'OCR & Data Extraction', 'Multi-layer text & tabular capture', LucideIcons.fileSearch),
    _StepDef(3, 'Document Structure Analysis', 'Watermark & seal verification', LucideIcons.layers),
    _StepDef(4, 'Entity Matching', 'Buyer, seller & revenue registry lookup', LucideIcons.userCheck),
    _StepDef(5, 'Cross-Document Consistency', 'Cross-deed discrepancy matrix', LucideIcons.gitCompare),
    _StepDef(6, 'Authorized Source Verification', 'State revenue & RERA check', LucideIcons.landmark),
    _StepDef(7, 'Risk Analysis', '8-vector legal risk scoring', LucideIcons.shieldAlert),
    _StepDef(8, 'AI Report Generation', 'Summary & certificate compilation', LucideIcons.fileCheck),
  ];

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
                      color: const Color(0xFF7C3AED).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(LucideIcons.activity, size: 16, color: Color(0xFF7C3AED)),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'AI Verification Workflow Pipeline',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  if (isRunning) ...[
                    const SizedBox(
                      width: 12,
                      height: 12,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF7C3AED)),
                    ),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    isRunning ? 'Step $activeStep of 8 In Progress' : (activeStep >= 8 ? 'Verification Complete' : 'Ready to Run'),
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: isRunning
                          ? const Color(0xFF7C3AED)
                          : (activeStep >= 8 ? const Color(0xFF10B981) : const Color(0xFF64748B)),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Overall Progress Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: overallProgress.clamp(0.0, 1.0),
              backgroundColor: const Color(0xFFF1F5F9),
              valueColor: AlwaysStoppedAnimation<Color>(
                activeStep >= 8 ? const Color(0xFF10B981) : const Color(0xFF7C3AED),
              ),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 18),

          // Steps Timeline Grid
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 720;

              if (isWide) {
                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 14,
                    mainAxisSpacing: 10,
                    mainAxisExtent: 68,
                  ),
                  itemCount: _steps.length,
                  itemBuilder: (context, index) {
                    return _buildStepTile(_steps[index]);
                  },
                );
              }

              return Column(
                children: _steps.map((s) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _buildStepTile(s),
                )).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStepTile(_StepDef step) {
    final isCompleted = step.number < activeStep || (step.number == 8 && activeStep >= 8 && !isRunning);
    final isCurrent = step.number == activeStep && isRunning;

    Color iconBg;
    Color iconColor;
    String statusText;

    if (isCompleted) {
      iconBg = const Color(0xFFDCFCE7);
      iconColor = const Color(0xFF15803D);
      statusText = 'Completed';
    } else if (isCurrent) {
      iconBg = const Color(0xFFEDE9FE);
      iconColor = const Color(0xFF7C3AED);
      statusText = 'Processing...';
    } else {
      iconBg = const Color(0xFFF1F5F9);
      iconColor = const Color(0xFF94A3B8);
      statusText = 'Pending';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isCurrent ? const Color(0xFFFAF5FF) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isCurrent ? const Color(0xFFC084FC) : const Color(0xFFE2E8F0),
          width: isCurrent ? 1.5 : 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: iconBg,
              shape: BoxShape.circle,
            ),
            child: Icon(
              isCompleted ? LucideIcons.check : step.icon,
              size: 14,
              color: iconColor,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '${step.number}. ${step.title}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF0F172A),
                  ),
                ),
                Text(
                  step.subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 10.5,
                    color: const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          Text(
            statusText,
            style: GoogleFonts.inter(
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
              color: iconColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _StepDef {
  final int number;
  final String title;
  final String subtitle;
  final IconData icon;

  const _StepDef(this.number, this.title, this.subtitle, this.icon);
}
