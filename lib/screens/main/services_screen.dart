import 'package:flutter/material.dart';
import '../../widgets/custom_app_bar.dart'; // Relative import

class ServicesScreen extends StatelessWidget {
  const ServicesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      appBar: CustomAppBar(title: 'Community Services'),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.handyman, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('Services Finder Coming in Phase 4'),
          ],
        ),
      ),
    );
  }
}
