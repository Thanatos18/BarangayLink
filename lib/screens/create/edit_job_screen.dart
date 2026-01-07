import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../constants/app_constants.dart';
import '../../models/job.dart';
import '../../providers/jobs_provider.dart';
import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';
import '../../services/cloudinary_service.dart';

class EditJobScreen extends StatefulWidget {
  final JobModel job;

  const EditJobScreen({super.key, required this.job});

  @override
  State<EditJobScreen> createState() => _EditJobScreenState();
}

class _EditJobScreenState extends State<EditJobScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _wageController;
  late TextEditingController _locationController;

  late String? _selectedCategory;
  late String? _selectedBarangay;
  late String _selectedStatus;
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
    // Pre-fill with existing job data
    _titleController = TextEditingController(text: widget.job.title);
    _descriptionController =
        TextEditingController(text: widget.job.description);
    _wageController =
        TextEditingController(text: widget.job.wage.toStringAsFixed(0));
    _locationController = TextEditingController(text: widget.job.location);
    _selectedCategory = widget.job.category;
    _selectedBarangay = widget.job.barangay;
    _selectedStatus = widget.job.status;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _wageController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final jobsProvider = context.watch<JobsProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Job', style: TextStyle(color: Colors.white)),
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
              // Status selector
              _buildStatusSelector(),
              const SizedBox(height: 24),

              // Title field
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Job Title *',
                  hintText: 'e.g., Need Plumber for Pipe Repair',
                  prefixIcon: Icon(Icons.work),
                ),
                textCapitalization: TextCapitalization.sentences,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a job title';
                  }
                  if (value.trim().length < 5) {
                    return 'Title must be at least 5 characters';
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
                items: jobsProvider.categories.map((cat) {
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
                  hintText: 'Describe the job in detail...',
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

              // Wage field
              TextFormField(
                controller: _wageController,
                decoration: const InputDecoration(
                  labelText: 'Wage / Payment (PHP) *',
                  hintText: 'e.g., 500',
                  prefixIcon: Icon(Icons.payments),
                  prefixText: kCurrencySymbol,
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a wage';
                  }
                  final wage = double.tryParse(value);
                  if (wage == null || wage <= 0) {
                    return 'Please enter a valid wage amount';
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
              const SizedBox(height: 16),

              // Location field (optional)
              TextFormField(
                controller: _locationController,
                decoration: const InputDecoration(
                  labelText: 'Specific Location (Optional)',
                  hintText: 'e.g., Near Public Market, Purok 5',
                  prefixIcon: Icon(Icons.place),
                ),
                textCapitalization: TextCapitalization.sentences,
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
                      : (widget.job.imageUrls.isNotEmpty
                          ? Image.network(
                              widget.job.imageUrls.first,
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
              const SizedBox(height: 32),

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

  Widget _buildStatusSelector() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Job Status',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: JobsProvider.jobStatuses.map((status) {
              final isSelected = _selectedStatus == status;
              Color bgColor;
              Color textColor;

              switch (status) {
                case 'Open':
                  bgColor =
                      isSelected ? Colors.green.shade100 : Colors.grey.shade200;
                  textColor =
                      isSelected ? Colors.green.shade700 : Colors.grey.shade600;
                  break;
                case 'In Progress':
                  bgColor = isSelected
                      ? Colors.orange.shade100
                      : Colors.grey.shade200;
                  textColor = isSelected
                      ? Colors.orange.shade700
                      : Colors.grey.shade600;
                  break;
                case 'Completed':
                  bgColor =
                      isSelected ? Colors.blue.shade100 : Colors.grey.shade200;
                  textColor =
                      isSelected ? Colors.blue.shade700 : Colors.grey.shade600;
                  break;
                default:
                  bgColor = Colors.grey.shade200;
                  textColor = Colors.grey.shade600;
              }

              return ChoiceChip(
                label: Text(status),
                selected: isSelected,
                onSelected: (selected) {
                  if (selected) {
                    setState(() {
                      _selectedStatus = status;
                    });
                  }
                },
                backgroundColor: bgColor,
                selectedColor: bgColor,
                labelStyle: TextStyle(
                  color: textColor,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              );
            }).toList(),
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
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'category': _selectedCategory!,
        'wage': double.parse(_wageController.text.trim()),
        'barangay': _selectedBarangay!,
        'location': _locationController.text.trim(),
        'status': _selectedStatus,
        'updatedAt': Timestamp.now(),
      };

      if (_newImageBytes != null) {
        final url = await _cloudinaryService.uploadImage(
          _newImageBytes!,
          'barangay_jobs',
          'job_${DateTime.now().millisecondsSinceEpoch}',
        );
        if (url != null) {
          updates['imageUrls'] = [url];
        }
      }

      await context.read<JobsProvider>().updateJob(widget.job.id, updates);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Job updated successfully!'),
            backgroundColor: kPrimaryColor,
          ),
        );
        // Pop twice to return to jobs list (skip detail screen)
        Navigator.pop(context);
        Navigator.pop(context);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating job: $e')),
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
