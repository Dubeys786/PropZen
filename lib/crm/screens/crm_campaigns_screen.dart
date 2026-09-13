import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../theme/app_theme.dart';
import '../models/crm_campaign.dart';
import '../models/whatsapp_template.dart';
import '../models/crm_lead.dart';
import '../services/crm_campaign_service.dart';

class CrmCampaignsScreen extends StatefulWidget {
  final int initialTab;

  const CrmCampaignsScreen({super.key, this.initialTab = 0});

  @override
  State<CrmCampaignsScreen> createState() => _CrmCampaignsScreenState();
}

class _CrmCampaignsScreenState extends State<CrmCampaignsScreen> with SingleTickerProviderStateMixin {
  final CrmCampaignService _service = CrmCampaignService.instance;
  late final TabController _tabController;

  List<CrmCampaign> _campaigns = [];
  List<WhatsAppTemplate> _templates = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this, initialIndex: widget.initialTab.clamp(0, 1));
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final campaignsFuture = _service.getCampaigns();
      final templatesFuture = _service.getApprovedTemplates();

      final results = await Future.wait([campaignsFuture, templatesFuture]);

      if (mounted) {
        setState(() {
          _campaigns = results[0] as List<CrmCampaign>;
          _templates = results[1] as List<WhatsAppTemplate>;
          _isLoading = false;
        });
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

  Future<void> _triggerSend(CrmCampaign campaign) async {
    // Section 13: Strict confirmation modal before bulk dispatch
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(LucideIcons.alertTriangle, color: Color(0xFFF59E0B), size: 22),
            const SizedBox(width: 10),
            Text('Confirm Campaign Dispatch', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'You are about to dispatch this campaign via official Meta WhatsApp Business API:',
              style: GoogleFonts.inter(fontSize: 13, color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Campaign: ${campaign.name}', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 13)),
                  const SizedBox(height: 4),
                  Text('Target Audience: ${campaign.totalRecipients} Contacts', style: GoogleFonts.inter(fontSize: 12)),
                  const SizedBox(height: 4),
                  Text('Channel: ${campaign.channel}', style: GoogleFonts.inter(fontSize: 12)),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'Consent verification and opt-out filters will be automatically enforced by the backend.',
              style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF64748B)),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF25D366),
              elevation: 0,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Confirm & Send', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _service.sendCampaign(campaign.id);
        _loadData();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Campaign dispatched to background processing queue')),
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
  }

  void _showCreateCampaignWizard() {
    final nameCtrl = TextEditingController();
    final cityCtrl = TextEditingController();
    String? selectedTemplateId = _templates.isNotEmpty ? _templates.first.id : null;
    LeadStatus? targetStatus;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDlgState) {
          final currentTemplate = _templates.firstWhere(
            (t) => t.id == selectedTemplateId,
            orElse: () => _templates.isNotEmpty
                ? _templates.first
                : const WhatsAppTemplate(id: '', name: 'Default', templateName: 'welcome', content: ''),
          );

          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Row(
              children: [
                const Icon(LucideIcons.megaphone, color: Color(0xFF25D366), size: 20),
                const SizedBox(width: 10),
                Text('Create WhatsApp Campaign', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 18)),
              ],
            ),
            content: SizedBox(
              width: 480,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Campaign Name *',
                        hintText: 'e.g. Noida Sector 150 Launch Alert',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Audience Filters
                    Text('1. Select Audience Segment', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 13)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<LeadStatus?>(
                            value: targetStatus,
                            decoration: const InputDecoration(labelText: 'Lead Status', border: OutlineInputBorder()),
                            items: [
                              const DropdownMenuItem(value: null, child: Text('All Statuses')),
                              ...LeadStatus.values.map((s) => DropdownMenuItem(value: s, child: Text(s.label))),
                            ],
                            onChanged: (val) => setDlgState(() => targetStatus = val),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: cityCtrl,
                            decoration: const InputDecoration(labelText: 'Target City', border: OutlineInputBorder()),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Template Selector
                    Text('2. WhatsApp Message Template', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 13)),
                    const SizedBox(height: 8),
                    if (_templates.isEmpty) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: Colors.amber.shade50, borderRadius: BorderRadius.circular(8)),
                        child: Text(
                          'No pre-approved WhatsApp templates registered on backend. Define templates first via /api/v1/whatsapp/template.',
                          style: GoogleFonts.inter(fontSize: 12, color: Colors.amber.shade900),
                        ),
                      ),
                    ] else ...[
                      DropdownButtonFormField<String>(
                        value: selectedTemplateId,
                        decoration: const InputDecoration(labelText: 'Approved Template', border: OutlineInputBorder()),
                        items: _templates.map((t) => DropdownMenuItem(value: t.id, child: Text(t.name))).toList(),
                        onChanged: (val) => setDlgState(() => selectedTemplateId = val),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Template Preview:', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: const Color(0xFF64748B))),
                            const SizedBox(height: 4),
                            Text(
                              currentTemplate.content.isNotEmpty ? currentTemplate.content : 'Template content preview',
                              style: GoogleFonts.inter(fontSize: 12, height: 1.4),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor),
                onPressed: () async {
                  final messenger = ScaffoldMessenger.of(context);
                  if (nameCtrl.text.trim().isEmpty || selectedTemplateId == null) {
                    messenger.showSnackBar(
                      const SnackBar(content: Text('Campaign name and template are required')),
                    );
                    return;
                  }
                  Navigator.of(ctx).pop();
                  try {
                    await _service.createCampaign(
                      name: nameCtrl.text.trim(),
                      templateId: selectedTemplateId!,
                      targetStatus: targetStatus,
                      targetCity: cityCtrl.text.trim(),
                    );
                    _loadData();
                    messenger.showSnackBar(
                      const SnackBar(content: Text('Campaign created as draft')),
                    );
                  } catch (e) {
                    messenger.showSnackBar(
                      SnackBar(content: Text('Failed: $e')),
                    );
                  }
                },
                child: const Text('Create Campaign', style: TextStyle(color: Colors.white)),
              ),
            ],
          );
        },
      ),
    );
  }

  List<CrmCampaign> get _activeCampaigns =>
      _campaigns.where((c) => c.status != CampaignStatus.completed && c.status != CampaignStatus.failed && c.status != CampaignStatus.cancelled).toList();

  List<CrmCampaign> get _historyCampaigns =>
      _campaigns.where((c) => c.status == CampaignStatus.completed || c.status == CampaignStatus.failed || c.status == CampaignStatus.cancelled).toList();

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
                      'WhatsApp & Marketing Campaigns',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Audience segmentation, pre-approved WhatsApp templates, and delivery analytics.',
                      style: GoogleFonts.inter(fontSize: 13, color: AppTheme.textSecondary),
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  icon: const Icon(LucideIcons.plus, size: 16),
                  label: const Text('New Campaign'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF25D366),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    elevation: 0,
                  ),
                  onPressed: _showCreateCampaignWizard,
                ),
              ],
            ),
            const SizedBox(height: 16),

            Container(
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
              ),
              child: TabBar(
                controller: _tabController,
                isScrollable: true,
                labelColor: AppTheme.primaryColor,
                unselectedLabelColor: const Color(0xFF64748B),
                indicatorColor: AppTheme.primaryColor,
                tabs: [
                  Tab(text: 'Active Campaigns (${_activeCampaigns.length})'),
                  Tab(text: 'Campaign History & Analytics (${_historyCampaigns.length})'),
                ],
              ),
            ),
            const SizedBox(height: 16),

            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor))
                  : _errorMessage != null
                      ? Center(child: Text('Error: $_errorMessage'))
                      : TabBarView(
                          controller: _tabController,
                          children: [
                            _activeCampaigns.isEmpty ? _buildEmptyState('No active campaigns running') : _buildListFor(_activeCampaigns),
                            _historyCampaigns.isEmpty ? _buildEmptyState('No historical campaigns found') : _buildListFor(_historyCampaigns),
                          ],
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState([String subtitle = 'Create your first targeted WhatsApp campaign to engage segmented leads.']) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(LucideIcons.megaphone, size: 48, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            'No marketing campaigns found',
            style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: GoogleFonts.inter(fontSize: 13, color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 18),
          ElevatedButton.icon(
            icon: const Icon(LucideIcons.plus, size: 16),
            label: const Text('Create Campaign'),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF25D366), elevation: 0),
            onPressed: _showCreateCampaignWizard,
          ),
        ],
      ),
    );
  }

  Widget _buildListFor(List<CrmCampaign> list) {
    return ListView.separated(
      itemCount: list.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, idx) {
        final c = list[idx];
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
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
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: c.status.color.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(LucideIcons.messageSquare, size: 18, color: c.status.color),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(c.name, style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w700)),
                          Text('Channel: ${c.channel} • Type: ${c.type}', style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF64748B))),
                        ],
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                        decoration: BoxDecoration(
                          color: c.status.color.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          c.status.label,
                          style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: c.status.color),
                        ),
                      ),
                      if (c.status == CampaignStatus.draft || c.status == CampaignStatus.scheduled) ...[
                        const SizedBox(width: 10),
                        ElevatedButton.icon(
                          icon: const Icon(LucideIcons.send, size: 13, color: Colors.white),
                          label: const Text('Send Now', style: TextStyle(fontSize: 11, color: Colors.white)),
                          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF25D366), elevation: 0),
                          onPressed: () => _triggerSend(c),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(height: 1, color: Color(0xFFF1F5F9)),
              const SizedBox(height: 14),

              // Real Delivery Analytics Grid
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildMetricCol('Recipients', '${c.totalRecipients}', const Color(0xFF0F172A)),
                  _buildMetricCol('Sent', '${c.sentCount}', const Color(0xFF3B82F6)),
                  _buildMetricCol('Delivered', '${c.deliveredCount}', const Color(0xFF10B981)),
                  _buildMetricCol('Read', '${c.readCount}', const Color(0xFF7C3AED)),
                  _buildMetricCol('Failed', '${c.failedCount}', const Color(0xFFEF4444)),
                  _buildMetricCol('Delivery Rate', '${c.deliveryRate.toStringAsFixed(1)}%', const Color(0xFF059669)),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMetricCol(String label, String value, Color valColor) {
    return Column(
      children: [
        Text(value, style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w800, color: valColor)),
        const SizedBox(height: 2),
        Text(label, style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF94A3B8))),
      ],
    );
  }
}
