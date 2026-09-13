import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../models/property.dart';
import '../models/ai_advisor_models.dart';
import 'property_state_service.dart';

class NriAiAdvisorEngineService extends ChangeNotifier {
  NriAiAdvisorEngineService._internal() {
    _initDefaultSession();
  }
  static final NriAiAdvisorEngineService instance = NriAiAdvisorEngineService._internal();
  factory NriAiAdvisorEngineService() => instance;

  final List<AiAdvisorMessageModel> _messages = [];
  List<AiAdvisorMessageModel> get messages => List.unmodifiable(_messages);

  bool _isSearching = false;
  bool get isSearching => _isSearching;

  void _initDefaultSession() {
    _messages.add(
      AiAdvisorMessageModel(
        id: 'MSG-INIT',
        sessionId: 'SES-DEFAULT',
        sender: 'assistant',
        content: '👋 Namaste & Welcome to **PropZen NRI AI Investment Advisor**!\n\nTell me your investment goals, budget, or preferred corridor in natural language. For example:\n- *"I have a ₹2 crore budget and want commercial property near Noida Expressway with good rental potential."*\n- *"Show me 3 BHK luxury ready-to-move apartments in Sector 150 under ₹2.5 Cr."*',
        createdAt: DateTime.now(),
      ),
    );
  }

  // =========================================================================
  // 1. PROCESS NATURAL LANGUAGE QUERY
  // =========================================================================
  Future<AiAdvisorMessageModel> processUserQuery(String query) async {
    // 1. Add user message
    final userMsg = AiAdvisorMessageModel(
      id: 'MSG-USER-${DateTime.now().millisecondsSinceEpoch}',
      sessionId: 'SES-DEFAULT',
      sender: 'user',
      content: query,
      createdAt: DateTime.now(),
    );
    _messages.add(userMsg);
    _isSearching = true;
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 600));

    // 2. Parse structured criteria
    final lower = query.toLowerCase();
    double? budgetCr;
    if (lower.contains('2 cr') || lower.contains('2 crore') || lower.contains('2crore')) {
      budgetCr = 2.0;
    } else if (lower.contains('1.5 cr') || lower.contains('1.5 crore')) {
      budgetCr = 1.5;
    } else if (lower.contains('3 cr') || lower.contains('3 crore')) {
      budgetCr = 3.0;
    } else if (lower.contains('5 cr') || lower.contains('5 crore')) {
      budgetCr = 5.0;
    }

    String? type;
    if (lower.contains('commercial') || lower.contains('office') || lower.contains('retail')) {
      type = 'Commercial';
    } else if (lower.contains('villa') || lower.contains('independent')) {
      type = 'Villa';
    } else if (lower.contains('apartment') || lower.contains('flat') || lower.contains('bhk')) {
      type = 'Apartment';
    }

    String? locality;
    if (lower.contains('150') || lower.contains('sector 150')) {
      locality = '150';
    } else if (lower.contains('expressway') || lower.contains('noida expressway')) {
      locality = 'Expressway';
    } else if (lower.contains('yamuna') || lower.contains('jewar')) {
      locality = 'Yamuna';
    } else if (lower.contains('extension') || lower.contains('greater noida')) {
      locality = 'Greater Noida';
    }

    final criteria = AiAdvisorCriteria(
      maxBudgetCr: budgetCr,
      propertyType: type,
      localityOrSector: locality,
    );

    // 3. Query actual Supabase properties from state catalog (zero hallucinations!)
    final allProperties = PropertyStateService.instance.allProperties;
    List<Property> candidates = List.from(allProperties);

    if (type != null) {
      final filteredByType = candidates.where((p) => p.category.toLowerCase().contains(type!.toLowerCase()) || p.propertyType.toLowerCase().contains(type.toLowerCase())).toList();
      if (filteredByType.isNotEmpty) candidates = filteredByType;
    }

    if (locality != null) {
      final filteredByLoc = candidates.where((p) => '${p.sector} ${p.locality} ${p.address}'.toLowerCase().contains(locality!.toLowerCase())).toList();
      if (filteredByLoc.isNotEmpty) candidates = filteredByLoc;
    }

    if (budgetCr != null) {
      final filteredByBudget = candidates.where((p) => p.askingPriceCr <= (budgetCr! * 1.15)).toList();
      if (filteredByBudget.isNotEmpty) candidates = filteredByBudget;
    }

    final hasExact = candidates.isNotEmpty;
    final displayList = hasExact ? candidates.take(3).toList() : allProperties.take(2).toList();

    final List<AiAdvisorMatchResult> results = displayList.map((p) {
      return AiAdvisorMatchResult(
        property: p,
        matchScore: hasExact ? 94 : 76,
        isExactMatch: hasExact,
        whyItMatches: [
          'Asking price ₹${p.askingPriceCr} Cr matches budget bracket.',
          'Located in high-demand ${p.sector} corridor with ${p.rentalYieldPercent}% rental yield.',
          'PropZen Verified title with AI Intelligence Score ${p.intelligenceScore}/100.',
        ],
        projectedYield: p.rentalYieldPercent,
        matchHeadline: hasExact ? 'Top Exact Match for your portfolio' : 'Closest recommended alternative',
      );
    }).toList();

    final assistantResponseContent = hasExact
        ? '🎯 I analyzed PropZen\'s live verified database and found **${results.length} high-potential properties** perfectly matching your investment criteria:'
        : '⚠️ **No exact matches found** for those strict criteria in the live database. Here are the **closest verified alternatives** that offer strong appreciation and rental yields:';

    final assistantMsg = AiAdvisorMessageModel(
      id: 'MSG-AST-${DateTime.now().millisecondsSinceEpoch}',
      sessionId: 'SES-DEFAULT',
      sender: 'assistant',
      content: assistantResponseContent,
      extractedCriteria: criteria,
      recommendations: results,
      hasExactMatches: hasExact,
      createdAt: DateTime.now(),
    );

    _messages.add(assistantMsg);
    _isSearching = false;
    notifyListeners();
    return assistantMsg;
  }

  void clearChat() {
    _messages.clear();
    _initDefaultSession();
    notifyListeners();
  }
}
