// import 'dart:io';
// import 'package:flutter/material.dart';
// import 'package:intl/intl.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:firebase_storage/firebase_storage.dart';
// import '../models/person_model.dart';
// import '../models/user_model.dart';
// import '../services/firestore_service.dart';
// import '../services/storage_service.dart';
// import '../utils/validators.dart';
// import '../widgets/photo_picker_widget.dart';
// import '../widgets/upload_progress_widget.dart';

// class PersonFormScreen extends StatefulWidget {
//   final PersonModel? person;
//   final UserModel user;

//   const PersonFormScreen({
//     super.key,
//     this.person,
//     required this.user,
//   });

//   @override
//   State<PersonFormScreen> createState() => _PersonFormScreenState();
// }

// class _PersonFormScreenState extends State<PersonFormScreen> {
//   final _formKey = GlobalKey<FormState>();
//   final _nameController = TextEditingController();
//   final _emailController = TextEditingController();
//   final _phoneController = TextEditingController();
//   final FirestoreService _firestoreService = FirestoreService();
//   final StorageService _storageService = StorageService();
//   final FirebaseAuth _auth = FirebaseAuth.instance;

//   DateTime? _selectedDate;
//   File? _selectedPhoto;
//   String? _currentPhotoUrl;
//   bool _isLoading = false;
//   UploadTask? _uploadTask;
//   bool _isEditMode = false;

//   @override
//   void initState() {
//     super.initState();
//     _isEditMode = widget.person != null;
//     if (_isEditMode) {
//       final person = widget.person!;
//       _nameController.text = person.name;
//       _emailController.text = person.email;
//       _phoneController.text = person.phone;
//       _selectedDate = person.dateOfBirth;
//       _currentPhotoUrl = person.photoUrl;
//     }
//   }

//   @override
//   void dispose() {
//     _nameController.dispose();
//     _emailController.dispose();
//     _phoneController.dispose();
//     super.dispose();
//   }

//   Future<void> _selectDate(BuildContext context) async {
//     final DateTime? picked = await showDatePicker(
//       context: context,
//       initialDate: _selectedDate ?? DateTime.now().subtract(const Duration(days: 365 * 18)),
//       firstDate: DateTime(1900),
//       lastDate: DateTime.now(),
//       helpText: 'Select Date of Birth',
//     );

//     if (picked != null) {
//       setState(() {
//         _selectedDate = picked;
//       });
//     }
//   }

//   Future<void> _savePerson() async {
//     if (!_formKey.currentState!.validate()) {
//       return;
//     }

//     if (_selectedDate == null) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Please select date of birth')),
//       );
//       return;
//     }

//     final validationError = Validators.validateDateOfBirth(_selectedDate);
//     if (validationError != null) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text(validationError)),
//       );
//       return;
//     }

//     // Check limit for new person
//     if (!_isEditMode) {
//       final remainingSlots = 150 - widget.user.peopleCount;
//       if (remainingSlots <= 0) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(
//             content: Text('Maximum limit of 150 people reached'),
//             backgroundColor: Colors.red,
//           ),
//         );
//         return;
//       }
//     }

//     setState(() {
//       _isLoading = true;
//     });

//     try {
//       String? photoUrl = _currentPhotoUrl;
//       String personId = widget.person?.id ?? '';

//       if (_isEditMode) {
//         // Update existing person
//         if (_selectedPhoto != null) {
//           // Delete old photo if exists
//           if (_currentPhotoUrl != null && widget.person?.id != null) {
//             await _storageService.deletePersonPhoto(widget.person!.id!);
//           }

//           _uploadTask = _storageService.uploadPersonPhotoWithProgress(
//             _selectedPhoto!,
//             widget.person!.id!,
//           );
//           setState(() {});

//           await _uploadTask!;
//           photoUrl = await _storageService.uploadPersonPhoto(
//             _selectedPhoto!,
//             widget.person!.id!,
//           );
//         }

//         final updatedPerson = widget.person!.copyWith(
//           name: _nameController.text.trim(),
//           email: _emailController.text.trim(),
//           phone: _phoneController.text.trim(),
//           dateOfBirth: _selectedDate,
//           photoUrl: photoUrl,
//         );

//         await _firestoreService.updatePerson(
//           _auth.currentUser!.uid,
//           updatedPerson,
//         );
//       } else {
//         // Create new person
//         final newPerson = PersonModel(
//           name: _nameController.text.trim(),
//           email: _emailController.text.trim(),
//           phone: _phoneController.text.trim(),
//           dateOfBirth: _selectedDate!,
//         );

//         // Add person with transaction (enforces limit)
//         personId = await _firestoreService.addPerson(
//           _auth.currentUser!.uid,
//           newPerson,
//         );

//         // Upload photo if selected
//         if (_selectedPhoto != null) {
//           _uploadTask = _storageService.uploadPersonPhotoWithProgress(
//             _selectedPhoto!,
//             personId,
//           );
//           setState(() {});

//           await _uploadTask!;
//           photoUrl = await _storageService.uploadPersonPhoto(
//             _selectedPhoto!,
//             personId,
//           );

//           // Update person with photo URL
//           final personWithPhoto = newPerson.copyWith(
//             id: personId,
//             photoUrl: photoUrl,
//           );
//           await _firestoreService.updatePerson(
//             _auth.currentUser!.uid,
//             personWithPhoto,
//           );
//         }
//       }

//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text(
//               _isEditMode
//                   ? 'Person updated successfully'
//                   : 'Person added successfully',
//             ),
//             backgroundColor: Colors.green,
//           ),
//         );
//         Navigator.pop(context, true);
//       }
//     } catch (e) {
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text(
//               'Failed to ${_isEditMode ? 'update' : 'add'} person: ${e.toString()}',
//             ),
//             backgroundColor: Colors.red,
//           ),
//         );
//       }
//     } finally {
//       if (mounted) {
//         setState(() {
//           _isLoading = false;
//           _uploadTask = null;
//         });
//       }
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     final remainingSlots = 150 - widget.user.peopleCount;

//     return Scaffold(
//       appBar: AppBar(
//         title: Text(_isEditMode ? 'Edit Person' : 'Add Person'),
//       ),
//       body: SingleChildScrollView(
//         padding: const EdgeInsets.all(24.0),
//         child: Form(
//           key: _formKey,
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.stretch,
//             children: [
//               if (!_isEditMode) ...[
//                 Container(
//                   padding: const EdgeInsets.all(12),
//                   decoration: BoxDecoration(
//                     color: remainingSlots > 0 ? Colors.blue[50] : Colors.orange[50],
//                     borderRadius: BorderRadius.circular(8),
//                   ),
//                   child: Row(
//                     children: [
//                       Icon(
//                         remainingSlots > 0 ? Icons.info_outline : Icons.warning,
//                         color: remainingSlots > 0 ? Colors.blue : Colors.orange,
//                       ),
//                       const SizedBox(width: 8),
//                       Expanded(
//                         child: Text(
//                           remainingSlots > 0
//                               ? '$remainingSlots slots remaining'
//                               : 'Maximum limit reached',
//                           style: TextStyle(
//                             fontWeight: FontWeight.w500,
//                             color: remainingSlots > 0
//                                 ? Colors.blue[900]
//                                 : Colors.orange[900],
//                           ),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//                 const SizedBox(height: 16),
//               ],
//               PhotoPickerWidget(
//                 initialPhoto: _selectedPhoto,
//                 onPhotoSelected: (file) {
//                   setState(() {
//                     _selectedPhoto = file;
//                   });
//                 },
//                 label: 'Photo',
//               ),
//               if (_currentPhotoUrl != null && _selectedPhoto == null) ...[
//                 const SizedBox(height: 8),
//                 Text(
//                   'Current photo',
//                   style: Theme.of(context).textTheme.bodySmall,
//                 ),
//                 const SizedBox(height: 8),
//                 ClipRRect(
//                   borderRadius: BorderRadius.circular(8),
//                   child: Image.network(
//                     _currentPhotoUrl!,
//                     height: 120,
//                     width: 120,
//                     fit: BoxFit.cover,
//                     errorBuilder: (context, error, stackTrace) {
//                       return Container(
//                         height: 120,
//                         width: 120,
//                         color: Colors.grey[300],
//                         child: const Icon(Icons.error),
//                       );
//                     },
//                   ),
//                 ),
//               ],
//               const SizedBox(height: 24),
//               TextFormField(
//                 controller: _nameController,
//                 decoration: const InputDecoration(
//                   labelText: 'Name',
//                   border: OutlineInputBorder(),
//                   prefixIcon: Icon(Icons.person),
//                 ),
//                 validator: Validators.validateName,
//                 textCapitalization: TextCapitalization.words,
//               ),
//               const SizedBox(height: 16),
//               TextFormField(
//                 controller: _emailController,
//                 decoration: const InputDecoration(
//                   labelText: 'Email',
//                   border: OutlineInputBorder(),
//                   prefixIcon: Icon(Icons.email),
//                 ),
//                 keyboardType: TextInputType.emailAddress,
//                 validator: Validators.validateEmail,
//               ),
//               const SizedBox(height: 16),
//               TextFormField(
//                 controller: _phoneController,
//                 decoration: const InputDecoration(
//                   labelText: 'Phone Number',
//                   border: OutlineInputBorder(),
//                   prefixIcon: Icon(Icons.phone),
//                 ),
//                 keyboardType: TextInputType.phone,
//                 validator: Validators.validatePhone,
//               ),
//               const SizedBox(height: 16),
//               InkWell(
//                 onTap: () => _selectDate(context),
//                 child: InputDecorator(
//                   decoration: const InputDecoration(
//                     labelText: 'Date of Birth',
//                     border: OutlineInputBorder(),
//                     prefixIcon: Icon(Icons.calendar_today),
//                   ),
//                   child: Text(
//                     _selectedDate == null
//                         ? 'Select date'
//                         : DateFormat('MMM dd, yyyy').format(_selectedDate!),
//                     style: TextStyle(
//                       color: _selectedDate == null
//                           ? Colors.grey[600]
//                           : Colors.black87,
//                     ),
//                   ),
//                 ),
//               ),
//               if (_uploadTask != null) ...[
//                 const SizedBox(height: 16),
//                 UploadProgressWidget(
//                   task: _uploadTask!,
//                   label: 'Uploading photo',
//                 ),
//               ],
//               const SizedBox(height: 32),
//               SizedBox(
//                 height: 50,
//                 child: ElevatedButton(
//                   onPressed: _isLoading ? null : _savePerson,
//                   child: _isLoading
//                       ? const SizedBox(
//                           height: 20,
//                           width: 20,
//                           child: CircularProgressIndicator(
//                             strokeWidth: 2,
//                             valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
//                           ),
//                         )
//                       : Text(_isEditMode ? 'Update Person' : 'Add Person'),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/person_model.dart';
import '../models/user_model.dart';
import '../services/firestore_service.dart';
import '../services/storage_service.dart';
import '../utils/validators.dart';
import '../widgets/photo_picker_widget.dart';
import '../widgets/upload_progress_widget.dart';

class PersonFormScreen extends StatefulWidget {
  final PersonModel? person;
  final UserModel user;

  const PersonFormScreen({
    super.key,
    this.person,
    required this.user,
  });

  @override
  State<PersonFormScreen> createState() => _PersonFormScreenState();
}

class _PersonFormScreenState extends State<PersonFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final FirestoreService _firestoreService = FirestoreService();
  final StorageService _storageService = StorageService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  DateTime? _selectedDate;
  File? _selectedPhoto;
  String? _currentPhotoUrl;
  bool _isLoading = false;
  UploadTask? _uploadTask;
  bool _isEditMode = false;

  @override
  void initState() {
    super.initState();
    _isEditMode = widget.person != null;

    if (_isEditMode) {
      final person = widget.person!;
      _nameController.text = person.name;
      _emailController.text = person.email;
      _phoneController.text = person.phone;
      _selectedDate = person.dateOfBirth;
      _currentPhotoUrl = person.photoUrl;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now().subtract(const Duration(days: 365 * 18)),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      helpText: 'Select Date of Birth',
    );

    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _savePerson() async {
    if (!_formKey.currentState!.validate()) return;

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

    // Check limit (only for adding new)
    if (!_isEditMode) {
      final remainingSlots = 150 - widget.user.peopleCount;
      if (remainingSlots <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Maximum limit of 150 people reached'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    }

    setState(() => _isLoading = true);

    try {
      String? photoUrl = _currentPhotoUrl;
      String personId = widget.person?.id ?? '';

      if (_isEditMode) {
        // UPDATE PERSON
        if (_selectedPhoto != null) {
          if (_currentPhotoUrl != null) {
            await _storageService.deletePersonPhoto(widget.person!.id!);
          }

          _uploadTask = _storageService.uploadPersonPhotoWithProgress(
            _selectedPhoto!,
            widget.person!.id!,
          );
          setState(() {});

          await _uploadTask!;
          photoUrl = await _storageService.uploadPersonPhoto(
            _selectedPhoto!,
            widget.person!.id!,
          );
        }

        final updated = widget.person!.copyWith(
          name: _nameController.text.trim(),
          email: _emailController.text.trim(),
          phone: _phoneController.text.trim(),
          dateOfBirth: _selectedDate,
          photoUrl: photoUrl,
        );

        await _firestoreService.updatePerson(
          _auth.currentUser!.uid,
          updated,
        );
      } else {
        // ADD NEW PERSON
        final newPerson = PersonModel(
          name: _nameController.text.trim(),
          email: _emailController.text.trim(),
          phone: _phoneController.text.trim(),
          dateOfBirth: _selectedDate!,
        );

        personId = await _firestoreService.addPerson(
          _auth.currentUser!.uid,
          newPerson,
        );

        if (_selectedPhoto != null) {
          _uploadTask = _storageService.uploadPersonPhotoWithProgress(
            _selectedPhoto!,
            personId,
          );
          setState(() {});

          await _uploadTask!;
          photoUrl = await _storageService.uploadPersonPhoto(
            _selectedPhoto!,
            personId,
          );

          final updated = newPerson.copyWith(id: personId, photoUrl: photoUrl);
          await _firestoreService.updatePerson(
            _auth.currentUser!.uid,
            updated,
          );
        }
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isEditMode
              ? 'Person updated successfully'
              : 'Person added successfully'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed: ${e.toString()}'),
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
    final remainingSlots = 150 - widget.user.peopleCount;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditMode ? 'Edit Person' : 'Add Person'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // --------------------------------------------------------
              // SIDE-BY-SIDE CURRENT PHOTO + PHOTO PICKER
              // --------------------------------------------------------
              if (_isEditMode)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // LEFT – Current photo
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Current Photo",
                            style: Theme.of(context).textTheme.bodySmall),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.network(
                            _currentPhotoUrl ?? "",
                            height: 120,
                            width: 120,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              height: 120,
                              width: 120,
                              color: Colors.grey[300],
                              child: const Icon(Icons.error),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(width: 18),

                    // RIGHT – Edit / New Photo Picker (expands)
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          PhotoPickerWidget(
                            initialPhoto: _selectedPhoto,
                            onPhotoSelected: (file) {
                              setState(() => _selectedPhoto = file);
                            },
                            label: "Edit Photo",
                          ),
                          if (_selectedPhoto != null)
                            const SizedBox(height: 6),
                          if (_selectedPhoto != null)
                            Text("New photo selected",
                                style: Theme.of(context).textTheme.bodySmall),
                        ],
                      ),
                    ),
                  ],
                )
              else
                // ADD MODE – only photo picker
                PhotoPickerWidget(
                  initialPhoto: _selectedPhoto,
                  onPhotoSelected: (file) {
                    setState(() => _selectedPhoto = file);
                  },
                  label: "Photo",
                ),

              const SizedBox(height: 20),

              if (!_isEditMode)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: remainingSlots > 0 ? Colors.blue[50] : Colors.orange[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        remainingSlots > 0 ? Icons.info_outline : Icons.warning,
                        color: remainingSlots > 0 ? Colors.blue : Colors.orange,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          remainingSlots > 0
                              ? '$remainingSlots slots remaining'
                              : 'Maximum limit reached',
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            color: remainingSlots > 0
                                ? Colors.blue[900]
                                : Colors.orange[900],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              if (_uploadTask != null) ...[
                const SizedBox(height: 20),
                UploadProgressWidget(
                  task: _uploadTask!,
                  label: 'Uploading photo',
                ),
              ],

              const SizedBox(height: 20),

              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Name',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
                validator: Validators.validateName,
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.email),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: Validators.validateEmail,
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

              const SizedBox(height: 32),

              SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _savePerson,
                  child: _isLoading
                      ? const CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        )
                      : Text(_isEditMode ? 'Update Person' : 'Add Person'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
