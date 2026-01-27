import 'package:flutter/material.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('O nas'),
      ),
      body: const Center(
        child: Text('About Page - To be implemented'),
      ),
    );
  }
}
