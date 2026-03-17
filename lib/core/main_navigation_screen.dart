import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../../services/notification_services.dart'; // Ensure this is imported

// Feature imports
import '../../features/home/screens/home_page.dart';
import '../../features/auth/screens/account_screen.dart';
import '../../features/pets/screens/mypets_screen.dart';
import '../../features/records/screen/records_screen.dart';
import 'custom_nav_bar.dart';
import 'quick_add_modal.dart';

// --- PROVIDER ---
class NavigationNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void setIndex(int index) {
    if (state != index) state = index;
  }
}

final navigationIndexProvider = NotifierProvider<NavigationNotifier, int>(() {
  return NavigationNotifier();
});

// --- UI ---

// ... your NavigationNotifier and Provider stay the same ...

class MainNavigationScreen extends ConsumerStatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  ConsumerState<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends ConsumerState<MainNavigationScreen> {
  
  @override
  void initState() {
    super.initState();
    // Trigger the permission check as soon as the main screen loads
    _requestNotificationPermissions();
  }

  Future<void> _requestNotificationPermissions() async {
    // 1. Check if already allowed via your service helper
    final bool isAllowed = await NotificationService.isAllowed();

    if (!isAllowed) {
      // 2. Request permission explicitly for Android
      // This triggers the system dialog "Allow Pawfolio to send notifications?"
      await FlutterLocalNotificationsPlugin()
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedIndex = ref.watch(navigationIndexProvider);

    final List<Widget> pages = [
      const HomePage(),
      const MyPetsScreen(),
      const RecordsScreen(),
      const AccountScreen(),
    ];

    return Scaffold(
      extendBody: true,
      body: IndexedStack(
        index: selectedIndex,
        children: pages,
      ),
      bottomNavigationBar: CustomNavBar(
        selectedIndex: selectedIndex,
        onItemSelected: (index) {
          ref.read(navigationIndexProvider.notifier).setIndex(index);
        },
        onAddPressed: () => QuickAddModal.show(context),
      ),
    );
  }
}