import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/pet_model.dart';
import '../widgets/add_grooming.dart';
import '../widgets/stat_filter.dart'; // Ensure this file exists

class GroomingHistoryView extends StatefulWidget {
  final Pet pet; // Accepts the full Pet object

  const GroomingHistoryView({super.key, required this.pet});

  @override
  State<GroomingHistoryView> createState() => _GroomingHistoryViewState();
}

class _GroomingHistoryViewState extends State<GroomingHistoryView> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String _currentFilter = "ALL"; 

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final screenHeight = screenSize.height;
    final screenWidth = screenSize.width;

    const Color navBlue = Color(0xFF455A64);
    const Color accentBeige = Color(0xFFD7CCC8);
    const Color listContainerBeige = Color(0xFFEFEBE9);

    return Scaffold(
      backgroundColor: const Color(0xFF2D2D2D),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: screenWidth * 0.02,
            vertical: screenHeight * 0.01,
          ),
          child: Container(
            decoration: BoxDecoration(
              color: accentBeige,
              borderRadius: BorderRadius.circular(32),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(32),
              child: Column(
                children: [
                  const SizedBox(height: 15),
                  _buildHeader(context, navBlue),
                  
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: screenWidth * 0.06, 
                      vertical: 10
                    ),
                    child: _petProfileCard(widget.pet, screenWidth),
                  ),
                  
                  const SizedBox(height: 10),
                  
                  Expanded(
                    child: Container(
                      width: double.infinity,
                      decoration: const BoxDecoration(
                        color: listContainerBeige,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(40),
                          topRight: Radius.circular(40),
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Column(
                          children: [
                            const SizedBox(height: 20),
                            
                            // Minimalist Filter Widget
                            StatusFilterRow(
                              selectedStatus: _currentFilter,
                              onStatusSelected: (newStatus) {
                                setState(() => _currentFilter = newStatus);
                              },
                            ),

                            const SizedBox(height: 10),

                            Align(
                              alignment: Alignment.centerRight,
                              child: ElevatedButton.icon(
                                onPressed: () => showAddGroomingDialog(
                                  context, 
                                  widget.pet.petID,
                                ),
                                icon: const Icon(Icons.add_circle_outline, size: 20),
                                label: const Text("ADD GROOMING"),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: navBlue,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10)
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 15),
                            Expanded(child: _buildGroomingStream()),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, Color navBlue) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            "GROOMING HISTORY",
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: navBlue,
              letterSpacing: 1.2,
            ),
          ),
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: CircleAvatar(
              backgroundColor: navBlue,
              child: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  Widget _petProfileCard(Pet pet, double screenWidth) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF546E7A),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        children: [
          Container(
            width: screenWidth * 0.20,
            height: screenWidth * 0.20,
            decoration: BoxDecoration(
              color: const Color(0xFF8D8D76),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white, width: 2),
            ),
            child: Icon(Icons.pets, color: Colors.white, size: screenWidth * 0.08),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _profileTextItem("Name", pet.name, 18),
                const SizedBox(height: 4),
                _profileTextItem("Breed", pet.breed, 13),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _profileTextItem(String label, String value, double fontSize) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 9)),
        Text(
          value, 
          style: TextStyle(
            color: Colors.white, 
            fontSize: fontSize, 
            fontWeight: FontWeight.bold
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildGroomingStream() {
    Query query = _firestore
        .collection('pets')
        .doc(widget.pet.petID)
        .collection('groom_visits')
        .orderBy('date_timestamp', descending: true);

    if (_currentFilter != "ALL") {
      query = query.where('status', isEqualTo: _currentFilter);
    }

    return StreamBuilder<QuerySnapshot>(
      stream: query.snapshots(),
      builder: (context, snapshot) {
        // In GroomingHistoryView.dart, find this line:
if (snapshot.hasError) return Center(child: Text("Error: ${snapshot.error}")); 
// Adding ${snapshot.error} will print the REAL reason (like 'Missing Index')
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.data!.docs.isEmpty) {
          return Center(
            child: Text(
              _currentFilter == "ALL" 
                ? "No records found." 
                : "No $_currentFilter records.",
              style: const TextStyle(color: Colors.grey)
            )
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.only(bottom: 20),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            var data = snapshot.data!.docs[index].data() as Map<String, dynamic>;
            
            String status = (data['status'] ?? 'UPCOMING').toString().toUpperCase();
            Color statusColor = status == 'COMPLETED' ? Colors.green : 
                               status == 'ONGOING' ? Colors.red : Colors.orange;

            return _groomingItem(
              type: data['type'] ?? 'N/A',
              date: data['date_string'] ?? 'No Date',
              provider: data['provider'] ?? 'Unknown',
              status: status,
              statusColor: statusColor,
            );
          },
        );
      },
    );
  }

  Widget _groomingItem({
    required String type,
    required String date,
    required String provider,
    required String status,
    required Color statusColor,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF546E7A).withOpacity(0.3), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(type, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: statusColor),
                ),
                child: Text(
                  status,
                  style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const Divider(height: 20),
          Row(
            children: [
              Expanded(child: _infoTile("DATE", date)),
              Expanded(child: _infoTile("CLINIC", provider)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _infoTile(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 9, color: Colors.grey, fontWeight: FontWeight.bold)),
        Text(value, style: const TextStyle(fontSize: 12, color: Color(0xFF455A64))),
      ],
    );
  }
}