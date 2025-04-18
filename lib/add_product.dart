import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class AddProduct extends StatefulWidget {
  const AddProduct({super.key});

  @override
  State<AddProduct> createState() => _AddProductState();
}

class _AddProductState extends State<AddProduct> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _stockCountController = TextEditingController(text: '1');
  final TextEditingController _discountController = TextEditingController();
  File? _selectedImage;
  bool _isUploading = false;

  // Categories as in original code
  final List<String> _categories = ['Games', 'Consoles', 'Accessories', 'Collectibles'];
  String _selectedCategory = 'Games'; // Default category

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  Future<String?> _uploadImage(File image) async {
    try {
      final storageRef = FirebaseStorage.instance.ref();
      final imageRef = storageRef
          .child('product_images/${DateTime.now().millisecondsSinceEpoch}.jpg');
      await imageRef.putFile(image);
      return await imageRef.getDownloadURL();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to upload image: $e')),
      );
      return null;
    }
  }

  void _decrementStock() {
    int currentValue = int.tryParse(_stockCountController.text) ?? 1;
    if (currentValue > 1) {
      setState(() {
        _stockCountController.text = (currentValue - 1).toString();
      });
    }
  }

  void _incrementStock() {
    int currentValue = int.tryParse(_stockCountController.text) ?? 1;
    setState(() {
      _stockCountController.text = (currentValue + 1).toString();
    });
  }

  Future<void> _addProduct() async {
    final name = _nameController.text.trim();
    final price = _priceController.text.trim();
    final description = _descriptionController.text.trim();
    final stockCount = _stockCountController.text.trim();
    final discount = _discountController.text.trim();

    if (name.isEmpty || price.isEmpty || description.isEmpty || stockCount.isEmpty || _selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields and select an image')),
      );
      return;
    }

    setState(() {
      _isUploading = true;
    });

    try {
      // Upload the image and get its URL
      final imageUrl = await _uploadImage(_selectedImage!);
      if (imageUrl == null) return;

      // Add the product to Firestore
      await FirebaseFirestore.instance.collection('products').add({
        'name': name,
        'price': double.parse(price),
        'description': description,
        'stockCount': int.parse(stockCount),
        'category': _selectedCategory,
        'discount': discount.isNotEmpty ? double.parse(discount) : 0.0,
        'imageUrl': imageUrl,
        'createdAt': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Product added successfully!')),
      );

      // Clear the input fields and image
      _nameController.clear();
      _priceController.clear();
      _descriptionController.clear();
      _stockCountController.text = '1';
      _discountController.clear();
      setState(() {
        _selectedImage = null;
        _selectedCategory = 'Games'; // Reset category to default
      });

      // Navigate back to Homepage after adding
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to add product: $e')),
      );
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }

  Widget _buildStockCounter() {
    final screenWidth = MediaQuery.of(context).size.width;

    return Container(
      margin: const EdgeInsets.all(8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(4),
      ),
      child: screenWidth > 600
          ? Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Available Stock',
                  style: TextStyle(
                    color: Colors.white,
                    fontFamily: 'PixelFont',
                    fontSize: 16,
                  ),
                ),
                Row(
                  children: [
                    InkWell(
                      onTap: _decrementStock,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Icon(Icons.remove, color: Colors.white),
                      ),
                    ),
                    Container(
                      width: 60,
                      alignment: Alignment.center,
                      margin: const EdgeInsets.symmetric(horizontal: 8),
                      child: TextField(
                        controller: _stockCountController,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontFamily: 'PixelFont',
                        ),
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ),
                    InkWell(
                      onTap: _incrementStock,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.green,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Icon(Icons.add, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Available Stock',
                  style: TextStyle(
                    color: Colors.white,
                    fontFamily: 'PixelFont',
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    InkWell(
                      onTap: _decrementStock,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Icon(Icons.remove, color: Colors.white),
                      ),
                    ),
                    Container(
                      width: 60,
                      alignment: Alignment.center,
                      margin: const EdgeInsets.symmetric(horizontal: 8),
                      child: TextField(
                        controller: _stockCountController,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontFamily: 'PixelFont',
                        ),
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ),
                    InkWell(
                      onTap: _incrementStock,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.green,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Icon(Icons.add, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ],
            ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text(
          'Add Product',
          style: TextStyle(
            fontFamily: 'PixelFont',
            color: Colors.white,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Game Name Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12),
              color: const Color(0xFF1A1A2E),
              child: Center(
                child: TextField(
                  controller: _nameController,
                  style: const TextStyle(
                    color: Colors.white,
                    fontFamily: 'PixelFont',
                    fontSize: 24,
                  ),
                  decoration: const InputDecoration(
                    hintText: 'Game Name',
                    hintStyle: TextStyle(
                      color: Colors.grey,
                      fontFamily: 'PixelFont',
                    ),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 16),
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image section
                Expanded(
                  flex: 4,
                  child: Container(
                    margin: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black,
                      border: Border.all(color: Colors.white24),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    height: 340,
                    child: InkWell(
                      onTap: _pickImage,
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
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: const [
                                Icon(
                                  Icons.add_photo_alternate,
                                  size: 64,
                                  color: Colors.white38,
                                ),
                                SizedBox(height: 12),
                                Text(
                                  'Select Image',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontFamily: 'PixelFont',
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                ),
                
                // Right column with details
                Expanded(
                  flex: 5,
                  child: Column(
                    children: [
                      // Description Box
                      Container(
                        margin: const EdgeInsets.all(8),
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1A1A2E),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Description',
                              style: TextStyle(
                                color: Colors.white,
                                fontFamily: 'PixelFont',
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextField(
                              controller: _descriptionController,
                              style: const TextStyle(color: Colors.white),
                              maxLines: 4,
                              decoration: const InputDecoration(
                                hintText: 'Enter product description...',
                                hintStyle: TextStyle(color: Colors.grey),
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.all(8),
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      // Category Selection
                      Container(
                        margin: const EdgeInsets.all(8),
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1A1A2E),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Category',
                              style: TextStyle(
                                color: Colors.white,
                                fontFamily: 'PixelFont',
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 8),
                            DropdownButtonFormField<String>(
                              value: _selectedCategory,
                              dropdownColor: const Color(0xFF1A1A2E),
                              decoration: const InputDecoration(
                                filled: true,
                                fillColor: Colors.black54,
                                border: OutlineInputBorder(),
                              ),
                              style: const TextStyle(
                                color: Colors.white,
                                fontFamily: 'PixelFont',
                              ),
                              items: _categories.map((category) {
                                return DropdownMenuItem(
                                  value: category,
                                  child: Text(category),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setState(() {
                                  _selectedCategory = value!;
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                      
                      // Price & Discount
                      Container(
                        margin: const EdgeInsets.all(8),
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1A1A2E),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Text(
                                  'Selling Price',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontFamily: 'PixelFont',
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: TextField(
                                    controller: _priceController,
                                    style: const TextStyle(color: Colors.white),
                                    keyboardType: TextInputType.number,
                                    decoration: const InputDecoration(
                                      hintText: '0.00',
                                      hintStyle: TextStyle(color: Colors.grey),
                                      prefixText: '\$ ',
                                      prefixStyle: TextStyle(color: Colors.green),
                                      border: InputBorder.none,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                const Text(
                                  'Discount',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontFamily: 'PixelFont',
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: TextField(
                                    controller: _discountController,
                                    style: const TextStyle(color: Colors.white),
                                    keyboardType: TextInputType.number,
                                    decoration: const InputDecoration(
                                      hintText: '0',
                                      hintStyle: TextStyle(color: Colors.grey),
                                      suffixText: '%',
                                      suffixStyle: TextStyle(color: Colors.red),
                                      border: InputBorder.none,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      
                      // Available Stock
                      _buildStockCounter(),
                    ],
                  ),
                ),
              ],
            ),
            
            // Add Product Button
            Container(
              margin: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _isUploading ? null : _addProduct,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.pink,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                child: _isUploading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'Add to your store',
                        style: TextStyle(
                          fontFamily: 'PixelFont',
                          fontSize: 18,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}