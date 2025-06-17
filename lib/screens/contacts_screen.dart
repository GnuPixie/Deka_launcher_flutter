import 'package:flutter/material.dart';
import 'package:contacts_service_plus/contacts_service_plus.dart'
    as contacts_service;
import '../services/contacts_service.dart' as app_contacts;

class ContactsScreen extends StatefulWidget {
  const ContactsScreen({super.key});

  @override
  State<ContactsScreen> createState() => _ContactsScreenState();
}

class _ContactsScreenState extends State<ContactsScreen> {
  final app_contacts.ContactsService _contactsService =
      app_contacts.ContactsService();
  final TextEditingController _searchController = TextEditingController();
  List<contacts_service.Contact> _contacts = [];
  List<contacts_service.Contact> _filteredContacts = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  static const int pageSize = 50;
  int _currentPage = 0;
  bool _hasMoreContacts = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadContacts();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadContacts() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });

      final contacts = await _contactsService.getContacts();
      setState(() {
        _contacts = contacts;
        _filteredContacts = contacts.take(pageSize).toList();
        _isLoading = false;
        _hasMoreContacts = contacts.length > pageSize;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load contacts: ${e.toString()}';
      });
    }
  }

  Future<void> _loadMoreContacts() async {
    if (!_isLoadingMore && _hasMoreContacts) {
      setState(() {
        _isLoadingMore = true;
      });

      final nextPage = _currentPage + 1;
      final startIndex = nextPage * pageSize;
      final endIndex = startIndex + pageSize;

      if (startIndex < _contacts.length) {
        setState(() {
          _filteredContacts.addAll(
            _contacts.skip(startIndex).take(endIndex - startIndex),
          );
          _currentPage = nextPage;
          _hasMoreContacts = endIndex < _contacts.length;
          _isLoadingMore = false;
        });
      } else {
        setState(() {
          _hasMoreContacts = false;
          _isLoadingMore = false;
        });
      }
    }
  }

  Future<void> _searchContacts(String query) async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });

      final results = await _contactsService.searchContacts(query);
      setState(() {
        _filteredContacts = results.take(pageSize).toList();
        _isLoading = false;
        _hasMoreContacts = results.length > pageSize;
        _currentPage = 0;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to search contacts: ${e.toString()}';
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
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadContacts,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search contacts...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onChanged: _searchContacts,
            ),
          ),
          if (_errorMessage.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                _errorMessage,
                style: const TextStyle(color: Colors.red),
              ),
            ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : NotificationListener<ScrollNotification>(
                    onNotification: (ScrollNotification scrollInfo) {
                      if (scrollInfo.metrics.pixels ==
                          scrollInfo.metrics.maxScrollExtent) {
                        _loadMoreContacts();
                      }
                      return true;
                    },
                    child: ListView.builder(
                      itemCount:
                          _filteredContacts.length + (_hasMoreContacts ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index == _filteredContacts.length) {
                          return const Center(
                            child: Padding(
                              padding: EdgeInsets.all(8.0),
                              child: CircularProgressIndicator(),
                            ),
                          );
                        }
                        final contact = _filteredContacts[index];
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
                  ),
          ),
        ],
      ),
    );
  }
}
