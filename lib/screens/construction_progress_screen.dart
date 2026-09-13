import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../models/construction_model.dart';
import '../models/property.dart';
import '../services/construction_service.dart';
import '../theme/app_theme.dart';

class ConstructionProgressScreen extends StatefulWidget {
  final Property property;

  const ConstructionProgressScreen({super.key, required this.property});

  @override
  State<ConstructionProgressScreen> createState() => _ConstructionProgressScreenState();
}

class _ConstructionProgressScreenState extends State<ConstructionProgressScreen> {
  final ConstructionService _constructionService = ConstructionService.instance;

  void _openUploadDialog(ConstructionProjectModel project) {
    ConstructionPhase phase = project.currentPhase;
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final progressCtrl = TextEditingController(text: project.overallProgress.toStringAsFixed(0));

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.cardWhite,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.only(left: 20, right: 20, top: 20, bottom: MediaQuery.of(ctx).viewInsets.bottom + 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Upload Site Engineer Update', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                  IconButton(icon: const Icon(LucideIcons.x, size: 20), onPressed: () => Navigator.pop(ctx)),
                ],
              ),
              Text('Project: ${project.projectName}', style: GoogleFonts.inter(fontSize: 12, color: AppTheme.primaryViolet, fontWeight: FontWeight.w600)),
              const SizedBox(height: 12),
              DropdownButtonFormField<ConstructionPhase>(
                value: phase,
                decoration: InputDecoration(
                  labelText: 'Construction Phase',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
                items: ConstructionPhase.values
                    .map((p) => DropdownMenuItem(value: p, child: Text(p.displayName, style: const TextStyle(fontSize: 12))))
                    .toList(),
                onChanged: (v) {
                  if (v != null) setModalState(() => phase = v);
                },
              ),
              const SizedBox(height: 10),
              TextField(
                controller: titleCtrl,
                decoration: InputDecoration(
                  labelText: 'Milestone Title',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: descCtrl,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Technical Description & Audit Notes',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: progressCtrl,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Progress %',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryViolet,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(46),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                icon: const Icon(LucideIcons.uploadCloud, size: 16),
                label: const Text('Submit Progress Update for Review', style: TextStyle(fontWeight: FontWeight.bold)),
                onPressed: () {
                  if (titleCtrl.text.trim().isEmpty) return;
                  final pVal = double.tryParse(progressCtrl.text.trim()) ?? project.overallProgress;
                  _constructionService.submitEngineerUpdate(
                    projectId: project.projectId,
                    phase: phase,
                    title: titleCtrl.text.trim(),
                    description: descCtrl.text.trim(),
                    progress: pVal,
                    photos: ['https://images.unsplash.com/photo-1541888946425-d0fbb18f15f6?w=600'],
                    engineerName: 'Er. Verified Site Engineer',
                  );
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Construction update recorded and published to buyers!')),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _constructionService,
      builder: (context, _) {
        final project = _constructionService.getProjectForProperty(widget.property);

        return Scaffold(
          backgroundColor: AppTheme.pageBackground,
          appBar: AppBar(
            backgroundColor: AppTheme.cardWhite,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(LucideIcons.arrowLeft, color: AppTheme.textPrimary),
              onPressed: () => Navigator.of(context).pop(),
            ),
            title: Text(
              'Real-Time Construction Progress',
              style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
            ),
            actions: [
              IconButton(
                icon: const Icon(LucideIcons.camera, color: AppTheme.primaryViolet),
                tooltip: 'Engineer Photo Upload',
                onPressed: () => _openUploadDialog(project),
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Overall Progress Hero Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppTheme.cardWhite,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.borderLight),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(project.projectName, style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                                Text('By ${project.builderName} • Verified Audit', style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textSecondary)),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppTheme.emeraldSuccess.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${project.overallProgress.toStringAsFixed(1)}% Completed',
                              style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.emeraldSuccess),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Progress Bar
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: project.overallProgress / 100.0,
                          backgroundColor: AppTheme.surfaceSubtle,
                          valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.emeraldSuccess),
                          minHeight: 10,
                        ),
                      ),
                      const SizedBox(height: 14),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildMetaChip('Current Phase', project.currentPhase.displayName.split('. ')[1]),
                          _buildMetaChip('Expected Delivery', '${project.expectedCompletionDate.month}/${project.expectedCompletionDate.year}'),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text('Next Milestone: ${project.nextMilestone}', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.primaryViolet)),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // 2. Timeline of 13 Phases
                Text('Phase-Wise Construction Roadmap (13 Phases)', style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                const SizedBox(height: 10),

                ...ConstructionPhase.values.map((ph) {
                  final isCompleted = ph.index < project.currentPhase.index;
                  final isCurrent = ph.index == project.currentPhase.index;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: isCurrent ? AppTheme.primaryViolet.withOpacity(0.04) : AppTheme.cardWhite,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: isCurrent ? AppTheme.primaryViolet.withOpacity(0.3) : AppTheme.borderLight),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isCompleted ? LucideIcons.checkCircle2 : (isCurrent ? LucideIcons.loader : LucideIcons.circle),
                          size: 16,
                          color: isCompleted ? AppTheme.emeraldSuccess : (isCurrent ? AppTheme.primaryViolet : AppTheme.textMuted),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            ph.displayName,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: isCurrent ? FontWeight.bold : FontWeight.w500,
                              color: isCurrent ? AppTheme.primaryViolet : AppTheme.textPrimary,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: isCompleted ? AppTheme.emeraldSuccess.withOpacity(0.1) : (isCurrent ? AppTheme.primaryViolet.withOpacity(0.1) : AppTheme.surfaceSubtle),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            isCompleted ? 'COMPLETED' : (isCurrent ? 'IN PROGRESS' : 'UPCOMING'),
                            style: GoogleFonts.inter(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: isCompleted ? AppTheme.emeraldSuccess : (isCurrent ? AppTheme.primaryViolet : AppTheme.textMuted),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),

                const SizedBox(height: 20),

                // 3. Approved Site Photos & Updates
                Text('Site Engineer Updates & Photographic Log', style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                const SizedBox(height: 10),

                ...project.updates.map((u) => Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.cardWhite,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppTheme.borderLight),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(u.phase.displayName, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.primaryViolet)),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppTheme.emeraldSuccess.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text('VERIFIED AUDIT', style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.bold, color: AppTheme.emeraldSuccess)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(u.title, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                          const SizedBox(height: 4),
                          Text(u.description, style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textSecondary)),
                          const SizedBox(height: 10),

                          if (u.photos.isNotEmpty)
                            SizedBox(
                              height: 120,
                              child: ListView(
                                scrollDirection: Axis.horizontal,
                                children: u.photos.map((ph) => Container(
                                      margin: const EdgeInsets.only(right: 8),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: Image.network(
                                          ph,
                                          width: 160,
                                          height: 120,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) => Container(width: 160, height: 120, color: AppTheme.surfaceSubtle),
                                        ),
                                      ),
                                    )).toList(),
                              ),
                            ),

                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('By ${u.uploadedBy}', style: GoogleFonts.inter(fontSize: 10, color: AppTheme.textMuted)),
                              Text('Captured: ${u.capturedAt.day}/${u.capturedAt.month}/${u.capturedAt.year}', style: GoogleFonts.inter(fontSize: 10, color: AppTheme.textMuted)),
                            ],
                          ),
                        ],
                      ),
                    )),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMetaChip(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.inter(fontSize: 10, color: AppTheme.textMuted)),
        const SizedBox(height: 2),
        Text(value, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
      ],
    );
  }
}
