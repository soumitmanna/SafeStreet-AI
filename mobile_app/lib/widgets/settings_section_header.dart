import 'package:flutter/material.dart';

class SettingsSectionHeader extends StatelessWidget {
  final String title;
  
  const SettingsSectionHeader({
    super.key,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 12, top: 24),
      child: Text(
        title.toUpperCase(),
        style: theme.textTheme.titleSmall?.copyWith(
          color: Colors.black54,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
          fontSize: 12,
        ),
      ),
    );
  }
}
