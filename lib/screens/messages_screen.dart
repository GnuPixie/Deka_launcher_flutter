import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key});

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  final List<Message> _messages = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMessages();
  }

  Future<void> _loadMessages() async {
    if (await Permission.sms.request().isGranted) {
      // TODO: Implement SMS loading using platform channels
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Messages'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.green,
                    child: Text(
                      message.sender[0].toUpperCase(),
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  title: Text(message.sender),
                  subtitle: Text(message.content),
                  trailing: Text(
                    message.time,
                    style: const TextStyle(color: Colors.grey),
                  ),
                  onTap: () {
                    // TODO: Implement message details view
                  },
                );
              },
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

class Message {
  final String sender;
  final String content;
  final String time;

  Message({
    required this.sender,
    required this.content,
    required this.time,
  });
}
