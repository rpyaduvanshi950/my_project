import 'dart:io';

class Validators {
  // Validate phone number (flexible format)
  static String? validatePhone(String? value) {
    if (value == null || value.isEmpty) {
      return 'Phone number is required';
    }

    // Remove common separators and spaces
    final cleaned = value.replaceAll(RegExp(r'[\s\-\(\)\.]'), '');

    // Check if it contains only digits and optional + at start
    if (!RegExp(r'^\+?[0-9]{7,15}$').hasMatch(cleaned)) {
      return 'Please enter a valid phone number';
    }

    return null;
  }

  // Validate date of birth (must be at least 13 years old)
  static String? validateDateOfBirth(DateTime? date) {
    if (date == null) {
      return 'Date of birth is required';
    }

    final now = DateTime.now();
    final age = now.year - date.year;

    // Check if birthday has passed this year
    final hasBirthdayPassed = now.month > date.month ||
        (now.month == date.month && now.day >= date.day);

    final actualAge = hasBirthdayPassed ? age : age - 1;

    if (actualAge < 13) {
      return 'You must be at least 13 years old';
    }

    if (date.isAfter(now)) {
      return 'Date of birth cannot be in the future';
    }

    return null;
  }

  // Validate photo file
  static String? validatePhoto(File? file) {
    if (file == null) {
      return 'Photo is required';
    }

    // Check file extension
    final extension = file.path.toLowerCase().split('.').last;
    if (extension != 'jpg' && extension != 'jpeg' && extension != 'png') {
      return 'Photo must be in JPG or PNG format';
    }

    // Check file size (5MB = 5 * 1024 * 1024 bytes)
    final fileSize = file.lengthSync();
    const maxSize = 5 * 1024 * 1024; // 5MB

    if (fileSize > maxSize) {
      return 'Photo size must be less than 5MB';
    }

    return null;
  }

  // Validate name
  static String? validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Name is required';
    }

    if (value.trim().length < 2) {
      return 'Name must be at least 2 characters';
    }

    return null;
  }

  // Validate email
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }

    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );

    if (!emailRegex.hasMatch(value)) {
      return 'Please enter a valid email address';
    }

    return null;
  }
}
