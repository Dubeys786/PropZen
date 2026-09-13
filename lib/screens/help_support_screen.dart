import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/app_theme.dart';

class HelpSupportScreen extends StatefulWidget {
  const HelpSupportScreen({super.key});

  @override
  State<HelpSupportScreen> createState() => _HelpSupportScreenState();
}

class _HelpSupportScreenState extends State<HelpSupportScreen> {
  final List<Map<String, String>> _faqs = [
    {
      'q': 'How does Propzen verify property listings?',
      'a': 'Every property on Propzen undergoes a rigorous 4-step verification: State RERA registration validation, 30-year title deed verification, physical inspection by our surveyor, and builder track record clearance.',
    },
    {
      'q': 'Are there any hidden brokerage charges on direct properties?',
      'a': 'No! Properties listed under Zero Brokerage have 0% commission. You connect directly with verified developers and partner brokers.',
    },
    {
      'q': 'How do I schedule and reschedule a site visit?',
      'a': 'Click "Book Site Visit" on any property page, pick your preferred date and time slot (10 AM, 11 AM, 2 PM, 4:30 PM), and our property manager will be assigned. You can manage or reschedule anytime in Profile > My Bookings.',
    },
    {
      'q': 'How does the AI Property Advisor work?',
      'a': 'Our AI Advisor understands natural language criteria such as "3 BHK in Noida under 1.5 Cr near Metro" and instantly ranks verified properties based on capital appreciation potential and rental yields.',
    },
    {
      'q': 'How can I get home loan eligibility assistance?',
      'a': 'Use our built-in Loan Calculator to compare partner bank interest rates (SBI, HDFC, ICICI, Axis Bank) and click "Check Eligibility" for doorstep document collection and zero processing fee loans.',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.pageBackground,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppTheme.textPrimary),
        title: Text(
          'Help & Support',
          style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
        ),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: AppTheme.borderLight),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Contact Support Grid Cards
            Row(
              children: [
                Expanded(
                  child: _buildContactCard(
                    icon: LucideIcons.phoneCall,
                    title: 'Call Support',
                    subtitle: '+91 98103 94068',
                    color: AppTheme.emeraldSuccess,
                    onTap: () async {
                      final uri = Uri.parse('tel:+919810394068');
                      await launchUrl(uri);
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildContactCard(
                    icon: LucideIcons.messageCircle,
                    title: 'WhatsApp Chat',
                    subtitle: 'Instant response',
                    color: const Color(0xFF25D366),
                    onTap: () async {
                      final uri = Uri.parse('https://wa.me/919810394068?text=Hi%20Propzen%20Support!');
                      await launchUrl(uri, mode: LaunchMode.externalApplication);
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: _buildContactCard(
                    icon: LucideIcons.mail,
                    title: 'Email Support',
                    subtitle: 'support@propzen.ai',
                    color: AppTheme.primaryViolet,
                    onTap: () async {
                      final uri = Uri.parse('mailto:support@propzen.ai');
                      await launchUrl(uri);
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildContactCard(
                    icon: LucideIcons.bot,
                    title: 'AI Advisor',
                    subtitle: '24/7 automated assistance',
                    color: AppTheme.primaryViolet,
                    onTap: () => Navigator.of(context).pop(),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 28),

            // FAQs Header
            Text(
              'Frequently Asked Questions',
              style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
            ),
            const SizedBox(height: 12),

            ..._faqs.map((faq) => _buildFaqTile(faq['q']!, faq['a']!)),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildContactCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppTheme.cardWhite,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.borderLight),
          boxShadow: AppTheme.subtleCardShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(height: 10),
            Text(title, style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
            Text(subtitle, style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textMuted)),
          ],
        ),
      ),
    );
  }

  Widget _buildFaqTile(String question, String answer) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppTheme.cardWhite,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.borderLight),
        boxShadow: AppTheme.subtleCardShadow,
      ),
      child: ExpansionTile(
        iconColor: AppTheme.primaryViolet,
        collapsedIconColor: AppTheme.textHint,
        title: Text(
          question,
          style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
            child: Text(
              answer,
              style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textSecondary, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }
}
