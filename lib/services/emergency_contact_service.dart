import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class EmergencyContactService {
  
  static const String _key = 'emergency_contacts';
  
  // Save contacts to SharedPreferences
  Future<void> saveContacts(List<Map<String, String>> contacts) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = jsonEncode(contacts);
    await prefs.setString(_key, jsonString);
  }
  
  // Load contacts from SharedPreferences
  Future<List<Map<String, String>>> getContacts() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_key);
    if (jsonString == null) return [];
    try {
      final List<dynamic> decoded = jsonDecode(jsonString);
      return decoded.map((e) => Map<String, String>.from(e)).toList();
    } catch (e) {
      return [];
    }
  }
  
  // Add single contact
  Future<void> addContact(String name, String phone) async {
    final contacts = await getContacts();
    if (contacts.length >= 3) {
      throw Exception('Maximum 3 emergency contacts allowed');
    }
    contacts.add({'name': name, 'phone': phone});
    await saveContacts(contacts);
  }
  
  // Remove contact by index
  Future<void> removeContact(int index) async {
    final contacts = await getContacts();
    if (index >= 0 && index < contacts.length) {
      contacts.removeAt(index);
      await saveContacts(contacts);
    }
  }
  
  // Get phone numbers only for SOS
  Future<List<String>> getPhoneNumbers() async {
    final contacts = await getContacts();
    return contacts
      .map((c) => c['phone'] ?? '')
      .where((p) => p.isNotEmpty)
      .toList();
  }
}
