import 'package:flutter/material.dart';
import '../../widgets/custom_app_bar.dart'; // Relative import

class RentalsScreen extends StatelessWidget {
  const RentalsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      appBar: CustomAppBar(title: 'Rent-A-Tool'),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.build, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('Equipment Rentals Coming in Phase 5'),
          ],
        ),
      ),
    );
  }
}
