import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../constants/app_constants.dart';
import '../../models/rental.dart';
import '../../providers/rentals_provider.dart';
import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';
import '../../services/cloudinary_service.dart';

class EditRentalScreen extends StatefulWidget {
  final RentalModel rental;

  const EditRentalScreen({super.key, required this.rental});

  @override
  State<EditRentalScreen> createState() => _EditRentalScreenState();
}

class _EditRentalScreenState extends State<EditRentalScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _itemNameController;
  late TextEditingController _descriptionController;
  late TextEditingController _rentPriceController;

  late String? _selectedCategory;
  late String? _selectedBarangay;
  late String _selectedCondition;
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
    // Pre-fill with existing rental data
    _itemNameController = TextEditingController(text: widget.rental.itemName);
    _descriptionController =
        TextEditingController(text: widget.rental.description);
    _rentPriceController =
        TextEditingController(text: widget.rental.rentPrice.toStringAsFixed(0));
    _selectedCategory = widget.rental.category;
    _selectedBarangay = widget.rental.barangay;
    _selectedCondition = widget.rental.condition;
    _isAvailable = widget.rental.isAvailable;
  }

  @override
  void dispose() {
    _itemNameController.dispose();
    _descriptionController.dispose();
    _rentPriceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final rentalsProvider = context.watch<RentalsProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Rental', style: TextStyle(color: Colors.white)),
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
              // Availability card at top
              _buildAvailabilityCard(),
              const SizedBox(height: 24),

              // Item name field
              TextFormField(
                controller: _itemNameController,
                decoration: const InputDecoration(
                  labelText: 'Item Name *',
                  hintText: 'e.g., Power Drill, Folding Tables',
                  prefixIcon: Icon(Icons.inventory_2),
                ),
                textCapitalization: TextCapitalization.sentences,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter an item name';
                  }
                  if (value.trim().length < 3) {
                    return 'Name must be at least 3 characters';
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
                items: rentalsProvider.categories.map((cat) {
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
                  hintText: 'Describe the item, what it includes, any rules...',
                  prefixIcon: Icon(Icons.description),
                  alignLabelWithHint: true,
                ),
                maxLines: 4,
                textCapitalization: TextCapitalization.sentences,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a description';
                  }
                  if (value.trim().length < 15) {
                    return 'Description must be at least 15 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Rent price field
              TextFormField(
                controller: _rentPriceController,
                decoration: const InputDecoration(
                  labelText: 'Rent Price (PHP per day) *',
                  hintText: 'e.g., 100',
                  prefixIcon: Icon(Icons.payments),
                  prefixText: kCurrencySymbol,
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a rent price';
                  }
                  final price = double.tryParse(value);
                  if (price == null || price <= 0) {
                    return 'Please enter a valid price';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Condition dropdown
              DropdownButtonFormField<String>(
                value: _selectedCondition,
                decoration: const InputDecoration(
                  labelText: 'Item Condition *',
                  prefixIcon: Icon(Icons.star_outline),
                ),
                isExpanded: true,
                items: RentalsProvider.conditionOptions.map((cond) {
                  return DropdownMenuItem(value: cond, child: Text(cond));
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedCondition = value;
                    });
                  }
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
                      : (widget.rental.imageUrls.isNotEmpty
                          ? Image.network(
                              widget.rental.imageUrls.first,
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
        color: _isAvailable ? Colors.green.shade50 : Colors.orange.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _isAvailable ? Colors.green.shade300 : Colors.orange.shade300,
        ),
      ),
      child: Row(
        children: [
          Icon(
            _isAvailable ? Icons.check_circle : Icons.pending,
            color: _isAvailable ? Colors.green : Colors.orange,
            size: 32,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isAvailable ? 'Available' : 'Rented Out',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: _isAvailable
                        ? Colors.green.shade700
                        : Colors.orange.shade700,
                  ),
                ),
                Text(
                  _isAvailable
                      ? 'Others can request to rent this item'
                      : 'Item is currently rented out',
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
        'itemName': _itemNameController.text.trim(),
        'description': _descriptionController.text.trim(),
        'category': _selectedCategory!,
        'rentPrice': double.parse(_rentPriceController.text.trim()),
        'barangay': _selectedBarangay!,
        'condition': _selectedCondition,
        'isAvailable': _isAvailable,
        'updatedAt': Timestamp.now(),
      };

      if (_newImageBytes != null) {
        final url = await _cloudinaryService.uploadImage(
          _newImageBytes!,
          'barangay_rentals',
          'rental_${DateTime.now().millisecondsSinceEpoch}',
        );
        if (url != null) {
          updates['imageUrls'] = [url];
        }
      }

      await context
          .read<RentalsProvider>()
          .updateRental(widget.rental.id, updates);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Rental updated successfully!'),
            backgroundColor: kPrimaryColor,
          ),
        );
        // Pop twice to return to rentals list
        Navigator.pop(context);
        Navigator.pop(context);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating rental: $e')),
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
