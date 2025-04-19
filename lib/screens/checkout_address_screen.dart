import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/address_provider.dart';
import '../models/address.dart';
import 'address_form_screen.dart';

class CheckoutAddressScreen extends StatefulWidget {
  final Function(Address) onAddressSelected;

  const CheckoutAddressScreen({
    super.key,
    required this.onAddressSelected,
  });

  @override
  State<CheckoutAddressScreen> createState() => _CheckoutAddressScreenState();
}

class _CheckoutAddressScreenState extends State<CheckoutAddressScreen> {
  @override
  void initState() {
    super.initState();
    _loadAddresses();
  }

  Future<void> _loadAddresses() async {
    try {
      await Provider.of<AddressProvider>(context, listen: false).loadAddresses();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading addresses: $e'),
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
        title: const Text('Select Delivery Address'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AddressFormScreen(),
                ),
              );
              if (result == true && mounted) {
                _loadAddresses();
              }
            },
          ),
        ],
      ),
      body: Consumer<AddressProvider>(
        builder: (context, addressProvider, child) {
          if (addressProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (addressProvider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Error: ${addressProvider.error}',
                    style: const TextStyle(color: Colors.red),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadAddresses,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (addressProvider.addresses.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'No saved addresses',
                    style: TextStyle(fontSize: 18),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AddressFormScreen(),
                        ),
                      );
                      if (result == true && mounted) {
                        _loadAddresses();
                      }
                    },
                    child: const Text('Add Address'),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: addressProvider.addresses.length,
            itemBuilder: (context, index) {
              final address = addressProvider.addresses[index];
              return _buildAddressCard(address, addressProvider);
            },
          );
        },
      ),
    );
  }

  Widget _buildAddressCard(Address address, AddressProvider addressProvider) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () {
          widget.onAddressSelected(address);
          Navigator.pop(context);
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    address.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (address.isDefault)
                    const Chip(
                      label: Text('Default'),
                      backgroundColor: Colors.green,
                      labelStyle: TextStyle(color: Colors.white),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(address.phone),
              const SizedBox(height: 8),
              Text(address.addressLine1),
              if (address.addressLine2 != null) ...[
                const SizedBox(height: 4),
                Text(address.addressLine2!),
              ],
              const SizedBox(height: 4),
              Text('${address.city}, ${address.state} ${address.zipCode}'),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AddressFormScreen(address: address),
                        ),
                      );
                      if (result == true && mounted) {
                        _loadAddresses();
                      }
                    },
                    icon: const Icon(Icons.edit),
                    label: const Text('Edit'),
                  ),
                  const SizedBox(width: 8),
                  if (!address.isDefault)
                    TextButton.icon(
                      onPressed: () async {
                        try {
                          await addressProvider.setDefaultAddress(address.id);
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Default address updated'),
                                backgroundColor: Colors.green,
                              ),
                            );
                          }
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Error updating default address: $e'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        }
                      },
                      icon: const Icon(Icons.star),
                      label: const Text('Set as Default'),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
} 