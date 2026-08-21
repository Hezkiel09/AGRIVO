import 'package:flutter/material.dart';

class CustomBackButton extends StatelessWidget {
  final VoidCallback? onTap;
  final Color backgroundColor;
  final Color iconColor;
  final double size;
  final double iconSize;

  const CustomBackButton({
    super.key,
    this.onTap,
    this.backgroundColor = const Color(0xFF1B4F1E),
    this.iconColor = Colors.white,
    this.size = 40.0,
    this.iconSize = 20.0,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap ?? () => Navigator.of(context).maybePop(),
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: backgroundColor,
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Icon(
            Icons.arrow_back,
            color: iconColor,
            size: iconSize,
          ),
        ),
      ),
    );
  }
}
