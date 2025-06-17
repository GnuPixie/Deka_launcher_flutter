import 'package:flutter/material.dart';
import 'package:contacts_service_plus/contacts_service_plus.dart';
import 'package:permission_handler/permission_handler.dart';

class ContactsScreen extends StatefulWidget {
  const ContactsScreen({super.key});

  @override
  State<ContactsScreen> createState() => _ContactsScreenState();
}

class _ContactsScreenState extends State<ContactsScreen> {
  List<Contact> contacts = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadContacts();
  }

  Future<void> _loadContacts() async {
    if (await Permission.contacts.request().isGranted) {
      final contactsList = await ContactsService.getContacts();
      setState(() {
        contacts = contactsList.toList();
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Contacts'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: contacts.length,
              itemBuilder: (context, index) {
                final contact = contacts[index];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.blue,
                    child: Text(
                      contact.initials(),
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  title: Text(contact.displayName ?? ''),
                  subtitle: contact.phones!.isNotEmpty
                      ? Text(contact.phones!.first.value ?? '')
                      : null,
                  onTap: () {
                    // Handle contact selection
                  },
                );
              },
            ),
    );
  }
} 