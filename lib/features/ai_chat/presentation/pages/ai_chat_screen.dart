import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:meow_track/core/app_state.dart';

class AiChatScreen extends StatefulWidget {
  const AiChatScreen({super.key});

  @override
  State<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends State<AiChatScreen> {
  bool _isVoiceMode = false;
  final TextEditingController _messageController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Default to the latest session if none is active
    if (appState.activeSession == null && appState.chatHistory.isNotEmpty) {
      appState.activeSession = appState.chatHistory.first;
    }
  }

  void _showChatHistory() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          height: 400,
          child: Column(
            children: [
              const Text('Chat History', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const Divider(height: 30),
              Expanded(
                child: ListView.builder(
                  itemCount: appState.chatHistory.length,
                  itemBuilder: (context, index) {
                    final session = appState.chatHistory[index];
                    return ListTile(
                      leading: SvgPicture.asset('assets/icons/History chat.svg', colorFilter: const ColorFilter.mode(Color(0xFF985BEF), BlendMode.srcIn), width: 24, height: 24),
                      title: Text(session.title, style: const TextStyle(fontWeight: FontWeight.w500)),
                      subtitle: Text('${session.messages.length} messages'),
                      onTap: () {
                        setState(() {
                          appState.setActiveSession(session);
                          _isVoiceMode = false;
                        });
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: appState,
      builder: (context, _) {
        return Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: SvgPicture.asset('assets/icons/Back.svg', colorFilter: const ColorFilter.mode(Color(0xFF985BEF), BlendMode.srcIn), width: 30, height: 30),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              _isVoiceMode ? 'AI Paws' : (appState.activeSession?.title ?? 'AI Chat'),
              style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
            ),
            centerTitle: true,
          ),
          body: _isVoiceMode ? _buildVoiceUI() : _buildChatUI(),
          bottomNavigationBar: _buildBottomInputArea(),
        );
      },
    );
  }

  Widget _buildVoiceUI() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Spacer(),
        CircleAvatar(
          radius: 80,
          backgroundColor: const Color(0xFFF5F5F5),
          child: SizedBox(
              width: 80,
              height: 80,
              child: SvgPicture.asset('assets/icons/Chat Ai.svg', colorFilter: const ColorFilter.mode(Colors.orange, BlendMode.srcIn), width: 80, height: 80)),
        ),
        const SizedBox(height: 60),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(7, (index) => Container(
            margin: const EdgeInsets.symmetric(horizontal: 4),
            height: (index % 2 == 0 ? 60 : 100).toDouble(),
            width: 8,
            decoration: BoxDecoration(color: const Color(0xFF985BEF), borderRadius: BorderRadius.circular(10)),
          )),
        ),
        const Spacer(),
      ],
    );
  }

  Widget _buildChatUI() {
    final messages = appState.activeSession?.messages ?? [];
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: messages.length,
            itemBuilder: (context, index) {
              final msg = messages[index];
              return _buildBubble(msg.text, msg.isMe);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildBubble(String text, bool isMe) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isMe) CircleAvatar(backgroundColor: const Color(0xFFF5F5F5), child: SvgPicture.asset('assets/icons/Chat Ai.svg', width: 20, height: 20, colorFilter: const ColorFilter.mode(Colors.orange, BlendMode.srcIn))),
          const SizedBox(width: 10),
          Container(
            constraints: const BoxConstraints(maxWidth: 250),
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: isMe ? const Color(0xFF985BEF) : const Color(0xFFF0F0F0),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(text, style: TextStyle(color: isMe ? Colors.white : Colors.black)),
          ),
          if (isMe) const SizedBox(width: 10),
          if (isMe) const CircleAvatar(backgroundColor: Color(0xFF985BEF), child: Icon(Icons.person, size: 20, color: Colors.white)),
        ],
      ),
    );
  }

  Widget _buildBottomInputArea() {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, -5))],
        ),
        child: Row(
          children: [
            // 1. EXACT PLACEMENT: FAR BOTTOM LEFT HISTORY ICON
            IconButton(
              icon: SvgPicture.asset('assets/icons/History chat.svg', colorFilter: const ColorFilter.mode(Color(0xFF985BEF), BlendMode.srcIn), width: 32, height: 32),
              onPressed: _showChatHistory,
            ),
            const SizedBox(width: 5),
            // 2. Chat TextField
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 15),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _messageController,
                        decoration: const InputDecoration(
                          hintText: 'Ask AI Paws...',
                          border: InputBorder.none,
                        ),
                        onSubmitted: (val) => _sendMessage(),
                      ),
                    ),
                    IconButton(
                      icon: SvgPicture.asset('assets/icons/Mic.svg', colorFilter: const ColorFilter.mode(Color(0xFF985BEF), BlendMode.srcIn), width: 24, height: 24),
                      onPressed: () => setState(() => _isVoiceMode = !_isVoiceMode),
                    ),
                    IconButton(
                      icon: SvgPicture.asset('assets/icons/Send.svg', colorFilter: const ColorFilter.mode(Color(0xFF985BEF), BlendMode.srcIn), width: 24, height: 24),
                      onPressed: _sendMessage,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _sendMessage() {
    if (_messageController.text.isNotEmpty) {
      appState.addMessageToActiveSession(_messageController.text, true);
      _messageController.clear();
      
      // Simulated AI Response
      Future.delayed(const Duration(seconds: 1), () {
        appState.addMessageToActiveSession("I'm analyzing your request about the cat's health...", false);
      });
    }
  }
}
