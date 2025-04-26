import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Map<String, int> _stats = {
    'users': 0,
    'sellers': 0,
    'products': 0,
    'orders': 0,
    'pendingApplications': 0,
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
      final userSnapshot = await FirebaseFirestore.instance.collection('users').get();
      final sellerCount = userSnapshot.docs.where((doc) {
        final data = doc.data();
        return data['sellerStatus'] == 'approved';
      }).length;

      // Get product count
      final productSnapshot = await FirebaseFirestore.instance.collection('products').get();
      
      // Get order count
      final orderSnapshot = await FirebaseFirestore.instance.collection('orders').get();
      
      // Get pending applications
      final applicationSnapshot = await FirebaseFirestore.instance.collection('sellerApplications').get();

      setState(() {
        _stats = {
          'users': userSnapshot.size,
          'sellers': sellerCount,
          'products': productSnapshot.size,
          'orders': orderSnapshot.size,
          'pendingApplications': applicationSnapshot.size,
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
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .update({'sellerStatus': 'approved'});

      await FirebaseFirestore.instance
          .collection('sellerApplications')
          .doc(userId)
          .delete();

      _loadStats(); // Refresh stats after approval
      debugPrint('Seller approved for userId: $userId');
    } catch (e) {
      debugPrint('Error approving seller: $e');
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
              backgroundColor: Colors.grey[900],
              title: const Text(
                'Restrict Account',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
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
                              reasonController.clear(); // Clear custom input if not "Other"
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
                  child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
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

                        debugPrint('Account restricted for userId: $userId with reason: $reason');
                        Navigator.pop(context);

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Account restricted for reason: $reason'),
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
                          content: Text('Please select or provide a valid reason'),
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
    return Card(
      color: Colors.grey[850],
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white70,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value.toString(),
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 24,
              ),
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
          'Admin Dashboard',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.black,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.cyan,
          tabs: const [
            Tab(text: 'Overview', icon: Icon(Icons.dashboard)),
            Tab(text: 'Seller Applications', icon: Icon(Icons.store)),
            Tab(text: 'Users', icon: Icon(Icons.people)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
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
              ? const Center(child: CircularProgressIndicator(color: Colors.cyan))
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
                          _buildStatCard('Total Users', _stats['users']!, Icons.people, Colors.blue),
                          _buildStatCard('Sellers', _stats['sellers']!, Icons.store, Colors.green),
                          _buildStatCard('Products', _stats['products']!, Icons.shopping_bag, Colors.orange),
                          _buildStatCard('Orders', _stats['orders']!, Icons.shopping_cart, Colors.purple),
                        ],
                      ),
                      const SizedBox(height: 24),
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
                              label: Text('Seller Applications (${_stats['pendingApplications']})'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.cyan,
                                foregroundColor: Colors.black,
                                padding: const EdgeInsets.symmetric(vertical: 16),
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
                                padding: const EdgeInsets.symmetric(vertical: 16),
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
                return const Center(child: CircularProgressIndicator(color: Colors.cyan));
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
                  final applicationData = application.data() as Map<String, dynamic>;
                  final storeName = applicationData['storeName'] ?? 'Unknown Store';
                  final storeDescription =
                      applicationData['storeDescription'] ?? 'No Description';
                  final submittedDate = applicationData['timestamp'] != null
                      ? DateFormat('MMM d, y').format((applicationData['timestamp'] as Timestamp).toDate())
                      : 'Unknown date';

                  return Card(
                    margin: const EdgeInsets.only(bottom: 16),
                    color: Colors.grey[900],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                      side: const BorderSide(color: Colors.cyan, width: 1),
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
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
                                style: TextStyle(color: Colors.grey[400], fontSize: 12),
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
                                      content: Text('Rejected seller: $storeName'),
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
                                      content: Text('Approved seller: $storeName'),
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
                return const Center(child: CircularProgressIndicator(color: Colors.cyan));
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
                    color: Colors.grey[850],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      leading: CircleAvatar(
                        backgroundColor: Colors.grey[700],
                        backgroundImage: photoURL != null ? NetworkImage(photoURL) : null,
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
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
                              style: const TextStyle(color: Colors.red, fontSize: 12),
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
                                      content: Text('Account restriction removed'),
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
                              onPressed: () => _restrictAccount(context, user.id),
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