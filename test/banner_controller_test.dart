import 'package:admob_nextgen/admob_nextgen.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('isBannerErrorRetryable', () {
    test('does not retry by default', () {
      const networkError =
          AdError(code: BannerAdErrorCode.networkError, message: 'net');
      const noFill = AdError(code: BannerAdErrorCode.noFill, message: 'fill');

      expect(isBannerErrorRetryable(networkError), isFalse);
      expect(isBannerErrorRetryable(noFill), isFalse);
    });

    test('retries network errors when enabled', () {
      const error = AdError(code: BannerAdErrorCode.networkError, message: 'net');
      expect(
        isBannerErrorRetryable(error, retryOnNetworkError: true),
        isTrue,
      );
      expect(
        isBannerErrorRetryable(error, retryOnNetworkError: false),
        isFalse,
      );
    });

    test('retries no fill when enabled', () {
      const error = AdError(code: BannerAdErrorCode.noFill, message: 'fill');
      expect(
        isBannerErrorRetryable(error, retryOnNoFill: true),
        isTrue,
      );
      expect(
        isBannerErrorRetryable(error, retryOnNoFill: false),
        isFalse,
      );
    });

    test('never retries invalid request or internal error', () {
      expect(
        isBannerErrorRetryable(
          const AdError(code: BannerAdErrorCode.invalidRequest, message: 'bad'),
          retryOnNoFill: true,
          retryOnNetworkError: true,
        ),
        isFalse,
      );
      expect(
        isBannerErrorRetryable(
          const AdError(code: BannerAdErrorCode.internalError, message: 'oops'),
          retryOnNoFill: true,
          retryOnNetworkError: true,
        ),
        isFalse,
      );
    });

    test('does not retry unknown error codes', () {
      expect(
        isBannerErrorRetryable(
          const AdError(code: 99, message: 'unknown'),
          retryOnNoFill: true,
          retryOnNetworkError: true,
        ),
        isFalse,
      );
    });
  });

  test('BannerAdController defaults do not auto-retry', () {
    final controller = BannerAdController();
    expect(controller.maxAttempts, 2);
    expect(controller.delay, Duration.zero);
    expect(controller.retryOnNoFill, isFalse);
    expect(controller.retryOnNetworkError, isFalse);
  });
}
