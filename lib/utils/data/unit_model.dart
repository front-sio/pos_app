class ProductUnit {
  final int id;
  final String name;

  const ProductUnit({required this.id, required this.name});

  factory ProductUnit.fromJson(Map<String, dynamic> j) {
    return ProductUnit(
      id: j['id'] is int ? j['id'] as int : int.tryParse('${j['id']}') ?? 0,
      name: (j['name'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toJson() => {'id': id, 'name': name};
}