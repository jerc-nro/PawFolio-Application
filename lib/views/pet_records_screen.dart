import 'package:flutter/material.dart';

class InformationView extends StatelessWidget {
  const InformationView({super.key});

  @override
  Widget build(BuildContext context) {
    // Kinukuha ang screen size dynamically
    final screenSize = MediaQuery.of(context).size;
    
    const Color cardBlue = Color(0xFF546E7A);
    const Color navBlue = Color(0xFF455A64);

    return Scaffold(
      backgroundColor: const Color(0xFF2D2D2D), 
      body: Center(
        child: Container(
          // Puno ang screen pero may maximum width para sa tablets/web
          width: screenSize.width > 500 ? 400 : screenSize.width,
          height: screenSize.height,
          decoration: BoxDecoration(
            color: const Color(0xFFD7CCC8), 
            // Dynamic border radius: nawawala sa full screen mobile, meron sa centered web
            borderRadius: screenSize.width > 500 
                ? BorderRadius.circular(32) 
                : BorderRadius.zero,
          ),
          child: ClipRRect(
            borderRadius: screenSize.width > 500 
                ? BorderRadius.circular(32) 
                : BorderRadius.zero,
            child: Scaffold(
              backgroundColor: Colors.transparent,
              body: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 25),
                  child: Column(
                    children: [
                      const SizedBox(height: 20),
                      Align(
                        alignment: Alignment.topRight,
                        child: IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const CircleAvatar(
                            backgroundColor: navBlue,
                            child: Icon(Icons.arrow_back, color: Colors.white),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      
                      // Mas maganda kung ito ay nasa lib/widgets/pet_info_card.dart
                      _dummyPetCard("Nero", "Cat | Siamese"),
                      const SizedBox(height: 20),
                      
                      // MEDICAL HISTORY CONTAINER
                      Expanded(
                        child: Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: cardBlue,
                            borderRadius: BorderRadius.circular(25),
                          ),
                          child: Column(
                            children: [
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 15),
                                child: Text(
                                  "Medical History",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.all(15),
                                  decoration: const BoxDecoration(
                                    color: Color(0xFFDED6D3), 
                                    borderRadius: BorderRadius.only(
                                      bottomLeft: Radius.circular(25),
                                      bottomRight: Radius.circular(25),
                                    ),
                                  ),
                                  child: ListView(
                                    physics: const BouncingScrollPhysics(),
                                    children: [
                                      _sectionHeader("Vaccinations"),
                                      _historyItem("Rabies", "01.01.26", false),
                                      _historyItem("FVRCP", "01.01.26", true),
                                      const SizedBox(height: 15),
                                      _sectionHeader("Vet Visits"),
                                      _historyItem("Annual Checkup", "01.01.26", false),
                                      _historyItem("Ear Infection", "01.01.26", false),
                                      const SizedBox(height: 15),
                                      _sectionHeader("Medications"),
                                      _historyItem("Antibiotics", "01.01.26", true),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Helper Widgets (Mainam na ilipat ito sa separate files sa /widgets folder)
  
  Widget _sectionHeader(String title) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF546E7A),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          const Icon(Icons.arrow_circle_right, color: Colors.white, size: 22),
        ],
      ),
    );
  }

  Widget _historyItem(String label, String date, bool isChecked) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.5),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        children: [
          Icon(
            isChecked ? Icons.check_circle : Icons.cancel,
            color: isChecked ? Colors.green : Colors.red,
            size: 28,
          ),
          const SizedBox(width: 12),
          Expanded( // Added expanded para hindi mag-overflow ang text sa maliit na screen
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF455A64), fontSize: 16),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            "DATE: $date",
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF546E7A)),
          ),
        ],
      ),
    );
  }

  Widget _dummyPetCard(String name, String breed) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: const Color(0xFF546E7A),
        borderRadius: BorderRadius.circular(25),
      ),
      child: Row(
        children: [
          Container(
            width: 80, height: 80,
            decoration: BoxDecoration(
              color: const Color(0xFF8D8D76),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: Colors.white, width: 3),
            ),
            child: const Icon(Icons.pets, color: Colors.white, size: 40),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                Text(breed, style: const TextStyle(color: Colors.white70, fontSize: 14)),
                const Text("01.01.2026", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}