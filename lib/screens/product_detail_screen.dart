import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sensors_plus/sensors_plus.dart';
import '../models/app_state.dart';
import '../models/product.dart';
import '../services/device_service.dart';
import 'cart_screen.dart';

class ProductDetailScreen extends StatefulWidget {
  final Map<String, dynamic> product;

  const ProductDetailScreen({super.key, required this.product});

  @override
  _ProductDetailScreenState createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  StreamSubscription<AccelerometerEvent>? _accelerometerSubscription;
  DateTime _lastShakeAt = DateTime.fromMillisecondsSinceEpoch(0);
  bool _discountUnlocked = false;
  final String _discountText = 'Shake Deal: 10% off accessories today!';
  static const double _shakeThresholdG = 2.7;
  static const int _shakeCooldownMs = 900;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );
    _animationController.forward();

    _accelerometerSubscription = accelerometerEvents.listen(_handleAccelerometerEvent);
  }

  @override
  void dispose() {
    _accelerometerSubscription?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  void _handleAccelerometerEvent(AccelerometerEvent event) {
    final double gX = event.x / 9.81;
    final double gY = event.y / 9.81;
    final double gZ = event.z / 9.81;
    final double gForce = math.sqrt(gX * gX + gY * gY + gZ * gZ);
    final now = DateTime.now();

    if (gForce > _shakeThresholdG &&
        now.difference(_lastShakeAt).inMilliseconds > _shakeCooldownMs) {
      _lastShakeAt = now;
      _unlockDiscount();
    }
  }

  void _unlockDiscount() {
    if (_discountUnlocked) return;
    if (!mounted) return;
    setState(() {
      _discountUnlocked = true;
    });
    DeviceService().vibrateMedium();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Discount unlocked! Check the deal below.'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final productObj = Product.fromMap(widget.product);
    final isFavorite = appState.isFavorite(productObj.id);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Product Details'),
        actions: [
          IconButton(
            icon: Icon(
              isFavorite ? Icons.favorite : Icons.favorite_border,
              color: isFavorite ? Colors.red : null,
            ),
            onPressed: () {
              DeviceService().vibrateLight();
              appState.toggleFavorite(productObj);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    isFavorite
                        ? '${widget.product['name']} removed from favorites'
                        : '${widget.product['name']} added to favorites! ❤️',
                  ),
                  duration: const Duration(seconds: 2),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Sharing product...')),
              );
            },
          ),
        ],
      ),
      body: ScaleTransition(
        scale: _scaleAnimation,
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Product image
              Container(
                height: 300,
                width: double.infinity,
                color: Colors.grey[200],
                child: widget.product['image']!.startsWith('http')
                    ? Image.network(
                        widget.product['image']!,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Center(
                            child: CircularProgressIndicator(
                              value: loadingProgress.expectedTotalBytes != null
                                  ? loadingProgress.cumulativeBytesLoaded /
                                      loadingProgress.expectedTotalBytes!
                                  : null,
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          return const Center(
                            child: Icon(Icons.headphones, size: 100, color: Colors.grey),
                          );
                        },
                      )
                    : Image.asset(
                        widget.product['image']!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return const Center(
                            child: Icon(Icons.headphones, size: 100, color: Colors.grey),
                          );
                        },
                      ),
              ),

              // Product details
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.product['name']!,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.product['price']!,
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                    ),
                    const SizedBox(height: 12),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _discountUnlocked ? Colors.green[50] : Colors.grey[200],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _discountUnlocked ? Colors.green : Colors.grey.shade400,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _discountUnlocked ? Icons.local_offer : Icons.sensors,
                            color: _discountUnlocked ? Colors.green : Colors.grey[700],
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _discountUnlocked
                                  ? _discountText
                                  : 'Shake your phone to unlock a discount!',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: _discountUnlocked ? Colors.green[800] : Colors.grey[800],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: const [
                        Icon(Icons.star, color: Colors.amber, size: 20),
                        Icon(Icons.star, color: Colors.amber, size: 20),
                        Icon(Icons.star, color: Colors.amber, size: 20),
                        Icon(Icons.star, color: Colors.amber, size: 20),
                        Icon(Icons.star_half, color: Colors.amber, size: 20),
                        SizedBox(width: 8),
                        Text('4.5 (128 reviews)'),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Description
                    Text(
                      'Description',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Experience premium sound quality with our latest wireless earbuds. '
                      'Featuring noise cancellation, 24-hour battery life, and comfortable fit '
                      'for all-day wear.',
                      style: TextStyle(fontSize: 16, height: 1.5),
                    ),
                    const SizedBox(height: 20),

                    // Features
                    Text(
                      'Features',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 8),
                    _buildFeatureItem('Noise Cancellation'),
                    _buildFeatureItem('24h Battery Life'),
                    _buildFeatureItem('Wireless Charging'),
                    _buildFeatureItem('Water Resistant'),
                    const SizedBox(height: 30),

                    // Add to cart button with animation
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 500),
                      curve: Curves.easeInOut,
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: () async {
                          // Play a bounce animation when adding to cart
                          _animationController.reset();
                          _animationController.forward();
                          
                          await DeviceService().vibrateSuccess();
                          appState.addToCart(productObj);
                          
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('${widget.product['name']} added to cart'),
                                action: SnackBarAction(
                                  label: 'View Cart',
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (context) => const CartScreen()),
                                    );
                                  },
                                ),
                              ),
                            );
                          }
                        },
                        child: const Text(
                          'Add to Cart',
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureItem(String feature) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: Colors.green, size: 20),
          const SizedBox(width: 8),
          Text(feature),
        ],
      ),
    );
  }
}

