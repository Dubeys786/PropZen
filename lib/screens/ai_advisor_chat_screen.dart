import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../models/property.dart';
import '../models/lead_model.dart';
import '../services/property_state_service.dart';
import '../services/propzen_ai_agent_service.dart';
import '../services/propzen_voice_service.dart';
import '../services/dealer_lead_service.dart';
import '../theme/app_theme.dart';
import '../routes/app_routes.dart';
import 'user_profile_screen.dart';
import 'property_details_screen.dart';
import 'dealer_subscription_plans_screen.dart';
import 'nri_subscription_plans_screen.dart';
import '../widgets/property_card.dart';
import '../widgets/nri_drone_tour_player_modal.dart';
import '../widgets/property_360_tour_viewer.dart';
import '../widgets/property_3d_model_viewer.dart';
import '../widgets/property_floor_plan_viewer.dart';
import '../widgets/nri_remote_tour_dialog.dart';
import '../widgets/nri_investment_calculator_dialog.dart';
import '../widgets/nri_loan_assistance_dialog.dart';
import '../widgets/nri_document_concierge_modal.dart';
import '../widgets/nri_family_decision_dialog.dart';

class AiAdvisorChatScreen extends StatefulWidget {
  final Property? property;
  final String? initialQuery;

  const AiAdvisorChatScreen({
    super.key,
    this.property,
    this.initialQuery,
  });

  @override
  State<AiAdvisorChatScreen> createState() => _AiAdvisorChatScreenState();
}

class _AiAdvisorChatScreenState extends State<AiAdvisorChatScreen> with SingleTickerProviderStateMixin {
  final PropzenAiAgentService _aiAgent = PropzenAiAgentService.instance;
  final PropzenVoiceService _voiceService = PropzenVoiceService.instance;
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  late final AnimationController _pulseController;
  String _selectedLangCode = 'hi-IN'; // 'hi-IN' for Hindi & Hinglish, 'en-IN' for English
  String _speakingMessageText = '';
  bool _isProcessingQuery = false;

  final List<String> _quickShortcuts = [
    '🏠 Find Property',
    '💰 Search by Budget',
    '📍 Search by Location',
    '🛏️ Search by BHK',
    '⭐ Recommended',
    '⚖️ Compare Properties',
    '📅 Book Site Visit',
    '🎥 Drone Tour',
  ];

  @override
  void initState() {
    super.initState();
    _voiceService.initialize();
    _voiceService.stateNotifier.addListener(_onVoiceStateChanged);

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeChatSession();
    });
  }

  void _onVoiceStateChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _voiceService.stateNotifier.removeListener(_onVoiceStateChanged);
    _voiceService.stopAll();
    _pulseController.dispose();
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _initializeChatSession() {
    if (widget.property != null) {
      _aiAgent.context.selectedProperty = widget.property;
      _aiAgent.context.location = widget.property!.sector;
      _aiAgent.context.bedrooms = int.tryParse(widget.property!.bhk.split(' ').first) ?? 3;
    }

    if (_aiAgent.sessionHistory.isEmpty) {
      final greetingLang = (_selectedLangCode == 'en-IN') ? 'english' : 'hinglish';
      _aiAgent.startProactiveTurn(language: greetingLang);
      setState(() {});
    }

    if (widget.initialQuery != null && widget.initialQuery!.trim().isNotEmpty) {
      _handleUserSubmit(widget.initialQuery!);
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _handleUserSubmit(String query) async {
    final text = query.trim();
    if (text.isEmpty) return;

    _textController.clear();
    _voiceService.stopSpeaking();
    _voiceService.stopListening();
    _voiceService.stateNotifier.value = VoiceAgentState.thinking;

    setState(() {
      _isProcessingQuery = true;
    });
    _scrollToBottom();

    // Process through unified multilingual AI engine
    final result = await _aiAgent.processDialogue(text);

    if (!mounted) return;

    setState(() {
      _isProcessingQuery = false;
    });
    _scrollToBottom();

    // Check for triggered action execution
    if (result.triggeredAction != null) {
      _executeTriggeredAction(result.triggeredAction!, result.actionTargetProperty ?? (result.matchedProperties.isNotEmpty ? result.matchedProperties.first : null));
    }

    // Play natural female voice output
    final ttsLang = (result.language == 'english') ? 'en-IN' : 'hi-IN';
    _speakingMessageText = result.speechResponse;

    await _voiceService.speak(
      result.speechResponse,
      languageCode: ttsLang,
      onCompleted: () {
        if (mounted) {
          setState(() {
            _speakingMessageText = '';
          });
        }
      },
    );
  }

  void _executeTriggeredAction(String action, Property? prop) {
    final targetProp = prop ?? _aiAgent.context.selectedProperty ?? (PropertyStateService.instance.allProperties.isNotEmpty ? PropertyStateService.instance.allProperties.first : null);

    switch (action) {
      case 'open_details':
        if (targetProp != null) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => PropertyDetailsScreen(property: targetProp)),
          );
        }
        break;
      case 'open_drone':
        if (targetProp != null) {
          NriDroneTourPlayerModal.show(context, targetProp);
        }
        break;
      case 'open_360':
        if (targetProp != null) {
          Property360TourViewer.show(context, targetProp);
        }
        break;
      case 'open_3d':
        if (targetProp != null) {
          Property3DModelViewer.show(context, targetProp);
        }
        break;
      case 'book_site_visit':
        // Guided in-chat flow active
        break;
      case 'request_remote_tour':
        if (targetProp != null) {
          NriRemoteTourDialog.show(context, property: targetProp);
        }
        break;
      case 'view_plans':
        if (UserSession.isDealer) {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const DealerSubscriptionPlansScreen()));
        } else {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const NriSubscriptionPlansScreen()));
        }
        break;
      case 'open_investment_calc':
        if (targetProp != null) {
          NriInvestmentCalculatorDialog.show(context, property: targetProp);
        }
        break;
      case 'open_loan_assistance':
        if (targetProp != null) {
          NriLoanAssistanceDialog.show(context, property: targetProp);
        }
        break;
      case 'open_deal_room':
        Navigator.pushNamed(context, AppRoutes.dealRoom);
        break;
    }
  }

  Future<void> _startVoiceListening() async {
    // Barge-in: immediately stop speaking
    _voiceService.stopSpeaking();

    await _voiceService.startListening(
      languageCode: _selectedLangCode,
      onResult: (text, isFinal) {
        if (isFinal && text.trim().isNotEmpty) {
          _handleUserSubmit(text.trim());
        }
      },
      onError: (err) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Microphone: $err'),
              backgroundColor: AppTheme.coralDanger,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      },
      onDone: () {
        final currentText = _voiceService.liveTranscriptNotifier.value.trim();
        if (currentText.isNotEmpty && _voiceService.stateNotifier.value == VoiceAgentState.idle) {
          _handleUserSubmit(currentText);
        }
      },
    );
  }

  void _stopVoiceSpeaking() {
    _voiceService.stopSpeaking();
    setState(() {
      _speakingMessageText = '';
    });
  }

  void _speakMessage(String text, String lang) {
    _voiceService.stopSpeaking();
    final ttsLang = (lang == 'english') ? 'en-IN' : 'hi-IN';
    setState(() {
      _speakingMessageText = text;
    });

    _voiceService.speak(
      text,
      languageCode: ttsLang,
      onCompleted: () {
        if (mounted) {
          setState(() {
            _speakingMessageText = '';
          });
        }
      },
    );
  }

  void _handleShortcutTap(String shortcut) {
    switch (shortcut) {
      case '🏠 Find Property':
        _handleUserSubmit('Mujhe NCR mein verified residential property chahiye');
        break;
      case '💰 Search by Budget':
        _handleUserSubmit('Mujhe 80 lakh ke andar best properties dikhao');
        break;
      case '📍 Search by Location':
        _handleUserSubmit('Greater Noida aur Sector 150 mein properties dikhao');
        break;
      case '🛏️ Search by BHK':
        _handleUserSubmit('Mujhe 3 BHK luxury flats dikhao');
        break;
      case '⭐ Recommended':
        _handleUserSubmit('Top recommended properties with highest rating dikhao');
        break;
      case '⚖️ Compare Properties':
        _handleUserSubmit('Top 2 properties ko side by side compare karo');
        break;
      case '📅 Book Site Visit':
        _handleUserSubmit('Mujhe site visit book karni hai');
        break;
      case '🎥 Drone Tour':
        _handleUserSubmit('4K aerial drone tour dikhao');
        break;
      default:
        _handleUserSubmit(shortcut);
    }
  }

  @override
  Widget build(BuildContext context) {
    final voiceState = _voiceService.stateNotifier.value;
    final isListening = voiceState == VoiceAgentState.listening;
    final isSpeaking = voiceState == VoiceAgentState.speaking;
    final isThinking = voiceState == VoiceAgentState.thinking || _isProcessingQuery;

    final isDealer = UserSession.isDealer;
    final isNri = UserSession.isNri;

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A), // Premium Dark Slate Background
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        elevation: 1,
        titleSpacing: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [Color(0xFF6366F1), Color(0xFFEC4899)],
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF6366F1).withOpacity(0.4),
                    blurRadius: 10,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: const Icon(LucideIcons.bot, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'PropZen AI',
                        style: GoogleFonts.outfit(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFF10B981).withOpacity(0.4)),
                        ),
                        child: Text(
                          'Female Voice Active',
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF34D399),
                          ),
                        ),
                      ),
                    ],
                  ),
                  Text(
                    isSpeaking
                        ? 'PropZen AI is speaking...'
                        : isListening
                            ? 'Listening to you...'
                            : isThinking
                                ? 'Analyzing verified inventory...'
                                : 'Hindi • Hinglish • English Assistant',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: isSpeaking
                          ? const Color(0xFFEC4899)
                          : isListening
                              ? const Color(0xFF38BDF8)
                              : Colors.white60,
                      fontWeight: isSpeaking || isListening ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          // User Role Pill
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: isDealer
                  ? const Color(0xFF3B82F6).withOpacity(0.2)
                  : isNri
                      ? const Color(0xFFF59E0B).withOpacity(0.2)
                      : const Color(0xFF64748B).withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDealer
                    ? const Color(0xFF3B82F6).withOpacity(0.5)
                    : isNri
                        ? const Color(0xFFF59E0B).withOpacity(0.5)
                        : const Color(0xFF64748B).withOpacity(0.5),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isDealer ? LucideIcons.briefcase : isNri ? LucideIcons.globe : LucideIcons.user,
                  size: 13,
                  color: isDealer ? const Color(0xFF60A5FA) : isNri ? const Color(0xFFFBBF24) : Colors.white70,
                ),
                const SizedBox(width: 4),
                Text(
                  isDealer ? 'Dealer' : isNri ? 'NRI Buyer' : 'Buyer',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isDealer ? const Color(0xFF60A5FA) : isNri ? const Color(0xFFFBBF24) : Colors.white70,
                  ),
                ),
              ],
            ),
          ),
          // Language Switcher Button
          PopupMenuButton<String>(
            icon: const Icon(LucideIcons.languages, color: Colors.white70, size: 20),
            tooltip: 'Change Language',
            color: const Color(0xFF1E293B),
            onSelected: (code) {
              setState(() {
                _selectedLangCode = code;
              });
              final langLabel = (code == 'hi-IN') ? 'Hindi / Hinglish' : 'Indian English';
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Voice Language: $langLabel (Female Voice)'),
                  backgroundColor: const Color(0xFF6366F1),
                  duration: const Duration(seconds: 2),
                ),
              );
            },
            itemBuilder: (_) => [
              PopupMenuItem(
                value: 'hi-IN',
                child: Row(
                  children: [
                    const Text('🇮🇳 ', style: TextStyle(fontSize: 16)),
                    Text(
                      'Hindi / Hinglish',
                      style: GoogleFonts.inter(
                        color: _selectedLangCode == 'hi-IN' ? const Color(0xFF38BDF8) : Colors.white,
                        fontWeight: _selectedLangCode == 'hi-IN' ? FontWeight.w700 : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'en-IN',
                child: Row(
                  children: [
                    const Text('🇬🇧 ', style: TextStyle(fontSize: 16)),
                    Text(
                      'English (India)',
                      style: GoogleFonts.inter(
                        color: _selectedLangCode == 'en-IN' ? const Color(0xFF38BDF8) : Colors.white,
                        fontWeight: _selectedLangCode == 'en-IN' ? FontWeight.w700 : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          // Clear Chat
          IconButton(
            icon: const Icon(LucideIcons.trash2, color: Colors.white54, size: 19),
            tooltip: 'Clear Conversation',
            onPressed: () {
              _aiAgent.clearSession();
              _voiceService.stopAll();
              _initializeChatSession();
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Active Live Transcript Banner (when listening)
            ValueListenableBuilder<String>(
              valueListenable: _voiceService.liveTranscriptNotifier,
              builder: (context, transcript, _) {
                if (transcript.isEmpty) return const SizedBox.shrink();
                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF38BDF8).withOpacity(0.15),
                    border: const Border(
                      bottom: BorderSide(color: Color(0xFF38BDF8), width: 1),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(LucideIcons.mic, size: 16, color: Color(0xFF38BDF8)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Hearing: "$transcript"',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFFBAE6FD),
                            fontStyle: FontStyle.italic,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),

            // Main Message Feed
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                itemCount: _aiAgent.sessionHistory.length + (_isProcessingQuery ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == _aiAgent.sessionHistory.length && _isProcessingQuery) {
                    return _buildThinkingBubble();
                  }
                  final msg = _aiAgent.sessionHistory[index];
                  return _buildMessageBubble(msg);
                },
              ),
            ),

            // Quick Shortcuts Bar
            Container(
              height: 42,
              padding: const EdgeInsets.symmetric(vertical: 4),
              color: const Color(0xFF0B1120),
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: _quickShortcuts.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, i) {
                  final s = _quickShortcuts[i];
                  return ActionChip(
                    backgroundColor: const Color(0xFF1E293B),
                    side: const BorderSide(color: Color(0xFF334155)),
                    label: Text(
                      s,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFFE2E8F0),
                      ),
                    ),
                    onPressed: () => _handleShortcutTap(s),
                  );
                },
              ),
            ),

            // Voice & Text Input Bar
            _buildInputControlBar(isListening, isSpeaking, isThinking),
          ],
        ),
      ),
    );
  }

  Widget _buildThinkingBubble() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12, right: 48),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF6366F1).withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Color(0xFF818CF8),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'PropZen AI is understanding your query...',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontStyle: FontStyle.italic,
                color: const Color(0xFF94A3B8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageBubble(ConversationMessage msg) {
    final isUser = msg.role == 'user';
    final isSpeakingThis = _speakingMessageText == msg.text;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * (isUser ? 0.78 : 0.90),
        ),
        child: Column(
          crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            // Message bubble container
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isUser
                    ? const Color(0xFF4F46E5) // Indigo user bubble
                    : const Color(0xFF1E293B), // Dark Slate AI bubble
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: Radius.circular(isUser ? 18 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 18),
                ),
                border: Border.all(
                  color: isSpeakingThis
                      ? const Color(0xFFEC4899)
                      : isUser
                          ? const Color(0xFF6366F1)
                          : const Color(0xFF334155),
                  width: isSpeakingThis ? 1.5 : 1.0,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.18),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Text Content
                  Text(
                    msg.text,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      height: 1.45,
                      color: Colors.white,
                      fontWeight: isUser ? FontWeight.w500 : FontWeight.w400,
                    ),
                  ),

                  // Assistant Audio Play / Stop Action
                  if (!isUser) ...[
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            GestureDetector(
                              onTap: () {
                                if (isSpeakingThis) {
                                  _stopVoiceSpeaking();
                                } else {
                                  _speakMessage(msg.text, msg.language);
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: isSpeakingThis
                                      ? const Color(0xFFEC4899).withOpacity(0.2)
                                      : const Color(0xFF334155),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      isSpeakingThis ? LucideIcons.volumeX : LucideIcons.volume2,
                                      size: 13,
                                      color: isSpeakingThis ? const Color(0xFFF472B6) : const Color(0xFF94A3B8),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      isSpeakingThis ? 'Stop Voice' : 'Play Voice',
                                      style: GoogleFonts.inter(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: isSpeakingThis ? const Color(0xFFF472B6) : const Color(0xFFCBD5E1),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        Text(
                          '${msg.timestamp.hour.toString().padLeft(2, '0')}:${msg.timestamp.minute.toString().padLeft(2, '0')}',
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            color: Colors.white38,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),

            // Rich Property Cards Attachment
            if (msg.properties != null && msg.properties!.isNotEmpty && msg.flowType != 'comparison') ...[
              const SizedBox(height: 10),
              SizedBox(
                height: 240,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: msg.properties!.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (context, pIdx) {
                    final prop = msg.properties![pIdx];
                    return _buildPropertyMiniCard(prop);
                  },
                ),
              ),
            ],

            // Side-by-Side Comparison Matrix Attachment
            if (msg.comparisonData != null || (msg.flowType == 'comparison' && msg.properties != null && msg.properties!.length >= 2)) ...[
              const SizedBox(height: 10),
              _buildComparisonMatrixCard(msg),
            ],

            // Dealer Leads Cards Attachment
            if (msg.dealerLeads != null && msg.dealerLeads!.isNotEmpty) ...[
              const SizedBox(height: 10),
              _buildDealerLeadsCard(msg.dealerLeads!),
            ],

            // Suggested Action Chips
            if (msg.suggestedChips != null && msg.suggestedChips!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: msg.suggestedChips!.map((chip) {
                  return InkWell(
                    onTap: () => _handleUserSubmit(chip),
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: const Color(0xFF334155),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFF6366F1).withOpacity(0.4)),
                      ),
                      child: Text(
                        chip,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFFBAE6FD),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPropertyMiniCard(Property prop) {
    return Container(
      width: 250,
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image banner with badges
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
                child: Image.network(
                  prop.imageUrl,
                  height: 110,
                  width: 250,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    height: 110,
                    color: const Color(0xFF334155),
                    child: const Center(child: Icon(LucideIcons.home, color: Colors.white54, size: 28)),
                  ),
                ),
              ),
              Positioned(
                top: 6,
                left: 6,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '100% RERA',
                    style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.w700, color: Colors.white),
                  ),
                ),
              ),
              if (prop.hasDroneTour)
                Positioned(
                  top: 6,
                  right: 6,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6366F1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(LucideIcons.video, size: 10, color: Colors.white),
                        const SizedBox(width: 2),
                        Text(
                          '4K Drone',
                          style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.w700, color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),

          // Details Body
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  prop.title,
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${prop.sector}, ${prop.city} • ${prop.bhk}',
                  style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF94A3B8)),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      prop.priceRangeDisplay,
                      style: GoogleFonts.outfit(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF38BDF8),
                      ),
                    ),
                    Text(
                      '${prop.sqft} sq.ft.',
                      style: GoogleFonts.inter(fontSize: 10, color: Colors.white60),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                // Action Buttons Row
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4F46E5),
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          minimumSize: const Size(0, 26),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => PropertyDetailsScreen(property: prop)),
                          );
                        },
                        child: Text(
                          'Details',
                          style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.white),
                        ),
                      ),
                    ),
                    if (prop.hasDroneTour) ...[
                      const SizedBox(width: 4),
                      IconButton(
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 26, minHeight: 26),
                        icon: const Icon(LucideIcons.video, size: 14, color: Color(0xFF38BDF8)),
                        tooltip: 'Watch Drone Tour',
                        onPressed: () => NriDroneTourPlayerModal.show(context, prop),
                      ),
                    ],
                    const SizedBox(width: 4),
                    IconButton(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 26, minHeight: 26),
                      icon: const Icon(LucideIcons.calendar, size: 14, color: Color(0xFF10B981)),
                      tooltip: 'Book Site Visit',
                      onPressed: () => _handleUserSubmit('Book site visit for ${prop.title}'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComparisonMatrixCard(ConversationMessage msg) {
    final props = msg.properties ?? [];
    if (props.length < 2) return const SizedBox.shrink();

    final p1 = props[0];
    final p2 = props[1];

    final comp = msg.comparisonData;
    final betterBudget = comp?['betterBudget'] ?? (p1.askingPriceCr <= p2.askingPriceCr ? p1.title : p2.title);
    final betterSize = comp?['betterSize'] ?? (p1.sqft >= p2.sqft ? p1.title : p2.title);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF6366F1).withOpacity(0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(LucideIcons.scale, color: Color(0xFF818CF8), size: 16),
              const SizedBox(width: 6),
              Text(
                'Side-by-Side Property Comparison',
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Table(
            border: TableBorder.all(color: const Color(0xFF334155)),
            children: [
              TableRow(
                decoration: const BoxDecoration(color: Color(0xFF0F172A)),
                children: [
                  _buildTableCell('Metric', isHeader: true),
                  _buildTableCell(p1.title, isHeader: true),
                  _buildTableCell(p2.title, isHeader: true),
                ],
              ),
              TableRow(
                children: [
                  _buildTableCell('Price'),
                  _buildTableCell(p1.priceRangeDisplay),
                  _buildTableCell(p2.priceRangeDisplay),
                ],
              ),
              TableRow(
                children: [
                  _buildTableCell('Area (Sq.ft.)'),
                  _buildTableCell('${p1.sqft}'),
                  _buildTableCell('${p2.sqft}'),
                ],
              ),
              TableRow(
                children: [
                  _buildTableCell('BHK Layout'),
                  _buildTableCell(p1.bhk),
                  _buildTableCell(p2.bhk),
                ],
              ),
              TableRow(
                children: [
                  _buildTableCell('Location'),
                  _buildTableCell(p1.sector),
                  _buildTableCell(p2.sector),
                ],
              ),
              TableRow(
                children: [
                  _buildTableCell('Remote Tours'),
                  _buildTableCell(p1.hasDroneTour ? '4K Drone + 360' : '360° Panorama'),
                  _buildTableCell(p2.hasDroneTour ? '4K Drone + 360' : '360° Panorama'),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '💡 AI Verdict:',
                  style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: const Color(0xFF38BDF8)),
                ),
                const SizedBox(height: 2),
                Text(
                  '• Budget Friendly: $betterBudget\n• Maximum Living Area: $betterSize',
                  style: GoogleFonts.inter(fontSize: 11, color: Colors.white70, height: 1.3),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTableCell(String text, {bool isHeader = false}) {
    return Padding(
      padding: const EdgeInsets.all(6.0),
      child: Text(
        text,
        style: GoogleFonts.inter(
          fontSize: 10,
          fontWeight: isHeader ? FontWeight.w700 : FontWeight.w500,
          color: isHeader ? const Color(0xFF38BDF8) : Colors.white,
        ),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _buildDealerLeadsCard(List<DealerLead> leads) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF3B82F6).withOpacity(0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(LucideIcons.users, color: Color(0xFF60A5FA), size: 16),
              const SizedBox(width: 6),
              Text(
                'Active Dealer Leads (${leads.length})',
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...leads.take(3).map((lead) {
            final isHot = lead.scoreTier == LeadScoreTier.hot;
            return Container(
              margin: const EdgeInsets.only(bottom: 6),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${lead.buyerName} • ${lead.requirement}',
                          style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white),
                        ),
                        Text(
                          'Budget: ₹${lead.budgetCr.toStringAsFixed(2)} Cr • Score: ${lead.leadScore}/100',
                          style: GoogleFonts.inter(fontSize: 10, color: const Color(0xFF94A3B8)),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: isHot ? const Color(0xFFEF4444).withOpacity(0.2) : const Color(0xFF3B82F6).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      isHot ? '🔥 HOT' : 'WARM',
                      style: GoogleFonts.inter(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: isHot ? const Color(0xFFF87171) : const Color(0xFF60A5FA),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildInputControlBar(bool isListening, bool isSpeaking, bool isThinking) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: const BoxDecoration(
        color: Color(0xFF1E293B),
        border: Border(
          top: BorderSide(color: Color(0xFF334155), width: 1),
        ),
      ),
      child: Row(
        children: [
          // Microphone Pulsating Voice Button
          GestureDetector(
            onTap: () {
              if (isSpeaking) {
                _stopVoiceSpeaking();
              } else if (isListening) {
                _voiceService.stopListening();
              } else {
                _startVoiceListening();
              }
            },
            child: AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) {
                final pulseScale = (isListening || isSpeaking) ? 1.0 + (_pulseController.value * 0.12) : 1.0;
                return Transform.scale(
                  scale: pulseScale,
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: isListening
                          ? const LinearGradient(colors: [Color(0xFFEF4444), Color(0xFFDC2626)])
                          : isSpeaking
                              ? const LinearGradient(colors: [Color(0xFFEC4899), Color(0xFFD946EF)])
                              : const LinearGradient(colors: [Color(0xFF6366F1), Color(0xFF4F46E5)]),
                      boxShadow: [
                        BoxShadow(
                          color: (isListening ? const Color(0xFFEF4444) : const Color(0xFF6366F1)).withOpacity(0.4),
                          blurRadius: (isListening || isSpeaking) ? 12 : 6,
                          spreadRadius: (isListening || isSpeaking) ? 2 : 0,
                        ),
                      ],
                    ),
                    child: Icon(
                      isListening
                          ? LucideIcons.micOff
                          : isSpeaking
                              ? LucideIcons.volumeX
                              : LucideIcons.mic,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(width: 8),

          // Text Input Box
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFF334155)),
              ),
              child: TextField(
                controller: _textController,
                style: GoogleFonts.inter(color: Colors.white, fontSize: 13),
                decoration: InputDecoration(
                  hintText: isListening
                      ? 'Listening... Speak now'
                      : isSpeaking
                          ? 'PropZen AI is speaking...'
                          : 'Ask in Hindi, English or Hinglish...',
                  hintStyle: GoogleFonts.inter(color: Colors.white38, fontSize: 13),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                ),
                onSubmitted: _handleUserSubmit,
              ),
            ),
          ),

          const SizedBox(width: 6),

          // Send Text Button
          IconButton(
            icon: const Icon(LucideIcons.send, color: Color(0xFF38BDF8), size: 20),
            onPressed: () {
              final text = _textController.text.trim();
              if (text.isNotEmpty) {
                _handleUserSubmit(text);
              }
            },
          ),
        ],
      ),
    );
  }
}
