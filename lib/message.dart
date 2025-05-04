import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'home.dart';
import 'category.dart';
import 'profile.dart';
import 'see_all_recommend.dart';

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
  bool _isLoading = true;
  bool _isSearching = false;

  int _currentNavIndex = 2; // Message is the 3rd item (index 2)

  @override
  void initState() {
    super.initState();
    _fetchConversations();
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
        _isSearching = false;
      });
      return;
    }

    setState(() {
      _isSearching = true;
    });

    try {
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

      for (var user in results) {
        _userDetails[user['id']] = user;
      }

      setState(() {
        _searchResults = results;
        _isSearching = false;
      });
    } catch (e) {
      setState(() {
        _isSearching = false;
      });
      print('Error searching users: $e');
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

  void _startChat(String userId, String userName) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    final conversationId = currentUser.uid.compareTo(userId) < 0
        ? '${currentUser.uid}_$userId'
        : '${userId}_${currentUser.uid}';

    final conversationRef = _firestore.collection('conversations').doc(conversationId);
    final conversationSnapshot = await conversationRef.get();

    if (!conversationSnapshot.exists) {
      await conversationRef.set({
        'participants': [currentUser.uid, userId],
        'lastMessage': '',
        'timestamp': FieldValue.serverTimestamp(),
      });
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatDetailPage(
          conversationId: conversationId,
          recipientId: userId,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Messages',
          style: TextStyle(fontFamily: 'PixelFont'), // Apply PixelFont
        ),
        backgroundColor: Colors.black,
      ),
      backgroundColor: Colors.black,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              style: const TextStyle(color: Colors.white, fontFamily: 'PixelFont'), // Apply PixelFont
              decoration: InputDecoration(
                hintText: 'Search users...',
                hintStyle: const TextStyle(color: Colors.grey, fontFamily: 'PixelFont'), // Apply PixelFont
                prefixIcon: const Icon(Icons.search, color: Colors.white),
                filled: true,
                fillColor: Colors.grey.shade800,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (value) => _searchUsers(value),
            ),
          ),
          Expanded(
            child: _isSearching
                ? const Center(
                    child: CircularProgressIndicator(color: Colors.cyan),
                  )
                : _searchResults.isNotEmpty
                    ? ListView.builder(
                        itemCount: _searchResults.length,
                        itemBuilder: (context, index) {
                          final user = _searchResults[index];
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Colors.grey.shade800,
                              backgroundImage: user['photoURL'] != null
                                  ? CachedNetworkImageProvider(user['photoURL'])
                                  : null,
                              child: user['photoURL'] == null
                                  ? const Icon(Icons.person, color: Colors.white)
                                  : null,
                            ),
                            title: Text(
                              user['displayName'] ?? 'Unknown User',
                              style: const TextStyle(color: Colors.white, fontFamily: 'PixelFont'), // Apply PixelFont
                            ),
                            subtitle: Text(
                              user['email'] ?? '',
                              style: const TextStyle(color: Colors.grey, fontFamily: 'PixelFont'), // Apply PixelFont
                            ),
                            onTap: () => _startChat(user['id'], user['displayName']),
                          );
                        },
                      )
                    : _isLoading
                        ? const Center(
                            child: CircularProgressIndicator(color: Colors.cyan),
                          )
                        : _conversations.isEmpty
                            ? const Center(
                                child: Text(
                                  'No conversations found',
                                  style: TextStyle(color: Colors.white, fontSize: 16, fontFamily: 'PixelFont'), // Apply PixelFont
                                ),
                              )
                            : ListView.builder(
                                itemCount: _conversations.length,
                                itemBuilder: (context, index) {
                                  final conversation = _conversations[index];
                                  final participants = conversation['participants'] as List;
                                  final recipientId = participants.firstWhere(
                                    (id) => id != _auth.currentUser?.uid,
                                    orElse: () => '',
                                  );

                                  final recipientDetails = _userDetails[recipientId];
                                  final recipientName = recipientDetails?['displayName'] ?? 'Unknown User';
                                  final photoURL = recipientDetails?['photoURL'];

                                  return ListTile(
                                    leading: CircleAvatar(
                                      backgroundColor: Colors.grey.shade800,
                                      backgroundImage: photoURL != null
                                          ? CachedNetworkImageProvider(photoURL)
                                          : null,
                                      child: photoURL == null
                                          ? const Icon(Icons.person, color: Colors.white)
                                          : null,
                                    ),
                                    title: Text(
                                      recipientName,
                                      style: const TextStyle(color: Colors.white, fontFamily: 'PixelFont'), // Apply PixelFont
                                    ),
                                    subtitle: Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            conversation['lastMessage'] ?? '',
                                            style: const TextStyle(color: Colors.grey, fontFamily: 'PixelFont'), // Apply PixelFont
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                    trailing: Text(
                                      _formatTimestamp(conversation['timestamp']),
                                      style: TextStyle(color: Colors.grey.shade500, fontSize: 12, fontFamily: 'PixelFont'), // Apply PixelFont
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
                                  );
                                },
                              ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.black,
        selectedItemColor: const Color.fromARGB(255, 212, 0, 0),
        unselectedItemColor: Colors.white,
        currentIndex: _currentNavIndex,
        onTap: _navigateWithBottomBar,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.category), label: 'Category'),
          BottomNavigationBarItem(icon: Icon(Icons.message), label: 'Message'),
          BottomNavigationBarItem(icon: Icon(Icons.shop), label: 'Shop'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
        selectedLabelStyle: const TextStyle(
          fontFamily: 'PixelFont',
          fontSize: 12,
        ),
        unselectedLabelStyle: const TextStyle(
          fontFamily: 'PixelFont',
          fontSize: 12,
        ),
      ),
    );
  }
}

class ChatDetailPage extends StatefulWidget {
  final String conversationId;
  final String recipientId;

  const ChatDetailPage({
    Key? key,
    required this.conversationId,
    required this.recipientId,
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

      // Update the conversation's last message and timestamp
      await _firestore.collection('conversations').doc(widget.conversationId).update({
        'lastMessage': message,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error sending message: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send message: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _isLoading
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
                      child: Column(
                        crossAxisAlignment: isCurrentUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: isCurrentUser ? MainAxisAlignment.end : MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              if (!isCurrentUser)
                                CircleAvatar(
                                  radius: 12,
                                  backgroundColor: Colors.grey.shade800,
                                  backgroundImage: _recipientData?['photoURL'] != null
                                      ? CachedNetworkImageProvider(_recipientData!['photoURL'])
                                      : null,
                                  child: _recipientData?['photoURL'] == null
                                      ? const Icon(Icons.person, color: Colors.white, size: 12)
                                      : null,
                                ),
                              if (!isCurrentUser) const SizedBox(width: 8),
                              Container(
                                constraints: BoxConstraints(
                                  maxWidth: MediaQuery.of(context).size.width * 0.7,
                                ),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: isCurrentUser ? Colors.cyan : Colors.grey.shade800,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Text(
                                  messageData['message'] ?? '',
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ),
                              if (isCurrentUser) const SizedBox(width: 8),
                              if (isCurrentUser)
                                CircleAvatar(
                                  radius: 12,
                                  backgroundColor: Colors.grey.shade800,
                                  backgroundImage: _auth.currentUser?.photoURL != null
                                      ? NetworkImage(_auth.currentUser!.photoURL!)
                                      : null,
                                  child: _auth.currentUser?.photoURL == null
                                      ? const Icon(Icons.person, color: Colors.white, size: 12)
                                      : null,
                                ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          if (messageTime != null)
                            Padding(
                              padding: EdgeInsets.only(
                                left: isCurrentUser ? 0 : 32,
                                right: isCurrentUser ? 32 : 0,
                              ),
                              child: Text(
                                DateFormat('h:mm a').format(messageTime.toDate()),
                                style: TextStyle(
                                  color: Colors.grey.shade500,
                                  fontSize: 10,
                                ),
                              ),
                            ),
                        ],
                      ),
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
                  onPressed: () {
                    // TODO: Implement image sending functionality
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Image upload coming soon!')),
                    );
                  },
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
              ],
            ),
          ),
        ],
      ),
    );
  }
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