import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cached_network_image/cached_network_image.dart';

class FriendsPage extends StatefulWidget {
  const FriendsPage({Key? key}) : super(key: key);

  @override
  State<FriendsPage> createState() => _FriendsPageState();
}

class _FriendsPageState extends State<FriendsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = false;
  List<Map<String, dynamic>> _friends = [];
  List<Map<String, dynamic>> _friendRequests = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadFriends();
    _loadFriendRequests();
  }

  Future<void> _loadFriends() async {
    setState(() => _isLoading = true);
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) throw 'User not logged in';

      final friendsSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('friends')
          .where('status', isEqualTo: 'accepted')
          .get();

      final List<Map<String, dynamic>> friends = [];
      for (var doc in friendsSnapshot.docs) {
        final friendId = doc.id;
        final friendData = await FirebaseFirestore.instance
            .collection('users')
            .doc(friendId)
            .get();

        if (friendData.exists) {
          friends.add({
            'id': friendId,
            'name': friendData['displayName'] ?? 'Unknown User',
            'photoURL': friendData['photoURL'],
            'status': friendData['onlineStatus'] ?? 'offline',
            'lastSeen': friendData['lastSeen'],
            'level': friendData['level'] ?? 1,
          });
        }
      }

      setState(() {
        _friends = friends;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _loadFriendRequests() async {
    try {
      setState(() => _isLoading = true);
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) throw 'User not logged in';

      // Get friend requests where status is pending and current user is not the sender
      final requestsSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('friends')
          .where('status', isEqualTo: 'pending')
          .where('senderId', isNotEqualTo: userId)
          .orderBy('senderId') // Required for inequality queries
          .orderBy('timestamp', descending: true)
          .get();

      final List<Map<String, dynamic>> requests = [];

      for (var doc in requestsSnapshot.docs) {
        try {
          final senderId = doc.data()['senderId'] as String;
          final senderDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(senderId)
              .get();

          if (senderDoc.exists) {
            requests.add({
              'id': senderId,
              'name': senderDoc.data()?['displayName'] ?? 'Unknown User',
              'photoURL': senderDoc.data()?['photoURL'],
              'level': senderDoc.data()?['level'] ?? 1,
              'timestamp': doc.data()['timestamp'],
              'status': doc.data()['status'],
            });
          }
        } catch (e) {
          print('Error processing request: $e');
        }
      }

      setState(() {
        _friendRequests = requests;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading friend requests: $e');
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<bool> _checkExistingFriendship(String targetUserId) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return false;

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('friends')
        .doc(targetUserId)
        .get();

    return doc.exists;
  }

  Future<void> _sendFriendRequest(String targetUserId) async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) return;

      // Check if friendship already exists
      final exists = await _checkExistingFriendship(targetUserId);
      if (exists) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Friend request already sent or already friends'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      final timestamp = FieldValue.serverTimestamp();
      final requestData = {
        'status': 'pending',
        'timestamp': timestamp,
        'lastInteraction': timestamp,
        'senderId': userId,
      };

      // Create friend request in both collections
      final batch = FirebaseFirestore.instance.batch();

      // In sender's collection
      batch.set(
        FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .collection('friends')
            .doc(targetUserId),
        requestData,
      );

      // In receiver's collection
      batch.set(
        FirebaseFirestore.instance
            .collection('users')
            .doc(targetUserId)
            .collection('friends')
            .doc(userId),
        requestData,
      );

      // Update friend request count
      batch.update(
        FirebaseFirestore.instance.collection('users').doc(targetUserId),
        {'friendRequestCount': FieldValue.increment(1)},
      );

      await batch.commit();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Friend request sent!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error sending friend request: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _acceptFriendRequest(String friendId) async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) return;

      // Update both users' friend collections
      final batch = FirebaseFirestore.instance.batch();

      final userFriendRef = FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('friends')
          .doc(friendId);

      final friendUserRef = FirebaseFirestore.instance
          .collection('users')
          .doc(friendId)
          .collection('friends')
          .doc(userId);

      batch.update(userFriendRef, {
        'status': 'accepted',
        'lastInteraction': FieldValue.serverTimestamp(),
      });

      batch.update(friendUserRef, {
        'status': 'accepted',
        'lastInteraction': FieldValue.serverTimestamp(),
      });

      // Update friend counts for both users
      final userRef =
          FirebaseFirestore.instance.collection('users').doc(userId);
      final friendRef =
          FirebaseFirestore.instance.collection('users').doc(friendId);

      batch.update(userRef, {
        'friendCount': FieldValue.increment(1),
        'friendRequestCount': FieldValue.increment(-1),
      });

      batch.update(friendRef, {
        'friendCount': FieldValue.increment(1),
      });

      await batch.commit();

      // Refresh lists
      await _loadFriends();
      await _loadFriendRequests();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Friend request accepted!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error accepting friend request: $e')),
      );
    }
  }

  Future<void> _rejectFriendRequest(String friendId) async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) return;

      // Delete from both users' friend collections
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('friends')
          .doc(friendId)
          .delete();

      await FirebaseFirestore.instance
          .collection('users')
          .doc(friendId)
          .collection('friends')
          .doc(userId)
          .delete();

      // Update friend request count
      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'friendRequestCount': FieldValue.increment(-1),
      });

      // Refresh lists
      await _loadFriendRequests();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Friend request rejected'),
          backgroundColor: Colors.grey,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error rejecting friend request: $e')),
      );
    }
  }

  Future<void> _showAddFriendDialog() async {
    String searchQuery = '';

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: const Color(0xFF1A1A2E),
          title: const Text(
            'Add Friend',
            style: TextStyle(
              color: Colors.white,
              fontFamily: 'PixelFont',
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  hintText: 'Search by username',
                  hintStyle: TextStyle(color: Colors.grey),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFFFF0077)),
                  ),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFFFF0077)),
                  ),
                ),
                onChanged: (value) => searchQuery = value,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF0077),
                  foregroundColor: Colors.white,
                ),
                onPressed: () async {
                  if (searchQuery.isEmpty) return;

                  final usersSnapshot = await FirebaseFirestore.instance
                      .collection('users')
                      .where('displayName', isEqualTo: searchQuery)
                      .get();

                  if (usersSnapshot.docs.isNotEmpty) {
                    final foundUser = usersSnapshot.docs.first;
                    final currentUserId =
                        FirebaseAuth.instance.currentUser?.uid;

                    if (foundUser.id != currentUserId) {
                      Navigator.pop(context);
                      _sendFriendRequest(foundUser.id);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("You can't add yourself as a friend"),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('User not found'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
                child: const Text(
                  'SEARCH',
                  style: TextStyle(fontFamily: 'PixelFont'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text(
          'FRIENDS',
          style: TextStyle(
            fontFamily: 'PixelFont',
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
          ),
        ),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFFFF0077),
          tabs: const [
            Tab(text: 'FRIENDS'),
            Tab(text: 'REQUESTS'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add, color: Color(0xFFFF0077)),
            onPressed: _showAddFriendDialog,
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildFriendsList(),
          _buildRequestsList(),
        ],
      ),
    );
  }

  Widget _buildFriendsList() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFFFF0077)),
      );
    }

    if (_error != null) {
      return Center(
        child: Text(
          _error!,
          style: const TextStyle(color: Colors.red),
        ),
      );
    }

    if (_friends.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 64, color: Colors.grey.shade700),
            const SizedBox(height: 16),
            const Text(
              'No friends yet',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontFamily: 'PixelFont',
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: _friends.length,
      itemBuilder: (context, index) {
        final friend = _friends[index];
        return _buildFriendCard(friend);
      },
    );
  }

  Widget _buildRequestsList() {
    if (_friendRequests.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.person_add_disabled,
                size: 64, color: Colors.grey.shade700),
            const SizedBox(height: 16),
            const Text(
              'No friend requests',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontFamily: 'PixelFont',
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: _friendRequests.length,
      itemBuilder: (context, index) {
        final request = _friendRequests[index];
        return _buildRequestCard(request);
      },
    );
  }

  Widget _buildFriendCard(Map<String, dynamic> friend) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF333355)),
      ),
      child: ListTile(
        leading: Stack(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: const Color(0xFFFF0077),
              backgroundImage: friend['photoURL'] != null
                  ? NetworkImage(friend['photoURL'])
                  : null,
              child: friend['photoURL'] == null
                  ? const Icon(Icons.person, color: Colors.white)
                  : null,
            ),
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color:
                      friend['status'] == 'online' ? Colors.green : Colors.grey,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
              ),
            ),
          ],
        ),
        title: Text(
          friend['name'],
          style: const TextStyle(
            color: Colors.white,
            fontFamily: 'PixelFont',
            fontSize: 16,
          ),
        ),
        subtitle: Text(
          'Level ${friend['level']}',
          style: TextStyle(
            color: Colors.grey.shade400,
            fontFamily: 'PixelFont',
            fontSize: 12,
          ),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.more_vert, color: Colors.white),
          onPressed: () {
            // TODO: Show friend options menu
          },
        ),
      ),
    );
  }

  Widget _buildRequestCard(Map<String, dynamic> request) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF333355)),
      ),
      child: ListTile(
        leading: CircleAvatar(
          radius: 24,
          backgroundColor: const Color(0xFFFF0077),
          backgroundImage: request['photoURL'] != null
              ? NetworkImage(request['photoURL'])
              : null,
          child: request['photoURL'] == null
              ? const Icon(Icons.person, color: Colors.white)
              : null,
        ),
        title: Text(
          request['name'],
          style: const TextStyle(
            color: Colors.white,
            fontFamily: 'PixelFont',
            fontSize: 16,
          ),
        ),
        subtitle: Text(
          'Level ${request['level']}',
          style: TextStyle(
            color: Colors.grey.shade400,
            fontFamily: 'PixelFont',
            fontSize: 12,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.check, color: Colors.green),
              onPressed: () => _acceptFriendRequest(request['id']),
            ),
            IconButton(
              icon: const Icon(Icons.close, color: Colors.red),
              onPressed: () => _rejectFriendRequest(request['id']),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}
