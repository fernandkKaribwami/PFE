import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../services/chat_service.dart';
import '../services/user_service.dart';

class ChatScreen extends StatelessWidget {
  const ChatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Messages'),
        actions: [IconButton(icon: const Icon(Icons.search), onPressed: () {})],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.chat_bubble_outline, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Aucun message',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Vos conversations apparaîtront ici',
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // TODO: Navigate to new chat
        },
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.message),
      ),
    );
  }
}

class ChatDetailScreen extends StatefulWidget {
  final String userId;
  const ChatDetailScreen({super.key, required this.userId});

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final ChatService _chatService = ChatService();
  // ignore: unused_field
  final UserService _userService = UserService();
  final TextEditingController _messageController = TextEditingController();

  List<dynamic> messages = [];
  Map<String, dynamic>? otherUser;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    otherUser = await _userService.getUser(widget.userId);
    messages = await _chatService.getMessages(widget.userId);
    if (mounted) {
      setState(() => isLoading = false);
    }
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.isEmpty) return;

    final success = await _chatService.sendMessage(
      widget.userId,
      _messageController.text,
    );

    if (success) {
      _messageController.clear();
      await _loadData();
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(otherUser?['nom'] ?? 'Chat'),
        backgroundColor: const Color(0xFF003366),
        foregroundColor: Colors.white,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    reverse: true,
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final msg = messages[messages.length - 1 - index];
                      final isSent = msg['from'] == widget.userId;

                      return Align(
                        alignment: isSent
                            ? Alignment.centerLeft
                            : Alignment.centerRight,
                        child: Container(
                          margin: const EdgeInsets.all(8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isSent
                                ? Colors.grey[300]
                                : const Color(0xFF003366),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            msg['text'] ?? '',
                            style: TextStyle(
                              color: isSent ? Colors.black : Colors.white,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _messageController,
                          decoration: InputDecoration(
                            hintText: 'Message...',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      FloatingActionButton(
                        onPressed: _sendMessage,
                        backgroundColor: const Color(0xFF003366),
                        child: const Icon(Icons.send),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }
}
