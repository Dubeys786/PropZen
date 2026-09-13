import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../theme/app_theme.dart';
import '../screens/user_profile_screen.dart';
import '../services/supabase_service.dart';

/// Complete Legal & Compliance Master Hub for PropZen
/// Contains all 9 legal policy documents and the Delete Account workflow
class LegalHubScreen extends StatefulWidget {
  final int initialIndex;

  const LegalHubScreen({super.key, this.initialIndex = 0});

  static Future<void> show(BuildContext context, {int initialIndex = 0}) {
    return Navigator.of(context).push(
      MaterialPageRoute(
        builder: (ctx) => LegalHubScreen(initialIndex: initialIndex),
      ),
    );
  }

  @override
  State<LegalHubScreen> createState() => _LegalHubScreenState();
}

class _LegalHubScreenState extends State<LegalHubScreen> with SingleTickerProviderStateMixin {
  late int _selectedIndex;

  final List<_LegalDocItem> _docs = [
    _LegalDocItem(
      id: 'privacy',
      title: 'Privacy Policy',
      subtitle: 'Data protection, encryption, and zero-spam policy',
      icon: LucideIcons.lock,
      sections: [
        _LegalSection(
          title: '1. Information We Collect',
          content:
              'PropZen collects personal information necessary to deliver personalized property recommendations, facilitate site visits, and coordinate with verified real estate partners. This includes your name, verified mobile number, email address, residency status (Indian Resident / NRI), shortlisted properties, search queries, and budget preferences.',
        ),
        _LegalSection(
          title: '2. Zero Spam & Data Confidentiality',
          content:
              'We enforce a strict Zero-Spam pledge. Your contact information is encrypted and never sold, rented, or shared with unauthorized third-party marketing agencies. Only assigned verified dealers or platform concierges can contact you regarding explicit site visits or property enquiries you initiate.',
        ),
        _LegalSection(
          title: '3. Data Security & Storage',
          content:
              'All user records, payment signatures, and document uploads are secured using 256-bit SSL encryption at rest and in transit on Supabase ISO/IEC 27001-certified cloud infrastructure.',
        ),
        _LegalSection(
          title: '4. Cookies & Analytics',
          content:
              'We use essential session tokens and performance telemetry to improve search filtering, property rematches, and app stability. You can control cookie preferences in your browser or device settings.',
        ),
        _LegalSection(
          title: '5. Your Data Rights & GDPR / DPDPA Compliance',
          content:
              'Under India’s Digital Personal Data Protection Act (DPDPA) and global privacy standards, you have the right to access, correct, export, or permanently delete your personal data at any time via the Delete Account option in Settings.',
        ),
      ],
    ),
    _LegalDocItem(
      id: 'terms',
      title: 'Terms & Conditions',
      subtitle: 'General platform rules, RERA compliance, and usage terms',
      icon: LucideIcons.fileText,
      sections: [
        _LegalSection(
          title: '1. Acceptance of Terms',
          content:
              'By accessing, downloading, or using the PropZen mobile application and web platform, you agree to be bound by these Terms and Conditions and all applicable central and state laws governing real estate in India.',
        ),
        _LegalSection(
          title: '2. Real Estate Regulatory Authority (RERA) Adherence',
          content:
              'PropZen operates as a real estate intelligence and facilitation platform. All property listings display statutory RERA registration numbers (UPRERA / HRERA / Delhi RERA) where mandated by law. Buyers are advised to independently cross-verify RERA status on official government portals before entering into financial commitments.',
        ),
        _LegalSection(
          title: '3. Market Intelligence & Fair Value Scores',
          content:
              'The PropZen 10X Intelligence Scores, Fair Value calculations, and projected rental yields are algorithmic estimates compiled from historical registry data, circle rates, and infrastructure indices. They are provided solely for indicative evaluation and do not constitute formal banking appraisals.',
        ),
        _LegalSection(
          title: '4. Site Visit Protocols',
          content:
              'Site visit bookings scheduled via PropZen are complimentary. No dealer, builder representative, or cab driver is authorized to demand unrecorded cash payments or booking advances during site visits.',
        ),
        _LegalSection(
          title: '5. Limitation of Liability',
          content:
              'PropZen is not liable for indirect, incidental, or consequential damages arising from transactions between buyers, dealers, and developers. All real estate transactions are subject to final mutual agreements between contracting parties.',
        ),
      ],
    ),
    _LegalDocItem(
      id: 'refunds',
      title: 'Refund & Cancellation Policy',
      subtitle: 'Subscription refunds, cooling-off periods, and cancellations',
      icon: LucideIcons.rotateCcw,
      sections: [
        _LegalSection(
          title: '1. 7-Day Refund Policy',
          content:
              'Subscribers of the Dealer Growth Suite, NRI Remote Property Pass, or Drone Tour Subscription may request a full refund within 7 calendar days of initial purchase if no premium reports or virtual tours have been utilized.',
        ),
        _LegalSection(
          title: '2. Prorated Cancellations',
          content:
              'After the initial 7-day period, subscriptions can be cancelled at any time to prevent auto-renewal. Access will remain active until the end of the current paid billing cycle.',
        ),
        _LegalSection(
          title: '3. Processing Timelines',
          content:
              'Approved refund amounts are credited back to the original payment method (Bank Account, UPI, Credit/Debit Card, Apple Pay) within 5 to 7 business days via our payment gateway partner.',
        ),
        _LegalSection(
          title: '4. Non-Refundable Items',
          content:
              'Government stamp duty verification fees, customized legal title search reports already delivered by empaneled advocates, and completed physical site visits are non-refundable.',
        ),
      ],
    ),
    _LegalDocItem(
      id: 'subscriptions',
      title: 'Subscription Terms',
      subtitle: 'Dealer plans, Drone Tour access, and billing lifecycle',
      icon: LucideIcons.creditCard,
      sections: [
        _LegalSection(
          title: '1. Distinct Subscription Categories',
          content:
              'PropZen maintains strictly decoupled subscription products: (a) Dealer Business Subscription (controls listing capacity, lead assignments, and broker CRM); (b) Drone Tour Subscription (unlocks 4K aerial interactive views across all properties); and (c) NRI Remote Suite (cross-border concierge and legal deal room). Dealer subscription status does NOT automatically unlock Drone Tour features.',
        ),
        _LegalSection(
          title: '2. Payment Verification & Activation',
          content:
              'Subscriptions become active strictly after server-side cryptographic signature verification of payment receipts. Selecting a plan or generating an order ID does not grant entitlement access.',
        ),
        _LegalSection(
          title: '3. Expiration & Grace Period',
          content:
              'Subscriptions automatically expire at 23:59:59 IST on the specified expiry date. Premium access is immediately suspended upon expiration until a valid renewal is completed.',
        ),
      ],
    ),
    _LegalDocItem(
      id: 'property_disclaimer',
      title: 'Property Verification Disclaimer',
      subtitle: '5-Pillar verification scope, RERA disclaimers, and title guidelines',
      icon: LucideIcons.shieldAlert,
      sections: [
        _LegalSection(
          title: '1. Scope of 5-Pillar Verification',
          content:
              'The PropZen Verified badge indicates that our intelligence team has validated statutory RERA filings, builder credentials, municipal zoning coordinates, approved floor layouts, and baseline circle rate consistency.',
        ),
        _LegalSection(
          title: '2. Buyer Due Diligence Requirement',
          content:
              'While PropZen employs stringent validation algorithms and document OCR verification, prospective buyers must conduct independent legal title verification, encumbrance certificate searches, and physical boundary inspections prior to executing property sales deeds.',
        ),
        _LegalSection(
          title: '3. Media Accuracy',
          content:
              '3D models, 360° panoramas, and drone aerial captures depict real site conditions at the time of recording. Seasonal weather changes, ongoing builder construction milestones, and interior staging variations may occur.',
        ),
      ],
    ),
    _LegalDocItem(
      id: 'dealer_terms',
      title: 'Dealer Terms & Code of Conduct',
      subtitle: 'Broker obligations, listing limits, and anti-fraud rules',
      icon: LucideIcons.briefcase,
      sections: [
        _LegalSection(
          title: '1. Mandatory RERA Registration',
          content:
              'All real estate agents, brokers, and channel partners operating on PropZen must hold a valid State RERA Broker Registration number. Operating without active RERA credentials will result in instant account termination.',
        ),
        _LegalSection(
          title: '2. Accurate Listing Declarations',
          content:
              'Dealers warrant that all posted properties, super areas, carpet dimensions, floor numbers, and asking prices are authentic and directly authorized by the property titleholder.',
        ),
        _LegalSection(
          title: '3. Lead Handling & Anti-Harassment',
          content:
              'Dealers must adhere to professional communication ethics. Multiple unsolicited calls, unrecorded fee demands, or misrepresenting competitor properties to buyers will trigger penalty flags and immediate listing delisting.',
        ),
      ],
    ),
    _LegalDocItem(
      id: 'drone_terms',
      title: 'Drone Tour Terms',
      subtitle: 'Aerial visualization rules, DGCA compliance, and safety standards',
      icon: LucideIcons.video,
      sections: [
        _LegalSection(
          title: '1. Regulatory & DGCA Compliance',
          content:
              'All aerial drone footage hosted on PropZen is captured by certified RPAS (Remotely Piloted Aircraft System) operators adhering to Directorate General of Civil Aviation (DGCA) Green Zone flight parameters and local municipal permissions.',
        ),
        _LegalSection(
          title: '2. Universal Visibility & Entitlement',
          content:
              'Drone Tour previews and cards are visible to all users across all properties. Interactive 4K flight paths, altitude controls, and surrounding POI telemetry require an active, verified Drone Tour Subscription.',
        ),
        _LegalSection(
          title: '3. Intellectual Property Rights',
          content:
              'All 4K aerial recordings, telemetry overlays, and 3D terrain captures are the exclusive copyrighted property of PropZen AI Technologies Pvt. Ltd. Unauthorized downloading or commercial redistribution is strictly prohibited.',
        ),
      ],
    ),
    _LegalDocItem(
      id: 'partner_terms',
      title: 'Service Partner Terms',
      subtitle: 'Home loan banks, legal advisors, and inspection partners',
      icon: LucideIcons.userCheck,
      sections: [
        _LegalSection(
          title: '1. Empaneled Service Partners',
          content:
              'PropZen connects users with empaneled Scheduled Commercial Banks (HDFC, SBI, ICICI, Axis), legal title verification attorneys, and RERA property inspectors.',
        ),
        _LegalSection(
          title: '2. Professional Independence',
          content:
              'Empaneled advocates and bank loan officers provide services under their respective professional licenses. PropZen does not offer direct financial underwriting or judicial legal guarantees.',
        ),
      ],
    ),
    _LegalDocItem(
      id: 'grievance',
      title: 'Contact & Grievance Officer',
      subtitle: 'Statutory grievance redressal, contact details, and resolution timelines',
      icon: LucideIcons.helpCircle,
      sections: [
        _LegalSection(
          title: '1. Grievance Officer Information',
          content:
              'In accordance with the Information Technology Act 2000 and the Consumer Protection (E-Commerce) Rules 2020, the details of the designated Grievance Officer for PropZen are provided below:\n\n'
              '• Name: Mr. Alok Shrivastava\n'
              '• Designation: Head of Compliance & Grievance Redressal\n'
              '• Official Email: grievance@propzen.ai\n'
              '• Phone: +91 98103 94068 / 1800-PROPZEN\n'
              '• Corporate Office: Tower B, Advant Navis Business Park, Sector 142, Noida Expressway, Uttar Pradesh - 201305, India',
        ),
        _LegalSection(
          title: '2. Grievance Redressal Timeline',
          content:
              'We acknowledge all formal grievance tickets within 24 hours of receipt and resolve user complaints within a maximum of 15 business days under statutory guidelines.',
        ),
      ],
    ),
  ];

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex.clamp(0, _docs.length - 1);
  }

  @override
  Widget build(BuildContext context) {
    final currentDoc = _docs[_selectedIndex];

    return Scaffold(
      backgroundColor: AppTheme.pageBackground,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppTheme.textPrimary),
        title: Text(
          'Legal & Compliance',
          style: GoogleFonts.poppins(fontSize: 17, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
        ),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: AppTheme.borderLight),
        ),
      ),
      body: Column(
        children: [
          // 1. Horizontal Document Selector Bar
          Container(
            height: 52,
            color: Colors.white,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              itemCount: _docs.length,
              itemBuilder: (ctx, i) {
                final isSelected = i == _selectedIndex;
                final doc = _docs[i];
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          doc.icon,
                          size: 13,
                          color: isSelected ? Colors.white : AppTheme.textSecondary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          doc.title,
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                            color: isSelected ? Colors.white : AppTheme.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    selected: isSelected,
                    selectedColor: AppTheme.primaryViolet,
                    backgroundColor: const Color(0xFFF1F5F9),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    onSelected: (selected) {
                      if (selected) {
                        setState(() => _selectedIndex = i);
                      }
                    },
                  ),
                );
              },
            ),
          ),
          const Divider(height: 1, color: AppTheme.borderLight),

          // 2. Active Policy Content Area
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Document Header Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.borderLight),
                      boxShadow: AppTheme.subtleCardShadow,
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryViolet.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(currentDoc.icon, color: AppTheme.primaryViolet, size: 24),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                currentDoc.title,
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                currentDoc.subtitle,
                                style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textMuted),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Policy Sections
                  ...currentDoc.sections.map((sec) => _buildPolicySectionCard(sec)),

                  const SizedBox(height: 20),

                  // Legal Version Footer
                  Center(
                    child: Column(
                      children: [
                        Text(
                          'Last Updated: August 2026 • Legal Policy v2.4.0',
                          style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textMuted),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'PropZen AI Technologies Private Limited • Institutional Compliance',
                          style: GoogleFonts.inter(fontSize: 10, color: AppTheme.textMuted),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 30),

                  // Quick Access to Delete Account
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF2F2),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFFECACA)),
                    ),
                    child: Row(
                      children: [
                        const Icon(LucideIcons.trash2, color: Color(0xFFDC2626), size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Looking to delete your account?',
                                style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF991B1B),
                                ),
                              ),
                              Text(
                                'Erase all personal data, shortlisted deals, and preferences.',
                                style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFFB91C1C)),
                              ),
                            ],
                          ),
                        ),
                        TextButton(
                          onPressed: () => _promptDeleteAccountFlow(context),
                          style: TextButton.styleFrom(
                            foregroundColor: const Color(0xFFDC2626),
                            backgroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          child: Text(
                            'Delete Account',
                            style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 60),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPolicySectionCard(_LegalSection sec) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.borderLight),
        boxShadow: AppTheme.subtleCardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            sec.title,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            sec.content,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: AppTheme.textSecondary,
              height: 1.55,
            ),
          ),
        ],
      ),
    );
  }

  /// Complete interactive Delete Account confirmation flow
  void _promptDeleteAccountFlow(BuildContext context) {
    final confirmationController = TextEditingController();
    String selectedReason = 'No longer looking for property';
    bool isDeleting = false;
    String? errorMessage;

    final reasons = [
      'No longer looking for property',
      'Found property on PropZen',
      'Found property elsewhere',
      'Privacy and data concerns',
      'Creating a new account',
      'Other reason',
    ];

    showDialog(
      context: context,
      barrierDismissible: !isDeleting,
      builder: (dlgCtx) => StatefulBuilder(
        builder: (ctx, setDlgState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEE2E2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(LucideIcons.alertTriangle, color: Color(0xFFDC2626), size: 22),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Delete Account',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFFDC2626),
                    ),
                  ),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Permanently delete your PropZen profile and erase all associated records?',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF2F2),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFFECACA)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'What will be permanently wiped:',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF991B1B),
                          ),
                        ),
                        const SizedBox(height: 6),
                        _buildBulletPoint('Your profile details and verified phone/email credentials'),
                        _buildBulletPoint('All saved favorite properties and comparison matrices'),
                        _buildBulletPoint('Scheduled site visits and dealer enquiry records'),
                        _buildBulletPoint('Active subscription access and AI chat conversation history'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Reason for leaving (optional):',
                    style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: selectedReason,
                        isExpanded: true,
                        icon: const Icon(LucideIcons.chevronDown, size: 16),
                        style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textPrimary),
                        items: reasons.map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setDlgState(() => selectedReason = val);
                          }
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Type "DELETE" below to confirm:',
                    style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: confirmationController,
                    autofocus: false,
                    style: GoogleFonts.inter(fontSize: 13, color: AppTheme.textPrimary),
                    decoration: InputDecoration(
                      hintText: 'Type DELETE',
                      hintStyle: GoogleFonts.inter(fontSize: 12, color: AppTheme.textMuted),
                      errorText: errorMessage,
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Color(0xFFDC2626), width: 1.5),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: isDeleting ? null : () => Navigator.of(dlgCtx).pop(),
                child: Text('Cancel', style: GoogleFonts.inter(color: AppTheme.textMuted, fontWeight: FontWeight.w600)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFDC2626),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: isDeleting
                    ? null
                    : () async {
                        final entered = confirmationController.text.trim().toUpperCase();
                        if (entered != 'DELETE') {
                          setDlgState(() => errorMessage = 'Please type "DELETE" to confirm');
                          return;
                        }

                        setDlgState(() {
                          isDeleting = true;
                          errorMessage = null;
                        });

                        final userEmail = UserSession.email;
                        final userPhone = UserSession.phone;

                        // 1. Call Backend Deletion / Deactivation
                        await SupabaseService.instance.deleteUserAccountPermanently(
                          email: userEmail,
                          phone: userPhone,
                          reason: selectedReason,
                        );

                        // 2. Wipe Local Session & Log Out
                        UserSession.clearSession();

                        if (context.mounted) {
                          Navigator.of(dlgCtx).pop();
                          Navigator.of(context).popUntil((route) => route.isFirst);

                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Your account and personal data have been permanently deleted.'),
                              backgroundColor: Color(0xFFDC2626),
                              duration: Duration(seconds: 4),
                            ),
                          );
                        }
                      },
                child: isDeleting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : Text(
                        'Permanently Delete',
                        style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildBulletPoint(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(color: Color(0xFFDC2626), fontSize: 13)),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF7F1D1D), height: 1.3),
            ),
          ),
        ],
      ),
    );
  }
}

class _LegalDocItem {
  final String id;
  final String title;
  final String subtitle;
  final IconData icon;
  final List<_LegalSection> sections;

  _LegalDocItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.sections,
  });
}

class _LegalSection {
  final String title;
  final String content;

  _LegalSection({required this.title, required this.content});
}
