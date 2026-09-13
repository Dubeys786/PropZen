import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../theme/app_theme.dart';
import '../models/crm_lead.dart';
import '../models/crm_note.dart';
import '../models/crm_task.dart';
import '../services/crm_service.dart';
import '../services/crm_follow_up_service.dart';
import '../widgets/ai_assistant_card.dart';

class CrmLeadDetailsScreen extends StatefulWidget {
  final String leadId;
  final VoidCallback? onUpdated;

  const CrmLeadDetailsScreen({
    super.key,
    required this.leadId,
    this.onUpdated,
  });

  @override
  State<CrmLeadDetailsScreen> createState() => _CrmLeadDetailsScreenState();
}

class _CrmLeadDetailsScreenState extends State<CrmLeadDetailsScreen> with SingleTickerProviderStateMixin {
  final CrmService _crmService = CrmService.instance;
  final CrmFollowUpService _followUpService = CrmFollowUpService.instance;

  late final TabController _tabController;
  CrmLead? _lead;
  List<LeadActivity> _timeline = [];
  List<CrmNote> _notes = [];
  List<CrmTask> _tasks = [];

  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadLeadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadLeadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final leadFuture = _crmService.getLead(widget.leadId);
      final timelineFuture = _crmService.getTimeline(widget.leadId);
      final notesFuture = _crmService.getNotes(widget.leadId);
      final tasksFuture = _crmService.getTasks(widget.leadId);

      final results = await Future.wait([leadFuture, timelineFuture, notesFuture, tasksFuture]);

      if (mounted) {
        setState(() {
          _lead = results[0] as CrmLead;
          _timeline = results[1] as List<LeadActivity>;
          _notes = results[2] as List<CrmNote>;
          _tasks = results[3] as List<CrmTask>;
          _isLoading = false;
        });
        widget.onUpdated?.call();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString();
        });
      }
    }
  }

  Future<void> _updateStatus(LeadStatus newStatus) async {
    try {
      final updated = await _crmService.updateLeadStatus(widget.leadId, newStatus);
      setState(() => _lead = updated);
      _loadLeadData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lead status updated to ${newStatus.label}')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update status: $e')),
        );
      }
    }
  }

  Future<void> _updatePriority(LeadPriority newPriority) async {
    try {
      final updated = await _crmService.updateLeadPriority(widget.leadId, newPriority);
      setState(() => _lead = updated);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Priority set to ${newPriority.label}')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update priority: $e')),
        );
      }
    }
  }

  Future<void> _updateStage(LeadStage newStage) async {
    try {
      final updated = await _crmService.updateLeadStage(widget.leadId, newStage);
      setState(() => _lead = updated);
      _loadLeadData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Pipeline stage set to ${newStage.label}')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update stage: $e')),
        );
      }
    }
  }

  void _showAddNoteDialog() {
    final noteCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Add Internal Note', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700)),
        content: TextField(
          controller: noteCtrl,
          maxLines: 4,
          decoration: const InputDecoration(
            hintText: 'Enter internal conversation note or customer details...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor),
            onPressed: () async {
              if (noteCtrl.text.trim().isEmpty) return;
              Navigator.of(ctx).pop();
              try {
                await _crmService.addNote(widget.leadId, noteCtrl.text.trim());
                _loadLeadData();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Note added')),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to add note: $e')),
                  );
                }
              }
            },
            child: const Text('Save Note', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showScheduleFollowUpDialog() {
    DateTime selectedDate = DateTime.now().add(const Duration(days: 1));
    final notesCtrl = TextEditingController();
    String channel = 'PHONE';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDlgState) => AlertDialog(
          title: Text('Schedule Follow-up', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(LucideIcons.calendar, color: Color(0xFF3B82F6)),
                title: Text('Date: ${selectedDate.day}/${selectedDate.month}/${selectedDate.year}'),
                trailing: TextButton(
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (picked != null) {
                      setDlgState(() => selectedDate = picked);
                    }
                  },
                  child: const Text('Change'),
                ),
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: channel,
                decoration: const InputDecoration(labelText: 'Channel', border: OutlineInputBorder()),
                items: const [
                  DropdownMenuItem(value: 'PHONE', child: Text('Phone Call')),
                  DropdownMenuItem(value: 'WHATSAPP', child: Text('WhatsApp')),
                  DropdownMenuItem(value: 'EMAIL', child: Text('Email')),
                  DropdownMenuItem(value: 'MEETING', child: Text('In-Person Meeting')),
                ],
                onChanged: (val) {
                  if (val != null) setDlgState(() => channel = val);
                },
              ),
              const SizedBox(height: 12),
              TextField(
                controller: notesCtrl,
                decoration: const InputDecoration(labelText: 'Follow-up Agenda / Notes', border: OutlineInputBorder()),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor),
              onPressed: () async {
                final messenger = ScaffoldMessenger.of(context);
                Navigator.of(ctx).pop();
                try {
                  await _followUpService.scheduleFollowUp(
                    leadId: widget.leadId,
                    scheduledAt: selectedDate,
                    channel: channel,
                    notes: notesCtrl.text.trim(),
                  );
                  _loadLeadData();
                  messenger.showSnackBar(
                    const SnackBar(content: Text('Follow-up scheduled successfully')),
                  );
                } catch (e) {
                  messenger.showSnackBar(
                    SnackBar(content: Text('Failed: $e')),
                  );
                }
              },
              child: const Text('Schedule', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  void _showCreateTaskDialog() {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    String priority = 'MEDIUM';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDlgState) => AlertDialog(
          title: Text('Add Task', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleCtrl,
                decoration: const InputDecoration(labelText: 'Task Title *', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: descCtrl,
                decoration: const InputDecoration(labelText: 'Description', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: priority,
                decoration: const InputDecoration(labelText: 'Priority', border: OutlineInputBorder()),
                items: const [
                  DropdownMenuItem(value: 'LOW', child: Text('Low')),
                  DropdownMenuItem(value: 'MEDIUM', child: Text('Medium')),
                  DropdownMenuItem(value: 'HIGH', child: Text('High')),
                  DropdownMenuItem(value: 'URGENT', child: Text('Urgent')),
                ],
                onChanged: (val) {
                  if (val != null) setDlgState(() => priority = val);
                },
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor),
              onPressed: () async {
                final messenger = ScaffoldMessenger.of(context);
                if (titleCtrl.text.trim().isEmpty) return;
                Navigator.of(ctx).pop();
                try {
                  await _crmService.createTask(
                    widget.leadId,
                    title: titleCtrl.text.trim(),
                    description: descCtrl.text.trim(),
                    priority: priority,
                  );
                  _loadLeadData();
                  messenger.showSnackBar(
                    const SnackBar(content: Text('Task created')),
                  );
                } catch (e) {
                  messenger.showSnackBar(
                    SnackBar(content: Text('Failed: $e')),
                  );
                }
              },
              child: const Text('Create', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppTheme.pageBackground,
        appBar: AppBar(backgroundColor: Colors.white, elevation: 0),
        body: const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor)),
      );
    }

    if (_errorMessage != null || _lead == null) {
      return Scaffold(
        backgroundColor: AppTheme.pageBackground,
        appBar: AppBar(backgroundColor: Colors.white, elevation: 0),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(LucideIcons.alertCircle, size: 40, color: Colors.red),
              const SizedBox(height: 12),
              Text(_errorMessage ?? 'Lead details not found'),
              const SizedBox(height: 12),
              ElevatedButton(onPressed: _loadLeadData, child: const Text('Retry')),
            ],
          ),
        ),
      );
    }

    final lead = _lead!;

    return Scaffold(
      backgroundColor: AppTheme.pageBackground,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppTheme.textPrimary),
        title: Row(
          children: [
            Text(
              lead.name,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
              ),
            ),
            if (lead.leadNumber != null) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  lead.leadNumber!,
                  style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: const Color(0xFF64748B)),
                ),
              ),
            ],
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.refreshCw, size: 18),
            onPressed: _loadLeadData,
            tooltip: 'Refresh',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Customer Profile & Status Card
            _buildProfileCard(lead),
            const SizedBox(height: 20),

            // Pipeline Stage Stepper
            _buildStageStepper(lead),
            const SizedBox(height: 20),

            // AI Intelligence Section
            LayoutBuilder(
              builder: (context, constraints) {
                final isNarrow = constraints.maxWidth < 800;
                final aiScoreCard = AiLeadScoreCard(
                  leadId: widget.leadId,
                  initialScore: lead.leadScore,
                  onScoreUpdated: () {},
                );
                final aiNextAction = AiNextActionCard(leadId: widget.leadId);

                if (isNarrow) {
                  return Column(children: [aiScoreCard, const SizedBox(height: 16), aiNextAction]);
                }
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 5, child: aiScoreCard),
                    const SizedBox(width: 16),
                    Expanded(flex: 5, child: aiNextAction),
                  ],
                );
              },
            ),
            const SizedBox(height: 20),

            // AI Follow-up Assistant Card
            AiFollowUpAssistantCard(
              leadId: widget.leadId,
              customerPhone: lead.phone,
              customerName: lead.name,
            ),
            const SizedBox(height: 24),

            // Tabbed History Section: Timeline, Notes, Tasks
            _buildTabsSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileCard(CrmLead lead) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 26,
                    backgroundColor: lead.status.color.withOpacity(0.12),
                    child: Text(
                      lead.name.isNotEmpty ? lead.name[0].toUpperCase() : 'L',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: lead.status.color,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        lead.name,
                        style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          const Icon(LucideIcons.phone, size: 13, color: Color(0xFF64748B)),
                          const SizedBox(width: 4),
                          Text(lead.phone, style: GoogleFonts.inter(fontSize: 13, color: AppTheme.textSecondary)),
                          if (lead.email != null && lead.email!.isNotEmpty) ...[
                            const SizedBox(width: 12),
                            const Icon(LucideIcons.mail, size: 13, color: Color(0xFF64748B)),
                            const SizedBox(width: 4),
                            Text(lead.email!, style: GoogleFonts.inter(fontSize: 13, color: AppTheme.textSecondary)),
                          ],
                        ],
                      ),
                    ],
                  ),
                ],
              ),
              // Action Buttons: Call, WhatsApp, Schedule Follow-up
              Wrap(
                spacing: 8,
                children: [
                  OutlinedButton.icon(
                    icon: const Icon(LucideIcons.phone, size: 14, color: Color(0xFF10B981)),
                    label: const Text('Call'),
                    onPressed: () async {
                      final url = Uri.parse('tel:${lead.phone}');
                      if (await canLaunchUrl(url)) await launchUrl(url);
                    },
                  ),
                  OutlinedButton.icon(
                    icon: const Icon(LucideIcons.messageSquare, size: 14, color: Color(0xFF25D366)),
                    label: const Text('WhatsApp'),
                    onPressed: () async {
                      final clean = lead.phone.replaceAll(RegExp(r'[^0-9]'), '');
                      final url = Uri.parse('https://wa.me/$clean');
                      if (await canLaunchUrl(url)) await launchUrl(url, mode: LaunchMode.externalApplication);
                    },
                  ),
                  ElevatedButton.icon(
                    icon: const Icon(LucideIcons.calendarPlus, size: 14, color: Colors.white),
                    label: const Text('Follow-up', style: TextStyle(color: Colors.white)),
                    style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor, elevation: 0),
                    onPressed: _showScheduleFollowUpDialog,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 18),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          const SizedBox(height: 14),

          // Metadata Grid
          Wrap(
            spacing: 24,
            runSpacing: 12,
            children: [
              _buildMetaItem('Status', lead.status.label, lead.status.color),
              _buildMetaItem('Priority', lead.priority.label, lead.priority.color),
              _buildMetaItem('Source', lead.source.label, const Color(0xFF475569)),
              _buildMetaItem('Budget', lead.displayBudget, const Color(0xFF0F172A)),
              _buildMetaItem('Location', lead.displayLocation, const Color(0xFF0F172A)),
              if (lead.preferredBhk != null) _buildMetaItem('BHK', lead.preferredBhk!, const Color(0xFF0F172A)),
            ],
          ),
          const SizedBox(height: 16),

          // Status & Priority Quick Changers
          Row(
            children: [
              Text('Change Status: ', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600)),
              DropdownButton<LeadStatus>(
                value: lead.status,
                items: LeadStatus.values.map((s) => DropdownMenuItem(value: s, child: Text(s.label, style: const TextStyle(fontSize: 12)))).toList(),
                onChanged: (s) {
                  if (s != null && s != lead.status) _updateStatus(s);
                },
              ),
              const SizedBox(width: 24),
              Text('Change Priority: ', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600)),
              DropdownButton<LeadPriority>(
                value: lead.priority,
                items: LeadPriority.values.map((p) => DropdownMenuItem(value: p, child: Text(p.label, style: const TextStyle(fontSize: 12)))).toList(),
                onChanged: (p) {
                  if (p != null && p != lead.priority) _updatePriority(p);
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetaItem(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF94A3B8))),
        const SizedBox(height: 2),
        Text(value, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: color)),
      ],
    );
  }

  Widget _buildStageStepper(CrmLead lead) {
    const stages = [
      LeadStage.newLead,
      LeadStage.contacted,
      LeadStage.interested,
      LeadStage.siteVisitBooked,
      LeadStage.siteVisitCompleted,
      LeadStage.negotiation,
      LeadStage.converted,
    ];

    final currentIdx = stages.indexOf(lead.stage);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Pipeline Progression',
                style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w700),
              ),
              Text(
                'Current: ${lead.stage.label}',
                style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.primaryColor),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: stages.asMap().entries.map((entry) {
                final idx = entry.key;
                final stage = entry.value;
                final isDone = currentIdx >= 0 && idx <= currentIdx;
                final isCurrent = idx == currentIdx;

                return InkWell(
                  onTap: () => _updateStage(stage),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: isCurrent
                              ? AppTheme.primaryColor
                              : isDone
                                  ? const Color(0xFF10B981).withOpacity(0.12)
                                  : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isCurrent
                                ? AppTheme.primaryColor
                                : isDone
                                    ? const Color(0xFF10B981)
                                    : const Color(0xFFCBD5E1),
                          ),
                        ),
                        child: Text(
                          stage.label,
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: isCurrent
                                ? Colors.white
                                : isDone
                                    ? const Color(0xFF059669)
                                    : const Color(0xFF64748B),
                          ),
                        ),
                      ),
                      if (idx < stages.length - 1)
                        Container(
                          width: 20,
                          height: 2,
                          color: isDone ? const Color(0xFF10B981) : const Color(0xFFE2E8F0),
                        ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabsSection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          TabBar(
            controller: _tabController,
            labelColor: AppTheme.primaryColor,
            unselectedLabelColor: const Color(0xFF64748B),
            indicatorColor: AppTheme.primaryColor,
            tabs: [
              Tab(text: 'Activity Timeline (${_timeline.length})'),
              Tab(text: 'Internal Notes (${_notes.length})'),
              Tab(text: 'Tasks (${_tasks.length})'),
            ],
          ),
          SizedBox(
            height: 380,
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildTimelineTab(),
                _buildNotesTab(),
                _buildTasksTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineTab() {
    if (_timeline.isEmpty) {
      return Center(
        child: Text('No activity records logged yet.', style: GoogleFonts.inter(fontSize: 13, color: AppTheme.textSecondary)),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _timeline.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, idx) {
        final item = _timeline[idx];
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFF3B82F6).withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(LucideIcons.activity, size: 14, color: Color(0xFF3B82F6)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.summary, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700)),
                  if (item.details != null && item.details!.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(item.details!, style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textSecondary)),
                  ],
                  const SizedBox(height: 4),
                  Text(
                    '${item.createdAt.day}/${item.createdAt.month}/${item.createdAt.year} at ${item.createdAt.hour}:${item.createdAt.minute.toString().padLeft(2, '0')}',
                    style: GoogleFonts.inter(fontSize: 10, color: const Color(0xFF94A3B8)),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildNotesTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Align(
            alignment: Alignment.centerRight,
            child: OutlinedButton.icon(
              icon: const Icon(LucideIcons.plus, size: 14),
              label: const Text('Add Note'),
              onPressed: _showAddNoteDialog,
            ),
          ),
        ),
        Expanded(
          child: _notes.isEmpty
              ? Center(child: Text('No notes added.', style: GoogleFonts.inter(fontSize: 13, color: AppTheme.textSecondary)))
              : ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _notes.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, idx) {
                    final note = _notes[idx];
                    return Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(note.content, style: GoogleFonts.inter(fontSize: 13)),
                          const SizedBox(height: 6),
                          Text(
                            '${note.createdByName ?? 'Staff'} • ${note.createdAt.day}/${note.createdAt.month}/${note.createdAt.year}',
                            style: GoogleFonts.inter(fontSize: 10, color: const Color(0xFF94A3B8)),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildTasksTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Align(
            alignment: Alignment.centerRight,
            child: OutlinedButton.icon(
              icon: const Icon(LucideIcons.plus, size: 14),
              label: const Text('Add Task'),
              onPressed: _showCreateTaskDialog,
            ),
          ),
        ),
        Expanded(
          child: _tasks.isEmpty
              ? Center(child: Text('No tasks associated with this lead.', style: GoogleFonts.inter(fontSize: 13, color: AppTheme.textSecondary)))
              : ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _tasks.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, idx) {
                    final t = _tasks[idx];
                    return Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            t.isCompleted ? LucideIcons.checkCircle2 : LucideIcons.circle,
                            color: t.isCompleted ? const Color(0xFF10B981) : const Color(0xFF94A3B8),
                            size: 18,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  t.title,
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    decoration: t.isCompleted ? TextDecoration.lineThrough : null,
                                  ),
                                ),
                                if (t.description != null && t.description!.isNotEmpty)
                                  Text(t.description!, style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textSecondary)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
