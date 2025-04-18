import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AddressPage extends StatefulWidget {
  const AddressPage({Key? key}) : super(key: key);

  @override
  State<AddressPage> createState() => _AddressPageState();
}

class _AddressPageState extends State<AddressPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<Map<String, dynamic>> addresses = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchAddresses();
  }

  Future<void> _fetchAddresses() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        print('Fetching addresses for user: ${user.uid}'); // Debug log
        final snapshot = await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('addresses')
            .get();

        setState(() {
          addresses = snapshot.docs
              .map((doc) => {
                    'id': doc.id,
                    ...doc.data(),
                  })
              .toList();
          _isLoading = false;
        });
      } else {
        throw 'User is not authenticated';
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error fetching addresses: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _addAddress(Map<String, dynamic> address) async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('addresses')
            .add(address);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Address added successfully!'),
            backgroundColor: Colors.green,
          ),
        );

        _fetchAddresses(); // Refresh the address list
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error adding address: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _deleteAddress(String addressId) async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('addresses')
            .doc(addressId)
            .delete();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Address deleted successfully!'),
            backgroundColor: Colors.green,
          ),
        );

        _fetchAddresses(); // Refresh the address list
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error deleting address: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showAddAddressDialog() {
    final TextEditingController countryController = TextEditingController();
    final TextEditingController stateController = TextEditingController();
    final TextEditingController cityController = TextEditingController();
    final TextEditingController barangayController = TextEditingController();
    final TextEditingController streetController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1A1A2E),
          title: const Text(
            'Add New Address',
            style: TextStyle(
              color: Colors.white,
              fontFamily: 'PixelFont',
              fontSize: 20,
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildTextField(countryController, 'Country'),
                _buildTextField(stateController, 'State/Province'),
                _buildTextField(cityController, 'City'),
                _buildTextField(barangayController, 'Barangay'),
                _buildTextField(streetController, 'Street Address'),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              style: TextButton.styleFrom(
                foregroundColor: Colors.grey,
              ),
              child: const Text(
                'Cancel',
                style: TextStyle(fontFamily: 'PixelFont'),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                final newAddress = {
                  'country': countryController.text,
                  'state': stateController.text,
                  'city': cityController.text,
                  'barangay': barangayController.text,
                  'street': streetController.text,
                  'timestamp': DateTime.now(),
                };
                _addAddress(newAddress);
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.pink,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              child: const Text(
                'Add',
                style: TextStyle(
                  fontFamily: 'PixelFont',
                  color: Colors.white,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTextField(TextEditingController controller, String label) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: TextField(
        controller: controller,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(
            color: Colors.grey,
            fontFamily: 'PixelFont',
          ),
          enabledBorder: const OutlineInputBorder(
            borderSide: BorderSide(color: Colors.grey),
          ),
          focusedBorder: const OutlineInputBorder(
            borderSide: BorderSide(color: Colors.pink),
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
          'Manage Addresses',
          style: TextStyle(
            fontFamily: 'PixelFont',
            color: Colors.white,
          ),
        ),
        actions: [
          TextButton.icon(
            onPressed: _showAddAddressDialog,
            icon: const Icon(Icons.add, color: Colors.pink),
            label: const Text(
              'Add Address',
              style: TextStyle(
                color: Colors.pink,
                fontFamily: 'PixelFont',
              ),
            ),
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          color: Colors.black,
          border: Border.all(color: Colors.white10),
          borderRadius: BorderRadius.circular(8),
        ),
        margin: const EdgeInsets.all(16),
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(
                  color: Colors.pink,
                ),
              )
            : addresses.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.location_off,
                          size: 64,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'No addresses found',
                          style: TextStyle(
                            color: Colors.white,
                            fontFamily: 'PixelFont',
                            fontSize: 18,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Add a new shipping address',
                          style: TextStyle(
                            color: Colors.grey,
                            fontFamily: 'PixelFont',
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: _showAddAddressDialog,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.pink,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                          ),
                          icon: const Icon(Icons.add),
                          label: const Text(
                            'Add Address',
                            style: TextStyle(fontFamily: 'PixelFont'),
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(8),
                    itemCount: addresses.length,
                    itemBuilder: (context, index) {
                      final address = addresses[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1A1A2E),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.white10),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(
                                    Icons.location_on,
                                    color: Colors.pink,
                                    size: 24,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '${address['street']}',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontFamily: 'PixelFont',
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '${address['barangay']}, ${address['city']}',
                                          style: const TextStyle(
                                            color: Colors.grey,
                                            fontFamily: 'PixelFont',
                                            fontSize: 14,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          '${address['state']}, ${address['country']}',
                                          style: const TextStyle(
                                            color: Colors.grey,
                                            fontFamily: 'PixelFont',
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              decoration: const BoxDecoration(
                                border: Border(
                                  top: BorderSide(color: Colors.white10),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  TextButton.icon(
                                    onPressed: () => _deleteAddress(address['id']),
                                    icon: const Icon(
                                      Icons.delete,
                                      color: Colors.red,
                                      size: 18,
                                    ),
                                    label: const Text(
                                      'Delete',
                                      style: TextStyle(
                                        color: Colors.red,
                                        fontFamily: 'PixelFont',
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}