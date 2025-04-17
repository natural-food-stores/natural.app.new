class Address {
  final String id;
  final String name;
  final String phone;
  final String addressLine1;
  final String? addressLine2;
  final String city;
  final String state;
  final String zipCode;
  final bool isDefault;

  Address({
    required this.id,
    required this.name,
    required this.phone,
    required this.addressLine1,
    this.addressLine2,
    required this.city,
    required this.state,
    required this.zipCode,
    this.isDefault = false,
  });

  // Create a copy of this address with modified fields
  Address copyWith({
    String? id,
    String? name,
    String? phone,
    String? addressLine1,
    String? addressLine2,
    String? city,
    String? state,
    String? zipCode,
    bool? isDefault,
  }) {
    return Address(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      addressLine1: addressLine1 ?? this.addressLine1,
      addressLine2: addressLine2 ?? this.addressLine2,
      city: city ?? this.city,
      state: state ?? this.state,
      zipCode: zipCode ?? this.zipCode,
      isDefault: isDefault ?? this.isDefault,
    );
  }

  // Convert address to a map for storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'addressLine1': addressLine1,
      'addressLine2': addressLine2,
      'city': city,
      'state': state,
      'zipCode': zipCode,
      'isDefault': isDefault,
    };
  }

  // Create an address from a map
  factory Address.fromMap(Map<String, dynamic> map) {
    return Address(
      id: map['id'],
      name: map['name'],
      phone: map['phone'],
      addressLine1: map['addressLine1'],
      addressLine2: map['addressLine2'],
      city: map['city'],
      state: map['state'],
      zipCode: map['zipCode'],
      isDefault: map['isDefault'] ?? false,
    );
  }

  // For debugging
  @override
  String toString() {
    return 'Address{id: $id, name: $name, phone: $phone, addressLine1: $addressLine1, addressLine2: $addressLine2, city: $city, state: $state, zipCode: $zipCode, isDefault: $isDefault}';
  }
}
