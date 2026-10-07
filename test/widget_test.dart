import 'package:ctadmobl_project/providers/theme_provider.dart';
import 'package:ctadmobl_project/screens/login_screen.dart';
import 'package:ctadmobl_project/theme/app_theme.dart';
import 'package:ctadmobl_project/widgets/theme_mode_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('theme mode loads and persists', () async {
    SharedPreferences.setMockInitialValues({'themeMode': 'dark'});
    final provider = ThemeProvider();
    await provider.load();
    expect(provider.themeMode, ThemeMode.dark);

    await provider.toggleTheme();
    expect(provider.themeMode, ThemeMode.light);
    expect(
      (await SharedPreferences.getInstance()).getString('themeMode'),
      'light',
    );
    provider.dispose();
  });

  testWidgets('login screen renders with both theme configurations', (
    tester,
  ) async {
    for (final themeMode in [ThemeMode.light, ThemeMode.dark]) {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: themeMode,
          home: const LoginScreen(),
        ),
      );
      await tester.pumpAndSettle();

      final theme = Theme.of(tester.element(find.text('Welcome back')));
      expect(
        theme.brightness,
        themeMode == ThemeMode.dark ? Brightness.dark : Brightness.light,
      );
      expect(
        theme.scaffoldBackgroundColor,
        themeMode == ThemeMode.dark ? const Color(0xFF0E0E0E) : Colors.white,
      );
      expect(
        theme.inputDecorationTheme.fillColor,
        themeMode == ThemeMode.dark
            ? const Color(0xFF1E1E1E)
            : const Color(0xFFF5F5F5),
      );
    }
  });

  testWidgets('profile theme switch updates app appearance', (tester) async {
    final provider = ThemeProvider();
    await provider.load();

    await tester.pumpWidget(
      ChangeNotifierProvider<ThemeProvider>.value(
        value: provider,
        child: Consumer<ThemeProvider>(
          builder: (context, theme, _) => MaterialApp(
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            themeMode: theme.themeMode,
            home: const Scaffold(body: ThemeModeTile()),
          ),
        ),
      ),
    );

    expect(
      Theme.of(tester.element(find.text('Dark Mode'))).brightness,
      Brightness.light,
    );
    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();
    expect(
      Theme.of(tester.element(find.text('Dark Mode'))).brightness,
      Brightness.dark,
    );

    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();
    expect(
      Theme.of(tester.element(find.text('Dark Mode'))).brightness,
      Brightness.light,
    );
    provider.dispose();
  });
}
