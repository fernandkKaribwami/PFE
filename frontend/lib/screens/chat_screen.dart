import 'dart:async';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../services/chat_service.dart';
import '../services/realtime_service.dart';
import '../services/user_service.dart';
import '../theme/app_colors.dart';
import '../utils/app_config.dart';
import 'new_message_screen.dart';

String _extensionBasedAttachmentKind(Map<String, dynamic> attachment) {
  final explicitKind = attachment['kind']?.toString() ?? 'document';
  if (explicitKind != 'document') {
    return explicitKind;
  }

  final mimeType = attachment['mimeType']?.toString().toLowerCase() ?? '';
  if (mimeType.startsWith('image/')) {
    return 'image';
  }
  if (mimeType.startsWith('audio/')) {
    return 'audio';
  }
  if (mimeType.startsWith('video/')) {
    return 'video';
  }

  final fileName = attachment['fileName']?.toString().toLowerCase() ?? '';
  if (RegExp(r'\.(jpg|jpeg|png|gif|webp)$').hasMatch(fileName)) {
    return 'image';
  }
  if (RegExp(r'\.(mp3|wav|aac|m4a)$').hasMatch(fileName)) {
    return 'audio';
  }
  if (RegExp(r'\.(mp4|mov|webm)$').hasMatch(fileName)) {
    return 'video';
  }

  return 'document';
}

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final ChatService _chatService = ChatService();
  StreamSubscription<Map<String, dynamic>>? _messageListSubscription;
  bool _isLoading = true;
  List<dynamic> _conversations = [];

  @override
  void initState() {
    super.initState();
    _loadConversations();
    _messageListSubscription = RealtimeService.instance.messages.listen((_) {
      if (!mounted) {
        return;
      }
      _loadConversations();
    });
  }

  @override
  void dispose() {
    _messageListSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadConversations() async {
    final conversations = await _chatService.getConversations();
    if (mounted) {
      setState(() {
        _conversations = conversations;
        _isLoading = false;
      });
    }
  }

  Future<void> _startNewConversation() async {
    final selectedUser = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(builder: (_) => const NewMessageScreen()),
    );

    final userId = selectedUser?['_id']?.toString();
    if (!mounted || userId == null || userId.isEmpty) {
      return;
    }

    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ChatDetailScreen(userId: userId)),
    );

    _loadConversations();
  }

  String _conversationPreview(Map<String, dynamic> lastMessage) {
    final content = lastMessage['content']?.toString().trim() ?? '';
    if (content.isNotEmpty) {
      return content;
    }

    final attachments = lastMessage['attachments'] as List? ?? const [];
    if (attachments.isEmpty) {
      return '';
    }

    final firstAttachment = attachments.first as Map<String, dynamic>;
    switch (_extensionBasedAttachmentKind(firstAttachment)) {
      case 'image':
        return 'Photo envoyee';
      case 'audio':
        return 'Audio envoye';
      case 'video':
        return 'Video envoyee';
      default:
        return firstAttachment['fileName']?.toString() ?? 'Document envoye';
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Messages'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadConversations,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _conversations.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.chat_bubble_outline,
                    size: 80,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Aucune conversation',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 14),
                  ElevatedButton.icon(
                    onPressed: _startNewConversation,
                    icon: const Icon(Icons.edit_square),
                    label: const Text('Nouveau message'),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadConversations,
              child: ListView.separated(
                itemCount: _conversations.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final conversation =
                      _conversations[index] as Map<String, dynamic>;
                  final user =
                      conversation['user'] as Map<String, dynamic>? ?? {};
                  final lastMessage =
                      conversation['lastMessage'] as Map<String, dynamic>? ??
                      {};
                  final avatarUrl = AppConfig.resolveUrl(
                    user['avatar']?.toString(),
                  );

                  return ListTile(
                    leading: CircleAvatar(
                      backgroundImage: avatarUrl.isNotEmpty
                          ? NetworkImage(avatarUrl)
                          : null,
                      child: avatarUrl.isEmpty
                          ? const Icon(Icons.person)
                          : null,
                    ),
                    title: Text(user['name'] ?? 'Utilisateur'),
                    subtitle: Text(
                      _conversationPreview(lastMessage),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              ChatDetailScreen(userId: user['_id'] ?? ''),
                        ),
                      );
                      _loadConversations();
                    },
                  );
                },
              ),
            ),
      floatingActionButton: authProvider.user == null
          ? null
          : FloatingActionButton(
              onPressed: _startNewConversation,
              backgroundColor: AppColors.primary,
              child: const Icon(Icons.edit_note_rounded),
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
  final UserService _userService = UserService();
  final TextEditingController _messageController = TextEditingController();
  static const int _maxAttachmentSize = 25 * 1024 * 1024;

  StreamSubscription<Map<String, dynamic>>? _messageSubscription;
  StreamSubscription<Map<String, dynamic>>? _typingSubscription;
  Timer? _typingDebounce;
  Timer? _typingIndicatorTimer;

  final List<MultipartAttachment> _pendingAttachments = [];

  List<dynamic> messages = [];
  Map<String, dynamic>? otherUser;
  bool isLoading = true;
  bool isSending = false;
  bool isOtherUserTyping = false;

  @override
  void initState() {
    super.initState();
    _loadData();

    _messageSubscription = RealtimeService.instance.messages.listen((message) {
      final sender = message['sender'] as Map<String, dynamic>?;
      final receiver = message['receiver'] as Map<String, dynamic>?;
      final conversationMatches =
          sender?['_id'] == widget.userId || receiver?['_id'] == widget.userId;

      if (!conversationMatches || !mounted) {
        return;
      }

      setState(() {
        final messageId = message['_id']?.toString();
        final existingIndex = messages.indexWhere(
          (item) =>
              (item as Map<String, dynamic>)['_id']?.toString() == messageId,
        );

        if (existingIndex == -1) {
          messages.add(message);
        } else {
          messages[existingIndex] = message;
        }
      });
    });

    _typingSubscription = RealtimeService.instance.typingEvents.listen((event) {
      final typingUserId = event['userId']?.toString();
      if (typingUserId != widget.userId || !mounted) {
        return;
      }

      final isTyping = event['isTyping'] == true;
      _typingIndicatorTimer?.cancel();
      setState(() {
        isOtherUserTyping = isTyping;
      });

      if (isTyping) {
        _typingIndicatorTimer = Timer(const Duration(seconds: 2), () {
          if (!mounted) {
            return;
          }
          setState(() {
            isOtherUserTyping = false;
          });
        });
      }
    });
  }

  Future<void> _loadData() async {
    otherUser = await _userService.getUser(widget.userId);
    messages = await _chatService.getMessages(widget.userId);
    if (mounted) {
      setState(() => isLoading = false);
    }
  }

  Future<void> _pickAttachments() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      withData: kIsWeb,
      type: FileType.any,
    );

    if (result == null || result.files.isEmpty || !mounted) {
      return;
    }

    final validAttachments = <MultipartAttachment>[];
    final rejectedFiles = <String>[];

    for (final file in result.files) {
      final hasPayload =
          (file.bytes != null && file.bytes!.isNotEmpty) ||
          (file.path != null && file.path!.isNotEmpty);

      if (!hasPayload) {
        rejectedFiles.add(file.name);
        continue;
      }

      if (file.size > _maxAttachmentSize) {
        rejectedFiles.add(file.name);
        continue;
      }

      validAttachments.add(
        MultipartAttachment(
          fileName: file.name,
          bytes: file.bytes,
          path: file.path,
        ),
      );
    }

    if (validAttachments.isEmpty) {
      _showSnackBar('Aucun fichier exploitable. Limite: 25 MB par fichier.');
      return;
    }

    setState(() {
      _pendingAttachments.addAll(validAttachments);
    });

    final selectionMessage = StringBuffer(
      validAttachments.length == 1
          ? '1 fichier pret a etre envoye'
          : '${validAttachments.length} fichiers prets a etre envoyes',
    );
    if (rejectedFiles.isNotEmpty) {
      selectionMessage.write(
        ' • ${rejectedFiles.length} ignore(s) car invalides ou trop volumineux',
      );
    }
    _showSnackBar(selectionMessage.toString());
  }

  void _removeAttachmentAt(int index) {
    setState(() {
      _pendingAttachments.removeAt(index);
    });
  }

  void _emitTypingState(bool isTyping) {
    final currentUser = Provider.of<AuthProvider>(
      context,
      listen: false,
    ).user?['_id']?.toString();
    if (currentUser == null || currentUser.isEmpty) {
      return;
    }

    RealtimeService.instance.sendTyping(
      sender: currentUser,
      receiver: widget.userId,
      isTyping: isTyping,
    );
  }

  void _handleComposerChanged(String value) {
    _typingDebounce?.cancel();
    _emitTypingState(value.trim().isNotEmpty);
    _typingDebounce = Timer(const Duration(milliseconds: 900), () {
      _emitTypingState(false);
    });
  }

  Future<void> _sendMessage() async {
    if ((_messageController.text.trim().isEmpty &&
            _pendingAttachments.isEmpty) ||
        isSending) {
      return;
    }

    final hadAttachments = _pendingAttachments.isNotEmpty;

    setState(() {
      isSending = true;
    });

    final sendResult = await _chatService.sendMessage(
      widget.userId,
      text: _messageController.text,
      attachments: List<MultipartAttachment>.from(_pendingAttachments),
    );

    if (!mounted) {
      return;
    }

    if (sendResult.isSuccess) {
      _messageController.clear();
      _typingDebounce?.cancel();
      _emitTypingState(false);
      setState(() {
        isSending = false;
        _pendingAttachments.clear();
        messages.add(sendResult.data!);
      });
      if (hadAttachments) {
        _showSnackBar('Piece jointe envoyee avec succes');
      }
      return;
    }

    setState(() {
      isSending = false;
    });

    _showSnackBar(
      sendResult.error ?? 'Echec de l envoi. Verifie le serveur et reessaie.',
    );
  }

  void _showSnackBar(String message) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  String _attachmentLabel(Map<String, dynamic> attachment) {
    final fileName = attachment['fileName']?.toString() ?? 'Piece jointe';
    final kind = _extensionBasedAttachmentKind(attachment);
    if (kind == 'audio') {
      return 'Audio - $fileName';
    }
    if (kind == 'video') {
      return 'Video - $fileName';
    }
    if (kind == 'image') {
      return fileName;
    }
    return 'Document - $fileName';
  }

  Widget _buildAttachmentChip(
    Map<String, dynamic> attachment, {
    bool isSent = false,
  }) {
    final kind = _extensionBasedAttachmentKind(attachment);
    final icon = switch (kind) {
      'audio' => Icons.graphic_eq_rounded,
      'video' => Icons.play_circle_outline_rounded,
      'image' => Icons.image_outlined,
      _ => Icons.attach_file_rounded,
    };

    final foregroundColor = isSent ? Colors.white : Colors.black87;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isSent
            ? Colors.white.withValues(alpha: 0.14)
            : Colors.black.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: foregroundColor),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              _attachmentLabel(attachment),
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: foregroundColor),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageAttachments(
    List<dynamic> attachments, {
    bool isSent = false,
  }) {
    if (attachments.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: attachments.map<Widget>((attachment) {
          final data = Map<String, dynamic>.from(attachment as Map);
          final kind = _extensionBasedAttachmentKind(data);
          final resolvedUrl = AppConfig.resolveUrl(data['url']?.toString());

          if (kind == 'image' && resolvedUrl.isNotEmpty) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.network(
                  resolvedUrl,
                  height: 180,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return _buildAttachmentChip(data, isSent: isSent);
                  },
                ),
              ),
            );
          }

          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _buildAttachmentChip(data, isSent: isSent),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildPendingAttachments() {
    if (_pendingAttachments.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      height: 54,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _pendingAttachments.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final attachment = _pendingAttachments[index];
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.attach_file_rounded, size: 18),
                const SizedBox(width: 6),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 160),
                  child: Text(
                    attachment.fileName,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 6),
                InkWell(
                  onTap: () => _removeAttachmentAt(index),
                  child: const Icon(Icons.close, size: 18),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = Provider.of<AuthProvider>(
      context,
      listen: false,
    ).user?['_id'];

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(otherUser?['name'] ?? 'Chat'),
            if (isOtherUserTyping)
              const Text(
                'en train d ecrire...',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w400),
              ),
          ],
        ),
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
                      final msg =
                          messages[messages.length - 1 - index]
                              as Map<String, dynamic>;
                      final sender =
                          msg['sender'] as Map<String, dynamic>? ?? {};
                      final attachments =
                          msg['attachments'] as List? ?? const [];
                      final isSent = sender['_id'] == currentUser;
                      final bubbleColor = isSent
                          ? const Color(0xFF003366)
                          : Colors.grey[300];

                      return Align(
                        alignment: isSent
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.all(8),
                          padding: const EdgeInsets.all(12),
                          constraints: const BoxConstraints(maxWidth: 320),
                          decoration: BoxDecoration(
                            color: bubbleColor,
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if ((msg['content']?.toString().isNotEmpty ??
                                  false))
                                Text(
                                  msg['content'] ?? '',
                                  style: TextStyle(
                                    color: isSent ? Colors.white : Colors.black,
                                  ),
                                ),
                              _buildMessageAttachments(
                                attachments,
                                isSent: isSent,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildPendingAttachments(),
                      Row(
                        children: [
                          IconButton(
                            onPressed: _pickAttachments,
                            icon: const Icon(Icons.attach_file_rounded),
                            color: AppColors.primary,
                          ),
                          Expanded(
                            child: TextField(
                              controller: _messageController,
                              onChanged: _handleComposerChanged,
                              minLines: 1,
                              maxLines: 4,
                              decoration: InputDecoration(
                                hintText: 'Message, document, audio...',
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
                            onPressed: isSending ? null : _sendMessage,
                            backgroundColor: const Color(0xFF003366),
                            child: Icon(
                              isSending ? Icons.hourglass_top : Icons.send,
                            ),
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

  @override
  void dispose() {
    _typingDebounce?.cancel();
    _typingIndicatorTimer?.cancel();
    _typingSubscription?.cancel();
    _messageSubscription?.cancel();
    _messageController.dispose();
    super.dispose();
  }
}
