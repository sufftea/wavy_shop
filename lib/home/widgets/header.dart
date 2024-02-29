import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_shaders/flutter_shaders.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:unicorns/home/providers.dart';
import 'package:unicorns/utils.dart';

const buttonSize = 48.0;

const blackWhite = Colors.black;

class Header extends ConsumerStatefulWidget {
  const Header({super.key});

  @override
  ConsumerState<Header> createState() => _HeaderState();
}

class _HeaderState extends ConsumerState<Header> with TickerProviderStateMixin {
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
  List<GlobalKey> buttonKeys = <GlobalKey>[];

  @override
  void initState() {
    super.initState();

    timeAnimController.repeat();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      focusButton(0);
    });

    categoryListScrollController.addListener(onCategoryListScroll);

    ref.listenManual(
      tabContentListProvider,
      (previous, next) {
        buttonKeys = next.map((e) => GlobalKey()).toList();
      },
      fireImmediately: true,
    );
  }

  void onCategoryListScroll() {
    final stackContext = stackKey.currentContext!;
    final selectedButton = ref.read(tabProvider);

    final center = buttonKeys[selectedButton]
        .getPaintBounds(stackContext.findRenderObject())!
        .center;

    final offset = center.dx / stackContext.size!.width;
    oldOffset = offset;
    targetOffset = offset;
  }

  void focusButton(int index) {
    final stackContext = stackKey.currentContext!;

    final center = buttonKeys[index]
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
    ref.listen(
      tabProvider,
      (previous, next) {
        focusButton(next);
      },
    );

    return SizedBox(
      height: 340,
      child: Stack(
        key: stackKey,
        fit: StackFit.passthrough,
        children: [
          buildBackground(),
          buildShaderMask(),
          buildContent(),
        ],
      ),
    );
  }

  Consumer buildBackground() {
    return Consumer(builder: (context, ref, child) {
      final content = ref.watch(tabContentProvider);

      return Image.asset(
        content.headerImagePath,
        fit: BoxFit.cover,
        alignment: Alignment.topCenter,
      );
    });
  }

  ShaderBuilder buildShaderMask() {
    return ShaderBuilder(
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
              child: buildMaskedContent(),
            );
          },
        );
      },
      assetKey: 'assets/shaders/wavy.frag',
    );
  }

  Widget buildMaskedContent() {
    return Consumer(builder: (context, ref, child) {
      final s = ref.watch(tabContentProvider);

      return AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        color: Color.lerp(Colors.white, s.color, 0.1),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 32),
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
            SizedBox(height: 110),
          ],
        ),
      );
    });
  }

  Widget buildContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        const SizedBox(
          height: 64,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Consumer(builder: (context, ref, child) {
            final content = ref.watch(tabContentProvider);

            return Text(
              content.headerName,
              style: const TextStyle(
                fontSize: 24,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            );
          }),
        ),
        const SizedBox(
          height: 16,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Consumer(builder: (context, ref, child) {
            final content = ref.watch(tabContentProvider);

            const height = 48.0;
            final border = OutlineInputBorder(
              borderRadius: BorderRadius.circular(height / 2),
              borderSide: BorderSide(
                color: content.color,
                width: 1,
              ),
            );
            return TextField(
              style: const TextStyle(fontSize: 20, color: Colors.white),
              decoration: InputDecoration(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                hintStyle: const TextStyle(color: Colors.white),
                hintText: 'Search',
                filled: true,
                fillColor: Color.lerp(Colors.black, content.color, 0.7)!
                    .withOpacity(0.8),
                suffixIcon: const Icon(Icons.search),
                suffixIconColor: Colors.white,
                constraints: const BoxConstraints.tightFor(height: height),
                errorBorder: border,
                focusedBorder: border,
                enabledBorder: border,
                disabledBorder: border,
                border: border,
              ),
            );
          }),
        ),
        const Spacer(),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          controller: categoryListScrollController,
          child: Consumer(
            builder: (context, ref, child) {
              final currIndex = ref.watch(tabProvider);
              final contents = ref.watch(tabContentListProvider);

              return Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(width: 32),
                  for (final (i, content) in contents.enumerate()) ...[
                    buildButton(buttonKeys[i], i, currIndex, content),
                    if (i < buttonKeys.length - 1) const SizedBox(width: 64),
                  ],
                  const SizedBox(width: 32),
                ],
              );
            },
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget buildButton(
    GlobalKey<State<StatefulWidget>> key,
    int buttonIndex,
    int selectedButtonIndex,
    TabContent content,
  ) {
    return Column(
      children: [
        SizedBox(
          key: key,
          width: buttonSize,
          height: buttonSize,
          child: FilledButton(
            onPressed: () {
              ref.read(tabProvider.notifier).state = buttonIndex;
            },
            statesController: MaterialStatesController({
              if (buttonIndex == selectedButtonIndex) MaterialState.selected,
            }),
            style: ButtonStyle(
              animationDuration: offsetAnimController.duration,
              padding: const MaterialStatePropertyAll(EdgeInsets.zero),
              shape: MaterialStateProperty.resolveWith((states) {
                if (states.contains(MaterialState.selected)) {
                  return const CircleBorder();
                }
                return const CircleBorder(
                  side: BorderSide(color: Colors.black, width: 1),
                );
              }),
              foregroundColor: MaterialStateProperty.resolveWith((states) {
                return Colors.black;
              }),
              backgroundColor: MaterialStateProperty.resolveWith((states) {
                if (states.contains(MaterialState.selected)) {
                  return Colors.white.withOpacity(0.4);
                }
                return Colors.transparent;
              }),
            ),
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Builder(builder: (context) {
                final color = IconTheme.of(context).color;
                return SvgPicture.asset(
                  content.buttonIcon,
                  alignment: Alignment.center,
                  color: color,
                );
              }),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          content.buttonName,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
