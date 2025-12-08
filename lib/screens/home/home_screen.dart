import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:my_app/screens/home/spare_parts.dart';
import 'package:my_app/screens/customers/customers_screen.dart'; // Add this import
import '../../services/auth_service.dart';
import '../../services/database_service.dart';
import '../../models/accident_model.dart';
import '../../models/user_model.dart';
import '../auth/login_screen.dart';
import '../accidents/new_accident_screen.dart';
import '../accidents/estimation_report_screen.dart';
import '../profile/profile_screen.dart';
import '../../models/customer_model.dart';
import '../../models/inspector_profile.dart';
import '../../models/spare_part_model.dart';
import '../../services/customer_service.dart';
import '../../database/spare_parts_database.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final AuthService _authService = AuthService();
  final DatabaseService _databaseService = DatabaseService();
  final CustomerService _customerService = CustomerService();
  final SparePartsDatabase _sparePartsDatabase = SparePartsDatabase();
  int _selectedIndex = 0;
  String? _currentUserName;

  @override
  void initState() {
    super.initState();
    _loadCurrentUserName();
  }

  Future<void> _loadCurrentUserName() async {
    final User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final DocumentSnapshot<Map<String, dynamic>> doc = await FirebaseFirestore
            .instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (doc.exists && doc.data() != null) {
          final userData = UserModel.fromMap(doc.data()!);
          setState(() {
            _currentUserName = userData.name.toUpperCase();
          });
        }
      } catch (e) {
        print('Error loading user name: $e');
        // Fallback to email if Firestore fetch fails
        setState(() {
          _currentUserName = user.email?.split('@')[0].toUpperCase() ?? 'USER';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final User? user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Background Image
          Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage('lib/screens/assets/images/bg.png'), // Add your background image here
                fit: BoxFit.cover,
              ),
            ),
          ),
          // Semi-transparent overlay
          Container(
            color: Colors.white.withOpacity(0.85),
          ),
          // Main Content
          SafeArea(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    children: [
                      // Clickable Profile Icon with Dropdown
                      PopupMenuButton<String>(
                        onSelected: (value) async {
                          if (value == 'logout') {
                            await _handleLogout();
                          } else if (value == 'profile') {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => ProfileScreen()),
                            );
                          }
                        },
                        itemBuilder: (BuildContext context) {
                          return [
                            PopupMenuItem<String>(
                              value: 'profile',
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.person,
                                    color: Color(0xFF1DA1F2),
                                    size: 20,
                                  ),
                                  SizedBox(width: 12),
                                  Text(
                                    'My Profile',
                                    style: TextStyle(
                                      color: Colors.black87,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            PopupMenuItem<String>(
                              value: 'logout',
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.logout,
                                    color: Colors.red,
                                    size: 20,
                                  ),
                                  SizedBox(width: 12),
                                  Text(
                                    'Logout',
                                    style: TextStyle(
                                      color: Colors.red,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ];
                        },
                        child: Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: Color(0xFF1DA1F2),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.person,
                            color: Colors.white,
                            size: 30,
                          ),
                        ),
                        offset: Offset(0, 55),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        elevation: 4,
                      ),
                      SizedBox(width: 15),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Hello,',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey,
                            ),
                          ),
                          Text(
                            _currentUserName ?? 'LOADING...',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                        ],
                      ),
                      Spacer(),
                    ],
                  ),
                  SizedBox(height: 30),

                  // Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => _showNewAccidentDialog(),
                          child: Container(
                            height: 120,
                            decoration: BoxDecoration(
                              color: Color(0xFF1DA1F2),
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  width: 50,
                                  height: 50,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.car_crash,
                                    color: Color(0xFF1DA1F2),
                                    size: 25,
                                  ),
                                ),
                                SizedBox(height: 10),
                                Text(
                                  'New Accident',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 15),
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => CustomersScreen()),
                            );
                          },
                          child: Container(
                            height: 120,
                            decoration: BoxDecoration(
                              color: Color(0xFF1DA1F2),
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  width: 50,
                                  height: 50,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.people,
                                    color: Color(0xFF1DA1F2),
                                    size: 25,
                                  ),
                                ),
                                SizedBox(height: 10),
                                Text(
                                  'Customers',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 30),

                  // Summary Section
                  Text(
                    'Summary',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  SizedBox(height: 15),

                  // Accident List
                  Expanded(
                    child: StreamBuilder<List<AccidentModel>>(
                      stream: _databaseService.getAccidents(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return Center(child: CircularProgressIndicator());
                        }

                        if (!snapshot.hasData || snapshot.data!.isEmpty) {
                          return Center(
                            child: Text(
                              'No accidents reported yet',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey,
                              ),
                            ),
                          );
                        }

                        return ListView.builder(
                          itemCount: snapshot.data!.length,
                          itemBuilder: (context, index) {
                            final accident = snapshot.data![index];
                            return _buildAccidentCard(accident);
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          if (index == 1) { // Spare Parts tab
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => SparePartsScreen()),
            );
          } else if (index == 2) { // Profile tab
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => ProfileScreen()),
            );
          } else {
            setState(() {
              _selectedIndex = index;
            });
          }
        },
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.build),
            label: 'Spare Parts',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
        selectedItemColor: Color(0xFF1DA1F2),
        unselectedItemColor: Colors.grey,
      ),
    );
  }

  Widget _buildAccidentCard(AccidentModel accident) {
    // Calculate average total cost
    int? totalAvgCost;
    if (accident.estimatedParts.isNotEmpty) {
      totalAvgCost = accident.estimatedParts.fold<int>(
        0,
        (sum, part) {
          final min = (part['min_price'] as num?)?.toInt() ?? 0;
          final max = (part['max_price'] as num?)?.toInt() ?? 0;
          return sum + ((min + max) ~/ 2);
        },
      );
    } else if (accident.estimatedMinCost != null &&
        accident.estimatedMaxCost != null) {
      totalAvgCost = (accident.estimatedMinCost! + accident.estimatedMaxCost!) ~/ 2;
    }

    return InkWell(
      onTap: () => _viewEstimationReport(accident),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        margin: EdgeInsets.only(bottom: 15),
        padding: EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                accident.id,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getStatusColor(accident.status).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Completed',
                  style: TextStyle(
                  color: _getStatusColor('Completed'),
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            accident.location,
            style: TextStyle(
              fontSize: 14,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 4),
          Text(
            accident.description,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
          if (totalAvgCost != null) ...[
            SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Color(0xFF1DA1F2).withOpacity(0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Estimated Total Cost',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  Text(
                    'LKR ${_formatCurrency(totalAvgCost)}',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
            ),
          ],
          SizedBox(height: 8),
          Text(
            _formatDate(accident.timestamp),
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey,
            ),
          ),
        ],
        ),
      ),
    );
  }

  Future<void> _viewEstimationReport(AccidentModel accident) async {
    try {
      // Extract customer name from description
      // Format: "Customer: [Name], Vehicle: [Number], Model: [Model], Parts: [Parts]"
      String customerName = '';
      String vehicleNumber = accident.vehicleNumber;
      
      if (accident.description.contains('Customer:')) {
        final parts = accident.description.split(',');
        for (var part in parts) {
          if (part.trim().startsWith('Customer:')) {
            customerName = part.replaceFirst('Customer:', '').trim();
            break;
          }
        }
      }

      // Try to find customer by name or vehicle number
      CustomerModel? customer;
      try {
        final customersStream = _customerService.getCustomers();
        final customers = await customersStream.first;
        try {
          customer = customers.firstWhere(
            (c) => c.fullName == customerName || c.vehicleNumber == vehicleNumber,
          );
        } catch (_) {
          // Customer not found, create a placeholder
          final nameParts = customerName.split(' ');
          customer = CustomerModel(
            id: 'temp',
            firstName: nameParts.isNotEmpty ? nameParts.first : 'Unknown',
            lastName: nameParts.length > 1 ? nameParts.skip(1).join(' ') : '',
            phoneNumber: '-',
            nic: '-',
            address: '-',
            vehicleNumber: vehicleNumber,
            model: accident.vehicleModel,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );
        }
      } catch (e) {
        // If error loading customers, create a placeholder
        final nameParts = customerName.split(' ');
        customer = CustomerModel(
          id: 'temp',
          firstName: nameParts.isNotEmpty ? nameParts.first : 'Unknown',
          lastName: nameParts.length > 1 ? nameParts.skip(1).join(' ') : '',
          phoneNumber: '-',
          nic: '-',
          address: '-',
          vehicleNumber: vehicleNumber,
          model: accident.vehicleModel,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
      }

      // Load inspector profile from user's profile
      InspectorProfile? inspectorProfile;
      try {
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          final doc = await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get();
          if (doc.exists && doc.data() != null) {
            final userData = doc.data()!;
            // Use user's name as inspector name
            final userName = userData['name'] ?? 
                            '${userData['firstName'] ?? ''} ${userData['lastName'] ?? ''}'.trim() ??
                            user.displayName ??
                            user.email?.split('@')[0] ??
                            'Inspector';
            inspectorProfile = InspectorProfile.fromMap(
              userData,
              fallbackName: userName,
              fallbackPhone: userData['phoneNumber'] ?? '',
            );
          }
        }
      } catch (e) {
        print('Error loading inspector profile: $e');
      }

      // Convert estimatedParts to SparePart objects
      final List<SparePart> estimationParts = [];
      for (var partMap in accident.estimatedParts) {
        final name = partMap['name']?.toString() ?? '';
        final minPrice = (partMap['min_price'] as num?)?.toInt() ?? 0;
        final maxPrice = (partMap['max_price'] as num?)?.toInt() ?? 0;
        if (name.isNotEmpty) {
          estimationParts.add(SparePart(
            name: name,
            minPrice: minPrice,
            maxPrice: maxPrice,
          ));
        }
      }

      // If no parts from estimatedParts, try to load from spare parts database
      if (estimationParts.isEmpty) {
        final allParts = await _sparePartsDatabase.getAllSpareParts();
        for (var partMap in accident.estimatedParts) {
          final name = partMap['name']?.toString() ?? '';
          if (name.isNotEmpty) {
            try {
              final part = allParts.firstWhere((p) => p.name == name);
              estimationParts.add(part);
            } catch (_) {
              // Part not found, skip
            }
          }
        }
      }

      if (customer != null) {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => EstimationReportScreen(
              accident: accident,
              customer: customer!,
              inspectorProfile: inspectorProfile,
              estimationParts: estimationParts,
            ),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading report: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.green;
      case 'in progress':
        return Colors.blue;
      case 'completed':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}.${date.month.toString().padLeft(2, '0')}.${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')} ${date.hour >= 12 ? 'pm' : 'am'}';
  }

  String _formatCurrency(num value) {
    final str = value.toStringAsFixed(0);
    final reg = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
    return str.replaceAllMapped(reg, (match) => '${match[1]},');
  }

  void _showNewAccidentDialog() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => NewAccidentScreen()),
    ).then((result) {
      if (result == true) {
        // Refresh the accidents list
        setState(() {});
      }
    });
  }

  void _addNewAccident(String location, String description) {
    if (location.isNotEmpty && description.isNotEmpty) {
      final accident = AccidentModel(
        id: 'ACC-${DateTime.now().millisecondsSinceEpoch}',
        location: location,
        description: description,
        timestamp: DateTime.now(),
        status: 'Completed',
        vehicleNumber: 'N/A',
        vehicleModel: 'N/A',
      );

      _databaseService.addAccident(accident);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Accident reported successfully')),
      );
    }
  }

  // Enhanced logout method with confirmation dialog and error handling
  Future<void> _handleLogout() async {
    // Show confirmation dialog
    final bool? shouldLogout = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: Row(
            children: [
              Icon(
                Icons.logout,
                color: Colors.red,
                size: 24,
              ),
              SizedBox(width: 10),
              Text(
                'Confirm Logout',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: Text(
            'Are you sure you want to logout from your account?',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[700],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 16,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(
                'Logout',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              ),
            ),
          ],
        );
      },
    );

    // If user confirmed logout
    if (shouldLogout == true) {
      await _performLogout();
    }
  }

  Future<void> _performLogout() async {
    try {
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => WillPopScope(
          onWillPop: () async => false,
          child: Dialog(
            backgroundColor: Colors.transparent,
            child: Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1DA1F2)),
                  ),
                  SizedBox(height: 15),
                  Text(
                    'Logging out...',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[700],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      // Perform logout
      await _authService.signOut();

      // Close loading dialog
      if (mounted) {
        Navigator.of(context).pop();

        // Navigate to login screen and clear navigation stack
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => LoginScreen()),
              (route) => false,
        );

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 10),
                Text('Successfully logged out'),
              ],
            ),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    } catch (e) {
      print('Logout error: $e');

      // Close loading dialog if still open
      if (mounted) {
        Navigator.of(context).pop();

        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error, color: Colors.white),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Failed to logout. Please try again.',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            action: SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: () => _handleLogout(),
            ),
          ),
        );
      }
    }
  }

  // Keep the old simple logout method as backup (you can remove this if not needed)
  void _signOut() async {
    try {
      await _authService.signOut();
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => LoginScreen()),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error logging out: $e')),
      );
    }
  }
}