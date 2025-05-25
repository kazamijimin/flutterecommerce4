import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'message.dart';

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
  final _auth = FirebaseAuth.instance;

  // Add these new class variables to _FriendsPageState
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _searchResults = [];
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadFriends();
    _fixFriendRequests().then((_) => _loadFriendRequests());

    // Clear search when tab changes
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        setState(() {
          _searchResults = [];
          _searchController.clear();
        });
      }
    });
  }

  Future<void> _loadFriends() async {
    if (!mounted) return;
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
        try {
          final friendData = await FirebaseFirestore.instance
              .collection('users')
              .doc(friendId)
              .get();

          if (friendData.exists) {
            final data = friendData.data();
            if (data != null) {
              // Debug info
              print('Friend data fields: ${data.keys.toList()}');

              // Determine online status with safe access
              String onlineStatus = 'offline';
              if (data.containsKey('status')) {
                onlineStatus = data['status'] as String? ?? 'offline';
              } else if (data.containsKey('onlineStatus')) {
                onlineStatus = data['onlineStatus'] as String? ?? 'offline';
              }

              friends.add({
                'id': friendId,
                'name': data['displayName'] ?? 'Unknown User',
                'photoURL': data['photoURL'],
                'status': onlineStatus,
                'lastSeen': data['lastSeen'],
                'level': data['level'] ?? 1,
              });
            }
          }
        } catch (e) {
          print('Error loading friend $friendId: $e');
          // Continue with next friend instead of failing the whole process
        }
      }

      if (mounted) {
        setState(() {
          _friends = friends;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading friends: $e');
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadFriendRequests() async {
    if (!mounted) return;

    try {
      setState(() => _isLoading = true);
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) throw 'User not logged in';

      print("Current user ID: $userId");

      final requestsSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('friends')
          .where('status', isEqualTo: 'pending')
          .get();

      print("Friend requests found: ${requestsSnapshot.docs.length}");

      final List<Map<String, dynamic>> requests = [];

      for (var doc in requestsSnapshot.docs) {
        try {
          final data = doc.data();
          // Check if senderId exists in the document
          if (!data.containsKey('senderId')) {
            print("Warning: Document ${doc.id} doesn't have senderId field");
            continue;
          }

          final senderId = data['senderId'] as String?;
          if (senderId == null) {
            print("Warning: senderId is null in document ${doc.id}");
            continue;
          }

          print("Request from sender: $senderId");

          // Skip requests sent by the current user
          if (senderId == userId) {
            print("Skipping own request");
            continue;
          }

          final senderDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(senderId)
              .get();

          if (senderDoc.exists) {
            final senderData = senderDoc.data();
            if (senderData != null) {
              print(
                  "Found sender profile: ${senderData.containsKey('displayName')}");
              requests.add({
                'id': senderId,
                'name': senderData['displayName'] ?? 'Unknown User',
                'photoURL': senderData['photoURL'],
                'level': senderData['level'] ?? 1,
                'timestamp': data['timestamp'],
                'status': data['status'] ?? 'pending',
              });
              print(
                  "Added request from: ${senderData['displayName'] ?? 'Unknown User'}");
            }
          } else {
            print("Sender document doesn't exist: $senderId");
          }
        } catch (e) {
          print('Error processing request: $e');
          // Continue processing other requests
        }
      }

      print("Total requests after processing: ${requests.length}");

      if (mounted) {
        setState(() {
          _friendRequests = requests;
          _isLoading = false;
        });
      }

      print("Friend requests added to UI: ${_friendRequests.length}");
    } catch (e) {
      print('Error loading friend requests: $e');
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
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

  Future<void> _fixFriendRequests() async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) return;

      // Get all pending requests
      final requestsSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('friends')
          .where('status', isEqualTo: 'pending')
          .get();

      // Check for requests without senderId
      final batch = FirebaseFirestore.instance.batch();
      bool updatesNeeded = false;

      for (var doc in requestsSnapshot.docs) {
        final data = doc.data();
        if (!data.containsKey('senderId')) {
          print('Fixing document ${doc.id} - adding senderId');

          // The document ID is the other user's ID
          batch.update(doc.reference, {
            'senderId': doc.id, // The person who sent the request
          });
          updatesNeeded = true;
        }
      }

      if (updatesNeeded) {
        await batch.commit();
        print('Friend requests updated with senderId');
      } else {
        print('No fixes needed for friend requests');
      }
    } catch (e) {
      print('Error fixing friend requests: $e');
    }
  }

  Future<void> _sendFriendRequest(String targetUserId) async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('You must be logged in to send friend requests'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      // Check if friendship already exists
      final exists = await _checkExistingFriendship(targetUserId);
      if (exists) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Friend request already sent or already friends'),
              backgroundColor: Colors.orange,
            ),
          );
        }
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

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Friend request sent!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error sending friend request: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
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

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Friend request accepted!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error accepting friend request: $e')),
        );
      }
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

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Friend request rejected'),
            backgroundColor: Colors.grey,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error rejecting friend request: $e')),
        );
      }
    }
  }

  Future<void> _showAddFriendDialog() async {
    String searchQuery = '';

    if (!mounted) return;

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

  void _showFriendOptions(Map<String, dynamic> friend) {
    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A2E),
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // In the _showFriendOptions method, update the 'Message' ListTile onTap function

          ListTile(
            leading: const Icon(Icons.message, color: Color(0xFFFF0077)),
            title: const Text(
              'Message',
              style: TextStyle(
                color: Colors.white,
                fontFamily: 'PixelFont',
              ),
            ),
            onTap: () {
              Navigator.pop(context); // Close the bottom sheet

              // Navigate to the chat detail page with the selected friend
              final conversationId =
                  _auth.currentUser!.uid.compareTo(friend['id']) < 0
                      ? '${_auth.currentUser!.uid}_${friend['id']}'
                      : '${friend['id']}_${_auth.currentUser!.uid}';

              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ChatDetailPage(
                    conversationId: conversationId,
                    recipientId: friend['id'],
                    recipientName: friend['name'],
                  ),
                ),
              );
            },
          ),
          ListTile(
            leading:
                const Icon(Icons.videogame_asset, color: Color(0xFFFF0077)),
            title: const Text(
              'Invite to Game',
              style: TextStyle(
                color: Colors.white,
                fontFamily: 'PixelFont',
              ),
            ),
            onTap: () {
              Navigator.pop(context);
              // TODO: Implement game invitation
            },
          ),
          ListTile(
            leading: const Icon(Icons.remove_circle_outline, color: Colors.red),
            title: const Text(
              'Remove Friend',
              style: TextStyle(
                color: Colors.red,
                fontFamily: 'PixelFont',
              ),
            ),
            onTap: () async {
              Navigator.pop(context);
              _showRemoveFriendDialog(friend);
            },
          ),
        ],
      ),
    );
  }

  void _showRemoveFriendDialog(Map<String, dynamic> friend) {
    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Text(
          'Remove Friend',
          style: TextStyle(
            color: Colors.white,
            fontFamily: 'PixelFont',
          ),
        ),
        content: Text(
          'Are you sure you want to remove ${friend['name']} from your friends list?',
          style: const TextStyle(
            color: Colors.white,
            fontFamily: 'PixelFont',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'CANCEL',
              style: TextStyle(
                color: Colors.grey,
                fontFamily: 'PixelFont',
              ),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _removeFriend(friend['id']);
            },
            child: const Text(
              'REMOVE',
              style: TextStyle(
                color: Colors.red,
                fontFamily: 'PixelFont',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _removeFriend(String friendId) async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) return;

      final batch = FirebaseFirestore.instance.batch();

      // Remove from both users' collections
      batch.delete(
        FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .collection('friends')
            .doc(friendId),
      );

      batch.delete(
        FirebaseFirestore.instance
            .collection('users')
            .doc(friendId)
            .collection('friends')
            .doc(userId),
      );

      // Update friend counts
      batch.update(
        FirebaseFirestore.instance.collection('users').doc(userId),
        {'friendCount': FieldValue.increment(-1)},
      );

      batch.update(
        FirebaseFirestore.instance.collection('users').doc(friendId),
        {'friendCount': FieldValue.increment(-1)},
      );

      await batch.commit();
      await _loadFriends();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Friend removed'),
            backgroundColor: Colors.grey,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error removing friend: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Add this method for searching users
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
      // Search users by displayName containing the query
      final querySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .get();
      
      final results = querySnapshot.docs
          .map((doc) {
            final data = doc.data();
            data['id'] = doc.id;
            return data;
          })
          .where((user) =>
              user['id'] != currentUser.uid &&
              (user['displayName'] ?? '')
                  .toLowerCase()
                  .contains(query.toLowerCase()))
          .toList();

      setState(() {
        _searchResults = results;
        _isSearching = false;
      });
    } catch (e) {
      print('Error searching users: $e');
      setState(() {
        _isSearching = false;
      });
    }
  }

  // Replace the _buildFriendsList method with this updated version
  Widget _buildFriendsList() {
    if (_isSearching) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFFFF0077)),
      );
    }

    if (_searchResults.isNotEmpty) {
      return _buildSearchResults();
    }

    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFFFF0077)),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              _error!,
              style: const TextStyle(color: Colors.red),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadFriends,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF0077),
                foregroundColor: Colors.white,
              ),
              child: const Text('Retry'),
            ),
          ],
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

    return RefreshIndicator(
      onRefresh: _loadFriends,
      color: const Color(0xFFFF0077),
      child: ListView.builder(
        padding: const EdgeInsets.all(8),
        itemCount: _friends.length,
        itemBuilder: (context, index) {
          final friend = _friends[index];
          return _buildFriendCard(friend);
        },
      ),
    );
  }

  // Add this new method to build search results
  Widget _buildSearchResults() {
    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final user = _searchResults[index];
        
        // Check if this user is already a friend
        final isFriend = _friends.any((friend) => friend['id'] == user['id']);
        
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
              backgroundImage: user['photoURL'] != null
                  ? CachedNetworkImageProvider(user['photoURL'])
                  : null,
              child: user['photoURL'] == null
                  ? const Icon(Icons.person, color: Colors.white)
                  : null,
            ),
            title: Text(
              user['displayName'] ?? 'Unknown User',
              style: const TextStyle(
                color: Colors.white,
                fontFamily: 'PixelFont',
                fontSize: 16,
              ),
            ),
            subtitle: Text(
              'Level ${user['level'] ?? 1}',
              style: TextStyle(
                color: Colors.grey.shade400,
                fontFamily: 'PixelFont',
                fontSize: 12,
              ),
            ),
            trailing: isFriend
              ? const Icon(Icons.check_circle, color: Colors.green)
              : IconButton(
                  icon: const Icon(Icons.person_add, color: Color(0xFFFF0077)),
                  onPressed: () => _sendFriendRequest(user['id']),
                ),
          ),
        );
      },
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
      body: Column(
        children: [
          // Search Bar with Cyberpunk design
          Container(
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade900,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFFFF0077).withOpacity(0.3),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFF0077).withOpacity(0.1),
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
                hintText: 'Search for new friends...',
                hintStyle: TextStyle(
                  color: Colors.grey.shade500,
                  fontFamily: 'PixelFont',
                ),
                prefixIcon: Icon(
                  Icons.search,
                  color: const Color(0xFFFF0077).withOpacity(0.7),
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.all(16),
              ),
              onChanged: (value) => _searchUsers(value),
            ),
          ),

          // TabBarView for the rest of the content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildFriendsList(),
                _buildRequestsList(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRequestsList() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFFFF0077)),
      );
    }

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

    return RefreshIndicator(
      onRefresh: _loadFriendRequests,
      color: const Color(0xFFFF0077),
      child: ListView.builder(
        padding: const EdgeInsets.all(8),
        itemCount: _friendRequests.length,
        itemBuilder: (context, index) {
          final request = _friendRequests[index];
          return _buildRequestCard(request);
        },
      ),
    );
  }

  Widget _buildFriendCard(Map<String, dynamic> friend) {
    // Safely check status
    final status = friend['status'] as String? ?? 'offline';

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
                  ? CachedNetworkImageProvider(friend['photoURL'])
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
                  color: status == 'online' ? Colors.green : Colors.grey,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
              ),
            ),
          ],
        ),
        title: Text(
          friend['name'] as String? ?? 'Unknown User',
          style: const TextStyle(
            color: Colors.white,
            fontFamily: 'PixelFont',
            fontSize: 16,
          ),
        ),
        subtitle: Text(
          'Level ${friend['level'] ?? 1}',
          style: TextStyle(
            color: Colors.grey.shade400,
            fontFamily: 'PixelFont',
            fontSize: 12,
          ),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.more_vert, color: Colors.white),
          onPressed: () => _showFriendOptions(friend),
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
              ? CachedNetworkImageProvider(request['photoURL'])
              : null,
          child: request['photoURL'] == null
              ? const Icon(Icons.person, color: Colors.white)
              : null,
        ),
        title: Text(
          request['name'] as String? ?? 'Unknown User',
          style: const TextStyle(
            color: Colors.white,
            fontFamily: 'PixelFont',
            fontSize: 16,
          ),
        ),
        subtitle: Text(
          'Level ${request['level'] ?? 1}',
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
