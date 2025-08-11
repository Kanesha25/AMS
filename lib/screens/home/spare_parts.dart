import 'package:flutter/material.dart';
import '../../models/spare_part_model.dart';
import 'spare_parts_edit.dart';


class SparePartsScreen extends StatefulWidget {
  @override
  _SparePartsScreenState createState() => _SparePartsScreenState();
}

class _SparePartsScreenState extends State<SparePartsScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<SparePart> _allSpareParts = [];
  List<SparePart> _filteredSpareParts = [];

  @override
  void initState() {
    super.initState();
    _initializeSpareParts();
    _filteredSpareParts = _allSpareParts;
  }

  void _initializeSpareParts() {
    _allSpareParts = [
      SparePart(
        name: 'Left Headlight',
        minPrice: 50000,
        maxPrice: 125000,
      ),
      SparePart(
        name: 'Side Mirror',
        minPrice: 20000,
        maxPrice: 75000,
      ),
      SparePart(
        name: 'Tail Light',
        minPrice: 50000,
        maxPrice: 100000,
      ),
      SparePart(
        name: 'Bonnet',
        minPrice: 10000,
        maxPrice: 15000,
      ),
      SparePart(
        name: 'Bumper',
        minPrice: 70000,
        maxPrice: 150000,
      ),
      SparePart(
        name: 'Windscreen',
        minPrice: 100000,
        maxPrice: 175000,
      ),
    ];
  }

  void _filterSpareParts(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredSpareParts = _allSpareParts;
      } else {
        _filteredSpareParts = _allSpareParts
            .where((part) =>
            part.name.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
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
          'Spare Parts',
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
                // Search Bar
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: _filterSpareParts,
                    decoration: InputDecoration(
                      hintText: 'Start typing here',
                      hintStyle: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 16,
                      ),
                      prefixIcon: Icon(
                        Icons.search,
                        color: Colors.grey[600],
                      ),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 15,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 30),

                // Spare Parts List
                Expanded(
                  child: ListView.builder(
                    itemCount: _filteredSpareParts.length,
                    itemBuilder: (context, index) {
                      final sparePart = _filteredSpareParts[index];
                      return _buildSparePartCard(sparePart);
                    },
                  ),
                ),

                // Edit Spare Parts Button
                Container(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => EditSparePartsScreen(
                            spareParts: _allSpareParts,
                            onSave: (updatedParts) {
                              setState(() {
                                _allSpareParts = updatedParts;
                                _filterSpareParts(_searchController.text);
                              });
                            },
                          ),
                        ),
                      );
                    },
                    child: Text(
                      'Edit Spare Parts',
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

  Widget _buildSparePartCard(SparePart sparePart) {
    return Container(
      margin: EdgeInsets.only(bottom: 15),
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            sparePart.name,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
          SizedBox(height: 8),
          Container(
            height: 2,
            color: Colors.black,
          ),
          SizedBox(height: 8),
          Text(
            'Price : ${_formatPrice(sparePart.minPrice)} - ${_formatPrice(sparePart.maxPrice)} LKR',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }

  String _formatPrice(int price) {
    return price.toString().replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},');
  }
}