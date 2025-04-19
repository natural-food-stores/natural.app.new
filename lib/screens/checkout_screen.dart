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

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({Key? key}) : super(key: key);

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
  String _selectedPaymentMethod = 'Cash on Delivery'; // Default selection

  // Loading state for placing order
  bool _isPlacingOrder = false;

  // Supabase client and UUID generator
  final supabase = Supabase.instance.client;
  final uuid = const Uuid();
  final random = Random(); // For payment simulation

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
  void _saveAddress() {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please fill all required address fields.')),
      );
      return;
    }

    final addressProvider =
        Provider.of<AddressProvider>(context, listen: false);
    final currentUser = supabase.auth.currentUser; // Get current user

    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('You must be logged in to save an address.')),
      );
      return;
    }

    // Create the Address object - Use Uuid for ID and fetch userId
    final newAddress = Address(
      id: uuid.v4(), // Generate a new unique ID for this address
      userId: currentUser.id, // Assign the logged-in user's ID
      name: _nameController.text,
      phone: _phoneController.text,
      addressLine1: _addressLine1Controller.text,
      addressLine2: _addressLine2Controller.text.isEmpty
          ? null
          : _addressLine2Controller.text,
      city: _cityController.text,
      state: _stateController.text,
      zipCode: _zipCodeController.text,
      // Let AddressProvider handle setting the default status logic internally.
      // Setting isDefault: true here might be desired, or you could add a checkbox.
      // For now, let's assume saving always tries to make it default if none exists.
      isDefault: true, // Let the provider logic handle conflicts
    );

    // Use a try-catch block for the async operation
    try {
      // Call the provider's addAddress method
      addressProvider.addAddress(newAddress).then((_) {
        // Check if mounted before showing SnackBar
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Address saved successfully'),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              margin: const EdgeInsets.all(10),
            ),
          );
        }
      }).catchError((error) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to save address: $error')),
          );
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('An error occurred while saving address: $e')),
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
      const double deliveryFee = 100.0; // Example fee - make dynamic if needed
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

  // --- Builds the main Stepper UI ---
  @override
  Widget build(BuildContext context) {
    // Listen to cart provider to react to changes (e.g., cart becomes empty)
    final cartProvider = Provider.of<CartProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Checkout'),
        elevation: 1,
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor ??
            Theme.of(context).colorScheme.surface,
      ),
      body: cartProvider.itemCount == 0 // Use itemCount getter for efficiency
          ? _buildEmptyCart() // Show empty cart message
          : Stepper(
              type: StepperType.vertical, // Or StepperType.horizontal
              currentStep: _currentStep,
              physics:
                  const ClampingScrollPhysics(), // Good for nested scrolling
              onStepContinue: _isPlacingOrder
                  ? null
                  : _handleStepContinue, // Disable while loading
              onStepCancel: _isPlacingOrder
                  ? null
                  : _handleStepCancel, // Disable while loading
              // Custom Controls Builder for better button layout & loading indicator
              controlsBuilder: (context, details) {
                final bool isLastStep =
                    _currentStep == 1; // Steps are 0 (Address), 1 (Payment)

                return Padding(
                  padding: const EdgeInsets.only(top: 24.0, bottom: 8.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          // Use the provided details.onStepContinue which maps to our _handleStepContinue
                          onPressed: details.onStepContinue,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8)),
                            backgroundColor:
                                Theme.of(context).colorScheme.primary,
                            foregroundColor:
                                Theme.of(context).colorScheme.onPrimary,
                          ),
                          child: (_isPlacingOrder && isLastStep)
                              ? const SizedBox(
                                  // Show loader inside button on last step
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2.5, color: Colors.white),
                                )
                              : Text(isLastStep ? 'PLACE ORDER' : 'CONTINUE'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Show Cancel/Back button only if not loading
                      if (!_isPlacingOrder)
                        Expanded(
                          child: OutlinedButton(
                            onPressed: details
                                .onStepCancel, // Uses our _handleStepCancel
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8)),
                              side: BorderSide(
                                  color: Theme.of(context).colorScheme.outline),
                            ),
                            child: Text(_currentStep == 0
                                ? 'CANCEL'
                                : 'BACK TO ADDRESS'),
                          ),
                        ),
                    ],
                  ),
                );
              },
              steps: [
                Step(
                  title: const Text('Shipping Address'),
                  content: _buildAddressForm(),
                  isActive: _currentStep >= 0,
                  // Mark as complete if we moved past this step
                  state:
                      _currentStep > 0 ? StepState.complete : StepState.indexed,
                ),
                Step(
                  title: const Text('Payment & Summary'),
                  content: _buildPaymentAndSummary(), // Combined widget
                  isActive: _currentStep >= 1,
                  // State can be editing or indexed based on current step
                  state:
                      _currentStep >= 1 ? StepState.editing : StepState.indexed,
                ),
              ],
            ),
    );
  }

  // Handles Stepper Continue logic
  void _handleStepContinue() {
    if (_currentStep == 0) {
      // Moving from Address to Payment
      if (_formKey.currentState!.validate()) {
        // Address form is valid, move to the next step
        if (mounted) {
          setState(() => _currentStep += 1);
        }
      } else {
        // Address form has errors
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Please fix the errors in the address form.')),
        );
      }
    } else if (_currentStep == 1) {
      // On the Payment step, 'Continue' means Place Order
      _placeOrder(); // Trigger the order placement process
    }
  }

  // Handles Stepper Cancel/Back logic
  void _handleStepCancel() {
    if (_currentStep > 0) {
      // Go back from Payment step to Address step
      if (mounted) {
        setState(() => _currentStep -= 1);
      }
    } else {
      // On the first step (Address), 'Cancel' leaves the checkout screen
      Navigator.of(context).pop();
    }
  }

  // --- Builds the UI for an empty cart ---
  Widget _buildEmptyCart() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.shopping_cart_checkout_rounded,
                size: 80, color: Colors.grey[400]),
            const SizedBox(height: 24),
            Text('Your Cart is Empty',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      // Adjusted style
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                textAlign: TextAlign.center),
            const SizedBox(height: 12),
            Text(
                'Looks like you haven\'t added anything yet. Start shopping to proceed to checkout!',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      // Adjusted style
                      color: Colors.grey[600],
                      height: 1.5,
                    ),
                textAlign: TextAlign.center),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).pop(); // Go back
              },
              icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 16),
              label: const Text('BACK TO SHOP'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  // --- Builds the Address Form ---
  Widget _buildAddressForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextFormField(
            controller: _nameController,
            decoration: _inputDecoration(
                labelText: 'Full Name', icon: Icons.person_outline),
            textCapitalization: TextCapitalization.words,
            validator: (value) => (value == null || value.trim().isEmpty)
                ? 'Please enter your name'
                : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _phoneController,
            decoration: _inputDecoration(
                labelText: 'Phone Number', icon: Icons.phone_outlined),
            keyboardType: TextInputType.phone,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(
                  10) // Adjust length as needed for your region
            ],
            validator: (value) {
              if (value == null || value.isEmpty)
                return 'Please enter phone number';
              if (value.length < 10)
                return 'Enter a valid 10-digit number'; // Adjust validation
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _addressLine1Controller,
            decoration: _inputDecoration(
                labelText: 'Address Line 1 (House No, Building, Street)',
                icon: Icons.home_outlined),
            textCapitalization: TextCapitalization.sentences,
            maxLines: null, // Allows multiple lines if needed
            validator: (value) => (value == null || value.trim().isEmpty)
                ? 'Please enter your address'
                : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _addressLine2Controller,
            decoration: _inputDecoration(
                labelText: 'Address Line 2 (Area, Landmark - Optional)',
                icon: Icons.apartment_outlined),
            textCapitalization: TextCapitalization.sentences,
            maxLines: null,
            // No validator needed for optional field
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _cityController,
            decoration: _inputDecoration(
                labelText: 'City', icon: Icons.location_city_outlined),
            textCapitalization: TextCapitalization.words,
            validator: (value) => (value == null || value.trim().isEmpty)
                ? 'Please enter your city'
                : null,
          ),
          const SizedBox(height: 16),
          Row(
            // State and Zip side-by-side
            children: [
              Expanded(
                child: TextFormField(
                  controller: _stateController,
                  decoration: _inputDecoration(
                      labelText: 'State', icon: Icons.map_outlined),
                  textCapitalization: TextCapitalization.words,
                  validator: (value) => (value == null || value.trim().isEmpty)
                      ? 'Enter state'
                      : null,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                    controller: _zipCodeController,
                    decoration: _inputDecoration(
                        labelText: 'ZIP / Pincode',
                        icon: Icons.pin_drop_outlined),
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(
                          6) // Common length for India
                    ],
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Enter ZIP';
                      if (value.length != 6)
                        return 'Enter a valid 6-digit ZIP'; // Adjust if needed
                      return null;
                    }),
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Save Address Button - Allows users to save the entered address
          // without necessarily placing the order immediately.
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _saveAddress,
              icon: const Icon(Icons.save_alt_rounded, size: 18),
              label: const Text('SAVE THIS ADDRESS FOR LATER'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.primary,
                side: BorderSide(
                    color:
                        Theme.of(context).colorScheme.primary.withOpacity(0.5)),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),
          const SizedBox(
              height: 16), // Add space before the end of the step content
        ],
      ),
    );
  }

  // Helper for consistent Input Decoration styling
  InputDecoration _inputDecoration(
      {required String labelText, required IconData icon}) {
    return InputDecoration(
      labelText: labelText,
      prefixIcon: Icon(icon, size: 20),
      border: const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(8)),
      ),
      enabledBorder: OutlineInputBorder(
          borderRadius: const BorderRadius.all(Radius.circular(8)),
          borderSide: BorderSide(color: Colors.grey.shade400)),
      focusedBorder: OutlineInputBorder(
          borderRadius: const BorderRadius.all(Radius.circular(8)),
          borderSide: BorderSide(
              color: Theme.of(context).colorScheme.primary, width: 1.5)),
      errorBorder: OutlineInputBorder(
          // Style for error state
          borderRadius: const BorderRadius.all(Radius.circular(8)),
          borderSide: BorderSide(
              color: Theme.of(context).colorScheme.error, width: 1.5)),
      focusedErrorBorder: OutlineInputBorder(
          // Style for error state when focused
          borderRadius: const BorderRadius.all(Radius.circular(8)),
          borderSide: BorderSide(
              color: Theme.of(context).colorScheme.error, width: 2.0)),
      contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
      // isDense: true, // Can make field slightly more compact if needed
    );
  }

  // --- Builds the combined Payment Method Selection and Order Summary UI ---
  Widget _buildPaymentAndSummary() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildOrderSummary(), // Shows Subtotal, Delivery, Total
        const SizedBox(height: 24),
        const Text('Select Payment Method',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),

        // --- Payment Options ---
        _buildPaymentOption(
          title: 'Cash on Delivery',
          subtitle: 'Pay when you receive your order',
          icon: Icons.local_shipping_outlined, // More relevant icon
          value: 'Cash on Delivery',
          isSelected: _selectedPaymentMethod == 'Cash on Delivery',
          onTap: () {
            if (mounted && !_isPlacingOrder) {
              // Prevent changing while placing order
              setState(() => _selectedPaymentMethod = 'Cash on Delivery');
            }
          },
        ),
        const SizedBox(height: 12),

        _buildPaymentOption(
          title: 'Credit/Debit Card',
          subtitle: 'Pay securely online (Simulated)', // Indicate simulation
          icon: Icons.credit_card,
          value: 'Credit/Debit Card',
          isSelected: _selectedPaymentMethod == 'Credit/Debit Card',
          // isDisabled: true, // <-- REMOVED: Enable the option
          onTap: () {
            if (mounted && !_isPlacingOrder) {
              setState(() => _selectedPaymentMethod = 'Credit/Debit Card');
            }
            // Removed the "unavailable" snackbar
          },
        ),
        const SizedBox(height: 12),

        _buildPaymentOption(
          title: 'UPI Payment',
          subtitle: 'Pay using your UPI app (Simulated)', // Indicate simulation
          icon: Icons.currency_rupee_rounded, // Alternative UPI icon
          value: 'UPI Payment',
          isSelected: _selectedPaymentMethod == 'UPI Payment',
          // isDisabled: true, // <-- REMOVED: Enable the option
          onTap: () {
            if (mounted && !_isPlacingOrder) {
              setState(() => _selectedPaymentMethod = 'UPI Payment');
            }
            // Removed the "unavailable" snackbar
          },
        ),
        const SizedBox(
            height: 16), // Add space before the end of the step content
        // Add more payment options here if needed
      ],
    );
  }

  // --- Builds a single Payment Option Tile ---
  Widget _buildPaymentOption({
    required String title,
    required String subtitle,
    required IconData icon,
    required String value, // Unique value for this option
    required bool isSelected,
    bool isDisabled = false, // Keep for potential future use
    required VoidCallback onTap,
  }) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final Color effectiveColor =
        isDisabled ? Colors.grey.shade500 : colorScheme.onSurface;

    return Material(
      color: isDisabled
          ? Colors.grey.shade100 // Disabled background
          : (isSelected
              ? colorScheme.primaryContainer
                  .withOpacity(0.3) // Selected background
              : colorScheme.surfaceVariant
                  .withOpacity(0.2)), // Default background
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: isDisabled ? null : onTap, // Disable tap if needed
        borderRadius: BorderRadius.circular(12),
        splashColor: colorScheme.primary.withOpacity(0.1),
        highlightColor: colorScheme.primary.withOpacity(0.05),
        child: Container(
          padding: const EdgeInsets.symmetric(
              horizontal: 16, vertical: 14), // Adjusted padding
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDisabled
                  ? Colors.grey.shade300
                  : (isSelected
                      ? colorScheme.primary // Selected border
                      : colorScheme.outlineVariant
                          .withOpacity(0.5)), // Default border
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
                        fontWeight: FontWeight.w600, // Slightly bolder title
                        color: effectiveColor,
                      ),
                    ),
                    if (subtitle.isNotEmpty) ...[
                      // Show subtitle only if provided
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 13,
                          color: effectiveColor
                              .withOpacity(0.7), // Softer subtitle color
                        ),
                      ),
                    ]
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Radio button for selection indication
              Radio<String>(
                value: value, // Use the unique value
                groupValue: _selectedPaymentMethod, // Bind to state variable
                onChanged: isDisabled
                    ? null
                    : (String? newValue) {
                        if (newValue != null) {
                          onTap(); // Call the onTap which handles setState
                        }
                      },
                activeColor: colorScheme.primary,
                materialTapTargetSize:
                    MaterialTapTargetSize.shrinkWrap, // Compact tap area
                visualDensity:
                    VisualDensity.compact, // Make radio slightly smaller
              ),
              // Optional: Show lock icon if disabled
              // if (isDisabled)
              //   Padding(
              //     padding: const EdgeInsets.only(right: 8.0),
              //     child: Icon(Icons.lock_outline_rounded,
              //         color: Colors.grey.shade400, size: 20),
              //   ),
            ],
          ),
        ),
      ),
    );
  }

  // --- Builds the Order Summary Box ---
  Widget _buildOrderSummary() {
    // Use listen: true here if summary needs to update live (e.g., coupon applied)
    // If only read once when building the step, listen: false is fine.
    // For simplicity, using listen: true is safer if cart changes are possible.
    final cartProvider = Provider.of<CartProvider>(context);

    // Example delivery fee logic (make this more sophisticated if needed)
    final double deliveryFee = cartProvider.totalPrice > 0 ? 100.0 : 0.0;
    final double totalWithDelivery = cartProvider.totalPrice + deliveryFee;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color:
                Theme.of(context).colorScheme.outlineVariant.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Order Summary',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          _buildSummaryRow(
            label:
                'Subtotal (${cartProvider.totalItemsCount} ${cartProvider.totalItemsCount == 1 ? "item" : "items"})',
            value: 'Rs.${cartProvider.totalPrice.toStringAsFixed(2)}',
          ),
          const SizedBox(height: 8),
          _buildSummaryRow(
            label: 'Delivery Fee',
            value: deliveryFee > 0
                ? 'Rs.${deliveryFee.toStringAsFixed(2)}'
                : 'Free',
            valueColor: deliveryFee > 0
                ? null
                : Colors.green.shade700, // Highlight 'Free'
          ),
          const Padding(
              padding: EdgeInsets.symmetric(vertical: 12), child: Divider()),
          _buildSummaryRow(
            label: 'Total Amount',
            value: 'Rs.${totalWithDelivery.toStringAsFixed(2)}',
            isTotal: true, // Make total stand out
          ),
        ],
      ),
    );
  }

  // Helper widget for styling order summary rows
  Widget _buildSummaryRow(
      {required String label,
      required String value,
      Color? valueColor,
      bool isTotal = false}) {
    final textTheme = Theme.of(context).textTheme;
    final labelStyle = isTotal
        ? textTheme.titleMedium
            ?.copyWith(fontWeight: FontWeight.bold) // Bolder total label
        : textTheme.bodyMedium?.copyWith(color: Colors.grey[700]);
    final valueStyle = isTotal
        ? textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold, // Bolder total value
            color: valueColor ?? Theme.of(context).colorScheme.primary)
        : textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: valueColor); // Slightly bolder regular value

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: labelStyle),
        Text(value, style: valueStyle),
      ],
    );
  }
} // End of _CheckoutScreenState
