import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../providers/address_provider.dart';
import '../models/address.dart';
import '../main.dart';

class AddressFormScreen extends StatefulWidget {
  final Address? address; // Optional address for editing

  const AddressFormScreen({super.key, this.address});

  @override
  State<AddressFormScreen> createState() => _AddressFormScreenState();
}

class _AddressFormScreenState extends State<AddressFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressLine1Controller = TextEditingController();
  final _addressLine2Controller = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _zipCodeController = TextEditingController();
  final uuid = const Uuid();

  @override
  void initState() {
    super.initState();
    // If editing an existing address, populate the form
    if (widget.address != null) {
      _nameController.text = widget.address!.name;
      _phoneController.text = widget.address!.phone;
      _addressLine1Controller.text = widget.address!.addressLine1;
      _addressLine2Controller.text = widget.address!.addressLine2 ?? '';
      _cityController.text = widget.address!.city;
      _stateController.text = widget.address!.state;
      _zipCodeController.text = widget.address!.zipCode;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressLine1Controller.dispose();
    _addressLine2Controller.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _zipCodeController.dispose();
    super.dispose();
  }

  Future<void> _saveAddress() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    try {
      final addressProvider = Provider.of<AddressProvider>(context, listen: false);
      final currentUser = supabase.auth.currentUser;

      if (currentUser == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('You must be logged in to save an address.')),
        );
        return;
      }

      final newAddress = Address(
        id: widget.address?.id ?? uuid.v4(),
        userId: currentUser.id,
        name: _nameController.text,
        phone: _phoneController.text,
        addressLine1: _addressLine1Controller.text,
        addressLine2: _addressLine2Controller.text.isEmpty
            ? null
            : _addressLine2Controller.text,
        city: _cityController.text,
        state: _stateController.text,
        zipCode: _zipCodeController.text,
        isDefault: widget.address?.isDefault ?? false,
      );

      if (widget.address != null) {
        // Update existing address
        await addressProvider.updateAddress(newAddress);
      } else {
        // Add new address
        await addressProvider.addAddress(newAddress);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Address ${widget.address != null ? 'updated' : 'saved'} successfully'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true); // Return true to indicate success
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving address: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.address != null ? 'Edit Address' : 'Add Address'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Full Name',
                prefixIcon: Icon(Icons.person_outline),
              ),
              validator: (value) =>
                  value?.isEmpty ?? true ? 'Please enter your name' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _phoneController,
              decoration: const InputDecoration(
                labelText: 'Phone Number',
                prefixIcon: Icon(Icons.phone_outlined),
              ),
              keyboardType: TextInputType.phone,
              validator: (value) {
                if (value?.isEmpty ?? true) {
                  return 'Please enter phone number';
                }
                if (value!.length < 10) {
                  return 'Enter a valid 10-digit number';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _addressLine1Controller,
              decoration: const InputDecoration(
                labelText: 'Address Line 1',
                prefixIcon: Icon(Icons.home_outlined),
              ),
              validator: (value) =>
                  value?.isEmpty ?? true ? 'Please enter address' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _addressLine2Controller,
              decoration: const InputDecoration(
                labelText: 'Address Line 2 (Optional)',
                prefixIcon: Icon(Icons.apartment_outlined),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _cityController,
              decoration: const InputDecoration(
                labelText: 'City',
                prefixIcon: Icon(Icons.location_city_outlined),
              ),
              validator: (value) =>
                  value?.isEmpty ?? true ? 'Please enter city' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _stateController,
              decoration: const InputDecoration(
                labelText: 'State',
                prefixIcon: Icon(Icons.map_outlined),
              ),
              validator: (value) =>
                  value?.isEmpty ?? true ? 'Please enter state' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _zipCodeController,
              decoration: const InputDecoration(
                labelText: 'ZIP Code',
                prefixIcon: Icon(Icons.pin_drop_outlined),
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value?.isEmpty ?? true) {
                  return 'Please enter ZIP code';
                }
                if (value!.length != 6) {
                  return 'Enter a valid 6-digit ZIP code';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _saveAddress,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  widget.address != null ? 'Update Address' : 'Save Address',
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 