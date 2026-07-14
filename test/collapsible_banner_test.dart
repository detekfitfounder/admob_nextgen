import 'package:admob_nextgen/admob_nextgen.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('AdRequest.extras includes collapsible in toMap', () {
    const request = AdRequest(
      extras: {'collapsible': 'bottom'},
    );

    expect(request.extras, {'collapsible': 'bottom'});
    expect(request.toMap()['extras'], {'collapsible': 'bottom'});
  });

  test('AdRequest.extras supports top placement', () {
    const request = AdRequest(
      extras: {'collapsible': 'top'},
    );

    expect(request.toMap()['extras'], {'collapsible': 'top'});
  });

  test('AdRequest omits extras from toMap when empty', () {
    const request = AdRequest();

    expect(request.extras, isEmpty);
    expect(request.toMap().containsKey('extras'), isFalse);
  });

  test('BannerAdView passes request extras for collapsible', () {
    const view = BannerAdView(
      adUnitId: 'ca-app-pub-test/banner',
      size: AdSize.anchored(),
      height: 100,
      request: AdRequest(extras: {'collapsible': 'bottom'}),
    );

    expect(view.request?.extras['collapsible'], 'bottom');
    expect(view.size.type, 'anchored');
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
