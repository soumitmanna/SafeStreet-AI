import 'package:flutter/material.dart';
import '../controllers/theme_controller.dart';
import '../widgets/settings_section_header.dart';

class AppearanceScreen extends StatelessWidget {
  const AppearanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeController = ThemeController();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Appearance'),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: [
          const SettingsSectionHeader(title: 'Theme Settings'),
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).cardTheme.color,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Theme.of(context).dividerColor),
            ),
            child: ListenableBuilder(
              listenable: themeController,
              builder: (context, _) {
                return RadioGroup<ThemeMode>(
                  groupValue: themeController.themeMode,
                  onChanged: (val) {
                    if (val != null) themeController.updateThemeMode(val);
                  },
                  child: Column(
                    children: [
                      _ThemeRadioTile(
                        title: 'System Default',
                        subtitle: 'Matches your device theme',
                        value: ThemeMode.system,
                        isFirst: true,
                      ),
                      const Divider(height: 1, indent: 16, endIndent: 16),
                      _ThemeRadioTile(
                        title: 'Light',
                        subtitle: 'Always use light theme',
                        value: ThemeMode.light,
                      ),
                      const Divider(height: 1, indent: 16, endIndent: 16),
                      _ThemeRadioTile(
                        title: 'Dark',
                        subtitle: 'Always use dark theme',
                        value: ThemeMode.dark,
                        isLast: true,
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ThemeRadioTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final ThemeMode value;
  final bool isFirst;
  final bool isLast;

  const _ThemeRadioTile({
    required this.title,
    required this.subtitle,
    required this.value,
    this.isFirst = false,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(isFirst ? 20 : 0),
        bottom: Radius.circular(isLast ? 20 : 0),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        child: RadioListTile<ThemeMode>(
          title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
          subtitle: Text(subtitle, style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color)),
          value: value,
          activeColor: Theme.of(context).primaryColor,
          controlAffinity: ListTileControlAffinity.trailing,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12),
        ),
      ),
    );
  }
}
