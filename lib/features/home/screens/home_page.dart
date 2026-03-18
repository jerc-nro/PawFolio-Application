import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/custom_nav_bar.dart';
import '../../pets/screens/add_pet_page.dart';
import '../../pets/screens/mypets_screen.dart';
import '../../records/screen/records_screen.dart';
import 'home_content.dart';
import '../../auth/screens/account_screen.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const HomeContent(),
    const MyPetsScreen(),
    const RecordsScreen(),
    const AccountScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 235, 222, 205),
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      bottomNavigationBar: CustomNavBar(
        selectedIndex: _selectedIndex,
        onItemSelected: (index) => setState(() => _selectedIndex = index),
        onAddPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AddPetPage()),
        ),
      ),
    );
  }
}