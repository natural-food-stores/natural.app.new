import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart'; // Needed if generating ID here, though Checkout does it now
import '../models/address.dart'; // Adjust path if needed

class AddressProvider with ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;
  List<Address> _addresses = [];
  Address? _defaultAddress; // Can be null if no addresses or none are default
  bool _isLoading = false;
  String? _error;

  // Public getters
  List<Address> get addresses =>
      List.unmodifiable(_addresses); // Return unmodifiable list
  Address? get defaultAddress => _defaultAddress;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Fetch addresses for the current user
  Future<void> loadAddresses() async {
    _isLoading = true;
    _error = null;
    notifyListeners(); // Notify loading start

    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        _addresses = []; // Clear addresses if user logs out
        _defaultAddress = null;
        throw Exception('User not logged in.'); // Or handle silently
      }

      final response = await _supabase
          .from('addresses')
          .select() // Select all columns
          .eq('user_id', user.id)
          .order('is_default', ascending: false) // Default address first
          .order('created_at', ascending: false); // Then newest first

      // Supabase Flutter v2+ returns List<Map<String, dynamic>> directly
      final List<dynamic> data = response as List<dynamic>;
      _addresses = data
          .map((json) => Address.fromJson(json as Map<String, dynamic>))
          .toList();

      // Find the default address after fetching
      _updateDefaultAddressLocally();

      debugPrint("AddressProvider: Loaded ${_addresses.length} addresses.");
    } catch (e) {
      debugPrint('Error loading addresses: $e');
      _error = 'Failed to load addresses: $e';
      _addresses = []; // Clear list on error
      _defaultAddress = null;
    } finally {
      _isLoading = false;
      notifyListeners(); // Notify loading end / data update / error
    }
  }

  // Add a new address
  Future<void> addAddress(Address address) async {
    // No loading state needed here usually, happens fast
    _error = null; // Clear previous error

    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('User not logged in.');

      // Determine if this new address should become the default
      // It becomes default if it's the very first address OR if explicitly marked AND no other default exists
      // The isDefault flag in the passed 'address' object can guide this.
      final shouldBeDefault = _addresses.isEmpty || address.isDefault;

      // Create the final address object to insert
      // Use ID/UserID from the incoming object if provided, otherwise ensure they are set
      final addressToInsert = address.copyWith(
        // ID is generated in CheckoutScreen now, ensure it's passed correctly
        userId: user.id, // Always associate with the current user
        isDefault: shouldBeDefault, // Set based on logic above
        // created_at will be handled by Supabase default
      );

      // If this new address IS becoming the default, unset others first
      if (shouldBeDefault && _addresses.isNotEmpty) {
        await _unsetCurrentDefault(user.id);
        // Update local list state immediately for responsiveness (optional but good UX)
        for (var i = 0; i < _addresses.length; i++) {
          if (_addresses[i].isDefault) {
            _addresses[i] = _addresses[i].copyWith(isDefault: false);
            break; // Assuming only one default exists
          }
        }
      }

      // Insert the new address into Supabase
      await _supabase.from('addresses').insert(addressToInsert.toJson());

      // Add to local list and update default if needed
      _addresses.insert(0, addressToInsert); // Add to beginning (often desired)
      if (shouldBeDefault) {
        _defaultAddress = addressToInsert;
      }

      debugPrint(
          "AddressProvider: Added address ${addressToInsert.id}. Default: $shouldBeDefault");
      notifyListeners();
    } catch (e) {
      debugPrint('Error adding address: $e');
      _error = 'Failed to add address: $e';
      notifyListeners(); // Notify about the error
      rethrow; // Rethrow to allow UI to handle specific errors if needed
    }
  }

  // Update an existing address
  Future<void> updateAddress(Address address) async {
    _error = null;
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('User not logged in.');

      // If this updated address is being set as default, unset the current one first
      if (address.isDefault) {
        await _unsetCurrentDefault(user.id, excludeId: address.id);
        // Update local list state immediately
        for (var i = 0; i < _addresses.length; i++) {
          if (_addresses[i].isDefault && _addresses[i].id != address.id) {
            _addresses[i] = _addresses[i].copyWith(isDefault: false);
            break;
          }
        }
      }

      // Perform the update in Supabase
      await _supabase
          .from('addresses')
          .update(address
              .toJson()) // Assumes toJson excludes fields like created_at
          .eq('id', address.id)
          .eq('user_id', user.id); // Ensure user owns the address

      // Update the local list
      final index = _addresses.indexWhere((a) => a.id == address.id);
      if (index != -1) {
        _addresses[index] = address;
        // Re-evaluate the default address locally
        _updateDefaultAddressLocally();
        debugPrint("AddressProvider: Updated address ${address.id}.");
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error updating address: $e');
      _error = 'Failed to update address: $e';
      notifyListeners();
      rethrow;
    }
  }

  // Delete an address
  Future<void> deleteAddress(String id) async {
    _error = null;
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('User not logged in.');

      await _supabase
          .from('addresses')
          .delete()
          .eq('id', id)
          .eq('user_id', user.id); // Ensure user owns the address

      // Remove from local list
      final removedAddress =
          _addresses.firstWhere((a) => a.id == id); // Get before removing
      _addresses.removeWhere((address) => address.id == id);

      // If the deleted address was the default, find a new default
      if (removedAddress.isDefault) {
        // Try to set the first remaining address as default in DB and locally
        if (_addresses.isNotEmpty) {
          await setDefaultAddress(
              _addresses.first.id); // This will notifyListeners
        } else {
          _defaultAddress = null; // No addresses left
          notifyListeners();
        }
      } else {
        // If deleted was not default, no change to default needed, just notify
        notifyListeners();
      }
      debugPrint("AddressProvider: Deleted address $id.");
    } catch (e) {
      debugPrint('Error deleting address: $e');
      _error = 'Failed to delete address: $e';
      notifyListeners();
      rethrow;
    }
  }

  // Set a specific address as the default
  Future<void> setDefaultAddress(String id) async {
    _error = null;
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('User not logged in.');

      // Find the target address locally first
      final targetAddressIndex = _addresses.indexWhere((a) => a.id == id);
      if (targetAddressIndex == -1)
        throw Exception('Address not found locally.');

      // 1. Unset the current default address in Supabase
      await _unsetCurrentDefault(user.id, excludeId: id);

      // 2. Set the new address as default in Supabase
      await _supabase
          .from('addresses')
          .update({'is_default': true})
          .eq('id', id)
          .eq('user_id', user.id);

      // 3. Update local state for immediate UI feedback
      final currentDefaultIndex = _addresses.indexWhere((a) => a.isDefault);
      if (currentDefaultIndex != -1) {
        _addresses[currentDefaultIndex] =
            _addresses[currentDefaultIndex].copyWith(isDefault: false);
      }
      _addresses[targetAddressIndex] =
          _addresses[targetAddressIndex].copyWith(isDefault: true);
      _defaultAddress =
          _addresses[targetAddressIndex]; // Update the cached default

      debugPrint("AddressProvider: Set address $id as default.");
      notifyListeners();
    } catch (e) {
      debugPrint('Error setting default address: $e');
      _error = 'Failed to set default address: $e';
      notifyListeners();
      rethrow;
    }
  }

  // Helper to unset the current default address in Supabase
  Future<void> _unsetCurrentDefault(String userId, {String? excludeId}) async {
    var query = _supabase
        .from('addresses')
        .update({'is_default': false})
        .eq('user_id', userId)
        .eq('is_default', true); // Only target the current default

    // Optionally exclude the ID that is *about* to become default
    if (excludeId != null) {
      query = query.neq('id', excludeId);
    }

    await query;
    debugPrint(
        "AddressProvider: Unset previous default address in DB (excluding: $excludeId).");
  }

  // Helper to find and set the _defaultAddress from the local _addresses list
  void _updateDefaultAddressLocally() {
    try {
      _defaultAddress = _addresses.firstWhere((address) => address.isDefault);
    } catch (e) {
      // No address marked as default, fallback to the first address if list isn't empty
      _defaultAddress = _addresses.isNotEmpty ? _addresses.first : null;
      // You might want to automatically set the first one as default in the DB here if none exists
      // if (_defaultAddress != null) {
      //   setDefaultAddress(_defaultAddress!.id);
      // }
    }
    debugPrint(
        "AddressProvider: Updated local default address reference. ID: ${_defaultAddress?.id}");
  }
}
