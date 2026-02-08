class Product {
  final String id;
  final String name;
  final String price;
  final String rating;
  final String image;
  final String? description;
  final List<String>? features;
  final String? brand;
  final String? category;
  final bool? inStock;
  final int? reviews;

  Product({
    required this.id,
    required this.name,
    required this.price,
    required this.rating,
    required this.image,
    this.description,
    this.features,
    this.brand,
    this.category,
    this.inStock,
    this.reviews,
  });

  // Turn this Product into a map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'price': price,
      'rating': rating,
      'image': image,
      'description': description,
      'features': features,
      'brand': brand,
      'category': category,
      'inStock': inStock,
      'reviews': reviews,
    };
  }

  // Build a Product from a map
  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      id: map['id']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      price: map['price']?.toString() ?? '',
      rating: map['rating']?.toString() ?? '0.0',
      image: map['image']?.toString() ?? '',
      description: map['description']?.toString(),
      features: map['features'] != null 
          ? List<String>.from(map['features'])
          : null,
      brand: map['brand']?.toString(),
      category: map['category']?.toString(),
      inStock: map['inStock'] as bool?,
      reviews: map['reviews'] as int?,
    );
  }

  // Build a Product from JSON
  factory Product.fromJson(Map<String, dynamic> json) {
    return Product.fromMap(json);
  }

  // Convert this Product to JSON
  Map<String, dynamic> toJson() => toMap();

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Product && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

