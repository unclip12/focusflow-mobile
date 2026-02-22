import 'package:flutter/material.dart';

class TodaysPlanScreen extends StatelessWidget {
  const TodaysPlanScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Today's Plan")),
      body: const Center(child: Text("Today's Plan — full build in Turn 2")),
    );
  }
}
