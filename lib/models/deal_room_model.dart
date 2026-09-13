enum DealStage {
  propertySelected,
  verification,
  siteVisit,
  negotiation,
  agreement,
  payment,
  dealCompleted,
}

extension DealStageExt on DealStage {
  String get displayName {
    switch (this) {
      case DealStage.propertySelected:
        return 'Property Selected';
      case DealStage.verification:
        return 'AI Verification';
      case DealStage.siteVisit:
        return 'Site Visit';
      case DealStage.negotiation:
        return 'Negotiation';
      case DealStage.agreement:
        return 'Agreement Drafted';
      case DealStage.payment:
        return 'Payment Milestones';
      case DealStage.dealCompleted:
        return 'Deal Completed 🎉';
    }
  }

  String get label => displayName;

  int get stepIndex {
    switch (this) {
      case DealStage.propertySelected:
        return 1;
      case DealStage.verification:
        return 2;
      case DealStage.siteVisit:
        return 3;
      case DealStage.negotiation:
        return 4;
      case DealStage.agreement:
        return 5;
      case DealStage.payment:
        return 6;
      case DealStage.dealCompleted:
        return 7;
    }
  }
}

enum OfferStatus {
  pending,
  accepted,
  rejected,
  countered,
}

class DealOffer {
  final String id;
  final String dealRoomId;
  final String senderId;
  final String senderName;
  final String senderRole; // 'Buyer' or 'Dealer'
  final double amountCr;
  final String formattedAmount;
  final String? note;
  final OfferStatus status;
  final DateTime createdAt;

  DealOffer({
    required this.id,
    required this.dealRoomId,
    required this.senderId,
    required this.senderName,
    required this.senderRole,
    required this.amountCr,
    String? formattedAmount,
    this.note,
    this.status = OfferStatus.pending,
    DateTime? createdAt,
  })  : formattedAmount = formattedAmount ?? '₹${amountCr.toStringAsFixed(2)} Cr',
        createdAt = createdAt ?? DateTime.now();

  DealOffer copyWith({
    OfferStatus? status,
    String? note,
  }) {
    return DealOffer(
      id: id,
      dealRoomId: dealRoomId,
      senderId: senderId,
      senderName: senderName,
      senderRole: senderRole,
      amountCr: amountCr,
      formattedAmount: formattedAmount,
      note: note ?? this.note,
      status: status ?? this.status,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'deal_room_id': dealRoomId,
        'sender_id': senderId,
        'sender_name': senderName,
        'sender_role': senderRole,
        'amount_cr': amountCr,
        'formatted_amount': formattedAmount,
        'note': note,
        'status': status.name,
        'created_at': createdAt.toIso8601String(),
      };

  factory DealOffer.fromMap(Map<String, dynamic> map) => DealOffer(
        id: map['id']?.toString() ?? 'OFFER-${DateTime.now().millisecondsSinceEpoch}',
        dealRoomId: map['deal_room_id']?.toString() ?? '',
        senderId: map['sender_id']?.toString() ?? '',
        senderName: map['sender_name']?.toString() ?? 'Participant',
        senderRole: map['sender_role']?.toString() ?? 'Buyer',
        amountCr: (map['amount_cr'] as num?)?.toDouble() ?? 1.80,
        formattedAmount: map['formatted_amount']?.toString(),
        note: map['note']?.toString(),
        status: OfferStatus.values.firstWhere(
          (s) => s.name == (map['status']?.toString() ?? 'pending'),
          orElse: () => OfferStatus.pending,
        ),
        createdAt: map['created_at'] != null ? DateTime.tryParse(map['created_at'].toString()) : null,
      );
}

enum MilestoneStatus {
  pending,
  upcoming,
  paid,
  overdue,
}

class PaymentMilestone {
  final String id;
  final String dealRoomId;
  final String title;
  final double amountCr;
  final String formattedAmount;
  final String dueDate;
  final MilestoneStatus status;
  final String? paymentReference;
  final String? notes;
  final DateTime? paidAt;

  PaymentMilestone({
    required this.id,
    required this.dealRoomId,
    required this.title,
    required this.amountCr,
    String? formattedAmount,
    required this.dueDate,
    this.status = MilestoneStatus.pending,
    this.paymentReference,
    this.notes,
    this.paidAt,
  }) : formattedAmount = formattedAmount ?? '₹${amountCr.toStringAsFixed(2)} Cr';

  PaymentMilestone copyWith({
    MilestoneStatus? status,
    String? paymentReference,
    String? notes,
    DateTime? paidAt,
  }) {
    return PaymentMilestone(
      id: id,
      dealRoomId: dealRoomId,
      title: title,
      amountCr: amountCr,
      formattedAmount: formattedAmount,
      dueDate: dueDate,
      status: status ?? this.status,
      paymentReference: paymentReference ?? this.paymentReference,
      notes: notes ?? this.notes,
      paidAt: paidAt ?? this.paidAt,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'deal_room_id': dealRoomId,
        'title': title,
        'amount_cr': amountCr,
        'formatted_amount': formattedAmount,
        'due_date': dueDate,
        'status': status.name,
        'payment_reference': paymentReference,
        'notes': notes,
        'paid_at': paidAt?.toIso8601String(),
      };

  factory PaymentMilestone.fromMap(Map<String, dynamic> map) => PaymentMilestone(
        id: map['id']?.toString() ?? 'MILE-${DateTime.now().millisecondsSinceEpoch}',
        dealRoomId: map['deal_room_id']?.toString() ?? '',
        title: map['title']?.toString() ?? 'Milestone',
        amountCr: (map['amount_cr'] as num?)?.toDouble() ?? 0.15,
        formattedAmount: map['formatted_amount']?.toString(),
        dueDate: map['due_date']?.toString() ?? '15 Sept 2026',
        status: MilestoneStatus.values.firstWhere(
          (s) => s.name == (map['status']?.toString() ?? 'pending'),
          orElse: () => MilestoneStatus.pending,
        ),
        paymentReference: map['payment_reference']?.toString(),
        notes: map['notes']?.toString(),
        paidAt: map['paid_at'] != null ? DateTime.tryParse(map['paid_at'].toString()) : null,
      );
}

class DealDocument {
  final String id;
  final String dealRoomId;
  final String documentName;
  final String documentType; // 'Title Deed', 'RERA Certificate', 'Agreement Draft', 'Token Receipt', 'Tax Receipt'
  final String uploadedBy;
  final String uploaderRole;
  final String fileUrl;
  final String fileSize;
  final String verificationStatus; // 'Verified ✓', 'Needs Review', 'Pending'
  final DateTime uploadedAt;

  DealDocument({
    required this.id,
    required this.dealRoomId,
    required this.documentName,
    required this.documentType,
    required this.uploadedBy,
    required this.uploaderRole,
    required this.fileUrl,
    this.fileSize = '1.8 MB',
    this.verificationStatus = 'Verified ✓',
    DateTime? uploadedAt,
  }) : uploadedAt = uploadedAt ?? DateTime.now();

  Map<String, dynamic> toMap() => {
        'id': id,
        'deal_room_id': dealRoomId,
        'document_name': documentName,
        'document_type': documentType,
        'uploaded_by': uploadedBy,
        'uploader_role': uploaderRole,
        'file_url': fileUrl,
        'file_size': fileSize,
        'verification_status': verificationStatus,
        'uploaded_at': uploadedAt.toIso8601String(),
      };

  factory DealDocument.fromMap(Map<String, dynamic> map) => DealDocument(
        id: map['id']?.toString() ?? 'DOC-${DateTime.now().millisecondsSinceEpoch}',
        dealRoomId: map['deal_room_id']?.toString() ?? '',
        documentName: map['document_name']?.toString() ?? 'Document.pdf',
        documentType: map['document_type']?.toString() ?? 'Deed',
        uploadedBy: map['uploaded_by']?.toString() ?? 'Dealer',
        uploaderRole: map['uploader_role']?.toString() ?? 'Dealer',
        fileUrl: map['file_url']?.toString() ?? '',
        fileSize: map['file_size']?.toString() ?? '1.2 MB',
        verificationStatus: map['verification_status']?.toString() ?? 'Verified ✓',
        uploadedAt: map['uploaded_at'] != null ? DateTime.tryParse(map['uploaded_at'].toString()) : null,
      );
}

class DealMessage {
  final String id;
  final String dealRoomId;
  final String senderId;
  final String senderName;
  final String senderRole; // 'Buyer' or 'Dealer' or 'AI Assistant'
  final String content;
  final String? messageType; // 'text', 'offer_created', 'milestone_updated', 'document_shared', 'site_visit'
  final Map<String, dynamic>? metadata;
  final DateTime timestamp;

  DealMessage({
    required this.id,
    required this.dealRoomId,
    required this.senderId,
    required this.senderName,
    required this.senderRole,
    required this.content,
    this.messageType = 'text',
    this.metadata,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toMap() => {
        'id': id,
        'deal_room_id': dealRoomId,
        'sender_id': senderId,
        'sender_name': senderName,
        'sender_role': senderRole,
        'content': content,
        'message_type': messageType,
        'metadata': metadata,
        'timestamp': timestamp.toIso8601String(),
      };

  factory DealMessage.fromMap(Map<String, dynamic> map) => DealMessage(
        id: map['id']?.toString() ?? 'MSG-${DateTime.now().millisecondsSinceEpoch}',
        dealRoomId: map['deal_room_id']?.toString() ?? '',
        senderId: map['sender_id']?.toString() ?? '',
        senderName: map['sender_name']?.toString() ?? 'User',
        senderRole: map['sender_role']?.toString() ?? 'Buyer',
        content: map['content']?.toString() ?? '',
        messageType: map['message_type']?.toString() ?? 'text',
        metadata: map['metadata'] as Map<String, dynamic>?,
        timestamp: map['timestamp'] != null ? DateTime.tryParse(map['timestamp'].toString()) : null,
      );
}

class DealActivityEvent {
  final String title;
  final String description;
  final String actorName;
  final String actorRole;
  final DateTime timestamp;
  final String eventType;

  DealActivityEvent({
    required this.title,
    required this.description,
    required this.actorName,
    required this.actorRole,
    DateTime? timestamp,
    this.eventType = 'general',
  }) : timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toMap() => {
        'title': title,
        'description': description,
        'actor_name': actorName,
        'actor_role': actorRole,
        'timestamp': timestamp.toIso8601String(),
        'event_type': eventType,
      };

  factory DealActivityEvent.fromMap(Map<String, dynamic> map) => DealActivityEvent(
        title: map['title']?.toString() ?? 'Activity',
        description: map['description']?.toString() ?? '',
        actorName: map['actor_name']?.toString() ?? 'System',
        actorRole: map['actor_role']?.toString() ?? 'System',
        timestamp: map['timestamp'] != null ? DateTime.tryParse(map['timestamp'].toString()) : null,
        eventType: map['event_type']?.toString() ?? 'general',
      );
}

class DealRoom {
  final String id;
  final String propertyId;
  final String propertyTitle;
  final String propertyImage;
  final String propertyLocation;
  final double listedPriceCr;
  final String buyerId;
  final String buyerName;
  final String buyerPhone;
  final String buyerEmail;
  final String dealerId;
  final String dealerName;
  final String dealerPhone;
  final String dealerEmail;
  final DealStage stage;
  final int dealScore; // 0 - 100
  final double? agreedPriceCr;
  final List<DealOffer> offers;
  final List<PaymentMilestone> paymentMilestones;
  final List<DealDocument> documents;
  final List<DealMessage> messages;
  final List<DealActivityEvent> activityTimeline;
  final DateTime createdAt;
  final DateTime updatedAt;

  DealRoom({
    required this.id,
    required this.propertyId,
    required this.propertyTitle,
    required this.propertyImage,
    required this.propertyLocation,
    required this.listedPriceCr,
    required this.buyerId,
    required this.buyerName,
    this.buyerPhone = '',
    this.buyerEmail = '',
    required this.dealerId,
    required this.dealerName,
    this.dealerPhone = '',
    this.dealerEmail = '',
    this.stage = DealStage.negotiation,
    this.dealScore = 87,
    this.agreedPriceCr,
    this.offers = const [],
    this.paymentMilestones = const [],
    this.documents = const [],
    this.messages = const [],
    this.activityTimeline = const [],
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  DealOffer? get latestOffer => offers.isNotEmpty ? offers.first : null;
  List<PaymentMilestone> get milestones => paymentMilestones;

  DealRoom copyWith({
    DealStage? stage,
    int? dealScore,
    double? agreedPriceCr,
    List<DealOffer>? offers,
    List<PaymentMilestone>? paymentMilestones,
    List<DealDocument>? documents,
    List<DealMessage>? messages,
    List<DealActivityEvent>? activityTimeline,
    DateTime? updatedAt,
  }) {
    return DealRoom(
      id: id,
      propertyId: propertyId,
      propertyTitle: propertyTitle,
      propertyImage: propertyImage,
      propertyLocation: propertyLocation,
      listedPriceCr: listedPriceCr,
      buyerId: buyerId,
      buyerName: buyerName,
      buyerPhone: buyerPhone,
      buyerEmail: buyerEmail,
      dealerId: dealerId,
      dealerName: dealerName,
      dealerPhone: dealerPhone,
      dealerEmail: dealerEmail,
      stage: stage ?? this.stage,
      dealScore: dealScore ?? this.dealScore,
      agreedPriceCr: agreedPriceCr ?? this.agreedPriceCr,
      offers: offers ?? this.offers,
      paymentMilestones: paymentMilestones ?? this.paymentMilestones,
      documents: documents ?? this.documents,
      messages: messages ?? this.messages,
      activityTimeline: activityTimeline ?? this.activityTimeline,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'property_id': propertyId,
        'property_title': propertyTitle,
        'property_image': propertyImage,
        'property_location': propertyLocation,
        'listed_price_cr': listedPriceCr,
        'buyer_id': buyerId,
        'buyer_name': buyerName,
        'buyer_phone': buyerPhone,
        'buyer_email': buyerEmail,
        'dealer_id': dealerId,
        'dealer_name': dealerName,
        'dealer_phone': dealerPhone,
        'dealer_email': dealerEmail,
        'stage': stage.name,
        'deal_score': dealScore,
        'agreed_price_cr': agreedPriceCr,
        'offers': offers.map((o) => o.toMap()).toList(),
        'payment_milestones': paymentMilestones.map((m) => m.toMap()).toList(),
        'documents': documents.map((d) => d.toMap()).toList(),
        'messages': messages.map((m) => m.toMap()).toList(),
        'activity_timeline': activityTimeline.map((a) => a.toMap()).toList(),
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };

  factory DealRoom.fromMap(Map<String, dynamic> map) => DealRoom(
        id: map['id']?.toString() ?? 'DEAL-ROOM-${DateTime.now().millisecondsSinceEpoch}',
        propertyId: map['property_id']?.toString() ?? 'PROP-ATS-01',
        propertyTitle: map['property_title']?.toString() ?? 'ATS HomeKraft Pious Orchards',
        propertyImage: map['property_image']?.toString() ?? 'https://images.unsplash.com/photo-1545324418-cc1a3fa10c00?w=800',
        propertyLocation: map['property_location']?.toString() ?? 'Sector 150, Noida Expressway',
        listedPriceCr: (map['listed_price_cr'] as num?)?.toDouble() ?? 1.85,
        buyerId: map['buyer_id']?.toString() ?? 'usr_buyer',
        buyerName: map['buyer_name']?.toString() ?? 'Rahul Singhania',
        buyerPhone: map['buyer_phone']?.toString() ?? '+91 98103 44521',
        buyerEmail: map['buyer_email']?.toString() ?? 'rahul.s@example.com',
        dealerId: map['dealer_id']?.toString() ?? 'dealer_active',
        dealerName: map['dealer_name']?.toString() ?? 'Aman Sharma (Prime Realty)',
        dealerPhone: map['dealer_phone']?.toString() ?? '+91 98103 94068',
        dealerEmail: map['dealer_email']?.toString() ?? 'aman@dealghar.com',
        stage: DealStage.values.firstWhere(
          (s) => s.name == (map['stage']?.toString() ?? 'negotiation'),
          orElse: () => DealStage.negotiation,
        ),
        dealScore: (map['deal_score'] as num?)?.toInt() ?? 87,
        agreedPriceCr: (map['agreed_price_cr'] as num?)?.toDouble(),
        offers: (map['offers'] as List<dynamic>?)
                ?.map((o) => DealOffer.fromMap(Map<String, dynamic>.from(o as Map)))
                .toList() ??
            [],
        paymentMilestones: (map['payment_milestones'] as List<dynamic>?)
                ?.map((m) => PaymentMilestone.fromMap(Map<String, dynamic>.from(m as Map)))
                .toList() ??
            [],
        documents: (map['documents'] as List<dynamic>?)
                ?.map((d) => DealDocument.fromMap(Map<String, dynamic>.from(d as Map)))
                .toList() ??
            [],
        messages: (map['messages'] as List<dynamic>?)
                ?.map((m) => DealMessage.fromMap(Map<String, dynamic>.from(m as Map)))
                .toList() ??
            [],
        activityTimeline: (map['activity_timeline'] as List<dynamic>?)
                ?.map((a) => DealActivityEvent.fromMap(Map<String, dynamic>.from(a as Map)))
                .toList() ??
            [],
        createdAt: map['created_at'] != null ? DateTime.tryParse(map['created_at'].toString()) : null,
        updatedAt: map['updated_at'] != null ? DateTime.tryParse(map['updated_at'].toString()) : null,
      );

  /// Default sample deal room for instant interactive experience
  static DealRoom sampleRoom() => DealRoom(
        id: 'DEAL-NCR-101',
        propertyId: 'PROP-ATS-01',
        propertyTitle: 'ATS HomeKraft Pious Orchards',
        propertyImage: 'https://images.unsplash.com/photo-1545324418-cc1a3fa10c00?w=800',
        propertyLocation: 'Sector 150, Noida Expressway',
        listedPriceCr: 1.85,
        buyerId: 'usr_buyer_active',
        buyerName: 'Rahul Singhania',
        buyerPhone: '+91 98103 44521',
        buyerEmail: 'rahul.singhania@techcorp.com',
        dealerId: 'dealer_ncr_01',
        dealerName: 'Aman Sharma (Prime Realty)',
        dealerPhone: '+91 98103 94068',
        dealerEmail: 'aman@dealghar.com',
        stage: DealStage.negotiation,
        dealScore: 88,
        offers: [
          DealOffer(
            id: 'OFF-004',
            dealRoomId: 'DEAL-NCR-101',
            senderId: 'dealer_ncr_01',
            senderName: 'Aman Sharma',
            senderRole: 'Dealer',
            amountCr: 1.78,
            note: 'Final best price including 2 reserved covered parking spots.',
            status: OfferStatus.pending,
            createdAt: DateTime.now().subtract(const Duration(minutes: 40)),
          ),
          DealOffer(
            id: 'OFF-003',
            dealRoomId: 'DEAL-NCR-101',
            senderId: 'usr_buyer_active',
            senderName: 'Rahul Singhania',
            senderRole: 'Buyer',
            amountCr: 1.76,
            note: 'Immediate token payment ready if registry in Sept.',
            status: OfferStatus.countered,
            createdAt: DateTime.now().subtract(const Duration(hours: 3)),
          ),
          DealOffer(
            id: 'OFF-002',
            dealRoomId: 'DEAL-NCR-101',
            senderId: 'dealer_ncr_01',
            senderName: 'Aman Sharma',
            senderRole: 'Dealer',
            amountCr: 1.81,
            note: 'Owner willing to close at ₹1.81 Cr with modular kitchen inclusions.',
            status: OfferStatus.countered,
            createdAt: DateTime.now().subtract(const Duration(days: 1)),
          ),
          DealOffer(
            id: 'OFF-001',
            dealRoomId: 'DEAL-NCR-101',
            senderId: 'usr_buyer_active',
            senderName: 'Rahul Singhania',
            senderRole: 'Buyer',
            amountCr: 1.72,
            note: 'Initial proposal based on sector valuation average.',
            status: OfferStatus.countered,
            createdAt: DateTime.now().subtract(const Duration(days: 2)),
          ),
        ],
        paymentMilestones: [
          PaymentMilestone(
            id: 'M1',
            dealRoomId: 'DEAL-NCR-101',
            title: '1. Booking Token Amount',
            amountCr: 0.10,
            dueDate: '05 Sept 2026',
            status: MilestoneStatus.paid,
            paymentReference: 'TXN-HDFC-992810',
            paidAt: DateTime.now().subtract(const Duration(days: 2)),
            notes: '₹10 Lakhs Token paid upon initial deal confirmation.',
          ),
          PaymentMilestone(
            id: 'M2',
            dealRoomId: 'DEAL-NCR-101',
            title: '2. Agreement to Sale (BBA Execution)',
            amountCr: 0.25,
            dueDate: '20 Sept 2026',
            status: MilestoneStatus.upcoming,
            notes: 'Due upon signing Builder Buyer Agreement draft.',
          ),
          PaymentMilestone(
            id: 'M3',
            dealRoomId: 'DEAL-NCR-101',
            title: '3. Bank Home Loan Disbursement',
            amountCr: 1.25,
            dueDate: '15 Oct 2026',
            status: MilestoneStatus.pending,
            notes: 'Direct loan disbursement via HDFC / SBI home loan team.',
          ),
          PaymentMilestone(
            id: 'M4',
            dealRoomId: 'DEAL-NCR-101',
            title: '4. Final Possession & Sub-Registrar Registry',
            amountCr: 0.18,
            dueDate: '10 Nov 2026',
            status: MilestoneStatus.pending,
            notes: 'Final mutation and key handover at Sub-Registrar Office.',
          ),
        ],
        documents: [
          DealDocument(
            id: 'DOC-01',
            dealRoomId: 'DEAL-NCR-101',
            documentName: 'Sanctioned_Building_Plan_ATS.pdf',
            documentType: 'Approved Building Plan',
            uploadedBy: 'Aman Sharma (Dealer)',
            uploaderRole: 'Dealer',
            fileUrl: 'https://propzen.ai/docs/ats_sanction.pdf',
            fileSize: '3.4 MB',
            verificationStatus: 'Verified ✓',
            uploadedAt: DateTime.now().subtract(const Duration(days: 3)),
          ),
          DealDocument(
            id: 'DOC-02',
            dealRoomId: 'DEAL-NCR-101',
            documentName: 'UPRERA_Registration_Certificate.pdf',
            documentType: 'RERA Certificate',
            uploadedBy: 'Aman Sharma (Dealer)',
            uploaderRole: 'Dealer',
            fileUrl: 'https://propzen.ai/docs/uprera.pdf',
            fileSize: '1.2 MB',
            verificationStatus: 'Verified ✓',
            uploadedAt: DateTime.now().subtract(const Duration(days: 3)),
          ),
          DealDocument(
            id: 'DOC-03',
            dealRoomId: 'DEAL-NCR-101',
            documentName: 'Buyer_PAN_and_Aadhaar_KYC.pdf',
            documentType: 'Identity / KYC Proof',
            uploadedBy: 'Rahul Singhania (Buyer)',
            uploaderRole: 'Buyer',
            fileUrl: 'https://propzen.ai/docs/buyer_kyc.pdf',
            fileSize: '850 KB',
            verificationStatus: 'Verified ✓',
            uploadedAt: DateTime.now().subtract(const Duration(days: 2)),
          ),
          DealDocument(
            id: 'DOC-04',
            dealRoomId: 'DEAL-NCR-101',
            documentName: 'Draft_Sale_Agreement_v2.pdf',
            documentType: 'Sale Agreement Draft',
            uploadedBy: 'PropZen Legal Desk',
            uploaderRole: 'Legal Advisor',
            fileUrl: 'https://propzen.ai/docs/draft_agreement.pdf',
            fileSize: '2.1 MB',
            verificationStatus: 'Needs Review',
            uploadedAt: DateTime.now().subtract(const Duration(hours: 4)),
          ),
        ],
        messages: [
          DealMessage(
            id: 'MSG-01',
            dealRoomId: 'DEAL-NCR-101',
            senderId: 'dealer_ncr_01',
            senderName: 'Aman Sharma',
            senderRole: 'Dealer',
            content: 'Hello Mr. Singhania, welcome to the official PropZen Safe Deal Room for ATS HomeKraft Pious Orchards. All verified paperwork and RERA certificates are uploaded in the Documents tab.',
            timestamp: DateTime.now().subtract(const Duration(days: 3)),
          ),
          DealMessage(
            id: 'MSG-02',
            dealRoomId: 'DEAL-NCR-101',
            senderId: 'usr_buyer_active',
            senderName: 'Rahul Singhania',
            senderRole: 'Buyer',
            content: 'Thank you Aman. We inspected the site and really liked the tower location. Can we finalize the deal with 2 covered car parking slots included?',
            timestamp: DateTime.now().subtract(const Duration(days: 2)),
          ),
          DealMessage(
            id: 'MSG-03',
            dealRoomId: 'DEAL-NCR-101',
            senderId: 'dealer_ncr_01',
            senderName: 'Aman Sharma',
            senderRole: 'Dealer',
            content: 'Yes! I have spoken to the builder desk. They have approved 2 covered basement parking spots and a revised counter-offer of ₹1.78 Cr has been placed in the Offers tab.',
            timestamp: DateTime.now().subtract(const Duration(minutes: 40)),
          ),
        ],
        activityTimeline: [
          DealActivityEvent(
            title: 'Dealer Counter-Offer Submitted',
            description: 'Aman Sharma submitted revised counter offer of ₹1.78 Cr.',
            actorName: 'Aman Sharma',
            actorRole: 'Dealer',
            timestamp: DateTime.now().subtract(const Duration(minutes: 40)),
            eventType: 'offer',
          ),
          DealActivityEvent(
            title: 'Draft Sale Agreement Uploaded',
            description: 'Draft_Sale_Agreement_v2.pdf uploaded for legal review.',
            actorName: 'PropZen Legal Desk',
            actorRole: 'Advisor',
            timestamp: DateTime.now().subtract(const Duration(hours: 4)),
            eventType: 'document',
          ),
          DealActivityEvent(
            title: 'Token Milestone Paid',
            description: '₹10 Lakhs Token marked Paid via TXN-HDFC-992810.',
            actorName: 'Rahul Singhania',
            actorRole: 'Buyer',
            timestamp: DateTime.now().subtract(const Duration(days: 2)),
            eventType: 'payment',
          ),
          DealActivityEvent(
            title: 'Safe Deal Room Initialized',
            description: 'Private deal room created for Rahul Singhania & Aman Sharma on ATS HomeKraft.',
            actorName: 'PropZen System',
            actorRole: 'System',
            timestamp: DateTime.now().subtract(const Duration(days: 3)),
            eventType: 'system',
          ),
        ],
      );
}
