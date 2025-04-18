import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'product_details.dart';

class CategoryPage extends StatefulWidget {
  const CategoryPage({Key? key}) : super(key: key);

  @override
  State<CategoryPage> createState() => _CategoryPageState();
}

class _CategoryPageState extends State<CategoryPage> {
  final List<String> _categories = [
    'Games',
    'Consoles',
    'Accessories',
    'Collectibles'
  ];
  String _selectedCategory = 'Games';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Categories',
          style: TextStyle(fontFamily: 'PixelFont'),
        ),
        backgroundColor: Colors.black,
      ),
      backgroundColor: Colors.black,
      body: Column(
        children: [
          // Category Dropdown
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: DropdownButtonFormField<String>(
              value: _selectedCategory,
              dropdownColor: Colors.grey[900],
              decoration: InputDecoration(
                labelText: 'Select Category',
                labelStyle: const TextStyle(
                    color: Colors.white, fontFamily: 'PixelFont'),
                filled: true,
                fillColor: Colors.grey[800],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
              ),
              style:
                  const TextStyle(color: Colors.white, fontFamily: 'PixelFont'),
              onChanged: (value) {
                setState(() {
                  _selectedCategory = value!;
                });
              },
              items: _categories.map((category) {
                return DropdownMenuItem(
                  value: category,
                  child: Text(category),
                );
              }).toList(),
            ),
          ),

          // Products List
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('products')
                  .where('category', isEqualTo: _selectedCategory)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: Colors.cyan),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Text(
                      'No products found in this category',
                      style: TextStyle(
                          color: Colors.white, fontFamily: 'PixelFont'),
                    ),
                  );
                }

                final products = snapshot.data!.docs;

                return GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.75,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: products.length,
                  itemBuilder: (context, index) {
                    final product = products[index];
                    final productData = product.data() as Map<String, dynamic>?;

                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ProductDetails(
                              productId:
                                  product.id, // Pass the Firestore document ID
                              imageUrl: productData?['imageUrl'] ?? '',
                              title: productData?['name'] ?? 'Unknown Product',
                              price:
                                  productData?['price']?.toString() ?? '0.00',
                              description: productData?['description'] ??
                                  'No description available',
                              stockCount: productData?['stockCount'] ?? 0,
                              userId: productData?['userId'] ?? 'Unknown User',
                            ),
                          ),
                        );
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.grey[900],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey[800]!),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(
                              child: ClipRRect(
                                borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(7)),
                                child: Image.network(
                                  productData?['imageUrl'] ?? '',
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      color: Colors.grey.shade900,
                                      child: const Center(
                                        child: Icon(Icons.image_not_supported,
                                            color: Colors.grey),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    productData?['name'] ?? 'Unknown Product',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      fontFamily: 'PixelFont',
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'PHP ${productData?['price'] ?? '0.00'}',
                                    style: const TextStyle(
                                      color: Colors.cyan,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      fontFamily: 'PixelFont',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
