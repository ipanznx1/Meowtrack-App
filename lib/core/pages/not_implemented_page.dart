import 'package:flutter/material.dart';

class NotImplementedPage extends StatelessWidget {
  final String title;
  const NotImplementedPage({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title), backgroundColor: const Color(0xFF985BEF)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text('This feature is not implemented yet: $title', textAlign: TextAlign.center, style: const TextStyle(fontSize: 16)),
        ),
      ),
    );
  }
}
