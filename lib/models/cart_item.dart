class CartItem {
  final String id;
  final String name;
  final String price;
  final String image;
  int quantity;

  CartItem({
    required this.id,
    required this.name,
    required this.price,
    required this.image,
    this.quantity = 1,
  });

  double get priceValue {
    return double.parse(price.replaceAll('\$', '').replaceAll(',', ''));
  }

  double get totalPrice {
    return priceValue * quantity;
  }
}
