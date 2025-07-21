import 'package:flutter/material.dart';

class CircleIconButton extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color backgroundColor;
  final String tooltip;
  final VoidCallback onPressed;

  const CircleIconButton({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.backgroundColor,
    required this.tooltip,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    // Responsive sizing
    final double iconSize = screenWidth > 600 ? 32.0 : (screenWidth > 400 ? 28.0 : 24.0);
    final double padding = screenWidth > 600 ? 16.0 : (screenWidth > 400 ? 12.0 : 8.0);

    return Tooltip(
      message: tooltip,
      child: Padding(
        padding: EdgeInsets.all(padding / 2),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(40),
          child: CircleAvatar(
            radius: iconSize,
            backgroundColor: backgroundColor,
            child: Icon(
              icon,
              color: iconColor,
              size: iconSize,
            ),
          ),
        ),
      ),
    );
  }
}
