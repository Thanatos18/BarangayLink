import 'package:flutter/material.dart';
import '../constants/app_constants.dart'; // Changed to relative import

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final bool showBackButton;

  const CustomAppBar({
    super.key,
    required this.title,
    this.actions,
    this.showBackButton = false,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      centerTitle:
          false, // You can change this to true if you prefer centered titles
      backgroundColor: kPrimaryColor,
      foregroundColor: Colors.white,
      automaticallyImplyLeading: showBackButton,
      actions: actions,
      elevation: 0,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
