class Category {
  final int id;
  final String name;

  const Category({required this.id, required this.name});

  factory Category.fromJson(Map<String, dynamic> j) {
    return Category(
      id: j['id'] is int ? j['id'] as int : int.tryParse('${j['id']}') ?? 0,
      name: (j['name'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toJson() => {'id': id, 'name': name};
}