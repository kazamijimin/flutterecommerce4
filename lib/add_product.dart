import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Add this import
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'seller_dashboard.dart'; // Import seller dashboard for navigation
import 'profile.dart'; // Import profile for navigation

class AddProduct extends StatefulWidget {
  const AddProduct({super.key});

  @override
  State<AddProduct> createState() => _AddProductState();
}

class _AddProductState extends State<AddProduct> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _stockCountController =
      TextEditingController(text: '1');
  final TextEditingController _discountController = TextEditingController();
  File? _selectedImage;
  bool _isUploading = false;

  List<File> _additionalImages = [];
  bool _isUploadingAdditional = false;
  final int maxAdditionalImages = 10; // Maximum number of additional images allowed

  // Categories as in original code
  final List<String> _categories = [
    'Games',
    'Consoles',
    'Accessories',
    'Collectibles',
    'Action RPG',
    'Turn Based RPG',
    'Visual Novel',
    'Horror',
    'Souls Like',
    'Rogue Like',
    'Puzzle',
    'Open World',
    'MMORPG',
    'Sports',
    'Casual',
    'Slice of Life',
    'Farming Simulator',
    'Card Game',
    'Gacha',
    'Shooting',
  ];
  String _selectedCategory = 'Games'; // Default category

  Future<void> _pickImage() async {
    final pickedFile =
        await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  // Add this method after _pickImage()
  Future<void> _pickAdditionalImages() async {
    try {
      final ImagePicker picker = ImagePicker();
      final List<XFile> images = await picker.pickMultiImage();
      
      if (images.isNotEmpty) {
        setState(() {
          // Add new images while respecting the maximum limit
          final remainingSlots = maxAdditionalImages - _additionalImages.length;
          final imagesToAdd = images.take(remainingSlots).map((x) => File(x.path)).toList();
          _additionalImages.addAll(imagesToAdd);
          
          if (images.length > remainingSlots) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Only $remainingSlots image(s) added. Maximum limit reached.'),
                backgroundColor: Colors.orange,
              ),
            );
          }
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking images: $e')),
      );
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

  // Add this method to upload multiple images
  Future<List<String>> _uploadAdditionalImages() async {
    List<String> urls = [];
    try {
      for (File image in _additionalImages) {
        final storageRef = FirebaseStorage.instance.ref();
        final imageRef = storageRef
            .child('product_additional_images/${DateTime.now().millisecondsSinceEpoch}_${urls.length}.jpg');
        await imageRef.putFile(image);
        String url = await imageRef.getDownloadURL();
        urls.add(url);
      }
      return urls;
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to upload additional images: $e')),
      );
      return [];
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

    if (name.isEmpty ||
        price.isEmpty ||
        description.isEmpty ||
        stockCount.isEmpty ||
        _selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please fill in all fields and select an image')),
      );
      return;
    }

    setState(() {
      _isUploading = true;
      _isUploadingAdditional = true;
    });

    try {
      // Get the current user
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User not logged in');
      }

      // Fetch the store information from the users collection
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (!userDoc.exists) {
        throw Exception('User information not found for user ID: ${user.uid}');
      }

      final userData = userDoc.data();
      final storeName = userData?['storeName'];
      final storeDescription = userData?['storeDescription'];
      final joinDate = userData?['joinDate'];
      final sellerStatus = userData?['sellerStatus'];

      if (storeName == null || storeName.isEmpty) {
        throw Exception('Store name is missing in the user document.');
      }

      if (sellerStatus != 'approved') {
        throw Exception('Your seller application is not approved yet.');
      }

      // Upload the image and get its URL
      final imageUrl = await _uploadImage(_selectedImage!);
      if (imageUrl == null) return;

      // Upload additional images
      final additionalImageUrls = await _uploadAdditionalImages();

      // Add the product to Firestore with additional images
      await FirebaseFirestore.instance.collection('products').add({
        'name': name,
        'price': double.parse(price),
        'description': description,
        'stockCount': int.parse(stockCount),
        'category': _selectedCategory,
        'discount': discount.isNotEmpty ? double.parse(discount) : 0.0,
        'imageUrl': imageUrl,
        'additionalImages': additionalImageUrls,
        'sellerId': user.uid,
        'storeName': storeName,
        'storeDescription': storeDescription,
        'joinDate': joinDate,
        'createdAt': FieldValue.serverTimestamp(),
        'availability': true,
        'archived': false,
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
        _additionalImages.clear();
        _selectedCategory = 'Games'; // Reset category to default
      });

      // Navigate back to the previous screen
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to add product: $e')),
      );
    } finally {
      setState(() {
        _isUploading = false;
        _isUploadingAdditional = false;
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

  Widget _buildAdditionalImagesSection() {
    return Container(
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Additional Images',
                style: TextStyle(
                  color: Colors.white,
                  fontFamily: 'PixelFont',
                  fontSize: 16,
                ),
              ),
              if (_additionalImages.length < maxAdditionalImages)
                TextButton.icon(
                  onPressed: _pickAdditionalImages,
                  icon: const Icon(Icons.add_photo_alternate, color: Colors.pink),
                  label: const Text(
                    'Add Images',
                    style: TextStyle(
                      color: Colors.white,
                      fontFamily: 'PixelFont',
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          if (_additionalImages.isNotEmpty)
            SizedBox(
              height: 100,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _additionalImages.length,
                itemBuilder: (context, index) {
                  return Stack(
                    children: [
                      Container(
                        width: 100,
                        height: 100,
                        margin: const EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.pink.withOpacity(0.5)),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.file(
                            _additionalImages[index],
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      Positioned(
                        top: 4,
                        right: 12,
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _additionalImages.removeAt(index);
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.7),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.close,
                              size: 16,
                              color: Colors.pink,
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            )
          else
            Container(
              width: double.infinity,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.black12,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.withOpacity(0.3)),
              ),
              child: const Center(
                child: Text(
                  'No additional images selected',
                  style: TextStyle(
                    color: Colors.grey,
                    fontFamily: 'PixelFont',
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // Add this method at the start of your _AddProductState class
  bool _isSmallScreen(BuildContext context) {
    return MediaQuery.of(context).size.width < 600;
  }

  // Replace the build method with this responsive layout
  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmall = _isSmallScreen(context);
    
    return Scaffold(
      backgroundColor: Colors.black,
      drawer: Drawer(
        backgroundColor: Colors.black,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.black,
                gradient: LinearGradient(
                  colors: [Colors.black, Colors.pink.withOpacity(0.6)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  const Text(
                    'SELLER PORTAL',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontFamily: 'PixelFont',
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Add your products',
                    style: TextStyle(
                      color: Colors.cyan,
                      fontSize: 14,
                      fontFamily: 'PixelFont',
                    ),
                  ),
                ],
              ),
            ),
            // Existing drawer items...
            ListTile(
              leading: Icon(Icons.dashboard, color: Colors.pink),
              title: const Text(
                'Dashboard',
                style: TextStyle(color: Colors.white, fontFamily: 'PixelFont'),
              ),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const SellerDashboard()),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.add_box, color: Colors.pink),
              title: const Text(
                'Add Product',
                style: TextStyle(color: Colors.white, fontFamily: 'PixelFont'),
              ),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: Icon(Icons.person, color: Colors.pink),
              title: const Text(
                'Profile',
                style: TextStyle(color: Colors.white, fontFamily: 'PixelFont'),
              ),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const ProfileScreen()),
                );
              },
            ),
            const Divider(color: Colors.grey),
            ListTile(
              leading: Icon(Icons.help, color: Colors.pink),
              title: const Text(
                'Help',
                style: TextStyle(color: Colors.white, fontFamily: 'PixelFont'),
              ),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Help section coming soon')),
                );
              },
            ),
          ],
        ),
      ),
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text(
          'Add Product',
          style: TextStyle(
            fontFamily: 'PixelFont',
            color: Colors.white,
          ),
        ),
        iconTheme: IconThemeData(color: Colors.pink),
        actions: [
          TextButton.icon(
            onPressed: _isUploading ? null : _addProduct,
            icon: Icon(Icons.save, color: Colors.pink),
            label: const Text(
              'SAVE',
              style: TextStyle(
                color: Colors.white,
                fontFamily: 'PixelFont',
              ),
            ),
          ),
        ],
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

            // Content Layout - Responsive between row and column
            isSmall
                ? _buildMobileLayout(context)
                : _buildDesktopLayout(context),

            // Add Product Button
            Container(
              margin: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isUploading ? null : _addProduct,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.pink,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 5,
                  shadowColor: Colors.pink.withOpacity(0.5),
                ),
                child: _isUploading
                    ? SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.storefront, color: Colors.white),
                          SizedBox(width: 10),
                          Text(
                            'Add to your store',
                            style: TextStyle(
                              fontFamily: 'PixelFont',
                              fontSize: 18,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Mobile layout - stacked vertically
  Widget _buildMobileLayout(BuildContext context) {
    return Column(
      children: [
        // Image section first
        Container(
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A2E),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.pink.withOpacity(0.2),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Main product image
              Container(
                height: 250, // Smaller height for mobile
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.white24),
                ),
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
                              'Select Main Image',
                              style: TextStyle(
                                color: Colors.white70,
                                fontFamily: 'PixelFont',
                              ),
                            ),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 16),
              // Additional Images Section - Compact for mobile
              _buildResponsiveAdditionalImagesSection(),
            ],
          ),
        ),

        // Details section
        _buildProductDetailsSection(),
      ],
    );
  }

  // Desktop layout - side by side
  Widget _buildDesktopLayout(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Image section (left side)
        Expanded(
          flex: 4,
          child: Container(
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A2E),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.pink.withOpacity(0.2),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Main product image
                Container(
                  height: 340,
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.white24),
                  ),
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
                                'Select Main Image',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontFamily: 'PixelFont',
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
                const SizedBox(height: 16),
                // Additional images section
                _buildResponsiveAdditionalImagesSection(),
              ],
            ),
          ),
        ),

        // Right column with details
        Expanded(
          flex: 5,
          child: _buildProductDetailsSection(),
        ),
      ],
    );
  }

  // Details section components (price, description, etc.)
  Widget _buildProductDetailsSection() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // Description Box with improved styling
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A2E),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 8,
                ),
              ],
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: const [
                    Icon(Icons.description, color: Colors.pink, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Description',
                      style: TextStyle(
                        color: Colors.white,
                        fontFamily: 'PixelFont',
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _descriptionController,
                  style: const TextStyle(color: Colors.white),
                  maxLines: 4,
                  decoration: InputDecoration(
                    hintText: 'Enter product description...',
                    hintStyle: TextStyle(color: Colors.grey.shade500),
                    filled: true,
                    fillColor: Colors.black38,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.pink.withOpacity(0.3)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.pink.withOpacity(0.3)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Colors.pink),
                    ),
                    contentPadding: const EdgeInsets.all(12),
                  ),
                ),
              ],
            ),
          ),

          // Category Selection with improved styling
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A2E),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 8,
                ),
              ],
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: const [
                    Icon(Icons.category, color: Colors.pink, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Category',
                      style: TextStyle(
                        color: Colors.white,
                        fontFamily: 'PixelFont',
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _selectedCategory,
                  dropdownColor: const Color(0xFF1A1A2E),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.black38,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.pink.withOpacity(0.3)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.pink.withOpacity(0.3)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Colors.pink),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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

          // Price & Discount with improved styling
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A2E),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 8,
                ),
              ],
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: const [
                    Icon(Icons.php, color: Colors.pink, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Pricing',
                      style: TextStyle(
                        color: Colors.white,
                        fontFamily: 'PixelFont',
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                
                // Price field with better styling
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Selling Price',
                      style: TextStyle(
                        color: Colors.white70,
                        fontFamily: 'PixelFont',
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.black38,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.pink.withOpacity(0.3)),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: TextField(
                        controller: _priceController,
                        style: const TextStyle(color: Colors.white),
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          hintText: '0.00',
                          hintStyle: TextStyle(color: Colors.grey),
                          prefixText: '\PHP ',
                          prefixStyle: TextStyle(color: Colors.green),
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // Discount field with better styling
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Discount',
                      style: TextStyle(
                        color: Colors.white70,
                        fontFamily: 'PixelFont',
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.black38,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.pink.withOpacity(0.3)),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
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

          // Available Stock with improved styling
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A2E),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 8,
                ),
              ],
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: const [
                    Icon(Icons.inventory, color: Colors.pink, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Available Stock',
                      style: TextStyle(
                        color: Colors.white,
                        fontFamily: 'PixelFont',
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    InkWell(
                      onTap: _decrementStock,
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red.shade900,
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.red.withOpacity(0.3),
                              blurRadius: 5,
                            ),
                          ],
                        ),
                        child: const Icon(Icons.remove, color: Colors.white),
                      ),
                    ),
                    Container(
                      width: 80,
                      alignment: Alignment.center,
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.black38,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.pink.withOpacity(0.3)),
                      ),
                      child: TextField(
                        controller: _stockCountController,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontFamily: 'PixelFont',
                          fontSize: 20,
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
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.green.shade900,
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.green.withOpacity(0.3),
                              blurRadius: 5,
                            ),
                          ],
                        ),
                        child: const Icon(Icons.add, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Responsive additional images section
  Widget _buildResponsiveAdditionalImagesSection() {
    final isSmall = _isSmallScreen(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Row(
                children: [
                  const Icon(Icons.photo_library, color: Colors.pink, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    'Additional Views (${_additionalImages.length}/$maxAdditionalImages)',
                    style: const TextStyle(
                      color: Colors.white,
                      fontFamily: 'PixelFont',
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (_additionalImages.length < maxAdditionalImages)
              ElevatedButton.icon(
                onPressed: _pickAdditionalImages,
                icon: const Icon(Icons.add_photo_alternate, size: 16),
                label: Text(
                  isSmall ? 'Add' : 'Add Images',
                  style: const TextStyle(
                    fontFamily: 'PixelFont',
                    fontSize: 12,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.pink.shade900,
                  padding: EdgeInsets.symmetric(
                    horizontal: isSmall ? 8 : 12,
                    vertical: 6,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        if (_additionalImages.isNotEmpty)
          SizedBox(
            height: isSmall ? 80 : 100,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _additionalImages.length,
              itemBuilder: (context, index) {
                return Stack(
                  children: [
                    Container(
                      width: isSmall ? 80 : 100,
                      height: isSmall ? 80 : 100,
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.pink.withOpacity(0.5)),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(
                          _additionalImages[index],
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    Positioned(
                      top: 4,
                      right: 12,
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _additionalImages.removeAt(index);
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.7),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.close,
                            size: 16,
                            color: Colors.pink,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          )
        else
          Container(
            width: double.infinity,
            height: isSmall ? 80 : 100,
            decoration: BoxDecoration(
              color: Colors.black38,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.withOpacity(0.3)),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(
                  Icons.collections,
                  color: Colors.grey,
                  size: 24,
                ),
                SizedBox(height: 8),
                Text(
                  'Add more views of your product',
                  style: TextStyle(
                    color: Colors.grey,
                    fontFamily: 'PixelFont',
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
