import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ctadmobl_project/widgets/app_error_state.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  int _usersStreamKey = 0;

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      return const Center(child: Text('Sign in to use chat.'));
    }

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      key: ValueKey(_usersStreamKey),
      stream: FirebaseFirestore.instance.collection('users').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          debugPrint('Unable to load chat contacts: ${snapshot.error}');
          return AppErrorState(
            onRetry: () => setState(() => _usersStreamKey++),
          );
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final contacts =
            snapshot.data!.docs.where((doc) => doc.id != currentUser.uid).map((
              doc,
            ) {
              final data = doc.data();
              final name = data['name'] as String?;
              final email = data['email'] as String?;
              return ChatContact(
                id: doc.id,
                name: name?.trim().isNotEmpty == true
                    ? name!.trim()
                    : email?.trim().isNotEmpty == true
                    ? email!.trim()
                    : 'User',
              );
            }).toList()..sort(
              (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
            );

        if (contacts.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text('No other users are available to chat yet.'),
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: contacts.length,
          separatorBuilder: (_, _) => const Divider(height: 1, indent: 72),
          itemBuilder: (context, index) {
            final contact = contacts[index];
            return ListTile(
              leading: CircleAvatar(
                child: Text(contact.name.substring(0, 1).toUpperCase()),
              ),
              title: Text(contact.name),
              subtitle: const Text('Private conversation'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => ChatConversationScreen(contact: contact),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class ChatContact {
  const ChatContact({required this.id, required this.name});

  final String id;
  final String name;
}

class ChatConversationScreen extends StatefulWidget {
  const ChatConversationScreen({required this.contact, super.key});

  final ChatContact contact;

  @override
  State<ChatConversationScreen> createState() => _ChatConversationScreenState();
}

class _ChatConversationScreenState extends State<ChatConversationScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  bool _sending = false;
  bool _preparingRoom = true;
  Object? _roomError;
  int _lastMessageCount = 0;
  int _messageStreamKey = 0;

  User? get _user => FirebaseAuth.instance.currentUser;

  String get _roomId {
    final ids = [_user!.uid, widget.contact.id]..sort();
    return '${ids[0]}__${ids[1]}';
  }

  DocumentReference<Map<String, dynamic>> get _room =>
      FirebaseFirestore.instance.collection('chat_rooms').doc(_roomId);

  CollectionReference<Map<String, dynamic>> get _messages =>
      _room.collection('messages');

  late final Stream<QuerySnapshot<Map<String, dynamic>>> _messageStream =
      _messages.orderBy('createdAt').snapshots();

  @override
  void initState() {
    super.initState();
    _prepareRoom();
  }

  Future<void> _prepareRoom() async {
    final user = _user;
    if (user == null) return;
    setState(() {
      _preparingRoom = true;
      _roomError = null;
    });
    try {
      final participants = [user.uid, widget.contact.id]..sort();
      await _room.set({
        'participants': participants,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (error) {
      debugPrint('Unable to open private chat: $error');
      if (mounted) setState(() => _roomError = error);
    } finally {
      if (mounted) setState(() => _preparingRoom = false);
    }
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    final user = _user;
    if (text.isEmpty || user == null || _sending) return;

    setState(() => _sending = true);
    try {
      await _messages.add({
        'text': text,
        'senderId': user.uid,
        'senderName':
            user.displayName ?? user.email?.split('@').first ?? 'User',
        'createdAt': FieldValue.serverTimestamp(),
      });
      _messageController.clear();
    } catch (error, stackTrace) {
      debugPrint('Unable to send chat message: $error\n$stackTrace');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(appErrorMessage),
          action: SnackBarAction(label: 'Retry', onPressed: _sendMessage),
        ),
      );
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  void _scrollToLatest(int messageCount) {
    if (messageCount == _lastMessageCount) return;
    _lastMessageCount = messageCount;
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

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = _user;
    return Scaffold(
      appBar: AppBar(title: Text(widget.contact.name)),
      body: user == null
          ? const Center(child: Text('Sign in to use chat.'))
          : _preparingRoom
          ? const Center(child: CircularProgressIndicator())
          : _roomError != null
          ? AppErrorState(onRetry: _prepareRoom)
          : Column(
              children: [
                Expanded(
                  child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                    key: ValueKey(_messageStreamKey),
                    stream: _messageStream,
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        debugPrint(
                          'Unable to load private chat messages: '
                          '${snapshot.error}',
                        );
                        return AppErrorState(
                          onRetry: () => setState(() => _messageStreamKey++),
                        );
                      }
                      if (!snapshot.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final messages = snapshot.data!.docs;
                      _scrollToLatest(messages.length);
                      if (messages.isEmpty) {
                        return const Center(
                          child: Text('No messages yet. Say hello!'),
                        );
                      }
                      return ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(16),
                        itemCount: messages.length,
                        itemBuilder: (context, index) {
                          final data = messages[index].data();
                          final isMine = data['senderId'] == user.uid;
                          return Align(
                            alignment: isMine
                                ? Alignment.centerRight
                                : Alignment.centerLeft,
                            child: Container(
                              constraints: BoxConstraints(
                                maxWidth:
                                    MediaQuery.sizeOf(context).width * 0.75,
                              ),
                              margin: const EdgeInsets.symmetric(vertical: 5),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: isMine
                                    ? Colors.black
                                    : Theme.of(context).brightness ==
                                          Brightness.dark
                                    ? const Color(0xFF424242)
                                    : const Color(0xFFE9E9E9),
                                borderRadius: BorderRadius.circular(18),
                              ),
                              child: Text(
                                data['text'] as String? ?? '',
                                style: TextStyle(
                                  color: isMine
                                      ? Colors.white
                                      : Theme.of(context).colorScheme.onSurface,
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
                SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _messageController,
                            textCapitalization: TextCapitalization.sentences,
                            minLines: 1,
                            maxLines: 4,
                            onSubmitted: (_) => _sendMessage(),
                            decoration: const InputDecoration(
                              hintText: 'Message',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton.filled(
                          onPressed: _sending ? null : _sendMessage,
                          tooltip: 'Send message',
                          icon: _sending
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.send),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
