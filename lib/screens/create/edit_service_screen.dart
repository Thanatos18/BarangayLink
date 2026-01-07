import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../constants/app_constants.dart';
import '../../models/service.dart';
import '../../providers/services_provider.dart';
import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';
import '../../services/cloudinary_service.dart';

class EditServiceScreen extends StatefulWidget {
  final ServiceModel service;

  const EditServiceScreen({super.key, required this.service});

  @override
  State<EditServiceScreen> createState() => _EditServiceScreenState();
}

class _EditServiceScreenState extends State<EditServiceScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _rateController;
  late TextEditingController _contactController;

  late String? _selectedCategory;
  late String? _selectedBarangay;
  late bool _isAvailable;
  bool _isSubmitting = false;

  Uint8List? _newImageBytes;
  final ImagePicker _picker = ImagePicker();
  final CloudinaryService _cloudinaryService = CloudinaryService();

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 70,
      );
      if (image != null) {
        final bytes = await image.readAsBytes();
        setState(() {
          _newImageBytes = bytes;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error picking image: $e')));
      }
    }
  }

  @override
  void initState() {
    super.initState();
    // Pre-fill with existing service data
    _nameController = TextEditingController(text: widget.service.name);
    _descriptionController =
        TextEditingController(text: widget.service.description);
    _rateController =
        TextEditingController(text: widget.service.rate.toStringAsFixed(0));
    _contactController =
        TextEditingController(text: widget.service.contactNumber);
    _selectedCategory = widget.service.category;
    _selectedBarangay = widget.service.barangay;
    _isAvailable = widget.service.isAvailable;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _rateController.dispose();
    _contactController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final servicesProvider = context.watch<ServicesProvider>();

    return Scaffold(
      appBar: AppBar(
        title:
            const Text('Edit Service', style: TextStyle(color: Colors.white)),
        backgroundColor: kPrimaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Availability toggle at top
              _buildAvailabilityCard(),
              const SizedBox(height: 24),

              // Service name field
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Service Name *',
                  hintText: 'e.g., Home Cleaning Services',
                  prefixIcon: Icon(Icons.home_repair_service),
                ),
                textCapitalization: TextCapitalization.sentences,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a service name';
                  }
                  if (value.trim().length < 5) {
                    return 'Name must be at least 5 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Category dropdown
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                decoration: const InputDecoration(
                  labelText: 'Category *',
                  prefixIcon: Icon(Icons.category),
                ),
                hint: const Text('Select a category'),
                isExpanded: true,
                items: servicesProvider.categories.map((cat) {
                  return DropdownMenuItem(value: cat, child: Text(cat));
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedCategory = value;
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please select a category';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Description field
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description *',
                  hintText: 'Describe your service in detail...',
                  prefixIcon: Icon(Icons.description),
                  alignLabelWithHint: true,
                ),
                maxLines: 5,
                textCapitalization: TextCapitalization.sentences,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a description';
                  }
                  if (value.trim().length < 20) {
                    return 'Description must be at least 20 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Rate field
              TextFormField(
                controller: _rateController,
                decoration: const InputDecoration(
                  labelText: 'Rate (PHP per hour) *',
                  hintText: 'e.g., 150',
                  prefixIcon: Icon(Icons.payments),
                  prefixText: kCurrencySymbol,
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a rate';
                  }
                  final rate = double.tryParse(value);
                  if (rate == null || rate <= 0) {
                    return 'Please enter a valid rate';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Contact number field
              TextFormField(
                controller: _contactController,
                decoration: const InputDecoration(
                  labelText: 'Contact Number *',
                  hintText: 'e.g., 09123456789',
                  prefixIcon: Icon(Icons.phone),
                ),
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a contact number';
                  }
                  if (value.trim().length < 10) {
                    return 'Please enter a valid contact number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Barangay dropdown
              DropdownButtonFormField<String>(
                value: _selectedBarangay,
                decoration: const InputDecoration(
                  labelText: 'Barangay *',
                  prefixIcon: Icon(Icons.location_city),
                ),
                hint: const Text('Select barangay'),
                isExpanded: true,
                items: tagumBarangays.map((brgy) {
                  return DropdownMenuItem(value: brgy, child: Text(brgy));
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedBarangay = value;
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please select a barangay';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              const SizedBox(height: 16),

              // Image Picker
              Text('Reference Image',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.grey[700])),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  height: 150,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: _newImageBytes != null
                      ? Image.memory(
                          _newImageBytes!,
                          fit: BoxFit.cover,
                        )
                      : (widget.service.imageUrls.isNotEmpty
                          ? Image.network(
                              widget.service.imageUrls.first,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  const Center(
                                      child: Icon(Icons.broken_image,
                                          color: Colors.grey)),
                            )
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.add_a_photo,
                                    size: 40, color: Colors.grey),
                                const SizedBox(height: 8),
                                Text('Tap to add photo',
                                    style: TextStyle(color: Colors.grey[600])),
                              ],
                            )),
                ),
              ),
              if (_newImageBytes != null)
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: () => setState(() => _newImageBytes = null),
                    icon: const Icon(Icons.undo, color: Colors.orange),
                    label: const Text('Revert to original',
                        style: TextStyle(color: Colors.orange)),
                  ),
                ),
              const SizedBox(height: 24),

              // Submit button
              ElevatedButton(
                onPressed: _isSubmitting ? null : () => _submitUpdate(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: kPrimaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.save),
                          SizedBox(width: 8),
                          Text(
                            'Save Changes',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
              ),
              const SizedBox(height: 16),

              // Cancel button
              OutlinedButton(
                onPressed: _isSubmitting ? null : () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Cancel'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvailabilityCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _isAvailable ? Colors.green.shade50 : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _isAvailable ? Colors.green.shade300 : Colors.grey.shade300,
        ),
      ),
      child: Row(
        children: [
          Icon(
            _isAvailable ? Icons.check_circle : Icons.cancel,
            color: _isAvailable ? Colors.green : Colors.grey,
            size: 32,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isAvailable ? 'Available' : 'Unavailable',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: _isAvailable
                        ? Colors.green.shade700
                        : Colors.grey.shade700,
                  ),
                ),
                Text(
                  _isAvailable
                      ? 'Customers can book your service'
                      : 'Service is currently unavailable',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: _isAvailable,
            onChanged: (value) {
              setState(() {
                _isAvailable = value;
              });
            },
            activeColor: kPrimaryColor,
          ),
        ],
      ),
    );
  }

  Future<void> _submitUpdate(BuildContext context) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      final updates = <String, dynamic>{
        'name': _nameController.text.trim(),
        'description': _descriptionController.text.trim(),
        'category': _selectedCategory!,
        'rate': double.parse(_rateController.text.trim()),
        'barangay': _selectedBarangay!,
        'contactNumber': _contactController.text.trim(),
        'status': _isAvailable ? 'Available' : 'Unavailable',
        'updatedAt': Timestamp.now(),
      };

      if (_newImageBytes != null) {
        final url = await _cloudinaryService.uploadImage(
          _newImageBytes!,
          'barangay_services',
          'service_${DateTime.now().millisecondsSinceEpoch}',
        );
        if (url != null) {
          updates['imageUrls'] = [url];
        }
      }

      await context
          .read<ServicesProvider>()
          .updateService(widget.service.id, updates);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Service updated successfully!'),
            backgroundColor: kPrimaryColor,
          ),
        );
        // Pop twice to return to services list
        Navigator.pop(context);
        Navigator.pop(context);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating service: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }
}
