import 'package:latlong2/latlong.dart';

class Bench {
  final String? id;
  final String name;
  final LatLng position;

  Bench({this.id, required this.name, required this.position});

  factory Bench.fromJson(Map<String, dynamic> json) {
    return Bench(
      id: json['id'],
      name: json['name'],
      position: LatLng(json['position']['lat'], json['position']['lng']),
    );
  }

  Map<String, dynamic> toJSON() => {
        'id': id,
        'name': name,
        'position': {'lat': position.latitude, 'lng': position.longitude}
      };
}
