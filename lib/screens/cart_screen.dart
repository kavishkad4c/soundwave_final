 import 'package:flutter/material.dart';
 import 'package:provider/provider.dart';
 import '../models/app_state.dart';
 import '../services/device_service.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, appState, child) {
        final cartItems = appState.cartItems;
        final subtotal = appState.cartSubtotal;
        final shipping = appState.cartShipping;
        final total = appState.cartTotal;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Shopping Cart'),
          ),
          body: Column(
            children: [
              Expanded(
                child: cartItems.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.shopping_cart_outlined, size: 80, color: Colors.grey),
                            SizedBox(height: 16),
                            Text(
                              'Your cart is empty',
                              style: TextStyle(fontSize: 18, color: Colors.grey),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: cartItems.length,
                        itemBuilder: (context, index) {
                          return _buildCartItem(context, cartItems[index], appState);
                        },
                      ),
              ),

              // Checkout summary and action
              if (cartItems.isNotEmpty) _buildCheckoutSection(context, subtotal, shipping, total),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCartItem(BuildContext context, cartItem, AppState appState) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: ListTile(
        leading: Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: cartItem.image.startsWith('http')
                ? Image.network(
                    cartItem.image,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Center(
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          value: loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded /
                                  loadingProgress.expectedTotalBytes!
                              : null,
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.grey[200],
                        child: const Icon(Icons.headphones, color: Colors.grey),
                      );
                    },
                  )
                : Image.asset(
                    cartItem.image,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.grey[200],
                        child: const Icon(Icons.headphones, color: Colors.grey),
                      );
                    },
                  ),
          ),
        ),
        title: Text(
          cartItem.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(cartItem.price),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.remove_circle_outline),
              onPressed: () {
                DeviceService().vibrateLight();
                appState.decrementCartItem(cartItem.id);
              },
            ),
            Text('${cartItem.quantity}'),
            IconButton(
              icon: const Icon(Icons.add_circle_outline),
              onPressed: () {
                DeviceService().vibrateLight();
                appState.incrementCartItem(cartItem.id);
              },
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              onPressed: () async {
                await DeviceService().vibrateMedium();
                appState.removeFromCart(cartItem.id);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${cartItem.name} removed from cart'),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCheckoutSection(BuildContext context, double subtotal, double shipping, double total) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        children: [
          _buildPriceRow('Subtotal', '\$$subtotal'),
          _buildPriceRow('Shipping', '\$$shipping'),
          const SizedBox(height: 8),
          _buildPriceRow(
            'Total',
            '\$$total',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const CheckoutFormScreen()),
                );
              },
              child: const Text(
                'Proceed to Checkout',
                style: TextStyle(fontSize: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceRow(String label, String value, {TextStyle? style}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label),
        Text(value, style: style),
      ],
    );
  }
}

// Checkout form screen (leave this intact)
class CheckoutFormScreen extends StatefulWidget {
  const CheckoutFormScreen({super.key});

  @override
  _CheckoutFormScreenState createState() => _CheckoutFormScreenState();
}

class _CheckoutFormScreenState extends State<CheckoutFormScreen> {
  final _formKey = GlobalKey<FormState>();
  String _paymentMethod = 'credit_card';
  String _cardNumber = '';
  String _expiryDate = '';
  String _cvv = '';
  String _cardHolder = '';
  String _email = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Checkout'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Contact details
              _buildSectionTitle('Contact Information'),
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Email Address',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.email),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your email';
                  }
                  return null;
                },
                onSaved: (value) => _email = value!,
              ),
              const SizedBox(height: 20),

              // Choose a payment method
              _buildSectionTitle('Payment Method'),
              _buildPaymentMethodOption('Credit/Debit Card', 'credit_card'),
              _buildPaymentMethodOption('PayPal', 'paypal'),
              _buildPaymentMethodOption('Google Pay', 'google_pay'),
              const SizedBox(height: 20),

              // Card details (only when card is selected)
              if (_paymentMethod == 'credit_card') ...[
                _buildSectionTitle('Card Details'),
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Card Number',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.credit_card),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter card number';
                    }
                    if (value.length < 16) {
                      return 'Please enter valid card number';
                    }
                    return null;
                  },
                  onSaved: (value) => _cardNumber = value!,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        decoration: const InputDecoration(
                          labelText: 'Expiry Date',
                          border: OutlineInputBorder(),
                          hintText: 'MM/YY',
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter expiry date';
                          }
                          return null;
                        },
                        onSaved: (value) => _expiryDate = value!,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        decoration: const InputDecoration(
                          labelText: 'CVV',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter CVV';
                          }
                          if (value.length < 3) {
                            return 'Please enter valid CVV';
                          }
                          return null;
                        },
                        onSaved: (value) => _cvv = value!,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Cardholder Name',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter cardholder name';
                    }
                    return null;
                  },
                  onSaved: (value) => _cardHolder = value!,
                ),
                const SizedBox(height: 20),
              ],

              // Order summary
              _buildSectionTitle('Order Summary'),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _buildOrderRow('Subtotal', '\$299.98'),
                      _buildOrderRow('Shipping', '\$9.99'),
                      _buildOrderRow('Tax', '\$25.00'),
                      const Divider(),
                      _buildOrderRow(
                        'Total',
                        '\$334.97',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 30),

              // Pay now action
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      _formKey.currentState!.save();
                      _processPayment(context);
                    }
                  },
                  child: const Text(
                    'Pay Now',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildPaymentMethodOption(String title, String value) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: RadioListTile(
        title: Text(title),
        value: value,
        groupValue: _paymentMethod,
        onChanged: (newValue) {
          setState(() {
            _paymentMethod = newValue!;
          });
        },
      ),
    );
  }

  Widget _buildOrderRow(String label, String value, {TextStyle? style}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(value, style: style),
        ],
      ),
    );
  }

  void _processPayment(BuildContext context) {
    // Show a loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Processing payment...'),
          ],
        ),
      ),
    );

    // Simulate payment processing time
    Future.delayed(const Duration(seconds: 2), () {
      Navigator.pop(context); // Dismiss the loading dialog
      _showSuccessDialog(context);
    });
  }

  void _showSuccessDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green),
            SizedBox(width: 8),
            Text('Payment Successful'),
          ],
        ),
        content: const Text('Your order has been placed successfully! You will receive a confirmation email shortly.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.popUntil(context, (route) => route.isFirst);
            },
            child: const Text('Continue Shopping'),
          ),
        ],
      ),
    );
  }
}
