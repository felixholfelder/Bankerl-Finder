import 'package:bankerl_finder/model/Bench.dart';
import 'package:bankerl_finder/service/BenchService.dart';
import 'package:bankerl_finder/service/DialogService.dart';
import 'package:bankerl_finder/service/SharedPreferencesService.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:maps_launcher/maps_launcher.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final BenchService _benchService = BenchService();
  final SharedPreferencesService _prefService = SharedPreferencesService();

  LatLng _center = LatLng(0, 0);
  final double _zoom = 14;
  List<Marker> _benches = List.of({});

  final _mapController = MapController();

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
          IconButton(onPressed: _getBenches, icon: const Icon(Icons.refresh)),
          IconButton(onPressed: _goToCurrPosition, icon: const Icon(Icons.my_location))
        ],
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
                initialZoom: _zoom,
                initialCenter: _center,
                onTap: (TapPosition pos, LatLng latlng) => _openBenchDialog(context, pos, latlng),
                interactionOptions: const InteractionOptions(
                    flags: InteractiveFlag.drag | InteractiveFlag.pinchZoom | InteractiveFlag.pinchMove),
                maxZoom: 20),
            children: [
              TileLayer(urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png'),
              MarkerLayer(
                markers: [
                  Marker(
                    alignment: Alignment.topCenter,
                    point: _center,
                    child: const Icon(
                      Icons.location_on,
                      color: Colors.red,
                      size: 40,
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
              TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text("Abbrechen")),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _addBench(latlng);
                },
                style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor, foregroundColor: Colors.white),
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

    setState(() => _benches = []);

    _benches.addAll(
      benches.map((e) => _getMarker(e)),
    );

    setState(() => _benches);
  }

  Marker _getMarker(Bench bench) {
    return Marker(
      point: bench.position,
      alignment: Alignment.topCenter,
      child: GestureDetector(
        onTap: () => _showMarkerBottomSheet(bench.position),
        onLongPress: () => _showDeleteDialog(bench),
        child: const Icon(Icons.location_on, color: Colors.blue, size: 40),
      ),
    );
  }

  void _showMarkerBottomSheet(LatLng position) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SizedBox(
            height: 120,
            child: Padding(
              padding: const EdgeInsets.all(10.0),
              child: Row(children: [
                const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Icon(Icons.location_on, size: 28),
                ),
                Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(position.latitude.toString(), style: const TextStyle(fontSize: 20)),
                      Text(position.longitude.toString(), style: const TextStyle(fontSize: 20)),
                    ]),
                const Spacer(),
                IconButton(
                  tooltip: "In Google Maps öffnen",
                  onPressed: () => _openGoogleMaps(position),
                  icon: const Icon(Icons.near_me, size: 28),
                ),
              ]),
            ));
      },
    );
  }

  Future<void> _showDeleteDialog(Bench bench) async {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(builder: (context, setState) {
          return AlertDialog(
            title: const Text("Bank löschen?"),
            actionsOverflowButtonSpacing: 20,
            actions: [
              TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text("Abbrechen")),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _deleteBench(bench);
                },
                style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor, foregroundColor: Colors.white),
                child: const Text("Löschen"),
              ),
            ],
          );
        });
      },
    );
  }

  void _openGoogleMaps(LatLng position) => MapsLauncher.launchCoordinates(position.latitude, position.longitude);

  Future<void> _addBench(LatLng pos) async {
    Bench bench = Bench(name: "", position: pos);

    await _benchService.createBench(context, bench);

    _getBenches();
  }

  Future<void> _deleteBench(Bench bench) async {
    await _benchService.deleteBench(context, bench);
    _getBenches();
  }

  void _goToCurrPosition() async {
    Position? pos = await _getPosition();

    if (pos != null) {
      _center = LatLng(pos.latitude, pos.longitude);
      await _prefService.saveLocation(_center);
    } else {
      _center = await _prefService.getLocation();
    }

    setState(() => _center);
    _mapController.move(_center, _zoom);
  }

  Future<Position?> _getPosition() async {
    final hasPermission = await _handleLocationPermission(context);

    if (!hasPermission) {
      SnackBarService.errorSnackBar(
          context: context, title: "GPS-Fehler", message: "GPS ist für diese App deaktiviert!");
      return null;
    }

    return await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
  }

  Future<bool> _handleLocationPermission(BuildContext context) async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      SnackBarService.warningSnackBar(context: context, title: "GPS-Fehler", message: "Dein GPS ist ausgeschaltet!");
      return false;
    }
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        SnackBarService.warningSnackBar(
            context: context, title: "GPS-Fehler", message: "GPS ist für diese App deaktiviert!");
        return false;
      }
    }
    if (permission == LocationPermission.deniedForever) {
      SnackBarService.warningSnackBar(
          context: context,
          title: "GPS-Fehler",
          message: "GPS ist für diese App deaktiviert!. Ändere deine Einstellungen um die GPS-Suche zu verwenden!");
      return false;
    }
    return true;
  }
}
