import 'package:latlong2/latlong.dart';

class Bench {
  final String name;
  final LatLng position;

  Bench({required this.name, required this.position});

  factory Bench.fromJson(Map<String, dynamic> json) {
    return Bench(
      name: json['name'],
      position: LatLng.fromJson(json['position']),
    );
  }

  Map<String, dynamic> toJSON() => {
        'name': name,
        'position': position.toJson(),
      };
}
