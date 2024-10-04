import 'dart:convert';

import 'package:bankerl_finder/model/Bench.dart';
import 'package:flutter/cupertino.dart';
import 'package:http/http.dart';

import 'DialogService.dart';

class BenchService {
  final String baseUrl = "https://bankerl-service.holfelder.cloud/api/benches";

  Future<List<Bench>> getBenches(BuildContext context) async {
    Response res = await get(Uri.parse(baseUrl));
    if (res.statusCode != 200) {
      SnackBarService.errorSnackBar(
        context: context,
        title: "Fehler ${res.statusCode}",
        message: "Ein Fehler ist aufgetreten! Versuche es später erneut.",
      );
      throw Exception(res.statusCode);
    }

    List<dynamic> body = jsonDecode(utf8.decode(res.bodyBytes));

    return body.map((dynamic item) => Bench.fromJson(item)).toList();
  }

  Future<void> createBench(BuildContext context, Bench bench) async {
    Response res = await post(
      Uri.parse(baseUrl),
      body: jsonEncode(bench.toJSON()),
      headers: {"Content-Type": "application/json"},
    );

    if (res.statusCode != 200) {
      SnackBarService.errorSnackBar(
        context: context,
        title: "Fehler ${res.statusCode}",
        message: "Ein Fehler ist aufgetreten! Versuche es später erneut.",
      );
      throw Exception(res.statusCode);
    }
  }

  Future<void> deleteBench(BuildContext context, Bench bench) async {
    Response res = await delete(
      Uri.parse("$baseUrl/${bench.id}"),
      body: jsonEncode(bench.toJSON()),
      headers: {"Content-Type": "application/json"},
    );

    if (res.statusCode != 200) {
      SnackBarService.errorSnackBar(
        context: context,
        title: "Fehler ${res.statusCode}",
        message: "Ein Fehler ist aufgetreten! Versuche es später erneut.",
      );
      throw Exception(res.statusCode);
    }
  }
}
