import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/spare_part_model.dart';
import '../../database/spare_parts_database.dart';

class EditSparePartsScreen extends StatefulWidget {
  final List<SparePart> spareParts;
  final Function(List<SparePart>) onSave;

  const EditSparePartsScreen({
    Key? key,
    required this.spareParts,
    required this.onSave,
  }) : super(key: key);

  @override
  _EditSparePartsScreenState createState() => _EditSparePartsScreenState();
}

class _EditSparePartsScreenState extends State<EditSparePartsScreen> {
  final TextEditingController _searchController = TextEditingController();
  final SparePartsDatabase _database = SparePartsDatabase();

  late List<SparePart> _editableSpareParts;
  List<SparePart> _filteredSpareParts = [];
  List<TextEditingController> _minPriceControllers = [];
  List<TextEditingController> _maxPriceControllers = [];
  bool _isLoading = false;
  bool _hasUnsavedChanges = false;

  @override
  void initState() {
    super.initState();
    _editableSpareParts = widget.spareParts
        .map(
          (part) => SparePart(
            documentId: part.documentId,
            id: part.id,
            name: part.name,
            minPrice: part.minPrice,
            maxPrice: part.maxPrice,
          ),
        )
        .toList();

    _filteredSpareParts = _editableSpareParts;
    _initializeControllers();
  }

  void _initializeControllers() {
    // Clear existing controllers
    for (var controller in _minPriceControllers) {
      controller.dispose();
    }
    for (var controller in _maxPriceControllers) {
      controller.dispose();
    }

    _minPriceControllers.clear();
    _maxPriceControllers.clear();

    // Initialize controllers for filtered parts
    for (int i = 0; i < _filteredSpareParts.length; i++) {
      _minPriceControllers.add(
        TextEditingController(text: _filteredSpareParts[i].minPrice.toString()),
      );
      _maxPriceControllers.add(
        TextEditingController(text: _filteredSpareParts[i].maxPrice.toString()),
      );
    }
  }

  void _filterSpareParts(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredSpareParts = _editableSpareParts;
      } else {
        _filteredSpareParts = _editableSpareParts
            .where((part) =>
            part.name.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
    _initializeControllers();
  }

  void _onPriceChanged() {
    if (!_hasUnsavedChanges) {
      setState(() {
        _hasUnsavedChanges = true;
      });
    }
  }

  Future<void> _saveChanges() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Update all spare parts with new prices
      for (int i = 0; i < _filteredSpareParts.length; i++) {
        final minPrice = int.tryParse(_minPriceControllers[i].text) ??
            _filteredSpareParts[i].minPrice;
        final maxPrice = int.tryParse(_maxPriceControllers[i].text) ??
            _filteredSpareParts[i].maxPrice;

        // Validate price range
        if (minPrice > maxPrice) {
          _showErrorDialog('Invalid Price Range',
              'Minimum price cannot be greater than maximum price for ${_filteredSpareParts[i]
                  .name}');
          setState(() {
            _isLoading = false;
          });
          return;
        }

        // Update in the main list
        final originalIndex = _editableSpareParts.indexWhere(
                (part) => part.id == _filteredSpareParts[i].id);
        if (originalIndex != -1) {
          _editableSpareParts[originalIndex] =
              _editableSpareParts[originalIndex].copyWith(
                minPrice: minPrice,
                maxPrice: maxPrice,
              );
        }
      }

      // Save to database
      await _database.updateMultipleSpareParts(_editableSpareParts);

      // Call the callback to update the parent
      widget.onSave(_editableSpareParts);

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 10),
              Text('Spare parts updated successfully!'),
            ],
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      );

      setState(() {
        _hasUnsavedChanges = false;
        _isLoading = false;
      });

      // Go back to previous screen
      Navigator.pop(context, true);
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      _showErrorDialog('Error', 'Failed to save changes: $e');
    }
  }

  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) =>
          AlertDialog(
            title: Text(title),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('OK'),
              ),
            ],
          ),
    );
  }

  Future<bool> _onWillPop() async {
    if (!_hasUnsavedChanges) return true;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) =>
          AlertDialog(
            title: Text('Unsaved Changes'),
            content: Text(
                'You have unsaved changes. Do you want to discard them?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text('Discard'),
              ),
            ],
          ),
    );

    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () async {
              final canPop = await _onWillPop();
              if (canPop) {
                Navigator.pop(context);
              }
            },
          ),
          title: Text(
            'Edit Spare Parts',
            style: TextStyle(
              color: Colors.black,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          centerTitle: true,
          actions: [
            if (_hasUnsavedChanges)
              Container(
                margin: EdgeInsets.only(right: 8),
                child: Icon(
                  Icons.circle,
                  color: Colors.orange,
                  size: 12,
                ),
              ),
          ],
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
            Padding(
              padding: EdgeInsets.all(20),
              child: Column(
                children: [
                  // Search Bar
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: _filterSpareParts,
                      decoration: InputDecoration(
                        hintText: 'Search spare parts to edit',
                        hintStyle: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 16,
                        ),
                        prefixIcon: Icon(
                          Icons.search,
                          color: Colors.grey[600],
                        ),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                          icon: Icon(Icons.clear, color: Colors.grey[600]),
                          onPressed: () {
                            _searchController.clear();
                            _filterSpareParts('');
                          },
                        )
                            : null,
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 15,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 20),

                  // Results count
                  if (_searchController.text.isNotEmpty)
                    Container(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        '${_filteredSpareParts.length} spare part(s) found',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                    ),
                  if (_searchController.text.isNotEmpty)
                    SizedBox(height: 10),

                  // Editable Spare Parts List
                  Expanded(
                    child: _filteredSpareParts.isEmpty
                        ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.search_off,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          SizedBox(height: 16),
                          Text(
                            'No spare parts found',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey[600],
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Try adjusting your search terms',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    )
                        : ListView.builder(
                      itemCount: _filteredSpareParts.length,
                      itemBuilder: (context, index) {
                        final sparePart = _filteredSpareParts[index];
                        return _buildEditableSparePartCard(sparePart, index);
                      },
                    ),
                  ),

                  // Save Changes Button
                  Container(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _saveChanges,
                      child: _isLoading
                          ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white),
                            ),
                          ),
                          SizedBox(width: 10),
                          Text(
                            'Saving...',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ],
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
                        backgroundColor: _hasUnsavedChanges
                            ? Color(0xFF1DA1F2)
                            : Colors.grey[400],
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEditableSparePartCard(SparePart sparePart, int index) {
    return Container(
      margin: EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Spare Part Name
          Text(
            sparePart.name,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
          SizedBox(height: 10),

          // Price Range Input
          Container(
            padding: EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: Colors.grey[400]!,
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Text(
                  'Price : ',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[700],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                // Min Price Input
                Expanded(
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: TextField(
                      controller: _minPriceControllers[index],
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.black,
                        fontWeight: FontWeight.w500,
                      ),
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(vertical: 8),
                        isDense: true,
                      ),
                      onChanged: (value) {
                        _onPriceChanged();
                        final newMinPrice = int.tryParse(value);
                        if (newMinPrice != null) {
                          final originalIndex = _editableSpareParts.indexWhere(
                                  (part) =>
                              part.id == _filteredSpareParts[index].id);
                          if (originalIndex != -1) {
                            _editableSpareParts[originalIndex] =
                                _editableSpareParts[originalIndex].copyWith(
                                  minPrice: newMinPrice,
                                );
                          }
                        }
                      },
                    ),
                  ),
                ),
                Container(
                  margin: EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    ' - ',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                // Max Price Input
                Expanded(
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: TextField(
                      controller: _maxPriceControllers[index],
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.black,
                        fontWeight: FontWeight.w500,
                      ),
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(vertical: 8),
                        isDense: true,
                      ),
                      onChanged: (value) {
                        _onPriceChanged();
                        final newMaxPrice = int.tryParse(value);
                        if (newMaxPrice != null) {
                          final originalIndex = _editableSpareParts.indexWhere(
                                  (part) =>
                              part.id == _filteredSpareParts[index].id);
                          if (originalIndex != -1) {
                            _editableSpareParts[originalIndex] =
                                _editableSpareParts[originalIndex].copyWith(
                                  maxPrice: newMaxPrice,
                                );
                          }
                        }
                      },
                    ),
                  ),
                ),
                Text(
                  ' LKR',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[700],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    for (var controller in _minPriceControllers) {
      controller.dispose();
    }
    for (var controller in _maxPriceControllers) {
      controller.dispose();
    }
    super.dispose();
  }
}