import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';

// Feature imports
import 'features/auth/providers/auth_provider.dart';
import 'features/auth/screens/login_page.dart';
import 'core/main_navigation_screen.dart'; 
import 'firebase_options.dart';
import 'services/notification_services.dart';

// --- GLOBAL KEY ---
// Allows snackbars to persist even when navigating back to Login
final messengerKey = GlobalKey<ScaffoldMessengerState>();

void main() async {
  // 1. Mandatory for all native plugins
  WidgetsFlutterBinding.ensureInitialized();

  // 2. Initialize Firebase FIRST
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint("Firebase initialization failed: $e");
  }

  // 3. Initialize Notifications AFTER platform is ready
  // Ensure your init() method handles the kIsWeb check we discussed!
  await NotificationService.init();

  runApp(
    const ProviderScope(child: PawfolioApp()),
  );
}

class PawfolioApp extends ConsumerWidget {
  const PawfolioApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch the auth state - this is your app's "brain"
    final authState = ref.watch(authProvider);

    return MaterialApp(
      scaffoldMessengerKey: messengerKey,
      title: 'Pawfolio',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFF8B947E), // Sage Green
        scaffoldBackgroundColor: const Color(0xFFF5F2EE), // Cream
      ),
      // Reactive navigation switch
      home: _getHomeWidget(authState),
    );
  }

Widget _getHomeWidget(AuthState authState) {
  // Only show splash during cold-start initialization, NOT during login attempts
  if (authState.isInitializing) return const SplashScreen();
  if (authState.user != null) return const MainNavigationScreen();
  return const LoginPage();
}
}
// --- Splash Screen ---
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFFD7CCC8),
      body: Center(
        child: CircularProgressIndicator(color: Color(0xFF8B947E)),
      ),
    );
  }
}