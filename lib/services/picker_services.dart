import 'dart:convert'; // Added for base64Encode
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class PickerService {
  static final ImagePicker _picker = ImagePicker();

  /// Picks an image and converts it directly to a Base64 string.
  /// This is the method your AccountScreen is currently trying to call.
  static Future<String?> pickImageAsBase64() async {
    try {
      final XFile? xFile = await pickPetPhoto();
      if (xFile == null) return null;

      final bytes = await xFile.readAsBytes();
      return base64Encode(bytes);
    } catch (e) {
      rethrow; // Pass the error (like "Only JPG/PNG allowed") to the UI
    }
  }

  /// Picks a photo and validates the file extension.
  static Future<XFile?> pickPetPhoto() async {
    final XFile? picked = await _picker.pickImage(
      source: ImageSource.gallery, 
      imageQuality: 80, // Slightly reduced to keep Base64 strings smaller
      maxWidth: 500,
    );
    
    if (picked == null) return null;

    final String fileName = picked.name.toLowerCase();
    if (!fileName.endsWith('.jpg') && 
        !fileName.endsWith('.jpeg') && 
        !fileName.endsWith('.png')) {
      throw 'Only JPG or PNG images are allowed.';
    }

    return picked;
  }

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