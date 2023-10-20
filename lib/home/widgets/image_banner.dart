import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:unicorns/home/providers.dart';

class ImageBanner extends StatelessWidget {
  ImageBanner({super.key});

  final tapNotifier = ValueNotifier(false);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
      child: GestureDetector(
        onTapDown: (details) {
          tapNotifier.value = true;
        },
        onTapUp: (details) {
          tapNotifier.value = false;
        },
        onTapCancel: () {
          tapNotifier.value = false;
        },
        child: ValueListenableBuilder(
          valueListenable: tapNotifier,
          builder: (context, value, child) {
            return AnimatedScale(
              duration: const Duration(milliseconds: 100),
              scale: tapNotifier.value ? 0.95 : 1,
              child: child,
            );
          },
          child: SizedBox(
            height: 96,
            child: Card(
              clipBehavior: Clip.antiAlias,
              margin: EdgeInsets.zero,
              elevation: 16,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Consumer(builder: (context, ref, child) {
                final content = ref.watch(tabContentProvider);

                return Stack(
                  children: [
                    Positioned.fill(
                      child: Image.asset(
                        content.headerImagePath,
                        fit: BoxFit.cover,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Center(
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            content.bannerTitle,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}
