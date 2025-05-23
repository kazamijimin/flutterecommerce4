import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'account_deletion_requests.dart';
class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Map<String, int> _stats = {
    'users': 0,
    'sellers': 0,
    'products': 0,
    'orders': 0,
    'pendingApplications': 0,
    'deletionRequests': 0, // Added deletion requests stat
  };
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadStats();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadStats() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Get user count
      final userSnapshot =
          await FirebaseFirestore.instance.collection('users').get();
      final sellerCount = userSnapshot.docs.where((doc) {
        final data = doc.data();
        return data['sellerStatus'] == 'approved';
      }).length;

      // Get product count
      final productSnapshot =
          await FirebaseFirestore.instance.collection('products').get();

      // Get order count
      final orderSnapshot =
          await FirebaseFirestore.instance.collection('orders').get();

      // Get pending applications
      final applicationSnapshot = await FirebaseFirestore.instance
          .collection('sellerApplications')
          .get();

      // Get deletion requests
      final deletionRequestsSnapshot = await FirebaseFirestore.instance
          .collection('deletion_requests')
          .where('status', isEqualTo: 'pending')
          .get();

      setState(() {
        _stats = {
          'users': userSnapshot.size,
          'sellers': sellerCount,
          'products': productSnapshot.size,
          'orders': orderSnapshot.size,
          'pendingApplications': applicationSnapshot.size,
          'deletionRequests':
              deletionRequestsSnapshot.size, // Add deletion requests count
        };
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading stats: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Approve seller application
  Future<void> _approveSeller(String userId) async {
    try {
      // Update the seller's status to "approved"
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .update({'sellerStatus': 'approved'});

      // Delete the seller application
      await FirebaseFirestore.instance
          .collection('sellerApplications')
          .doc(userId)
          .delete();

      // Add a notification for the user
      await FirebaseFirestore.instance.collection('notifications').add({
        'userId': userId,
        'title': 'Congratulations!',
        'message': 'Your seller request has been approved. Start selling now!',
        'type': 'sellerApproval',
        'isRead': false,
        'timestamp': FieldValue.serverTimestamp(),
      });

      // Refresh stats after approval
      _loadStats();

      // Show a success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Approved seller and notification sent.'),
          backgroundColor: Colors.green,
        ),
      );

      debugPrint('Seller approved and notification sent for userId: $userId');
    } catch (e) {
      debugPrint('Error approving seller: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error approving seller: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Reject seller application
  Future<void> _rejectSeller(String userId) async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .update({'sellerStatus': 'notApplied'});

      await FirebaseFirestore.instance
          .collection('sellerApplications')
          .doc(userId)
          .delete();

      _loadStats(); // Refresh stats after rejection
      debugPrint('Seller rejected for userId: $userId');
    } catch (e) {
      debugPrint('Error rejecting seller: $e');
    }
  }

  // Process account deletion
  Future<void> _processAccountDeletion(
      String docId, String userId, bool approve) async {
    try {
      if (approve) {
        // Get user data for notification
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .get();

        final userEmail = userDoc.data()?['email'] ?? 'Unknown email';

        // Update deletion request status
        await FirebaseFirestore.instance
            .collection('deletion_requests')
            .doc(docId)
            .update({
          'status': 'approved',
          'processedAt': FieldValue.serverTimestamp(),
          'processedBy': 'admin', // You might want to store actual admin ID
        });

        // Add admin notification for tracking
        await FirebaseFirestore.instance.collection('admin_logs').add({
          'action': 'account_deletion_approved',
          'userId': userId,
          'userEmail': userEmail,
          'timestamp': FieldValue.serverTimestamp(),
          'adminId':
              'admin', // Replace with actual admin ID when you have authentication
        });

        // You would normally schedule the actual account deletion here
        // For immediate deletion (example only):
        // await FirebaseFirestore.instance.collection('users').doc(userId).delete();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content:
                Text('Account deletion approved and scheduled for processing'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        // Reject deletion request
        await FirebaseFirestore.instance
            .collection('deletion_requests')
            .doc(docId)
            .update({
          'status': 'rejected',
          'processedAt': FieldValue.serverTimestamp(),
          'processedBy': 'admin', // You might want to store actual admin ID
        });

        // Notify user that their request was denied
        await FirebaseFirestore.instance.collection('notifications').add({
          'userId': userId,
          'title': 'Account Deletion Request',
          'message':
              'Your request to delete your account has been rejected. Please contact support for more information.',
          'type': 'accountDeletionRejected',
          'isRead': false,
          'timestamp': FieldValue.serverTimestamp(),
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Account deletion request rejected'),
            backgroundColor: Colors.orange,
          ),
        );
      }

      _loadStats(); // Refresh stats
    } catch (e) {
      debugPrint('Error processing deletion request: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error processing request: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Restrict user account
  Future<void> _restrictAccount(BuildContext context, String userId) async {
    String selectedReason = 'Select a reason'; // Default dropdown value
    final List<String> predefinedReasons = [
      'Select a reason',
      'Violation of terms',
      'Inappropriate behavior',
      'Fraudulent activity',
      'Spamming',
      'Other'
    ];
    final TextEditingController reasonController = TextEditingController();

    // Show a dialog to input the reason for restriction
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF1A1A2E),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: const Color(0xFF333355),
                  width: 1.5,
                ),
              ),
              title: const Text(
                'RESTRICT ACCOUNT',
                style: TextStyle(
                  color: Colors.white,
                  fontFamily: 'PixelFont',
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Please select or provide a reason for restricting this account:',
                    style: TextStyle(color: Colors.white70),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.grey[850],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.cyan),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: selectedReason,
                        isExpanded: true,
                        dropdownColor: Colors.grey[850],
                        style: const TextStyle(color: Colors.white),
                        items: predefinedReasons.map((reason) {
                          return DropdownMenuItem<String>(
                            value: reason,
                            child: Text(reason),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            selectedReason = value!;
                            if (selectedReason != 'Other') {
                              reasonController
                                  .clear(); // Clear custom input if not "Other"
                            }
                          });
                        },
                      ),
                    ),
                  ),
                  if (selectedReason == 'Other') ...[
                    const SizedBox(height: 16),
                    TextField(
                      controller: reasonController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Enter custom reason',
                        hintStyle: const TextStyle(color: Colors.grey),
                        filled: true,
                        fillColor: Colors.grey[850],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.cyan),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.cyan),
                        ),
                      ),
                      maxLines: 3,
                    ),
                  ],
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel',
                      style: TextStyle(color: Colors.grey)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () async {
                    final reason = selectedReason == 'Other'
                        ? reasonController.text.trim()
                        : selectedReason;

                    if (reason.isNotEmpty && reason != 'Select a reason') {
                      try {
                        // Update the user's status and add the restriction reason
                        await FirebaseFirestore.instance
                            .collection('users')
                            .doc(userId)
                            .update({
                          'accountStatus': 'restricted',
                          'restrictionReason': reason,
                        });

                        debugPrint(
                            'Account restricted for userId: $userId with reason: $reason');
                        Navigator.pop(context);

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content:
                                Text('Account restricted for reason: $reason'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      } catch (e) {
                        debugPrint('Error restricting account: $e');
                        Navigator.pop(context);

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Failed to restrict account: $e'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content:
                              Text('Please select or provide a valid reason'),
                          backgroundColor: Colors.orange,
                        ),
                      );
                    }
                  },
                  child: const Text('Restrict'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildStatCard(String title, int value, IconData icon, Color color) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF333355),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: color.withOpacity(0.5),
                  width: 1.5,
                ),
              ),
              child: Icon(icon, color: color, size: 32),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white70,
                fontFamily: 'PixelFont',
                fontSize: 14,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              value.toString(),
              style: TextStyle(
                color: color,
                fontFamily: 'PixelFont',
                fontWeight: FontWeight.bold,
                fontSize: 24,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Build deletion request card for horizontal slider
  Widget _buildDeletionRequestCard(String docId, Map<String, dynamic> data) {
    final userId = data['userId'] ?? 'Unknown';
    final userEmail = data['userEmail'] ?? 'Unknown Email';
    final reason = data['reason'] ?? 'No reason provided';

    // Format date
    String requestDate = 'Unknown date';
    if (data['requestedAt'] != null) {
      requestDate = DateFormat('MMM d, y')
          .format((data['requestedAt'] as Timestamp).toDate());
    }

    return Container(
      width: 300,
      margin: const EdgeInsets.only(right: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFFF0077),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF0077).withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF0077).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: const Color(0xFFFF0077),
                    ),
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: const Text(
                    'DELETION REQUEST',
                    style: TextStyle(
                      color: Color(0xFFFF0077),
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  requestDate,
                  style: TextStyle(color: Colors.grey[400], fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              'User Details:',
              style: TextStyle(
                color: Color(0xFF00E5FF),
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              userEmail,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Reason:',
              style: TextStyle(
                color: Color(0xFF00E5FF),
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.grey.withOpacity(0.2),
                  ),
                ),
                child: Text(
                  reason,
                  style: const TextStyle(color: Colors.white70),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 3,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () =>
                        _processAccountDeletion(docId, userId, false),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.cyan,
                      side: const BorderSide(color: Colors.cyan),
                    ),
                    child: const Text('Reject'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () =>
                        _processAccountDeletion(docId, userId, true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF0077),
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Approve'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'ADMIN DASHBOARD',
          style: TextStyle(
            fontFamily: 'PixelFont',
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
            color: Colors.white,
            fontSize: 20,
          ),
        ),
        backgroundColor: const Color(0xFF0D0D0D),
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Color(0xFFFF0077)),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFFFF0077),
          labelStyle: const TextStyle(fontFamily: 'PixelFont'),
          tabs: const [
            Tab(text: 'OVERVIEW', icon: Icon(Icons.dashboard)),
            Tab(text: 'SELLER APPS', icon: Icon(Icons.store)),
            Tab(text: 'USERS', icon: Icon(Icons.people)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xFFFF0077)),
            onPressed: _loadStats,
            tooltip: 'Refresh data',
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Overview tab
          _isLoading
              ? const Center(
                  child: CircularProgressIndicator(
                      color: Color(0xFFFF0077), strokeWidth: 2))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Dashboard Overview',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Last updated: ${DateFormat('MMM d, y h:mm a').format(DateTime.now())}',
                        style: TextStyle(color: Colors.grey[400], fontSize: 12),
                      ),
                      const SizedBox(height: 24),
                      GridView.count(
                        shrinkWrap: true,
                        crossAxisCount: 2,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        physics: const NeverScrollableScrollPhysics(),
                        children: [
                          _buildStatCard('Total Users', _stats['users']!,
                              Icons.people, Colors.blue),
                          _buildStatCard('Sellers', _stats['sellers']!,
                              Icons.store, Colors.green),
                          _buildStatCard('Products', _stats['products']!,
                              Icons.shopping_bag, Colors.orange),
                          _buildStatCard('Orders', _stats['orders']!,
                              Icons.shopping_cart, Colors.purple),
                        ],
                      ),

                      // Account Deletion Requests Section
                      const SizedBox(height: 32),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Text(
                                'Account Deletion Requests',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color:
                                      const Color(0xFFFF0077).withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                      color: const Color(0xFFFF0077)),
                                ),
                                child: Text(
                                  '${_stats['deletionRequests']}',
                                  style: const TextStyle(
                                    color: Color(0xFFFF0077),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          // In admin_dashboard.dart, update the "View All" button:
                          TextButton.icon(
                            icon: const Icon(Icons.chevron_right, size: 18),
                            label: const Text('View All'),
                            style: TextButton.styleFrom(
                              foregroundColor: const Color(0xFF00E5FF),
                            ),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const AccountDeletionRequestsPage(),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Horizontal Slider for Deletion Requests
                      SizedBox(
                        height: 220, // Fixed height for the cards
                        child: StreamBuilder<QuerySnapshot>(
                          stream: FirebaseFirestore.instance
                              .collection('deletion_requests')
                              .where('status', isEqualTo: 'pending')
                              .orderBy('requestedAt', descending: true)
                              .limit(10)
                              .snapshots(),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const Center(
                                child: CircularProgressIndicator(
                                  color: Color(0xFFFF0077),
                                  strokeWidth: 2,
                                ),
                              );
                            }

                            if (!snapshot.hasData ||
                                snapshot.data!.docs.isEmpty) {
                              return Container(
                                height: 220,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1A1A2E),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: const Color(0xFF333355),
                                    width: 1.5,
                                  ),
                                ),
                                child: Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.delete_forever,
                                        size: 48,
                                        color: Colors.grey[700],
                                      ),
                                      const SizedBox(height: 16),
                                      const Text(
                                        'No pending deletion requests',
                                        style: TextStyle(
                                          color: Colors.white70,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }

                            final deletionRequests = snapshot.data!.docs;

                            return ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: deletionRequests.length,
                              itemBuilder: (context, index) {
                                final doc = deletionRequests[index];
                                final data = doc.data() as Map<String, dynamic>;
                                return _buildDeletionRequestCard(doc.id, data);
                              },
                            );
                          },
                        ),
                      ),

                      const SizedBox(height: 32),
                      const Text(
                        'Quick Actions',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              icon: const Icon(Icons.store),
                              label: Text(
                                'SELLER APPS (${_stats['pendingApplications']})',
                                style: const TextStyle(fontFamily: 'PixelFont'),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFFF0077),
                                foregroundColor: Colors.white,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              onPressed: () {
                                _tabController.animateTo(1);
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton.icon(
                              icon: const Icon(Icons.people),
                              label: const Text('Manage Users'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.pink,
                                foregroundColor: Colors.white,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                              ),
                              onPressed: () {
                                _tabController.animateTo(2);
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

          // Seller Applications tab
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('sellerApplications')
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                    child: CircularProgressIndicator(
                        color: Color(0xFFFF0077), strokeWidth: 2));
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.store, size: 64, color: Colors.grey[700]),
                      const SizedBox(height: 16),
                      const Text(
                        'No pending seller applications',
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                    ],
                  ),
                );
              }

              final pendingApplications = snapshot.data!.docs;

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: pendingApplications.length,
                itemBuilder: (context, index) {
                  final application = pendingApplications[index];
                  final userId = application.id;
                  final applicationData =
                      application.data() as Map<String, dynamic>;
                  final storeName =
                      applicationData['storeName'] ?? 'Unknown Store';
                  final storeDescription =
                      applicationData['storeDescription'] ?? 'No Description';
                  final submittedDate = applicationData['timestamp'] != null
                      ? DateFormat('MMM d, y').format(
                          (applicationData['timestamp'] as Timestamp).toDate())
                      : 'Unknown date';

                  return Card(
                    margin: const EdgeInsets.only(bottom: 16),
                    color: const Color(0xFF1A1A2E),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color: const Color(0xFF333355),
                        width: 1.5,
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.cyan,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                child: const Text(
                                  'PENDING',
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Submitted: $submittedDate',
                                style: TextStyle(
                                    color: Colors.grey[400], fontSize: 12),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            storeName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            storeDescription,
                            style: const TextStyle(color: Colors.white70),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              OutlinedButton.icon(
                                icon: const Icon(Icons.close),
                                label: const Text('Reject'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.red,
                                  side: const BorderSide(color: Colors.red),
                                ),
                                onPressed: () {
                                  _rejectSeller(userId);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content:
                                          Text('Rejected seller: $storeName'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(width: 12),
                              ElevatedButton.icon(
                                icon: const Icon(Icons.check),
                                label: const Text('Approve'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  foregroundColor: Colors.white,
                                ),
                                onPressed: () {
                                  _approveSeller(userId);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content:
                                          Text('Approved seller: $storeName'),
                                      backgroundColor: Colors.green,
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),

          // Users tab
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('users').snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                    child: CircularProgressIndicator(
                        color: Color(0xFFFF0077), strokeWidth: 2));
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Center(
                  child: Text(
                    'No users found',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                );
              }

              final users = snapshot.data!.docs;

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: users.length,
                itemBuilder: (context, index) {
                  final user = users[index];
                  final userData = user.data() as Map<String, dynamic>;
                  final displayName = userData['displayName'] ?? 'Unknown User';
                  final email = userData['email'] ?? 'No Email';
                  final sellerStatus = userData['sellerStatus'] ?? 'notApplied';
                  final accountStatus = userData['accountStatus'] ?? 'active';
                  final photoURL = userData['photoURL'];

                  Color statusColor;
                  String statusText;

                  if (accountStatus == 'restricted') {
                    statusColor = Colors.red;
                    statusText = 'Restricted';
                  } else if (sellerStatus == 'approved') {
                    statusColor = Colors.green;
                    statusText = 'Seller';
                  } else if (sellerStatus == 'pending') {
                    statusColor = Colors.orange;
                    statusText = 'Pending Seller';
                  } else {
                    statusColor = Colors.blue;
                    statusText = 'Customer';
                  }

                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    color: const Color(0xFF1A1A2E),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color: const Color(0xFF333355),
                        width: 1.5,
                      ),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      leading: CircleAvatar(
                        backgroundColor: Colors.grey[700],
                        backgroundImage:
                            photoURL != null ? NetworkImage(photoURL) : null,
                        child: photoURL == null
                            ? const Icon(Icons.person, color: Colors.white)
                            : null,
                      ),
                      title: Row(
                        children: [
                          Expanded(
                            child: Text(
                              displayName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: statusColor.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: statusColor),
                            ),
                            child: Text(
                              statusText,
                              style: TextStyle(
                                color: statusColor,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          Text(
                            email,
                            style: const TextStyle(color: Colors.white70),
                          ),
                          if (accountStatus == 'restricted') ...[
                            const SizedBox(height: 4),
                            Text(
                              'Reason: ${userData['restrictionReason'] ?? 'Unknown'}',
                              style: const TextStyle(
                                  color: Colors.red, fontSize: 12),
                            ),
                          ],
                        ],
                      ),
                      trailing: accountStatus == 'restricted'
                          ? OutlinedButton(
                              onPressed: () async {
                                try {
                                  await FirebaseFirestore.instance
                                      .collection('users')
                                      .doc(user.id)
                                      .update({
                                    'accountStatus': 'active',
                                    'restrictionReason': FieldValue.delete(),
                                  });

                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content:
                                          Text('Account restriction removed'),
                                      backgroundColor: Colors.green,
                                    ),
                                  );
                                } catch (e) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Error: $e'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              },
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.green,
                                side: const BorderSide(color: Colors.green),
                              ),
                              child: const Text('Unrestrict'),
                            )
                          : IconButton(
                              icon: const Icon(Icons.block, color: Colors.red),
                              onPressed: () =>
                                  _restrictAccount(context, user.id),
                              tooltip: 'Restrict Account',
                            ),
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
      backgroundColor: Colors.black,
    );
  }
}
