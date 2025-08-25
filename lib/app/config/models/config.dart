class Config {
  final int id;
  final String cod;
  final String value;

  Config({required this.id, required this.cod, required this.value});

  factory Config.fromJson(Map<String, dynamic> json) {
    return Config(id: json['id'], cod: json['cod'], value: json['value']);
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'cod': cod, 'value': value};
  }
}
