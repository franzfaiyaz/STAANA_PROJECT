import 'package:ctadmobl_project/providers/theme_provider.dart';
import 'package:ctadmobl_project/widgets/app_error_state.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ThemeModeTile extends StatelessWidget {
  const ThemeModeTile({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ThemeProvider>();
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      title: const Text('Dark Mode'),
      subtitle: Text(
        'Use a darker appearance',
        style: Theme.of(context).textTheme.bodySmall,
      ),
      value: Theme.of(context).brightness == Brightness.dark,
      onChanged: (enabled) async {
        try {
          await provider.setThemeMode(
            enabled ? ThemeMode.dark : ThemeMode.light,
          );
        } catch (error) {
          debugPrint('Unable to save theme: $error');
          if (!context.mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text(appErrorMessage),
              action: SnackBarAction(
                label: 'Retry',
                onPressed: () => provider.setThemeMode(
                  enabled ? ThemeMode.dark : ThemeMode.light,
                ),
              ),
            ),
          );
        }
      },
    );
  }
}
