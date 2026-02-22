import 'package:flutter/material.dart';

class FocusTimerScreen extends StatelessWidget {
  const FocusTimerScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Focus Timer')),
      body: const Center(child: Text('Focus Timer — coming in Turn 3')),
    );
  }
}
