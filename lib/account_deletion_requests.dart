import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class AccountDeletionRequestsPage extends StatefulWidget {
  const AccountDeletionRequestsPage({Key? key}) : super(key: key);

  @override
  State<AccountDeletionRequestsPage> createState() => _AccountDeletionRequestsPageState();
}

class _AccountDeletionRequestsPageState extends State<AccountDeletionRequestsPage> {
  bool _isLoading = false;
  String _statusFilter = 'pending'; // Default to pending requests
  
  Future<void> _processAccountDeletion(String docId, String userId, bool approve) async {
    setState(() {
      _isLoading = true;
    });
    
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
          'adminId': 'admin', // Replace with actual admin ID when you have authentication
        });
        
        // You would normally schedule the actual account deletion here
        // For immediate deletion (example only):
        // await FirebaseFirestore.instance.collection('users').doc(userId).delete();
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Account deletion approved and scheduled for processing'),
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
          'message': 'Your request to delete your account has been rejected. Please contact support for more information.',
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
    } catch (e) {
      debugPrint('Error processing deletion request: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error processing request: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text(
          'ACCOUNT DELETION REQUESTS',
          style: TextStyle(
            fontFamily: 'PixelFont',
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
            color: Colors.white,
            fontSize: 18,
          ),
        ),
        backgroundColor: const Color(0xFF0D0D0D),
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Color(0xFFFF0077)),
      ),
      body: Column(
        children: [
          // Status filter
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A2E),
              border: Border(
                bottom: BorderSide(color: Colors.grey.withOpacity(0.2), width: 1),
              ),
            ),
            child: Row(
              children: [
                const Text(
                  'Filter by status:',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFF333355)),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _statusFilter,
                        isExpanded: true,
                        dropdownColor: const Color(0xFF1A1A2E),
                        style: const TextStyle(color: Colors.white),
                        items: const [
                          DropdownMenuItem(
                            value: 'all',
                            child: Text('All Requests'),
                          ),
                          DropdownMenuItem(
                            value: 'pending',
                            child: Text('Pending'),
                          ),
                          DropdownMenuItem(
                            value: 'approved',
                            child: Text('Approved'),
                          ),
                          DropdownMenuItem(
                            value: 'rejected',
                            child: Text('Rejected'),
                          ),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _statusFilter = value!;
                          });
                        },
                        icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF00E5FF)),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Deletion requests list
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFFFF0077),
                      strokeWidth: 2,
                    ),
                  )
                : StreamBuilder<QuerySnapshot>(
                    stream: _statusFilter == 'all'
                        ? FirebaseFirestore.instance
                            .collection('deletion_requests')
                            .orderBy('requestedAt', descending: true)
                            .snapshots()
                        : FirebaseFirestore.instance
                            .collection('deletion_requests')
                            .where('status', isEqualTo: _statusFilter)
                            .orderBy('requestedAt', descending: true)
                            .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: CircularProgressIndicator(
                            color: Color(0xFFFF0077),
                            strokeWidth: 2,
                          ),
                        );
                      }
                      
                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.delete_forever,
                                size: 64,
                                color: Colors.grey[700],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No $_statusFilter deletion requests found',
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        );
                      }
                      
                      final deletionRequests = snapshot.data!.docs;
                      
                      return ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: deletionRequests.length,
                        itemBuilder: (context, index) {
                          final doc = deletionRequests[index];
                          final data = doc.data() as Map<String, dynamic>;
                          
                          final userId = data['userId'] ?? 'Unknown';
                          final userEmail = data['userEmail'] ?? 'Unknown Email';
                          final reason = data['reason'] ?? 'No reason provided';
                          final status = data['status'] ?? 'pending';
                          
                          // Format date
                          String requestDate = 'Unknown date';
                          if (data['requestedAt'] != null) {
                            requestDate = DateFormat('MMM d, y').format(
                                (data['requestedAt'] as Timestamp).toDate());
                          }
                          
                          // Format processed date if available
                          String processedDate = '';
                          if (data['processedAt'] != null) {
                            processedDate = DateFormat('MMM d, y').format(
                                (data['processedAt'] as Timestamp).toDate());
                          }
                          
                          // Status color
                          Color statusColor;
                          switch (status) {
                            case 'approved':
                              statusColor = Colors.green;
                              break;
                            case 'rejected':
                              statusColor = Colors.red;
                              break;
                            default:
                              statusColor = const Color(0xFFFF0077);
                          }
                          
                          return Card(
                            margin: const EdgeInsets.only(bottom: 16),
                            color: const Color(0xFF1A1A2E),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(
                                color: statusColor.withOpacity(0.5),
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
                                          color: statusColor.withOpacity(0.2),
                                          borderRadius: BorderRadius.circular(4),
                                          border: Border.all(
                                            color: statusColor,
                                          ),
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 4),
                                        child: Text(
                                          status.toUpperCase(),
                                          style: TextStyle(
                                            color: statusColor,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                      const Spacer(),
                                      Text(
                                        'Requested: $requestDate',
                                        style: TextStyle(
                                            color: Colors.grey[400], fontSize: 12),
                                      ),
                                    ],
                                  ),
                                  if (processedDate.isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    Align(
                                      alignment: Alignment.topRight,
                                      child: Text(
                                        'Processed: $processedDate',
                                        style: TextStyle(
                                            color: Colors.grey[400], fontSize: 12),
                                      ),
                                    ),
                                  ],
                                  const SizedBox(height: 16),
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            const Text(
                                              'User Email:',
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
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            const Text(
                                              'User ID:',
                                              style: TextStyle(
                                                color: Color(0xFF00E5FF),
                                                fontSize: 14,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              userId,
                                              style: const TextStyle(
                                                color: Colors.white70,
                                                fontSize: 14,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  const Text(
                                    'Reason:',
                                    style: TextStyle(
                                      color: Color(0xFF00E5FF),
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(12),
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
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  if (status == 'pending')
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        Expanded(
                                          child: OutlinedButton(
                                            onPressed: () => _processAccountDeletion(
                                                doc.id, userId, false),
                                            style: OutlinedButton.styleFrom(
                                              foregroundColor: Colors.cyan,
                                              side: const BorderSide(color: Colors.cyan),
                                              padding: const EdgeInsets.symmetric(vertical: 12),
                                            ),
                                            child: const Text('REJECT'),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: ElevatedButton(
                                            onPressed: () => _processAccountDeletion(
                                                doc.id, userId, true),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: const Color(0xFFFF0077),
                                              foregroundColor: Colors.white,
                                              padding: const EdgeInsets.symmetric(vertical: 12),
                                            ),
                                            child: const Text('APPROVE'),
                                          ),
                                        ),
                                      ],
                                    )
                                  else
                                    Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: statusColor.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: statusColor.withOpacity(0.3),
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(
                                            status == 'approved'
                                                ? Icons.check_circle
                                                : Icons.cancel,
                                            color: statusColor,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            status == 'approved'
                                                ? 'This request has been approved'
                                                : 'This request has been rejected',
                                            style: TextStyle(
                                              color: statusColor,
                                              fontWeight: FontWeight.bold,
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