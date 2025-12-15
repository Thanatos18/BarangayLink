import 'package:flutter/material.dart';
import '../../widgets/custom_app_bar.dart'; // Relative import

class JobsScreen extends StatelessWidget {
  const JobsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      appBar: CustomAppBar(title: 'Barangay Jobs'),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.work, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('Jobs Board Coming in Phase 3'),
          ],
        ),
      ),
    );
  }
}
