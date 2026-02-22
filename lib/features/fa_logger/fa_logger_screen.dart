import 'package:flutter/material.dart';

class FALoggerScreen extends StatelessWidget {
  const FALoggerScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('FA Logger')),
      body: const Center(child: Text('FA Logger — full build in Turn 2')),
    );
  }
}
