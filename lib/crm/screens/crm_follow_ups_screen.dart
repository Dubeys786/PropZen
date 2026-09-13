import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../theme/app_theme.dart';
import '../models/crm_follow_up.dart';
import '../services/crm_follow_up_service.dart';

class CrmFollowUpsScreen extends StatefulWidget {
  const CrmFollowUpsScreen({super.key});

  @override
  State<CrmFollowUpsScreen> createState() => _CrmFollowUpsScreenState();
}

class _CrmFollowUpsScreenState extends State<CrmFollowUpsScreen> with SingleTickerProviderStateMixin {
  final CrmFollowUpService _service = CrmFollowUpService.instance;
  late final TabController _tabController;

  List<CrmFollowUp> _allFollowUps = [];
  bool _isLoading = true;

  Future<void> _callCustomer(CrmFollowUp f) async {
    final phone = f.leadPhone?.replaceAll(RegExp(r'[^0-9+]'), '') ?? '';
    if (phone.isNotEmpty) {
      final uri = Uri.parse('tel:$phone');
      if (await canLaunchUrl(uri)) await launchUrl(uri);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No phone number recorded for this lead')));
    }
  }

  Future<void> _whatsAppCustomer(CrmFollowUp f) async {
    final phone = f.leadPhone?.replaceAll(RegExp(r'[^0-9]'), '') ?? '';
    if (phone.isNotEmpty) {
      final text = Uri.encodeComponent('Hello ${f.leadName ?? "there"}, following up from PropZen regarding your property enquiry.');
      final uri = Uri.parse('https://wa.me/$phone?text=$text');
      if (await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No phone number recorded for WhatsApp')));
    }
  }

  Future<void> _emailCustomer(CrmFollowUp f) async {
    final email = f.leadEmail ?? '';
    if (email.isNotEmpty) {
      final uri = Uri.parse('mailto:$email?subject=PropZen Follow-up');
      if (await canLaunchUrl(uri)) await launchUrl(uri);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No email recorded for this lead')));
    }
  }

  Future<void> _rescheduleFollowUp(CrmFollowUp f) async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (pickedDate == null || !mounted) return;
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 11, minute: 0),
    );
    if (pickedTime == null || !mounted) return;

    final newDateTime = DateTime(pickedDate.year, pickedDate.month, pickedDate.day, pickedTime.hour, pickedTime.minute);
    try {
      await _service.scheduleFollowUp(
        leadId: f.leadId,
        scheduledAt: newDateTime,
        channel: f.channel,
        notes: f.notes != null ? '${f.notes} (Rescheduled)' : 'Rescheduled follow-up',
      );
      _fetchFollowUps();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Follow-up successfully rescheduled')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: $e')),
        );
      }
    }
  }

  Future<void> _addNoteToFollowUp(CrmFollowUp f) async {
    final noteCtrl = TextEditingController();
    final messenger = ScaffoldMessenger.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Add Follow-up Note', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700)),
        content: TextField(
          controller: noteCtrl,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: 'Enter internal follow-up remarks...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Save Note', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true && noteCtrl.text.trim().isNotEmpty) {
      try {
        await _service.scheduleFollowUp(
          leadId: f.leadId,
          scheduledAt: f.scheduledAt,
          channel: f.channel,
          notes: f.notes != null ? '${f.notes}\nNote: ${noteCtrl.text.trim()}' : noteCtrl.text.trim(),
        );
        _fetchFollowUps();
        messenger.showSnackBar(const SnackBar(content: Text('Note added to follow-up')));
      } catch (e) {
        messenger.showSnackBar(SnackBar(content: Text('Failed to add note: $e')));
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _fetchFollowUps();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchFollowUps() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final list = await _service.getFollowUps();
      if (mounted) {
        setState(() {
          _allFollowUps = list;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _markCompleted(String id) async {
    try {
      await _service.completeFollowUp(id);
      _fetchFollowUps();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Follow-up marked as completed')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: $e')),
        );
      }
    }
  }

  List<CrmFollowUp> get _todayList =>
      _allFollowUps.where((f) => f.isToday && f.status == FollowUpStatus.pending).toList();

  List<CrmFollowUp> get _upcomingList {
    final now = DateTime.now();
    return _allFollowUps
        .where((f) => f.status == FollowUpStatus.pending && f.scheduledAt.isAfter(now) && !f.isToday)
        .toList();
  }

  List<CrmFollowUp> get _overdueList =>
      _allFollowUps.where((f) => f.isOverdue).toList();

  List<CrmFollowUp> get _completedList =>
      _allFollowUps.where((f) => f.status == FollowUpStatus.completed).toList();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.pageBackground,
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Follow-up Management',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Track calls, messages, and site visit follow-ups scheduled with prospects.',
                      style: GoogleFonts.inter(fontSize: 13, color: AppTheme.textSecondary),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(LucideIcons.refreshCw, size: 18),
                  onPressed: _fetchFollowUps,
                  tooltip: 'Refresh',
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Tabs
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: TabBar(
                controller: _tabController,
                labelColor: AppTheme.primaryColor,
                unselectedLabelColor: const Color(0xFF64748B),
                indicatorColor: AppTheme.primaryColor,
                tabs: [
                  Tab(text: "Today's (${_todayList.length})"),
                  Tab(text: 'Upcoming (${_upcomingList.length})'),
                  Tab(text: 'Overdue (${_overdueList.length})'),
                  Tab(text: 'Completed (${_completedList.length})'),
                ],
              ),
            ),
            const SizedBox(height: 16),

            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor))
                  : TabBarView(
                      controller: _tabController,
                      children: [
                        _buildList(_todayList, 'No follow-ups scheduled for today.'),
                        _buildList(_upcomingList, 'No upcoming follow-ups scheduled.'),
                        _buildList(_overdueList, 'Great job! No overdue follow-ups.'),
                        _buildList(_completedList, 'No completed follow-ups recorded.'),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildList(List<CrmFollowUp> list, String emptyMessage) {
    if (list.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(LucideIcons.calendarCheck, size: 40, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            Text(emptyMessage, style: GoogleFonts.inter(fontSize: 13, color: AppTheme.textSecondary)),
          ],
        ),
      );
    }

    return ListView.separated(
      itemCount: list.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, idx) {
        final f = list[idx];
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: f.isOverdue ? const Color(0xFFFCA5A5) : const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.01),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: f.status.color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  f.channel == 'WHATSAPP'
                      ? LucideIcons.messageSquare
                      : f.channel == 'EMAIL'
                          ? LucideIcons.mail
                          : LucideIcons.phone,
                  size: 20,
                  color: f.status.color,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          f.leadName ?? 'Lead Follow-up',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: f.status.color.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            f.status.label,
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: f.status.color,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      f.notes ?? f.type,
                      style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textSecondary),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Scheduled: ${f.scheduledAt.day}/${f.scheduledAt.month}/${f.scheduledAt.year} at ${f.scheduledAt.hour}:${f.scheduledAt.minute.toString().padLeft(2, '0')}',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: f.isOverdue ? Colors.red.shade700 : const Color(0xFF64748B),
                        fontWeight: f.isOverdue ? FontWeight.w600 : FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(LucideIcons.phone, size: 16, color: Color(0xFF3B82F6)),
                    tooltip: 'Call Customer',
                    onPressed: () => _callCustomer(f),
                  ),
                  IconButton(
                    icon: const Icon(LucideIcons.messageSquare, size: 16, color: Color(0xFF25D366)),
                    tooltip: 'Send WhatsApp',
                    onPressed: () => _whatsAppCustomer(f),
                  ),
                  IconButton(
                    icon: const Icon(LucideIcons.mail, size: 16, color: Color(0xFF64748B)),
                    tooltip: 'Send Email',
                    onPressed: () => _emailCustomer(f),
                  ),
                  IconButton(
                    icon: const Icon(LucideIcons.calendarClock, size: 16, color: Color(0xFF8B5CF6)),
                    tooltip: 'Reschedule',
                    onPressed: () => _rescheduleFollowUp(f),
                  ),
                  IconButton(
                    icon: const Icon(LucideIcons.filePlus, size: 16, color: Color(0xFFD97706)),
                    tooltip: 'Add Note',
                    onPressed: () => _addNoteToFollowUp(f),
                  ),
                  if (f.status == FollowUpStatus.pending) ...[
                    const SizedBox(width: 4),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF10B981),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: () => _markCompleted(f.id),
                      child: const Text('Mark Done', style: TextStyle(fontSize: 12, color: Colors.white)),
                    ),
                  ],
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
