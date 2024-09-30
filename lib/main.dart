import 'package:bankerl_finder/HomePage.dart';
import 'package:flutter/material.dart';


void main() {
  runApp(const BankerlFinder());
}

class BankerlFinder extends StatelessWidget {
  const BankerlFinder({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bankerl Finder',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.lightGreenAccent),
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}