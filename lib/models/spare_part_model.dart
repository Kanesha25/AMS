class SparePart {
  int? id;
  String name;
  int minPrice;
  int maxPrice;

  SparePart({
    this.id,
    required this.name,
    required this.minPrice,
    required this.maxPrice,
  });

  SparePart copyWith({
    int? id,
    String? name,
    int? minPrice,
    int? maxPrice,
  }) {
    return SparePart(
      id: id ?? this.id,
      name: name ?? this.name,
      minPrice: minPrice ?? this.minPrice,
      maxPrice: maxPrice ?? this.maxPrice,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'min_price': minPrice,
      'max_price': maxPrice,
    };
  }

  factory SparePart.fromMap(Map<String, dynamic> map) {
    return SparePart(
      id: map['id'],
      name: map['name'],
      minPrice: map['min_price'],
      maxPrice: map['max_price'],
    );
  }
}