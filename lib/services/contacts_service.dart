import 'package:contacts_service_plus/contacts_service_plus.dart'
    as contacts_service;
import 'package:permission_handler/permission_handler.dart';

class ContactsService {
  static final ContactsService _instance = ContactsService._internal();
  factory ContactsService() => _instance;
  ContactsService._internal();

  List<contacts_service.Contact> _cachedContacts = [];
  bool _isInitialized = false;

  Future<bool> requestPermission() async {
    final status = await Permission.contacts.request();
    return status.isGranted;
  }

  Future<List<contacts_service.Contact>> getContacts(
      {bool forceRefresh = false}) async {
    if (!_isInitialized || forceRefresh) {
      if (await requestPermission()) {
        try {
          final contacts = await contacts_service.ContactsService.getContacts(
            withThumbnails: false,
            photoHighResolution: false,
          );
          _cachedContacts = contacts.toList();
          _isInitialized = true;
        } catch (e) {
          _cachedContacts = [];
          _isInitialized = false;
          rethrow;
        }
      } else {
        throw Exception('Contacts permission not granted');
      }
    }
    return _cachedContacts;
  }

  Future<List<contacts_service.Contact>> searchContacts(String query) async {
    if (!_isInitialized) {
      await getContacts();
    }

    if (query.isEmpty) {
      return _cachedContacts;
    }

    final lowercaseQuery = query.toLowerCase();
    return _cachedContacts.where((contact) {
      final name = contact.displayName?.toLowerCase() ?? '';
      final phones =
          contact.phones?.map((p) => p.value?.toLowerCase() ?? '').toList() ??
              [];
      final emails =
          contact.emails?.map((e) => e.value?.toLowerCase() ?? '').toList() ??
              [];

      return name.contains(lowercaseQuery) ||
          phones.any((phone) => phone.contains(lowercaseQuery)) ||
          emails.any((email) => email.contains(lowercaseQuery));
    }).toList();
  }

  void clearCache() {
    _cachedContacts = [];
    _isInitialized = false;
  }
}
