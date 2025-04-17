import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/address.dart';

class AddressProvider with ChangeNotifier {
  List<Address> _addresses = [];
  bool _isLoaded = false;

  List<Address> get addresses => [..._addresses];

  // Load addresses from SharedPreferences
  Future<void> loadAddresses() async {
    if (_isLoaded) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final addressesJson = prefs.getString('addresses');

      if (addressesJson != null) {
        final List<dynamic> decodedData = json.decode(addressesJson);
        _addresses = decodedData.map((item) => Address.fromMap(item)).toList();

        _isLoaded = true;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading addresses: $e');
    }
  }

  // Save addresses to SharedPreferences
  Future<void> _saveAddresses() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final addressesJson = json.encode(
        _addresses.map((address) => address.toMap()).toList(),
      );

      await prefs.setString('addresses', addressesJson);
    } catch (e) {
      debugPrint('Error saving addresses: $e');
    }
  }

  // Add a new address
  Future<void> addAddress(Address address) async {
    // If this is the default address, remove default from others
    if (address.isDefault) {
      _addresses = _addresses.map((addr) {
        return addr.copyWith(isDefault: false);
      }).toList();
    }

    // Check if address already exists (by ID)
    final existingIndex =
        _addresses.indexWhere((addr) => addr.id == address.id);

    if (existingIndex >= 0) {
      // Update existing address
      _addresses[existingIndex] = address;
    } else {
      // Add new address
      _addresses.add(address);
    }

    notifyListeners();
    await _saveAddresses();
  }

  // Remove an address
  Future<void> removeAddress(String id) async {
    _addresses.removeWhere((address) => address.id == id);
    notifyListeners();
    await _saveAddresses();
  }

  // Set an address as default
  Future<void> setDefaultAddress(String id) async {
    _addresses = _addresses.map((address) {
      return address.copyWith(
        isDefault: address.id == id,
      );
    }).toList();

    notifyListeners();
    await _saveAddresses();
  }

  // Get the default address
  Address? getDefaultAddress() {
    if (!_isLoaded) {
      loadAddresses();
      return null;
    }

    try {
      return _addresses.firstWhere((address) => address.isDefault);
    } catch (e) {
      // If no default address is found, return the first one if available
      return _addresses.isNotEmpty ? _addresses.first : null;
    }
  }
}
