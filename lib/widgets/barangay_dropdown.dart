import 'package:flutter/material.dart';
import '../constants/app_constants.dart'; // Relative import

class BarangayDropdown extends StatelessWidget {
  final String? selectedValue;
  final Function(String?) onChanged;
  final String? Function(String?)? validator;

  const BarangayDropdown({
    super.key,
    required this.selectedValue,
    required this.onChanged,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      value: selectedValue,
      decoration: InputDecoration(
        labelText: 'Select Barangay',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0)),
      ),
      isExpanded: true,
      hint: const Text('Choose your barangay'),
      // Updated to use the new variable name 'tagumBarangays'
      items: tagumBarangays.map((String barangay) {
        return DropdownMenuItem<String>(value: barangay, child: Text(barangay));
      }).toList(),
      onChanged: onChanged,
      validator: validator,
    );
  }
}
