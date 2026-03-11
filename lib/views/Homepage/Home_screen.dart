import 'dart:math' as math;
import 'package:cloud_firestore/cloud_firestore.dart'; // Added for Records
import 'package:intl/intl.dart'; // Added for Date Formatting
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../../providers/pet_provider.dart';
import '../../providers/user_provider.dart';
import '../../models/pet_model.dart';
import '../../widgets/navigation_btn.dart';
import '../../widgets/Homepage/pet_card.dart';
import '../../widgets/Homepage/categories_filter.dart';
import '../Homepage/Records_screen.dart';
import '../Homepage/Account_screen.dart';
import '../xaddpet.dart';
import 'MyPets_screen.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  String _filter = 'ALL';
  int _currentPage = 0;
  final PageController _pageController = PageController();

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null && mounted) {
        context.read<PetProvider>().fetchPets(uid);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> _internalPages = [
      _buildHomeContent(),
      const MyPetsScreen(),
      const RecordsScreen(),
      const AccountScreen(),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFE8DDD6),
      body: IndexedStack(
        index: _selectedIndex,
        children: _internalPages,
      ),
      bottomNavigationBar: CustomNavBar(
        selectedIndex: _selectedIndex,
        onItemSelected: (index) {
          setState(() => _selectedIndex = index);
        },
        onAddPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const AddPetPage()));
        },
      ),
    );
  }

  Widget _buildHomeContent() {
    final petProvider = context.watch<PetProvider>();
    final pets = _filteredPets(petProvider.pets);
    final totalPages = (pets.length / 4).ceil();

    return SafeArea(
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            _buildGreetingRow(),
            const SizedBox(height: 24),
            _buildCategoryCard(pets, totalPages),
            const SizedBox(height: 24),
            // --- NEW RECORDS SECTION ---
            _buildUpcomingRecords(),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // --- RECORD LIST LOGIC ---
  Widget _buildUpcomingRecords() {
    final String? uid = FirebaseAuth.instance.currentUser?.uid;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Upcoming Records',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF4A5568),
              ),
            ),
            TextButton(
              onPressed: () => setState(() => _selectedIndex = 2), // Jump to Records tab
              child: const Text("View All", style: TextStyle(color: Color(0xFF4A5568))),
            )
          ],
        ),
        const SizedBox(height: 8),
        StreamBuilder<QuerySnapshot>(
          // Querying grooming visits specifically for this owner
          stream: FirebaseFirestore.instance
              .collection('groom_visits')
              .where('ownerID', isEqualTo: uid)
              .where('status', whereIn: ['Upcoming', 'Ongoing'])
              .orderBy('date_timestamp', descending: false) // Closest date first
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return _buildStatusBox("Query error: Check if Index is created.");
            }
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final docs = snapshot.data?.docs ?? [];

            if (docs.isEmpty) {
              return _buildStatusBox("No upcoming or ongoing records found.");
            }

            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: docs.length,
              itemBuilder: (context, index) {
                final data = docs[index].data() as Map<String, dynamic>;
                return _buildRecordTile(data);
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildRecordTile(Map<String, dynamic> data) {
    DateTime? date;
    if (data['date_timestamp'] is Timestamp) {
      date = (data['date_timestamp'] as Timestamp).toDate();
    }

    String timeText = date != null ? DateFormat('MMM d • hh:mm a').format(date) : 'TBD';
    bool isOngoing = data['status'] == 'Ongoing';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFCFC5BC),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: isOngoing ? Colors.orangeAccent : const Color(0xFF4A5568),
            child: Icon(
              isOngoing ? Icons.sync : Icons.calendar_today,
              color: Colors.white,
              size: 18,
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "${data['petName'] ?? 'Pet'} Grooming",
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF423D39)),
                ),
                Text(
                  timeText,
                  style: TextStyle(color: Colors.black.withOpacity(0.5), fontSize: 12),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: isOngoing ? Colors.orange.withOpacity(0.2) : Colors.black12,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              data['status'].toString().toUpperCase(),
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: isOngoing ? Colors.orange[900] : Colors.black54,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBox(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFCFC5BC).withOpacity(0.5),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Center(
        child: Text(
          message,
          style: const TextStyle(color: Color(0xFF423D39), fontSize: 13),
        ),
      ),
    );
  }

  // --- EXISTING CATEGORY & GREETING UI ---

  List<Pet> _filteredPets(List<Pet> all) {
    if (_filter == 'ALL') return all;
    return all.where((p) => p.type.toUpperCase() == _filter).toList();
  }

  Widget _buildCategoryCard(List<Pet> pets, int totalPages) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        color: const Color(0xFFCFC5BC),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Categories',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF423D39)),
                ),
                Flexible(
                  child: CategoryFilter(
                    onFilterChanged: (val) {
                      setState(() {
                        _filter = val;
                        _currentPage = 0;
                      });
                      if (_pageController.hasClients) {
                        _pageController.jumpToPage(0);
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 15),
          SizedBox(
            height: 340,
            child: pets.isEmpty
                ? const Center(child: Text("No pets available"))
                : PageView.builder(
                    controller: _pageController,
                    itemCount: totalPages,
                    onPageChanged: (p) => setState(() => _currentPage = p),
                    itemBuilder: (context, pageIndex) {
                      final start = pageIndex * 4;
                      final end = (start + 4 > pets.length) ? pets.length : start + 4;
                      final pageItems = pets.sublist(start, end);

                      return GridView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          childAspectRatio: 1.6,
                        ),
                        itemCount: pageItems.length,
                        itemBuilder: (context, i) => PetCard(pet: pageItems[i]),
                      );
                    },
                  ),
          ),
          if (totalPages > 1) ...[
            const SizedBox(height: 10),
            _buildPaginationDots(totalPages),
          ],
        ],
      ),
    );
  }

  Widget _buildPaginationDots(int totalPages) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(totalPages, (index) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: _currentPage == index ? 12 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: _currentPage == index ? const Color(0xFF4A5568) : Colors.white54,
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }

  Widget _buildGreetingRow() {
    final String userName = FirebaseAuth.instance.currentUser?.displayName ?? 'User';
    return Row(
      children: [
        Text(
          'Hi there $userName,',
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF4A5568)),
        ),
        const Spacer(),
        IconButton(
          icon: const Icon(Icons.logout, color: Color(0xFF7B2B2B)),
          onPressed: () => context.read<UserProvider>().logout(),
        ),
      ],
    );
  }
}