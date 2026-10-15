import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/user_model.dart';
import '../services/firestore_service.dart';
import '../services/storage_service.dart';
import '../utils/validators.dart';
import '../widgets/photo_picker_widget.dart';
import '../widgets/upload_progress_widget.dart';

class OnboardingScreen extends StatefulWidget {
  final String uid;
  final String? displayName;
  final String? email;

  const OnboardingScreen({
    super.key,
    required this.uid,
    this.displayName,
    this.email,
  });

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final FirestoreService _firestoreService = FirestoreService();
  final StorageService _storageService = StorageService();

  DateTime? _selectedDate;
  File? _selectedPhoto;
  bool _isLoading = false;
  UploadTask? _uploadTask;

  @override
  void initState() {
    super.initState();
    if (widget.displayName != null) {
      _nameController.text = widget.displayName!;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 365 * 18)),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      helpText: 'Select Date of Birth',
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select date of birth')),
      );
      return;
    }

    final validationError = Validators.validateDateOfBirth(_selectedDate);
    if (validationError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(validationError)),
      );
      return;
    }

    if (_selectedPhoto == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a photo')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      String? photoUrl;

      // Upload photo with progress
      if (_selectedPhoto != null) {
        _uploadTask = _storageService.uploadProfilePhotoWithProgress(_selectedPhoto!);
        setState(() {});

        await _uploadTask!;
        photoUrl = await _storageService.uploadProfilePhoto(_selectedPhoto!);
      }

      // Create user document
      final user = UserModel(
        uid: widget.uid,
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        dateOfBirth: _selectedDate!,
        photoUrl: photoUrl,
        peopleCount: 0,
      );

      await _firestoreService.createUser(user);

      if (mounted) {
        // Navigation will be handled by auth state listener in main.dart
        // The AuthWrapper will detect the new user and show dashboard
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to complete onboarding: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() {
          _isLoading = false;
          _uploadTask = null;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Complete Your Profile'),
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Welcome to Wish Manager! Let\'s set up your profile',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 32),
              PhotoPickerWidget(
                onPhotoSelected: (file) {
                  setState(() {
                    _selectedPhoto = file;
                  });
                },
                label: 'Profile Photo',
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Full Name',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
                validator: Validators.validateName,
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(
                  labelText: 'Phone Number',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.phone),
                ),
                keyboardType: TextInputType.phone,
                validator: Validators.validatePhone,
              ),
              const SizedBox(height: 16),
              InkWell(
                onTap: () => _selectDate(context),
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Date of Birth',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.calendar_today),
                  ),
                  child: Text(
                    _selectedDate == null
                        ? 'Select date'
                        : DateFormat('MMM dd, yyyy').format(_selectedDate!),
                    style: TextStyle(
                      color: _selectedDate == null
                          ? Colors.grey[600]
                          : Colors.black87,
                    ),
                  ),
                ),
              ),
              if (_uploadTask != null) ...[
                const SizedBox(height: 16),
                UploadProgressWidget(
                  task: _uploadTask!,
                  label: 'Uploading photo',
                ),
              ],
              const SizedBox(height: 32),
              SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitForm,
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text('Complete Setup'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

