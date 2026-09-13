import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../crm/services/crm_api_client.dart';
import '../theme/app_theme.dart';
import '../widgets/empty_state_view.dart';

class CustomerServiceLead {
  final String id;
  final String leadNumber;
  final String serviceCategory;
  final String assignmentStatus;
  final String? assignedPartnerId;
  final String? assignedPartnerName;
  final String status;
  final String? stage;
  final String? name;
  final String? phone;
  final String? email;
  final String? message;
  final String? preferredCity;
  final DateTime? createdAt;

  CustomerServiceLead({
    required this.id,
    required this.leadNumber,
    required this.serviceCategory,
    required this.assignmentStatus,
    this.assignedPartnerId,
    this.assignedPartnerName,
    required this.status,
    this.stage,
    this.name,
    this.phone,
    this.email,
    this.message,
    this.preferredCity,
    this.createdAt,
  });

  factory CustomerServiceLead.fromJson(Map<String, dynamic> json) {
    DateTime? parsedDate;
    if (json['createdAt'] != null) {
      try {
        parsedDate = DateTime.parse(json['createdAt'].toString());
      } catch (_) {}
    }

    return CustomerServiceLead(
      id: json['id']?.toString() ?? '',
      leadNumber: json['leadNumber']?.toString() ?? 'REQ-${DateTime.now().millisecondsSinceEpoch}',
      serviceCategory: json['serviceCategory']?.toString() ?? 'GENERAL',
      assignmentStatus: json['assignmentStatus']?.toString().toUpperCase() ?? 'UNASSIGNED',
      assignedPartnerId: json['assignedPartnerId']?.toString(),
      assignedPartnerName: json['assignedPartnerName']?.toString(),
      status: json['status']?.toString().toUpperCase() ?? 'NEW',
      stage: json['stage']?.toString(),
      name: json['name']?.toString(),
      phone: json['phone']?.toString(),
      email: json['email']?.toString(),
      message: json['message']?.toString(),
      preferredCity: json['preferredCity']?.toString(),
      createdAt: parsedDate,
    );
  }

  bool get isAssigned => assignmentStatus == 'ASSIGNED' && (assignedPartnerName != null && assignedPartnerName!.isNotEmpty);
}

class MyServiceRequestsScreen extends StatefulWidget {
  const MyServiceRequestsScreen({super.key});

  @override
  State<MyServiceRequestsScreen> createState() => _MyServiceRequestsScreenState();
}

class _MyServiceRequestsScreenState extends State<MyServiceRequestsScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  List<CustomerServiceLead> _leads = [];
  String _selectedFilter = 'ALL';

  @override
  void initState() {
    super.initState();
    _fetchMyServiceRequests();
  }

  Future<void> _fetchMyServiceRequests() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final res = await CrmApiClient.instance.get('/api/v1/crm/leads/my');
      final List<CustomerServiceLead> parsed = [];
      if (res is List) {
        for (final item in res) {
          if (item is Map<String, dynamic>) {
            parsed.add(CustomerServiceLead.fromJson(item));
          }
        }
      }
      setState(() {
        _leads = parsed;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Could not load service requests: $e';
        _isLoading = false;
      });
    }
  }

  List<CustomerServiceLead> get _filteredLeads {
    if (_selectedFilter == 'ALL') return _leads;
    if (_selectedFilter == 'ASSIGNED') {
      return _leads.where((l) => l.isAssigned).toList();
    }
    if (_selectedFilter == 'MATCHING') {
      return _leads.where((l) => !l.isAssigned).toList();
    }
    if (_selectedFilter == 'COMPLETED') {
      return _leads.where((l) => l.status == 'COMPLETED' || l.status == 'CONVERTED').toList();
    }
    return _leads;
  }

  String _formatDate(DateTime dt) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final local = dt.toLocal();
    final day = local.day.toString().padLeft(2, '0');
    final month = months[local.month - 1];
    final year = local.year;
    final hour = local.hour % 12 == 0 ? 12 : local.hour % 12;
    final min = local.minute.toString().padLeft(2, '0');
    final ampm = local.hour >= 12 ? 'PM' : 'AM';
    return '$day $month $year, $hour:$min $ampm';
  }

  String _formatCategory(String raw) {
    switch (raw.toUpperCase()) {
      case 'HOME_LOAN':
        return 'Home Loan & Financing';
      case 'HOME_DESIGN':
        return 'Interior & Architectural Design';
      case 'VASTU_CONSULTATION':
        return 'Vastu Consultation';
      case 'LEGAL_VERIFICATION':
        return 'Legal & Title Verification';
      case 'CONSTRUCTION':
        return 'Civil & Construction';
      case 'VIRTUAL_3D_TOUR':
        return 'Virtual 3D & Drone Tour';
      default:
        return raw.replaceAll('_', ' ').toLowerCase().split(' ').map((s) => s.isNotEmpty ? s[0].toUpperCase() + s.substring(1) : '').join(' ');
    }
  }

  IconData _getCategoryIcon(String raw) {
    switch (raw.toUpperCase()) {
      case 'HOME_LOAN':
        return LucideIcons.landmark;
      case 'HOME_DESIGN':
        return LucideIcons.palette;
      case 'VASTU_CONSULTATION':
        return LucideIcons.compass;
      case 'LEGAL_VERIFICATION':
        return LucideIcons.shieldCheck;
      case 'CONSTRUCTION':
        return LucideIcons.hardHat;
      case 'VIRTUAL_3D_TOUR':
        return LucideIcons.box;
      default:
        return LucideIcons.briefcase;
    }
  }

  Color _getCategoryColor(String raw) {
    switch (raw.toUpperCase()) {
      case 'HOME_LOAN':
        return const Color(0xFF0284C7); // Sky Blue
      case 'HOME_DESIGN':
        return const Color(0xFF7C3AED); // Violet
      case 'VASTU_CONSULTATION':
        return const Color(0xFFEA580C); // Orange
      case 'LEGAL_VERIFICATION':
        return const Color(0xFF059669); // Emerald
      case 'CONSTRUCTION':
        return const Color(0xFFD97706); // Amber
      case 'VIRTUAL_3D_TOUR':
        return const Color(0xFFDB2777); // Pink
      default:
        return const Color(0xFF475569);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.pageBackground,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppTheme.textPrimary),
        title: Text(
          'My Service Requests',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.refreshCw, size: 20),
            tooltip: 'Refresh',
            onPressed: _fetchMyServiceRequests,
          ),
        ],
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: AppTheme.borderLight),
        ),
      ),
      body: Column(
        children: [
          // Filter Chips Row
          _buildFilterBar(),

          // Main Body Area
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryViolet))
                : _errorMessage != null
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(LucideIcons.alertCircle, size: 40, color: AppTheme.coralDanger),
                              const SizedBox(height: 12),
                              Text(
                                _errorMessage!,
                                textAlign: TextAlign.center,
                                style: GoogleFonts.inter(fontSize: 14, color: AppTheme.textSecondary),
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton.icon(
                                onPressed: _fetchMyServiceRequests,
                                icon: const Icon(LucideIcons.rotateCcw, size: 16),
                                label: const Text('Try Again'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.primaryViolet,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : _filteredLeads.isEmpty
                        ? RefreshIndicator(
                            onRefresh: _fetchMyServiceRequests,
                            child: SingleChildScrollView(
                              physics: const AlwaysScrollableScrollPhysics(),
                              child: Padding(
                                padding: const EdgeInsets.only(top: 80.0),
                                child: EmptyStateView(
                                  title: _leads.isEmpty ? 'No service requests yet' : 'No matches found',
                                  message: _leads.isEmpty
                                      ? 'When you request a home loan, design consultation, legal check, or construction quote, track your partner assignment and status here in real-time.'
                                      : 'No requests matched the "$_selectedFilter" filter.',
                                  icon: LucideIcons.briefcase,
                                ),
                              ),
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: _fetchMyServiceRequests,
                            child: ListView.separated(
                              physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                              padding: const EdgeInsets.all(16),
                              itemCount: _filteredLeads.length,
                              separatorBuilder: (ctx, i) => const SizedBox(height: 12),
                              itemBuilder: (ctx, i) => _buildLeadCard(_filteredLeads[i]),
                            ),
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar() {
    final filters = [
      {'key': 'ALL', 'label': 'All (${_leads.length})'},
      {'key': 'MATCHING', 'label': 'Matching (${_leads.where((l) => !l.isAssigned).length})'},
      {'key': 'ASSIGNED', 'label': 'Assigned (${_leads.where((l) => l.isAssigned).length})'},
      {'key': 'COMPLETED', 'label': 'Completed (${_leads.where((l) => l.status == 'COMPLETED' || l.status == 'CONVERTED').length})'},
    ];

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Row(
          children: filters.map((f) {
            final isSelected = _selectedFilter == f['key'];
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                selected: isSelected,
                label: Text(
                  f['label'] as String,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: isSelected ? AppTheme.primaryViolet : AppTheme.textSecondary,
                  ),
                ),
                backgroundColor: AppTheme.surfaceSubtle,
                selectedColor: AppTheme.primaryViolet.withOpacity(0.12),
                checkmarkColor: AppTheme.primaryViolet,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(
                    color: isSelected ? AppTheme.primaryViolet : AppTheme.borderLight,
                  ),
                ),
                onSelected: (val) {
                  setState(() {
                    _selectedFilter = f['key'] as String;
                  });
                },
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildLeadCard(CustomerServiceLead lead) {
    final catColor = _getCategoryColor(lead.serviceCategory);
    final catIcon = _getCategoryIcon(lead.serviceCategory);

    return InkWell(
      onTap: () => _showLeadDetailSheet(lead),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.borderLight),
          boxShadow: const [
            BoxShadow(
              color: Color(0x040F172A),
              blurRadius: 10,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row: Category Badge & Assignment Badge
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: catColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: catColor.withOpacity(0.2)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(catIcon, size: 14, color: catColor),
                      const SizedBox(width: 6),
                      Text(
                        _formatCategory(lead.serviceCategory),
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: catColor,
                        ),
                      ),
                    ],
                  ),
                ),
                _buildAssignmentBadge(lead),
              ],
            ),
            const SizedBox(height: 12),

            // Lead Reference & Date
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  lead.leadNumber,
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
                if (lead.createdAt != null)
                  Text(
                    _formatDate(lead.createdAt!),
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: AppTheme.textMuted,
                    ),
                  ),
              ],
            ),

            if (lead.message != null && lead.message!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                lead.message!,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: AppTheme.textSecondary,
                  height: 1.35,
                ),
              ),
            ],

            const SizedBox(height: 12),
            const Divider(height: 1, color: AppTheme.borderLight),
            const SizedBox(height: 10),

            // Footer: Partner info & View Details button
            Row(
              children: [
                Icon(
                  lead.isAssigned ? LucideIcons.checkCircle : LucideIcons.clock,
                  size: 14,
                  color: lead.isAssigned ? AppTheme.emeraldSuccess : const Color(0xFFD97706),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    lead.isAssigned
                        ? 'Partner: ${lead.assignedPartnerName}'
                        : 'PropZen AI deterministic matching in progress...',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: lead.isAssigned ? FontWeight.w600 : FontWeight.normal,
                      color: lead.isAssigned ? AppTheme.textPrimary : AppTheme.textMuted,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Details',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primaryViolet,
                  ),
                ),
                const Icon(LucideIcons.chevronRight, size: 14, color: AppTheme.primaryViolet),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAssignmentBadge(CustomerServiceLead lead) {
    if (lead.isAssigned) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: AppTheme.emeraldSuccess.withOpacity(0.12),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: AppTheme.emeraldSuccess.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(LucideIcons.userCheck, size: 12, color: AppTheme.emeraldSuccess),
            const SizedBox(width: 4),
            Text(
              'ASSIGNED',
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: AppTheme.emeraldSuccess,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF59E0B).withOpacity(0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFFF59E0B).withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(LucideIcons.clock, size: 12, color: Color(0xFFD97706)),
          const SizedBox(width: 4),
          Text(
            'MATCHING',
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: const Color(0xFFD97706),
            ),
          ),
        ],
      ),
    );
  }

  void _showLeadDetailSheet(CustomerServiceLead lead) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final catColor = _getCategoryColor(lead.serviceCategory);
        final catIcon = _getCategoryIcon(lead.serviceCategory);

        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 28,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Title & Category
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: catColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(catIcon, size: 24, color: catColor),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _formatCategory(lead.serviceCategory),
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Ref: ${lead.leadNumber}',
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 12,
                            color: AppTheme.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildAssignmentBadge(lead),
                ],
              ),
              const SizedBox(height: 24),

              // Status Tracker Timeline
              _buildProgressTracker(lead),
              const SizedBox(height: 24),

              // Assigned Partner Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceSubtle,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppTheme.borderLight),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Assigned Service Partner',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textMuted,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (lead.isAssigned) ...[
                      Row(
                        children: [
                          const CircleAvatar(
                            radius: 18,
                            backgroundColor: Color(0xFFEDE9FE),
                            child: Icon(LucideIcons.briefcase, size: 18, color: AppTheme.primaryViolet),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  lead.assignedPartnerName!,
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.textPrimary,
                                  ),
                                ),
                                Text(
                                  'Verified PropZen Partner',
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    color: AppTheme.emeraldSuccess,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ] else ...[
                      Row(
                        children: [
                          const Icon(LucideIcons.loader, size: 18, color: Color(0xFFD97706)),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Our auto-routing engine is currently selecting the best-rated, available verified partner in your area.',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),

              if (lead.message != null && lead.message!.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(
                  'Your Notes / Requirements',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textMuted,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppTheme.borderLight),
                  ),
                  child: Text(
                    lead.message!,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton.icon(
                  onPressed: () => Navigator.of(ctx).pop(),
                  icon: const Icon(LucideIcons.check, size: 18),
                  label: const Text('Close'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.textPrimary,
                    side: const BorderSide(color: AppTheme.borderLight),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildProgressTracker(CustomerServiceLead lead) {
    final isAssigned = lead.isAssigned;
    final isCompleted = lead.status == 'COMPLETED' || lead.status == 'CONVERTED';
    final isInProgress = isAssigned && !isCompleted;

    return Row(
      children: [
        _buildStepIndicator(
          title: 'Submitted',
          isDone: true,
          isActive: false,
        ),
        _buildStepLine(isDone: isAssigned),
        _buildStepIndicator(
          title: 'Partner Matched',
          isDone: isAssigned,
          isActive: !isAssigned,
        ),
        _buildStepLine(isDone: isCompleted),
        _buildStepIndicator(
          title: 'Completed',
          isDone: isCompleted,
          isActive: isInProgress,
        ),
      ],
    );
  }

  Widget _buildStepIndicator({
    required String title,
    required bool isDone,
    required bool isActive,
  }) {
    Color color = const Color(0xFFCBD5E1);
    if (isDone) {
      color = AppTheme.emeraldSuccess;
    } else if (isActive) {
      color = AppTheme.primaryViolet;
    }

    return Expanded(
      child: Column(
        children: [
          Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              color: isDone ? color : Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: color, width: 2),
            ),
            child: Center(
              child: isDone
                  ? const Icon(LucideIcons.check, size: 14, color: Colors.white)
                  : Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            title,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: (isDone || isActive) ? FontWeight.w600 : FontWeight.normal,
              color: (isDone || isActive) ? AppTheme.textPrimary : AppTheme.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepLine({required bool isDone}) {
    return Container(
      width: 24,
      height: 2,
      margin: const EdgeInsets.only(bottom: 18),
      color: isDone ? AppTheme.emeraldSuccess : const Color(0xFFCBD5E1),
    );
  }
}
