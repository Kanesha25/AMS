import 'package:flutter/material.dart';
import '../../models/customer_model.dart';
import '../../services/customer_service.dart';

class CustomerFormScreen extends StatefulWidget {
  final CustomerModel? customer; // null for new customer, existing customer for edit

  CustomerFormScreen({this.customer});

  @override
  _CustomerFormScreenState createState() => _CustomerFormScreenState();
}

class _CustomerFormScreenState extends State<CustomerFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final CustomerService _customerService = CustomerService();

  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _phoneController;
  late TextEditingController _nicController;
  late TextEditingController _addressController;
  late TextEditingController _vehicleNumberController;
  late TextEditingController _modelController;

  String _selectedCountryCode = '+94';
  bool _isLoading = false;
  bool get _isEditing => widget.customer != null;

  @override
  void initState() {
    super.initState();

    // Initialize controllers
    _firstNameController = TextEditingController(text: widget.customer?.firstName ?? '');
    _lastNameController = TextEditingController(text: widget.customer?.lastName ?? '');
    _phoneController = TextEditingController(text: widget.customer?.phoneNumber.replaceFirst('+94', '') ?? '');
    _nicController = TextEditingController(text: widget.customer?.nic ?? '');
    _addressController = TextEditingController(text: widget.customer?.address ?? '');
    _vehicleNumberController = TextEditingController(text: widget.customer?.vehicleNumber ?? '');
    _modelController = TextEditingController(text: widget.customer?.model ?? '');
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _nicController.dispose();
    _addressController.dispose();
    _vehicleNumberController.dispose();
    _modelController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          _isEditing ? widget.customer!.fullName : 'New Customer',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: Stack(
          children: [
          // Background Image
          Container(
            decoration: BoxDecoration(
            image: DecorationImage(
            image: AssetImage('lib/screens/assets/images/bg.png'),
            fit: BoxFit.cover,
            ),
            ),
          ),
          // Semi-transparent overlay
          Container(
            color: Colors.white.withOpacity(0.85),
          ),
          // Main content
          Form(
          key: _formKey,
          child: SingleChildScrollView(
          padding: EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // First Name
              _buildSectionTitle('First Name'),
              SizedBox(height: 8),
              _buildTextField(
                controller: _firstNameController,
                hintText: 'Enter first name',
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'First name is required';
                  }
                  return null;
                },
              ),
              SizedBox(height: 20),

              // Last Name
              _buildSectionTitle('Last Name'),
              SizedBox(height: 8),
              _buildTextField(
                controller: _lastNameController,
                hintText: 'Enter last name',
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Last name is required';
                  }
                  return null;
                },
              ),
              SizedBox(height: 20),

              // Phone Number
              _buildSectionTitle('Phone Number'),
              SizedBox(height: 8),
              Row(
                children: [
                  Container(
                    width: 80,
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedCountryCode,
                        items: [
                          DropdownMenuItem(value: '+94', child: Text('+94')),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _selectedCountryCode = value!;
                          });
                        },
                        isExpanded: true,
                        icon: Icon(Icons.keyboard_arrow_down),
                        style: TextStyle(color: Colors.black, fontSize: 16),
                        dropdownColor: Colors.white,
                      ),
                    ),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: _buildTextField(
                      controller: _phoneController,
                      hintText: 'Enter phone number',
                      keyboardType: TextInputType.phone,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Phone number is required';
                        }
                        if (value.length < 9) {
                          return 'Enter a valid phone number';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20),

              // NIC
              _buildSectionTitle('NIC'),
              SizedBox(height: 8),
              _buildTextField(
                controller: _nicController,
                hintText: 'Enter NIC number',
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'NIC is required';
                  }
                  if (value.length < 10) {
                    return 'Enter a valid NIC number';
                  }
                  return null;
                },
              ),
              SizedBox(height: 20),

              // Address
              _buildSectionTitle('Address'),
              SizedBox(height: 8),
              _buildTextField(
                controller: _addressController,
                hintText: 'Enter address',
                maxLines: 2,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Address is required';
                  }
                  return null;
                },
              ),
              SizedBox(height: 20),

              // Vehicle Number
              _buildSectionTitle('Vehicle Number'),
              SizedBox(height: 8),
              _buildTextField(
                controller: _vehicleNumberController,
                hintText: 'Enter vehicle number',
                textCapitalization: TextCapitalization.characters,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Vehicle number is required';
                  }
                  return null;
                },
              ),
              SizedBox(height: 20),

              // Model
              _buildSectionTitle('Model'),
              SizedBox(height: 8),
              _buildTextField(
                controller: _modelController,
                hintText: 'Enter vehicle model',
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Vehicle model is required';
                  }
                  return null;
                },
              ),
              SizedBox(height: 40),

              // Save Button
              Container(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveCustomer,
                  child: _isLoading
                      ? CircularProgressIndicator(color: Colors.white)
                      : Text(
                    _isEditing ? 'Save Changes' : 'Add Customer',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF1DA1F2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 2,
                  ),
                ),
              ),

              // Delete Button (only for existing customers)
              if (_isEditing) ...[
                SizedBox(height: 20),
                Container(
                  width: double.infinity,
                  height: 50,
                  child: OutlinedButton(
                    onPressed: _isLoading ? null : _deleteCustomer,
                    child: Text(
                      'Delete Customer',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Colors.red),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
          ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: Colors.black,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    int maxLines = 1,
    TextCapitalization textCapitalization = TextCapitalization.none,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(8),
      ),
      child: TextFormField(
        controller: controller,
        validator: validator,
        keyboardType: keyboardType,
        maxLines: maxLines,
        textCapitalization: textCapitalization,
        style: TextStyle(
          fontSize: 16,
          color: Colors.black,
        ),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(
            color: Colors.grey[600],
            fontSize: 16,
          ),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 15,
          ),
        ),
      ),
    );
  }

  Future<void> _saveCustomer() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final fullPhoneNumber = '$_selectedCountryCode${_phoneController.text.trim()}';

      // Check for duplicate NIC (only for new customers or if NIC changed)
      if (!_isEditing || widget.customer!.nic != _nicController.text.trim()) {
        bool nicExists = await _customerService.customerExistsByNIC(_nicController.text.trim());
        if (nicExists) {
          _showErrorSnackBar('A customer with this NIC already exists');
          setState(() {
            _isLoading = false;
          });
          return;
        }
      }

      // Check for duplicate phone number (only for new customers or if phone changed)
      if (!_isEditing || widget.customer!.phoneNumber != fullPhoneNumber) {
        bool phoneExists = await _customerService.customerExistsByPhone(fullPhoneNumber);
        if (phoneExists) {
          _showErrorSnackBar('A customer with this phone number already exists');
          setState(() {
            _isLoading = false;
          });
          return;
        }
      }

      final now = DateTime.now();
      final customer = CustomerModel(
        id: _isEditing ? widget.customer!.id : 'CUST-${now.millisecondsSinceEpoch}',
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        phoneNumber: fullPhoneNumber,
        nic: _nicController.text.trim(),
        address: _addressController.text.trim(),
        vehicleNumber: _vehicleNumberController.text.trim().toUpperCase(),
        model: _modelController.text.trim(),
        createdAt: _isEditing ? widget.customer!.createdAt : now,
        updatedAt: now,
      );

      if (_isEditing) {
        await _customerService.updateCustomer(customer);
        _showSuccessSnackBar('Customer updated successfully');
      } else {
        await _customerService.addCustomer(customer);
        _showSuccessSnackBar('Customer added successfully');
      }

      Navigator.pop(context);
    } catch (e) {
      _showErrorSnackBar('Failed to save customer: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _deleteCustomer() async {
    final bool? shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Customer'),
        content: Text('Are you sure you want to delete this customer? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Delete'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          ),
        ],
      ),
    );

    if (shouldDelete == true) {
      setState(() {
        _isLoading = true;
      });

      try {
        await _customerService.deleteCustomer(widget.customer!.id);
        _showSuccessSnackBar('Customer deleted successfully');
        Navigator.pop(context);
      } catch (e) {
        _showErrorSnackBar('Failed to delete customer: $e');
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 10),
            Text(message),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.error, color: Colors.white),
            SizedBox(width: 10),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}