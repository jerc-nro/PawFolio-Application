import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class PickerService {
  static final ImagePicker _picker = ImagePicker();

  // Logic for picking and validating images
  static Future<File?> pickPetPhoto() async {
    final picked = await _picker.pickImage(
      source: ImageSource.gallery, 
      imageQuality: 85,
      maxWidth: 500, // Memory optimization: prevents loading massive images
    );
    
    if (picked == null) return null;

    final ext = picked.path.split('.').last.toLowerCase();
    if (!['jpg', 'jpeg', 'png'].contains(ext)) {
      throw 'Only JPG or PNG images are allowed.';
    }

    return File(picked.path);
  }

  // Logic for date picking
  static Future<DateTime?> pickDate(BuildContext context, Color primaryColor) async {
    return await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: ColorScheme.light(primary: primaryColor),
        ),
        child: child!,
      ),
    );
  }
}