class ItemModel {
  final int id;
  final String name;
  final int quantity;
  final String? location;

  ItemModel({
    required this.id,
    required this.name,
    required this.quantity,
    this.location,
  });

  factory ItemModel.fromJson(Map<String, dynamic> json) {
    return ItemModel(
      id: json['id'],
      name: json['name'],
      quantity: json['quantity'],
      location: json['location_name'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'quantity': quantity,
      'location_name': location,
    };
  }
}
