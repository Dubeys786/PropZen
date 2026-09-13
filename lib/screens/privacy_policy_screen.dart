import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const sections = [
      {
        'title': '1. Introduction & Scope',
        'content':
            'Propzen Real Estate Intelligence Platform ("Propzen", "we", "our") is committed to protecting the privacy and confidentiality of dealers, property owners, and buyers using our services. This Privacy Policy details how we collect, process, store, and protect your information.',
      },
      {
        'title': '2. Information We Collect',
        'content':
            'We collect registration details (name, phone number, email address), business identification, property listing specifics, geographic location coordinates, and uploaded media/documents solely for property verification and transaction enablement.',
      },
      {
        'title': '3. Use of Information',
        'content':
            'Your data is utilized to: (a) verify property ownership and RERA compliance; (b) connect dealers with verified prospective buyers; (c) enable automated site visit scheduling; and (d) maintain platform safety and prevent fraudulent listings.',
      },
      {
        'title': '4. Data Security & Storage',
        'content':
            'All database communications are secured using industry-standard TLS encryption, strict Row Level Security (RLS) policies on our Supabase backend, and token-based authentication. We never sell dealer or buyer personal information to third-party marketers.',
      },
      {
        'title': '5. Dealer Confidentiality & Lead Protection',
        'content':
            'Lead information and buyer inquiry contact details routed through Propzen are protected. Dealers are strictly prohibited from sharing, exporting, or redistributing buyer details outside authorized property transactions.',
      },
      {
        'title': '6. Your Rights & Data Retention',
        'content':
            'Dealers and users may at any time request an export of their stored profile and listing data, update their contact credentials, or request account and listing deactivation by contacting our support team.',
      },
      {
        'title': '7. Contact & Grievance Redressal',
        'content':
            'For questions regarding this policy or data processing practices, reach out to our Data Protection Officer at privacy@propzen.ai or write to Propzen Intelligence Towers, Sector 62, Noida, UP - 201309.',
      },
    ];

    return Scaffold(
      backgroundColor: AppTheme.pageBackground,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppTheme.textPrimary),
        title: Text(
          'Privacy Policy',
          style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
        ),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: AppTheme.borderLight),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              physics: const BouncingScrollPhysics(),
              itemCount: sections.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, i) {
                final s = sections[i];
                return Container(
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
                        s['title']!,
                        style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        s['content']!,
                        style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textSecondary, height: 1.5),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: AppTheme.borderLight)),
            ),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryViolet,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text('Close', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
