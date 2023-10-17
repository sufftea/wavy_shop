import 'package:flutter/material.dart';

extension GlobalKeyExtension on GlobalKey {
  Rect? get globalPaintBounds {
    return getPaintBounds(null);
  }

  Rect? getPaintBounds(RenderObject? parent) {
    final renderObject = currentContext?.findRenderObject();
    final translation = renderObject?.getTransformTo(parent).getTranslation();
    if (translation != null && renderObject?.paintBounds != null) {
      final offset = Offset(translation.x, translation.y);
      return renderObject!.paintBounds.shift(offset);
    } else {
      return null;
    }
  }
}

extension ListX<T> on List<T> {
  List<(int, T)> enumerate() {
    int i = 0;
    return map((e) => (i++, e)).toList();
  }
}
