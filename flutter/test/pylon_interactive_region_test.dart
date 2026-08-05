import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pylon_chat/src/pylon_interactive_region.dart';

void main() {
  /// A [Stack] with a tap target behind a [PylonInteractiveRegion] whose child
  /// is another tap target — the arrangement the widget is used in.
  Future<List<String>> tapAt(
    WidgetTester tester,
    Offset point, {
    required List<Rect> regions,
    bool absorbAll = false,
  }) async {
    final List<String> taps = <String>[];
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Stack(
          children: <Widget>[
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => taps.add('app'),
              ),
            ),
            Positioned.fill(
              child: PylonInteractiveRegion(
                regions: regions,
                absorbAll: absorbAll,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => taps.add('widget'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
    await tester.tapAt(point);
    await tester.pump();
    return taps;
  }

  // The default test surface is 800x600.
  const List<Rect> bubble = <Rect>[Rect.fromLTWH(700, 500, 60, 60)];

  testWidgets('a pointer on the bubble goes to the widget', (
    WidgetTester tester,
  ) async {
    expect(
      await tapAt(tester, const Offset(730, 530), regions: bubble),
      <String>['widget'],
    );
  });

  testWidgets('a pointer beside the bubble reaches the app behind', (
    WidgetTester tester,
  ) async {
    expect(
      await tapAt(tester, const Offset(100, 100), regions: bubble),
      <String>['app'],
    );
  });

  testWidgets('with nothing visible every pointer reaches the app', (
    WidgetTester tester,
  ) async {
    expect(
      await tapAt(tester, const Offset(730, 530), regions: const <Rect>[]),
      <String>['app'],
    );
  });

  testWidgets('an open chat window takes every pointer', (
    WidgetTester tester,
  ) async {
    expect(
      await tapAt(
        tester,
        const Offset(100, 100),
        regions: const <Rect>[],
        absorbAll: true,
      ),
      <String>['widget'],
    );
  });

  testWidgets('a pointer on a second element, such as a survey, is taken', (
    WidgetTester tester,
  ) async {
    const List<Rect> withSurvey = <Rect>[
      Rect.fromLTWH(700, 500, 60, 60),
      Rect.fromLTWH(40, 400, 300, 160),
    ];
    expect(
      await tapAt(tester, const Offset(190, 480), regions: withSurvey),
      <String>['widget'],
    );
  });

  testWidgets('regions that change are picked up without a relayout', (
    WidgetTester tester,
  ) async {
    final List<String> taps = <String>[];
    Widget build(List<Rect> regions) {
      return Directionality(
        textDirection: TextDirection.ltr,
        child: Stack(
          children: <Widget>[
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => taps.add('app'),
              ),
            ),
            Positioned.fill(
              child: PylonInteractiveRegion(
                regions: regions,
                absorbAll: false,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => taps.add('widget'),
                ),
              ),
            ),
          ],
        ),
      );
    }

    await tester.pumpWidget(build(const <Rect>[]));
    await tester.tapAt(const Offset(730, 530));
    await tester.pump();
    expect(taps, <String>['app'], reason: 'bubble not shown yet');

    // The bubble appears and the widget reports its bounds.
    await tester.pumpWidget(build(bubble));
    await tester.tapAt(const Offset(730, 530));
    await tester.pump();
    expect(taps, <String>['app', 'widget']);
  });

  test('accepts() is exactly membership of the regions', () {
    final RenderPylonInteractiveRegion render = RenderPylonInteractiveRegion(
      regions: const <Rect>[Rect.fromLTWH(10, 10, 20, 20)],
      absorbAll: false,
    );

    expect(render.accepts(const Offset(20, 20)), isTrue);
    expect(render.accepts(const Offset(10, 10)), isTrue, reason: 'top left');
    expect(render.accepts(const Offset(30, 30)), isFalse, reason: 'exclusive');
    expect(render.accepts(const Offset(9, 20)), isFalse);

    render.absorbAll = true;
    expect(render.accepts(const Offset(9, 20)), isTrue);

    render.absorbAll = false;
    render.regions = const <Rect>[];
    expect(render.accepts(const Offset(20, 20)), isFalse);
  });
}
