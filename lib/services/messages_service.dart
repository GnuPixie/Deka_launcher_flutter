import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:developer' as developer;

class Message {
  final String id;
  final String sender;
  final String content;
  final DateTime timestamp;
  final bool isIncoming;

  Message({
    required this.id,
    required this.sender,
    required this.content,
    required this.timestamp,
    required this.isIncoming,
  });

  factory Message.fromJson(Map<dynamic, dynamic> json) {
    return Message(
      id: json['id']?.toString() ?? '',
      sender: json['sender']?.toString() ?? '',
      content: json['content']?.toString() ?? '',
      timestamp: DateTime.parse(
          json['timestamp']?.toString() ?? DateTime.now().toIso8601String()),
      isIncoming: json['isIncoming'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sender': sender,
      'content': content,
      'timestamp': timestamp.toIso8601String(),
      'isIncoming': isIncoming,
    };
  }
}

class MessagesService {
  static final MessagesService _instance = MessagesService._internal();
  factory MessagesService() => _instance;
  MessagesService._internal();

  static const platform = MethodChannel('com.example.launcher/messages');
  List<Message> _cachedMessages = [];
  bool _isInitialized = false;

  Future<bool> requestPermission() async {
    developer.log('Requesting SMS permission');
    final status = await Permission.sms.request();
    developer.log('SMS permission status: $status');
    return status.isGranted;
  }

  Future<List<String>> getAllConversations() async {
    developer.log('Getting all conversations');
    if (!_isInitialized) {
      if (await requestPermission()) {
        try {
          developer.log('Calling getAllConversations method channel');
          final result =
              await platform.invokeMethod<List<dynamic>>('getAllConversations');
          developer.log(
              'Received ${result?.length ?? 0} messages from method channel');
          if (result != null) {
            _cachedMessages = result
                .map((json) => Message.fromJson(json as Map<dynamic, dynamic>))
                .toList();
            _isInitialized = true;
            developer.log('Cached ${_cachedMessages.length} messages');
          }
        } catch (e) {
          developer.log('Error getting conversations: $e', error: e);
          _cachedMessages = [];
          _isInitialized = false;
          rethrow;
        }
      } else {
        developer.log('SMS permission not granted');
        throw Exception('SMS permission not granted');
      }
    }

    // Get unique phone numbers and sort by most recent message
    developer.log(
        'Processing conversations from ${_cachedMessages.length} messages');
    final conversations = _cachedMessages
        .fold<Map<String, DateTime>>({}, (map, message) {
          final currentLatest = map[message.sender];
          if (currentLatest == null ||
              message.timestamp.isAfter(currentLatest)) {
            map[message.sender] = message.timestamp;
          }
          return map;
        })
        .entries
        .toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final result = conversations.map((e) => e.key).toList();
    developer.log('Returning ${result.length} conversations');
    return result;
  }

  Future<List<Message>> getMessagesForNumber(String phoneNumber,
      {int limit = 20, int offset = 0}) async {
    developer.log(
        'Getting messages for $phoneNumber (limit: $limit, offset: $offset)');
    if (!_isInitialized) {
      await getAllConversations();
    }

    final messages = _cachedMessages
        .where((m) => m.sender == phoneNumber)
        .toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

    final start = offset;
    final end = offset + limit;
    final result = messages.length > start
        ? messages.sublist(start, end > messages.length ? messages.length : end)
        : <Message>[];
    developer.log('Returning ${result.length} messages for $phoneNumber');
    return result;
  }

  Future<void> sendMessage(String recipient, String content) async {
    developer.log('Sending message to $recipient');
    if (await requestPermission()) {
      try {
        await platform.invokeMethod('sendMessage', {
          'recipient': recipient,
          'content': content,
        });
        // Add the sent message to cache
        final newMessage = Message(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          sender: recipient,
          content: content,
          timestamp: DateTime.now(),
          isIncoming: false,
        );
        _cachedMessages.add(newMessage);
        developer.log('Message sent and cached');
      } catch (e) {
        developer.log('Error sending message: $e', error: e);
        rethrow;
      }
    } else {
      developer.log('SMS permission not granted');
      throw Exception('SMS permission not granted');
    }
  }

  void clearCache() {
    developer.log('Clearing message cache');
    _cachedMessages = [];
    _isInitialized = false;
  }
}
