import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/messages_service.dart';

class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key});

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  final MessagesService _messagesService = MessagesService();
  final ScrollController _scrollController = ScrollController();
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
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollListener() {
    if (_scrollController.position.pixels ==
        _scrollController.position.maxScrollExtent) {
      _loadMoreMessages();
    }
  }

  Future<void> _loadMessages() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });

      final messages = await _messagesService.getMessages(limit: pageSize);
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
        final moreMessages = await _messagesService.getMessages(
          limit: pageSize,
          offset: offset,
        );

        setState(() {
          _messages.addAll(moreMessages);
          _currentPage++;
          _hasMoreMessages = moreMessages.length >= pageSize;
          _isLoadingMore = false;
        });
      } catch (e) {
        setState(() {
          _isLoadingMore = false;
          _errorMessage = 'Failed to load more messages: ${e.toString()}';
        });
      }
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final messageDate = DateTime(date.year, date.month, date.day);

    if (messageDate == today) {
      return 'Today';
    } else if (messageDate == yesterday) {
      return 'Yesterday';
    } else {
      return DateFormat('MMM d, yyyy').format(date);
    }
  }

  Widget _buildMessageGroup(DateTime date, List<Message> messages) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Text(
            _formatDate(date),
            style: const TextStyle(
              color: Colors.grey,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        ...messages.map((message) => ListTile(
              leading: CircleAvatar(
                backgroundColor:
                    message.isIncoming ? Colors.green : Colors.blue,
                child: Text(
                  message.sender[0].toUpperCase(),
                  style: const TextStyle(color: Colors.white),
                ),
              ),
              title: Text(message.sender),
              subtitle: Text(message.content),
              trailing: Text(
                DateFormat('h:mm a').format(message.timestamp),
                style: const TextStyle(color: Colors.grey),
              ),
              onTap: () {
                // TODO: Implement message details view
              },
            )),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // Group messages by date
    final groupedMessages = <DateTime, List<Message>>{};
    for (final message in _messages) {
      final date = DateTime(
        message.timestamp.year,
        message.timestamp.month,
        message.timestamp.day,
      );
      groupedMessages.putIfAbsent(date, () => []).add(message);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Messages'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadMessages,
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
            child: ListView.builder(
              controller: _scrollController,
              itemCount: groupedMessages.length + (_hasMoreMessages ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == groupedMessages.length) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(8.0),
                      child: CircularProgressIndicator(),
                    ),
                  );
                }

                final date = groupedMessages.keys.elementAt(index);
                final messages = groupedMessages[date]!;
                return _buildMessageGroup(date, messages);
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
