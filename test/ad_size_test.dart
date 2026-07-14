import 'package:admob_nextgen/admob_nextgen.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('IAB fixed sizes match AdMob standard dimensions', () {
    expect(const AdSize.banner().widthDp, 320);
    expect(const AdSize.banner().suggestedHeightDp, 50.0);

    expect(const AdSize.largeBanner().widthDp, 320);
    expect(const AdSize.largeBanner().suggestedHeightDp, 100.0);

    expect(const AdSize.mediumRectangle().widthDp, 300);
    expect(const AdSize.mediumRectangle().suggestedHeightDp, 250.0);

    expect(const AdSize.fullBanner().widthDp, 468);
    expect(const AdSize.fullBanner().suggestedHeightDp, 60.0);

    expect(const AdSize.leaderboard().widthDp, 728);
    expect(const AdSize.leaderboard().suggestedHeightDp, 90.0);
  });

  test('AdSize.fixed uses custom dimensions', () {
    const size = AdSize.fixed(width: 320, height: 200);
    expect(size.widthDp, 320);
    expect(size.suggestedHeightDp, 200.0);
    expect(size.type, 'fixed');
  });

  test('adaptive sizes throw for suggestedHeightDp', () {
    expect(
      () => const AdSize.anchored().suggestedHeightDp,
      throwsA(isA<StateError>()),
    );
    expect(
      () => const AdSize.largeAnchored().suggestedHeightDp,
      throwsA(isA<StateError>()),
    );
    expect(
      () => const AdSize.inline().suggestedHeightDp,
      throwsA(isA<StateError>()),
    );
    expect(
      () => const AdSize.collapsible(
        placement: CollapsiblePlacement.bottom,
      ).suggestedHeightDp,
      throwsA(isA<StateError>()),
    );
  });
}
