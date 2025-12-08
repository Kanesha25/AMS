import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../database/spare_parts_database.dart';
import '../../models/accident_model.dart';
import '../../models/customer_model.dart';
import '../../models/detection_record.dart';
import '../../models/inspector_profile.dart';
import '../../models/spare_part_model.dart';
import '../../services/customer_service.dart';
import '../../services/database_service.dart';
import '../../services/detection_service.dart';
import 'estimation_report_screen.dart';

class NewAccidentScreen extends StatefulWidget {
  @override
  _NewAccidentScreenState createState() => _NewAccidentScreenState();
}

class _NewAccidentScreenState extends State<NewAccidentScreen> {
  final DatabaseService _databaseService = DatabaseService();
  final CustomerService _customerService = CustomerService();
  final SparePartsDatabase _sparePartsDatabase = SparePartsDatabase();
  final DetectionService _detectionService = DetectionService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final TextEditingController _vehicleNumberController = TextEditingController();
  final TextEditingController _modelController = TextEditingController();
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
  bool _isAnalyzingDetection = false;
  List<DetectionRecord> _latestDetections = [];
  String? _detectionError;
  static const int _maxPhotoCount = 5;
  List<SparePart> _matchedDetectedParts = [];
  int? _estimatedMinCost;
  int? _estimatedMaxCost;
  InspectorProfile? _inspectorProfile;
  static const Map<String, String> _labelAliases = {
    'rear_bumper': 'Rear Bumper',
    'rear bumper': 'Rear Bumper',
    'bumper_damage': 'Front Bumper',
    'bumper damage': 'Front Bumper',
    'bumper-damage': 'Front Bumper',
    'bumper': 'Front Bumper',
    'rear bumper damage': 'Rear Bumper',
    'left headlight damage': 'Left Headlight',
    'right headlight damage': 'Right Headlight',
    'front door': 'Front Door',
    'front_door': 'Front Door',
    'rear_door': 'Rear Door',
    'rear door': 'Rear Door',
    'bonnet': 'Bonnet',
    'hood': 'Bonnet',
    'trunk': 'Trunk',
    'boot': 'Trunk',
    'windshield_damage': 'Front Windshield',
    'rear_windshield': 'Rear Windshield',
    'windshield damage': 'Front Windshield',
    'windshield': 'Front Windshield',
    'windshield_rear': 'Rear Windshield',
    'left_headlight': 'Left Headlight',
    'right_headlight': 'Right Headlight',
    'left_side_mirror': 'Left Side Mirror',
    'right_side_mirror': 'Right Side Mirror',
    'tail_light': 'Tail Light',
    'taillight': 'Tail Light',
  };

  @override
  void initState() {
    super.initState();
    _loadSpareParts();
    _loadCustomers();
    _loadInspectorProfile();
    _dateTimeController.text = _formatDateTime(_selectedDateTime);
  }

  @override
  void dispose() {
    _vehicleNumberController.dispose();
    _modelController.dispose();
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

  Future<void> _loadInspectorProfile() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;
      final doc = await _firestore.collection('users').doc(user.uid).get();
      if (!doc.exists || doc.data() == null) return;
      final userData = doc.data()!;
      // Use user's name from profile as inspector name
      final userName = userData['name'] ?? 
                      '${userData['firstName'] ?? ''} ${userData['lastName'] ?? ''}'.trim() ??
                      user.displayName ??
                      user.email?.split('@')[0] ??
                      'Inspector';
      setState(() {
        _inspectorProfile = InspectorProfile.fromMap(
          userData,
          fallbackName: userName,
          fallbackPhone: userData['phoneNumber'] ?? user.phoneNumber ?? '',
        );
      });
    } catch (e) {
      print('Error loading inspector profile: $e');
    }
  }

  Future<void> _pickAdditionalImages() async {
    try {
      final List<XFile> images = await _picker.pickMultiImage(
        imageQuality: 85,
      );

      if (images.isNotEmpty) {
        setState(() {
          final remainingSlots = _maxPhotoCount - _additionalPhotos.length;
          _additionalPhotos.addAll(images.take(remainingSlots));
        });

        if (_additionalPhotos.length >= _maxPhotoCount) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Maximum $_maxPhotoCount images reached'),
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
      if (_additionalPhotos.isEmpty) {
        _latestDetections = [];
        _detectionError = null;
      }
    });
    if (_additionalPhotos.isEmpty) {
      _clearEstimation();
    }
  }


  Future<List<DetectionRecord>> _analyzeFirstPhoto({
    bool showLoader = true,
    bool showSnackOnError = true,
    bool throwOnError = false,
  }) async {
    if (_additionalPhotos.isEmpty) {
      if (showSnackOnError) {
        _showErrorSnackBar('Please upload at least one image first');
      }
      if (throwOnError) {
        throw Exception('No images available for detection.');
      }
      return [];
    }

    if (showLoader) {
      setState(() {
        _isAnalyzingDetection = true;
        _detectionError = null;
      });
    }

    try {
      final detections =
          await _detectionService.runDetection(File(_additionalPhotos.first.path));
      if (mounted) {
        setState(() {
          _latestDetections = detections;
          _detectionError = null;
        });
      }
      _updateEstimation(detections);
      return detections;
    } catch (e) {
      print('Detection error: $e');
      final message = 'Detection failed. Please try again.';
      if (mounted) {
        setState(() {
          _latestDetections = [];
          _detectionError = message;
        });
      }
      _clearEstimation();
      if (showSnackOnError) {
        _showErrorSnackBar(message);
      }
      if (throwOnError) {
        rethrow;
      }
      return [];
    } finally {
      if (showLoader && mounted) {
        setState(() {
          _isAnalyzingDetection = false;
        });
      }
    }
  }

  void _updateEstimation(List<DetectionRecord> detections) {
    final matchedParts = <SparePart>[];
    for (final detection in detections) {
      final match = _findSparePartForLabel(detection.label);
      if (match != null &&
          !matchedParts.any((existing) => existing.documentId == match.documentId)) {
        matchedParts.add(match);
      }
    }
    if (mounted) {
      setState(() {
        _matchedDetectedParts = matchedParts;
      });
    }
    _refreshCostEstimates();
  }

  void _clearEstimation() {
    if (!mounted) return;
    setState(() {
      _matchedDetectedParts = [];
    });
    _refreshCostEstimates();
  }

  SparePart? _findSparePartForLabel(String rawLabel) {
    if (_allSpareParts.isEmpty) return null;
    final resolvedName = _resolveDetectionLabel(rawLabel);
    try {
      return _allSpareParts.firstWhere(
        (part) => part.name.toLowerCase() == resolvedName.toLowerCase(),
      );
    } catch (_) {
      return null;
    }
  }

  String _resolveDetectionLabel(String label) {
    var normalized = label.trim().toLowerCase();
    
    // Check aliases first with original label
    if (_labelAliases.containsKey(normalized)) {
      return _labelAliases[normalized]!;
    }
    
    // Replace hyphens/underscores with spaces
    normalized = normalized.replaceAll(RegExp(r'[_-]+'), ' ');
    
    // Check aliases again after replacing hyphens/underscores
    if (_labelAliases.containsKey(normalized)) {
      return _labelAliases[normalized]!;
    }
    
    // Remove damage-related words
    normalized =
        normalized.replaceAll(RegExp(r'\b(damage|damaged|area|part)\b'), '').trim();
    normalized = normalized.replaceAll(RegExp(r'\s+'), ' ');

    if (normalized.isEmpty) {
      normalized = label.trim().toLowerCase();
    }

    // Check aliases one more time after removing damage words
    if (_labelAliases.containsKey(normalized)) {
      return _labelAliases[normalized]!;
    }

    return normalized
        .split(' ')
        .map(
          (word) => word.isEmpty
              ? word
              : '${word[0].toUpperCase()}${word.substring(1)}',
        )
        .join(' ');
  }

  String _formatCurrency(num value) {
    final str = value.toStringAsFixed(0);
    final reg = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
    return str.replaceAllMapped(reg, (Match m) => '${m[1]},');
  }

  List<SparePart> _getCombinedEstimationParts() {
    final Map<String, SparePart> partsMap = {};
    for (final part in _matchedDetectedParts) {
      final key = part.documentId ?? part.id?.toString() ?? part.name;
      partsMap[key] = part;
    }
    for (final part in _selectedSpareParts) {
      final key = part.documentId ?? part.id?.toString() ?? part.name;
      partsMap[key] = part;
    }
    return partsMap.values.toList();
  }

  void _refreshCostEstimates() {
    if (!mounted) return;
    final combined = _getCombinedEstimationParts();
    setState(() {
      if (combined.isEmpty) {
        _estimatedMinCost = null;
        _estimatedMaxCost = null;
      } else {
        _estimatedMinCost =
            combined.fold<int>(0, (sum, part) => sum + part.minPrice);
        _estimatedMaxCost =
            combined.fold<int>(0, (sum, part) => sum + part.maxPrice);
      }
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
                _refreshCostEstimates();
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
                    _modelController.text = customer.model;
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

    if (_additionalPhotos.isEmpty) {
      _showErrorSnackBar('Please upload at least one accident image');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final accidentId = 'ACC-${DateTime.now().millisecondsSinceEpoch}';
      final detections = await _analyzeFirstPhoto(
        showLoader: false,
        showSnackOnError: true,
        throwOnError: false,
      );

      final combinedParts = _getCombinedEstimationParts();
      if (combinedParts.isEmpty) {
        _showErrorSnackBar(
            'No spare parts detected. Please add them manually before submitting.');
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // Create accident model with all the data
      final accident = AccidentModel(
        id: accidentId,
        location: _locationController.text.trim(),
        description:
            'Customer: ${_selectedCustomer!.fullName}, Vehicle: ${_vehicleNumberController.text}, Model: ${_modelController.text}, Parts: ${combinedParts.map((p) => p.name).join(", ")}',
        timestamp: _selectedDateTime,
        status: 'Pending',
        vehicleNumber: _vehicleNumberController.text.trim(),
        vehicleModel: _modelController.text.trim(),
        imageUrls: const [],
        detections: detections,
        estimatedParts:
            combinedParts.map((part) => part.toEstimationMap()).toList(),
        estimatedMinCost: _estimatedMinCost ??
            combinedParts.fold<int>(0, (sum, part) => sum + part.minPrice),
        estimatedMaxCost: _estimatedMaxCost ??
            combinedParts.fold<int>(0, (sum, part) => sum + part.maxPrice),
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

      // Show preview/confirmation dialog
      final shouldViewReport = await _showEstimationPreviewDialog(
        context,
        accident,
        combinedParts,
      );

      if (shouldViewReport == true) {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => EstimationReportScreen(
              accident: accident,
              customer: _selectedCustomer!,
              inspectorProfile: _inspectorProfile,
              estimationParts: combinedParts,
            ),
          ),
        );
      }

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

  Future<bool?> _showEstimationPreviewDialog(
    BuildContext context,
    AccidentModel accident,
    List<SparePart> parts,
  ) async {
    final totalAvgCost = parts.fold<int>(
      0,
      (sum, part) => sum + ((part.minPrice + part.maxPrice) ~/ 2),
    );

    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text('Estimation Preview'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Estimated Cost: LKR ${_formatCurrency(totalAvgCost)}',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1DA1F2),
                ),
              ),
              SizedBox(height: 12),
              Text(
                'Detected Parts (${parts.length}):',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              SizedBox(height: 8),
              ...parts.map((part) => Padding(
                    padding: EdgeInsets.only(bottom: 4),
                    child: Text(
                      '• ${part.name}',
                      style: TextStyle(fontSize: 14),
                    ),
                  )),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF1DA1F2),
            ),
            child: Text('View Full Report'),
          ),
        ],
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
      ),
    );
  }

  Widget _buildDetectionSection() {
    if (_additionalPhotos.isEmpty) {
      return SizedBox.shrink();
    }

    final combinedParts = _getCombinedEstimationParts();

    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Damage Detection',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              TextButton.icon(
                onPressed: _isAnalyzingDetection
                    ? null
                    : () => _analyzeFirstPhoto(),
                icon: _isAnalyzingDetection
                    ? SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(Icons.auto_fix_high, size: 18),
                label: Text(
                  _latestDetections.isEmpty ? 'Analyze' : 'Re-run',
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          if (_detectionError != null)
            Text(
              _detectionError!,
              style: TextStyle(color: Colors.red, fontSize: 12),
            ),
          if (_latestDetections.isEmpty && _detectionError == null)
            Text(
              'We will analyse the first uploaded image to detect damaged parts.',
              style: TextStyle(color: Colors.grey[700], fontSize: 13),
            ),
          if (_latestDetections.isNotEmpty) ...[
            ..._latestDetections.map(
              (detection) => Padding(
                padding: const EdgeInsets.only(top: 6.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        detection.label,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Text(
                      '${(detection.confidence * 100).toStringAsFixed(1)}%',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[700],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          if (_selectedSpareParts.isNotEmpty) ...[
            SizedBox(height: 12),
            Text(
              'Manually added spare parts',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            ..._selectedSpareParts.map(
              (part) => Padding(
                padding: const EdgeInsets.only(top: 6.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        part.name,
                        style: TextStyle(fontSize: 13.5),
                      ),
                    ),
                    Text(
                      'LKR ${_formatCurrency(part.minPrice)} - ${_formatCurrency(part.maxPrice)}',
                      style: TextStyle(
                        fontSize: 12.5,
                        color: Colors.grey[700],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          if (combinedParts.isNotEmpty) ...[
            SizedBox(height: 12),
            Divider(),
            SizedBox(height: 8),
            Text(
              'Spare parts included in estimation',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            ...combinedParts.map(
              (part) => Padding(
                padding: const EdgeInsets.only(top: 6.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        part.name,
                        style: TextStyle(fontSize: 13.5),
                      ),
                    ),
                    Text(
                      'LKR ${_formatCurrency(part.minPrice)} - ${_formatCurrency(part.maxPrice)}',
                      style: TextStyle(
                        fontSize: 12.5,
                        color: Colors.grey[700],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (_estimatedMinCost != null && _estimatedMaxCost != null) ...[
              SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Color(0xFF1DA1F2).withOpacity(0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Estimated cost range',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'LKR ${_formatCurrency(_estimatedMinCost!)} - ${_formatCurrency(_estimatedMaxCost!)}',
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
          ] else if (_latestDetections.isNotEmpty &&
              _detectionError == null &&
              _selectedSpareParts.isEmpty) ...[
            SizedBox(height: 12),
            Text(
              'Detected parts did not match the configured spare parts list. Please add them manually using the spare parts selector above.',
              style: TextStyle(color: Colors.orange[700], fontSize: 12),
            ),
          ],
        ],
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
                if (_additionalPhotos.length < _maxPhotoCount)
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
                              '${_additionalPhotos.length}/$_maxPhotoCount uploaded',
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
                if (_additionalPhotos.isNotEmpty) SizedBox(height: 16),
                if (_additionalPhotos.isNotEmpty) _buildDetectionSection(),
                SizedBox(height: 24),

                // Spare Parts Section
                Text(
                  'Spare parts (optional)',
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
                              ? 'Add spare parts manually when detection misses'
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
                        _refreshCostEstimates();
                        },
                      );
                    }).toList(),
                  ),
                SizedBox(height: 16),

                // Customer
                Text(
                  'Customer',
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
                    hintText: 'CAA - 2530',
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

                // Vehicle Model
                Text(
                  'Vehicle Model',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: 8),
                TextFormField(
                  controller: _modelController,
                  decoration: InputDecoration(
                    hintText: 'Toyota Aqua',
                    filled: true,
                    fillColor: Colors.grey[200],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter vehicle model';
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
                    hintText: 'Ratmalana',
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