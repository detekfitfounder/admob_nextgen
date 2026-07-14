import 'package:admob_nextgen/admob_nextgen.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('CollapsiblePlacement wire values match Google extras', () {
    expect(CollapsiblePlacement.top.wireValue, 'top');
    expect(CollapsiblePlacement.bottom.wireValue, 'bottom');
  });

  test('AdSize.collapsible requires placement and maps to collapsible type', () {
    const size = AdSize.collapsible(
      placement: CollapsiblePlacement.bottom,
    );

    expect(size.type, 'collapsible');
    expect(size.collapsiblePlacement, CollapsiblePlacement.bottom);
    expect(size.collapsiblePlacement!.wireValue, 'bottom');
    expect(size.widthDp, 360);
    expect(AdSize.collapsibleRecommendedMinHeightDp, 100);
  });

  test('AdSize.collapsible supports custom width and top placement', () {
    const size = AdSize.collapsible(
      placement: CollapsiblePlacement.top,
      width: 320,
    );

    expect(size.collapsiblePlacement, CollapsiblePlacement.top);
    expect(size.widthDp, 320);
  });

  test('non-collapsible AdSize has null collapsiblePlacement', () {
    expect(const AdSize.anchored().collapsiblePlacement, isNull);
    expect(const AdSize.banner().collapsiblePlacement, isNull);
  });

  test('AdSize.collapsible throws for suggestedHeightDp', () {
    expect(
      () => const AdSize.collapsible(
        placement: CollapsiblePlacement.bottom,
      ).suggestedHeightDp,
      throwsA(isA<StateError>()),
    );
  });

  test('BannerAdListener accepts onIsCollapsible', () {
    var reported = false;
    final listener = BannerAdListener(
      onAdLoaded: () {},
      onIsCollapsible: (isCollapsible) => reported = isCollapsible,
    );

    listener.onIsCollapsible?.call(true);
    expect(reported, isTrue);
  });
}
