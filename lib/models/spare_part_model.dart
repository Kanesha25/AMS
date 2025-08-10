class SparePart {
  String name;
  int minPrice;
  int maxPrice;

  SparePart({
    required this.name,
    required this.minPrice,
    required this.maxPrice,
  });

  SparePart copyWith({
    String? name,
    int? minPrice,
    int? maxPrice,
  }) {
    return SparePart(
      name: name ?? this.name,
      minPrice: minPrice ?? this.minPrice,
      maxPrice: maxPrice ?? this.maxPrice,
    );
  }
}