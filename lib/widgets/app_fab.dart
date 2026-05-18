import 'package:flutter/material.dart';

class AppFab extends StatelessWidget {
  final VoidCallback onPressed;
  final IconData icon;

  const AppFab({super.key, required this.onPressed, this.icon = Icons.add});

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return FloatingActionButton(
      backgroundColor: primary,
      foregroundColor: Colors.white,
      onPressed: onPressed,
      child: Icon(icon),
    );
  }
}
