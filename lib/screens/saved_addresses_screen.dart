import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/address_provider.dart';
import '../models/address.dart';
import '../screens/checkout_screen.dart'; // Import checkout screen

class SavedAddressesScreen extends StatefulWidget {
  const SavedAddressesScreen({super.key});

  @override
  State<SavedAddressesScreen> createState() => _SavedAddressesScreenState();
}

class _SavedAddressesScreenState extends State<SavedAddressesScreen> {
  @override
  void initState() {
    super.initState();
    // Load addresses when the screen is first shown
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadAddresses();
    });
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
        title: const Text('Saved Addresses'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              // Navigate to add new address screen
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const CheckoutScreen(),
                ),
              ).then((_) {
                // Reload addresses when returning from checkout
                _loadAddresses();
              });
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
            // Show checkout form directly when no addresses exist
            return const CheckoutScreen();
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
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: address.isDefault
              ? Theme.of(context).colorScheme.primary
              : Colors.grey.shade300,
          width: address.isDefault ? 2 : 1,
        ),
      ),
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
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                if (address.isDefault)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Default',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              address.phone,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 8),
            Text(
              address.addressLine1,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            if (address.addressLine2 != null) ...[
              const SizedBox(height: 4),
              Text(
                address.addressLine2!,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
            const SizedBox(height: 4),
            Text(
              '${address.city}, ${address.state} - ${address.zipCode}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () {
                    // Set as default
                    if (!address.isDefault) {
                      addressProvider.setDefaultAddress(address.id);
                    }
                  },
                  icon: Icon(
                    Icons.star,
                    color: address.isDefault
                        ? Theme.of(context).colorScheme.primary
                        : Colors.grey,
                  ),
                  label: Text(
                    address.isDefault ? 'Default' : 'Set as Default',
                    style: TextStyle(
                      color: address.isDefault
                          ? Theme.of(context).colorScheme.primary
                          : Colors.grey,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                TextButton.icon(
                  onPressed: () {
                    // Delete address
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Delete Address'),
                        content: const Text(
                            'Are you sure you want to delete this address?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () async {
                              Navigator.pop(context);
                              try {
                                await addressProvider.deleteAddress(address.id);
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Address deleted successfully'),
                                    ),
                                  );
                                }
                              } catch (e) {
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Error deleting address: $e'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              }
                            },
                            child: const Text('Delete'),
                          ),
                        ],
                      ),
                    );
                  },
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  label: const Text(
                    'Delete',
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
} 