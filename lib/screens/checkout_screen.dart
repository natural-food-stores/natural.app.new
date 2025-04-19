import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart'
    hide Provider; // Hide Provider from supabase
import 'package:uuid/uuid.dart'; // Import UUID
import 'dart:convert'; // For jsonEncode
import 'dart:math'; // For random simulation

// Assume these paths are correct for your project structure
import '../providers/cart_provider.dart';
import '../providers/address_provider.dart';
import '../models/address.dart';
import '../models/cart_item.dart'; // Import your CartItem model
import 'checkout_address_screen.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  int _currentStep = 0;
  final _formKey = GlobalKey<FormState>();

  // Form controllers
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressLine1Controller = TextEditingController();
  final _addressLine2Controller = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _zipCodeController = TextEditingController();

  // Payment method state
  String _selectedPaymentMethod = 'Cash on Delivery';

  // Loading state for placing order
  bool _isPlacingOrder = false;

  // Supabase client and UUID generator
  final supabase = Supabase.instance.client;
  final uuid = const Uuid();
  final random = Random(); // For payment simulation

  Address? selectedAddress;

  @override
  void initState() {
    super.initState();
    // Load address after the first frame is built to ensure context is available
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadSavedAddress();
    });
  }

  @override
  void dispose() {
    // Dispose controllers to prevent memory leaks
    _nameController.dispose();
    _phoneController.dispose();
    _addressLine1Controller.dispose();
    _addressLine2Controller.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _zipCodeController.dispose();
    super.dispose();
  }

  // Improved: Loads the default address from the provider into the form fields
  void _loadSavedAddress() {
    // Use try-catch as provider access might fail if called too early
    try {
      // Ensure AddressProvider is accessed safely
      if (!mounted) return; // Check if widget is still in the tree
      final addressProvider =
          Provider.of<AddressProvider>(context, listen: false);

      // It's best practice to ensure addresses are loaded *before* this screen is shown.
      // However, we add checks here for robustness.
      if (addressProvider.addresses.isNotEmpty) {
        final savedAddress = addressProvider.defaultAddress; // Use the getter

        if (savedAddress != null && mounted) {
          // Check mounted again before setState
          setState(() {
            _nameController.text = savedAddress.name;
            _phoneController.text = savedAddress.phone;
            _addressLine1Controller.text = savedAddress.addressLine1;
            _addressLine2Controller.text = savedAddress.addressLine2 ?? '';
            _cityController.text = savedAddress.city;
            _stateController.text = savedAddress.state;
            _zipCodeController.text = savedAddress.zipCode;
          });
          debugPrint(
              "CheckoutScreen: Successfully loaded default address into form.");
        } else if (mounted) {
          // Addresses loaded, but no default address found (maybe first time, or all deleted)
          debugPrint(
              "CheckoutScreen: Addresses loaded, but no default address marked. Form is empty.");
          // Optionally, pre-fill with the first address if available?
          // final firstAddress = addressProvider.addresses.first;
          // ... pre-fill with firstAddress ...
        }
      } else if (mounted) {
        debugPrint(
            "CheckoutScreen: AddressProvider has no addresses loaded yet. Form is empty. Consider loading addresses earlier.");
        // You could optionally trigger a load here, but it might cause UI flicker.
        // addressProvider.loadAddresses().then((_) {
        //   if (mounted) _loadSavedAddress(); // Retry after loading
        // });
      }
    } catch (e) {
      debugPrint(
          "Error accessing AddressProvider or loading saved address in CheckoutScreen: $e");
      // Optionally show a non-intrusive message
      // if (mounted) {
      //   ScaffoldMessenger.of(context).showSnackBar(
      //     const SnackBar(content: Text('Could not pre-fill address.')),
      //   );
      // }
    }
  }

  // Saves the current address form details using AddressProvider
  // Note: This saves the *current form data* as a *new address*.
  // It doesn't update an existing one directly from here.
  Future<void> _saveAddress() async {
    // Validate required fields
    if (_nameController.text.isEmpty ||
        _phoneController.text.isEmpty ||
        _addressLine1Controller.text.isEmpty ||
        _cityController.text.isEmpty ||
        _stateController.text.isEmpty ||
        _zipCodeController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please fill all required address fields.')),
      );
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

      // Create the Address object
      final newAddress = Address(
        id: uuid.v4(),
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
        isDefault: true,
      );

      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      // Save the address
      await addressProvider.addAddress(newAddress);

      // Close loading dialog
      if (mounted) {
        Navigator.of(context).pop(); // Close loading dialog
        
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Address saved successfully'),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)),
            margin: const EdgeInsets.all(10),
          ),
        );

        // Clear form fields
        _nameController.clear();
        _phoneController.clear();
        _addressLine1Controller.clear();
        _addressLine2Controller.clear();
        _cityController.clear();
        _stateController.clear();
        _zipCodeController.clear();

        // Navigate back to profile tab
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop(); // Close loading dialog if open
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving address: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // --- Place Order Function with Simulated Online Payments and Stock Decrement ---
  Future<void> _placeOrder() async {
    // 1. Validate address form if on the first step (redundant check, good practice)
    if (_currentStep == 0) {
      if (!_formKey.currentState!.validate()) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Please complete the shipping address.')),
        );
        return; // Stop if form is invalid
      }
    }

    // 2. Check user login
    final currentUser = supabase.auth.currentUser;
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Error: User not logged in. Cannot place order.'),
            backgroundColor: Colors.red),
      );
      return;
    }

    // 3. Check if cart is empty
    final cartProvider = Provider.of<CartProvider>(context, listen: false);
    if (cartProvider.items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Your cart is empty.'),
            backgroundColor: Colors.orange),
      );
      return;
    }

    // 4. Set loading state
    if (mounted) {
      setState(() {
        _isPlacingOrder = true;
      });
    }

    // --- Payment Logic with Simulation ---
    bool paymentSuccessful = false;
    String? paymentTransactionId;
    String paymentStatusDetail = "Payment Pending"; // More descriptive status

    if (_selectedPaymentMethod == 'Cash on Delivery') {
      paymentSuccessful = true; // Assume COD is successful upfront
      paymentTransactionId = null; // No transaction ID for COD
      paymentStatusDetail = "Payment via Cash on Delivery";
      debugPrint("Proceeding with Cash on Delivery.");
    } else if (_selectedPaymentMethod == 'Credit/Debit Card' ||
        _selectedPaymentMethod == 'UPI Payment') {
      // --- SIMULATE ONLINE PAYMENT ---
      debugPrint("Simulating online payment for: $_selectedPaymentMethod...");
      // In a real app: Integrate with Stripe, Razorpay, Braintree, etc.
      // This would involve async calls, potentially showing a payment sheet/webview.
      await Future.delayed(
          const Duration(seconds: 2)); // Simulate network delay & processing

      // **** RANDOM SUCCESS/FAILURE FOR DEMO ****
      // In a real scenario, the payment gateway response determines success.
      bool simulatedSuccess = random.nextBool(); // 50/50 chance for demo
      // simulatedSuccess = true; // <-- Uncomment to force success for testing

      if (simulatedSuccess) {
        paymentSuccessful = true;
        // Generate a fake transaction ID
        paymentTransactionId =
            'sim_tx_${_selectedPaymentMethod.replaceAll(RegExp(r'[/ ]'), '_').toLowerCase()}_${uuid.v4().substring(0, 8)}';
        paymentStatusDetail =
            "Paid online via $_selectedPaymentMethod (ID: $paymentTransactionId)";
        debugPrint("Simulated Payment Successful: ID $paymentTransactionId");
      } else {
        paymentSuccessful = false;
        paymentTransactionId = null;
        paymentStatusDetail =
            "Online payment failed via $_selectedPaymentMethod";
        debugPrint("Simulated Payment Failed for $_selectedPaymentMethod");
      }
      // **** END OF SIMULATION ****
    } else {
      // Should not happen if UI is correct, but handle defensively
      debugPrint(
          "Error: Unknown payment method selected: $_selectedPaymentMethod");
      paymentSuccessful = false;
      paymentStatusDetail = "Unknown payment method error";
    }

    // Handle Payment Failure (Consolidated)
    if (!paymentSuccessful) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text('$paymentStatusDetail. Please try again or select COD.'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() {
          _isPlacingOrder = false;
        });
      }
      return; // Stop the process if payment failed
    }
    // --- End Payment Logic ---

    // 5. Proceed only if payment is considered successful
    final String orderId = uuid.v4(); // Generate unique order ID
    final List<Map<String, dynamic>> orderItemsList = []; // For JSONB column

    try {
      // 6. Prepare Order Items List & JSON
      for (var cartItem in cartProvider.items.values) {
        // Ensure product ID is a string (important for Supabase keys/joins)
        final String productId;
        if (cartItem.id is String) {
          productId = cartItem.id;
        } else {
          debugPrint(
              "Warning: CartItem ID is not a string: ${cartItem.id}. Converting...");
          productId = cartItem.id.toString();
        }

        if (cartItem.quantity <= 0) {
          // This should ideally be prevented by cart logic, but check again
          throw Exception(
              "Invalid quantity (0 or less) for product ${cartItem.name}");
        }

        orderItemsList.add({
          'product_id': productId,
          'product_name': cartItem.name,
          'quantity': cartItem.quantity,
          'price': cartItem.price, // Price per unit at time of order
          // Add 'image_url': cartItem.imageUrl, if needed for order history display
        });
      }
      final String orderItemsJson = jsonEncode(orderItemsList);

      // 7. Prepare Order Data Map for Supabase 'orders' table
      const double deliveryFee = 50.0; // Example fee - make dynamic if needed
      final double subtotal = cartProvider.totalPrice;
      final double totalAmount = subtotal + deliveryFee;

      final Map<String, dynamic> orderData = {
        'id': orderId, // Primary Key
        'user_id': currentUser.id, // Foreign Key to users
        // 'created_at': Let Supabase handle with default value 'now()'
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
        'payment_transaction_id':
            paymentTransactionId, // Add the transaction ID (can be null)
        'subtotal': subtotal,
        'delivery_fee': deliveryFee,
        'total_amount': totalAmount,
        'status':
            'Processing', // Initial status after successful placement/payment
        'order_items': orderItemsJson, // The JSON string/JSONB data
        // Add other fields as needed: discount, coupon_code, etc.
      };

      // 8. Insert Order into Supabase 'orders' table
      await supabase.from('orders').insert(orderData);
      debugPrint("Order $orderId inserted successfully into Supabase.");

      // ****** 9. Decrease Stock using RPC in a loop ******
      bool stockUpdateSuccess = true;
      List<String> failedStockUpdates = []; // Track which products failed

      for (var item in orderItemsList) {
        final productId = item['product_id'] as String;
        final quantity = item['quantity'] as int;

        // Skip if quantity is invalid (shouldn't happen based on earlier check)
        if (quantity <= 0) continue;

        debugPrint(
            "Attempting RPC decrease_stock: Product $productId, Quantity $quantity");
        try {
          // ** IMPORTANT: Ensure 'decrease_stock' function exists in Supabase **
          // This function should handle stock logic atomically (e.g., check if stock >= quantity before decreasing)
          await supabase.rpc(
            'decrease_stock',
            params: {
              'p_product_id': productId,
              'p_quantity_to_decrease': quantity,
            },
          );
          debugPrint("RPC decrease_stock succeeded for product $productId");
        } catch (e) {
          // Log the error, mark failure, and collect failed product ID
          stockUpdateSuccess = false;
          failedStockUpdates.add(productId); // Track which item failed
          debugPrint(
              "!!! RPC decrease_stock FAILED for product $productId: $e");
          // In Production: Log this error to a monitoring service (Sentry, etc.)
          // Consider the implications: Order is placed, but stock isn't updated. Requires intervention.
          // Sentry.captureException(e, stackTrace: stackTrace, hint: 'Failed to decrease stock for product $productId in order $orderId');
        }
      }
      // ****** End of Stock Decrease Loop ******

      // ****** 10. Finalize based on Stock Update Result ******
      if (!stockUpdateSuccess) {
        // Stock update failed for one or more items. Critical issue.
        debugPrint(
            "Stock update failed for products: ${failedStockUpdates.join(', ')} for order $orderId");
        // Attempt to update the order status to reflect the stock issue
        try {
          await supabase
              .from('orders')
              .update({'status': 'Failed - Stock Issue'}) // Use a clear status
              .eq('id', orderId);
          debugPrint(
              "Order $orderId status updated to 'Failed - Stock Issue'.");
        } catch (updateError) {
          // If even updating the status fails, log it as highly critical
          debugPrint(
              "CRITICAL ERROR: Failed to update order status for $orderId after stock decrease failure: $updateError");
          // Log this prominently - manual database correction might be needed.
        }

        // Notify the user, but DO NOT clear the cart.
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  'Order placed (ID: $orderId), but we encountered an issue updating stock levels. Please contact support.'),
              backgroundColor: Colors.orangeAccent,
              duration: const Duration(seconds: 10), // Longer duration
            ),
          );
          // Navigate back, potentially to the cart or order details page showing the error
          Navigator.of(context).pop(); // Go back from checkout
        }
        // Do NOT clear the cart here. User might need to retry or contact support.
      } else {
        // ALL GOOD: Stock updated successfully. Clear cart and show success.
        debugPrint("All stock updates successful for order $orderId.");
        if (mounted) {
          cartProvider.clearCart(); // Clear the cart only on full success
          _showOrderSuccessDialog(orderId); // Show the success confirmation
        }
      }
      // ****** End of Finalize Step ******
    } catch (error) {
      // 11. Error Handling for Order Insert or other critical issues during the process
      debugPrint(
          '!!! CRITICAL Error during order placement process (Order ID: $orderId): $error');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Error placing order: ${error.toString()}. Please try again.'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(10),
          ),
        );
      }
      // **** IMPORTANT: REFUND LOGIC ****
      // If an online payment was successful BUT the order insertion or stock update failed critically,
      // you MUST trigger a refund process here. This depends heavily on your payment gateway.
      if (_selectedPaymentMethod != 'Cash on Delivery' &&
          paymentTransactionId != null) {
        debugPrint(
            "!!! INITIATING REFUND PROCESS for failed order $orderId, TxID: $paymentTransactionId !!!");
        // refundPayment(paymentTransactionId, totalAmount); // Call your refund function
      }
      // Keep loading indicator false if error occurred before finally block
    } finally {
      // 12. Reset loading state regardless of success or failure, if mounted
      if (mounted) {
        setState(() {
          _isPlacingOrder = false;
        });
      }
    }
  }
  // --- End of Place Order Function ---

  // --- Displays the success dialog ---
  void _showOrderSuccessDialog(String orderId) {
    if (!mounted) return; // Don't show dialog if widget is disposed

    showDialog(
      context: context,
      barrierDismissible: false, // User must explicitly close
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
            SelectableText('Order ID: $orderId', // Make ID selectable
                style: TextStyle(color: Colors.grey[700], fontSize: 13)),
            const SizedBox(height: 4),
            Text('Payment Method: $_selectedPaymentMethod',
                style: TextStyle(color: Colors.grey[700], fontSize: 13)),
          ],
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop(); // Close dialog
              // Navigate back from checkout screen
              if (mounted) {
                Navigator.of(context).pop();
                // Consider navigating to 'My Orders' screen instead:
                // Navigator.of(context).pushReplacementNamed('/my-orders');
              }
            },
            child: const Text('CONTINUE SHOPPING'),
          ),
          // Optional: Button to go directly to order history
          // TextButton(
          //   onPressed: () {
          //     Navigator.of(ctx).pop(); // Close dialog
          //     if (mounted) {
          //        Navigator.of(context).pushReplacementNamed('/my-orders');
          //     }
          //   },
          //   child: const Text('VIEW MY ORDERS'),
          // ),
        ],
      ),
    );
  }

  // Add this widget to build the payment options section
  Widget _buildPaymentAndSummary() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Select Payment Method',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),

        // Payment Options
        _buildPaymentOption(
          title: 'Cash on Delivery',
          subtitle: 'Pay when you receive your order',
          icon: Icons.local_shipping_outlined,
          value: 'Cash on Delivery',
          isSelected: _selectedPaymentMethod == 'Cash on Delivery',
          onTap: () {
            if (mounted && !_isPlacingOrder) {
              setState(() => _selectedPaymentMethod = 'Cash on Delivery');
            }
          },
        ),
        const SizedBox(height: 12),

        _buildPaymentOption(
          title: 'Credit/Debit Card',
          subtitle: 'Pay securely online',
          icon: Icons.credit_card,
          value: 'Credit/Debit Card',
          isSelected: _selectedPaymentMethod == 'Credit/Debit Card',
          onTap: () {
            if (mounted && !_isPlacingOrder) {
              setState(() => _selectedPaymentMethod = 'Credit/Debit Card');
            }
          },
        ),
        const SizedBox(height: 12),

        _buildPaymentOption(
          title: 'UPI Payment',
          subtitle: 'Pay using your UPI app',
          icon: Icons.currency_rupee_rounded,
          value: 'UPI Payment',
          isSelected: _selectedPaymentMethod == 'UPI Payment',
          onTap: () {
            if (mounted && !_isPlacingOrder) {
              setState(() => _selectedPaymentMethod = 'UPI Payment');
            }
          },
        ),
      ],
    );
  }

  // Add this helper widget to build individual payment options
  Widget _buildPaymentOption({
    required String title,
    required String subtitle,
    required IconData icon,
    required String value,
    required bool isSelected,
    bool isDisabled = false,
    required VoidCallback onTap,
  }) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final Color effectiveColor = isDisabled ? Colors.grey.shade500 : colorScheme.onSurface;

    return Material(
      color: isDisabled
          ? Colors.grey.shade100
          : (isSelected
              ? colorScheme.primaryContainer.withOpacity(0.3)
              : colorScheme.surfaceVariant.withOpacity(0.2)),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: isDisabled ? null : onTap,
        borderRadius: BorderRadius.circular(12),
        splashColor: colorScheme.primary.withOpacity(0.1),
        highlightColor: colorScheme.primary.withOpacity(0.05),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDisabled
                  ? Colors.grey.shade300
                  : (isSelected
                      ? colorScheme.primary
                      : colorScheme.outlineVariant.withOpacity(0.5)),
              width: isSelected ? 1.5 : 1.0,
            ),
          ),
          child: Row(
            children: [
              Icon(icon,
                  color: isSelected
                      ? colorScheme.primary
                      : effectiveColor.withOpacity(0.8),
                  size: 24),
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
                        color: effectiveColor,
                      ),
                    ),
                    if (subtitle.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 13,
                          color: effectiveColor.withOpacity(0.7),
                        ),
                      ),
                    ]
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Radio<String>(
                value: value,
                groupValue: _selectedPaymentMethod,
                onChanged: isDisabled
                    ? null
                    : (String? newValue) {
                        if (newValue != null) {
                          onTap();
                        }
                      },
                activeColor: colorScheme.primary,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Checkout'),
      ),
      body: Consumer<CartProvider>(
        builder: (context, cartProvider, child) {
          if (cartProvider.items.isEmpty) {
            return const Center(
              child: Text('Your cart is empty'),
            );
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Text(
                'Delivery Address',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Card(
                child: InkWell(
                  onTap: () async {
                    final address = await Navigator.push<Address>(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CheckoutAddressScreen(
                          onAddressSelected: (address) {
                            setState(() {
                              selectedAddress = address;
                            });
                          },
                        ),
                      ),
                    );
                    if (address != null) {
                      setState(() {
                        selectedAddress = address;
                      });
                    }
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: selectedAddress == null
                        ? const Row(
                            children: [
                              Icon(Icons.add_location_alt_outlined),
                              SizedBox(width: 8),
                              Text('Select Delivery Address'),
                            ],
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                selectedAddress!.name,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(selectedAddress!.phone),
                              const SizedBox(height: 4),
                              Text(selectedAddress!.addressLine1),
                              if (selectedAddress!.addressLine2 != null) ...[
                                const SizedBox(height: 4),
                                Text(selectedAddress!.addressLine2!),
                              ],
                              const SizedBox(height: 4),
                              Text(
                                  '${selectedAddress!.city}, ${selectedAddress!.state} ${selectedAddress!.zipCode}'),
                            ],
                          ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Order Summary',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              ...cartProvider.items.values.map((item) {
                return ListTile(
                  leading: item.imageUrl != null
                      ? Image.network(
                          item.imageUrl!,
                          width: 50,
                          height: 50,
                          fit: BoxFit.cover,
                        )
                      : const Icon(Icons.image_not_supported),
                  title: Text(item.name),
                  subtitle: Text('Quantity: ${item.quantity}'),
                  trailing: Text(
                    'Rs.${(item.price * item.quantity).toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                );
              }).toList(),
              const Divider(),
              ListTile(
                title: const Text(
                  'Subtotal',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                trailing: Text(
                  'Rs.${cartProvider.totalPrice.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              ListTile(
                title: const Text(
                  'Delivery Fee',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                trailing: const Text(
                  'Rs.50.00',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              ListTile(
                title: const Text(
                  'Total',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                trailing: Text(
                  'Rs.${(cartProvider.totalPrice + 50.0).toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              _buildPaymentAndSummary(),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: selectedAddress == null
                    ? null
                    : () async {
                        try {
                          final orderId = uuid.v4();
                          final List<Map<String, dynamic>> orderItemsList = [];

                          for (var item in cartProvider.items.values) {
                            orderItemsList.add({
                              'product_id': item.id,
                              'product_name': item.name,
                              'quantity': item.quantity,
                              'price': item.price,
                            });
                          }

                          final orderData = {
                            'id': orderId,
                            'user_id': supabase.auth.currentUser!.id,
                            'shipping_name': selectedAddress!.name,
                            'shipping_phone': selectedAddress!.phone,
                            'shipping_address_line1': selectedAddress!.addressLine1,
                            'shipping_address_line2': selectedAddress!.addressLine2,
                            'shipping_city': selectedAddress!.city,
                            'shipping_state': selectedAddress!.state,
                            'shipping_zip_code': selectedAddress!.zipCode,
                            'payment_method': _selectedPaymentMethod,
                            'subtotal': cartProvider.totalPrice,
                            'delivery_fee': 50.0,
                            'total_amount': cartProvider.totalPrice + 50.0,
                            'status': 'Processing',
                            'order_items': jsonEncode(orderItemsList),
                          };

                          await supabase.from('orders').insert(orderData);
                          
                          // Update stock
                          for (var item in orderItemsList) {
                            await supabase.rpc(
                              'decrease_stock',
                              params: {
                                'p_product_id': item['product_id'],
                                'p_quantity_to_decrease': item['quantity'],
                              },
                            );
                          }

                          cartProvider.clearCart();
                          
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Order placed successfully!'),
                                backgroundColor: Colors.green,
                              ),
                            );
                            Navigator.pop(context);
                          }
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Error placing order: $e'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        }
                      },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text(
                  'Place Order',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
