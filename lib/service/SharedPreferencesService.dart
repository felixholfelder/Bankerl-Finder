import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/StorageKeys.dart';

class SharedPreferencesService {
  final Future<SharedPreferences> _prefs = SharedPreferences.getInstance();

  Future<LatLng> getLocation() async {
    String? locationString = await getPrefString(StorageKeys.locationStorageKey);
    if (locationString != null) {
      return LatLng.fromJson(jsonDecode(locationString));
    }

    return const LatLng(0, 0);
  }

  Future<void> saveLocation(LatLng center) async {
    await savePref(StorageKeys.locationStorageKey, center.toJson());
  }

  Future<void> savePref(String key, dynamic value) async {
    SharedPreferences prefs = await _prefs;
    if (value is String) prefs.setString(key, value);
    if (value is int) prefs.setInt(key, value);
    if (value is Map) prefs.setString(key, jsonEncode(value));
  }

  Future<String?> getPrefString(String key) async {
    SharedPreferences prefs = await _prefs;
    return prefs.getString(key);
  }

  Future<int?> getPrefInt(String key) async {
    SharedPreferences prefs = await _prefs;
    return prefs.getInt(key);
  }

  Future<Map<String, dynamic>?> getPrefObject(String key) async {
    SharedPreferences prefs = await _prefs;
    String? stringResult = prefs.getString(key);
    if (stringResult != null) {
      return jsonDecode(stringResult);
    }
    return null;
  }
}
