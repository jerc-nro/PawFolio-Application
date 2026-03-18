import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';

import 'features/auth/providers/auth_provider.dart';
import 'features/auth/screens/login_page.dart';
import 'features/pets/screens/add_pet_page.dart';
import 'core/main_navigation_screen.dart';
import 'firebase_options.dart';
import 'services/notification_services.dart';
import 'services/overdue_services.dart';

final messengerKey = GlobalKey<ScaffoldMessengerState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform);
  } catch (e) {
    debugPrint('Firebase initialization failed: $e');
  }

  try {
    await NotificationService.init();
  } catch (e) {
    debugPrint('Notification Init Failed: $e');
  }

  runApp(const ProviderScope(child: PawfolioApp()));
}

class PawfolioApp extends ConsumerWidget {
  const PawfolioApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

    return MaterialApp(
      scaffoldMessengerKey: messengerKey,
      title: 'Pawfolio',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFF8B947E),
        scaffoldBackgroundColor: const Color(0xFFF5F2EE),
      ),
      home: _resolveHome(authState, ref),
    );
  }

  Widget _resolveHome(AuthState authState, WidgetRef ref) {
    if (authState.isInitializing) return const _SplashScreen();
    if (authState.user == null) return const LoginPage();
    if (authState.isLoading) return const _LoadingHomeScreen();

    if (authState.isNewUser) {
      return _NewUserGate(
        onDone: () => ref.read(authProvider.notifier).clearNewUserFlag(),
      );
    }

    return _OverdueGate(uid: authState.user!.userID);
  }
}

// ─── Overdue Gate ─────────────────────────────────────────────────────────────

class _OverdueGate extends StatefulWidget {
  final String uid;
  const _OverdueGate({required this.uid});

  @override
  State<_OverdueGate> createState() => _OverdueGateState();
}

class _OverdueGateState extends State<_OverdueGate> {
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    OverdueService.markOverdueRecords(widget.uid).then((_) {
      if (mounted) setState(() => _ready = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) return const _LoadingHomeScreen();
    return const MainNavigationScreen();
  }
}

// ─── New User Gate ────────────────────────────────────────────────────────────

class _NewUserGate extends StatelessWidget {
  final VoidCallback onDone;
  const _NewUserGate({required this.onDone});

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        body: Stack(
          children: [
            AddPetPage(
              onComplete: onDone,
              showCancel: false,
            ),
            SafeArea(
              child: Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: const EdgeInsets.only(right: 8, top: 4),
                  child: TextButton(
                    onPressed: onDone,
                    child: const Text(
                      'Skip',
                      style: TextStyle(
                          color: Color(0xFF45617D),
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Screens ──────────────────────────────────────────────────────────────────

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFFD7CCC8),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.pets, size: 64, color: Color(0xFF45617D)),
            SizedBox(height: 24),
            CircularProgressIndicator(color: Color(0xFF8B947E)),
          ],
        ),
      ),
    );
  }
}

class _LoadingHomeScreen extends StatelessWidget {
  const _LoadingHomeScreen();

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