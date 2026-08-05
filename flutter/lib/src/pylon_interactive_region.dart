import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

/// Restricts hit testing of [child] to a set of rectangles.
///
/// The chat widget is a full-screen overlay that is mostly empty — only the
/// bubble, and any popup survey or message, are actually there. Pointers that
/// land outside those must reach the app underneath, so this widget reports a
/// miss for everything else and lets the hit test continue to the widgets
/// behind it in the [Stack].
///
/// While the chat window is open the widget owns the whole screen, which
/// [absorbAll] expresses.
class PylonInteractiveRegion extends SingleChildRenderObjectWidget {
  /// Creates a region that only accepts pointers inside [regions].
  const PylonInteractiveRegion({
    super.key,
    required this.regions,
    required this.absorbAll,
    required Widget super.child,
  });

  /// The rectangles that accept pointers, in this widget's local coordinates.
  final List<Rect> regions;

  /// When true, every pointer inside this widget is accepted and [regions] is
  /// ignored.
  final bool absorbAll;

  @override
  RenderPylonInteractiveRegion createRenderObject(BuildContext context) {
    return RenderPylonInteractiveRegion(regions: regions, absorbAll: absorbAll);
  }

  @override
  void updateRenderObject(
    BuildContext context,
    RenderPylonInteractiveRegion renderObject,
  ) {
    renderObject
      ..regions = regions
      ..absorbAll = absorbAll;
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(IterableProperty<Rect>('regions', regions));
    properties.add(FlagProperty('absorbAll', value: absorbAll, ifTrue: 'all'));
  }
}

/// The render object behind [PylonInteractiveRegion].
class RenderPylonInteractiveRegion extends RenderProxyBox {
  /// Creates a render object that only accepts pointers inside [regions].
  RenderPylonInteractiveRegion({
    required List<Rect> regions,
    required bool absorbAll,
  }) : _regions = regions,
       _absorbAll = absorbAll;

  /// The rectangles that accept pointers, in local coordinates.
  List<Rect> get regions => _regions;
  List<Rect> _regions;
  set regions(List<Rect> value) {
    if (listEquals(_regions, value)) return;
    _regions = value;
    // Hit testing reads this live, so nothing needs to be laid out or painted.
  }

  /// Whether every pointer inside this render object is accepted.
  bool get absorbAll => _absorbAll;
  bool _absorbAll;
  set absorbAll(bool value) {
    if (_absorbAll == value) return;
    _absorbAll = value;
  }

  @override
  bool hitTest(BoxHitTestResult result, {required Offset position}) {
    if (!accepts(position)) return false;
    return super.hitTest(result, position: position);
  }

  /// Whether a pointer at [position] (in local coordinates) is ours to handle.
  @visibleForTesting
  bool accepts(Offset position) {
    if (_absorbAll) return true;
    for (final Rect region in _regions) {
      if (region.contains(position)) return true;
    }
    return false;
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(IterableProperty<Rect>('regions', regions));
    properties.add(FlagProperty('absorbAll', value: absorbAll, ifTrue: 'all'));
  }
}
