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

class ProfileScreen extends StatefulWidget {
  final UserModel user;

  const ProfileScreen({
    super.key,
    required this.user,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final FirestoreService _firestoreService = FirestoreService();
  final StorageService _storageService = StorageService();

  DateTime? _selectedDate;
  File? _selectedPhoto;
  String? _currentPhotoUrl;
  bool _isLoading = false;
  UploadTask? _uploadTask;

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.user.name;
    _phoneController.text = widget.user.phone;
    _selectedDate = widget.user.dateOfBirth;
    _currentPhotoUrl = widget.user.photoUrl;
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
      initialDate: _selectedDate ?? DateTime.now().subtract(const Duration(days: 365 * 18)),
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

  Future<void> _saveProfile() async {
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

    setState(() {
      _isLoading = true;
    });

    try {
      String? photoUrl = _currentPhotoUrl;

      // Upload new photo if selected
      if (_selectedPhoto != null) {
        // Delete old photo if exists
        if (_currentPhotoUrl != null) {
          await _storageService.deleteProfilePhoto();
        }

        _uploadTask = _storageService.uploadProfilePhotoWithProgress(_selectedPhoto!);
        setState(() {});

        await _uploadTask!;
        photoUrl = await _storageService.uploadProfilePhoto(_selectedPhoto!);
      }

      // Update user document
      final updatedUser = widget.user.copyWith(
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        dateOfBirth: _selectedDate,
        photoUrl: photoUrl,
      );

      await _firestoreService.updateUser(updatedUser);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, updatedUser);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update profile: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
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
        title: const Text('Edit Profile'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              PhotoPickerWidget(
                initialPhoto: _selectedPhoto,
                onPhotoSelected: (file) {
                  setState(() {
                    _selectedPhoto = file;
                    if (file == null && _currentPhotoUrl != null) {
                      // User removed photo, keep current URL for now
                    }
                  });
                },
                label: 'Profile Photo',
              ),
              if (_currentPhotoUrl != null && _selectedPhoto == null) ...[
                const SizedBox(height: 8),
                Text(
                  'Current photo',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    _currentPhotoUrl!,
                    height: 120,
                    width: 120,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        height: 120,
                        width: 120,
                        color: Colors.grey[300],
                        child: const Icon(Icons.error),
                      );
                    },
                  ),
                ),
              ],
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
                  onPressed: _isLoading ? null : _saveProfile,
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text('Save Changes'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

