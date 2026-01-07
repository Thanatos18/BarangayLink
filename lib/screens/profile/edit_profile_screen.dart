import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloudinary_public/cloudinary_public.dart';
import 'dart:convert';
import 'dart:typed_data';
import '../../constants/app_constants.dart';
import '../../providers/user_provider.dart';
import '../../services/firebase_service.dart';
import '../../widgets/custom_app_bar.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final FirebaseService _firebaseService = FirebaseService();

  late TextEditingController _nameController;
  late TextEditingController _contactController;
  late TextEditingController _bioController;
  String? _selectedBarangay;
  Uint8List? _selectedImageBytes; // Store image as bytes (Universal)
  bool _isLoading = false;
  bool _hasChanges = false;
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage() async {
    try {
      // Pick a smaller image to save space in Firestore (since we aren't using Storage)
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512, // Limit width
        maxHeight: 512, // Limit height
        imageQuality: 70, // Compress quality
      );
      if (image != null) {
        final bytes = await image.readAsBytes();
        setState(() {
          _selectedImageBytes = bytes;
          _hasChanges = true;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error picking image: $e')));
      }
    }
  }

  // Adjusted to return Base64 string instead of Storage URL
  Future<String?> _uploadImage(String userId) async {
    if (_selectedImageBytes == null) return null;

    try {
      final cloudinary =
          CloudinaryPublic('dlsnldb6p', 'my_app_preset', cache: false);

      CloudinaryResponse response = await cloudinary.uploadFile(
        CloudinaryFile.fromBytesData(
          _selectedImageBytes!,
          identifier: userId,
          folder: 'user_profiles',
          resourceType: CloudinaryResourceType.Image,
        ),
      );

      return response.secureUrl;
    } catch (e) {
      throw Exception('Error uploading to Cloudinary: $e');
    }
  }

  @override
  void initState() {
    super.initState();
    final user = Provider.of<UserProvider>(context, listen: false).currentUser;
    _nameController = TextEditingController(text: user?.name ?? '');
    _contactController = TextEditingController(text: user?.contactNumber ?? '');
    _bioController = TextEditingController();
    _selectedBarangay = user?.barangay;

    // Listen for changes
    _nameController.addListener(_onFieldChanged);
    _contactController.addListener(_onFieldChanged);
    _bioController.addListener(_onFieldChanged);
  }

  void _onFieldChanged() {
    if (!_hasChanges) {
      setState(() {
        _hasChanges = true;
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _contactController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(
        title: 'Edit Profile',
        showBackButton: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Profile Avatar Section
              _buildAvatarSection(),
              const SizedBox(height: 32),

              // Name Field
              _buildSectionTitle('Full Name'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  hintText: 'Enter your full name',
                  prefixIcon: Icon(Icons.person),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your name';
                  }
                  if (value.length < 3) {
                    return 'Name must be at least 3 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Contact Number Field
              _buildSectionTitle('Contact Number'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _contactController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  hintText: 'e.g., 09123456789',
                  prefixIcon: Icon(Icons.phone),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your contact number';
                  }
                  if (value.length < 10 || value.length > 11) {
                    return 'Contact number must be 10-11 digits';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Barangay Dropdown
              _buildSectionTitle('Barangay'),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _selectedBarangay,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.location_on),
                ),
                items: tagumBarangays.map((barangay) {
                  return DropdownMenuItem(
                    value: barangay,
                    child: Text(barangay),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedBarangay = value;
                    _hasChanges = true;
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please select your barangay';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Bio Field (Optional)
              _buildSectionTitle('Bio (Optional)'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _bioController,
                maxLines: 3,
                maxLength: 200,
                decoration: const InputDecoration(
                  hintText: 'Tell us about yourself...',
                  prefixIcon: Icon(Icons.info_outline),
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 32),

              // Save Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveChanges,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kPrimaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : const Text(
                          'Save Changes',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 12),

              // Cancel Button
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(color: Colors.grey, fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvatarSection() {
    final user = Provider.of<UserProvider>(context).currentUser;

    return Center(
      child: Column(
        children: [
          Stack(
            children: [
              CircleAvatar(
                radius: 50,
                backgroundColor: kPrimaryColor.withOpacity(0.1),
                backgroundImage: _selectedImageBytes != null
                    ? MemoryImage(_selectedImageBytes!)
                    : (user?.profileImageUrl != null &&
                            user!.profileImageUrl!.isNotEmpty)
                        ? (user.profileImageUrl!.startsWith('data:')
                            ? MemoryImage(
                                base64Decode(
                                  user.profileImageUrl!.split(',').last,
                                ),
                              )
                            : NetworkImage(user.profileImageUrl!)
                                as ImageProvider)
                        : null,
                child:
                    _selectedImageBytes == null && user?.profileImageUrl == null
                        ? Text(
                            (user?.name ?? 'U')[0].toUpperCase(),
                            style: const TextStyle(
                              fontSize: 40,
                              fontWeight: FontWeight.bold,
                              color: kPrimaryColor,
                            ),
                          )
                        : null,
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: kPrimaryColor,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: const Icon(
                      Icons.camera_alt,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextButton(onPressed: _pickImage, child: const Text('Change Photo')),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: 14,
        color: Colors.grey,
      ),
    );
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final user = userProvider.currentUser;

      if (user == null) {
        throw Exception('User not found');
      }

      // Prepare update data
      final updateData = <String, dynamic>{};

      if (_nameController.text.trim() != user.name) {
        updateData['name'] = _nameController.text.trim();
      }
      if (_contactController.text.trim() != user.contactNumber) {
        updateData['contactNumber'] = _contactController.text.trim();
      }
      if (_selectedBarangay != user.barangay) {
        updateData['barangay'] = _selectedBarangay;
      }

      if (updateData.isNotEmpty) {
        await _firebaseService.updateUserProfile(user.uid, updateData);
      }

      // Handle Image Upload independently but part of the save process
      if (_selectedImageBytes != null) {
        final imageUrl = await _uploadImage(user.uid);
        if (imageUrl != null) {
          updateData['profileImageUrl'] = imageUrl;
          // We need to update again if image was uploaded, or do it all in one go.
          // Since we already called update for text fields, let's just update the image now.
          // To be safer and atomic, we should have gathered all data first.
          // But since _uploadImage takes time, let's update it now.
          await _firebaseService.updateUserProfile(user.uid, {
            'profileImageUrl': imageUrl,
          });
        }
      }

      if (updateData.isNotEmpty || _selectedImageBytes != null) {
        // Refresh user data
        await userProvider.refreshUser();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profile updated successfully!'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context);
        }
      } else {
        if (mounted) {
          Navigator.pop(context);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating profile: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}
