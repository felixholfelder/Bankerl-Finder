import 'package:bankerl_finder/model/Bench.dart';
import 'package:bankerl_finder/service/BenchService.dart';
import 'package:bankerl_finder/service/DialogService.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final BenchService _benchService = BenchService();

  var _center = const LatLng(49.9012148, 12.2009079);
  List<Marker> _benches = List.of({});

  @override
  void initState() {
    super.initState();
    _goToCurrPosition();
    _getBenches();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text("Bankerl Finder"),
        actions: [
          IconButton(
              onPressed: _goToCurrPosition, icon: const Icon(Icons.my_location))
        ],
      ),
      body: Stack(
        children: [
          FlutterMap(
            options: MapOptions(
                initialZoom: 14,
                initialCenter: _center,
                onTap: (TapPosition pos, LatLng latlng) =>
                    _openBenchDialog(context, pos, latlng)),
            children: [
              TileLayer(
                  urlTemplate:
                      'https://tile.openstreetmap.org/{z}/{x}/{y}.png'),
              MarkerLayer(
                markers: [
                  Marker(
                    point: _center,
                    child: const Icon(
                      Icons.location_on,
                      color: Colors.red,
                      size: 30,
                    ),
                    rotate: true,
                  ),
                  ..._benches,
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _openBenchDialog(context, TapPosition pos, LatLng latlng) async {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(builder: (context, setState) {
          return AlertDialog(
            title: const Text("Bank anlegen"),
            actionsOverflowButtonSpacing: 20,
            actions: [
              TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text("Abbrechen")),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _addBench(latlng);
                },
                style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white),
                child: const Text("Speichern"),
              ),
            ],
          );
        });
      },
    );
  }

  void _getBenches() async {
    List<Bench> benches = await _benchService.getBenches(context);

    _benches.addAll(
      benches.map(
        (e) => Marker(
          point: LatLng(e.position.latitude, e.position.longitude),
          child: const Icon(
            Icons.location_on,
            color: Colors.blue,
            size: 30,
          ),
          rotate: true,
        ),
      ),
    );
  }

  void _addBench(LatLng pos) {
    Bench bench = Bench(name: "", position: pos);

    _benchService.createBench(context, bench);
  }

  void _goToCurrPosition() async {
    Position pos = await _getPosition();
    setState(() => _center = LatLng(pos.latitude, pos.longitude));
  }

  Future<Position> _getPosition() async {
    final hasPermission = await _handleLocationPermission(context);

    if (!hasPermission)
      SnackBarService.errorSnackBar(
          context: context,
          title: "GPS-Fehler",
          message: "GPS ist für diese App deaktiviert!");

    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
    return position;
  }

  Future<bool> _handleLocationPermission(BuildContext context) async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      SnackBarService.warningSnackBar(
          context: context,
          title: "GPS-Fehler",
          message: "Dein GPS ist ausgeschaltet!");
      return false;
    }
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        SnackBarService.warningSnackBar(
            context: context,
            title: "GPS-Fehler",
            message: "GPS ist für diese App deaktiviert!");
        return false;
      }
    }
    if (permission == LocationPermission.deniedForever) {
      SnackBarService.warningSnackBar(
          context: context,
          title: "GPS-Fehler",
          message:
              "GPS ist für diese App deaktiviert!. Ändere deine Einstellungen um die GPS-Suche zu verwenden!");
      return false;
    }
    return true;
  }
}
