import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

class OwnerChatMessage {
  final String text;
  final bool isMe;
  final String? imageUrl;

  OwnerChatMessage({required this.text, required this.isMe, this.imageUrl});
}

class OwnerChatPage extends StatefulWidget {
  final String ownerName;
  const OwnerChatPage({super.key, required this.ownerName});

  @override
  State<OwnerChatPage> createState() => _OwnerChatPageState();
}

class _OwnerChatPageState extends State<OwnerChatPage> {
  final TextEditingController _controller = TextEditingController();
  final List<OwnerChatMessage> _messages = [
    OwnerChatMessage(text: "Hi Ahmad! I dah sampai rumah you ni. Nak check pasal Luna kejap", isMe: false),
    OwnerChatMessage(text: "Hi Sarah! Thank you so much sudi tolong tengokkan Luna sementara I kat luar kawasan ni. 🙏", isMe: true),
    OwnerChatMessage(text: "Small matter lah! Eh, I dah bagi dia wet food tahu. I dah tick dekat \"Care Log\" apps kita juga. 👌", isMe: false),
    OwnerChatMessage(text: "Awesome! I dapat notification tadi. Macam mana dengan ubat kurap dia? Dia makan tak?", isMe: true),
    OwnerChatMessage(text: "", isMe: false, imageUrl: "https://images.unsplash.com/photo-1514888286974-6c03e2ca1dba?q=80&w=500"),
    OwnerChatMessage(text: "Haha dia merajuk sikit mula-mula, tapi lepas letak treats baru dia makan habis. All settled!", isMe: false),
    OwnerChatMessage(text: "Alhamdulillah, lega hati I dengar. You're the best Co-Owner ever! Haha. 🌟", isMe: true),
  ];

  void _sendMessage() {
    if (_controller.text.isNotEmpty) {
      setState(() {
        _messages.add(OwnerChatMessage(text: _controller.text, isMe: true));
        _controller.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(icon: SvgPicture.asset('assets/icons/Back.svg', width: 24, height: 24, colorFilter: const ColorFilter.mode(Color(0xFF985BEF), BlendMode.srcIn)), onPressed: () => Navigator.pop(context)),
        title: Text(widget.ownerName, style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: _messages.length,
              itemBuilder: (context, index) => _buildMessageBubble(_messages[index]),
            ),
          ),
          _buildInputBar(),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(OwnerChatMessage msg) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        mainAxisAlignment: msg.isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!msg.isMe) CircleAvatar(radius: 20, backgroundColor: const Color(0xFFF5F5F5), child: SvgPicture.asset('assets/icons/Cat’s Profile.svg', width: 20, height: 20, colorFilter: const ColorFilter.mode(Colors.grey, BlendMode.srcIn))),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: msg.isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              if (msg.imageUrl != null)
                Container(
                  margin: const EdgeInsets.only(bottom: 5),
                  height: 150,
                  width: 200,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    image: DecorationImage(image: NetworkImage(msg.imageUrl!), fit: BoxFit.cover),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                ),
              if (msg.text.isNotEmpty)
                Container(
                  constraints: const BoxConstraints(maxWidth: 250),
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: msg.isMe ? const Color(0xFF985BEF) : const Color(0xFFEFEFEF),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(msg.text, style: TextStyle(color: msg.isMe ? Colors.white : Colors.black, fontSize: 13)),
                ),
            ],
          ),
          const SizedBox(width: 10),
          if (msg.isMe) CircleAvatar(radius: 20, backgroundColor: const Color(0xFF985BEF), child: SvgPicture.asset('assets/icons/Cat’s Profile.svg', width: 20, height: 20, colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn))),
        ],
      ),
    );
  }

  Widget _buildInputBar() {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: Colors.grey[200]!))),
        child: Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 15),
                decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(30)),
                child: Row(
                  children: [
                    Expanded(child: TextField(controller: _controller, decoration: const InputDecoration(hintText: "Type a message...", border: InputBorder.none))),
                    SvgPicture.asset('assets/icons/Upload Photo Gallery, zoom, add.svg', width: 20, height: 20, colorFilter: const ColorFilter.mode(Colors.grey, BlendMode.srcIn)),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 10),
            IconButton(
              icon: SvgPicture.asset('assets/icons/Send.svg', width: 24, height: 24, colorFilter: const ColorFilter.mode(Color(0xFF985BEF), BlendMode.srcIn)),
              onPressed: _sendMessage,
            ),
          ],
        ),
      ),
    );
  }
}
