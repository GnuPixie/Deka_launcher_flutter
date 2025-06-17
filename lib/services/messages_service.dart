import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';

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
    final status = await Permission.sms.request();
    return status.isGranted;
  }

  Future<List<Message>> getMessages({int limit = 20, int offset = 0}) async {
    if (!_isInitialized) {
      if (await requestPermission()) {
        try {
          final result =
              await platform.invokeMethod<List<dynamic>>('getMessages', {
            'limit': limit,
            'offset': offset,
          });

          if (result != null) {
            _cachedMessages = result
                .map((json) => Message.fromJson(json as Map<dynamic, dynamic>))
                .toList();
            _isInitialized = true;
          }
        } catch (e) {
          _cachedMessages = [];
          _isInitialized = false;
          rethrow;
        }
      } else {
        throw Exception('SMS permission not granted');
      }
    }
    return _cachedMessages;
  }

  Future<void> sendMessage(String recipient, String content) async {
    if (await requestPermission()) {
      try {
        await platform.invokeMethod('sendMessage', {
          'recipient': recipient,
          'content': content,
        });
      } catch (e) {
        rethrow;
      }
    } else {
      throw Exception('SMS permission not granted');
    }
  }

  void clearCache() {
    _cachedMessages = [];
    _isInitialized = false;
  }
}
