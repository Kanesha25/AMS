import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/spare_part_model.dart';

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
  late List<SparePart> _editableSpareParts;
  List<TextEditingController> _minPriceControllers = [];
  List<TextEditingController> _maxPriceControllers = [];

  @override
  void initState() {
    super.initState();
    _editableSpareParts = widget.spareParts
        .map((part) => SparePart(
      name: part.name,
      minPrice: part.minPrice,
      maxPrice: part.maxPrice,
    ))
        .toList();

    // Initialize controllers with current values
    for (int i = 0; i < _editableSpareParts.length; i++) {
      _minPriceControllers.add(
        TextEditingController(text: _editableSpareParts[i].minPrice.toString()),
      );
      _maxPriceControllers.add(
        TextEditingController(text: _editableSpareParts[i].maxPrice.toString()),
      );
    }
  }

  @override
  void dispose() {
    for (var controller in _minPriceControllers) {
      controller.dispose();
    }
    for (var controller in _maxPriceControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _saveChanges() {
    // Update the spare parts with new prices
    for (int i = 0; i < _editableSpareParts.length; i++) {
      final minPrice = int.tryParse(_minPriceControllers[i].text) ?? _editableSpareParts[i].minPrice;
      final maxPrice = int.tryParse(_maxPriceControllers[i].text) ?? _editableSpareParts[i].maxPrice;

      _editableSpareParts[i] = _editableSpareParts[i].copyWith(
        minPrice: minPrice,
        maxPrice: maxPrice,
      );
    }

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

    // Go back to previous screen
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
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
      ),
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
          // Main content
          Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              children: [
                // Editable Spare Parts List
                Expanded(
                  child: ListView.builder(
                    itemCount: _editableSpareParts.length,
                    itemBuilder: (context, index) {
                      final sparePart = _editableSpareParts[index];
                      return _buildEditableSparePartCard(sparePart, index);
                    },
                  ),
                ),

                // Save Changes Button
                Container(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _saveChanges,
                    child: Text(
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
                        borderRadius: BorderRadius.circular(25),
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
                  child: TextField(
                    controller: _minPriceControllers[index],
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[700],
                      fontWeight: FontWeight.w500,
                    ),
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                      isDense: true,
                    ),
                    onChanged: (value) {
                      // Update the model in real-time if needed
                      final newMinPrice = int.tryParse(value);
                      if (newMinPrice != null) {
                        _editableSpareParts[index] = _editableSpareParts[index].copyWith(
                          minPrice: newMinPrice,
                        );
                      }
                    },
                  ),
                ),
                Text(
                  ' - ',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[700],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                // Max Price Input
                Expanded(
                  child: TextField(
                    controller: _maxPriceControllers[index],
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[700],
                      fontWeight: FontWeight.w500,
                    ),
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                      isDense: true,
                    ),
                    onChanged: (value) {
                      // Update the model in real-time if needed
                      final newMaxPrice = int.tryParse(value);
                      if (newMaxPrice != null) {
                        _editableSpareParts[index] = _editableSpareParts[index].copyWith(
                          maxPrice: newMaxPrice,
                        );
                      }
                    },
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
}