import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'home.dart';
import 'category.dart';
import 'profile.dart';
import 'see_all_recommend.dart';
import 'shop.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';

class ChatPage extends StatefulWidget {
  const ChatPage({Key? key}) : super(key: key);

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _conversations = [];
  List<Map<String, dynamic>> _searchResults = [];
  Map<String, Map<String, dynamic>> _userDetails = {};
  List<Map<String, dynamic>> _stores = [];
  List<Map<String, dynamic>> _filteredStores = []; // Add this line
  bool _isLoading = true;
  bool _isSearching = false;

  int _currentNavIndex = 2; // Message is the 3rd item (index 2)

  @override
  void initState() {
    super.initState();
    _fetchConversations();
    _fetchStores();
    _filteredStores = _stores;
  }

  Future<void> _fetchConversations() async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    try {
      _firestore
          .collection('conversations')
          .where('participants', arrayContains: currentUser.uid)
          .orderBy('timestamp', descending: true)
          .snapshots()
          .listen((snapshot) async {
        final conversations = snapshot.docs.map((doc) {
          final data = doc.data();
          data['id'] = doc.id;
          return data;
        }).toList();

        for (var conversation in conversations) {
          final participants = conversation['participants'] as List;
          final recipientId = participants.firstWhere(
            (id) => id != currentUser.uid,
            orElse: () => '',
          );

          if (recipientId.isNotEmpty && !_userDetails.containsKey(recipientId)) {
            await _fetchUserDetails(recipientId);
          }
        }

        setState(() {
          _conversations = conversations;
          _isLoading = false;
        });
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      print('Error fetching conversations: $e');
    }
  }

  Future<void> _fetchUserDetails(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();

      if (userDoc.exists) {
        final userData = userDoc.data()!;
        userData['id'] = userDoc.id;

        setState(() {
          _userDetails[userId] = userData;
        });
      }
    } catch (e) {
      print('Error fetching user details: $e');
    }
  }

  Future<void> _searchUsers(String query) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
        _filteredStores = _stores; // Reset stores to show all
        _isSearching = false;
      });
      return;
    }

    setState(() {
      _isSearching = true;
    });

    try {
      // Search users
      final querySnapshot = await _firestore.collection('users').get();
      final results = querySnapshot.docs
          .map((doc) {
            final data = doc.data();
            data['id'] = doc.id;
            return data;
          })
          .where((user) =>
              user['id'] != currentUser.uid &&
              (user['displayName'] ?? '').toLowerCase().contains(query.toLowerCase()))
          .toList();

      // Filter stores
      final filteredStores = _stores.where((store) =>
          (store['storeName'] ?? '').toLowerCase().contains(query.toLowerCase())).toList();

      for (var user in results) {
        _userDetails[user['id']] = user;
      }

      setState(() {
        _searchResults = results;
        _filteredStores = filteredStores;
        _isSearching = false;
      });
    } catch (e) {
      setState(() {
        _isSearching = false;
      });
      print('Error searching: $e');
    }
  }

  Future<void> _fetchStores() async {
    try {
      final querySnapshot = await _firestore
          .collection('users')
          .where('sellerStatus', isEqualTo: 'approved')
          .get();

      setState(() {
        _stores = querySnapshot.docs
            .map((doc) {
              final data = doc.data();
              data['id'] = doc.id;
              return data;
            })
            .where((user) => user['storeName'] != null)
            .toList();
        _filteredStores = _stores; // Initialize filteredStores with all stores
      });
    } catch (e) {
      print('Error fetching stores: $e');
    }
  }

  void _navigateWithBottomBar(int index) {
    if (index == _currentNavIndex) return;

    Widget page;
    switch (index) {
      case 0:
        page = const HomePage();
        break;
      case 1:
        page = const CategoryPage();
        break;
      case 2:
        page = const ChatPage(); // Current page
        break;
      case 3:
        page = const SeeAllProductsScreen(); // Shop page
        break;
      case 4:
        page = const ProfileScreen();
        break;
      default:
        page = const HomePage();
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => page),
    );
  }

  void _startChat(String userId, String userName) {
    // Navigate directly to the chat detail page WITHOUT creating a conversation document
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatDetailPage(
          conversationId: _generateConversationId(userId),
          recipientId: userId,
          recipientName: userName,
        ),
      ),
    );
  }

  // Add this helper method to generate conversation IDs consistently
  String _generateConversationId(String otherUserId) {
    final currentUserId = _auth.currentUser!.uid;
    // Create a deterministic conversation ID based on user IDs
    return currentUserId.compareTo(otherUserId) < 0
        ? '${currentUserId}_$otherUserId'
        : '${otherUserId}_$currentUserId';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Messages',
          style: TextStyle(
            fontFamily: 'PixelFont',
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.black,
        elevation: 0,
      ),
      backgroundColor: Colors.black,
      body: Column(
        children: [
          // Search Bar with Cyberpunk design
          Container(
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade900,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.cyan.withOpacity(0.3),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.cyan.withOpacity(0.1),
                  blurRadius: 8,
                  spreadRadius: 0,
                ),
              ],
            ),
            child: TextField(
              controller: _searchController,
              style: const TextStyle(
                color: Colors.white,
                fontFamily: 'PixelFont',
              ),
              decoration: InputDecoration(
                hintText: 'Search users...',
                hintStyle: TextStyle(
                  color: Colors.grey.shade500,
                  fontFamily: 'PixelFont',
                ),
                prefixIcon: Icon(
                  Icons.search,
                  color: Colors.cyan.withOpacity(0.7),
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.all(16),
              ),
              onChanged: (value) => _searchUsers(value),
            ),
          ),

          // Store Slider
          _buildStoreSlider(),

          // Recent Conversations Header
          if (!_isSearching && _conversations.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.pink.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.history,
                      color: Colors.pink,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'RECENT CHATS',
                    style: TextStyle(
                      color: Colors.pink,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'PixelFont',
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
            ),

          Expanded(
            child: _isSearching
                ? const Center(
                    child: CircularProgressIndicator(
                      color: Colors.cyan,
                    ),
                  )
                : _searchResults.isNotEmpty
                    ? _buildSearchResults()
                    : _isLoading
                        ? const Center(
                            child: CircularProgressIndicator(
                              color: Colors.cyan,
                            ),
                          )
                        : _conversations.isEmpty
                            ? _buildEmptyState()
                            : _buildConversationsList(),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.black,
        selectedItemColor: const Color.fromARGB(255, 212, 0, 0),
        unselectedItemColor: Colors.white,
        selectedLabelStyle: const TextStyle(fontFamily: 'PixelFont', fontSize: 12),
        unselectedLabelStyle: const TextStyle(fontFamily: 'PixelFont', fontSize: 12),
        currentIndex: 2, // Set to 2 because Message is the third item
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
            case 2: // Message - already here
              break;
            case 3: // Cart
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const ShopPage()),
              );
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

  Widget _buildSearchResults() {
    return ListView.builder(
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final user = _searchResults[index];
        return Container(
          margin: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 8,
          ),
          decoration: BoxDecoration(
            color: Colors.grey.shade900,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.grey.shade800,
              width: 1,
            ),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.all(12),
            leading: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.cyan.withOpacity(0.5),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.cyan.withOpacity(0.2),
                    blurRadius: 8,
                    spreadRadius: 0,
                  ),
                ],
              ),
              child: CircleAvatar(
                radius: 24,
                backgroundColor: Colors.grey.shade800,
                backgroundImage: user['photoURL'] != null
                    ? CachedNetworkImageProvider(user['photoURL'])
                    : null,
                child: user['photoURL'] == null
                    ? const Icon(
                        Icons.person,
                        color: Colors.white,
                        size: 24,
                      )
                    : null,
              ),
            ),
            title: Text(
              user['displayName'] ?? 'Unknown User',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
                fontFamily: 'PixelFont',
              ),
            ),
            subtitle: Text(
              user['email'] ?? '',
              style: TextStyle(
                color: Colors.grey.shade400,
                fontFamily: 'PixelFont',
                fontSize: 14,
              ),
            ),
            trailing: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.cyan.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.chat,
                color: Colors.cyan,
                size: 20,
              ),
            ),
            onTap: () => _startChat(user['id'], user['displayName']),
          ),
        );
      },
    );
  }

  Widget _buildConversationsList() {
    return ListView.builder(
      itemCount: _conversations.length,
      itemBuilder: (context, index) {
        final conversation = _conversations[index];
        final participants = conversation['participants'] as List;
        final recipientId = participants.firstWhere(
          (id) => id != _auth.currentUser?.uid,
          orElse: () => '',
        );

        final recipientDetails = _userDetails[recipientId];
        final isStore = conversation['type'] == 'store';
        final displayName = isStore
            ? (conversation['storeName'] ?? 'Store')
            : (recipientDetails?['displayName'] ?? 'Unknown User');
        final avatarUrl = isStore
            ? (recipientDetails?['storeAvatar'] ?? null)
            : (recipientDetails?['photoURL'] ?? null);

        return Container(
          margin: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 8,
          ),
          decoration: BoxDecoration(
            color: Colors.grey.shade900,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.grey.shade800,
              width: 1,
            ),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.all(12),
            leading: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isStore
                      ? Colors.purple.withOpacity(0.5)
                      : Colors.cyan.withOpacity(0.5),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: isStore
                        ? Colors.purple.withOpacity(0.2)
                        : Colors.cyan.withOpacity(0.2),
                    blurRadius: 8,
                    spreadRadius: 0,
                  ),
                ],
              ),
              child: CircleAvatar(
                radius: 24,
                backgroundColor: Colors.grey.shade800,
                backgroundImage: avatarUrl != null
                    ? CachedNetworkImageProvider(avatarUrl)
                    : null,
                child: avatarUrl == null
                    ? Icon(
                        isStore ? Icons.store : Icons.person,
                        color: Colors.white,
                        size: 24,
                      )
                    : null,
              ),
            ),
            title: Text(
              displayName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
                fontFamily: 'PixelFont',
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(
                  conversation['lastMessage'] ?? '',
                  style: TextStyle(
                    color: Colors.grey.shade400,
                    fontFamily: 'PixelFont',
                    fontSize: 14,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  _formatTimestamp(conversation['timestamp']),
                  style: TextStyle(
                    color: Colors.grey.shade500,
                    fontSize: 12,
                    fontFamily: 'PixelFont',
                  ),
                ),
              ],
            ),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ChatDetailPage(
                  conversationId: conversation['id'],
                  recipientId: recipientId,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: 64,
            color: Colors.grey.shade700,
          ),
          const SizedBox(height: 16),
          Text(
            'No conversations yet',
            style: TextStyle(
              color: Colors.grey.shade500,
              fontSize: 18,
              fontFamily: 'PixelFont',
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start chatting with other users',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 14,
              fontFamily: 'PixelFont',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStoreSlider() {
    if (_filteredStores.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Stores Header
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.purple.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.store,
                  color: Colors.purple,
                  size: 20,
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'STORES',
                style: TextStyle(
                  color: Colors.purple,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'PixelFont',
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
        ),
        // Stores Slider
        SizedBox(
          height: 120,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            itemCount: _filteredStores.length,
            itemBuilder: (context, index) {
              final store = _filteredStores[index];
              return Container(
                width: 100,
                margin: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  color: Colors.grey.shade900,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.purple.withOpacity(0.3),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.purple.withOpacity(0.1),
                      blurRadius: 8,
                      spreadRadius: 0,
                    ),
                  ],
                ),
                child: InkWell(
                  onTap: () => _startChat(store['id'], store['storeName']),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.purple.withOpacity(0.5),
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.purple.withOpacity(0.2),
                              blurRadius: 8,
                              spreadRadius: 0,
                            ),
                          ],
                        ),
                        child: CircleAvatar(
                          radius: 30,
                          backgroundColor: Colors.grey.shade800,
                          backgroundImage: store['storeAvatar'] != null
                              ? CachedNetworkImageProvider(store['storeAvatar'])
                              : null,
                          child: store['storeAvatar'] == null
                              ? const Icon(
                                  Icons.store,
                                  color: Colors.white,
                                  size: 30,
                                )
                              : null,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        store['storeName'] ?? 'Unknown Store',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontFamily: 'PixelFont',
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 2,
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class ChatDetailPage extends StatefulWidget {
  final String conversationId;
  final String recipientId;
  final String? recipientName; // <-- Add this

  const ChatDetailPage({
    Key? key,
    required this.conversationId,
    required this.recipientId,
    this.recipientName, // <-- Add this
  }) : super(key: key);

  @override
  State<ChatDetailPage> createState() => _ChatDetailPageState();
}

class _ChatDetailPageState extends State<ChatDetailPage> {
  final TextEditingController _messageController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  Map<String, dynamic>? _recipientData;
  bool _isLoading = true;
  final ImagePicker _picker = ImagePicker();
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _fetchRecipientData();
  }

  Future<void> _fetchRecipientData() async {
    try {
      final userDoc = await _firestore.collection('users').doc(widget.recipientId).get();
      
      if (userDoc.exists) {
        setState(() {
          _recipientData = userDoc.data();
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error fetching recipient data: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _sendMessage() async {
    final user = _auth.currentUser;
    if (user == null || _messageController.text.trim().isEmpty) return;

    final message = _messageController.text.trim();
    _messageController.clear();

    try {
      // Check if conversation document exists
      final conversationDoc = await _firestore
          .collection('conversations')
          .doc(widget.conversationId)
          .get();
    
      // If conversation doesn't exist, create it first
      if (!conversationDoc.exists) {
        await _firestore.collection('conversations').doc(widget.conversationId).set({
          'participants': [user.uid, widget.recipientId],
          'lastMessage': message,
          'timestamp': FieldValue.serverTimestamp(),
        });
      } else {
        // Just update the existing conversation
        await _firestore.collection('conversations').doc(widget.conversationId).update({
          'lastMessage': message,
          'timestamp': FieldValue.serverTimestamp(),
        });
      }

      // Add message to the conversation's messages subcollection
      await _firestore
          .collection('conversations')
          .doc(widget.conversationId)
          .collection('messages')
          .add({
        'senderId': user.uid,
        'recipientId': widget.recipientId,
        'message': message,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error sending message: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send message: $e')),
      );
    }
  }

  Future<void> _sendImage() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image == null) return;

      setState(() {
        _isUploading = true;
      });

      // Upload image to Firebase Storage
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('chat_images')
          .child('${DateTime.now().millisecondsSinceEpoch}.jpg');

      final uploadTask = await storageRef.putFile(File(image.path));
      final imageUrl = await uploadTask.ref.getDownloadURL();

      // Send message with image URL
      final user = _auth.currentUser;
      if (user == null) return;

      // Check if conversation exists
      final conversationDoc = await _firestore
          .collection('conversations')
          .doc(widget.conversationId)
          .get();

      if (!conversationDoc.exists) {
        await _firestore.collection('conversations').doc(widget.conversationId).set({
          'participants': [user.uid, widget.recipientId],
          'lastMessage': '📷 Image',
          'timestamp': FieldValue.serverTimestamp(),
        });
      } else {
        await _firestore.collection('conversations').doc(widget.conversationId).update({
          'lastMessage': '📷 Image',
          'timestamp': FieldValue.serverTimestamp(),
        });
      }

      // Add message with image
      await _firestore
          .collection('conversations')
          .doc(widget.conversationId)
          .collection('messages')
          .add({
        'senderId': user.uid,
        'recipientId': widget.recipientId,
        'message': '',
        'imageUrl': imageUrl,
        'timestamp': FieldValue.serverTimestamp(),
      });

    } catch (e) {
      print('Error sending image: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to send image')),
      );
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }

  // Modify the message bubble builder in the StreamBuilder to handle images
  Widget _buildMessageBubble(Map<String, dynamic> messageData, bool isCurrentUser) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: Column(
        crossAxisAlignment: isCurrentUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: isCurrentUser ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (!isCurrentUser) _buildAvatar(_recipientData),
              if (!isCurrentUser) const SizedBox(width: 8),
              Container(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.7,
                ),
                padding: messageData['imageUrl'] != null 
                    ? const EdgeInsets.all(4)
                    : const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isCurrentUser ? Colors.cyan : Colors.grey.shade800,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: messageData['imageUrl'] != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: CachedNetworkImage(
                          imageUrl: messageData['imageUrl'],
                          placeholder: (context, url) => const SizedBox(
                            height: 200,
                            child: Center(
                              child: CircularProgressIndicator(color: Colors.white),
                            ),
                          ),
                          errorWidget: (context, url, error) => const Icon(
                            Icons.error,
                            color: Colors.white,
                          ),
                        ),
                      )
                    : Text(
                        messageData['message'] ?? '',
                        style: const TextStyle(color: Colors.white),
                      ),
              ),
              if (isCurrentUser) const SizedBox(width: 8),
              if (isCurrentUser) _buildAvatar(null),
            ],
          ),
          const SizedBox(height: 2),
          if (messageData['timestamp'] != null)
            Padding(
              padding: EdgeInsets.only(
                left: isCurrentUser ? 0 : 32,
                right: isCurrentUser ? 32 : 0,
              ),
              child: Text(
                DateFormat('h:mm a').format(messageData['timestamp'].toDate()),
                style: TextStyle(
                  color: Colors.grey.shade500,
                  fontSize: 10,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAvatar(Map<String, dynamic>? userData) {
    return CircleAvatar(
      radius: 12,
      backgroundColor: Colors.grey.shade800,
      backgroundImage: userData?['photoURL'] != null
          ? CachedNetworkImageProvider(userData!['photoURL'])
          : null,
      child: userData?['photoURL'] == null
          ? const Icon(Icons.person, color: Colors.white, size: 12)
          : null,
    );
  }

  // Update the build method to use the new message bubble builder and add loading indicator
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: widget.recipientName != null
            ? Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: Colors.grey.shade800,
                    backgroundImage: _recipientData?['photoURL'] != null
                        ? CachedNetworkImageProvider(_recipientData!['photoURL'])
                        : null,
                    child: _recipientData?['photoURL'] == null
                        ? const Icon(Icons.person, color: Colors.white, size: 16)
                        : null,
                  ),
                  const SizedBox(width: 8),
                  Text(widget.recipientName!), // <-- Use store name if provided
                ],
              )
            : _isLoading
                ? const Text('Loading...')
                : Row(
                    children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundColor: Colors.grey.shade800,
                        backgroundImage: _recipientData?['photoURL'] != null
                            ? CachedNetworkImageProvider(_recipientData!['photoURL'])
                            : null,
                        child: _recipientData?['photoURL'] == null
                            ? const Icon(Icons.person, color: Colors.white, size: 16)
                            : null,
                      ),
                      const SizedBox(width: 8),
                      Text(_recipientData?['displayName'] ?? 'Unknown User'),
                    ],
                  ),
        backgroundColor: Colors.black,
      ),
      backgroundColor: Colors.black,
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('conversations')
                  .doc(widget.conversationId)
                  .collection('messages')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
                  return const Center(
                    child: CircularProgressIndicator(color: Colors.cyan),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Text(
                      'No messages yet',
                      style: TextStyle(color: Colors.white),
                    ),
                  );
                }

                final messages = snapshot.data!.docs;

                return ListView.builder(
                  reverse: true,
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final messageData = messages[index].data() as Map<String, dynamic>;
                    final isCurrentUser = messageData['senderId'] == _auth.currentUser?.uid;
                    final messageTime = messageData['timestamp'] as Timestamp?;
                    
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                      child: _buildMessageBubble(messageData, isCurrentUser),
                    );
                  },
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            color: Colors.grey.shade900,
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.photo, color: Colors.grey),
                  onPressed: _isUploading ? null : _sendImage,
                ),
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Type a message...',
                      hintStyle: TextStyle(color: Colors.grey.shade500),
                      filled: true,
                      fillColor: Colors.grey.shade800,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    maxLines: null,
                    textCapitalization: TextCapitalization.sentences,
                  ),
                ),
                const SizedBox(width: 8),
                InkWell(
                  onTap: _sendMessage,
                  child: Container(
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.cyan,
                    ),
                    padding: const EdgeInsets.all(8),
                    child: const Icon(
                      Icons.send,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
                // Add loading indicator if uploading
                if (_isUploading)
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.cyan,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

void startStoreChat(BuildContext context, String sellerId, String sellerName) {
  final FirebaseAuth auth = FirebaseAuth.instance;
  final currentUser = auth.currentUser;
  if (currentUser == null) return;

  // Generate conversation ID
  final conversationId = currentUser.uid.compareTo(sellerId) < 0
      ? '${currentUser.uid}_$sellerId'
      : '${sellerId}_${currentUser.uid}';

  // Navigate directly without creating the conversation document
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => ChatDetailPage(
        conversationId: conversationId,
        recipientId: sellerId,
        recipientName: sellerName,
      ),
    ),
  );
}

String _formatTimestamp(Timestamp? timestamp) {
  if (timestamp == null) return '';

  final now = DateTime.now();
  final messageTime = timestamp.toDate();
  final difference = now.difference(messageTime);

  if (difference.inDays == 0) {
    return DateFormat('h:mm a').format(messageTime);
  } else if (difference.inDays < 7) {
    return DateFormat('E').format(messageTime);
  } else {
    return DateFormat('MMM d').format(messageTime);
  }
}