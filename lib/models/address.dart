import 'package:flutter/foundation.dart'; // For @required in older Flutter versions, but generally good practice

// Make sure this matches your Supabase table columns exactly
class Address {
  final String id; // Should match Supabase 'id' column (usually uuid)
  final String
      userId; // Should match Supabase 'user_id' column (usually uuid referencing auth.users)
  final String name;
  final String phone;
  final String addressLine1;
  final String? addressLine2; // Nullable if the column allows NULL
  final String city;
  final String state;
  final String zipCode; // Changed to zipCode for consistency
  final bool isDefault;
  final DateTime?
      createdAt; // Optional: if you select it from Supabase (usually handled by default)

  Address({
    required this.id,
    required this.userId,
    required this.name,
    required this.phone,
    required this.addressLine1,
    this.addressLine2,
    required this.city,
    required this.state,
    required this.zipCode,
    this.isDefault = false, // Default to false unless specified
    this.createdAt, // Make optional
  });

  // Create a copy of this address with potentially modified fields
  // Useful for updating state immutably
  Address copyWith({
    String? id,
    String? userId,
    String? name,
    String? phone,
    String? addressLine1,
    // Handle nullable field copy correctly
    String?
        addressLine2, // Pass null to clear, value to set, leave absent to keep original
    bool? clearAddressLine2, // Explicit flag to set null
    String? city,
    String? state,
    String? zipCode,
    bool? isDefault,
    DateTime? createdAt,
  }) {
    return Address(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      addressLine1: addressLine1 ?? this.addressLine1,
      addressLine2: (clearAddressLine2 ?? false)
          ? null
          : (addressLine2 ?? this.addressLine2),
      city: city ?? this.city,
      state: state ?? this.state,
      zipCode: zipCode ?? this.zipCode,
      isDefault: isDefault ?? this.isDefault,
      createdAt: createdAt ?? this.createdAt, // Keep original if not provided
    );
  }

  // Convert Address object to a Map for Supabase insertion/update
  // Ensure keys match your Supabase column names EXACTLY
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'name': name,
      'phone': phone,
      'address_line1': addressLine1, // Match DB column name
      'address_line2': addressLine2, // Match DB column name
      'city': city,
      'state': state,
      'zip_code': zipCode, // Match DB column name
      'is_default': isDefault,
      // 'created_at': Handled by Supabase default value 'now()', usually excluded from inserts/updates
    };
  }

  // Create an Address object from a Map (e.g., from Supabase response)
  // Ensure keys match your Supabase column names EXACTLY
  factory Address.fromJson(Map<String, dynamic> json) {
    // Basic validation or default values can be added here
    if (json['id'] == null ||
        json['user_id'] == null ||
        json['name'] == null /* ... etc */) {
      // Handle missing required fields appropriately
      // throw FormatException("Missing required fields in Address JSON: $json");
      debugPrint(
          "Warning: Missing required fields in Address JSON: ${json['id']}");
      // Provide defaults or throw error based on requirements
    }

    return Address(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      name: json['name'] as String? ?? '', // Default to empty string if null
      phone: json['phone'] as String? ?? '',
      addressLine1: json['address_line1'] as String? ?? '',
      addressLine2: json['address_line2'] as String?, // Can be null
      city: json['city'] as String? ?? '',
      state: json['state'] as String? ?? '',
      zipCode: json['zip_code'] as String? ?? '',
      isDefault: json['is_default'] as bool? ??
          false, // Default to false if null/missing
      // Parse DateTime if the column is selected and returned
      createdAt: json['created_at'] == null
          ? null
          : DateTime.tryParse(json['created_at'] as String),
    );
  }

  // Useful for debugging
  @override
  String toString() {
    return 'Address(id: $id, userId: $userId, name: $name, phone: $phone, addressLine1: $addressLine1, addressLine2: $addressLine2, city: $city, state: $state, zipCode: $zipCode, isDefault: $isDefault, createdAt: $createdAt)';
  }

  // Optional: Implement equality operator if needed for comparisons (e.g., in tests or Sets)
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Address &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          userId == other.userId &&
          name == other.name &&
          phone == other.phone &&
          addressLine1 == other.addressLine1 &&
          addressLine2 == other.addressLine2 &&
          city == other.city &&
          state == other.state &&
          zipCode == other.zipCode &&
          isDefault == other.isDefault;
  // Note: createdAt is often excluded from equality checks unless critical

  @override
  int get hashCode => Object.hash(
        id,
        userId,
        name,
        phone,
        addressLine1,
        addressLine2,
        city,
        state,
        zipCode,
        isDefault,
      );
}
