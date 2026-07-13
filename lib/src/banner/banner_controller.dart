part of 'banner_ad.dart';

/// GMA Next-Gen SDK load error codes relevant to banner reload decisions.
abstract final class BannerAdErrorCode {
  /// Internal SDK error — not retried by default (policy violation risk).
  static const int internalError = 0;

  /// Invalid ad unit / request configuration — never retried.
  static const int invalidRequest = 1;

  /// Transient network failure.
  static const int networkError = 2;

  /// No ad inventory (no fill).
  static const int noFill = 3;
}

/// Optional retry tuning for [BannerAdController.reload] and automatic
/// reload-on-failure when a controller is attached to [BannerAdView].
///
/// Defaults are conservative for AdMob policy: at most two reload attempts,
/// no artificial delay, and retries only for no-fill and network errors.
class BannerReloadOptions {
  const BannerReloadOptions({
    this.maxAttempts = 2,
    this.delay = Duration.zero,
    this.retryOnNoFill = true,
    this.retryOnNetworkError = true,
  });

  /// Maximum number of reload attempts after a load failure before giving up.
  ///
  /// Does not count the initial load — only [BannerAdController.reload] calls
  /// triggered by failures (automatic or manual).
  final int maxAttempts;

  /// Wait time before each automatic reload after a failure.
  ///
  /// Manual [BannerAdController.reload] calls are not delayed.
  final Duration delay;

  /// Whether to reload when the SDK reports no fill ([BannerAdErrorCode.noFill]).
  final bool retryOnNoFill;

  /// Whether to reload on network errors ([BannerAdErrorCode.networkError]).
  final bool retryOnNetworkError;
}

/// Returns whether [error] should trigger an automatic banner reload under
/// [options].
///
/// Invalid requests and internal errors are never retried — retrying those
/// can waste requests and risks AdMob policy issues.
@visibleForTesting
bool isBannerErrorRetryable(AdError error, BannerReloadOptions options) {
  switch (error.code) {
    case BannerAdErrorCode.networkError:
      return options.retryOnNetworkError;
    case BannerAdErrorCode.noFill:
      return options.retryOnNoFill;
    case BannerAdErrorCode.invalidRequest:
    case BannerAdErrorCode.internalError:
      return false;
    default:
      return false;
  }
}

/// Controls an attached [BannerAdView], including native reload and optional
/// automatic retry when a load fails.
///
/// Create one controller per banner placement, pass it to [BannerAdView], and
/// call [dispose] when the placement is removed.
///
/// ```dart
/// final bannerController = BannerAdController();
///
/// BannerAdView(
///   controller: bannerController,
///   adUnitId: 'ca-app-pub-…/…',
///   listener: BannerAdListener(
///     onAdFailedToLoad: (error) => debugPrint('Banner failed: $error'),
///   ),
/// )
///
/// // Later, force a fresh load:
/// await bannerController.reload();
/// ```
class BannerAdController {
  BannerAdController({this.reloadOptions = const BannerReloadOptions()});

  /// Default retry settings for automatic reload-on-failure.
  final BannerReloadOptions reloadOptions;

  MethodChannel? _viewChannel;
  void Function()? _markFailed;
  void Function()? _clearFailed;
  Timer? _retryTimer;
  int _failureReloadCount = 0;
  bool _disposed = false;
  BannerReloadOptions? _activeOptions;

  /// Whether this controller is bound to a mounted [BannerAdView] platform view.
  bool get isAttached => _viewChannel != null;

  /// Requests a new load on the attached banner view.
  ///
  /// Resets the automatic retry counter. Pass [options] to override the
  /// controller defaults for subsequent automatic retries in this load cycle.
  ///
  /// Does nothing if the controller is not attached or has been [dispose]d.
  Future<void> reload({BannerReloadOptions? options}) async {
    if (_disposed) return;
    final channel = _viewChannel;
    if (channel == null) return;

    _failureReloadCount = 0;
    _activeOptions = options ?? reloadOptions;
    _retryTimer?.cancel();
    _clearFailed?.call();

    try {
      await channel.invokeMethod<void>('reload');
    } on PlatformException catch (e, st) {
      debugPrint('[admob_nextgen] BannerAdController.reload failed: $e\n$st');
      _markFailed?.call();
    }
  }

  /// Cancels pending retries. Call when the banner placement is removed.
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _retryTimer?.cancel();
    _unbindView();
  }

  void _bindView({
    required MethodChannel channel,
    required void Function() markFailed,
    required void Function() clearFailed,
  }) {
    _viewChannel = channel;
    _markFailed = markFailed;
    _clearFailed = clearFailed;
    _activeOptions ??= reloadOptions;
  }

  void _unbindView() {
    _retryTimer?.cancel();
    _markFailed = null;
    _clearFailed = null;
    _viewChannel = null;
    _failureReloadCount = 0;
    _activeOptions = null;
  }

  void _onAdLoaded() {
    _failureReloadCount = 0;
    _retryTimer?.cancel();
    _clearFailed?.call();
  }

  void _onAdFailedToLoad(AdError error) {
    if (_disposed) return;

    final options = _activeOptions ?? reloadOptions;

    if (!isBannerErrorRetryable(error, options)) {
      _markFailed?.call();
      return;
    }

    if (_failureReloadCount >= options.maxAttempts) {
      _markFailed?.call();
      return;
    }

    _failureReloadCount++;
    _retryTimer?.cancel();

    if (options.delay > Duration.zero) {
      _retryTimer = Timer(options.delay, _invokeReload);
    } else {
      _invokeReload();
    }
  }

  Future<void> _invokeReload() async {
    if (_disposed) return;
    final channel = _viewChannel;
    if (channel == null) return;

    try {
      await channel.invokeMethod<void>('reload');
    } on PlatformException catch (e, st) {
      debugPrint('[admob_nextgen] Banner auto-reload failed: $e\n$st');
      _markFailed?.call();
    }
  }
}
