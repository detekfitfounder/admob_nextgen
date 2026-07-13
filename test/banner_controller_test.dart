import 'package:admob_nextgen/admob_nextgen.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const defaults = BannerReloadOptions();

  group('isBannerErrorRetryable', () {
    test('retries network errors when enabled', () {
      const error = AdError(code: BannerAdErrorCode.networkError, message: 'net');
      expect(isBannerErrorRetryable(error, defaults), isTrue);
      expect(
        isBannerErrorRetryable(
          error,
          const BannerReloadOptions(retryOnNetworkError: false),
        ),
        isFalse,
      );
    });

    test('retries no fill when enabled', () {
      const error = AdError(code: BannerAdErrorCode.noFill, message: 'fill');
      expect(isBannerErrorRetryable(error, defaults), isTrue);
      expect(
        isBannerErrorRetryable(
          error,
          const BannerReloadOptions(retryOnNoFill: false),
        ),
        isFalse,
      );
    });

    test('never retries invalid request or internal error', () {
      expect(
        isBannerErrorRetryable(
          const AdError(code: BannerAdErrorCode.invalidRequest, message: 'bad'),
          defaults,
        ),
        isFalse,
      );
      expect(
        isBannerErrorRetryable(
          const AdError(code: BannerAdErrorCode.internalError, message: 'oops'),
          defaults,
        ),
        isFalse,
      );
    });

    test('does not retry unknown error codes', () {
      expect(
        isBannerErrorRetryable(
          const AdError(code: 99, message: 'unknown'),
          defaults,
        ),
        isFalse,
      );
    });
  });

  test('BannerReloadOptions defaults match safe AdMob policy', () {
    expect(defaults.maxAttempts, 2);
    expect(defaults.delay, Duration.zero);
    expect(defaults.retryOnNoFill, isTrue);
    expect(defaults.retryOnNetworkError, isTrue);
  });
}
