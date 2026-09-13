/// Centrally managed Propzen Dealer Terms & Conditions and Declarations
class DealerTermsConfig {
  static const String currentVersion = '1.0';
  static const String lastUpdated = '19 August 2026';
  static const String title = 'Propzen Dealer Terms & Conditions';

  static const String legalDisclaimer =
      'These terms and declarations are provided for platform use and should be reviewed by a qualified legal professional before production launch.';

  static const List<Map<String, String>> sections = [
    {
      'title': '1. Property Information Accuracy',
      'content':
          'The dealer represents and warrants that all information submitted regarding the property—including but not limited to title, dimensions, area, configuration (BHK), facing, furnishing, amenities, age of property, and possession timeline—is true, complete, and accurate in all respects.'
    },
    {
      'title': '2. Property Ownership / Authorization',
      'content':
          'The dealer confirms that they are either the lawful owner of the property or possess valid, subsisting, and verifiable written authorization, mandate, or power of attorney from the legal owner to market, advertise, and negotiate the listing on Propzen.'
    },
    {
      'title': '3. Property Images & Documents',
      'content':
          'All photographs, floor plans, 3D renders, video tours, title deeds, and documents uploaded by the dealer must be authentic, genuine, and pertain exclusively to the subject property. The dealer warrants they hold the necessary intellectual property rights and licenses to publish all uploaded media.'
    },
    {
      'title': '4. Pricing Information',
      'content':
          'The asking price, price per square foot, maintenance charges, taxes, and other financial disclosures must accurately reflect the bona fide pricing agreed with the owner. Artificial inflation, bait-and-switch pricing, or undisclosed mandatory charges are strictly prohibited.'
    },
    {
      'title': '5. Location & Geo-Coordinates',
      'content':
          'The dealer must provide the exact physical address, landmark, sector, city, and GPS coordinates for the property. Falsifying or deliberately obscuring the true geographic location of a listing is grounds for immediate listing rejection and dealer account suspension.'
    },
    {
      'title': '6. Legal / RERA Compliance',
      'content':
          'Where applicable under the Real Estate (Regulation and Development) Act, 2016 (RERA) or state authority regulations, the dealer must provide a valid RERA registration number and RERA certificate for projects. Propzen independently verifies legal documents before public display.'
    },
    {
      'title': '7. Contact & Dealer Identification',
      'content':
          'The dealer must maintain valid and active contact details, including full legal name, registered mobile number, business email, and official agency registration. Impersonating other brokers, builders, or buyers is strictly forbidden.'
    },
    {
      'title': '8. Prohibited & Misleading Listings',
      'content':
          'Listings containing duplicate postings, fraudulent claims, properties subject to active litigation or encumbrances without disclosure, non-existent inventory, or unauthorized commercial use of residential premises are prohibited and subject to immediate removal.'
    },
    {
      'title': '9. Property Verification Protocol',
      'content':
          'Propzen reserves the right to perform digital, algorithmic, physical, and third-party title verifications on any submitted listing. The dealer agrees to cooperate promptly by providing supplementary documentation when requested.'
    },
    {
      'title': '10. Admin Review & Approval Workflow',
      'content':
          'All submitted dealer properties are initially placed in a "pending" status and are not visible to public users. Propzen administrators review each submission against quality, compliance, and verification benchmarks before granting "published" status.'
    },
    {
      'title': '11. Property Rejection & Removal Rights',
      'content':
          'Propzen retains the absolute discretion to reject, edit, unpublish, suspend, or permanently remove any property listing that violates these terms, fails verification standards, or generates unresolved consumer grievances.'
    },
    {
      'title': '12. Dealer Duty & Ethical Code',
      'content':
          'Dealers on Propzen are expected to conduct all communications, property inspections, and negotiations with highest professional integrity, transparency, and responsiveness to prospective buyers and platform moderators.'
    },
    {
      'title': '13. Client Enquiries & Site Visits',
      'content':
          'Inquiries, visitor counts, and site visit bookings routed through Propzen must be honored professionally. The dealer agrees to protect prospective buyer privacy and use enquiry details solely for legitimate property transaction discussions.'
    },
    {
      'title': '14. Listing Modifications & Re-Verification',
      'content':
          'Significant modifications to an existing listing—such as changes to pricing, title, location, area, or legal documents—trigger a mandatory re-declaration and may require renewed administrative review before public updates take effect.'
    },
    {
      'title': '15. Privacy & Data Handling',
      'content':
          'Dealer personal and business data is handled in strict compliance with the Propzen Privacy Policy. Information is utilized for platform verification, matchmaking, transaction enablement, and anti-fraud monitoring.'
    },
    {
      'title': '16. General Platform Terms & Jurisdiction',
      'content':
          'These terms operate in conjunction with Propzen General Terms of Service. Any disputes arising hereunder shall be subject to the exclusive jurisdiction of the competent courts in Noida / Delhi NCR, India.'
    },
  ];

  static const List<Map<String, String>> mandatoryDeclarations = [
    {
      'key': 'accuracy',
      'text': 'I confirm that the property information provided by me is accurate and up to date.',
    },
    {
      'key': 'authorization',
      'text': 'I confirm that I am the owner of this property or authorized to list it on behalf of the owner.',
    },
    {
      'key': 'content_rights',
      'text': 'I confirm that the images, documents and other content uploaded by me are authentic and that I have the right to use them.',
    },
    {
      'key': 'pricing',
      'text': 'I confirm that the price, property status, location and other details provided in this listing are correct to the best of my knowledge.',
    },
    {
      'key': 'review_consent',
      'text': 'I understand that Propzen may review, approve, reject, edit, suspend or remove a listing if it does not meet platform requirements.',
    },
    {
      'key': 'terms_agreement',
      'text': 'I agree to the Propzen Dealer Terms & Conditions and Privacy Policy.',
    },
  ];
}
