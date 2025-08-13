import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/customer_model.dart';

class CustomerService {
  final CollectionReference _customersCollection =
  FirebaseFirestore.instance.collection('customers');

  // Add new customer
  Future<void> addCustomer(CustomerModel customer) async {
    try {
      await _customersCollection.doc(customer.id).set(customer.toMap());
    } catch (e) {
      print('Error adding customer: $e');
      throw Exception('Failed to add customer: $e');
    }
  }

  // Update existing customer
  Future<void> updateCustomer(CustomerModel customer) async {
    try {
      await _customersCollection.doc(customer.id).update(
          customer.copyWith(updatedAt: DateTime.now()).toMap()
      );
    } catch (e) {
      print('Error updating customer: $e');
      throw Exception('Failed to update customer: $e');
    }
  }

  // Delete customer
  Future<void> deleteCustomer(String customerId) async {
    try {
      await _customersCollection.doc(customerId).delete();
    } catch (e) {
      print('Error deleting customer: $e');
      throw Exception('Failed to delete customer: $e');
    }
  }

  // Get all customers as stream
  Stream<List<CustomerModel>> getCustomers() {
    return _customersCollection
        .orderBy('firstName')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return CustomerModel.fromMap(doc.data() as Map<String, dynamic>);
      }).toList();
    });
  }

  // Get customer by ID
  Future<CustomerModel?> getCustomerById(String customerId) async {
    try {
      final doc = await _customersCollection.doc(customerId).get();
      if (doc.exists) {
        return CustomerModel.fromMap(doc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      print('Error getting customer: $e');
      return null;
    }
  }

  // Search customers by name
  Stream<List<CustomerModel>> searchCustomers(String searchQuery) {
    if (searchQuery.isEmpty) {
      return getCustomers();
    }

    return _customersCollection
        .where('firstName', isGreaterThanOrEqualTo: searchQuery)
        .where('firstName', isLessThan: searchQuery + 'z')
        .snapshots()
        .map((snapshot) {
      List<CustomerModel> customers = snapshot.docs.map((doc) {
        return CustomerModel.fromMap(doc.data() as Map<String, dynamic>);
      }).toList();

      // Also search in last names
      return customers.where((customer) {
        return customer.firstName.toLowerCase().contains(searchQuery.toLowerCase()) ||
            customer.lastName.toLowerCase().contains(searchQuery.toLowerCase()) ||
            customer.fullName.toLowerCase().contains(searchQuery.toLowerCase());
      }).toList();
    });
  }

  // Check if customer exists by NIC
  Future<bool> customerExistsByNIC(String nic) async {
    try {
      final query = await _customersCollection
          .where('nic', isEqualTo: nic)
          .limit(1)
          .get();
      return query.docs.isNotEmpty;
    } catch (e) {
      print('Error checking customer by NIC: $e');
      return false;
    }
  }

  // Check if customer exists by phone number
  Future<bool> customerExistsByPhone(String phoneNumber) async {
    try {
      final query = await _customersCollection
          .where('phoneNumber', isEqualTo: phoneNumber)
          .limit(1)
          .get();
      return query.docs.isNotEmpty;
    } catch (e) {
      print('Error checking customer by phone: $e');
      return false;
    }
  }
}