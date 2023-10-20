import 'package:flutter/material.dart';
import 'package:unicorns/home/widgets/image_banner.dart';
import 'package:unicorns/home/widgets/header.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Header(),
          ImageBanner(),
        ],
      ),
    );
  }
}
