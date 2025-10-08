import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EditProfileScreen extends StatefulWidget {
  @override
  _EditProfileScreenState createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final _formKey = GlobalKey<FormState>();

  bool _isLoading = true;
  bool _isSaving = false;

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _nicController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _insuranceCompanyController = TextEditingController();
  final TextEditingController _regNumberController = TextEditingController();

  String _selectedCountryCode = '+94';
  final List<String> _countryCodes = ['+94', '+1', '+44', '+91', '+61'];

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _nicController.dispose();
    _addressController.dispose();
    _insuranceCompanyController.dispose();
    _regNumberController.dispose();
    super.dispose();
  }

  Future<void> _loadUserProfile() async {
    try {
      final User? user = _auth.currentUser;
      if (user != null) {
        final DocumentSnapshot<Map<String, dynamic>> doc =
        await _firestore.collection('users').doc(user.uid).get();

        if (doc.exists && doc.data() != null) {
          final data = doc.data()!;
          setState(() {
            _emailController.text = user.email ?? '';
            _firstNameController.text = data['firstName'] ?? data['name']?.split(' ')[0] ?? '';
            _lastNameController.text = data['lastName'] ?? (data['name']?.split(' ').length > 1 ? data['name']?.split(' ')[1] : '') ?? '';

            // Handle phone number with country code
            String phoneNumber = data['phoneNumber'] ?? '';
            if (phoneNumber.isNotEmpty) {
              // Extract country code if present
              if (phoneNumber.startsWith('+')) {
                int spaceIndex = phoneNumber.indexOf(' ');
                if (spaceIndex > 0) {
                  _selectedCountryCode = phoneNumber.substring(0, spaceIndex);
                  _phoneController.text = phoneNumber.substring(spaceIndex + 1);
                } else {
                  // Assume +94 and rest is number
                  if (phoneNumber.startsWith('+94')) {
                    _selectedCountryCode = '+94';
                    _phoneController.text = phoneNumber.substring(3);
                  } else {
                    _phoneController.text = phoneNumber;
                  }
                }
              } else {
                _phoneController.text = phoneNumber;
              }
            }

            _nicController.text = data['nic'] ?? '';
            _addressController.text = data['address'] ?? '';
            _insuranceCompanyController.text = data['insuranceCompany'] ?? '';
            _regNumberController.text = data['regNumber'] ?? '';
            _isLoading = false;
          });
        } else {
          setState(() {
            _emailController.text = user.email ?? '';
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      print('Error loading profile: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading profile data')),
      );
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final User? user = _auth.currentUser;
      if (user != null) {
        // Combine country code with phone number
        String fullPhoneNumber = _phoneController.text.isNotEmpty
            ? '$_selectedCountryCode ${_phoneController.text}'
            : '';

        await _firestore.collection('users').doc(user.uid).update({
          'firstName': _firstNameController.text.trim(),
          'lastName': _lastNameController.text.trim(),
          'phoneNumber': fullPhoneNumber.trim(),
          'nic': _nicController.text.trim(),
          'address': _addressController.text.trim(),
          'insuranceCompany': _insuranceCompanyController.text.trim(),
          'regNumber': _regNumberController.text.trim(),
          'updatedAt': FieldValue.serverTimestamp(),
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Profile updated successfully'),
            backgroundColor: Colors.green,
          ),
        );

        // Return true to indicate successful update
        Navigator.pop(context, true);
      }
    } catch (e) {
      print('Error saving profile: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating profile'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Edit Profile',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Email (Non-editable)
                _buildLabel('Email'),
                SizedBox(height: 8),
                _buildReadOnlyField(_emailController),
                SizedBox(height: 20),

                // First Name
                _buildLabel('First Name'),
                SizedBox(height: 8),
                _buildTextField(
                  controller: _firstNameController,
                  hintText: 'Enter first name',
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter first name';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 20),

                // Last Name
                _buildLabel('Last Name'),
                SizedBox(height: 8),
                _buildTextField(
                  controller: _lastNameController,
                  hintText: 'Enter last name',
                ),
                SizedBox(height: 20),

                // Phone Number with Country Code
                _buildLabel('Phone Number'),
                SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedCountryCode,
                          items: _countryCodes.map((code) {
                            return DropdownMenuItem(
                              value: code,
                              child: Text(
                                code,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.black,
                                ),
                              ),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              _selectedCountryCode = value!;
                            });
                          },
                          icon: Icon(Icons.arrow_drop_down, color: Colors.black),
                        ),
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: _buildTextField(
                        controller: _phoneController,
                        hintText: 'Phone number',
                        keyboardType: TextInputType.phone,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 20),

                // NIC
                _buildLabel('NIC'),
                SizedBox(height: 8),
                _buildTextField(
                  controller: _nicController,
                  hintText: 'Enter NIC',
                ),
                SizedBox(height: 20),

                // Address
                _buildLabel('Address'),
                SizedBox(height: 8),
                _buildTextField(
                  controller: _addressController,
                  hintText: 'Enter address',
                  maxLines: 2,
                ),
                SizedBox(height: 20),

                // Insurance Company
                _buildLabel('Insurance Company'),
                SizedBox(height: 8),
                _buildTextField(
                  controller: _insuranceCompanyController,
                  hintText: 'Enter insurance company',
                ),
                SizedBox(height: 20),

                // Registration Number
                _buildLabel('Reg. Number'),
                SizedBox(height: 8),
                _buildTextField(
                  controller: _regNumberController,
                  hintText: 'Enter registration number',
                ),
                SizedBox(height: 40),

                // Save Changes Button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _saveProfile,
                    child: _isSaving
                        ? SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                        : Text(
                      'Save Changes',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF1DA1F2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 0,
                    ),
                  ),
                ),
                SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String label) {
    return Text(
      label,
      style: TextStyle(
        fontSize: 14,
        color: Colors.black,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: validator,
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(color: Colors.grey[600]),
        filled: true,
        fillColor: Colors.grey[300],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Color(0xFF1DA1F2), width: 1),
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      style: TextStyle(
        fontSize: 14,
        color: Colors.black,
      ),
    );
  }

  Widget _buildReadOnlyField(TextEditingController controller) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              controller.text.isEmpty ? '-' : controller.text,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ),
          Icon(
            Icons.lock_outline,
            color: Colors.grey[500],
            size: 18,
          ),
        ],
      ),
    );
  }
}