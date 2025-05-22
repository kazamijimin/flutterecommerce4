// filepath: c:\Users\balli\Desktop\flutterecommerce4\lib\see_all_products_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'product_details.dart';
import 'home.dart';
import 'category.dart';
import 'message.dart';
import 'profile.dart';

class SeeAllProductsScreen extends StatelessWidget {
  const SeeAllProductsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'All Recommended Products',
          style: TextStyle(
            fontFamily: 'PixelFont', // Apply PixelFont
          ),
        ),
        backgroundColor: Colors.black,
      ),
      backgroundColor: Colors.black,
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('products')
            .orderBy('createdAt', descending: true)
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
                'No products available',
                style: TextStyle(
                  color: Colors.white,
                  fontFamily: 'PixelFont', // Apply PixelFont
                ),
              ),
            );
          }

          final products = snapshot.data!.docs;
          return GridView.builder(
            padding: const EdgeInsets.all(8),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 0.7,
            ),
            itemCount: products.length,
            itemBuilder: (context, index) {
              final product = products[index];
              final productData = product.data()
                  as Map<String, dynamic>?; // Safely cast the data

              return _buildProductCard(
                context,
                productData?['imageUrl'] ?? '',
                productData?['name'] ?? 'Unknown Product',
                'PHP ${productData?['price'] ?? '0.00'}',
                productData?['description'] ?? 'No description available',
                productData?['sellerId'] ?? 'Unknown Seller',
                product.id,
              );
            },
          );
        },
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.black,
        selectedItemColor: const Color.fromARGB(255, 212, 0, 0),
        unselectedItemColor: Colors.white,
        selectedLabelStyle: const TextStyle(fontFamily: 'PixelFont', fontSize: 12),
        unselectedLabelStyle: const TextStyle(fontFamily: 'PixelFont', fontSize: 12),
        currentIndex: 3, // Set to 3 because "Shop" is the fourth item
        onTap: (index) {
          switch (index) {
            case 0: // Home
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const HomePage()),
              );
              break;
            case 1: // Category
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const CategoryPage()),
              );
              break;
            case 2: // Message
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const ChatPage()),
              );
              break;
            case 3: // Shop - already here
              break;
            case 4: // Profile
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const ProfileScreen()),
              );
              break;
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.category), label: 'Category'),
          BottomNavigationBarItem(icon: Icon(Icons.message), label: 'Message'),
          BottomNavigationBarItem(icon: Icon(Icons.shopping_bag), label: 'Shop'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }

  Widget _buildProductCard(BuildContext context, String imageUrl, String title,
      String price, String description, String sellerId, String productId) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProductDetails(
              productId: productId,
              imageUrl: imageUrl,
              title: title,
              price: price,
              description: description,
              sellerId: sellerId, // Use sellerId here
              rating: 0.0, // Provide a default value for rating
              stockCount: 0, // Provide a default value for stockCount
              category: 'Unknown', // Provide a default value for category
            ),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey[800],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Colors.grey.shade900,
                      child: const Center(
                        child: Icon(Icons.error, color: Colors.white),
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
                    title,
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
                    price,
                    style: const TextStyle(
                      color: Colors.cyan,
                      fontSize: 12,
                      fontFamily: 'PixelFont',
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 10,
                      fontFamily: 'PixelFont',
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
