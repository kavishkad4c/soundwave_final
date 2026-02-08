import 'package:flutter/foundation.dart';
import '../models/product.dart';
import '../models/cart_item.dart';

class AppState extends ChangeNotifier {
  // Favorite items
  final List<Product> _favorites = [];

  List<Product> get favorites => _favorites;

  bool isFavorite(String productId) {
    return _favorites.any((product) => product.id == productId);
  }

  void toggleFavorite(Product product) {
    if (isFavorite(product.id)) {
      _favorites.removeWhere((p) => p.id == product.id);
    } else {
      _favorites.add(product);
    }
    notifyListeners();
  }

  void addToFavorites(Product product) {
    if (!isFavorite(product.id)) {
      _favorites.add(product);
      notifyListeners();
    }
  }

  void removeFromFavorites(String productId) {
    _favorites.removeWhere((product) => product.id == productId);
    notifyListeners();
  }

  // Cart items
  final List<CartItem> _cartItems = [];

  List<CartItem> get cartItems => _cartItems;

  int get cartItemCount => _cartItems.fold(0, (sum, item) => sum + item.quantity);

  double get cartSubtotal {
    return _cartItems.fold(0.0, (sum, item) => sum + item.totalPrice);
  }

  double get cartShipping => _cartItems.isEmpty ? 0.0 : 9.99;

  double get cartTotal => cartSubtotal + cartShipping;

  bool isInCart(String productId) {
    return _cartItems.any((item) => item.id == productId);
  }

  void addToCart(Product product) {
    final existingIndex = _cartItems.indexWhere((item) => item.id == product.id);
    
    if (existingIndex >= 0) {
      _cartItems[existingIndex].quantity++;
    } else {
      _cartItems.add(CartItem(
        id: product.id,
        name: product.name,
        price: product.price,
        image: product.image,
        quantity: 1,
      ));
    }
    notifyListeners();
  }

  void removeFromCart(String productId) {
    _cartItems.removeWhere((item) => item.id == productId);
    notifyListeners();
  }

  void updateCartItemQuantity(String productId, int quantity) {
    if (quantity <= 0) {
      removeFromCart(productId);
      return;
    }

    final index = _cartItems.indexWhere((item) => item.id == productId);
    if (index >= 0) {
      _cartItems[index].quantity = quantity;
      notifyListeners();
    }
  }

  void incrementCartItem(String productId) {
    final index = _cartItems.indexWhere((item) => item.id == productId);
    if (index >= 0) {
      _cartItems[index].quantity++;
      notifyListeners();
    }
  }

  void decrementCartItem(String productId) {
    final index = _cartItems.indexWhere((item) => item.id == productId);
    if (index >= 0) {
      if (_cartItems[index].quantity > 1) {
        _cartItems[index].quantity--;
      } else {
        removeFromCart(productId);
      }
      notifyListeners();
    }
  }

  void clearCart() {
    _cartItems.clear();
    notifyListeners();
  }
}

