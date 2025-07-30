class UnitModel {
  final int id;
  String name;

  UnitModel({required this.id, required this.name});

  factory UnitModel.fromJson(Map<String, dynamic> json) {
    return UnitModel(id: json['id'], name: json['name']);
  }
  
  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name};
  }
}
