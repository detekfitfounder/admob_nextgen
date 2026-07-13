import 'package:admob_nextgen/admob_nextgen.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('isBannerErrorRetryable', () {
    test('retries network errors when enabled', () {
      const error = AdError(code: BannerAdErrorCode.networkError, message: 'net');
      expect(isBannerErrorRetryable(error), isTrue);
      expect(
        isBannerErrorRetryable(error, retryOnNetworkError: false),
        isFalse,
      );
    });

    test('retries no fill when enabled', () {
      const error = AdError(code: BannerAdErrorCode.noFill, message: 'fill');
      expect(isBannerErrorRetryable(error), isTrue);
      expect(
        isBannerErrorRetryable(error, retryOnNoFill: false),
        isFalse,
      );
    });

    test('never retries invalid request or internal error', () {
      expect(
        isBannerErrorRetryable(
          const AdError(code: BannerAdErrorCode.invalidRequest, message: 'bad'),
        ),
        isFalse,
      );
      expect(
        isBannerErrorRetryable(
          const AdError(code: BannerAdErrorCode.internalError, message: 'oops'),
        ),
        isFalse,
      );
    });

    test('does not retry unknown error codes', () {
      expect(
        isBannerErrorRetryable(
          const AdError(code: 99, message: 'unknown'),
        ),
        isFalse,
      );
    });
  });

  test('BannerAdController defaults match safe AdMob policy', () {
    final controller = BannerAdController();
    expect(controller.maxAttempts, 2);
    expect(controller.delay, Duration.zero);
    expect(controller.retryOnNoFill, isTrue);
    expect(controller.retryOnNetworkError, isTrue);
  });
}
