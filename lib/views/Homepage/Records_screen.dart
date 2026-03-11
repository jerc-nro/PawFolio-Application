import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../models/pet_model.dart';
import '../../widgets/pet_info_card.dart'; 
import '../../widgets/Homepage/categories_filter.dart';
import '../pet_detail_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RecordsScreen extends StatefulWidget {
  const RecordsScreen({super.key});

  @override
  State<RecordsScreen> createState() => _RecordsScreenState();
}

class _RecordsScreenState extends State<RecordsScreen> {
  String _filter = 'ALL'; 
  String _searchQuery = ''; 
  String petName = '';

  Stream<QuerySnapshot> get _petsStream {
  final user = FirebaseAuth.instance.currentUser;

  return FirebaseFirestore.instance
      .collection('pets')
      .where('ownerID', isEqualTo: user?.uid) 
      .snapshots();
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFD7CCC8),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 20),
            _buildHeader(), 
            const SizedBox(height: 20),
            _buildSearchBar(),
            const SizedBox(height: 15),
            
            // Reusable Category Filter (Buttons only)
            CategoryFilter(
              onFilterChanged: (val) {
                setState(() {
                  _filter = val; 
                });
              },
            ),
            
            const SizedBox(height: 10),
            
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _petsStream,
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return const Center(child: Text('Something went wrong'));
                  }

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(child: Text('No pets found. Add one!'));
                  }

                  // 1. I-map ang docs papunta sa Pet Model
                  final allPets = snapshot.data!.docs.map((doc) {
                    return Pet.fromFirestore(doc.data() as Map<String, dynamic>);
                  }).toList();

                  // 2. COMBINED FILTER LOGIC: Category + Search (Name OR Type)
                  final filteredPets = allPets.where((p) {
                    // Check Category Filter
                    final matchesCategory = _filter == 'ALL' || p.type.toUpperCase() == _filter;
                    
                    // Check Search Query (Name or Type)
                    final matchesSearch = p.name.toLowerCase().contains(_searchQuery) || 
                                          p.type.toLowerCase().contains(_searchQuery);

                    return matchesCategory && matchesSearch;
                  }).toList();

                  // Display message kung walang nahanap pagkatapos mag-filter
                  if (filteredPets.isEmpty) {
                    return const Center(
                      child: Text('No pets match your search.'),
                    );
                  }

                  // Hanapin ang part ng ListView.builder sa MyPetsScreen mo at palitan ng ganito:

                return ListView.builder(
                  padding: const EdgeInsets.only(top: 10, bottom: 100),
                  itemCount: filteredPets.length,
                  itemBuilder: (context, index) {
                    final pet = filteredPets[index]; // Kunin ang pet object mula sa listahan

                    return PetCard(
                        pet: pet,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => PetDetailScreen(pet: pet),
                            ),
                          );
                        },
                      );
                  },
                );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- UI Helpers ---
  Widget _buildHeader() {
    return const Text(
      'SELECT PET',
      style: TextStyle(
        fontSize: 25,
        fontWeight: FontWeight.bold,
        color: Color(0xFF4A6572),
        letterSpacing: 1.2,
      ),
    );
  }

Widget _buildSearchBar() {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 25),
    child: Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9), // Slightly more opaque for better contrast
        borderRadius: BorderRadius.circular(20), // More rounded for a softer look
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05), // Very subtle shadow
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        onChanged: (value) {
          setState(() {
            _searchQuery = value.trim().toLowerCase();
          });
        },
        style: const TextStyle(fontSize: 14, color: Color(0xFF4A5568)),
        decoration: InputDecoration(
          hintText: 'Search by Name or Type...',
          hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 14),
          prefixIcon: Icon(Icons.search, color: Colors.grey.shade500, size: 20), // Moved to prefix for standard UI
          contentPadding: const EdgeInsets.symmetric(vertical: 15), // Centers text vertically
          border: InputBorder.none, // Removes the standard line/border
          focusedBorder: InputBorder.none,
          enabledBorder: InputBorder.none,
        ),
      ),
    ),
  );
}
}