import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dotted_border/dotted_border.dart';
import '../../models/accident_model.dart';
import '../../models/customer_model.dart';
import '../../models/spare_part_model.dart';
import '../../services/database_service.dart';
import '../../services/customer_service.dart';
import '../../database/spare_parts_database.dart';

class NewAccidentScreen extends StatefulWidget {
  @override
  _NewAccidentScreenState createState() => _NewAccidentScreenState();
}

class _NewAccidentScreenState extends State<NewAccidentScreen> {
  final DatabaseService _databaseService = DatabaseService();
  final CustomerService _customerService = CustomerService();
  final SparePartsDatabase _sparePartsDatabase = SparePartsDatabase();
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final TextEditingController _vehicleNumberController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _dateTimeController = TextEditingController();

  // State variables
  List<XFile> _additionalPhotos = [];
  final ImagePicker _picker = ImagePicker();
  List<SparePart> _allSpareParts = [];
  List<SparePart> _selectedSpareParts = [];
  List<CustomerModel> _allCustomers = [];
  CustomerModel? _selectedCustomer;
  DateTime _selectedDateTime = DateTime.now();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadSpareParts();
    _loadCustomers();
    _dateTimeController.text = _formatDateTime(_selectedDateTime);
  }

  @override
  void dispose() {
    _vehicleNumberController.dispose();
    _locationController.dispose();
    _dateTimeController.dispose();
    super.dispose();
  }

  Future<void> _loadSpareParts() async {
    try {
      final parts = await _sparePartsDatabase.getAllSpareParts();
      setState(() {
        _allSpareParts = parts;
      });
    } catch (e) {
      _showErrorSnackBar('Error loading spare parts: $e');
    }
  }

  Future<void> _loadCustomers() async {
    try {
      // Use stream and get the first snapshot to convert to list
      final customersStream = _customerService.getCustomers();
      final customers = await customersStream.first;
      setState(() {
        _allCustomers = customers;
      });
    } catch (e) {
      _showErrorSnackBar('Error loading customers: $e');
    }
  }

  Future<void> _pickAdditionalImages() async {
    try {
      final List<XFile> images = await _picker.pickMultiImage(
        imageQuality: 85,
      );

      if (images.isNotEmpty) {
        setState(() {
          int remainingSlots = 5 - _additionalPhotos.length;
          _additionalPhotos.addAll(images.take(remainingSlots));
        });

        if (_additionalPhotos.length >= 5) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Maximum 5 images reached'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      _showErrorSnackBar('Error picking images: $e');
    }
  }

  void _removeAdditionalPhoto(int index) {
    setState(() {
      _additionalPhotos.removeAt(index);
    });
  }

  Future<void> _selectDateTime() async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDateTime,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (pickedDate != null) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_selectedDateTime),
      );

      if (pickedTime != null) {
        setState(() {
          _selectedDateTime = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute,
          );
          _dateTimeController.text = _formatDateTime(_selectedDateTime);
        });
      }
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day.toString().padLeft(2, '0')}.${dateTime.month.toString().padLeft(2, '0')}.${dateTime.year} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')} ${dateTime.hour >= 12 ? 'pm' : 'am'}';
  }

  void _showSparePartsDialog() {
    List<SparePart> tempSelected = List.from(_selectedSpareParts);

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Select Spare Parts'),
          content: Container(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _allSpareParts.length,
              itemBuilder: (context, index) {
                final part = _allSpareParts[index];
                final isSelected = tempSelected.any((p) => p.id == part.id);

                return CheckboxListTile(
                  title: Text(part.name),
                  subtitle: Text(
                    'LKR ${part.minPrice} - ${part.maxPrice}',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                  value: isSelected,
                  activeColor: Color(0xFF1DA1F2),
                  onChanged: (bool? value) {
                    setDialogState(() {
                      if (value == true) {
                        tempSelected.add(part);
                      } else {
                        tempSelected.removeWhere((p) => p.id == part.id);
                      }
                    });
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _selectedSpareParts = tempSelected;
                });
                Navigator.pop(context);
              },
              child: Text('Done'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF1DA1F2),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCustomerDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Select Customer'),
        content: Container(
          width: double.maxFinite,
          child: _allCustomers.isEmpty
              ? Center(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Text(
                'No customers found.\nPlease add customers first.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
            ),
          )
              : ListView.builder(
            shrinkWrap: true,
            itemCount: _allCustomers.length,
            itemBuilder: (context, index) {
              final customer = _allCustomers[index];
              return ListTile(
                title: Text(customer.fullName),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Vehicle: ${customer.vehicleNumber}'),
                    Text('Phone: ${customer.phoneNumber}'),
                  ],
                ),
                selected: _selectedCustomer?.id == customer.id,
                selectedTileColor: Color(0xFF1DA1F2).withOpacity(0.1),
                onTap: () {
                  setState(() {
                    _selectedCustomer = customer;
                    _vehicleNumberController.text = customer.vehicleNumber;
                  });
                  Navigator.pop(context);
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _submitAccident() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedCustomer == null) {
      _showErrorSnackBar('Please select a customer');
      return;
    }

    if (_selectedSpareParts.isEmpty) {
      _showErrorSnackBar('Please select at least one spare part');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Create accident model with all the data
      final accident = AccidentModel(
        id: 'ACC-${DateTime.now().millisecondsSinceEpoch}',
        location: _locationController.text.trim(),
        description: 'Customer: ${_selectedCustomer!.fullName}, Vehicle: ${_vehicleNumberController.text}, Parts: ${_selectedSpareParts.map((p) => p.name).join(", ")}',
        timestamp: _selectedDateTime,
        status: 'Pending',
      );

      // Add accident to database
      await _databaseService.addAccident(accident);

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 10),
              Text('Accident reported successfully'),
            ],
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      );

      // Navigate back
      Navigator.pop(context, true);
    } catch (e) {
      _showErrorSnackBar('Error submitting accident: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
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
      ),
    );
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
          'New Accident',
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
                image: AssetImage('lib/screens/assets/images/car_accident_bg.png'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          // Content
          Form(
            key: _formKey,
            child: ListView(
              padding: EdgeInsets.all(16),
              children: [
                // Upload Images Section
                Text(
                  'Upload Images',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: 16),
                if (_additionalPhotos.length < 5)
                  Container(
                    width: double.infinity,
                    height: MediaQuery.of(context).size.height * 0.20,
                    padding: EdgeInsets.all(16.0),
                    decoration: BoxDecoration(
                      color: Color(0xFF029CDB),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: DottedBorder(
                      borderType: BorderType.RRect,
                      radius: const Radius.circular(8.0),
                      dashPattern: const [5, 5],
                      strokeWidth: 1.5,
                      color: Colors.white,
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            InkWell(
                              onTap: _pickAdditionalImages,
                              child: Icon(
                                Icons.add_photo_alternate,
                                size: 70,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(height: 8.0),
                            Text(
                              'Upload images (optional)',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12.0,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              '${_additionalPhotos.length}/5 uploaded',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 10.0,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                if (_additionalPhotos.isNotEmpty) SizedBox(height: 16),
                if (_additionalPhotos.isNotEmpty)
                  GridView.builder(
                    padding: EdgeInsets.zero,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _additionalPhotos.length,
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 4,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                    ),
                    itemBuilder: (context, index) {
                      final image = _additionalPhotos[index];
                      return Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.file(
                              File(image.path),
                              fit: BoxFit.cover,
                              width: double.infinity,
                              height: double.infinity,
                            ),
                          ),
                          Positioned(
                            right: 0,
                            top: 0,
                            child: InkWell(
                              onTap: () => _removeAdditionalPhoto(index),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.close,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                SizedBox(height: 24),

                // Spare Parts Section
                Text(
                  'Spare parts',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: 8),
                InkWell(
                  onTap: _showSparePartsDialog,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _selectedSpareParts.isEmpty
                              ? 'Select spare parts'
                              : '${_selectedSpareParts.length} part(s) selected',
                          style: TextStyle(
                            color: _selectedSpareParts.isEmpty
                                ? Colors.grey[600]
                                : Colors.black,
                          ),
                        ),
                        Icon(Icons.arrow_drop_down, color: Colors.grey[600]),
                      ],
                    ),
                  ),
                ),
                if (_selectedSpareParts.isNotEmpty) SizedBox(height: 8),
                if (_selectedSpareParts.isNotEmpty)
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _selectedSpareParts.map((part) {
                      return Chip(
                        label: Text(part.name),
                        backgroundColor: Color(0xFF1DA1F2).withOpacity(0.1),
                        deleteIcon: Icon(Icons.close, size: 18),
                        onDeleted: () {
                          setState(() {
                            _selectedSpareParts.remove(part);
                          });
                        },
                      );
                    }).toList(),
                  ),
                SizedBox(height: 16),

                // Vehicle Number
                Text(
                  'Vehicle Number',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: 8),
                TextFormField(
                  controller: _vehicleNumberController,
                  decoration: InputDecoration(
                    hintText: 'KW - 4637',
                    filled: true,
                    fillColor: Colors.grey[200],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter vehicle number';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 16),

                // Accident Location
                Text(
                  'Accident Location',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: 8),
                TextFormField(
                  controller: _locationController,
                  decoration: InputDecoration(
                    hintText: 'Kurunegala',
                    filled: true,
                    fillColor: Colors.grey[200],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter accident location';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 16),

                // Date & Time
                Text(
                  'Date & Time',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: 8),
                TextFormField(
                  controller: _dateTimeController,
                  readOnly: true,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.grey[200],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                    suffixIcon: Icon(Icons.calendar_today, color: Colors.grey[600]),
                  ),
                  onTap: _selectDateTime,
                ),
                SizedBox(height: 16),

                // Customer Name
                Text(
                  'Customer Name',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: 8),
                InkWell(
                  onTap: _showCustomerDialog,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _selectedCustomer?.fullName ?? 'Select customer',
                          style: TextStyle(
                            color: _selectedCustomer == null
                                ? Colors.grey[600]
                                : Colors.black,
                          ),
                        ),
                        Icon(Icons.arrow_drop_down, color: Colors.grey[600]),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 32),

                // Confirm Button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _submitAccident,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF1DA1F2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: _isLoading
                        ? CircularProgressIndicator(color: Colors.white)
                        : Text(
                      'Confirm',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 32),
              ],
            ),
          ),
        ],
      ),
    );
  }
}