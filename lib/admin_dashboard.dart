import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  // Approve seller application
  Future<void> _approveSeller(String userId) async {
    try {
      // Update the seller's status in the `users` collection
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .update({'sellerStatus': 'approved'});

      // Remove the application from the `sellerApplications` collection
      await FirebaseFirestore.instance
          .collection('sellerApplications')
          .doc(userId)
          .delete();

      debugPrint('Seller approved for userId: $userId');
    } catch (e) {
      debugPrint('Error approving seller: $e');
    }
  }

  // Reject seller application
  Future<void> _rejectSeller(String userId) async {
    try {
      // Update the seller's status in the `users` collection
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .update({'sellerStatus': 'notApplied'});

      // Remove the application from the `sellerApplications` collection
      await FirebaseFirestore.instance
          .collection('sellerApplications')
          .doc(userId)
          .delete();

      debugPrint('Seller rejected for userId: $userId');
    } catch (e) {
      debugPrint('Error rejecting seller: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        backgroundColor: Colors.black,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('sellerApplications')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                'No pending seller applications.',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            );
          }

          final pendingApplications = snapshot.data!.docs;

          return ListView.builder(
            itemCount: pendingApplications.length,
            itemBuilder: (context, index) {
              final application = pendingApplications[index];
              final userId = application.id;
              final applicationData = application.data() as Map<String, dynamic>;
              final storeName = applicationData['storeName'] ?? 'Unknown Store';
              final storeDescription =
                  applicationData['storeDescription'] ?? 'No Description';

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                color: Colors.grey[900],
                child: ListTile(
                  title: Text(
                    storeName,
                    style: const TextStyle(color: Colors.white),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        storeDescription,
                        style: const TextStyle(color: Colors.white70),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Seller Request Pending',
                        style: TextStyle(color: Colors.orange, fontSize: 14),
                      ),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.check, color: Colors.green),
                        onPressed: () {
                          _approveSeller(userId);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Approved seller: $storeName'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.red),
                        onPressed: () {
                          _rejectSeller(userId);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Rejected seller: $storeName'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      backgroundColor: Colors.black,
    );
  }
}