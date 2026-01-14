class LookupModel {
  final int id;
  final String name;

  const LookupModel({required this.id, required this.name});

  factory LookupModel.fromJson(Map<String, dynamic> json) {
    return LookupModel(id: json['id'] as int, name: json['name'] as String);
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name};
  }
}

class LookupResponse {
  final List<LookupModel> items;

  const LookupResponse({required this.items});

  factory LookupResponse.fromJson(List<dynamic> json) {
    return LookupResponse(
      items: json.map((item) => LookupModel.fromJson(item)).toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {'items': items.map((item) => item.toJson()).toList()};
  }
}
