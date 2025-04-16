// filepath: c:\Users\balli\Desktop\flutterecommerce4\lib\see_all_products_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'product_details.dart';

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
    final productData = product.data() as Map<String, dynamic>?; // Safely cast the data

    return _buildProductCard(
      context,
      productData?['imageUrl'] ?? '', // Default to an empty string if imageUrl is missing
      productData?['name'] ?? 'Unknown Product', // Default to 'Unknown Product' if name is missing
      'PHP ${productData?['price'] ?? '0.00'}', // Default to '0.00' if price is missing
      productData?['description'] ?? 'No description available', // Default to 'No description available'
      productData?['userId'] ?? 'Unknown User', // Default to 'Unknown User' if userId is missing
    );
  },
);
        },
      ),
    );
  }
Widget _buildProductCard(BuildContext context, String imageUrl, String title, String price, String description, String userId) {
  return GestureDetector(
    onTap: () {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ProductDetails(
            imageUrl: imageUrl,
            title: title,
            price: price,
            description: description, // Pass the description to the ProductDetails screen
            userId: userId, // Pass the userId to the ProductDetails screen
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