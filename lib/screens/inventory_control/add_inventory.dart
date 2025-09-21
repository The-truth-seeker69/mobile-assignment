import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

class AddInventoryScreen extends StatefulWidget {
  const AddInventoryScreen({super.key});

  @override
  State<AddInventoryScreen> createState() => _AddInventoryScreenState();
}

class _AddInventoryScreenState extends State<AddInventoryScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _itemNameController = TextEditingController();
  final TextEditingController _quantityController =
  TextEditingController(text: '5');
  final TextEditingController _supplierController = TextEditingController();
  final TextEditingController _remarksController = TextEditingController();
  File? _selectedImage;
  final picker = ImagePicker();
  bool _isSaving = false;

  String _selectedCategory = 'Brake';

  final List<String> _categories = [
    'Brake',
    'Engine',
    'Transmission',
    'Electrical',
    'Suspension',
    'Body',
    'Interior',
    'Other'
  ];

  /// Pick image from gallery with improved error handling
  Future<void> _pickImage() async {
    try {
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);

      if (pickedFile != null) {
        setState(() {
          _selectedImage = File(pickedFile.path);
        });
        print("✅ Image selected: ${pickedFile.path}");
      }
    } catch (e) {
      print("❌ Error picking image: $e");
      _showErrorDialog('Image Selection Error', 'Failed to pick image: $e');
    }
  }

  /// Take photo with camera
  Future<void> _takePhoto() async {
    try {
      final pickedFile = await picker.pickImage(source: ImageSource.camera);

      if (pickedFile != null) {
        setState(() {
          _selectedImage = File(pickedFile.path);
        });
        print("✅ Photo taken: ${pickedFile.path}");
      }
    } catch (e) {
      print("❌ Error taking photo: $e");
      _showErrorDialog('Camera Error', 'Failed to take photo: $e');
    }
  }



  /// Save image to local storage with improved error handling
  /// Save image to local storage and return only filename
  Future<String?> _saveImageLocally(File image, String itemId) async {
    try {
      final appDocDir = await getApplicationDocumentsDirectory();
      final fileName = "$itemId${p.extension(image.path)}"; // e.g., IT001.png
      final savedImage = await image.copy('${appDocDir.path}/$fileName');
      return fileName; // ✅ only store filename
    } catch (e) {
      debugPrint("Error saving image locally: $e");
      return null;
    }
  }


  Future<void> _saveItem() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
    });

    try {
      // Generate new item ID
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('inventory')
          .orderBy(FieldPath.documentId, descending: true)
          .limit(1)
          .get();

      String newId = "IT001";
      if (snapshot.docs.isNotEmpty) {
        String lastId = snapshot.docs.first.id;
        int lastNum = int.parse(lastId.substring(2));
        int nextNum = lastNum + 1;
        newId = "IT${nextNum.toString().padLeft(3, '0')}";
      }

      // Save image
      String imagePath;
      if (_selectedImage != null) {
        // Save picked image locally, only store filename
        final savedFileName = await _saveImageLocally(_selectedImage!, newId);
        imagePath = savedFileName ?? '';
      } else {
        // fallback → asset path (you can choose a default for each category)
        imagePath = "assets/inv/default.png";
      }

      // Save to Firestore
      await FirebaseFirestore.instance.collection('inventory').doc(newId).set({
        'itemID': newId,
        'category': _selectedCategory,
        'imagePath': imagePath,
        'isLowStock': int.parse(_quantityController.text.trim()) <= 5,
        'lastRefill': null,
        'name': _itemNameController.text.trim(),
        'quantity': int.parse(_quantityController.text.trim()),
        'supplier': _supplierController.text.trim(),
        'remarks': _remarksController.text.trim(),
        'usageLog': [],
        'createdAt': FieldValue.serverTimestamp(),
      });

      _showSuccessDialog();
    } catch (e) {
      print("❌ Error saving item: $e");
      _showErrorDialog('Save Error', 'Failed to add item: $e');
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Item Added'),
          content: Text(
              '${_itemNameController.text} has been added to inventory successfully.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop();
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Add Item',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image selection section
              const Text(
                'Item Image',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black),
              ),
              const SizedBox(height: 8),

              // Image preview
              Container(
                width: double.infinity,
                height: 200,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: _selectedImage != null
                    ? ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.file(
                    _selectedImage!,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                  ),
                )
                    : Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.image,
                          size: 50, color: Colors.grey[400]),
                      const SizedBox(height: 8),
                      Text(
                        'No image selected',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Image selection buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.photo_library),
                      label: const Text('Gallery'),
                      onPressed: _pickImage,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.camera_alt),
                      label: const Text('Camera'),
                      onPressed: _takePhoto,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Item Name
              _buildFormField(
                label: 'Item Name',
                controller: _itemNameController,
                hintText: 'Enter name',
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter item name';
                  }
                  // Regex: only letters and spaces allowed

                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Quantity
              _buildFormField(
                label: 'Quantity',
                controller: _quantityController,
                hintText: 'Enter quantity',
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter quantity';
                  }
                  if (int.tryParse(value.trim()) == null) {
                    return 'Quantity must be a valid integer';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Supplier Name
              _buildFormField(
                label: 'Supplier Name',
                controller: _supplierController,
                hintText: 'Enter Supplier Name',
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter supplier name';
                  }
                  // Must contain at least 1 letter
                  if (!RegExp(r'^[A-Za-z0-9 ]+$').hasMatch(value.trim())) {
                    return 'Supplier name can only contain letters, numbers, and spaces';
                  }
                  if (!RegExp(r'[A-Za-z]').hasMatch(value.trim())) {
                    return 'Supplier name must include at least one letter';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // Category Dropdown
              _buildDropdownField(),
              const SizedBox(height: 16),

              // Remarks
              _buildFormField(
                label: 'Remarks',
                controller: _remarksController,
                hintText: 'Enter remarks (optional)',
                maxLines: 3,
              ),
              const SizedBox(height: 32),

              // Confirm Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _saveItem,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                      : const Text(
                    'Confirm',
                    style:
                    TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFormField({
    required String label,
    required TextEditingController controller,
    required String hintText,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          validator: validator,
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: const TextStyle(color: Colors.grey),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.black),
            ),
            contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Category',
            style: TextStyle(
                fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black)),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedCategory,
              isExpanded: true,
              icon: const Icon(Icons.keyboard_arrow_down),
              items: _categories.map((String category) {
                return DropdownMenuItem<String>(
                  value: category,
                  child: Text(category),
                );
              }).toList(),
              onChanged: (String? newValue) {
                if (newValue != null) {
                  setState(() {
                    _selectedCategory = newValue;
                  });
                }
              },
            ),
          ),
        ),
      ],
    );
  }
}