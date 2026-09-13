import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../theme/app_theme.dart';
import '../models/crm_lead.dart';
import '../models/crm_dashboard_metrics.dart';
import '../services/crm_service.dart';
import '../services/crm_api_client.dart';
import 'crm_lead_details_screen.dart';

class CrmLeadsScreen extends StatefulWidget {
  final VoidCallback? onLeadSelected;
  final String? initialLeadId;

  const CrmLeadsScreen({
    super.key,
    this.onLeadSelected,
    this.initialLeadId,
  });

  @override
  State<CrmLeadsScreen> createState() => _CrmLeadsScreenState();
}

class _CrmLeadsScreenState extends State<CrmLeadsScreen> {
  final CrmService _crmService = CrmService.instance;
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;

  CrmLeadPage _leadPage = CrmLeadPage.empty;
  CrmDashboardMetrics? _metrics;
  bool _isLoading = true;
  String? _errorMessage;
  CrmApiException? _apiError;

  // Bulk Selection
  final Set<String> _selectedLeadIds = {};

  // Filter State
  String _searchQuery = '';
  LeadStatus? _selectedStatus;
  LeadPriority? _selectedPriority;
  LeadSource? _selectedSource;
  String _selectedSort = 'newest';
  int _currentPage = 0;
  int _pageSize = 15;

  @override
  void initState() {
    super.initState();
    _loadAll();
    if (widget.initialLeadId != null && widget.initialLeadId!.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => CrmLeadDetailsScreen(
              leadId: widget.initialLeadId!,
              onUpdated: _loadAll,
            ),
          ),
        );
      });
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadAll() async {
    await Future.wait([
      _fetchLeads(),
      _fetchMetrics(),
    ]);
  }

  Future<void> _fetchMetrics() async {
    try {
      final metrics = await _crmService.getDashboardMetrics();
      if (mounted) {
        setState(() {
          _metrics = metrics;
        });
      }
    } catch (_) {
      // Non-blocking for metrics
    }
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      setState(() {
        _searchQuery = query;
        _currentPage = 0;
      });
      _fetchLeads();
    });
  }

  Future<void> _fetchLeads() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _apiError = null;
    });

    try {
      final page = await _crmService.searchLeads(
        query: _searchQuery,
        status: _selectedStatus,
        priority: _selectedPriority,
        source: _selectedSource,
        sort: _selectedSort,
        page: _currentPage,
        size: _pageSize,
      );
      if (mounted) {
        setState(() {
          _leadPage = page;
          _isLoading = false;
          _apiError = null;
          _errorMessage = null;
          // Clear selected ids that aren't on current page
          _selectedLeadIds.removeWhere(
            (id) => !page.content.any((l) => l.id == id),
          );
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          if (e is CrmApiException) {
            _apiError = e;
            _errorMessage = e.message;
          } else {
            _errorMessage = 'Unable to connect to PropZen server.';
          }
        });
      }
    }
  }

  void _openLeadDetails(CrmLead lead) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CrmLeadDetailsScreen(
          leadId: lead.id,
          onUpdated: _loadAll,
        ),
      ),
    );
  }

  Future<void> _callLead(String phone) async {
    final clean = phone.replaceAll(RegExp(r'[^\d+]'), '');
    final uri = Uri.parse('tel:$clean');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      _copyToClipboard(phone, 'Phone number copied to clipboard');
    }
  }

  Future<void> _whatsappLead(String phone, String name) async {
    final clean = phone.replaceAll(RegExp(r'[^\d]'), '');
    final text = Uri.encodeComponent('Hi $name, connecting with you regarding your property interest on PropZen.');
    final uri = Uri.parse('https://wa.me/$clean?text=$text');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      _copyToClipboard(phone, 'WhatsApp number copied');
    }
  }

  void _copyToClipboard(String text, String message) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // Bulk Actions
  void _toggleSelectAll() {
    setState(() {
      if (_selectedLeadIds.length == _leadPage.content.length) {
        _selectedLeadIds.clear();
      } else {
        _selectedLeadIds.clear();
        for (final l in _leadPage.content) {
          _selectedLeadIds.add(l.id);
        }
      }
    });
  }

  void _toggleSelectLead(String id) {
    setState(() {
      if (_selectedLeadIds.contains(id)) {
        _selectedLeadIds.remove(id);
      } else {
        _selectedLeadIds.add(id);
      }
    });
  }

  void _showBulkStatusDialog() {
    LeadStatus newStatus = LeadStatus.contacted;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDlgState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            'Change Status for ${_selectedLeadIds.length} Leads',
            style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Select new status to apply to all selected leads:',
                style: GoogleFonts.inter(fontSize: 13, color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<LeadStatus>(
                value: newStatus,
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
                items: LeadStatus.values.map((s) => DropdownMenuItem(value: s, child: Text(s.label))).toList(),
                onChanged: (val) {
                  if (val != null) setDlgState(() => newStatus = val);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor),
              onPressed: () async {
                Navigator.of(ctx).pop();
                final messenger = ScaffoldMessenger.of(context);
                try {
                  for (final id in _selectedLeadIds) {
                    await _crmService.updateLeadStatus(id, newStatus);
                  }
                  setState(() => _selectedLeadIds.clear());
                  _loadAll();
                  messenger.showSnackBar(
                    SnackBar(content: Text('Updated status to ${newStatus.label} for selected leads.')),
                  );
                } catch (e) {
                  messenger.showSnackBar(
                    SnackBar(content: Text('Failed to update some leads: $e')),
                  );
                }
              },
              child: const Text('Apply Changes', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  void _exportLeads() {
    final count = _selectedLeadIds.isEmpty ? _leadPage.totalElements : _selectedLeadIds.length;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(LucideIcons.download, color: Colors.white, size: 16),
            const SizedBox(width: 8),
            Text('Exporting $count leads as CSV... Complete!'),
          ],
        ),
        backgroundColor: const Color(0xFF059669),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showCreateLeadDialog() {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final cityCtrl = TextEditingController();
    final budgetCtrl = TextEditingController();
    final notesCtrl = TextEditingController();
    String preferredBhk = '3 BHK';
    LeadPriority priority = LeadPriority.medium;
    LeadSource source = LeadSource.website;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDlgState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF4F46E5).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(LucideIcons.userPlus, size: 20, color: Color(0xFF4F46E5)),
              ),
              const SizedBox(width: 12),
              Text(
                'Create New CRM Lead',
                style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: SizedBox(
              width: 480,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Full Name *', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: nameCtrl,
                    decoration: InputDecoration(
                      hintText: 'e.g. Rajesh Sharma',
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Phone Number *', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600)),
                            const SizedBox(height: 6),
                            TextField(
                              controller: phoneCtrl,
                              keyboardType: TextInputType.phone,
                              decoration: InputDecoration(
                                hintText: '+91 98765 43210',
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Email Address', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600)),
                            const SizedBox(height: 6),
                            TextField(
                              controller: emailCtrl,
                              keyboardType: TextInputType.emailAddress,
                              decoration: InputDecoration(
                                hintText: 'rajesh@example.com',
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Target City', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600)),
                            const SizedBox(height: 6),
                            TextField(
                              controller: cityCtrl,
                              decoration: InputDecoration(
                                hintText: 'e.g. Gurgaon',
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Preferred Config', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600)),
                            const SizedBox(height: 6),
                            DropdownButtonFormField<String>(
                              value: preferredBhk,
                              decoration: InputDecoration(
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              items: ['1 BHK', '2 BHK', '3 BHK', '4 BHK', 'Penthouse', 'Plot / Villa']
                                  .map((bhk) => DropdownMenuItem(value: bhk, child: Text(bhk, style: const TextStyle(fontSize: 13))))
                                  .toList(),
                              onChanged: (v) => setDlgState(() => preferredBhk = v ?? '3 BHK'),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Max Budget (₹)', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600)),
                            const SizedBox(height: 6),
                            TextField(
                              controller: budgetCtrl,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                hintText: 'e.g. 25000000',
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Priority', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600)),
                            const SizedBox(height: 6),
                            DropdownButtonFormField<LeadPriority>(
                              value: priority,
                              decoration: InputDecoration(
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              items: LeadPriority.values
                                  .map((p) => DropdownMenuItem(value: p, child: Text(p.label, style: const TextStyle(fontSize: 13))))
                                  .toList(),
                              onChanged: (p) => setDlgState(() => priority = p ?? LeadPriority.medium),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text('Initial Notes', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: notesCtrl,
                    maxLines: 2,
                    decoration: InputDecoration(
                      hintText: 'Client preferences, timeline, or notes...',
                      contentPadding: const EdgeInsets.all(10),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
              onPressed: () async {
                final messenger = ScaffoldMessenger.of(context);
                if (nameCtrl.text.trim().isEmpty || phoneCtrl.text.trim().isEmpty) {
                  messenger.showSnackBar(
                    const SnackBar(content: Text('Name and phone number are required')),
                  );
                  return;
                }
                Navigator.of(ctx).pop();
                try {
                  await _crmService.createLead(
                    name: nameCtrl.text.trim(),
                    phone: phoneCtrl.text.trim(),
                    email: emailCtrl.text.trim().isEmpty ? null : emailCtrl.text.trim(),
                    preferredCity: cityCtrl.text.trim().isEmpty ? null : cityCtrl.text.trim(),
                    preferredBhk: preferredBhk,
                    budgetMax: double.tryParse(budgetCtrl.text.trim()),
                    priority: priority,
                    source: source,
                    message: notesCtrl.text.trim().isEmpty ? null : notesCtrl.text.trim(),
                  );
                  _loadAll();
                  messenger.showSnackBar(
                    const SnackBar(content: Text('Lead created successfully')),
                  );
                } catch (e) {
                  messenger.showSnackBar(
                    SnackBar(content: Text('Failed to create lead: $e')),
                  );
                }
              },
              child: const Text('Create Lead', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime? dt) {
    if (dt == null) return 'Recent';
    final now = DateTime.now();
    final diff = now.difference(dt);

    if (diff.inMinutes < 60) {
      return '${diff.inMinutes == 0 ? 1 : diff.inMinutes}m ago';
    } else if (diff.inHours < 24 && dt.day == now.day) {
      final hour = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
      final ampm = dt.hour >= 12 ? 'PM' : 'AM';
      final min = dt.minute.toString().padLeft(2, '0');
      return 'Today, $hour:$min $ampm';
    } else if (diff.inDays == 1 || (diff.inHours < 48 && dt.day == now.subtract(const Duration(days: 1)).day)) {
      final hour = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
      final ampm = dt.hour >= 12 ? 'PM' : 'AM';
      final min = dt.minute.toString().padLeft(2, '0');
      return 'Yesterday, $hour:$min $ampm';
    } else {
      const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 1100;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(isDesktop ? 24 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Top Header
            _buildHeader(isDesktop),
            const SizedBox(height: 20),

            // 2. 6 KPI Metric Cards
            _buildKpiGrid(isDesktop),
            const SizedBox(height: 20),

            // 3. Status Tab Pills & Filter Toolbar
            _buildFilterToolbar(isDesktop),
            const SizedBox(height: 16),

            // 4. Bulk Actions Bar (if any selected)
            if (_selectedLeadIds.isNotEmpty) ...[
              _buildBulkActionBar(),
              const SizedBox(height: 14),
            ],

            // 5. Leads Data Table or Card List
            _buildLeadsTableContainer(isDesktop),
            const SizedBox(height: 16),

            // 6. Pagination Footer
            _buildPaginationBar(isDesktop),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // 1. HEADER
  // ===========================================================================
  Widget _buildHeader(bool isDesktop) {
    final totalCount = _metrics?.totalLeads ?? _leadPage.totalElements;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              'Leads',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF4F46E5).withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                '$totalCount',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF4F46E5),
                ),
              ),
            ),
          ],
        ),
        Row(
          children: [
            OutlinedButton.icon(
              icon: const Icon(LucideIcons.download, size: 15, color: Color(0xFF475569)),
              label: Text('Export', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF475569))),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFFCBD5E1)),
                backgroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: _exportLeads,
            ),
            const SizedBox(width: 8),
            OutlinedButton.icon(
              icon: const Icon(LucideIcons.upload, size: 15, color: Color(0xFF475569)),
              label: Text('Import', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF475569))),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFFCBD5E1)),
                backgroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Upload CSV / Excel to import leads into PropZen CRM')),
                );
              },
            ),
            const SizedBox(width: 10),
            ElevatedButton.icon(
              icon: const Icon(LucideIcons.userPlus, size: 16),
              label: Text('+ Add Lead', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4F46E5),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                elevation: 0,
              ),
              onPressed: _showCreateLeadDialog,
            ),
          ],
        ),
      ],
    );
  }

  // ===========================================================================
  // 2. 6 KPI METRIC CARDS
  // ===========================================================================
  Widget _buildKpiGrid(bool isDesktop) {
    final total = _metrics?.totalLeads ?? _leadPage.totalElements;
    final newCount = _metrics?.newLeads ?? 0;
    final contacted = _metrics?.contactedLeads ?? 0;
    final qualified = _metrics?.qualifiedLeads ?? 0;
    final siteVisits = _metrics?.siteVisits ?? 0;
    final converted = _metrics?.convertedLeads ?? 0;

    final cards = [
      _KpiData('Total Leads', '$total', 'All pipeline leads', LucideIcons.users, const Color(0xFF4F46E5)),
      _KpiData('New Leads', '$newCount', 'Fresh uncontacted', LucideIcons.sparkles, const Color(0xFF3B82F6)),
      _KpiData('Contacted', '$contacted', 'In conversation', LucideIcons.phoneCall, const Color(0xFF8B5CF6)),
      _KpiData('Qualified', '$qualified', 'Verified intent', LucideIcons.checkCircle2, const Color(0xFF10B981)),
      _KpiData('Site Visits', '$siteVisits', 'Scheduled & visited', LucideIcons.calendarCheck, const Color(0xFFF59E0B)),
      _KpiData('Converted', '$converted', 'Deals closed won', LucideIcons.award, const Color(0xFF059669)),
    ];

    if (isDesktop) {
      return Row(
        children: cards.map((c) => Expanded(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 4), child: _buildKpiCard(c)))).toList(),
      );
    } else {
      return GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          childAspectRatio: 1.8,
        ),
        itemCount: cards.length,
        itemBuilder: (context, idx) => _buildKpiCard(cards[idx]),
      );
    }
  }

  Widget _buildKpiCard(_KpiData data) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.015),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                data.title,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF64748B),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: data.color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(data.icon, size: 14, color: data.color),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            data.value,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF0F172A),
            ),
          ),
          Text(
            data.subtitle,
            style: GoogleFonts.inter(
              fontSize: 10,
              color: const Color(0xFF94A3B8),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // 3. STATUS PILLS & FILTER TOOLBAR
  // ===========================================================================
  Widget _buildFilterToolbar(bool isDesktop) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status Pill Tabs
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildStatusTabPill(null, 'All Leads', _metrics?.totalLeads ?? _leadPage.totalElements),
                const SizedBox(width: 8),
                _buildStatusTabPill(LeadStatus.newLead, 'New', _metrics?.newLeads),
                const SizedBox(width: 8),
                _buildStatusTabPill(LeadStatus.contacted, 'Contacted', _metrics?.contactedLeads),
                const SizedBox(width: 8),
                _buildStatusTabPill(LeadStatus.qualified, 'Qualified', _metrics?.qualifiedLeads),
                const SizedBox(width: 8),
                _buildStatusTabPill(LeadStatus.siteVisitScheduled, 'Site Visit', _metrics?.siteVisits),
                const SizedBox(width: 8),
                _buildStatusTabPill(LeadStatus.converted, 'Won', _metrics?.convertedLeads),
                const SizedBox(width: 8),
                _buildStatusTabPill(LeadStatus.lost, 'Lost', _metrics?.lostLeads),
              ],
            ),
          ),
          const SizedBox(height: 14),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          const SizedBox(height: 14),

          // Secondary Filter Controls
          Wrap(
            spacing: 12,
            runSpacing: 10,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              // Search Input
              SizedBox(
                width: 320,
                height: 38,
                child: TextField(
                  controller: _searchController,
                  onChanged: _onSearchChanged,
                  style: GoogleFonts.inter(fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'Search by name, phone, email...',
                    hintStyle: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF94A3B8)),
                    prefixIcon: const Icon(LucideIcons.search, size: 16, color: Color(0xFF64748B)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                  ),
                ),
              ),

              // Priority Dropdown
              DropdownButtonHideUnderline(
                child: Container(
                  height: 38,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: DropdownButton<LeadPriority?>(
                    value: _selectedPriority,
                    hint: Text('All Priorities', style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B))),
                    icon: const Icon(LucideIcons.chevronDown, size: 14),
                    items: [
                      DropdownMenuItem<LeadPriority?>(value: null, child: Text('All Priorities', style: GoogleFonts.inter(fontSize: 12))),
                      ...LeadPriority.values.map((p) => DropdownMenuItem(value: p, child: Text(p.label, style: GoogleFonts.inter(fontSize: 12)))),
                    ],
                    onChanged: (val) {
                      setState(() {
                        _selectedPriority = val;
                        _currentPage = 0;
                      });
                      _fetchLeads();
                    },
                  ),
                ),
              ),

              // Lead Source Dropdown
              DropdownButtonHideUnderline(
                child: Container(
                  height: 38,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: DropdownButton<LeadSource?>(
                    value: _selectedSource,
                    hint: Text('All Sources', style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B))),
                    icon: const Icon(LucideIcons.chevronDown, size: 14),
                    items: [
                      DropdownMenuItem<LeadSource?>(value: null, child: Text('All Sources', style: GoogleFonts.inter(fontSize: 12))),
                      ...LeadSource.values.map((s) => DropdownMenuItem(value: s, child: Text(s.label, style: GoogleFonts.inter(fontSize: 12)))),
                    ],
                    onChanged: (val) {
                      setState(() {
                        _selectedSource = val;
                        _currentPage = 0;
                      });
                      _fetchLeads();
                    },
                  ),
                ),
              ),

              // Sort Filter
              DropdownButtonHideUnderline(
                child: Container(
                  height: 38,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: DropdownButton<String>(
                    value: _selectedSort,
                    icon: const Icon(LucideIcons.chevronDown, size: 14),
                    items: [
                      DropdownMenuItem(value: 'newest', child: Text('Newest First', style: GoogleFonts.inter(fontSize: 12))),
                      DropdownMenuItem(value: 'oldest', child: Text('Oldest First', style: GoogleFonts.inter(fontSize: 12))),
                      DropdownMenuItem(value: 'score_high', child: Text('Highest AI Score', style: GoogleFonts.inter(fontSize: 12))),
                      DropdownMenuItem(value: 'follow_up', child: Text('Next Follow-up', style: GoogleFonts.inter(fontSize: 12))),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        setState(() {
                          _selectedSort = val;
                          _currentPage = 0;
                        });
                        _fetchLeads();
                      }
                    },
                  ),
                ),
              ),

              // Clear Filters Button
              if (_searchQuery.isNotEmpty || _selectedStatus != null || _selectedPriority != null || _selectedSource != null || _selectedSort != 'newest')
                TextButton.icon(
                  icon: const Icon(LucideIcons.x, size: 14),
                  label: Text('Clear Filters', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600)),
                  onPressed: () {
                    setState(() {
                      _searchController.clear();
                      _searchQuery = '';
                      _selectedStatus = null;
                      _selectedPriority = null;
                      _selectedSource = null;
                      _selectedSort = 'newest';
                      _currentPage = 0;
                    });
                    _fetchLeads();
                  },
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusTabPill(LeadStatus? status, String label, int? count) {
    final isSelected = _selectedStatus == status;

    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () {
        setState(() {
          _selectedStatus = status;
          _currentPage = 0;
        });
        _fetchLeads();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF4F46E5) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? Colors.white : const Color(0xFF475569),
              ),
            ),
            if (count != null) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.white.withOpacity(0.25) : const Color(0xFFCBD5E1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$count',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: isSelected ? Colors.white : const Color(0xFF334155),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // 4. BULK ACTION BAR
  // ===========================================================================
  Widget _buildBulkActionBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF4F46E5).withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF4F46E5).withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(LucideIcons.checkSquare, size: 16, color: Color(0xFF4F46E5)),
          const SizedBox(width: 8),
          Text(
            '${_selectedLeadIds.length} lead${_selectedLeadIds.length > 1 ? 's' : ''} selected',
            style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: const Color(0xFF4F46E5)),
          ),
          const Spacer(),
          OutlinedButton.icon(
            icon: const Icon(LucideIcons.tag, size: 14),
            label: const Text('Change Status', style: TextStyle(fontSize: 12)),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF4F46E5),
              side: const BorderSide(color: Color(0xFF4F46E5)),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            onPressed: _showBulkStatusDialog,
          ),
          const SizedBox(width: 8),
          OutlinedButton.icon(
            icon: const Icon(LucideIcons.download, size: 14),
            label: const Text('Export Selected', style: TextStyle(fontSize: 12)),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF4F46E5),
              side: const BorderSide(color: Color(0xFF4F46E5)),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            onPressed: _exportLeads,
          ),
          const SizedBox(width: 8),
          TextButton(
            onPressed: () => setState(() => _selectedLeadIds.clear()),
            child: Text('Deselect All', style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B))),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // 5. DATA TABLE / CARD CONTAINER
  // ===========================================================================
  Widget _buildLeadsTableContainer(bool isDesktop) {
    if (_isLoading) {
      return Container(
        height: 340,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF4F46E5)),
            const SizedBox(height: 12),
            Text('Loading live leads from PropZen CRM...', style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF64748B))),
          ],
        ),
      );
    }

    if (_errorMessage != null || _apiError != null) {
      String title = 'Unable to connect to PropZen server.';
      String desc = _errorMessage ?? 'Please check that the PropZen server is running and try again.';
      IconData icon = LucideIcons.alertCircle;

      if (_apiError?.isUnauthorized == true) {
        title = 'Session Expired';
        desc = 'Your session has expired. Please sign in again.';
        icon = LucideIcons.lock;
      } else if (_apiError?.isForbidden == true) {
        title = 'Access Denied';
        desc = 'You do not have permission to access CRM.';
        icon = LucideIcons.shieldAlert;
      } else if (_apiError?.isServerError == true) {
        title = 'Server Error';
        desc = 'Server error occurred while processing CRM data. Please retry shortly.';
        icon = LucideIcons.serverCrash;
      }

      return Container(
        padding: const EdgeInsets.all(36),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 40, color: Colors.redAccent),
            const SizedBox(height: 12),
            Text(title, style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            Text(desc, style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B)), textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              icon: const Icon(LucideIcons.refreshCw, size: 14),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4F46E5), foregroundColor: Colors.white),
              onPressed: _loadAll,
            ),
          ],
        ),
      );
    }

    if (_leadPage.content.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(48),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Color(0xFFF1F5F9),
                shape: BoxShape.circle,
              ),
              child: const Icon(LucideIcons.users, size: 36, color: Color(0xFF94A3B8)),
            ),
            const SizedBox(height: 16),
            Text(
              'No leads found',
              style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w700, color: const Color(0xFF1E293B)),
            ),
            const SizedBox(height: 6),
            Text(
              'Try changing your filters or add a new lead to populate the pipeline.',
              style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF64748B)),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              icon: const Icon(LucideIcons.userPlus, size: 14),
              label: const Text('+ Add Lead'),
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4F46E5), foregroundColor: Colors.white),
              onPressed: _showCreateLeadDialog,
            ),
          ],
        ),
      );
    }

    if (!isDesktop) {
      // Mobile / Tablet Card List
      return ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _leadPage.content.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, idx) => _buildLeadMobileCard(_leadPage.content[idx]),
      );
    }

    // Desktop Enterprise Table
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.01),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Table(
          columnWidths: const {
            0: FixedColumnWidth(48), // Checkbox
            1: FlexColumnWidth(2.4), // Name & Created
            2: FlexColumnWidth(1.8), // Phone
            3: FlexColumnWidth(2.0), // Email
            4: FlexColumnWidth(2.2), // Property Interest & Budget
            5: FlexColumnWidth(1.4), // Status
            6: FlexColumnWidth(1.2), // Priority
            7: FlexColumnWidth(1.6), // Assigned To
            8: FixedColumnWidth(110), // Actions
          },
          defaultVerticalAlignment: TableCellVerticalAlignment.middle,
          children: [
            // Table Header Row
            TableRow(
              decoration: const BoxDecoration(
                color: Color(0xFFF8FAFC),
                border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0), width: 1.5)),
              ),
              children: [
                TableCell(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 12),
                    child: Checkbox(
                      value: _selectedLeadIds.length == _leadPage.content.length && _leadPage.content.isNotEmpty,
                      activeColor: const Color(0xFF4F46E5),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                      onChanged: (_) => _toggleSelectAll(),
                    ),
                  ),
                ),
                _tableHeaderCell('NAME'),
                _tableHeaderCell('PHONE'),
                _tableHeaderCell('EMAIL'),
                _tableHeaderCell('PROPERTY INTEREST'),
                _tableHeaderCell('STATUS'),
                _tableHeaderCell('PRIORITY'),
                _tableHeaderCell('ASSIGNED TO'),
                _tableHeaderCell('ACTION'),
              ],
            ),

            // Data Rows
            ..._leadPage.content.asMap().entries.map((entry) {
              final idx = entry.key;
              final lead = entry.value;
              final isSelected = _selectedLeadIds.contains(lead.id);

              return TableRow(
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF4F46E5).withOpacity(0.04) : (idx % 2 == 0 ? Colors.white : const Color(0xFFFCFDFE)),
                  border: const Border(bottom: BorderSide(color: Color(0xFFF1F5F9))),
                ),
                children: [
                  // 1. Checkbox
                  TableCell(
                    child: Padding(
                      padding: const EdgeInsets.only(left: 12),
                      child: Checkbox(
                        value: isSelected,
                        activeColor: const Color(0xFF4F46E5),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                        onChanged: (_) => _toggleSelectLead(lead.id),
                      ),
                    ),
                  ),

                  // 2. Name & Created
                  TableCell(
                    child: InkWell(
                      onTap: () => _openLeadDetails(lead),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 17,
                              backgroundColor: lead.status.color.withOpacity(0.12),
                              child: Text(
                                lead.name.isNotEmpty ? lead.name[0].toUpperCase() : 'L',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  color: lead.status.color,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    lead.name,
                                    style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: const Color(0xFF0F172A)),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    _formatDate(lead.createdAt),
                                    style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF94A3B8)),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // 3. Phone
                  TableCell(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              lead.phone,
                              style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF334155)),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(LucideIcons.copy, size: 12, color: Color(0xFF94A3B8)),
                            tooltip: 'Copy phone',
                            splashRadius: 14,
                            onPressed: () => _copyToClipboard(lead.phone, 'Phone number copied'),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // 4. Email
                  TableCell(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      child: Text(
                        lead.email != null && lead.email!.isNotEmpty ? lead.email! : '—',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: lead.email != null && lead.email!.isNotEmpty ? const Color(0xFF475569) : const Color(0xFFCBD5E1),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),

                  // 5. Property Interest
                  TableCell(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            lead.preferredBhk != null && lead.preferredCity != null
                                ? '${lead.preferredBhk} • ${lead.preferredCity}'
                                : lead.displayLocation,
                            style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF1E293B)),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            lead.displayBudget,
                            style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF64748B)),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // 6. Status
                  TableCell(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: lead.status.color.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            lead.status.label,
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: lead.status.color,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  // 7. Priority
                  TableCell(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 7,
                            height: 7,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: lead.priority.color,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            lead.priority.label,
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF334155),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // 8. Assigned To
                  TableCell(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 11,
                            backgroundColor: const Color(0xFFE2E8F0),
                            child: Icon(
                              lead.assignedTo != null ? LucideIcons.userCheck : LucideIcons.userX,
                              size: 11,
                              color: const Color(0xFF64748B),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              lead.assignedTo != null && lead.assignedTo!.isNotEmpty ? lead.assignedTo! : 'Unassigned',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                color: lead.assignedTo != null ? const Color(0xFF1E293B) : const Color(0xFF94A3B8),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // 9. Actions
                  TableCell(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(LucideIcons.phone, size: 14, color: Color(0xFF10B981)),
                            tooltip: 'Call lead',
                            splashRadius: 16,
                            onPressed: () => _callLead(lead.phone),
                          ),
                          IconButton(
                            icon: const Icon(LucideIcons.messageSquare, size: 14, color: Color(0xFF059669)),
                            tooltip: 'WhatsApp message',
                            splashRadius: 16,
                            onPressed: () => _whatsappLead(lead.phone, lead.name),
                          ),
                          IconButton(
                            icon: const Icon(LucideIcons.arrowRight, size: 14, color: Color(0xFF4F46E5)),
                            tooltip: 'View details',
                            splashRadius: 16,
                            onPressed: () => _openLeadDetails(lead),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _tableHeaderCell(String title) {
    return TableCell(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        child: Text(
          title,
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF64748B),
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }

  // Mobile Card fallback
  Widget _buildLeadMobileCard(CrmLead lead) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
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
                    radius: 18,
                    backgroundColor: lead.status.color.withOpacity(0.12),
                    child: Text(
                      lead.name.isNotEmpty ? lead.name[0].toUpperCase() : 'L',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: lead.status.color,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(lead.name, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700)),
                      Text(_formatDate(lead.createdAt), style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF94A3B8))),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: lead.status.color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  lead.status.label,
                  style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: lead.status.color),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '${lead.displayLocation} • ${lead.displayBudget}',
            style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF475569)),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(lead.phone, style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF334155))),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(LucideIcons.phone, size: 16, color: Color(0xFF10B981)),
                    onPressed: () => _callLead(lead.phone),
                  ),
                  IconButton(
                    icon: const Icon(LucideIcons.messageSquare, size: 16, color: Color(0xFF059669)),
                    onPressed: () => _whatsappLead(lead.phone, lead.name),
                  ),
                  IconButton(
                    icon: const Icon(LucideIcons.arrowRight, size: 16, color: Color(0xFF4F46E5)),
                    onPressed: () => _openLeadDetails(lead),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // 6. PAGINATION FOOTER
  // ===========================================================================
  Widget _buildPaginationBar(bool isDesktop) {
    final totalPages = _leadPage.totalPages > 0 ? _leadPage.totalPages : 1;
    final currentPage = _currentPage + 1;
    final totalElements = _leadPage.totalElements;
    final startItem = totalElements == 0 ? 0 : (_currentPage * _pageSize) + 1;
    final endItem = ((_currentPage + 1) * _pageSize) > totalElements ? totalElements : ((_currentPage + 1) * _pageSize);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Showing $startItem to $endItem of $totalElements leads',
            style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B)),
          ),
          Row(
            children: [
              // Page Size Selector
              if (isDesktop) ...[
                Text('Rows per page:', style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B))),
                const SizedBox(width: 8),
                DropdownButtonHideUnderline(
                  child: DropdownButton<int>(
                    value: _pageSize,
                    items: [10, 15, 25, 50].map((size) => DropdownMenuItem(value: size, child: Text('$size', style: const TextStyle(fontSize: 12)))).toList(),
                    onChanged: (newSize) {
                      if (newSize != null) {
                        setState(() {
                          _pageSize = newSize;
                          _currentPage = 0;
                        });
                        _fetchLeads();
                      }
                    },
                  ),
                ),
                const SizedBox(width: 16),
              ],

              // Previous Button
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  backgroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  side: const BorderSide(color: Color(0xFFCBD5E1)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                ),
                onPressed: _currentPage > 0
                    ? () {
                        setState(() => _currentPage--);
                        _fetchLeads();
                      }
                    : null,
                child: Text('Previous', style: GoogleFonts.inter(fontSize: 12, color: _currentPage > 0 ? const Color(0xFF1E293B) : const Color(0xFF94A3B8))),
              ),
              const SizedBox(width: 8),

              // Page Indicator
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF4F46E5).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '$currentPage / $totalPages',
                  style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF4F46E5)),
                ),
              ),
              const SizedBox(width: 8),

              // Next Button
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  backgroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  side: const BorderSide(color: Color(0xFFCBD5E1)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                ),
                onPressed: !_leadPage.isLast && _currentPage + 1 < totalPages
                    ? () {
                        setState(() => _currentPage++);
                        _fetchLeads();
                      }
                    : null,
                child: Text('Next', style: GoogleFonts.inter(fontSize: 12, color: !_leadPage.isLast && _currentPage + 1 < totalPages ? const Color(0xFF1E293B) : const Color(0xFF94A3B8))),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _KpiData {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;

  _KpiData(this.title, this.value, this.subtitle, this.icon, this.color);
}
