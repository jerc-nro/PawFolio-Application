import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class PickerService {
  static final ImagePicker _picker = ImagePicker();

  static Future<String?> pickImageAsBase64() async {
    try {
      final XFile? xFile = await pickPetPhoto();
      if (xFile == null) return null;
      final bytes = await xFile.readAsBytes();
      return base64Encode(bytes);
    } catch (e) {
      rethrow;
    }
  }

  static Future<XFile?> pickPetPhoto() async {
    try {
      final XFile? picked = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
        maxWidth: 500,
      );
      return picked;
    } catch (e) {
      // Recover lost data after activity recreation (Android)
      final LostDataResponse response = await _picker.retrieveLostData();
      if (!response.isEmpty && response.file != null) {
        return response.file;
      }
      return null;
    }
  }

  static Future<DateTime?> pickDate(
      BuildContext context, Color primaryColor) async {
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