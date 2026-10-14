// lib/screens/ai_screen.dart
import 'package:flutter/material.dart';

class AiScreen extends StatelessWidget {
  const AiScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI サポート'),
      ),
      body: const Center(
        child: Text('AI相談・サポート画面', style: TextStyle(fontSize: 24)),
      ),
    );
  }
}