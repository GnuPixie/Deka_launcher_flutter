import 'package:flutter/material.dart';
import 'package:call_log/call_log.dart';
import 'package:permission_handler/permission_handler.dart';

class CallLogsScreen extends StatefulWidget {
  const CallLogsScreen({super.key});

  @override
  State<CallLogsScreen> createState() => _CallLogsScreenState();
}

class _CallLogsScreenState extends State<CallLogsScreen> {
  List<CallLogEntry> _callLogs = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCallLogs();
  }

  Future<void> _loadCallLogs() async {
    if (await Permission.phone.request().isGranted) {
      final Iterable<CallLogEntry> entries = await CallLog.get();
      setState(() {
        _callLogs = entries.toList();
        _isLoading = false;
      });
    }
  }

  String _formatDuration(int? duration) {
    if (duration == null) return 'N/A';
    final minutes = (duration / 60).floor();
    final seconds = duration % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'N/A';
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute}';
  }

  IconData _getCallTypeIcon(CallType? type) {
    switch (type) {
      case CallType.incoming:
        return Icons.call_received;
      case CallType.outgoing:
        return Icons.call_made;
      case CallType.missed:
        return Icons.call_missed;
      default:
        return Icons.call;
    }
  }

  Color _getCallTypeColor(CallType? type) {
    switch (type) {
      case CallType.incoming:
        return Colors.green;
      case CallType.outgoing:
        return Colors.blue;
      case CallType.missed:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Call Logs'),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _callLogs.length,
              itemBuilder: (context, index) {
                final call = _callLogs[index];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: _getCallTypeColor(call.callType),
                    child: Icon(
                      _getCallTypeIcon(call.callType),
                      color: Colors.white,
                    ),
                  ),
                  title: Text(call.name ?? call.number ?? 'Unknown'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_formatDate(call.timestamp != null
                          ? DateTime.fromMillisecondsSinceEpoch(call.timestamp!)
                          : null)),
                      Text('Duration: ${_formatDuration(call.duration)}'),
                    ],
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.call),
                    onPressed: () {
                      // Implement call back functionality
                    },
                  ),
                );
              },
            ),
    );
  }
}
