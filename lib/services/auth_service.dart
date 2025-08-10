import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;


  Future<UserModel?> signUp(String email, String password, String name) async {
    try {
      print('Starting sign up for: $email');
      // Create user with Firebase Auth
      final UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final User? user = result.user;
      if (user == null) {
        print('Firebase user is null');
        return null;
      }
      // Update display name
      await user.updateDisplayName(name);
      // Create UserModel
      final userModel = UserModel(
        uid: user.uid,
        email: email,
        name: name,
        createdAt: DateTime.now(),
      );
      // Save user to Firestore
      await _firestore.collection('users').doc(user.uid).set(userModel.toMap());
      print('User stored in Firestore: ${userModel.toMap()}');
      return userModel;
    } on FirebaseAuthException catch (e) {
      print('FirebaseAuthException: ${e.code} - ${e.message}');
      rethrow;
    } catch (e, stack) {
      print('Unexpected error: $e');
      print(stack);
      return null;
    }
  }

  Future<UserModel?> signIn(String email, String password) async {
    try {
      print('Signing in with: $email');
      // Sign in with Firebase Auth
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      User? user = result.user;
      if (user == null) {
        print('Firebase user is null');
        return null;
      }
      // Fetch user data from Firestore
      DocumentSnapshot<Map<String, dynamic>> doc =
      await _firestore.collection('users').doc(user.uid).get();
      if (!doc.exists) {
        print('User document not found in Firestore');
        return null;
      }
      // Convert Firestore data to UserModel
      final userModel = UserModel.fromMap(doc.data()!);
      print('Signed in as: ${userModel.email}');
      return userModel;
    } on FirebaseAuthException catch (e) {
      print('FirebaseAuthException: ${e.code} - ${e.message}');
      rethrow;
    } catch (e, stack) {
      print('Unexpected error: $e');
      print(stack);
      return null;
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }
}