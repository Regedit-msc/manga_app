import 'package:flutter/material.dart';

class TonalIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;

  const TonalIconButton({super.key, required this.icon, this.onPressed});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.secondaryContainer,
      shape: const StadiumBorder(),
      child: InkWell(
        onTap: onPressed,
        customBorder: const StadiumBorder(),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Icon(icon, color: scheme.onSecondaryContainer),
        ),
      ),
    );
  }
}
