import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pawfolio/features/pets/providers/pet_filter_provider.dart';
import '../../../core/category_filter.dart';
import '../../../models/pet_model.dart';
import '../../pets/widgets/home_pets_card.dart';

class PetCategoryDisplay extends StatefulWidget {
  final List<Pet> pets;
  const PetCategoryDisplay({super.key, required this.pets});

  @override
  State<PetCategoryDisplay> createState() => _PetCategoryDisplayState();
}

class _PetCategoryDisplayState extends State<PetCategoryDisplay> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final totalPages = (widget.pets.length / 4).ceil();

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        color: const Color(0xFFCFC5BC),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildHeader(),
          const SizedBox(height: 15),
          _buildGridPage(totalPages),
          if (totalPages > 1) ...[
            const SizedBox(height: 10),
            _buildPaginationDots(totalPages),
          ],
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Consumer(builder: (context, ref, _) {
      final filter = ref.watch(petTypeFilterProvider);
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Categories', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF423D39))),
            Flexible(
              child: CategoryFilter(
                selectedCategory: filter,
                onFilterChanged: (val) {
                  ref.read(petTypeFilterProvider.notifier).state = val;
                  if (_pageController.hasClients) _pageController.jumpToPage(0);
                },
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildGridPage(int totalPages) {
    return SizedBox(
      height: 340,
      child: widget.pets.isEmpty
          ? const Center(child: Text("No pets available", style: TextStyle(color: Color(0xFF423D39))))
          : PageView.builder(
              controller: _pageController,
              itemCount: totalPages,
              onPageChanged: (p) => setState(() => _currentPage = p),
              itemBuilder: (context, pageIndex) {
                final start = pageIndex * 4;
                final end = (start + 4 > widget.pets.length) ? widget.pets.length : start + 4;
                final pageItems = widget.pets.sublist(start, end);

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
    );
  }

  Widget _buildPaginationDots(int totalPages) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(totalPages, (index) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
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
}