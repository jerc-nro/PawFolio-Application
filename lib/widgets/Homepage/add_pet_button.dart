import 'package:flutter/material.dart';


class AddPetButton extends StatelessWidget {
  const AddPetButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 64, height: 64,
      decoration: const BoxDecoration(
        color: Color(0xFFB5714A),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 4)),
        ],
      ),
      child: const Icon(Icons.add, color: Colors.white, size: 36),
    );
  }
}