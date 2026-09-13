import 'package:flutter/foundation.dart';
import '../models/deal_room_model.dart';
import '../models/property.dart';
import '../services/property_state_service.dart';
import '../services/supabase_service.dart';

class DealRoomService extends ChangeNotifier {
  static final DealRoomService instance = DealRoomService._internal();
  DealRoomService._internal();

  factory DealRoomService() => instance;

  final List<DealRoom> _rooms = [];

  List<DealRoom> get allRooms => List.unmodifiable(_rooms);
  List<DealRoom> get dealRooms => allRooms;

  List<DealRoom> getRoomsForBuyer(String buyerId) {
    if (buyerId.isEmpty) return [];
    return _rooms.where((r) => r.buyerId == buyerId).toList();
  }

  List<DealRoom> getRoomsForDealer(String dealerId) {
    if (dealerId.isEmpty) return [];
    return _rooms.where((r) => r.dealerId == dealerId).toList();
  }

  DealRoom? getRoomById(String id) {
    if (id.isEmpty) return null;
    try {
      return _rooms.firstWhere((r) => r.id == id);
    } catch (_) {
      return null;
    }
  }

  DealRoom getOrCreateDealRoom({
    required Property property,
    required String buyerId,
    required String buyerName,
    String buyerPhone = '',
    String buyerEmail = '',
    required String dealerId,
    required String dealerName,
    String dealerPhone = '',
    String dealerEmail = '',
  }) {
    // Check if room already exists for this property and buyer
    final existingIdx = _rooms.indexWhere(
      (r) => r.propertyId == property.id && (r.buyerId == buyerId || buyerId.isEmpty),
    );

    if (existingIdx != -1) {
      return _rooms[existingIdx];
    }

    final newRoom = DealRoom(
      id: 'DEAL-${DateTime.now().millisecondsSinceEpoch}',
      propertyId: property.id,
      propertyTitle: property.title,
      propertyImage: property.dynamicImageUrl,
      propertyLocation: '${property.effectiveLocality}, ${property.city}',
      listedPriceCr: property.askingPriceCr > 0 ? property.askingPriceCr : (property.price / 10000000),
      buyerId: buyerId.isNotEmpty ? buyerId : 'usr_buyer_active',
      buyerName: buyerName.isNotEmpty ? buyerName : 'Prospective Buyer',
      buyerPhone: buyerPhone,
      buyerEmail: buyerEmail,
      dealerId: dealerId.isNotEmpty ? dealerId : 'dealer_ncr_01',
      dealerName: dealerName.isNotEmpty ? dealerName : 'Aman Sharma (Prime Realty)',
      dealerPhone: dealerPhone.isNotEmpty ? dealerPhone : '+91 98103 94068',
      dealerEmail: dealerEmail,
      stage: DealStage.negotiation,
      dealScore: 88,
      offers: [
        DealOffer(
          id: 'OFF-${DateTime.now().millisecondsSinceEpoch}',
          dealRoomId: 'DEAL-NEW',
          senderId: dealerId,
          senderName: dealerName.isNotEmpty ? dealerName : 'Dealer Desk',
          senderRole: 'Dealer',
          amountCr: property.askingPriceCr,
          note: 'Listed price for ${property.title}',
          status: OfferStatus.pending,
        ),
      ],
      paymentMilestones: [
        PaymentMilestone(id: 'M1', dealRoomId: 'DEAL-NEW', title: '1. Booking Token Amount', amountCr: 0.10, dueDate: 'Within 7 Days', status: MilestoneStatus.pending),
        PaymentMilestone(id: 'M2', dealRoomId: 'DEAL-NEW', title: '2. Agreement to Sale Execution', amountCr: 0.25, dueDate: 'Within 21 Days', status: MilestoneStatus.pending),
        PaymentMilestone(id: 'M3', dealRoomId: 'DEAL-NEW', title: '3. Bank Loan / Construction Installment', amountCr: 1.25, dueDate: '45 Days', status: MilestoneStatus.pending),
        PaymentMilestone(id: 'M4', dealRoomId: 'DEAL-NEW', title: '4. Final Possession & Registry', amountCr: 0.25, dueDate: 'Upon Handover', status: MilestoneStatus.pending),
      ],
      documents: [
        DealDocument(
          id: 'DOC-01',
          dealRoomId: 'DEAL-NEW',
          documentName: 'Sanctioned_Building_Plan.pdf',
          documentType: 'Approved Building Plan',
          uploadedBy: dealerName.isNotEmpty ? dealerName : 'Dealer',
          uploaderRole: 'Dealer',
          fileUrl: 'https://propzen.ai/docs/plan.pdf',
          verificationStatus: 'Verified ✓',
        ),
        DealDocument(
          id: 'DOC-02',
          dealRoomId: 'DEAL-NEW',
          documentName: 'RERA_Registration_Doc.pdf',
          documentType: 'RERA Certificate',
          uploadedBy: dealerName.isNotEmpty ? dealerName : 'Dealer',
          uploaderRole: 'Dealer',
          fileUrl: 'https://propzen.ai/docs/rera.pdf',
          verificationStatus: 'Verified ✓',
        ),
      ],
      messages: [
        DealMessage(
          id: 'MSG-INIT',
          dealRoomId: 'DEAL-NEW',
          senderId: 'system',
          senderName: 'PropZen System',
          senderRole: 'System',
          content: 'Safe Deal Room created for ${property.title}. All participants can now securely review verification documents, negotiate offers, and track payment milestones.',
        ),
      ],
      activityTimeline: [
        DealActivityEvent(
          title: 'Safe Deal Room Initialized',
          description: 'Deal room started for ${property.title}.',
          actorName: buyerName,
          actorRole: 'Buyer',
        ),
      ],
    );

    _rooms.insert(0, newRoom);
    notifyListeners();
    return newRoom;
  }

  void submitOffer({
    required String dealRoomId,
    required String senderId,
    required String senderName,
    required String senderRole,
    required double amountCr,
    String? note,
  }) {
    final idx = _rooms.indexWhere((r) => r.id == dealRoomId);
    if (idx == -1) return;

    final currentRoom = _rooms[idx];
    final updatedOffers = List<DealOffer>.from(currentRoom.offers);

    // Mark previous pending offers as countered
    for (int i = 0; i < updatedOffers.length; i++) {
      if (updatedOffers[i].status == OfferStatus.pending) {
        updatedOffers[i] = updatedOffers[i].copyWith(status: OfferStatus.countered);
      }
    }

    final newOffer = DealOffer(
      id: 'OFF-${DateTime.now().millisecondsSinceEpoch}',
      dealRoomId: dealRoomId,
      senderId: senderId,
      senderName: senderName,
      senderRole: senderRole,
      amountCr: amountCr,
      note: note,
      status: OfferStatus.pending,
      createdAt: DateTime.now(),
    );

    updatedOffers.insert(0, newOffer);

    final updatedTimeline = List<DealActivityEvent>.from(currentRoom.activityTimeline);
    updatedTimeline.insert(
      0,
      DealActivityEvent(
        title: '$senderRole Offer Submitted: ₹${amountCr.toStringAsFixed(2)} Cr',
        description: note ?? '$senderName proposed a revised offer of ₹${amountCr.toStringAsFixed(2)} Cr.',
        actorName: senderName,
        actorRole: senderRole,
        eventType: 'offer',
      ),
    );

    final updatedMessages = List<DealMessage>.from(currentRoom.messages);
    updatedMessages.add(
      DealMessage(
        id: 'MSG-${DateTime.now().millisecondsSinceEpoch}',
        dealRoomId: dealRoomId,
        senderId: senderId,
        senderName: senderName,
        senderRole: senderRole,
        content: 'Proposed an offer of ₹${amountCr.toStringAsFixed(2)} Cr.${note != null && note.isNotEmpty ? " ($note)" : ""}',
        messageType: 'offer_created',
      ),
    );

    _rooms[idx] = currentRoom.copyWith(
      offers: updatedOffers,
      activityTimeline: updatedTimeline,
      messages: updatedMessages,
      stage: DealStage.negotiation,
    );

    notifyListeners();
  }

  void acceptOffer({required String dealRoomId, required String offerId, required String actorName, required String actorRole}) {
    final idx = _rooms.indexWhere((r) => r.id == dealRoomId);
    if (idx == -1) return;

    final currentRoom = _rooms[idx];
    final updatedOffers = List<DealOffer>.from(currentRoom.offers);

    double? agreedPrice;
    for (int i = 0; i < updatedOffers.length; i++) {
      if (updatedOffers[i].id == offerId) {
        updatedOffers[i] = updatedOffers[i].copyWith(status: OfferStatus.accepted);
        agreedPrice = updatedOffers[i].amountCr;
      } else if (updatedOffers[i].status == OfferStatus.pending) {
        updatedOffers[i] = updatedOffers[i].copyWith(status: OfferStatus.rejected);
      }
    }

    final updatedTimeline = List<DealActivityEvent>.from(currentRoom.activityTimeline);
    updatedTimeline.insert(
      0,
      DealActivityEvent(
        title: 'Offer Accepted — Price Finalized at ₹${agreedPrice?.toStringAsFixed(2) ?? ""} Cr! 🎉',
        description: '$actorName accepted the offer. Proceeding to Agreement to Sale (BBA).',
        actorName: actorName,
        actorRole: actorRole,
        eventType: 'deal_milestone',
      ),
    );

    final updatedMessages = List<DealMessage>.from(currentRoom.messages);
    updatedMessages.add(
      DealMessage(
        id: 'MSG-${DateTime.now().millisecondsSinceEpoch}',
        dealRoomId: dealRoomId,
        senderId: 'system',
        senderName: 'PropZen System',
        senderRole: 'System',
        content: '🎉 Offer accepted at ₹${agreedPrice?.toStringAsFixed(2) ?? ""} Cr! Both parties can now proceed with Agreement signing and Payment Milestones.',
      ),
    );

    _rooms[idx] = currentRoom.copyWith(
      offers: updatedOffers,
      agreedPriceCr: agreedPrice,
      stage: DealStage.agreement,
      activityTimeline: updatedTimeline,
      messages: updatedMessages,
    );

    notifyListeners();
  }

  void updateMilestoneStatus({
    required String dealRoomId,
    required String milestoneId,
    required MilestoneStatus status,
    String? paymentRef,
    String? actorName,
  }) {
    final idx = _rooms.indexWhere((r) => r.id == dealRoomId);
    if (idx == -1) return;

    final currentRoom = _rooms[idx];
    final updatedMilestones = List<PaymentMilestone>.from(currentRoom.paymentMilestones);

    final mIdx = updatedMilestones.indexWhere((m) => m.id == milestoneId);
    if (mIdx != -1) {
      final oldM = updatedMilestones[mIdx];
      updatedMilestones[mIdx] = oldM.copyWith(
        status: status,
        paymentReference: paymentRef,
        paidAt: status == MilestoneStatus.paid ? DateTime.now() : null,
      );

      final updatedTimeline = List<DealActivityEvent>.from(currentRoom.activityTimeline);
      updatedTimeline.insert(
        0,
        DealActivityEvent(
          title: 'Milestone Updated: ${oldM.title} → ${status.name.toUpperCase()}',
          description: paymentRef != null ? 'Ref: $paymentRef' : 'Status marked as ${status.name}.',
          actorName: actorName ?? 'User',
          actorRole: 'Participant',
          eventType: 'payment',
        ),
      );

      // Check if all milestones are paid -> mark Deal Completed
      final bool allPaid = updatedMilestones.every((m) => m.status == MilestoneStatus.paid);
      final newStage = allPaid ? DealStage.dealCompleted : DealStage.payment;

      _rooms[idx] = currentRoom.copyWith(
        paymentMilestones: updatedMilestones,
        activityTimeline: updatedTimeline,
        stage: newStage,
      );

      notifyListeners();
    }
  }

  void sendMessage({
    required String dealRoomId,
    required String senderId,
    required String senderName,
    required String senderRole,
    required String content,
  }) {
    final idx = _rooms.indexWhere((r) => r.id == dealRoomId);
    if (idx == -1) return;

    final currentRoom = _rooms[idx];
    final updatedMessages = List<DealMessage>.from(currentRoom.messages);

    updatedMessages.add(
      DealMessage(
        id: 'MSG-${DateTime.now().millisecondsSinceEpoch}',
        dealRoomId: dealRoomId,
        senderId: senderId,
        senderName: senderName,
        senderRole: senderRole,
        content: content,
        timestamp: DateTime.now(),
      ),
    );

    _rooms[idx] = currentRoom.copyWith(messages: updatedMessages);
    notifyListeners();
  }

  void uploadDocument({
    required String dealRoomId,
    required String documentName,
    required String documentType,
    required String uploadedBy,
    required String uploaderRole,
    required String fileUrl,
    String fileSize = '2.4 MB',
  }) {
    final idx = _rooms.indexWhere((r) => r.id == dealRoomId);
    if (idx == -1) return;

    final currentRoom = _rooms[idx];
    final updatedDocs = List<DealDocument>.from(currentRoom.documents);

    updatedDocs.insert(
      0,
      DealDocument(
        id: 'DOC-${DateTime.now().millisecondsSinceEpoch}',
        dealRoomId: dealRoomId,
        documentName: documentName,
        documentType: documentType,
        uploadedBy: uploadedBy,
        uploaderRole: uploaderRole,
        fileUrl: fileUrl,
        fileSize: fileSize,
        verificationStatus: 'Verified ✓',
        uploadedAt: DateTime.now(),
      ),
    );

    final updatedTimeline = List<DealActivityEvent>.from(currentRoom.activityTimeline);
    updatedTimeline.insert(
      0,
      DealActivityEvent(
        title: 'New Document Uploaded: $documentName',
        description: 'Uploaded by $uploadedBy ($uploaderRole) for private deal review.',
        actorName: uploadedBy,
        actorRole: uploaderRole,
        eventType: 'document',
      ),
    );

    _rooms[idx] = currentRoom.copyWith(
      documents: updatedDocs,
      activityTimeline: updatedTimeline,
    );

    notifyListeners();
  }
}
