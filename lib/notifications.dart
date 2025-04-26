import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart'; // You'll need to add this package
import 'order_details.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({Key? key}) : super(key: key);

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final Color _neonPink = const Color(0xFFFF0077);
  final Color _neonBlue = const Color(0xFF00E5FF);
  final Color _darkBackground = const Color(0xFF0F0F1B);
  bool _showOnlyUnread = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _darkBackground,
      appBar: AppBar(
        title: const Text(
          'NOTIFICATIONS',
          style: TextStyle(
            fontFamily: 'PixelFont', 
            letterSpacing: 2.0,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.black,
        actions: [
          // Add a popup menu button
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            color: const Color(0xFF1A1A2E),
            onSelected: (value) {
              if (value == 'markAllRead') {
                _showMarkAllReadDialog(context);
              } else if (value == 'markAllUnread') {
                _showMarkAllUnreadDialog(context);
              } else if (value == 'toggleUnread') {
                setState(() {
                  _showOnlyUnread = !_showOnlyUnread;
                });
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem<String>(
                value: 'markAllRead',
                child: Row(
                  children: [
                    Icon(Icons.done_all, color: _neonPink, size: 20),
                    const SizedBox(width: 8),
                    const Text(
                      'Mark all as read',
                      style: TextStyle(
                        color: Colors.white,
                        fontFamily: 'PixelFont',
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuItem<String>(
                value: 'markAllUnread',
                child: Row(
                  children: [
                    Icon(Icons.mark_email_unread, color: _neonBlue, size: 20),
                    const SizedBox(width: 8),
                    const Text(
                      'Mark all as unread',
                      style: TextStyle(
                        color: Colors.white,
                        fontFamily: 'PixelFont',
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuItem<String>(
                value: 'toggleUnread',
                child: Row(
                  children: [
                    Icon(
                      _showOnlyUnread ? Icons.filter_alt : Icons.filter_alt_outlined,
                      color: _showOnlyUnread ? _neonPink : Colors.white,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _showOnlyUnread ? 'Show all notifications' : 'Show only unread',
                      style: const TextStyle(
                        color: Colors.white,
                        fontFamily: 'PixelFont',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: _neonBlue,
          labelColor: _neonBlue,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'ALL'),
            Tab(text: 'ORDERS'),
            Tab(text: 'PROMOTIONS'),
          ],
          labelStyle: const TextStyle(
            fontFamily: 'PixelFont',
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildNotificationsList('all'),
          _buildNotificationsList('orders'),
          _buildNotificationsList('promotions'),
        ],
      ),
    );
  }

  Widget _buildNotificationsList(String type) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.notification_important, color: _neonPink, size: 64),
            const SizedBox(height: 16),
            const Text(
              'Please log in to view notifications.',
              style: TextStyle(color: Colors.white, fontFamily: 'PixelFont'),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                // Navigate to login page
                // Navigator.pushNamed(context, '/login');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _neonPink,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              ),
              child: const Text(
                'LOG IN',
                style: TextStyle(
                  fontFamily: 'PixelFont',
                  letterSpacing: 1.5,
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Create a more stable query
    Query query = FirebaseFirestore.instance
        .collection('notifications')
        .where('userId', isEqualTo: user.uid);
        
    // Only apply the type filter if not "all"
    if (type != 'all') {
      query = query.where('type', isEqualTo: type);
    }
    
    // Add filter for unread notifications if enabled
    if (_showOnlyUnread) {
      query = query.where('isRead', isEqualTo: false);
    }
    
    // Make sure we have a timestamp to sort by
    try {
      // Always sort by timestamp, descending
      query = query.orderBy('timestamp', descending: true);
    } catch (e) {
      print('Error setting up timestamp ordering: $e');
      // If timestamp ordering fails, try to continue without it
    }

    return StreamBuilder<QuerySnapshot>(
      stream: query.snapshots(),
      builder: (context, snapshot) {
        // Debug prints to see what's happening
        if (snapshot.connectionState == ConnectionState.active) {
          if (snapshot.hasData) {
            print('ACTIVE: Got ${snapshot.data!.docs.length} notifications for tab: $type');
            
            // Debug the notification types
            if (type == 'all' && snapshot.data!.docs.isNotEmpty) {
              final types = snapshot.data!.docs.map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                return data['type'] ?? 'unknown';
              }).toList();
              print('Notification types in "all" tab: $types');
            }
          } else if (snapshot.hasError) {
            print('Error loading notifications: ${snapshot.error}');
          }
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(_neonPink),
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  type == 'orders'
                      ? Icons.shopping_bag
                      : type == 'promotions'
                          ? Icons.local_offer
                          : Icons.notifications_off,
                  color: Colors.grey,
                  size: 64,
                ),
                const SizedBox(height: 16),
                Text(
                  'No ${type == 'all' ? '' : type} notifications yet.',
                  style: const TextStyle(
                    color: Colors.grey, 
                    fontFamily: 'PixelFont',
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          );
        }

        final notifications = snapshot.data!.docs;

        return ListView.builder(
          itemCount: notifications.length,
          itemBuilder: (context, index) {
            final notification = notifications[index].data() as Map<String, dynamic>;

            // Make sure timestamp is properly handled
            final DateTime timestamp;
            if (notification['timestamp'] is Timestamp) {
              timestamp = (notification['timestamp'] as Timestamp).toDate();
            } else {
              timestamp = DateTime.now(); // Fallback
            }

            final String formattedDate = DateFormat('MMM dd, yyyy • HH:mm').format(timestamp);

            // Use ?. and ?? for safe access to 'isRead' field
            final bool isRead = notification['isRead'] ?? false;
            
            return Dismissible(
              key: Key(notifications[index].id),
              background: Container(
                alignment: Alignment.centerLeft,
                padding: const EdgeInsets.only(left: 20),
                color: isRead ? _neonBlue.withOpacity(0.3) : _neonPink.withOpacity(0.3),
                child: Icon(
                  isRead ? Icons.mark_email_unread : Icons.mark_email_read,
                  color: isRead ? _neonBlue : _neonPink,
                  size: 28,
                ),
              ),
              secondaryBackground: Container(
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 20),
                color: Colors.red.withOpacity(0.3),
                child: const Icon(
                  Icons.delete_outline,
                  color: Colors.red,
                  size: 28,
                ),
              ),
              confirmDismiss: (direction) async {
                if (direction == DismissDirection.endToStart) {
                  // Delete action requires confirmation
                  final bool? result = await showDialog<bool>(
                    context: context,
                    builder: (dialogContext) => AlertDialog(
                      backgroundColor: const Color(0xFF1A1A2E),
                      title: const Text(
                        'Delete Notification',
                        style: TextStyle(
                          color: Colors.white,
                          fontFamily: 'PixelFont',
                          fontSize: 18,
                        ),
                      ),
                      content: const Text(
                        'Are you sure you want to delete this notification?',
                        style: TextStyle(
                          color: Colors.white70,
                          fontFamily: 'PixelFont',
                        ),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(dialogContext, false),
                          child: Text(
                            'CANCEL',
                            style: TextStyle(
                              color: _neonBlue,
                              fontFamily: 'PixelFont',
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(dialogContext, true),
                          child: const Text(
                            'DELETE',
                            style: TextStyle(
                              color: Colors.red,
                              fontFamily: 'PixelFont',
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                  return result ?? false;
                } else {
                  // For read/unread, no confirmation needed
                  return true;
                }
              },
              onDismissed: (direction) async {
                if (direction == DismissDirection.endToStart) {
                  // Delete notification
                  await FirebaseFirestore.instance
                      .collection('notifications')
                      .doc(notifications[index].id)
                      .delete();
                  
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Notification deleted',
                          style: TextStyle(fontFamily: 'PixelFont'),
                        ),
                        backgroundColor: Colors.red,
                        duration: Duration(seconds: 1),
                      ),
                    );
                  }
                } else {
                  // Toggle read status
                  final newReadStatus = !isRead;
                  await FirebaseFirestore.instance
                      .collection('notifications')
                      .doc(notifications[index].id)
                      .update({'isRead': newReadStatus});
                  
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          newReadStatus ? 'Marked as read' : 'Marked as unread',
                          style: const TextStyle(fontFamily: 'PixelFont'),
                        ),
                        backgroundColor: newReadStatus ? _neonPink : _neonBlue,
                        duration: const Duration(seconds: 1),
                      ),
                    );
                  }
                }
              },
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  border: Border.all(
                    color: isRead ? Colors.grey.withOpacity(0.3) : _neonBlue.withOpacity(0.5),
                    width: 1,
                  ),
                  boxShadow: [
                    if (!isRead)
                      BoxShadow(
                        color: _neonBlue.withOpacity(0.15),
                        blurRadius: 8,
                        spreadRadius: 1,
                      ),
                  ],
                ),
                child: InkWell(
                  onTap: () async {
                    // Existing onTap handling
                    if (!isRead) {
                      await FirebaseFirestore.instance
                          .collection('notifications')
                          .doc(notifications[index].id)
                          .update({'isRead': true});
                    }
                    
                    // Navigate to order details if it's an order notification
                    if (type == 'orders' || notification['type'] == 'orders') {
                      if (notification['orderId'] != null) {
                        final orderQuery = await FirebaseFirestore.instance
                            .collection('orders')
                            .where('orderId', isEqualTo: notification['orderId'])
                            .limit(1)
                            .get();
                            
                        if (orderQuery.docs.isNotEmpty) {
                          final orderData = orderQuery.docs.first.data();
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => OrderDetailsPage(
                                order: orderData,
                              ),
                            ),
                          );
                        }
                      }
                    }
                  },
                  onLongPress: () {
                    // Show context menu for read/unread options
                    _showNotificationOptions(context, notifications[index].id, isRead);
                  },
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(12),
                    leading: _buildNotificationLeading(notification, type),
                    title: Text(
                      notification['title'] ?? 'Notification',
                      style: TextStyle(
                        color: isRead ? Colors.white70 : Colors.white,
                        fontFamily: 'PixelFont',
                        fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Your existing subtitle content
                        const SizedBox(height: 4),
                        Text(
                          notification['message'] ?? '',
                          style: const TextStyle(color: Colors.grey, fontFamily: 'PixelFont'),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          formattedDate,
                          style: TextStyle(
                            color: Colors.cyan.withOpacity(0.6),
                            fontFamily: 'PixelFont',
                            fontSize: 12,
                          ),
                        ),
                        // Your existing conditional FutureBuilder for order items
                        if (type == 'orders' && notification['orderId'] != null)
                          FutureBuilder<DocumentSnapshot>(
                            future: FirebaseFirestore.instance
                                .collection('orders')
                                .where('orderId', isEqualTo: notification['orderId'])
                                .limit(1)
                                .get()
                                .then((snapshot) => snapshot.docs.first),
                            builder: (context, orderSnapshot) {
                              if (orderSnapshot.connectionState == ConnectionState.waiting) {
                                return const Padding(
                                  padding: EdgeInsets.only(top: 8.0),
                                  child: Text(
                                    'Loading order details...',
                                    style: TextStyle(color: Colors.grey, fontFamily: 'PixelFont', fontSize: 12),
                                  ),
                                );
                              }
                            
                              if (!orderSnapshot.hasData || orderSnapshot.hasError) {
                                return const SizedBox.shrink();
                              }
                            
                              final orderData = orderSnapshot.data!.data() as Map<String, dynamic>?;
                              if (orderData == null) return const SizedBox.shrink();
                              
                              final items = (orderData['items'] as List<dynamic>?) ?? [];
                              if (items.isEmpty) return const SizedBox.shrink();
                            
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Divider(color: Colors.white24),
                                  const Text(
                                    'ORDER ITEMS:',
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontFamily: 'PixelFont',
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  SizedBox(
                                    height: 40,
                                    child: ListView.builder(
                                      scrollDirection: Axis.horizontal,
                                      itemCount: items.length > 3 ? 3 : items.length,
                                      itemBuilder: (context, itemIndex) {
                                        final item = items[itemIndex];
                                        return Container(
                                          width: 40,
                                          height: 40,
                                          margin: const EdgeInsets.only(right: 8),
                                          decoration: BoxDecoration(
                                            border: Border.all(color: _neonPink, width: 1),
                                          ),
                                          child: item['imageUrl'] != null
                                              ? Image.network(
                                                  item['imageUrl'],
                                                  fit: BoxFit.cover,
                                                  loadingBuilder: (context, child, loadingProgress) {
                                                    if (loadingProgress == null) return child;
                                                    return Center(
                                                      child: CircularProgressIndicator(
                                                        value: loadingProgress.expectedTotalBytes != null
                                                            ? loadingProgress.cumulativeBytesLoaded /
                                                                loadingProgress.expectedTotalBytes!
                                                            : null,
                                                        strokeWidth: 2,
                                                        valueColor: AlwaysStoppedAnimation<Color>(_neonPink),
                                                      ),
                                                    );
                                                  },
                                                )
                                              : const Icon(Icons.image_not_supported, color: Colors.grey, size: 20),
                                        );
                                      },
                                    ),
                                  ),
                                  if (items.length > 3)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 4.0),
                                      child: Text(
                                        '+${items.length - 3} more',
                                        style: TextStyle(
                                          color: _neonBlue,
                                          fontFamily: 'PixelFont',
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                ],
                              );
                            },
                          ),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Read status indicator
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isRead ? Colors.transparent : _neonPink,
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Quick action button to toggle read status
                        IconButton(
                          icon: Icon(
                            isRead ? Icons.mark_email_unread : Icons.mark_email_read,
                            color: isRead ? _neonBlue.withOpacity(0.7) : _neonPink.withOpacity(0.7),
                            size: 20,
                          ),
                          onPressed: () async {
                            // Toggle read status
                            await FirebaseFirestore.instance
                                .collection('notifications')
                                .doc(notifications[index].id)
                                .update({'isRead': !isRead});
                            
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    isRead ? 'Marked as unread' : 'Marked as read',
                                    style: const TextStyle(fontFamily: 'PixelFont'),
                                  ),
                                  backgroundColor: isRead ? _neonBlue : _neonPink,
                                  duration: const Duration(seconds: 1),
                                ),
                              );
                            }
                          },
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          splashRadius: 18,
                        ),
                        const SizedBox(width: 8),
                        // Menu options button
                        IconButton(
                          icon: Icon(
                            Icons.more_vert,
                            color: Colors.grey.withOpacity(0.7),
                            size: 20,
                          ),
                          onPressed: () {
                            _showNotificationOptions(context, notifications[index].id, isRead);
                          },
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          splashRadius: 18,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildNotificationLeading(Map<String, dynamic> notification, String type) {
    // If notification has an image URL, show it
    if (notification['imageUrl'] != null && notification['imageUrl'].toString().isNotEmpty) {
      return Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          border: Border.all(
            color: _neonPink,
            width: 1.5,
          ),
        ),
        child: Image.network(
          notification['imageUrl'],
          fit: BoxFit.cover,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Center(
              child: CircularProgressIndicator(
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded /
                        loadingProgress.expectedTotalBytes!
                    : null,
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(_neonPink),
              ),
            );
          },
          errorBuilder: (context, error, stackTrace) {
            return _buildNotificationIcon(notification['type'] ?? type);
          },
        ),
      );
    } else {
      // Fallback to type-based icon
      return _buildNotificationIcon(notification['type'] ?? type);
    }
  }

  Widget _buildNotificationIcon(String type) {
    IconData iconData;
    Color iconColor;

    switch (type) {
      case 'orders':
        iconData = Icons.shopping_bag;
        iconColor = _neonPink;
        break;
      case 'promotions':
        iconData = Icons.local_offer;
        iconColor = _neonBlue;
        break;
      default:
        iconData = Icons.notifications;
        iconColor = Colors.cyan;
    }

    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: Colors.black,
        border: Border.all(color: iconColor.withOpacity(0.5)),
      ),
      child: Icon(
        iconData,
        color: iconColor,
        size: 28,
      ),
    );
  }

  void _showNotificationOptions(BuildContext context, String notificationId, bool isRead) {
    if (!context.mounted) return;
    
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A2E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.5),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          ListTile(
            leading: Icon(
              isRead ? Icons.mark_email_unread : Icons.mark_email_read,
              color: isRead ? _neonBlue : _neonPink,
            ),
            title: Text(
              isRead ? 'Mark as Unread' : 'Mark as Read',
              style: const TextStyle(
                color: Colors.white,
                fontFamily: 'PixelFont',
              ),
            ),
            onTap: () async {
              // Update the notification read status
              Navigator.pop(context); // Close the bottom sheet first
              
              await FirebaseFirestore.instance
                  .collection('notifications')
                  .doc(notificationId)
                  .update({'isRead': !isRead});
              
              // Only show snackbar if context is still valid
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      isRead ? 'Marked as unread' : 'Marked as read',
                      style: const TextStyle(fontFamily: 'PixelFont'),
                    ),
                    backgroundColor: isRead ? _neonBlue : _neonPink,
                    duration: const Duration(seconds: 1),
                  ),
                );
              }
            },
          ),
          ListTile(
            leading: const Icon(
              Icons.delete_outline,
              color: Colors.red,
            ),
            title: const Text(
              'Delete Notification',
              style: TextStyle(
                color: Colors.white,
                fontFamily: 'PixelFont',
              ),
            ),
            onTap: () {
              // First confirm the deletion
              _confirmDeleteNotification(context, notificationId);
            },
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  void _confirmDeleteNotification(BuildContext context, String notificationId) {
    if (!context.mounted) return;
    
    // Close the options sheet first
    Navigator.pop(context);
    
    // Small delay to ensure the previous dialog is closed
    Future.delayed(const Duration(milliseconds: 100), () {
      if (!context.mounted) return;
      
      // Show the confirmation dialog
      showDialog(
        context: context,
        builder: (dialogContext) => AlertDialog(
          backgroundColor: const Color(0xFF1A1A2E),
          title: const Text(
            'Delete Notification',
            style: TextStyle(
              color: Colors.white,
              fontFamily: 'PixelFont',
              fontSize: 18,
            ),
          ),
          content: const Text(
            'Are you sure you want to delete this notification?',
            style: TextStyle(
              color: Colors.white70,
              fontFamily: 'PixelFont',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(
                'CANCEL',
                style: TextStyle(
                  color: _neonBlue,
                  fontFamily: 'PixelFont',
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(dialogContext); // Close dialog first
                
                // Delete the notification
                await FirebaseFirestore.instance
                    .collection('notifications')
                    .doc(notificationId)
                    .delete();
                
                // Show confirmation only if context is still valid
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Notification deleted',
                        style: TextStyle(fontFamily: 'PixelFont'),
                      ),
                      backgroundColor: Colors.red,
                      duration: Duration(seconds: 1),
                    ),
                  );
                }
              },
              child: const Text(
                'DELETE',
                style: TextStyle(
                  color: Colors.red,
                  fontFamily: 'PixelFont',
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      );
    });
  }

  // Add this method to your _NotificationsPageState class

  void _showMarkAllReadDialog(BuildContext context) {
    if (!context.mounted) return;
    
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Text(
          'Mark All as Read',
          style: TextStyle(
            color: Colors.white,
            fontFamily: 'PixelFont',
            fontSize: 18,
          ),
        ),
        content: const Text(
          'Mark all notifications as read?',
          style: TextStyle(
            color: Colors.white70,
            fontFamily: 'PixelFont',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(
              'CANCEL',
              style: TextStyle(
                color: _neonBlue,
                fontFamily: 'PixelFont',
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          TextButton(
            onPressed: () async {
              final user = FirebaseAuth.instance.currentUser;
              if (user != null) {
                // Close the dialog first
                Navigator.pop(dialogContext);
                
                if (!context.mounted) return;
                
                // Show loading indicator
                _showLoadingDialog(context, 'Marking notifications as read...');
                
                try {
                  // Get all unread notifications for the current user
                  final unreadSnapshot = await FirebaseFirestore.instance
                      .collection('notifications')
                      .where('userId', isEqualTo: user.uid)
                      .where('isRead', isEqualTo: false)
                      .get();
                  
                  // Batch update
                  final batch = FirebaseFirestore.instance.batch();
                  
                  for (var doc in unreadSnapshot.docs) {
                    batch.update(doc.reference, {'isRead': true});
                  }
                  
                  await batch.commit();
                  
                  // Close loading and show confirmation
                  if (context.mounted) {
                    Navigator.pop(context); // Close loading dialog
                    
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Marked ${unreadSnapshot.docs.length} notifications as read',
                          style: const TextStyle(fontFamily: 'PixelFont'),
                        ),
                        backgroundColor: _neonPink,
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  }
                } catch (e) {
                  // Close loading and show error
                  if (context.mounted) {
                    Navigator.pop(context); // Close loading dialog
                    
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Error: $e',
                          style: const TextStyle(fontFamily: 'PixelFont'),
                        ),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              }
            },
            child: Text(
              'MARK ALL',
              style: TextStyle(
                color: _neonPink,
                fontFamily: 'PixelFont',
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Show a loading dialog
  void _showLoadingDialog(BuildContext context, String message) {
    if (!context.mounted) return;
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        content: Row(
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(_neonPink),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontFamily: 'PixelFont',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Add this method to your class

  void _showMarkAllUnreadDialog(BuildContext context) {
    if (!context.mounted) return;
    
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Text(
          'Mark All as Unread',
          style: TextStyle(
            color: Colors.white,
            fontFamily: 'PixelFont',
            fontSize: 18,
          ),
        ),
        content: const Text(
          'Mark all notifications as unread?',
          style: TextStyle(
            color: Colors.white70,
            fontFamily: 'PixelFont',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(
              'CANCEL',
              style: TextStyle(
                color: _neonBlue,
                fontFamily: 'PixelFont',
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          TextButton(
            onPressed: () async {
              final user = FirebaseAuth.instance.currentUser;
              if (user != null) {
                // Close the dialog first
                Navigator.pop(dialogContext);
                
                if (!context.mounted) return;
                
                // Show loading indicator
                _showLoadingDialog(context, 'Marking notifications as unread...');
                
                try {
                  // Get all read notifications for the current user
                  final readSnapshot = await FirebaseFirestore.instance
                      .collection('notifications')
                      .where('userId', isEqualTo: user.uid)
                      .where('isRead', isEqualTo: true)
                      .get();
                  
                  // Batch update
                  final batch = FirebaseFirestore.instance.batch();
                  
                  for (var doc in readSnapshot.docs) {
                    batch.update(doc.reference, {'isRead': false});
                  }
                  
                  await batch.commit();
                  
                  // Close loading and show confirmation
                  if (context.mounted) {
                    Navigator.pop(context); // Close loading dialog
                    
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Marked ${readSnapshot.docs.length} notifications as unread',
                          style: const TextStyle(fontFamily: 'PixelFont'),
                        ),
                        backgroundColor: _neonBlue,
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  }
                } catch (e) {
                  // Close loading and show error
                  if (context.mounted) {
                    Navigator.pop(context); // Close loading dialog
                    
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Error: $e',
                          style: const TextStyle(fontFamily: 'PixelFont'),
                        ),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              }
            },
            child: Text(
              'MARK ALL UNREAD',
              style: TextStyle(
                color: _neonBlue,
                fontFamily: 'PixelFont',
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}