import 'package:flutter/material.dart';
import '../services/product_api_service.dart';
import '../models/product.dart';

class DataDemoScreen extends StatefulWidget {
  const DataDemoScreen({super.key});

  @override
  State<DataDemoScreen> createState() => _DataDemoScreenState();
}

class _DataDemoScreenState extends State<DataDemoScreen> {
  final ProductApiService _apiService = ProductApiService();
  String _status = 'Ready';
  List<Product> _products = [];
  DateTime? _lastUpdate;

  @override
  void initState() {
    super.initState();
    _loadLastUpdate();
  }

  Future<void> _loadLastUpdate() async {
    final lastUpdate = await _apiService.getLastCacheUpdate();
    setState(() {
      _lastUpdate = lastUpdate;
    });
  }

  Future<void> _fetchFromAPI() async {
    setState(() {
      _status = 'Fetching from API...';
    });

    try {
      final products = await _apiService.fetchProductsFromApi();
      setState(() {
        _products = products;
        _status = 'Loaded ${products.length} products from API';
      });
      await _loadLastUpdate();
      
      _showSnackBar('Successfully fetched from FakeStore API', Colors.green);
    } catch (e) {
      setState(() {
        _status = 'Error: $e';
      });
      _showSnackBar('Failed to fetch from API', Colors.red);
    }
  }

  Future<void> _loadFromLocalJSON() async {
    setState(() {
      _status = 'Loading from local JSON...';
    });

    try {
      final products = await _apiService.loadProductsFromLocalJson();
      setState(() {
        _products = products;
        _status = 'Loaded ${products.length} products from local JSON';
      });
      
      _showSnackBar('Loaded from assets/data/products.json', Colors.blue);
    } catch (e) {
      setState(() {
        _status = 'Error: $e';
      });
    }
  }

  Future<void> _loadFromCache() async {
    setState(() {
      _status = 'Loading from cache...';
    });

    try {
      final products = await _apiService.getCachedProducts();
      setState(() {
        _products = products;
        _status = products.isEmpty
            ? 'No cached products found'
            : 'Loaded ${products.length} products from cache';
      });
      
      if (products.isNotEmpty) {
        _showSnackBar('Loaded from SharedPreferences cache', Colors.orange);
      }
    } catch (e) {
      setState(() {
        _status = 'Error: $e';
      });
    }
  }

  Future<void> _saveToLocalFile() async {
    if (_products.isEmpty) {
      _showSnackBar('No products to save', Colors.orange);
      return;
    }

    setState(() {
      _status = 'Saving to local file...';
    });

    try {
      await _apiService.saveProductsToLocalFile(_products);
      setState(() {
        _status = 'Saved ${_products.length} products to file';
      });
      
      _showSnackBar('Saved to app documents directory', Colors.green);
    } catch (e) {
      setState(() {
        _status = 'Error: $e';
      });
    }
  }

  Future<void> _readFromLocalFile() async {
    setState(() {
      _status = 'Reading from local file...';
    });

    try {
      final products = await _apiService.readProductsFromLocalFile();
      setState(() {
        _products = products;
        _status = products.isEmpty
            ? 'No saved products found'
            : 'Read ${products.length} products from file';
      });
      
      if (products.isNotEmpty) {
        _showSnackBar('Read from app documents directory', Colors.purple);
      }
    } catch (e) {
      setState(() {
        _status = 'Error: $e';
      });
    }
  }

  Future<void> _clearCache() async {
    await _apiService.clearCache();
    setState(() {
      _lastUpdate = null;
    });
    _showSnackBar('Cache cleared', Colors.grey);
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Data Source Demo'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Status overview
            Card(
              color: Theme.of(context).colorScheme.primaryContainer,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.info_outline),
                        const SizedBox(width: 8),
                        const Text(
                          'Status',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(_status),
                    if (_lastUpdate != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Last cache update: ${_lastUpdate!.toString().split('.')[0]}',
                        style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Online API actions
            const Text(
              'Online Operations',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: _fetchFromAPI,
              icon: const Icon(Icons.cloud_download),
              label: const Text('Fetch from API (FakeStore)'),
            ),
            const SizedBox(height: 24),

            // Local JSON actions
            const Text(
              'Local JSON File',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: _loadFromLocalJSON,
              icon: const Icon(Icons.folder_open),
              label: const Text('Load from Local JSON'),
            ),
            const SizedBox(height: 24),

            // Cache actions
            const Text(
              'Cache Operations',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: _loadFromCache,
              icon: const Icon(Icons.storage),
              label: const Text('Load from Cache'),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: _clearCache,
              icon: const Icon(Icons.clear),
              label: const Text('Clear Cache'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey,
              ),
            ),
            const SizedBox(height: 24),

            // File storage actions
            const Text(
              'File Storage Operations',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: _saveToLocalFile,
              icon: const Icon(Icons.save),
              label: const Text('Save to Local File'),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: _readFromLocalFile,
              icon: const Icon(Icons.file_open),
              label: const Text('Read from Local File'),
            ),
            const SizedBox(height: 24),

            // Products preview
            if (_products.isNotEmpty) ...[
              const Divider(),
              const SizedBox(height: 8),
              Text(
                'Products (${_products.length})',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ..._products.take(5).map((product) => Card(
                    child: ListTile(
                      leading: product.image.startsWith('http')
                          ? Image.network(
                              product.image,
                              width: 50,
                              height: 50,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => const Icon(Icons.image),
                            )
                          : const Icon(Icons.image),
                      title: Text(product.name),
                      subtitle: Text(product.price),
                      trailing: Text('⭐ ${product.rating}'),
                    ),
                  )),
              if (_products.length > 5)
                Center(
                  child: Text(
                    '...and ${_products.length - 5} more',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

