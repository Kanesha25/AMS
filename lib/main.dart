import 'package:flutter/material.dart';
import 'loading_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Accident Management System',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        primaryColor: Color(0xFF1DA1F2),
      ),
      home: LoadingScreen(), // Loading screen runs first
      debugShowCheckedModeBanner: false,
    );
  }
}