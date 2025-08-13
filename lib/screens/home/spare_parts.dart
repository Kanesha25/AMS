import 'package:flutter/material.dart';
import '../../models/spare_part_model.dart';
import '../../database/spare_parts_database.dart';
import 'spare_parts_edit.dart';

class SparePartsScreen extends StatefulWidget {
  @override
  _SparePartsScreenState createState() => _SparePartsScreenState();
}

class _SparePartsScreenState extends State<SparePartsScreen> {
  final TextEditingController _searchController = TextEditingController();
  final SparePartsDatabase _database = SparePartsDatabase();
  List<SparePart> _allSpareParts = [];
  List<SparePart> _filteredSpareParts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSparePartsFromDatabase();
  }

  Future<void> _loadSparePartsFromDatabase() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final spareParts = await _database.getAllSpareParts();
      setState(() {
        _allSpareParts = spareParts;
        _filteredSpareParts = spareParts;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading spare parts: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
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

  Future<void> _refreshData() async {
    await _loadSparePartsFromDatabase();
    _filterSpareParts(_searchController.text);
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
                      hintText: 'Start typing here',
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
                SizedBox(height: 30),

                // Content based on loading state
                Expanded(
                  child: _isLoading
                      ? Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Color(0xFF1DA1F2),
                      ),
                    ),
                  )
                      : _filteredSpareParts.isEmpty
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
                      : RefreshIndicator(
                    onRefresh: _refreshData,
                    color: Color(0xFF1DA1F2),
                    child: ListView.builder(
                      itemCount: _filteredSpareParts.length,
                      itemBuilder: (context, index) {
                        final sparePart = _filteredSpareParts[index];
                        return _buildSparePartCard(sparePart);
                      },
                    ),
                  ),
                ),

                // Edit Spare Parts Button
                Container(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading
                        ? null
                        : () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => EditSparePartsScreen(
                            spareParts: _allSpareParts,
                            onSave: (updatedParts) async {
                              await _refreshData();
                            },
                          ),
                        ),
                      );

                      // Refresh data when returning from edit screen
                      if (result == true) {
                        await _refreshData();
                      }
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
    );
  }

  Widget _buildSparePartCard(SparePart sparePart) {
    return Container(
      margin: EdgeInsets.only(bottom: 15),
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: Offset(0, 2),
          ),
        ],
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

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}