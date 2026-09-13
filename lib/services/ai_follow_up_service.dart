import '../models/lead_model.dart';

class GeneratedFollowUp {
  final String title;
  final String messageBody;
  final String channel; // 'WhatsApp', 'Email', 'In-App'
  final String rationale;

  GeneratedFollowUp({
    required this.title,
    required this.messageBody,
    required this.channel,
    required this.rationale,
  });
}

class AiFollowUpService {
  AiFollowUpService._();
  static final AiFollowUpService instance = AiFollowUpService._();

  /// Generates a contextual personalized follow-up message for a dealer lead
  Future<GeneratedFollowUp> generateFollowUpForLead(DealerLead lead, {String customContext = ''}) async {
    await Future.delayed(const Duration(milliseconds: 400));

    final String buyerFirstName = lead.buyerName.split(' ').first;
    final String prop = lead.propertyTitle;

    String body;
    String rationale;

    if (lead.siteVisitStatus == 'Confirmed' || lead.enquiryStatus == 'Site Visit Scheduled') {
      body = 'Hi $buyerFirstName, this is regarding your scheduled private site visit for $prop. '
          'Our advisor and property host are fully prepared. Would you like us to confirm your cab pickup location or share the exact gate navigation link?';
      rationale = 'Pre-visit confirmation to ensure 100% attendance and offer concierge logistics.';
    } else if (lead.siteVisitStatus == 'Completed' || lead.enquiryStatus == 'Negotiation') {
      body = 'Hi $buyerFirstName, thank you for visiting $prop! '
          'We have received clearance on preferred payment schedules and parking inclusions. Would you like to review the updated offer in our Safe Deal Room today?';
      rationale = 'Post-visit closing momentum to lock in negotiation parameters.';
    } else if (lead.scoreTier == LeadScoreTier.hot) {
      body = 'Hi $buyerFirstName, you recently showed high interest in the $prop (${lead.requirement}). '
          'A special weekend pricing window and verified title report are currently active. Would you like to schedule an exclusive 30-minute walkthrough this Saturday?';
      rationale = 'Urgency and title transparency for high-intent buyers.';
    } else {
      body = 'Hi $buyerFirstName, hope you are doing well! '
          'You recently enquired about properties in ${lead.preferredLocation}. We have newly verified inventory matching your ₹${lead.budgetCr.toStringAsFixed(2)} Cr budget. '
          'May I share the latest comparative floor plan and brochure?';
      rationale = 'Re-engagement with tailored inventory matching stated budget.';
    }

    if (customContext.trim().isNotEmpty) {
      body += '\n\nNote: $customContext';
    }

    return GeneratedFollowUp(
      title: 'Personalized Follow-up for $buyerFirstName',
      messageBody: body,
      channel: 'WhatsApp / In-App',
      rationale: rationale,
    );
  }
}
