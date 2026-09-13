import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../models/ai_home_project.dart';
import '../services/ai_home_designer_service.dart';
import '../services/supabase_service.dart';
import '../theme/app_theme.dart';
import '../theme/responsive_layout.dart';
import 'ai_home_designer_wizard_screen.dart';
import 'ai_home_share_screen.dart';

/// Screen listing saved AI Home & Vastu Designs from Supabase / Cache
class MyAiDesignsScreen extends StatefulWidget {
  const MyAiDesignsScreen({super.key});

  @override
  State<MyAiDesignsScreen> createState() => _MyAiDesignsScreenState();
}

class _MyAiDesignsScreenState extends State<MyAiDesignsScreen> {
  List<AiHomeProject> _projects = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProjects();
  }

  Future<void> _loadProjects() async {
    setState(() => _isLoading = true);
    final user = SupabaseService.instance.auth.currentUser;
    final list = await AiHomeDesignerService.instance.fetchUserProjects(user?.id ?? 'usr_active');
    if (!mounted) return;
    setState(() {
      _projects = list;
      _isLoading = false;
    });
  }

  void _deleteProject(AiHomeProject project) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete Design?', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        content: Text('Are you sure you want to delete "${project.projectName}"? This action cannot be undone.', style: GoogleFonts.inter(fontSize: 13)),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.coralDanger, foregroundColor: Colors.white),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await AiHomeDesignerService.instance.deleteProject(project.id);
      _loadProjects();
    }
  }

  void _duplicateProject(AiHomeProject project) async {
    await AiHomeDesignerService.instance.duplicateProject(project);
    _loadProjects();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.pageBackground,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: AppTheme.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'My AI Designs',
          style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
        ),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.plus, color: AppTheme.primaryViolet),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const AiHomeDesignerWizardScreen()),
              ).then((_) => _loadProjects());
            },
          ),
        ],
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: AppTheme.borderLight),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryViolet))
          : _projects.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: _loadProjects,
                  child: SingleChildScrollView(
                    padding: EdgeInsets.all(ResponsiveLayout.horizontalPadding(context)),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: ResponsiveLayout.maxContentWidth),
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final columns = ResponsiveLayout.propertyGridColumns(context);
                            if (columns == 1) {
                              return ListView.separated(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: _projects.length,
                                separatorBuilder: (ctx, i) => const SizedBox(height: 16),
                                itemBuilder: (ctx, i) => _buildProjectCard(_projects[i]),
                              );
                            }

                            return GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: columns,
                                crossAxisSpacing: 16,
                                mainAxisSpacing: 16,
                                childAspectRatio: 0.95,
                              ),
                              itemCount: _projects.length,
                              itemBuilder: (ctx, i) => _buildProjectCard(_projects[i]),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.purpleSubtle,
                shape: BoxShape.circle,
              ),
              child: const Icon(LucideIcons.folderHeart, size: 40, color: AppTheme.primaryViolet),
            ),
            const SizedBox(height: 16),
            Text(
              'No Saved AI Designs Yet',
              style: GoogleFonts.poppins(fontSize: 17, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
            ),
            const SizedBox(height: 6),
            Text(
              'Create custom Vastu-friendly 2D plans, 3D home visualizations and facade elevations in minutes.',
              style: GoogleFonts.inter(fontSize: 13, color: AppTheme.textMuted, height: 1.4),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const AiHomeDesignerWizardScreen()),
                ).then((_) => _loadProjects());
              },
              icon: const Icon(LucideIcons.sparkles, size: 16),
              label: const Text('Start Designing'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryViolet,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProjectCard(AiHomeProject project) {
    final previewImg = project.floorPlans.isNotEmpty && project.floorPlans.first.previewImageUrl != null
        ? project.floorPlans.first.previewImageUrl!
        : 'https://images.unsplash.com/photo-1600585154340-be6161a56a0c?auto=format&fit=crop&w=800&q=80';

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderLight),
        boxShadow: AppTheme.softCardShadow,
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Thumbnail Image with Status Badge
          Stack(
            children: [
              Image.network(
                previewImg,
                height: 140,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (c, e, s) => Container(
                  height: 140,
                  color: AppTheme.surfaceHighlight,
                  child: const Center(child: Icon(LucideIcons.image, color: AppTheme.textHint)),
                ),
              ),
              Positioned(
                top: 10,
                left: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: project.status == 'generated' || project.status == 'customized'
                        ? AppTheme.emeraldSuccess
                        : AppTheme.amberWarning,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    project.status.toUpperCase(),
                    style: GoogleFonts.inter(fontSize: 9.5, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
              ),
              Positioned(
                top: 10,
                right: 10,
                child: PopupMenuButton<String>(
                  icon: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(color: Colors.black.withOpacity(0.6), shape: BoxShape.circle),
                    child: const Icon(LucideIcons.moreVertical, size: 14, color: Colors.white),
                  ),
                  onSelected: (val) {
                    if (val == 'edit') {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => AiHomeDesignerWizardScreen(initialProject: project)),
                      ).then((_) => _loadProjects());
                    } else if (val == 'duplicate') {
                      _duplicateProject(project);
                    } else if (val == 'share') {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (_) => AiHomeShareDialog(project: project),
                      );
                    } else if (val == 'delete') {
                      _deleteProject(project);
                    }
                  },
                  itemBuilder: (ctx) => [
                    const PopupMenuItem(value: 'edit', child: Row(children: [Icon(LucideIcons.edit3, size: 15), SizedBox(width: 8), Text('Edit & Continue')])),
                    const PopupMenuItem(value: 'duplicate', child: Row(children: [Icon(LucideIcons.copy, size: 15), SizedBox(width: 8), Text('Duplicate')])),
                    const PopupMenuItem(value: 'share', child: Row(children: [Icon(LucideIcons.share2, size: 15), SizedBox(width: 8), Text('Share Design')])),
                    const PopupMenuItem(value: 'delete', child: Row(children: [Icon(LucideIcons.trash2, size: 15, color: Colors.red), SizedBox(width: 8), Text('Delete', style: TextStyle(color: Colors.red))])),
                  ],
                ),
              ),
            ],
          ),

          // Card Details
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  project.projectName,
                  style: GoogleFonts.poppins(fontSize: 13.5, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  '${project.formattedPlotDimensions} • ${project.summaryBadge}',
                  style: GoogleFonts.inter(fontSize: 11.5, color: AppTheme.textMuted),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),

                // Open / Edit Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => AiHomeDesignerWizardScreen(initialProject: project, initialStep: 3),
                            ),
                          ).then((_) => _loadProjects());
                        },
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          side: const BorderSide(color: AppTheme.primaryViolet),
                          foregroundColor: AppTheme.primaryViolet,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: const Text('Open Plan', style: TextStyle(fontSize: 12)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => AiHomeDesignerWizardScreen(initialProject: project, initialStep: 0),
                            ),
                          ).then((_) => _loadProjects());
                        },
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          backgroundColor: AppTheme.primaryViolet,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: const Text('Edit', style: TextStyle(fontSize: 12)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
