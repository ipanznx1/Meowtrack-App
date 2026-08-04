import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:meow_track/core/app_state.dart';
import 'package:google_generative_ai/google_generative_ai.dart' as gemini;
import 'package:speech_to_text/speech_to_text.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:meow_track/core/notification_service.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
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

  gemini.GenerativeModel? _model;
  final SpeechToText _speechToText = SpeechToText();
  bool _speechEnabled = false;
  String _lastWords = '';

  final ImagePicker _picker = ImagePicker();
  XFile? _selectedImage;
  bool _isAnalyzing = false;

  List<String> _suggestedQuestions = [
    "Cara mandikan kucing? 🛁",
    "Kenapa kucing saya tak makan? 😿",
    "Senarai makanan bahaya? 🚫",
    "Cara potong kuku kucing? ✂️",
    "Vaksin apa yang perlu? 💉",
  ];

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

    if (activeApiKey.isEmpty) {
      activeApiKey = appState.geminiApiKey;
    }
    
    if (activeApiKey.isNotEmpty) {
      _model = gemini.GenerativeModel(
        model: 'gemini-flash-latest',
        apiKey: activeApiKey,
        systemInstruction: gemini.Content.system(
          "You are 'AI Paws', a friendly and expert cat care assistant. "
          "STRICT RULE 1: Your knowledge and responses are strictly limited to cats and cat care. "
          "STRICT RULE 2: If a user sends an image, you must first check if it contains a cat or something related to cat care (like cat food, symptoms, or environment). "
          "If the image is NOT about cats (e.g., a person, a car, or another animal), you MUST politely say: 'Meow! Maaf, saya hanya boleh menganalisis gambar berkaitan kucing sahaja.' "
          "If a user asks anything NOT related to cats (e.g., general knowledge, math, cooking, or politics), "
          "you MUST politely decline and inform them that you only specialize in cats. "
          "OFFENSIVE LANGUAGE RULE: If the user uses offensive language, swear words, or is being rude, "
          "politely ask them to keep the conversation respectful and focused on cat care. "
          "Example: 'Meow! Sila gunakan bahasa yang sopan. Saya di sini hanya untuk membantu anda menjaga si bulu kesayangan anda.' "
          "When giving advice, use clear formatting with bullet points and bold text. "
          "IMPORTANT: At the very end of EVERY response, you MUST provide 3 short suggested replies related to cat care. "
          "Format: [SUGGESTIONS] Reply 1 | Reply 2 | Reply 3. "
          "Keep each suggestion very short (1-4 words only)."
        ),
      );
    }
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
        title: GestureDetector(
          onLongPress: _showModelDiagnostics,
          child: Text(
            appState.activeSession?.title ?? 'AI Paws', 
            style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)
          ),
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
          
          // 2. Suggested Questions Area
          if (!_isAnalyzing) _buildSuggestionsArea(),

          // 3. Bar Input Terapung (Akan sentiasa nampak di atas keyboard)
          _buildBottomInputArea(),
        ],
      ),
    );
  }

  Widget _buildSuggestionsArea() {
    return Container(
      height: 45,
      margin: const EdgeInsets.only(bottom: 5),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 15),
        itemCount: _suggestedQuestions.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.only(right: 10),
            child: ActionChip(
              label: Text(
                _suggestedQuestions[index],
                style: const TextStyle(color: Color(0xFF985BEF), fontSize: 13, fontWeight: FontWeight.bold),
              ),
              backgroundColor: const Color(0xFF985BEF).withOpacity(0.08),
              side: const BorderSide(color: Color(0xFF985BEF), width: 0.5),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              onPressed: () => _handleSuggestedQuestion(_suggestedQuestions[index]),
            ),
          );
        },
      ),
    );
  }

  void _handleSuggestedQuestion(String question) {
    _messageController.text = question;
    _sendMessage();
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
            Container(
              margin: const EdgeInsets.only(top: 4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF985BEF).withOpacity(0.2), width: 2),
              ),
              child: CircleAvatar(
                radius: 16,
                backgroundColor: Colors.white, 
                child: Padding(padding: const EdgeInsets.all(4), child: Image.asset('assets/images/Ai paws.png'))
              ),
            ),
          const SizedBox(width: 10),
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: msg.isMe ? const Color(0xFF985BEF) : const Color(0xFFF8F9FE),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20),
                  topRight: const Radius.circular(20),
                  bottomLeft: Radius.circular(msg.isMe ? 20 : 4),
                  bottomRight: Radius.circular(msg.isMe ? 4 : 20),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  )
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (msg.imagePath != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(File(msg.imagePath!), fit: BoxFit.cover),
                      ),
                    ),
                  msg.isMe 
                    ? Text(
                        msg.text, 
                        style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w500)
                      )
                    : MarkdownBody(
                        data: msg.text,
                        styleSheet: MarkdownStyleSheet(
                          p: const TextStyle(color: Colors.black87, fontSize: 15, height: 1.5),
                          strong: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF985BEF)),
                          listBullet: const TextStyle(color: Color(0xFF985BEF)),
                        ),
                      ),
                ],
              ),
            ),
          ),
          if (msg.isMe) const SizedBox(width: 10),
          if (msg.isMe) 
            Container(
              margin: const EdgeInsets.only(top: 4),
              child: CircleAvatar(
                radius: 16, 
                backgroundColor: const Color(0xFF985BEF).withOpacity(0.1), 
                child: const Icon(Icons.person, size: 18, color: Color(0xFF985BEF))
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _pickImage() async {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Pilih Gambar Kucing", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildPickerOption(Icons.camera_alt, "Kamera", ImageSource.camera),
                _buildPickerOption(Icons.photo_library, "Galeri", ImageSource.gallery),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildPickerOption(IconData icon, String label, ImageSource source) {
    return GestureDetector(
      onTap: () async {
        Navigator.pop(context);
        final XFile? image = await _picker.pickImage(source: source, imageQuality: 70);
        if (image != null) {
          setState(() {
            _selectedImage = image;
          });
        }
      },
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(color: const Color(0xFF985BEF).withOpacity(0.1), shape: BoxShape.circle),
            child: Icon(icon, color: const Color(0xFF985BEF), size: 30),
          ),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildImagePreview() {
    if (_selectedImage == null) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.all(10),
      margin: const EdgeInsets.only(bottom: 10, left: 15, right: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.file(File(_selectedImage!.path), width: 60, height: 60, fit: BoxFit.cover),
          ),
          const SizedBox(width: 15),
          const Expanded(
            child: Text("Gambar dipilih. Sila tanya sesuatu...", style: TextStyle(fontSize: 13, color: Colors.grey)),
          ),
          IconButton(
            icon: const Icon(Icons.cancel, color: Colors.redAccent),
            onPressed: () => setState(() => _selectedImage = null),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomInputArea() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildImagePreview(),
          Container(
            padding: EdgeInsets.fromLTRB(10, 10, 10, MediaQuery.of(context).padding.bottom + 10),
            child: Row(
              children: [
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
                        IconButton(
                          icon: SvgPicture.asset('assets/icons/Upload Photo Gallery, zoom, add.svg', colorFilter: const ColorFilter.mode(Color(0xFF985BEF), BlendMode.srcIn), width: 22, height: 22),
                          onPressed: _pickImage,
                        ),
                        Expanded(
                          child: TextField(
                            controller: _messageController,
                            style: const TextStyle(color: Colors.black),
                            decoration: const InputDecoration(
                              hintText: 'Ask AI Paws...',
                              border: InputBorder.none,
                            ),
                          ),
                        ),
                        if (_messageController.text.isEmpty && _selectedImage == null)
                          IconButton(
                            icon: Icon(_speechToText.isListening ? Icons.stop : Icons.mic, color: const Color(0xFF985BEF)),
                            onPressed: _toggleListening,
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
          ),
        ],
      ),
    );
  }

  void _showChatHistory() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10))),
            const SizedBox(height: 20),
            const Text("Chat History", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 20),
            Expanded(
              child: appState.chatHistory.isEmpty 
                ? const Center(child: Text("Tiada sejarah chat lagi."))
                : ListView.builder(
                    itemCount: appState.chatHistory.length,
                    itemBuilder: (context, index) {
                      final session = appState.chatHistory[index];
                      return ListTile(
                        leading: const Icon(Icons.chat_bubble_outline, color: Color(0xFF985BEF)),
                        title: Text(session.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                        subtitle: Text("${session.messages.length} mesej", style: const TextStyle(fontSize: 12)),
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

  Future<void> _toggleListening() async {
    if (!_speechEnabled) {
      final available = await _speechToText.initialize();
      if (!available) return;
    }

    if (_speechToText.isListening) {
      await _speechToText.stop();
      setState(() {});
    } else {
      await _speechToText.listen(
        onResult: (result) {
          setState(() {
            _messageController.text = result.recognizedWords;
          });
        },
        localeId: 'ms_MY', // Support Bahasa Melayu
      );
      setState(() {});
    }
  }

  void _showModelDiagnostics() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator(color: Color(0xFF985BEF))),
    );

    final models = await appState.getAvailableAiModels();
    if (mounted) Navigator.pop(context); // Close loading

    if (mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text("AI Diagnostic List"),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: models.length,
              itemBuilder: (context, i) => Text("• ${models[i]}", style: const TextStyle(fontSize: 12)),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Tutup")),
          ],
        ),
      );
    }
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    final hasImage = _selectedImage != null;
    
    if (text.isEmpty && !hasImage || _isAnalyzing) return;

    _initGemini();

    if (_model == null) {
      await appState.addMessageToActiveSession("Meow! Sistem AI belum sedia. Sila semak API Key.", false);
      return;
    }

    final String? imagePath = _selectedImage?.path;
    final Uint8List? imageBytes = hasImage ? await _selectedImage!.readAsBytes() : null;

    _messageController.clear();
    setState(() {
      _isAnalyzing = true;
      _suggestedQuestions.clear();
      _selectedImage = null; // Reset image preview
    });

    await appState.addMessageToActiveSession(text.isEmpty ? "[Sent an image]" : text, true, imagePath: imagePath);
    _scrollToBottom();

    try {
      final List<gemini.Content> content = [
        gemini.Content.multi([
          gemini.TextPart(text.isEmpty ? "What is in this image?" : text),
          if (imageBytes != null) gemini.DataPart('image/jpeg', imageBytes),
        ])
      ];

      final response = await _model!.generateContent(content);
      String? aiText = response.text;
      
      if (aiText != null) {
        // PARSING SUGGESTIONS
        if (aiText.contains("[SUGGESTIONS]")) {
          final parts = aiText.split("[SUGGESTIONS]");
          final cleanText = parts[0].trim();
          final suggestionsPart = parts[1].trim();
          
          final newSuggestions = suggestionsPart
              .split("|")
              .map((s) => s.trim())
              .where((s) => s.isNotEmpty)
              .toList();

          setState(() {
            _suggestedQuestions = newSuggestions;
          });
          
          await appState.addMessageToActiveSession(cleanText, false);
        } else {
          await appState.addMessageToActiveSession(aiText, false);
        }
        _scrollToBottom();
      }
    } catch (e) {
      debugPrint("Gemini Error: $e");
      String rawError = e.toString();
      String displayError = "Meow! Ralat dikesan: $rawError";
      
      if (rawError.contains("API_KEY_INVALID")) {
        displayError = "Meow! API Key anda tidak sah. Sila pastikan anda salin kunci dari Google AI Studio dengan betul.";
      } else if (rawError.contains("location not supported")) {
        displayError = "Meow! Gemini belum menyokong kawasan anda. Sila guna VPN atau tunggu kemaskini Google.";
      }

      await appState.addMessageToActiveSession(displayError, false);
    } finally {
      if (mounted) setState(() => _isAnalyzing = false);
    }
  }
}
