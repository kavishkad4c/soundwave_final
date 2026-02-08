import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/product.dart';

class ProductApiService {
  static final ProductApiService _instance = ProductApiService._internal();
  factory ProductApiService() => _instance;
  ProductApiService._internal();

  // Premium Audio API (mocked high-end catalog for demo data)
  static const String premiumApiUrl = 'https://raw.githubusercontent.com/SoundWave-App/api/main/headphones.json';
  
  // Keys we store in SharedPreferences for caching
  static const String cacheKey = 'cached_products_v2'; // Versioned key to invalidate older cache
  static const String lastUpdateKey = 'last_update_time_v2';

  /// Fetch products from our curated "Premium Audio API" feed
  /// Since brand APIs (like Bose/Sony) are private, we use a curated source
  Future<List<Product>> fetchProductsFromApi() async {
    try {
      // In a real build, this might be: https://api.bose.com/v1/products
      // Here we fake a premium response with high-quality headphones/earbuds
      final response = await http.get(
        Uri.parse('https://fakestoreapi.com/products/category/electronics'),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final List<dynamic> jsonData = json.decode(response.body);
        
        // Keep the API shape, but convert items into premium audio gear
        // to keep the "Bose/Sony"-level quality you wanted
        final List<Product> premiumProducts = [
          _createPremiumProduct('bose_1', 'Bose QuietComfort Ultra', '\$429.00', '4.9', 'https://images.unsplash.com/photo-1546435770-a3e426bf472b?w=500&q=80', 'Bose', 'The ultimate noise cancelling experience.'),
          _createPremiumProduct('sony_2', 'Sony WH-1000XM5 Black', '\$398.00', '4.8', 'https://images.unsplash.com/photo-1618366712010-f4ae9c647dcb?w=500&q=80', 'Sony', 'Industry-leading noise cancellation.'),
          _createPremiumProduct('apple_3', 'AirPods Max - Sky Blue', '\$549.00', '4.7', 'https://images.unsplash.com/photo-1613040809024-b4ef7ba99bc3?w=500&q=80', 'Apple', 'High-fidelity audio with active noise cancellation.'),
          _createPremiumProduct('senn_4', 'Sennheiser Momentum 4', '\$349.95', '4.8', 'https://images.unsplash.com/photo-1487215078519-e21cc028cb29?w=500&q=80', 'Sennheiser', 'Audiophile-grade sound quality.'),
          _createPremiumProduct('bose_5', 'Bose QuietComfort Earbuds II', '\$299.00', '4.7', 'https://images.unsplash.com/photo-1590658268037-6bf12165a8df?w=500&q=80', 'Bose', 'The world\'s best noise cancellation in an earbud.'),
        ];

        // Blend in any genuinely relevant items from the API
        final apiAudio = jsonData.where((item) {
          final title = (item['title'] ?? '').toString().toLowerCase();
          return title.contains('headphone') || title.contains('audio');
        }).map((item) => _mapApiProductToModel(item)).toList();

        return [...premiumProducts, ...apiAudio];
      }
      return [];
    } catch (e) {
      print('Error fetching from Premium API: $e');
      return [];
    }
  }

  Product _createPremiumProduct(String id, String name, String price, String rating, String image, String brand, String desc) {
    return Product(
      id: id,
      name: name,
      price: price,
      rating: rating,
      image: image,
      brand: brand,
      description: desc,
      category: 'Premium Audio',
      inStock: true,
      reviews: 500 + (id.hashCode % 1000),
      features: ['Active Noise Cancellation', '30h Battery Life', 'Hi-Res Audio'],
    );
  }

  /// Translate the API product shape into our Product model
  Product _mapApiProductToModel(Map<String, dynamic> apiData) {
    return Product(
      id: apiData['id'].toString(),
      name: apiData['title'] ?? 'Unknown Product',
      price: '\$${apiData['price']?.toStringAsFixed(2) ?? '0.00'}',
      rating: apiData['rating']?['rate']?.toString() ?? '4.0',
      image: apiData['image'] ?? '',
      description: apiData['description'] ?? '',
      category: apiData['category'] ?? 'electronics',
      inStock: true,
      reviews: apiData['rating']?['count'] ?? 0,
      features: ['Premium Quality', 'Fast Shipping', 'Warranty Included'],
    );
  }

  /// Load products from local JSON as an offline fallback
  Future<List<Product>> loadProductsFromLocalJson() async {
    try {
      final String jsonString = await rootBundle.loadString('assets/data/products.json');
      final Map<String, dynamic> jsonData = json.decode(jsonString);
      final List<dynamic> productsJson = jsonData['products'];
      
      return productsJson.map((json) => Product.fromJson(json)).toList();
    } catch (e) {
      print('Error loading local JSON: $e');
      return [];
    }
  }

  /// Store products in SharedPreferences for caching
  Future<void> _cacheProducts(List<Product> products) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = json.encode(products.map((p) => p.toJson()).toList());
      await prefs.setString(cacheKey, jsonString);
      await prefs.setInt(lastUpdateKey, DateTime.now().millisecondsSinceEpoch);
    } catch (e) {
      print('Error caching products: $e');
    }
  }

  /// Read cached products from SharedPreferences
  Future<List<Product>> getCachedProducts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(cacheKey);
      
      if (jsonString != null) {
        final List<dynamic> jsonData = json.decode(jsonString);
        return jsonData.map((json) => Product.fromJson(json)).toList();
      }
    } catch (e) {
      print('Error getting cached products: $e');
    }
    return [];
  }

  /// Read the last cache update timestamp
  Future<DateTime?> getLastCacheUpdate() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final timestamp = prefs.getInt(lastUpdateKey);
      if (timestamp != null) {
        return DateTime.fromMillisecondsSinceEpoch(timestamp);
      }
    } catch (e) {
      print('Error getting cache time: $e');
    }
    return null;
  }

  /// Write products to local file storage
  Future<void> saveProductsToLocalFile(List<Product> products) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/saved_products.json');
      
      final jsonString = json.encode({
        'products': products.map((p) => p.toJson()).toList(),
        'savedAt': DateTime.now().toIso8601String(),
      });
      
      await file.writeAsString(jsonString);
      print('Products saved to: ${file.path}');
    } catch (e) {
      print('Error saving to file: $e');
      rethrow;
    }
  }

  /// Read products back from local file storage
  Future<List<Product>> readProductsFromLocalFile() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/saved_products.json');
      
      if (await file.exists()) {
        final jsonString = await file.readAsString();
        final Map<String, dynamic> jsonData = json.decode(jsonString);
        final List<dynamic> productsJson = jsonData['products'];
        
        return productsJson.map((json) => Product.fromJson(json)).toList();
      }
    } catch (e) {
      print('Error reading from file: $e');
    }
    return [];
  }

  /// Smart fetch: API first, then cache, then local JSON
  Future<List<Product>> fetchProducts({bool forceRefresh = false}) async {
    List<Product> finalProducts = [];

    // 1. Start with our curated local products
    finalProducts = await loadProductsFromLocalJson();

    // 2. Try to add more from the "Premium Audio API"
    if (forceRefresh || await _shouldRefreshCache()) {
      try {
        final apiProducts = await fetchProductsFromApi();
        if (apiProducts.isNotEmpty) {
          // Merge carefully to avoid duplicates
          final Map<String, Product> allProducts = {};
          for (var p in finalProducts) {
            allProducts[p.id] = p;
          }
          for (var p in apiProducts) {
            if (!allProducts.containsKey(p.id)) {
              allProducts[p.id] = p;
            }
          }
          finalProducts = allProducts.values.toList();
          
          // Only cache when we actually have data
          if (finalProducts.isNotEmpty) {
            await _cacheProducts(finalProducts);
          }
        }
      } catch (e) {
        print('Premium API failed: $e');
      }
    } else {
      // Use the cache when not forcing a refresh
      final cached = await getCachedProducts();
      if (cached.isNotEmpty) {
        finalProducts = cached;
      }
    }

    // 3. Last-resort safety net: if we are still empty,
    // reload local JSON one last time to avoid empty screens
    if (finalProducts.isEmpty) {
      finalProducts = await loadProductsFromLocalJson();
    }

    return finalProducts;
  }

  /// Decide if the cache is stale (older than 1 hour)
  Future<bool> _shouldRefreshCache() async {
    final lastUpdate = await getLastCacheUpdate();
    if (lastUpdate == null) return true;
    
    final difference = DateTime.now().difference(lastUpdate);
    return difference.inHours >= 1;
  }

  /// Fetch a JSON file from a URL
  Future<Map<String, dynamic>> fetchExternalJson(String url) async {
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      throw Exception('Failed to load JSON: ${response.statusCode}');
    } catch (e) {
      print('Error fetching external JSON: $e');
      rethrow;
    }
  }

  /// Save user preferences/settings locally
  Future<void> saveUserPreference(String key, String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, value);
  }

  /// Read user preferences/settings back
  Future<String?> readUserPreference(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(key);
  }

  /// Clear out all cached data
  Future<void> clearCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(cacheKey);
    await prefs.remove(lastUpdateKey);
  }
}

