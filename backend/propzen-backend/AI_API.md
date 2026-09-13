# PropZen AI Intelligence — REST API Reference (Phase 11)

All AI endpoints are prefixed with `/api/v1/` and follow standard PropZen JSON response structures with Bearer JWT authentication.

---

## 1. CRM AI Intelligence Endpoints

### 1.1 Calculate or Recalculate Lead Score
- **Route:** `POST /api/v1/ai/crm/lead-score/{leadId}`
- **Role Required:** `DEALER`, `ADMIN`
- **Description:** Computes 0–100 predictive conversion score, intent classification (`HOT`, `WARM`, `COLD`), and key reasons based on live interactions, site visits, and follow-ups. Persists score history to `ai_lead_scores`.
- **Response `200 OK`:**
```json
{
  "success": true,
  "data": {
    "leadId": "3e966f6f-7d43-4b95-81b7-ad4a94223da7",
    "score": 85,
    "classification": "HOT",
    "reasons": [
      "Site visit booked or completed",
      "High recency and engaged dealer interaction"
    ],
    "nextAction": "Schedule final negotiation meeting & contract drafting",
    "confidence": 0.92
  },
  "message": "Lead score calculated successfully",
  "timestamp": "2026-09-08T17:52:00.000Z",
  "requestId": "cfa86e5f-33ae-4368-8c81-5f5e44e0d821"
}
```

### 1.2 Generate Lead Executive Summary
- **Route:** `POST /api/v1/ai/crm/lead-summary/{leadId}`
- **Role Required:** `DEALER`, `ADMIN`
- **Description:** Produces a concise executive brief of lead stage, preferences, and sentiment.
- **Response `200 OK`:**
```json
{
  "success": true,
  "data": {
    "leadId": "aa76bd2e-25ed-4e10-b573-dbe254fe7ca4",
    "summary": "Lead Pooja Sharma is actively looking for properties with verified high-intent engagement.",
    "priority": "HIGH",
    "sentiment": "POSITIVE",
    "recommendedAction": "Follow up via WhatsApp with verified project details",
    "suggestedFollowUp": "Follow up in 24 hours",
    "keyMilestones": ["Inquiry Received", "Contact Established"]
  },
  "message": "Lead summary generated successfully"
}
```

### 1.3 Recommend Next Best Action
- **Route:** `POST /api/v1/ai/crm/next-action/{leadId}`
- **Role Required:** `DEALER`, `ADMIN`
- **Description:** Recommends optimal CRM workflow action, preferred channel, priority, and SLA.
- **Response `200 OK`:**
```json
{
  "success": true,
  "data": {
    "leadId": "aa76bd2e-25ed-4e10-b573-dbe254fe7ca4",
    "action": "Confirm site visit route & prepare property documentation dossier",
    "channel": "WHATSAPP",
    "priority": "URGENT",
    "dueWithin": "2 Hours",
    "reason": "Stage SITE_VISIT_BOOKED workflow protocol"
  },
  "message": "Next action recommended successfully"
}
```

### 1.4 Generate Follow-Up Draft
- **Route:** `POST /api/v1/ai/crm/follow-up/{leadId}`
- **Role Required:** `DEALER`, `ADMIN`
- **Description:** Generates a ready-to-send personalized message draft and recommended contact timing.
- **Response `200 OK`:**
```json
{
  "success": true,
  "data": {
    "leadId": "aa76bd2e-25ed-4e10-b573-dbe254fe7ca4",
    "suggestedDate": "2026-09-09T17:52:00Z",
    "suggestedChannel": "WHATSAPP",
    "intent": "SITE_VISIT_CONFIRMATION",
    "suggestedMessage": "Hello Pooja Sharma, thank you for your interest in Property #P-100. We have prepared exclusive floor plans and site visit slots for this weekend. Would 11:00 AM work best for you?",
    "rationale": "Pre-visit engagement draft tailored to customer listing exploration"
  },
  "message": "Follow-up draft generated successfully"
}
```

### 1.5 Summarize Customer Conversation
- **Route:** `POST /api/v1/ai/crm/conversation-summary/{leadId}`
- **Role Required:** `DEALER`, `ADMIN`
- **Request Body:**
```json
{
  "conversationText": "Customer called at 4 PM. Very excited about Golf Course Extension road projects. Wants 4 BHK with 2 car parks."
}
```
- **Response `200 OK`:**
```json
{
  "success": true,
  "data": {
    "leadId": "3c85a78f-c6ad-4dcb-bb75-f992886795e3",
    "summary": "Customer discussed unit preferences, pricing queries, and availability. Key focus: floor preference and possession dates.",
    "priority": "HIGH",
    "sentiment": "POSITIVE",
    "recommendedAction": "Send verified registry details and RERA certification confirmation",
    "suggestedFollowUp": "Follow up via phone in 48 hours"
  },
  "message": "Conversation summarized successfully"
}
```

---

## 2. Property AI Endpoints

### 2.1 Get Match-Ranked Property Recommendations
- **Route:** `POST /api/v1/ai/properties/recommendations`
- **Role Required:** Authenticated (`BUYER`, `DEALER`, `ADMIN`)
- **Request Body:**
```json
{
  "city": "Gurgaon",
  "sector": "Golf Course Road",
  "bhk": "4 BHK",
  "propertyType": "Apartment",
  "maxBudgetCr": 15.00
}
```
- **Response `200 OK`:**
```json
{
  "success": true,
  "data": [
    {
      "propertyId": "9b1deb4d-3b7d-4bad-9bdd-2b0d7b3dcb6d",
      "title": "The Magnolias Ultra Luxury 4 BHK",
      "city": "Gurgaon",
      "sector": "Golf Course Road",
      "bhk": "4 BHK",
      "propertyType": "Apartment",
      "priceCr": 12.50,
      "sqft": 4500,
      "matchPercentage": 96.5,
      "matchHighlights": [
        "Matches preferred city Gurgaon",
        "Matches desired layout 4 BHK",
        "Priced well within maximum budget of 15.00 Cr"
      ]
    }
  ],
  "message": "Property recommendations generated successfully"
}
```

### 2.2 Generate High-Converting Property Listing & SEO Metadata
- **Route:** `POST /api/v1/ai/properties/generate-description`
- **Role Required:** `DEALER`, `ADMIN`
- **Request Body:**
```json
{
  "title": "Grand View Penthouse",
  "city": "Gurgaon",
  "sector": "Sector 54",
  "bhk": "3 BHK",
  "propertyType": "Penthouse",
  "priceCr": 4.20,
  "sqft": 2800,
  "amenities": ["Infinity Pool", "Private Terrace", "24/7 Concierge"]
}
```
- **Response `200 OK`:**
```json
{
  "success": true,
  "data": {
    "shortDescription": "Impeccably appointed 3 BHK Penthouse spanning 2800 sq.ft. in Sector 54, Gurgaon.",
    "detailedDescription": "Welcome to Grand View Penthouse, offering world-class living in the heart of Sector 54, Gurgaon. Featuring 3 BHK spacious layouts, expansive balconies with panoramic views, and premium architectural detailing...",
    "highlights": [
      "Expansive 3 BHK modern floor plan with 2800 sq.ft. usable area",
      "Prestigious prime sector address in Gurgaon",
      "Contemporary architectural finish and vastu-compliant layout",
      "High-yield investment potential"
    ],
    "seoTitle": "Grand View Penthouse | 3 BHK Penthouse in Sector 54, Gurgaon - PropZen",
    "seoDescription": "Explore Grand View Penthouse in Sector 54, Gurgaon. 3 BHK premium Penthouse with state-of-the-art amenities and verified legal title on PropZen.",
    "keywords": ["Gurgaon", "Sector 54", "3 BHK", "Penthouse", "luxury real estate", "verified property", "PropZen"]
  },
  "message": "Property description generated successfully"
}
```

---

## 3. Enquiry AI Endpoints

### 3.1 Classify Customer Enquiry
- **Route:** `POST /api/v1/ai/enquiries/{id}/classify`
- **Role Required:** `DEALER`, `ADMIN`
- **Description:** Analyzes enquiry message, detecting intent category (`SITE_VISIT`, `PRICING`, `LEGAL`, `GENERAL`), priority, sentiment, and recommended department. Persists result in `ai_enquiry_classifications`.
- **Response `200 OK`:**
```json
{
  "success": true,
  "data": {
    "enquiryId": "fd9d3c19-1714-45e7-83ae-3871a5876cf2",
    "category": "SITE_VISIT",
    "priority": "URGENT",
    "sentiment": "NEUTRAL",
    "suggestedDepartment": "SITE_VISIT_OPERATIONS",
    "suggestedAction": "Schedule on-site escort and dispatch property brochure",
    "confidence": 0.95
  },
  "message": "Enquiry classified successfully"
}
```

---

## 4. Document Intelligence Endpoints

### 4.1 Analyze Document Metadata & Completeness
- **Route:** `POST /api/v1/ai/documents/analyze`
- **Role Required:** Authenticated (`SERVICE_PARTNER`, `DEALER`, `ADMIN`)
- **Request Body:**
```json
{
  "fileName": "Property_Sale_Deed_Encumbrance_Certificate.pdf",
  "mimeType": "application/pdf",
  "fileSize": 2048500
}
```
- **Response `200 OK`:**
```json
{
  "success": true,
  "data": {
    "documentType": "SALE_DEED",
    "verificationStatus": "VERIFIED",
    "confidenceScore": 0.88,
    "extractedAttributes": {
      "documentCategory": "Conveyance & Sale Deed",
      "registrationJurisdiction": "Sub-Registrar Authority"
    },
    "flaggedDiscrepancies": [],
    "humanReviewRecommendation": "Document format and preliminary metadata structural checks passed"
  },
  "message": "Document analyzed successfully"
}
```

---

## 5. Market Intelligence Endpoints

### 5.1 Real Estate Market Trends & Sector Analytics
- **Route:** `GET /api/v1/ai/market/trends?city=Gurgaon&sector=Golf%20Course%20Road`
- **Role Required:** Authenticated
- **Response `200 OK`:**
```json
{
  "success": true,
  "data": {
    "city": "Gurgaon",
    "sector": "Golf Course Road",
    "sufficientData": true,
    "statusMessage": "SUFFICIENT_DATA",
    "totalActiveListings": 45,
    "averageAskingPriceCr": 4.25,
    "demandByBhk": {
      "2 BHK": 25,
      "3 BHK": 55,
      "4 BHK": 20
    },
    "marketTrends": [
      "High demand for luxury 3 & 4 BHK units in Golf Course Road",
      "Price appreciation of approximately 8.2% recorded over the past 6 months"
    ],
    "priceTrendIndicator": "INCREASING"
  },
  "message": "Market intelligence retrieved successfully"
}
```

---

## 6. Portals & BI Endpoints

### 6.1 Admin Platform AI Insights
- **Route:** `GET /api/v1/admin/ai/insights`
- **Role Required:** `ADMIN`
- **Response `200 OK`:**
```json
{
  "success": true,
  "data": {
    "hotLeadsCount": 12,
    "unattendedLeadsCount": 24,
    "overdueFollowUpsCount": 4,
    "pendingVerificationsCount": 3,
    "operationalRisks": [],
    "strategicRecommendations": [
      "Lead pipeline and partner operations functioning within nominal thresholds",
      "Launch targeted WhatsApp promotional broadcast for high-demand sectors"
    ],
    "platformHealthIndex": "EXCELLENT"
  }
}
```

### 6.2 Admin AI Usage & Cost Telemetry
- **Route:** `GET /api/v1/admin/ai/usage`
- **Role Required:** `ADMIN`
- **Response `200 OK`:**
```json
{
  "success": true,
  "data": {
    "totalRequests": 184,
    "successfulRequests": 184,
    "failedRequests": 0,
    "fallbackRequests": 0,
    "averageLatencyMs": 18.4,
    "totalTokensUsed": 0,
    "estimatedCostUsd": 0.0,
    "activeProvider": "LOCAL"
  }
}
```

### 6.3 Dealer Portal AI Insights (Tenant-Isolated)
- **Route:** `GET /api/v1/dealer/ai/insights`
- **Role Required:** `DEALER`, `ADMIN`
- **Response `200 OK`:**
```json
{
  "success": true,
  "data": {
    "dealerId": "9e2c4b8b-3e5f-4a6c-9c7d-8e9f0a1b2c3d",
    "totalAssignedLeads": 15,
    "hotLeads": 5,
    "conversionRate": 20.0,
    "listingRecommendations": [
      "Update property listings with high-resolution walkthrough photos to boost engagement"
    ],
    "leadFollowUpAlerts": [
      "2 leads awaiting response for over 12 hours"
    ],
    "dealerPerformanceGrade": "A+"
  }
}
```

### 6.4 Service Partner Portal AI Insights (Tenant-Isolated)
- **Route:** `GET /api/v1/partner/ai/insights`
- **Role Required:** `SERVICE_PARTNER`, `ADMIN`
- **Response `200 OK`:**
```json
{
  "success": true,
  "data": {
    "partnerId": "7b3d2e1c-5a6f-4b8c-9d0e-1f2a3b4c5d6e",
    "totalAssignedRequests": 20,
    "completedRequests": 18,
    "completionRate": 90.0,
    "averageRating": 4.8,
    "feedbackSentiment": "EXCELLENT",
    "operationalTips": [
      "Maintain active SLA updates to sustain top-tier partner allocation priority"
    ],
    "capacityStatus": "OPTIMAL"
  }
}
```
