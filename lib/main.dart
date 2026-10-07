import 'package:ctadmobl_project/providers/navigation_provider.dart';
import 'package:ctadmobl_project/providers/cart_provider.dart';
import 'package:ctadmobl_project/providers/auth_provider.dart';
import 'package:ctadmobl_project/providers/favorites_provider.dart';
import 'package:ctadmobl_project/providers/order_provider.dart';
import 'package:ctadmobl_project/providers/product_provider.dart';
import 'package:ctadmobl_project/providers/profile_provider.dart';
import 'package:ctadmobl_project/providers/review_provider.dart';
import 'package:ctadmobl_project/providers/theme_provider.dart';
import 'package:ctadmobl_project/providers/listing_provider.dart';
import 'package:ctadmobl_project/screens/home_screen.dart';
import 'package:ctadmobl_project/screens/login_screen.dart';
import 'package:ctadmobl_project/theme/app_theme.dart';
import 'package:ctadmobl_project/widgets/app_error_state.dart';
import 'package:ctadmobl_project/services/auth_service.dart';
import 'package:ctadmobl_project/services/product_service.dart';
import 'package:ctadmobl_project/services/listing_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'firebase_options.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ShoeShopApp());
}

class ShoeShopApp extends StatefulWidget {
  const ShoeShopApp({super.key});

  @override
  State<ShoeShopApp> createState() => _ShoeShopAppState();
}

class _ShoeShopAppState extends State<ShoeShopApp> {
  late final Future<ThemeProvider> _startup;

  @override
  void initState() {
    super.initState();
    _startup = _initializeApp();
  }

  Future<ThemeProvider> _initializeApp() async {
    final themeProvider = ThemeProvider();
    try {
      await Future.wait([
        Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform),
        themeProvider.load(),
      ]);
      return themeProvider;
    } catch (error) {
      debugPrint('Unable to initialize app services: $error');
      themeProvider.dispose();
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<ThemeProvider>(
      future: _startup,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _StatusApp(
            message: appErrorMessage,
            onRetry: () => setState(() => _startup = _initializeApp()),
          );
        }
        if (snapshot.connectionState != ConnectionState.done) {
          return const _StatusApp(
            message: 'Initializing...',
            showProgress: true,
          );
        }

        return MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => NavigationProvider()),
            ChangeNotifierProvider<ThemeProvider>.value(value: snapshot.data!),
            Provider(create: (_) => AuthService()),
            Provider(create: (_) => ProductService()),
            Provider(create: (_) => ListingService(FirebaseFirestore.instance)),
            ChangeNotifierProvider(
              create: (context) => AuthProvider(context.read<AuthService>()),
            ),
            ChangeNotifierProvider(
              create: (context) =>
                  ListingProvider(context.read<ListingService>()),
            ),
            ChangeNotifierProvider(
              create: (context) =>
                  ProductProvider(context.read<ProductService>()),
            ),
            ChangeNotifierProvider(create: (_) => CartProvider()),
            ChangeNotifierProvider(create: (_) => FavoritesProvider()),
            ChangeNotifierProvider(create: (_) => ReviewProvider()),
            ChangeNotifierProvider(create: (_) => OrderProvider()),
            ChangeNotifierProvider(
              create: (context) => ProfileProvider(context.read<AuthService>()),
            ),
          ],
          child: Consumer<ThemeProvider>(
            builder: (context, themeProvider, _) => MaterialApp(
              title: 'Shoe Shop',
              debugShowCheckedModeBanner: false,
              theme: AppTheme.light,
              darkTheme: AppTheme.dark,
              themeMode: themeProvider.themeMode,
              home: const AuthGate(),
            ),
          ),
        );
      },
    );
  }
}

class _StatusApp extends StatelessWidget {
  const _StatusApp({
    required this.message,
    this.showProgress = false,
    this.onRetry,
  });

  final String message;
  final bool showProgress;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (showProgress) ...[
                  const CircularProgressIndicator(),
                  const SizedBox(height: 20),
                ],
                Text(message, textAlign: TextAlign.center),
                if (onRetry != null) ...[
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: onRetry,
                    child: const Text('Retry'),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  int _authStreamKey = 0;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      key: ValueKey(_authStreamKey),
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          debugPrint('Unable to check sign-in status: ${snapshot.error}');
          return AppErrorState(
            onRetry: () => setState(() => _authStreamKey++),
          );
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _StatusApp(
            message: 'Checking sign-in status...',
            showProgress: true,
          );
        }

        return snapshot.data == null
            ? const LoginScreen()
            : Consumer<AuthProvider>(
                builder: (context, auth, _) {
                  if (auth.isLoading) {
                    return const Scaffold(
                      body: Center(child: CircularProgressIndicator()),
                    );
                  }
                  if (auth.error != null) {
                    return AppErrorState(
                      onRetry: auth.reload,
                    );
                  }
                  return HomeScreen(userId: snapshot.data!.uid);
                },
              );
      },
    );
  }
}
