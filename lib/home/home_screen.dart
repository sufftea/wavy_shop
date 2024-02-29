import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:unicorns/home/providers.dart';
import 'package:unicorns/home/widgets/image_banner.dart';
import 'package:unicorns/home/widgets/header.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    
    return Consumer(
      builder: (context, ref, child) {
        final s = ref.watch(tabContentProvider);

        return Scaffold(
          body: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            color: Color.lerp(Colors.white, s.color, 0.1),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Header(),
                ImageBanner(),
              ],
            ),
          ),
        );
      }
    );
  }
}
