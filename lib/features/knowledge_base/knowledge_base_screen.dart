import 'package:flutter/material.dart';

class KnowledgeBaseScreen extends StatelessWidget {
  const KnowledgeBaseScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Knowledge Base')),
      body: const Center(child: Text('Knowledge Base — full build in Turn 2')),
    );
  }
}
