import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/messages_service.dart';
import '../services/contacts_service.dart' as app_contacts;
import 'package:contacts_service_plus/contacts_service_plus.dart'
    as contacts_service;

class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key});

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  final MessagesService _messagesService = MessagesService();
  final app_contacts.ContactsService _contactsService =
      app_contacts.ContactsService();
  final ScrollController _scrollController = ScrollController();
  final Map<String, String> _contactNames = {};
  Set<String> _conversationNumbers = {};
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadConversations();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadContactNames() async {
    try {
      final contacts = await _contactsService.getContacts();
      for (final contact in contacts) {
        if (contact.phones != null) {
          for (final phone in contact.phones!) {
            if (phone.value != null) {
              _contactNames[phone.value!] = contact.displayName ?? phone.value!;
            }
          }
        }
      }
    } catch (e) {
      // Handle contact loading error silently
    }
  }

  Future<void> _loadConversations() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });

      await _loadContactNames();

      // Get all unique phone numbers from messages
      final messages = await _messagesService.getAllConversations();
      setState(() {
        _conversationNumbers = messages.toSet();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load conversations: ${e.toString()}';
      });
    }
  }

  void _openConversation(String phoneNumber) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ConversationScreen(
          phoneNumber: phoneNumber,
          contactName: _contactNames[phoneNumber] ?? phoneNumber,
        ),
      ),
    );
  }

  Widget _buildConversationTile(String phoneNumber) {
    final contactName = _contactNames[phoneNumber] ?? phoneNumber;

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: Colors.green,
        child: Text(
          contactName[0].toUpperCase(),
          style: const TextStyle(color: Colors.white),
        ),
      ),
      title: Text(
        contactName,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      onTap: () => _openConversation(phoneNumber),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Messages'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadConversations,
          ),
        ],
      ),
      body: Column(
        children: [
          if (_errorMessage.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                _errorMessage,
                style: const TextStyle(color: Colors.red),
              ),
            ),
          Expanded(
            child: _conversationNumbers.isEmpty
                ? const Center(
                    child: Text(
                      'No conversations found',
                      style: TextStyle(fontSize: 18, color: Colors.grey),
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    itemCount: _conversationNumbers.length,
                    itemBuilder: (context, index) {
                      final phoneNumber = _conversationNumbers.elementAt(index);
                      return _buildConversationTile(phoneNumber);
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.green,
        onPressed: () {
          // TODO: Implement new message creation
        },
        child: const Icon(Icons.message, color: Colors.white),
      ),
    );
  }
}

class ConversationScreen extends StatefulWidget {
  final String phoneNumber;
  final String contactName;

  const ConversationScreen({
    super.key,
    required this.phoneNumber,
    required this.contactName,
  });

  @override
  State<ConversationScreen> createState() => _ConversationScreenState();
}

class _ConversationScreenState extends State<ConversationScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final MessagesService _messagesService = MessagesService();
  List<Message> _messages = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  static const int pageSize = 20;
  int _currentPage = 0;
  bool _hasMoreMessages = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadMessages();
    _scrollController.addListener(_scrollListener);
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollListener() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadMoreMessages();
    }
  }

  Future<void> _loadMessages() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
        _currentPage = 0;
      });

      final messages = await _messagesService.getMessagesForNumber(
        widget.phoneNumber,
        limit: pageSize,
      );

      setState(() {
        _messages = messages;
        _isLoading = false;
        _hasMoreMessages = messages.length >= pageSize;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load messages: ${e.toString()}';
      });
    }
  }

  Future<void> _loadMoreMessages() async {
    if (!_isLoadingMore && _hasMoreMessages) {
      setState(() {
        _isLoadingMore = true;
      });

      try {
        final offset = _currentPage * pageSize;
        final moreMessages = await _messagesService.getMessagesForNumber(
          widget.phoneNumber,
          limit: pageSize,
          offset: offset,
        );

        if (moreMessages.isNotEmpty) {
          setState(() {
            _messages.addAll(moreMessages);
            _currentPage++;
            _hasMoreMessages = moreMessages.length >= pageSize;
          });
        } else {
          setState(() {
            _hasMoreMessages = false;
          });
        }
      } catch (e) {
        setState(() {
          _errorMessage = 'Failed to load more messages: ${e.toString()}';
        });
      } finally {
        setState(() {
          _isLoadingMore = false;
        });
      }
    }
  }

  Future<void> _sendMessage() async {
    final content = _messageController.text.trim();
    if (content.isEmpty) return;

    try {
      await _messagesService.sendMessage(widget.phoneNumber, content);
      _messageController.clear();
      // Refresh the conversation
      _loadMessages();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send message: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text(widget.contactName),
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.contactName),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          if (_errorMessage.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                _errorMessage,
                style: const TextStyle(color: Colors.red),
              ),
            ),
          Expanded(
            child: _messages.isEmpty
                ? const Center(
                    child: Text(
                      'No messages found',
                      style: TextStyle(fontSize: 18, color: Colors.grey),
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: _messages.length + (_hasMoreMessages ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == _messages.length) {
                        return _isLoadingMore
                            ? const Padding(
                                padding: EdgeInsets.all(16.0),
                                child: Center(
                                  child: CircularProgressIndicator(),
                                ),
                              )
                            : const SizedBox.shrink();
                      }

                      final message = _messages[index];
                      final isMe = !message.isIncoming;

                      return Align(
                        alignment:
                            isMe ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: isMe ? Colors.green : Colors.grey[300],
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                message.content,
                                style: TextStyle(
                                  color: isMe ? Colors.white : Colors.black,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                DateFormat('h:mm a').format(message.timestamp),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isMe ? Colors.white70 : Colors.black54,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.2),
                  spreadRadius: 1,
                  blurRadius: 3,
                  offset: const Offset(0, -1),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: const InputDecoration(
                      hintText: 'Type a message...',
                      border: InputBorder.none,
                    ),
                    maxLines: null,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send, color: Colors.green),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
