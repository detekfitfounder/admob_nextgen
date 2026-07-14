import 'package:admob_nextgen/admob_nextgen.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('detached BannerAdController ignores manual reload', () async {
    final controller = BannerAdController();

    expect(controller.isAttached, isFalse);
    await controller.reload();
    controller.dispose();
  });
}
