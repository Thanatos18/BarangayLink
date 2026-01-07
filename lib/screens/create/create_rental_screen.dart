import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_constants.dart';
import '../../models/rental.dart';
import '../../providers/rentals_provider.dart';
import '../../providers/user_provider.dart';
import '../../providers/feedback_provider.dart';
import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';
import '../../services/cloudinary_service.dart';
import '../../widgets/modern_dialog.dart';

class CreateRentalScreen extends StatefulWidget {
  const CreateRentalScreen({super.key});

  @override
  State<CreateRentalScreen> createState() => _CreateRentalScreenState();
}

class _CreateRentalScreenState extends State<CreateRentalScreen> {
  final _formKey = GlobalKey<FormState>();
  final _itemNameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _rentPriceController = TextEditingController();

  String? _selectedCategory;
  String? _selectedBarangay;
  String _selectedCondition = 'Good';
  bool _isAvailable = true;
  bool _isSubmitting = false;

  Uint8List? _selectedImageBytes;
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
          _selectedImageBytes = bytes;
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
    // Pre-fill with user's barangay
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final currentUser = context.read<UserProvider>().currentUser;
      if (currentUser != null) {
        setState(() {
          _selectedBarangay = currentUser.barangay;
        });
      }
    });
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
        title: const Text('List Item for Rent',
            style: TextStyle(color: Colors.white)),
        backgroundColor: kPrimaryColor,
        foregroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Info card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: kPrimaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border:
                      Border.all(color: kPrimaryColor.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, color: kPrimaryColor),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'List your items for rent to earn extra income from your barangay neighbors.',
                        style: TextStyle(color: Colors.grey.shade700),
                      ),
                    ),
                  ],
                ),
              ),
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
              const SizedBox(height: 8),
              // Add custom category option
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () =>
                      _showAddCategoryDialog(context, rentalsProvider),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add New Category'),
                  style: TextButton.styleFrom(
                    foregroundColor: kPrimaryColor,
                  ),
                ),
              ),
              const SizedBox(height: 8),

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
              Text('Reference Image (Optional)',
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
                    image: _selectedImageBytes != null
                        ? DecorationImage(
                            image: MemoryImage(_selectedImageBytes!),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: _selectedImageBytes == null
                      ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.add_a_photo,
                                size: 40, color: Colors.grey),
                            const SizedBox(height: 8),
                            Text('Tap to add photo',
                                style: TextStyle(color: Colors.grey[600])),
                          ],
                        )
                      : null,
                ),
              ),
              if (_selectedImageBytes != null)
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: () => setState(() => _selectedImageBytes = null),
                    icon: const Icon(Icons.delete, color: Colors.red),
                    label: const Text('Remove',
                        style: TextStyle(color: Colors.red)),
                  ),
                ),
              const SizedBox(height: 16),

              // Availability toggle
              SwitchListTile(
                title: const Text('Available for Rent'),
                subtitle: Text(
                  _isAvailable
                      ? 'Others can request to rent this item'
                      : 'Item is currently not available for rent',
                ),
                value: _isAvailable,
                onChanged: (value) {
                  setState(() {
                    _isAvailable = value;
                  });
                },
                activeThumbColor: kPrimaryColor,
              ),
              const SizedBox(height: 24),

              // Submit button
              ElevatedButton(
                onPressed: _isSubmitting ? null : () => _submitRental(context),
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
                          Icon(Icons.add_business),
                          SizedBox(width: 8),
                          Text(
                            'List Item',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddCategoryDialog(
      BuildContext context, RentalsProvider rentalsProvider) {
    final controller = TextEditingController();

    ModernDialog.show(
      context,
      title: 'Add New Category',
      content: TextField(
        controller: controller,
        decoration: const InputDecoration(
          labelText: 'Category Name',
          hintText: 'e.g., Baby Gear',
        ),
        textCapitalization: TextCapitalization.words,
        autofocus: true,
      ),
      primaryButtonText: 'Add',
      onPrimaryPressed: () async {
        final newCategory = controller.text.trim();
        if (newCategory.isNotEmpty) {
          await rentalsProvider.addCategory(newCategory);
          setState(() {
            _selectedCategory = newCategory;
          });
          if (context.mounted) {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Category "$newCategory" added!')),
            );
          }
        }
      },
      secondaryButtonText: 'Cancel',
    );
  }

  Future<void> _submitRental(BuildContext context) async {
    if (!_formKey.currentState!.validate()) return;

    final currentUser = context.read<UserProvider>().currentUser;
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to list an item')),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      List<String> imageUrls = [];
      if (_selectedImageBytes != null) {
        final url = await _cloudinaryService.uploadImage(
          _selectedImageBytes!,
          'barangay_rentals',
          'rental_${DateTime.now().millisecondsSinceEpoch}',
        );
        if (url != null) imageUrls.add(url);
      }

      final rental = RentalModel(
        id: '',
        itemName: _itemNameController.text.trim(),
        description: _descriptionController.text.trim(),
        category: _selectedCategory!,
        rentPrice: double.parse(_rentPriceController.text.trim()),
        ownerId: currentUser.uid,
        ownerName: currentUser.name,
        barangay: _selectedBarangay!,
        condition: _selectedCondition,
        isAvailable: _isAvailable,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        imageUrls: imageUrls,
      );

      await context.read<RentalsProvider>().createRental(rental);

      if (context.mounted) {
        context.read<FeedbackProvider>().refreshUserData(currentUser.uid);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Item listed successfully!'),
            backgroundColor: kPrimaryColor,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error listing item: $e')),
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
