import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../services/propzen_voice_service.dart';
import '../services/propzen_ai_agent_service.dart';
import '../widgets/property_card.dart';
import '../screens/property_details_screen.dart';
import '../theme/app_theme.dart';

class PropzenVoiceAgentModal extends StatefulWidget {
  const PropzenVoiceAgentModal({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const PropzenVoiceAgentModal(),
    );
  }

  @override
  State<PropzenVoiceAgentModal> createState() => _PropzenVoiceAgentModalState();
}

class _PropzenVoiceAgentModalState extends State<PropzenVoiceAgentModal> with SingleTickerProviderStateMixin {
  final PropzenVoiceService _voiceService = PropzenVoiceService.instance;
  final PropzenAiAgentService _aiAgentService = PropzenAiAgentService.instance;
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  late final AnimationController _pulseController;
  String _selectedLangCode = 'hi-IN'; // 'hi-IN' supports Hindi & Hinglish, 'en-IN' for English

  @override
  void initState() {
    super.initState();
    _voiceService.initialize();
    _voiceService.stateNotifier.addListener(_onVoiceStateChanged);
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    // Proactively start the conversation with the professional opening greeting
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_aiAgentService.sessionHistory.isEmpty) {
        _startProactiveGreeting();
      }
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

  Future<void> _startProactiveGreeting() async {
    final proactiveLang = (_selectedLangCode == 'en-IN') ? 'english' : 'hinglish';
    final msg = _aiAgentService.startProactiveTurn(language: proactiveLang);
    if (!mounted) return;
    setState(() {});
    _scrollToBottom();

    // Vocalize opening greeting aloud proactively
    final ttsLang = (proactiveLang == 'english') ? 'en-IN' : 'hi-IN';
    await _voiceService.speak(
      msg.text,
      languageCode: ttsLang,
      onCompleted: () {
        if (mounted && _voiceService.stateNotifier.value != VoiceAgentState.listening) {
          _startVoiceConversation();
        }
      },
    );
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _startVoiceConversation() async {
    // Interruption / Barge-in: immediately stop speaking
    _voiceService.stopSpeaking();

    await _voiceService.startListening(
      languageCode: _selectedLangCode,
      onResult: (text, isFinal) {
        if (isFinal && text.trim().isNotEmpty) {
          _processUserInput(text.trim());
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
        // If user finished speaking
        final currentText = _voiceService.liveTranscriptNotifier.value.trim();
        if (currentText.isNotEmpty && _voiceService.stateNotifier.value == VoiceAgentState.idle) {
          _processUserInput(currentText);
        }
      },
    );
  }

  Future<void> _processUserInput(String input) async {
    if (input.trim().isEmpty) return;

    // Barge-in: cancel any previous TTS speech immediately
    _voiceService.stopSpeaking();
    _voiceService.stopListening();
    _voiceService.stateNotifier.value = VoiceAgentState.thinking;
    setState(() {});
    _scrollToBottom();

    // Generate consultative AI response with verified property matching & booking workflows
    final result = await _aiAgentService.processDialogue(input);
    if (!mounted) return;

    setState(() {});
    _scrollToBottom();

    // Determine TTS language code based on detected language
    final detectedLang = result.language;
    final ttsLang = (detectedLang == 'english') ? 'en-IN' : 'hi-IN';

    // Speak AI response aloud
    await _voiceService.speak(
      result.speechResponse,
      languageCode: ttsLang,
      onCompleted: () {
        if (mounted) {
          setState(() {});
        }
      },
    );
  }

  void _handleSendText() {
    final text = _textController.text.trim();
    if (text.isEmpty) return;
    _textController.clear();
    _processUserInput(text);
  }

  void _stopEverything() {
    _voiceService.stopAll();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final state = _voiceService.stateNotifier.value;
    final isListening = state == VoiceAgentState.listening;
    final isSpeaking = state == VoiceAgentState.speaking;
    final isThinking = state == VoiceAgentState.thinking;

    final screenHeight = MediaQuery.of(context).size.height;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 680),
        child: Container(
          height: (screenHeight * 0.88).clamp(520.0, 780.0),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // Drag handle
              Container(
                margin: const EdgeInsets.only(top: 10, bottom: 6),
                width: 40,
                height: 4,
                decoration: BoxDecoration(color: const Color(0xFFCBD5E1), borderRadius: BorderRadius.circular(2)),
              ),

              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [Color(0xFF7C3AED), Color(0xFFEC4899)]),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(color: const Color(0xFF7C3AED).withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4)),
                        ],
                      ),
                      child: const Icon(LucideIcons.sparkles, color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text('PropZen AI', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: isListening ? const Color(0xFFDCFCE7) : (isSpeaking ? const Color(0xFFE0E7FF) : const Color(0xFFF1F5F9)),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  isListening ? '🎙️ LISTENING' : (isSpeaking ? '🔊 SPEAKING' : (isThinking ? '🧠 THINKING' : 'IDLE')),
                                  style: GoogleFonts.inter(
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                    color: isListening ? AppTheme.emeraldSuccess : (isSpeaking ? AppTheme.primaryViolet : const Color(0xFF64748B)),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          Text('Female Voice • Hindi • Hinglish • English', style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textSecondary)),
                        ],
                      ),
                    ),

                // Clear history button
                IconButton(
                  icon: const Icon(LucideIcons.rotateCcw, size: 18, color: Color(0xFF64748B)),
                  tooltip: 'Reset Conversation',
                  onPressed: () {
                    _aiAgentService.clearSession();
                    _voiceService.stopAll();
                    _startProactiveGreeting();
                  },
                ),
                // Close button
                IconButton(
                  icon: const Icon(LucideIcons.x, size: 20, color: Color(0xFF64748B)),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),

          const Divider(height: 1, color: Color(0xFFE2E8F0)),

          // Main Conversation Area
          Expanded(
            child: Container(
              color: const Color(0xFFF8FAFC),
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                itemCount: _aiAgentService.sessionHistory.length,
                itemBuilder: (ctx, i) {
                  final msg = _aiAgentService.sessionHistory[i];
                  final isUser = msg.role == 'user';
                  final isLatestAssistant = !isUser && i == _aiAgentService.sessionHistory.length - 1;
                  return _buildMessageBubble(msg, isUser, isLatestAssistant);
                },
              ),
            ),
          ),

          // Live transcript banner when listening
          ValueListenableBuilder<String>(
            valueListenable: _voiceService.liveTranscriptNotifier,
            builder: (ctx, transcript, _) {
              if (transcript.isEmpty || !isListening) return const SizedBox.shrink();
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                color: const Color(0xFFFEF3C7),
                child: Row(
                  children: [
                    const Icon(LucideIcons.mic, size: 14, color: Color(0xFFD97706)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Hearing: "$transcript"',
                        style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF92400E)),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),

          // Voice Control & Visualizer Bar
          Container(
            padding: EdgeInsets.fromLTRB(16, 12, 16, 12 + bottomInset),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Visualizer Waves
                if (isListening || isSpeaking) ...[
                  _buildAnimatedWaveVisualizer(isListening: isListening, isSpeaking: isSpeaking),
                  const SizedBox(height: 10),
                ],

                // Action Buttons Row: [Stop Button] - [Microphone Button / Wave] - [Send / Text]
                Row(
                  children: [
                    // Stop / Language Switch Button
                    if (isListening || isSpeaking || isThinking)
                      IconButton(
                        onPressed: _stopEverything,
                        icon: const Icon(LucideIcons.square, size: 20, color: AppTheme.coralDanger),
                        tooltip: 'Stop',
                        style: IconButton.styleFrom(
                          backgroundColor: const Color(0xFFFEE2E2),
                          padding: const EdgeInsets.all(12),
                        ),
                      )
                    else
                      IconButton(
                        onPressed: () {
                          setState(() {
                            _selectedLangCode = (_selectedLangCode == 'hi-IN') ? 'en-IN' : 'hi-IN';
                          });
                        },
                        icon: const Icon(LucideIcons.languages, size: 20, color: AppTheme.primaryViolet),
                        tooltip: 'Switch Speech Recognition Language (${_selectedLangCode == "hi-IN" ? "Hindi/Hinglish" : "English"})',
                        style: IconButton.styleFrom(
                          backgroundColor: const Color(0xFFF1F5F9),
                          padding: const EdgeInsets.all(12),
                        ),
                      ),

                    const SizedBox(width: 10),

                    // Primary Voice Button (Talk to PropZen AI)
                    Expanded(
                      child: SizedBox(
                        height: 48,
                        child: ElevatedButton.icon(
                          onPressed: isListening ? _stopEverything : _startVoiceConversation,
                          icon: Icon(
                            isListening ? LucideIcons.micOff : LucideIcons.mic,
                            color: Colors.white,
                            size: 20,
                          ),
                          label: Text(
                            isListening ? 'Listening... Tap to Stop' : (isSpeaking ? 'Speaking... Tap to Interrupt' : 'Talk to PropZen AI'),
                            style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isListening ? AppTheme.coralDanger : AppTheme.primaryViolet,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            elevation: isListening ? 6 : 2,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                // Fallback text input for silent environments
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 38,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: TextField(
                          controller: _textController,
                          style: GoogleFonts.inter(fontSize: 12),
                          decoration: InputDecoration(
                            hintText: 'Or type in Hindi, Hinglish, English...',
                            hintStyle: GoogleFonts.inter(fontSize: 12, color: AppTheme.textMuted),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          ),
                          onSubmitted: (_) => _handleSendText(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(LucideIcons.send, size: 16, color: AppTheme.primaryViolet),
                      onPressed: _handleSendText,
                      padding: const EdgeInsets.all(8),
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  ),
);
  }

  Widget _buildMessageBubble(ConversationMessage msg, bool isUser, bool isLatestAssistant) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            Container(
              width: 30,
              height: 30,
              decoration: const BoxDecoration(
                gradient: LinearGradient(colors: [Color(0xFF7C3AED), Color(0xFF4F46E5)]),
                shape: BoxShape.circle,
              ),
              child: const Icon(LucideIcons.bot, size: 16, color: Colors.white),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: isUser ? AppTheme.primaryViolet : Colors.white,
                    borderRadius: BorderRadius.circular(14).copyWith(
                      bottomRight: isUser ? const Radius.circular(2) : const Radius.circular(14),
                      bottomLeft: !isUser ? const Radius.circular(2) : const Radius.circular(14),
                    ),
                    border: isUser ? null : Border.all(color: const Color(0xFFE2E8F0)),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 6, offset: const Offset(0, 2)),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                    children: [
                      Text(
                        msg.text,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: isUser ? Colors.white : AppTheme.textPrimary,
                          height: 1.45,
                        ),
                      ),
                      if (!isUser && msg.properties != null && msg.properties!.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Column(
                          children: msg.properties!.map((prop) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: PropertyCard(
                                property: prop,
                                isCompact: true,
                                onTap: () {
                                  _aiAgentService.context.selectedProperty = prop;
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (ctx) => PropertyDetailsScreen(
                                        property: prop,
                                        propertyId: prop.id,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                      const SizedBox(height: 4),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            msg.language.toUpperCase(),
                            style: GoogleFonts.inter(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: isUser ? Colors.white.withOpacity(0.7) : AppTheme.textMuted,
                            ),
                          ),
                          if (!isUser) ...[
                            const SizedBox(width: 8),
                            InkWell(
                              onTap: () {
                                final langCode = (msg.language == 'english') ? 'en-IN' : 'hi-IN';
                                _voiceService.speak(msg.text, languageCode: langCode);
                              },
                              child: const Icon(LucideIcons.volume2, size: 12, color: AppTheme.primaryViolet),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),

                // Interactive Suggested Quick Chips below assistant turns
                if (!isUser && msg.suggestedChips != null && msg.suggestedChips!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: msg.suggestedChips!.map((chipText) {
                      return InkWell(
                        onTap: () {
                          _voiceService.stopSpeaking();
                          _processUserInput(chipText);
                        },
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEEF2FF),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFC7D2FE)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(LucideIcons.sparkles, size: 11, color: Color(0xFF4F46E5)),
                              const SizedBox(width: 5),
                              Text(
                                chipText,
                                style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: const Color(0xFF3730A3)),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ],
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: 8),
            Container(
              width: 30,
              height: 30,
              decoration: const BoxDecoration(
                color: Color(0xFF475569),
                shape: BoxShape.circle,
              ),
              child: const Icon(LucideIcons.user, size: 15, color: Colors.white),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAnimatedWaveVisualizer({required bool isListening, required bool isSpeaking}) {
    final color = isListening ? AppTheme.emeraldSuccess : AppTheme.primaryViolet;
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (ctx, _) {
        final val = _pulseController.value;
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(5, (index) {
            final offset = (index - 2).abs() * 0.2;
            final height = 10 + (22 * ((val + offset) % 1.0));
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: 4,
              height: height,
              decoration: BoxDecoration(
                color: color.withOpacity(0.6 + (0.4 * val)),
                borderRadius: BorderRadius.circular(2),
              ),
            );
          }),
        );
      },
    );
  }
}
