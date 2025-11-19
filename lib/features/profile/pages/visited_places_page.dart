import 'package:flutter/material.dart';

class VisitedPlacesPage extends StatelessWidget {
  const VisitedPlacesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lieux visités'),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFFDEBEE), Color(0xFFFFF7FF)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: const Center(
          child: Text(
            'Contenu à venir',
            style: TextStyle(fontSize: 18),
          ),
        ),
      ),
    );
  }
}
