import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'screens/contacts_screen.dart';
import 'screens/messages_screen.dart';
import 'screens/dialer_screen.dart';
import 'screens/call_logs_screen.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const LauncherHome(),
      theme: ThemeData(
        brightness: Brightness.light,
        primaryColor: Colors.blue,
        textTheme: const TextTheme(
          bodyLarge: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          bodyMedium: TextStyle(fontSize: 22),
        ),
      ),
    );
  }
}

class LauncherHome extends StatelessWidget {
  const LauncherHome({super.key});

  final List<_LauncherItem> items = const [
    _LauncherItem(
      label: 'Contacts',
      icon: Icons.contacts,
      color: Colors.blue,
      screen: ContactsScreen(),
    ),
    _LauncherItem(
      label: 'Messages',
      icon: Icons.message,
      color: Colors.green,
      screen: MessagesScreen(),
    ),
    _LauncherItem(
      label: 'Dial',
      icon: Icons.dialpad,
      color: Colors.orange,
      screen: DialerScreen(),
    ),
    _LauncherItem(
      label: 'Missed Calls',
      icon: Icons.call_missed,
      color: Colors.red,
      screen: CallLogsScreen(),
    ),
  ];

  Future<void> _onItemTap(BuildContext context, _LauncherItem item) async {
    // Request necessary permissions based on the selected feature
    if (item.screen is ContactsScreen) {
      await Permission.contacts.request();
    } else if (item.screen is MessagesScreen) {
      await Permission.sms.request();
    } else if (item.screen is CallLogsScreen) {
      await Permission.phone.request();
    }

    if (context.mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => item.screen),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: GridView.count(
              crossAxisCount: 2,
              mainAxisSpacing: 32,
              crossAxisSpacing: 32,
              shrinkWrap: true,
              childAspectRatio: 0.8,
              children: items.map((item) {
                return ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: item.color,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(32),
                    ),
                    padding: const EdgeInsets.all(16),
                    elevation: 8,
                  ),
                  onPressed: () => _onItemTap(context, item),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(item.icon, size: 64, color: Colors.white),
                      const SizedBox(height: 16),
                      Text(
                        item.label,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }
}

class _LauncherItem {
  final String label;
  final IconData icon;
  final Color color;
  final Widget screen;
  const _LauncherItem({
    required this.label,
    required this.icon,
    required this.color,
    required this.screen,
  });
}
