import 'package:flutter/material.dart';
import 'package:riverpod/riverpod.dart';

final tabProvider = StateProvider<int>(
  (ref) => 0,
);

final tabContentListProvider = Provider<List<TabContent>>((ref) {
  return tabContents;
});

final tabContentProvider = Provider<TabContent>((ref) {
  final index = ref.watch(tabProvider);
  final contents = ref.watch(tabContentListProvider);
  return contents[index];
});

class TabContent {
  const TabContent({
    required this.headerImagePath,
    required this.headerName,
    required this.bannerTitle,
    required this.bannerImagePath,
    required this.buttonName,
    required this.buttonIcon,
    required this.color,
  });

  final String headerImagePath;
  final String headerName;
  final String bannerTitle;
  final String bannerImagePath;
  final String buttonName;
  final String buttonIcon;
  final Color color;
}

final tabContents = <TabContent>[
  TabContent(
    headerImagePath: 'assets/images/night_sky_header.jpeg',
    headerName: 'PILLOW CUSHION',
    bannerTitle: 'Read our story',
    bannerImagePath: 'night_sky_banner.png',
    buttonName: 'Pillow',
    buttonIcon: 'assets/icons/star_icon.svg',
    color: Colors.blue.shade800,
  ),
  TabContent(
    headerImagePath: 'assets/images/unicorns_header.jpeg',
    headerName: 'BABY COLLECTION',
    bannerTitle: 'Special film BT21 baby collection',
    bannerImagePath: 'unicorns_banner.png',
    buttonName: 'Baby',
    buttonIcon: 'assets/icons/dog_icon.svg',
    color: Colors.pink.shade200,
  ),
  const TabContent(
    headerImagePath: 'assets/images/forest_header.jpeg',
    headerName: 'PILLOW CUSHION',
    bannerTitle: 'Read our story',
    bannerImagePath: 'night_sky_banner.png',
    buttonName: 'Flat fur',
    buttonIcon: 'assets/icons/ghost_icon.svg',
    color: Colors.lightGreen,
  ),
  const TabContent(
    headerImagePath: 'assets/images/sunflowers_header.jpeg',
    headerName: 'BABY COLLECTION',
    bannerTitle: 'Special film BT21 baby collection',
    bannerImagePath: 'unicorns_banner.png',
    buttonName: 'Flat fur',
    buttonIcon: 'assets/icons/ship_icon.svg',
    color: Colors.yellowAccent,
  ),
];
