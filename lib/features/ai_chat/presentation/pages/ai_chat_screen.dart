import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:meow_track/core/app_state.dart';
import 'package:google_generative_ai/google_generative_ai.dart' as gemini;
import 'package:speech_to_text/speech_to_text.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:meow_track/core/notification_service.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AiChatScreen extends StatefulWidget {
  const AiChatScreen({super.key});

  @override
  State<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends State<AiChatScreen> {
  bool _isVoiceMode = false;
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  late final gemini.GenerativeModel _model;
  final SpeechToText _speechToText = SpeechToText();
  bool _speechEnabled = false;
  String _lastWords = '';

  final ImagePicker _picker = ImagePicker();
  XFile? _selectedImage;
  bool _isAnalyzing = false;

  @override
  void initState() {
    super.initState();
    _initGemini();
    _initSpeech();
    _messageController.addListener(() => setState(() {}));
    appState.addListener(_onAppStateChanged);

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (appState.activeSession == null) {
        if (appState.chatHistory.isNotEmpty) {
          appState.setActiveSession(appState.chatHistory.first);
        } else {
          await appState.createNewChatSession();
        }
      }
    });
  }

  void _onAppStateChanged() {
    if (!mounted) return;
    setState(() {});
    _scrollToBottom();
  }

  @override
  void dispose() {
    appState.removeListener(_onAppStateChanged);
    _messageController.dispose();
    _scrollController.dispose();
    _speechToText.stop();
    super.dispose();
  }

  void _initGemini() {
    String activeApiKey = "";
    try {
      activeApiKey = dotenv.env['GEMINI_API_KEY'] ?? "";
    } catch (_) {}

    _model = gemini.GenerativeModel(
      model: 'gemini-1.5-flash-latest',
      apiKey: activeApiKey,
      systemInstruction: gemini.Content.system("You are 'AI Paws', an expert cat care assistant."),
    );
  }

  Future<void> _initSpeech() async {
    _speechEnabled = await _speechToText.initialize();
    if (mounted) setState(() {});
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final messages = appState.activeSession?.messages ?? [];
    
    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: true, // Biar keyboard tolak UI ke atas
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: SvgPicture.asset('assets/icons/Back.svg', colorFilter: const ColorFilter.mode(Color(0xFF985BEF), BlendMode.srcIn), width: 30, height: 30),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          appState.activeSession?.title ?? 'AI Paws', 
          style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_comment_outlined, color: Color(0xFF985BEF)),
            onPressed: () => appState.createNewChatSession(),
          ),
        ],
      ),
      body: Column(
        children: [
          // 1. Kawasan Chat Mesej
          Expanded(
            child: messages.isEmpty 
              ? _buildEmptyState() 
              : ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  itemCount: messages.length,
                  itemBuilder: (context, index) => _buildBubble(messages[index]),
                ),
          ),
          
          // 2. Bar Input Terapung (Akan sentiasa nampak di atas keyboard)
          _buildBottomInputArea(),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset('assets/images/Ai paws.png', width: 140),
          const SizedBox(height: 20),
          Text(
            "Meow! I'm AI Paws.\nHow can I help you today?",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[600], fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildBubble(ChatMessage msg) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        mainAxisAlignment: msg.isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!msg.isMe) 
            CircleAvatar(
              radius: 18,
              backgroundColor: const Color(0xFFF5F5F5), 
              child: Padding(padding: const EdgeInsets.all(4), child: Image.asset('assets/images/Ai paws.png'))
            ),
          const SizedBox(width: 10),
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: msg.isMe ? const Color(0xFF985BEF) : const Color(0xFFF0F0F0),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20),
                  topRight: const Radius.circular(20),
                  bottomLeft: Radius.circular(msg.isMe ? 20 : 5),
                  bottomRight: Radius.circular(msg.isMe ? 5 : 20),
                ),
              ),
              child: Text(
                msg.text, 
                style: TextStyle(color: msg.isMe ? Colors.white : Colors.black, fontSize: 15)
              ),
            ),
          ),
          if (msg.isMe) const SizedBox(width: 10),
          if (msg.isMe) 
            const CircleAvatar(radius: 18, backgroundColor: Color(0xFF985BEF), child: Icon(Icons.person, size: 20, color: Colors.white)),
        ],
      ),
    );
  }

  Widget _buildBottomInputArea() {
    return Container(
      padding: EdgeInsets.fromLTRB(10, 10, 10, MediaQuery.of(context).padding.bottom + 10),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))],
      ),
      child: Row(
        children: [
          // Butang History Lama
          IconButton(
            icon: SvgPicture.asset('assets/icons/History chat.svg', colorFilter: const ColorFilter.mode(Color(0xFF985BEF), BlendMode.srcIn), width: 28, height: 28),
            onPressed: () => _showChatHistory(),
          ),
          
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(color: const Color(0xFFF5F5F5), borderRadius: BorderRadius.circular(30)),
              child: Row(
                children: [
                  // Butang Upload Lama
                  IconButton(
                    icon: SvgPicture.asset('assets/icons/Upload Photo Gallery, zoom, add.svg', colorFilter: const ColorFilter.mode(Color(0xFF985BEF), BlendMode.srcIn), width: 22, height: 22),
                    onPressed: () {}, // Pick Image logic
                  ),
                  
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      style: const TextStyle(color: Colors.black), // Pastikan teks nampak (HITAM)
                      decoration: const InputDecoration(
                        hintText: 'Ask AI Paws...',
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  
                  // Mic atau Send (Logic Lama)
                  if (_messageController.text.isEmpty)
                    IconButton(
                      icon: Icon(_speechToText.isListening ? Icons.stop : Icons.mic, color: const Color(0xFF985BEF)),
                      onPressed: () {}, // Voice logic
                    )
                  else
                    IconButton(
                      icon: _isAnalyzing 
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF985BEF)))
                        : SvgPicture.asset('assets/icons/Send.svg', colorFilter: const ColorFilter.mode(Color(0xFF985BEF), BlendMode.srcIn), width: 24, height: 24),
                      onPressed: _sendMessage,
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showChatHistory() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        height: 350,
        child: Column(
          children: [
            const Text('Chat History', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const Divider(height: 30),
            Expanded(
              child: ListView.builder(
                itemCount: appState.chatHistory.length,
                itemBuilder: (context, index) {
                  final session = appState.chatHistory[index];
                  return ListTile(
                    title: Text(session.title),
                    onTap: () {
                      appState.setActiveSession(session);
                      Navigator.pop(context);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _isAnalyzing) return;

    _messageController.clear();
    setState(() => _isAnalyzing = true);

    await appState.addMessageToActiveSession(text, true);
    _scrollToBottom();

    try {
      final response = await _model.generateContent([gemini.Content.text(text)]);
      final aiText = response.text;
      if (aiText != null) {
        await appState.addMessageToActiveSession(aiText, false);
        _scrollToBottom();
      }
    } catch (e) {
      await appState.addMessageToActiveSession("Meow! Something went wrong.", false);
    } finally {
      if (mounted) setState(() => _isAnalyzing = false);
    }
  }
}
