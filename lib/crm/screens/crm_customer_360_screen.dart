import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../theme/app_theme.dart';
import '../models/customer_360.dart';
import '../models/crm_lead.dart';
import '../services/crm_service.dart';

class CrmCustomer360Screen extends StatefulWidget {
  final String? initialCustomerId;

  const CrmCustomer360Screen({super.key, this.initialCustomerId});

  @override
  State<CrmCustomer360Screen> createState() => _CrmCustomer360ScreenState();
}

class _CrmCustomer360ScreenState extends State<CrmCustomer360Screen> with SingleTickerProviderStateMixin {
  final CrmService _service = CrmService.instance;
  final TextEditingController _idController = TextEditingController();
  late final TabController _tabController;

  Customer360Profile? _profile;
  List<CrmLead> _recentLeads = [];
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    if (widget.initialCustomerId != null && widget.initialCustomerId!.isNotEmpty) {
      _idController.text = widget.initialCustomerId!;
      _searchCustomer(widget.initialCustomerId!);
    }
    _loadRecentCustomers();
  }

  Future<void> _loadRecentCustomers() async {
    try {
      final page = await _service.searchLeads(page: 0, size: 8);
      if (mounted) {
        setState(() => _recentLeads = page.content);
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _tabController.dispose();
    _idController.dispose();
    super.dispose();
  }

  Future<void> _searchCustomer(String id) async {
    if (id.trim().isEmpty) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final res = await _service.getCustomer360(id.trim());
      if (mounted) {
        setState(() {
          _profile = res;
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
                      'Customer 360 Journey',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Unified customer lifecycle aggregator across leads, visits, requests, communications, and notes.',
                      style: GoogleFonts.inter(fontSize: 13, color: AppTheme.textSecondary),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Search Bar
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _idController,
                      style: GoogleFonts.inter(fontSize: 13),
                      decoration: const InputDecoration(
                        hintText: 'Enter Customer UUID to look up 360 journey...',
                        border: InputBorder.none,
                        prefixIcon: Icon(LucideIcons.search, size: 16, color: Color(0xFF64748B)),
                      ),
                      onSubmitted: _searchCustomer,
                    ),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      elevation: 0,
                    ),
                    onPressed: () => _searchCustomer(_idController.text),
                    child: const Text('Lookup', style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor))
                  : _errorMessage != null
                      ? Center(child: Text(_errorMessage!, style: const TextStyle(color: Colors.red)))
                      : _profile == null
                          ? SingleChildScrollView(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Center(
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 24),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(LucideIcons.userCheck, size: 48, color: Colors.grey.shade300),
                                          const SizedBox(height: 12),
                                          Text(
                                            'Select a Customer to View Omnichannel 360 Journey',
                                            style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w700),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'Lookup via UUID above or tap any recent customer below.',
                                            style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textSecondary),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  if (_recentLeads.isNotEmpty) ...[
                                    Text(
                                      'Recent CRM Customers & Leads',
                                      style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
                                    ),
                                    const SizedBox(height: 12),
                                    ListView.separated(
                                      shrinkWrap: true,
                                      physics: const NeverScrollableScrollPhysics(),
                                      itemCount: _recentLeads.length,
                                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                                      itemBuilder: (ctx, idx) {
                                        final lead = _recentLeads[idx];
                                        return Container(
                                          padding: const EdgeInsets.all(14),
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: BorderRadius.circular(12),
                                            border: Border.all(color: const Color(0xFFE2E8F0)),
                                          ),
                                          child: Row(
                                            children: [
                                              CircleAvatar(
                                                backgroundColor: const Color(0xFF6366F1).withOpacity(0.12),
                                                child: Text(
                                                  lead.name.isNotEmpty ? lead.name[0].toUpperCase() : 'C',
                                                  style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, color: const Color(0xFF6366F1)),
                                                ),
                                              ),
                                              const SizedBox(width: 14),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text(lead.name, style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 14)),
                                                    Text('${lead.phone} • ${lead.email ?? "No email"}', style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B))),
                                                  ],
                                                ),
                                              ),
                                              ElevatedButton.icon(
                                                icon: const Icon(LucideIcons.sparkles, size: 14),
                                                label: const Text('View 360', style: TextStyle(fontSize: 12)),
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: AppTheme.primaryColor,
                                                  foregroundColor: Colors.white,
                                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                                  elevation: 0,
                                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                                ),
                                                onPressed: () {
                                                  _idController.text = lead.id;
                                                  _searchCustomer(lead.id);
                                                },
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                    ),
                                  ],
                                ],
                              ),
                            )
                          : _buildProfileContent(_profile!),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileContent(Customer360Profile p) {
    return Column(
      children: [
        // Summary Header Card
        Container(
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
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: const Color(0xFF3B82F6).withOpacity(0.12),
                    child: Text(
                      p.fullName.isNotEmpty ? p.fullName[0].toUpperCase() : 'C',
                      style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w800, color: const Color(0xFF3B82F6)),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(p.fullName, style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          if (p.phone != null) ...[
                            const Icon(LucideIcons.phone, size: 12, color: Color(0xFF64748B)),
                            const SizedBox(width: 4),
                            Text(p.phone!, style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textSecondary)),
                          ],
                          if (p.email != null) ...[
                            const SizedBox(width: 12),
                            const Icon(LucideIcons.mail, size: 12, color: Color(0xFF64748B)),
                            const SizedBox(width: 4),
                            Text(p.email!, style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textSecondary)),
                          ],
                        ],
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(height: 1, color: Color(0xFFF1F5F9)),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _metric('Total Leads', '${p.totalLeads}'),
                  _metric('Enquiries', '${p.totalEnquiries}'),
                  _metric('Site Visits', '${p.totalSiteVisits}'),
                  _metric('Service Requests', '${p.totalServiceRequests}'),
                  _metric('Total Spent', '₹${p.totalSpent.toStringAsFixed(0)}'),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

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
              Tab(text: 'Leads (${p.leads.length})'),
              Tab(text: 'Follow-ups (${p.followups.length})'),
              Tab(text: 'Tasks (${p.tasks.length})'),
              Tab(text: 'Notes (${p.notes.length})'),
            ],
          ),
        ),
        const SizedBox(height: 14),

        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              p.leads.isEmpty
                  ? Center(child: Text('No leads for this customer.', style: GoogleFonts.inter(color: AppTheme.textSecondary)))
                  : ListView.builder(
                      itemCount: p.leads.length,
                      itemBuilder: (_, i) => ListTile(
                        title: Text(p.leads[i].name),
                        subtitle: Text('Status: ${p.leads[i].status.label} • Budget: ${p.leads[i].displayBudget}'),
                      ),
                    ),
              p.followups.isEmpty
                  ? Center(child: Text('No follow-ups recorded.', style: GoogleFonts.inter(color: AppTheme.textSecondary)))
                  : ListView.builder(
                      itemCount: p.followups.length,
                      itemBuilder: (_, i) => ListTile(
                        title: Text(p.followups[i].type),
                        subtitle: Text('Scheduled: ${p.followups[i].scheduledAt.day}/${p.followups[i].scheduledAt.month} • ${p.followups[i].status.label}'),
                      ),
                    ),
              p.tasks.isEmpty
                  ? Center(child: Text('No tasks associated.', style: GoogleFonts.inter(color: AppTheme.textSecondary)))
                  : ListView.builder(
                      itemCount: p.tasks.length,
                      itemBuilder: (_, i) => ListTile(
                        title: Text(p.tasks[i].title),
                        subtitle: Text(p.tasks[i].description ?? 'Task'),
                      ),
                    ),
              p.notes.isEmpty
                  ? Center(child: Text('No notes.', style: GoogleFonts.inter(color: AppTheme.textSecondary)))
                  : ListView.builder(
                      itemCount: p.notes.length,
                      itemBuilder: (_, i) => ListTile(
                        title: Text(p.notes[i].content),
                        subtitle: Text('${p.notes[i].createdAt.day}/${p.notes[i].createdAt.month}/${p.notes[i].createdAt.year}'),
                      ),
                    ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _metric(String label, String value) {
    return Column(
      children: [
        Text(value, style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w800, color: AppTheme.textPrimary)),
        const SizedBox(height: 2),
        Text(label, style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF94A3B8))),
      ],
    );
  }
}
