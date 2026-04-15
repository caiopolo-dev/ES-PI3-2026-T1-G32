import 'package:flutter/material.dart';
//-------------------------
//pages
import 'package:mescla_invest/src/pages/auth/full_name_page.dart';
//-------------------------

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: const FullNamePage(),
    );
  }
}




