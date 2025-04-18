import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart'
    hide Provider; // <-- Add 'hide Provider'
import 'package:uuid/uuid.dart'; // Import UUID
import 'dart:convert'; // For jsonEncode

import '../providers/cart_provider.dart';
import '../providers/address_provider.dart';
import '../models/address.dart';
// Assume CartItem model exists and has necessary fields (id, name, price, quantity)
import '../models/cart_item.dart'; // Import your CartItem model

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({Key? key}) : super(key: key);

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  int _currentStep = 0;
  final _formKey = GlobalKey<FormState>();

  // Form controllers (keep as is)
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressLine1Controller = TextEditingController();
  final _addressLine2Controller = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _zipCodeController = TextEditingController();

  // Payment method (keep as is)
  String _selectedPaymentMethod = 'Cash on Delivery';

  // Loading state for placing order
  bool _isPlacingOrder = false; // Add this state variable

  // Supabase client and UUID generator
  final supabase = Supabase.instance.client;
  final uuid = const Uuid();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadSavedAddress();
    });
  }

  @override
  void dispose() {
    // Dispose controllers (keep as is)
    _nameController.dispose();
    _phoneController.dispose();
    _addressLine1Controller.dispose();
    _addressLine2Controller.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _zipCodeController.dispose();
    super.dispose();
  }

  void _loadSavedAddress() {
    // Keep _loadSavedAddress logic as is
    final addressProvider =
        Provider.of<AddressProvider>(context, listen: false);
    final savedAddress = addressProvider.getDefaultAddress();
    if (savedAddress != null) {
      setState(() {
        _nameController.text = savedAddress.name;
        _phoneController.text = savedAddress.phone;
        _addressLine1Controller.text = savedAddress.addressLine1;
        _addressLine2Controller.text = savedAddress.addressLine2 ?? '';
        _cityController.text = savedAddress.city;
        _stateController.text = savedAddress.state;
        _zipCodeController.text = savedAddress.zipCode;
      });
    }
  }

  void _saveAddress() {
    // 1. Validate the form first
    if (!_formKey.currentState!.validate()) {
      // If validation fails, exit the function early
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please fill all required address fields.')),
      );
      return;
    }

    // 2. Get the provider
    final addressProvider =
        Provider.of<AddressProvider>(context, listen: false);

    // --- ENSURE THIS DEFINITION EXISTS ---
    // 3. Create the Address object from the controllers
    final newAddress = Address(
      id: DateTime.now().toString(), // Or use uuid.v4() if you prefer
      name: _nameController.text,
      phone: _phoneController.text,
      addressLine1: _addressLine1Controller.text,
      addressLine2: _addressLine2Controller.text.isEmpty
          ? null // Store null if empty
          : _addressLine2Controller.text,
      city: _cityController.text,
      state: _stateController.text,
      zipCode: _zipCodeController.text,
      isDefault: true, // Assuming saving always makes it the default for now
    );
    // --- END OF DEFINITION CHECK ---

    // 4. Call the provider's addAddress method with the created object
    addressProvider.addAddress(
        newAddress); // <-- This line needs 'newAddress' defined above

    // 5. Show confirmation
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Address saved successfully'),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        margin: const EdgeInsets.all(10),
      ),
    );
  }

  // --- Modified _placeOrder Function ---
  Future<void> _placeOrder() async {
    // 1. Validate address form if on the first step
    if (_currentStep == 0 && !_formKey.currentState!.validate()) {
      return;
    }

    // Check if user is logged in
    final currentUser = supabase.auth.currentUser;
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error: User not logged in. Cannot place order.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // 2. Set loading state
    setState(() {
      _isPlacingOrder = true;
    });

    try {
      final cartProvider = Provider.of<CartProvider>(context, listen: false);
      final String orderId = uuid.v4(); // Generate unique order ID

      // 3. Prepare Order Items JSON
      final List<Map<String, dynamic>> orderItemsList = [];
      cartProvider.items.forEach((key, cartItem) {
        orderItemsList.add({
          'product_id': cartItem.id, // Assuming CartItem has product ID
          'product_name': cartItem.name,
          'quantity': cartItem.quantity,
          'price': cartItem.price, // Price per unit at time of order
        });
      });
      final String orderItemsJson = jsonEncode(orderItemsList);

      // 4. Prepare Order Data Map for Supabase
      const double deliveryFee = 100.0; // Keep consistent
      final double subtotal = cartProvider.totalPrice;
      final double totalAmount = subtotal + deliveryFee;

      final Map<String, dynamic> orderData = {
        'id': orderId,
        'user_id': currentUser.id,
        // 'created_at': handled by default value in Supabase
        'shipping_name': _nameController.text,
        'shipping_phone': _phoneController.text,
        'shipping_address_line1': _addressLine1Controller.text,
        'shipping_address_line2': _addressLine2Controller.text.isEmpty
            ? null
            : _addressLine2Controller.text,
        'shipping_city': _cityController.text,
        'shipping_state': _stateController.text,
        'shipping_zip_code': _zipCodeController.text,
        'payment_method': _selectedPaymentMethod,
        'subtotal': subtotal,
        'delivery_fee': deliveryFee,
        'total_amount': totalAmount,
        'status': 'Pending', // Initial status
        'order_items': orderItemsJson, // Store items as JSONB
      };

      // 5. Insert data into Supabase 'orders' table
      await supabase.from('orders').insert(orderData);

      // 6. Success: Clear cart and show success dialog
      cartProvider.clearCart();
      _showOrderSuccessDialog(orderId); // Pass order ID for potential display
    } catch (error) {
      // 7. Error Handling
      debugPrint('Error placing order: $error'); // Log the error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error placing order: ${error.toString()}'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(10),
        ),
      );
    } finally {
      // 8. Reset loading state
      if (mounted) {
        // Check if widget is still in the tree
        setState(() {
          _isPlacingOrder = false;
        });
      }
    }
  }
  // --- End of Modified _placeOrder Function ---

  // --- Modified Success Dialog ---
  void _showOrderSuccessDialog(String orderId) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Order Placed!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle_outline,
                color: Colors.green[600], size: 60),
            const SizedBox(height: 16),
            const Text('Your order has been placed successfully.',
                textAlign: TextAlign.center, style: TextStyle(fontSize: 16)),
            const SizedBox(height: 8),
            // Optional: Display Order ID
            // Text('Order ID: $orderId', style: TextStyle(color: Colors.grey[700], fontSize: 12)),
            // const SizedBox(height: 4),
            Text('Payment Method: $_selectedPaymentMethod',
                style: TextStyle(color: Colors.grey[700])),
          ],
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop(); // Close dialog
              Navigator.of(context).pop(); // Go back from checkout screen
            },
            child: const Text('CONTINUE SHOPPING'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cartProvider = Provider.of<CartProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Checkout'),
        elevation: 0,
      ),
      body: cartProvider.itemCount == 0
          ? _buildEmptyCart()
          : Stepper(
              type: StepperType.vertical,
              currentStep: _currentStep,
              onStepContinue: _isPlacingOrder
                  ? null
                  : () {
                      // Disable button while loading
                      if (_currentStep == 0) {
                        if (_formKey.currentState!.validate()) {
                          setState(() {
                            _currentStep += 1;
                          });
                        }
                      } else if (_currentStep == 1) {
                        _placeOrder(); // Call async function
                      }
                    },
              onStepCancel: _isPlacingOrder
                  ? null
                  : () {
                      // Disable button while loading
                      if (_currentStep > 0) {
                        setState(() {
                          _currentStep -= 1;
                        });
                      } else {
                        Navigator.of(context).pop();
                      }
                    },
              controlsBuilder: (context, details) {
                return Padding(
                  padding: const EdgeInsets.only(top: 20.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: details
                              .onStepContinue, // Will be null if _isPlacingOrder is true
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8)),
                          ),
                          child: _isPlacingOrder && _currentStep == 1
                              ? const SizedBox(
                                  // Show loader inside button
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2, color: Colors.white),
                                )
                              : Text(_currentStep == 0
                                  ? 'CONTINUE'
                                  : 'PLACE ORDER'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: details
                              .onStepCancel, // Will be null if _isPlacingOrder is true
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8)),
                          ),
                          child: Text(_currentStep == 0 ? 'CANCEL' : 'BACK'),
                        ),
                      ),
                    ],
                  ),
                );
              },
              steps: [
                Step(
                  title: const Text('Shipping Address'),
                  content: _buildAddressForm(), // Keep as is
                  isActive: _currentStep >= 0,
                  state:
                      _currentStep > 0 ? StepState.complete : StepState.indexed,
                ),
                Step(
                  title: const Text('Payment & Summary'), // Updated title
                  content: _buildPaymentMethodSelection(), // Keep as is
                  isActive: _currentStep >= 1,
                  state:
                      _currentStep > 1 ? StepState.complete : StepState.indexed,
                ),
              ],
            ),
    );
  }

  Widget _buildEmptyCart() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.shopping_cart_outlined,
            size: 70,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 24),
          Text(
            'Your Cart is Empty',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'Add some items to your cart before checkout.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                    height: 1.5,
                  ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.of(context).pop();
            },
            icon: const Icon(Icons.shopping_bag_outlined),
            label: const Text('BROWSE PRODUCTS'),
            style: ElevatedButton.styleFrom(
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildAddressForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Name field
          TextFormField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Full Name',
              prefixIcon: Icon(Icons.person_outline),
              border: OutlineInputBorder(
                  borderRadius:
                      BorderRadius.all(Radius.circular(8))), // Added border
              isDense: true, // Make field compact
            ),
            textCapitalization: TextCapitalization.words,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your name';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          // Phone field
          TextFormField(
            controller: _phoneController,
            decoration: const InputDecoration(
              labelText: 'Phone Number',
              prefixIcon: Icon(Icons.phone_outlined),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(8))),
              isDense: true,
            ),
            keyboardType: TextInputType.phone,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(10),
            ],
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your phone number';
              }
              if (value.length < 10) {
                return 'Please enter a valid 10-digit phone number';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          // Address Line 1
          TextFormField(
            controller: _addressLine1Controller,
            decoration: const InputDecoration(
              labelText: 'Address Line 1',
              prefixIcon: Icon(Icons.home_outlined),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(8))),
              isDense: true,
            ),
            maxLines: null, // Allow multiple lines if needed
            keyboardType: TextInputType.multiline,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your address';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          // Address Line 2 (optional)
          TextFormField(
            controller: _addressLine2Controller,
            decoration: const InputDecoration(
              labelText: 'Address Line 2 (optional)',
              prefixIcon: Icon(Icons.apartment_outlined),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(8))),
              isDense: true,
            ),
            maxLines: null,
            keyboardType: TextInputType.multiline,
          ),
          const SizedBox(height: 16),

          // City
          TextFormField(
            controller: _cityController,
            decoration: const InputDecoration(
              labelText: 'City',
              prefixIcon: Icon(Icons.location_city_outlined),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(8))),
              isDense: true,
            ),
            textCapitalization: TextCapitalization.words,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your city';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          // State & Zip Row
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _stateController,
                  decoration: const InputDecoration(
                    labelText: 'State',
                    prefixIcon: Icon(Icons.map_outlined),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(8))),
                    isDense: true,
                  ),
                  textCapitalization: TextCapitalization.words,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter state';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _zipCodeController,
                  decoration: const InputDecoration(
                    labelText: 'ZIP Code',
                    prefixIcon: Icon(Icons.pin_drop_outlined),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(8))),
                    isDense: true,
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(
                        6), // Adjust length if needed
                  ],
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Enter ZIP';
                    }
                    if (value.length < 5) {
                      // Adjust length validation if needed
                      return 'Invalid ZIP';
                    }
                    return null;
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Save address button (Optional: Keep or remove based on flow)
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  // Changed to OutlinedButton for less emphasis
                  onPressed: _saveAddress,
                  icon: const Icon(Icons.save_outlined, size: 18),
                  label: const Text('SAVE THIS ADDRESS'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Theme.of(context).primaryColor,
                    side: BorderSide(
                        color: Theme.of(context).primaryColor.withOpacity(0.5)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Order summary
        _buildOrderSummary(),
        const SizedBox(height: 24),

        // Payment method selection
        const Text(
          'Select Payment Method',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),

        // Cash on Delivery option
        _buildPaymentOption(
          title: 'Cash on Delivery',
          subtitle: 'Pay when you receive your order',
          icon: Icons.money_outlined,
          isSelected: _selectedPaymentMethod == 'Cash on Delivery',
          onTap: () {
            setState(() {
              _selectedPaymentMethod = 'Cash on Delivery';
            });
          },
        ),
        const SizedBox(height: 12),

        // Credit/Debit Card option (disabled for demo)
        _buildPaymentOption(
          title: 'Credit/Debit Card',
          subtitle: 'Pay securely with your card',
          icon: Icons.credit_card_outlined,
          isSelected: _selectedPaymentMethod == 'Credit/Debit Card',
          isDisabled: true, // Disabled for this demo
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Card payment not available in this demo'),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                margin: const EdgeInsets.all(10),
              ),
            );
          },
        ),
        const SizedBox(height: 12),

        // UPI option (disabled for demo)
        _buildPaymentOption(
          title: 'UPI Payment',
          subtitle: 'Pay using any UPI app',
          icon: Icons.account_balance_wallet_outlined,
          isSelected: _selectedPaymentMethod == 'UPI Payment',
          isDisabled: true, // Disabled for this demo
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('UPI payment not available in this demo'),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                margin: const EdgeInsets.all(10),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildPaymentOption({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isSelected,
    bool isDisabled = false,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: isDisabled ? null : onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDisabled
              ? Colors.grey[100] // Different background for disabled
              : (isSelected
                  ? Theme.of(context).primaryColor.withOpacity(0.1)
                  : Colors.white), // Use white or theme background
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDisabled
                ? Colors.grey[300]!
                : (isSelected
                    ? Theme.of(context).primaryColor
                    : Colors.grey.withOpacity(0.3)),
            width:
                isSelected ? 1.5 : 1.0, // Slightly thicker border if selected
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isDisabled
                    ? Colors.grey[200]
                    : (isSelected
                        ? Theme.of(context).primaryColor.withOpacity(0.2)
                        : Colors.grey.withOpacity(0.1)),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: isDisabled
                    ? Colors.grey[400]
                    : (isSelected
                        ? Theme.of(context).primaryColor
                        : Colors.grey[700]),
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isDisabled ? Colors.grey[500] : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: isDisabled ? Colors.grey[400] : Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            if (!isDisabled) // Only show checkmark for enabled options
              Radio<String>(
                value: title, // Use title as unique value for Radio group
                groupValue: _selectedPaymentMethod,
                onChanged: (String? value) {
                  if (value != null) {
                    onTap(); // Call the original onTap to update state
                  }
                },
                activeColor: Theme.of(context).primaryColor,
              )
            else
              Container(
                // Show "Coming Soon" for disabled options
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Soon',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey[500],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderSummary() {
    final cartProvider = Provider.of<CartProvider>(context);
    // Ensure delivery fee is handled correctly (e.g., free above certain amount?)
    final double deliveryFee = cartProvider.totalPrice > 0 ? 100.0 : 0.0;
    final double totalWithDelivery = cartProvider.totalPrice + deliveryFee;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Order Summary',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Subtotal (${cartProvider.totalItemsCount} ${cartProvider.totalItemsCount == 1 ? "item" : "items"})',
                style: TextStyle(fontSize: 14, color: Colors.grey[700]),
              ),
              Text(
                'Rs.${cartProvider.totalPrice.toStringAsFixed(2)}',
                style:
                    const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Delivery Fee',
                style: TextStyle(fontSize: 14, color: Colors.grey[700]),
              ),
              Text(
                deliveryFee > 0
                    ? 'Rs.${deliveryFee.toStringAsFixed(2)}'
                    : 'Free',
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: deliveryFee > 0 ? null : Colors.green[700]),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total Amount',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              Text(
                'Rs.${totalWithDelivery.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).primaryColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
} // End of _CheckoutScreenState
