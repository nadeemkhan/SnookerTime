// lib/main.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'home.dart';
import 'models.dart';

void main() {
  runApp(SnookerTimeApp());
}

class SnookerTimeApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SnookerTime',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Color(0xFF287233)),
        useMaterial3: true,
        textTheme: GoogleFonts.latoTextTheme(),
      ),
      home: SnookerTimeHome(),
    );
  }
}
