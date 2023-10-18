import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_shaders/flutter_shaders.dart';
import 'package:unicorns/utils.dart';

const buttonSize = 48.0;

const blackWhite = Colors.black;

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

  final categoryListScrollController = ScrollController();

  late final timeAnimController = AnimationController(
    vsync: this,
    duration: const Duration(days: 1),
  );

  double oldOffset = 0;
  double targetOffset = 0;
  double yOffset = 0;
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

    categoryListScrollController.addListener(onCategoryListScroll);
  }

  void onCategoryListScroll() {
    final stackContext = stackKey.currentContext!;

    final center = buttonKeys[selectedButton.value]
        .getPaintBounds(stackContext.findRenderObject())!
        .center;

    final offset = center.dx / stackContext.size!.width;
    oldOffset = offset;
    targetOffset = offset;
  }

  void focusButton(int selectedButton) {
    final stackContext = stackKey.currentContext!;

    final center = buttonKeys[selectedButton]
        .getPaintBounds(stackContext.findRenderObject())!
        .center;

    final offset = center.dx / stackContext.size!.width;
    oldOffset = currOffset;
    targetOffset = offset;

    yOffset = center.dy / stackContext.size!.height;

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
                              final double dist = offsetAnim.value;
                              final t = timeAnimController.value;
                              final offset = currOffset;

                              int i = 0;
                              shader
                                ..setFloat(i++, size.width)
                                ..setFloat(i++, size.height)
                                ..setFloat(i++, t * 50000)
                                ..setFloat(i++, offset)
                                ..setFloat(i++, dist)
                                ..setFloat(i++, yOffset)
                                ..setFloat(i++, oldOffset)
                                ..setFloat(i++, targetOffset)
                                ..setImageSampler(0, image);

                              canvas.drawRect(
                                Offset.zero & size,
                                Paint()..shader = shader,
                              );
                            },
                            child: Container(
                              color: Colors.white,
                              child: buildContent(),
                            ),
                          );
                        },
                      );
                    },
                    assetKey: 'assets/shaders/wavy.frag',
                  ),
                  buildButtons(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildContent() {
    return const Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Padding(
          padding: EdgeInsets.only(right: 32, left: 32, bottom: 120),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                'Collections',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: blackWhite,
                ),
              ),
              Spacer(),
              Text(
                'All',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: blackWhite,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget buildButtons() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Spacer(),
        const SizedBox(height: 24),
        SizedBox(
          height: buttonSize + 2,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            controller: categoryListScrollController,
            child: ValueListenableBuilder(
              valueListenable: selectedButton,
              builder: (context, value, child) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(width: 32),
                    for (final (i, key) in buttonKeys.enumerate()) ...[
                      buildButton(key, i, value),
                      if (i < buttonKeys.length - 1) const SizedBox(width: 64),
                    ],
                    const SizedBox(width: 32),
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

  Widget buildButton(GlobalKey<State<StatefulWidget>> key, int i, int value) {
    return SizedBox(
      key: key,
      width: buttonSize,
      height: buttonSize,
      child: FilledButton(
        onPressed: () {
          selectedButton.value = i;
        },
        statesController: MaterialStatesController({
          if (i == value) MaterialState.selected,
        }),
        style: ButtonStyle(
          animationDuration: offsetAnimController.duration,
          padding: const MaterialStatePropertyAll(EdgeInsets.zero),
          shape: MaterialStateProperty.resolveWith((states) {
            if (states.contains(MaterialState.selected)) {
              return const CircleBorder();
            }
            return const CircleBorder(
              side: BorderSide(color: Colors.black, width: 0.5),
            );
          }),
          foregroundColor: MaterialStateProperty.resolveWith((states) {
            if (states.contains(MaterialState.selected)) {
              return Colors.white;
            }
            return Colors.black;
          }),
          backgroundColor: const MaterialStatePropertyAll(Colors.transparent),
        ),
        child: const Icon(
          Icons.add_shopping_cart_rounded,
          // size: buttonSize / 2,
        ),
      ),
    );
  }
}
