import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_shaders/flutter_shaders.dart';
import 'package:unicorns/utils.dart';

const buttonSize = 48.0;

void main() {
  runApp(const MainApp());
}

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> with TickerProviderStateMixin {
  final selectedButton = ValueNotifier<int>(0);

  late final timeAnimController = AnimationController(
    vsync: this,
    duration: const Duration(days: 1),
  );

  double oldOffset = 0;
  double targetOffset = 0;
  double get currOffset {
    return ui.lerpDouble(
      oldOffset,
      targetOffset,
      offsetAnim.value,
    )!;
  }

  late final offsetAnimController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 500),
  );
  late final offsetAnim =
      CurveTween(curve: Curves.easeInOutQuad).animate(offsetAnimController);

  final stackKey = GlobalKey();
  final buttonKeys = List.generate(
    4,
    (index) => GlobalKey(),
  );

  @override
  void initState() {
    super.initState();

    timeAnimController.repeat();

    selectedButton.addListener(() {
      focusButton(selectedButton.value);
    });

    WidgetsBinding.instance.addPostFrameCallback((timeStamp) async {
      focusButton(0);
    });
  }

  void focusButton(int selectedButton) {
    final center = buttonKeys[selectedButton].globalPaintBounds!.center;

    final offset = center.dx / context.size!.width;
    oldOffset = currOffset;
    targetOffset = offset;

    offsetAnimController.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: 400,
              child: Stack(
                key: stackKey,
                fit: StackFit.passthrough,
                children: [
                  Image.asset(
                    'assets/images/clouds1.jpeg',
                    fit: BoxFit.cover,
                  ),
                  ShaderBuilder(
                    (context, shader, child) {
                      return AnimatedBuilder(
                        animation: Listenable.merge([
                          timeAnimController,
                          offsetAnimController,
                        ]),
                        builder: (context, child) {
                          return AnimatedSampler(
                            (image, size, canvas) {
                              final double dist =
                                  -pow(offsetAnim.value * 2 - 1, 2) + 1;
                              final t = timeAnimController.value;
                              final offset = currOffset;

                              int i = 0;
                              shader
                                ..setFloat(i++, size.width)
                                ..setFloat(i++, size.height)
                                ..setFloat(i++, t * 50000)
                                ..setFloat(i++, offset)
                                ..setFloat(i++, dist)
                                // ..setFloat(i++, dist)
                                // ..setFloat(i++, dist)
                                ..setImageSampler(0, image);

                              canvas.drawRect(
                                Offset.zero & size,
                                Paint()..shader = shader,
                              );
                            },
                            child: Container(
                              color: Colors.white,
                            ),
                          );
                        },
                      );
                    },
                    assetKey: 'assets/shaders/wavy.frag',
                  ),
                  buildContent(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Spacer(),
        // const Padding(
        //   padding: EdgeInsets.symmetric(horizontal: 32),
        //   child: Row(
        //     crossAxisAlignment: CrossAxisAlignment.center,
        //     children: [
        //       Text(
        //         'Collections',
        //         style: TextStyle(
        //           fontSize: 24,
        //           fontWeight: FontWeight.bold,
        //           color: _MagicColors.blackWhite,
        //         ),
        //       ),
        //       Spacer(),
        //       Text(
        //         'All',
        //         style: TextStyle(
        //           fontSize: 16,
        //           fontWeight: FontWeight.bold,
        //           color: _MagicColors.blackWhite,
        //         ),
        //       ),
        //     ],
        //   ),
        // ),
        const SizedBox(height: 24),
        SizedBox(
          height: buttonSize + 2,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ValueListenableBuilder(
              valueListenable: selectedButton,
              builder: (context, value, child) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(width: 32),
                    for (final (i, key) in buttonKeys.enumerate()) ...[
                      SizedBox(
                        key: key,
                        width: buttonSize,
                        height: buttonSize,
                        child: FilledButton(
                          onPressed: () {
                            selectedButton.value = i;
                          },
                          style: ButtonStyle(
                            padding: const MaterialStatePropertyAll(EdgeInsets.zero),
                            shape: MaterialStatePropertyAll(
                              ContinuousRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(buttonSize / 2),
                              ),
                            ),
                          ),
                          child: const Icon(
                            Icons.add_shopping_cart_rounded,
                            // size: buttonSize / 2,
                          ),
                        ),
                      ),
                      if (i < buttonKeys.length - 1) const SizedBox(width: 64),
                    ]
                  ],
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 48),
      ],
    );
  }
}
