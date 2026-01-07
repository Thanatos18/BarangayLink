import 'package:flutter/material.dart';
import '../constants/app_constants.dart';

class ModernDialog extends StatelessWidget {
  final String title;
  final String? description;
  final Widget? content;
  final String? primaryButtonText;
  final VoidCallback? onPrimaryPressed;
  final String? secondaryButtonText;
  final VoidCallback? onSecondaryPressed;
  final IconData? icon;
  final Color? iconColor;
  final bool isDestructive;

  const ModernDialog({
    super.key,
    required this.title,
    this.description,
    this.content,
    this.primaryButtonText,
    this.onPrimaryPressed,
    this.secondaryButtonText,
    this.onSecondaryPressed,
    this.icon,
    this.iconColor,
    this.isDestructive = false,
  });

  static Future<T?> show<T>(
    BuildContext context, {
    required String title,
    String? description,
    Widget? content,
    String? primaryButtonText,
    VoidCallback? onPrimaryPressed,
    String? secondaryButtonText,
    VoidCallback? onSecondaryPressed,
    IconData? icon,
    Color? iconColor,
    bool isDestructive = false,
  }) {
    return showDialog<T>(
      context: context,
      builder: (context) => ModernDialog(
        title: title,
        description: description,
        content: content,
        primaryButtonText: primaryButtonText,
        onPrimaryPressed: onPrimaryPressed,
        secondaryButtonText: secondaryButtonText,
        onSecondaryPressed: onSecondaryPressed,
        icon: icon,
        iconColor: iconColor,
        isDestructive: isDestructive,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      elevation: 0,
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.rectangle,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (icon != null) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: (iconColor ?? kPrimaryColor).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: 32,
                  color: iconColor ?? kPrimaryColor,
                ),
              ),
              const SizedBox(height: 16),
            ],
            Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
            if (description != null) ...[
              const SizedBox(height: 8),
              Text(
                description!,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (content != null) ...[
              const SizedBox(height: 16),
              content!,
            ],
            const SizedBox(height: 24),
            Row(
              children: [
                if (secondaryButtonText != null)
                  Expanded(
                    child: TextButton(
                      onPressed:
                          onSecondaryPressed ?? () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Text(
                        secondaryButtonText!,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                if (secondaryButtonText != null && primaryButtonText != null)
                  const SizedBox(width: 12),
                if (primaryButtonText != null)
                  Expanded(
                    child: ElevatedButton(
                      onPressed: onPrimaryPressed,
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            isDestructive ? Colors.red : kPrimaryColor,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Text(
                        primaryButtonText!,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
