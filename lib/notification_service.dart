import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Create order notification
  static Future<void> createOrderNotification({
    required String userId,
    required String orderId,
    required String status,
  }) async {
    String title = 'Order Update';
    String message = 'Your order has been updated.';
    
    // Customize message based on order status
    switch (status) {
      case 'placed':
        title = 'Order Placed Successfully';
        message = 'Your order #$orderId has been placed and is being processed.';
        break;
      case 'processing':
        title = 'Order Processing';
        message = 'Your order #$orderId is now being processed.';
        break;
      case 'shipped':
        title = 'Order Shipped';
        message = 'Your order #$orderId has been shipped and is on its way!';
        break;
      case 'delivered':
        title = 'Order Delivered';
        message = 'Your order #$orderId has been delivered. Enjoy!';
        break;
      case 'cancelled':
        title = 'Order Cancelled';
        message = 'Your order #$orderId has been cancelled.';
        break;
    }

    try {
      await _firestore.collection('notifications').add({
        'userId': userId,
        'type': 'orders',
        'title': title,
        'message': message,
        'orderId': orderId,
        'timestamp': FieldValue.serverTimestamp(),
      });
      
      print('Order notification created for order: $orderId');
    } catch (e) {
      print('Error creating order notification: $e');
    }
  }

  // Create promotion notification
  static Future<void> createPromotionNotification({
    required String userId,
    required String title,
    required String message,
  }) async {
    try {
      await _firestore.collection('notifications').add({
        'userId': userId,
        'type': 'promotions',
        'title': title,
        'message': message,
        'timestamp': FieldValue.serverTimestamp(),
      });
      
      print('Promotion notification created');
    } catch (e) {
      print('Error creating promotion notification: $e');
    }
  }

  // Delete notification
  static Future<void> deleteNotification(String notificationId) async {
    try {
      await _firestore.collection('notifications').doc(notificationId).delete();
    } catch (e) {
      print('Error deleting notification: $e');
    }
  }

  // Mark notification as read
  static Future<void> markAsRead(String notificationId) async {
    try {
      await _firestore.collection('notifications').doc(notificationId).update({
        'isRead': true,
      });
    } catch (e) {
      print('Error marking notification as read: $e');
    }
  }
}