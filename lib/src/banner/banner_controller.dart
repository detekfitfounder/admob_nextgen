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

/// Returns whether [error] should trigger an automatic banner reload.
///
/// Invalid requests and internal errors are never retried — retrying those
/// can waste requests and risks AdMob policy issues.
@visibleForTesting
bool isBannerErrorRetryable(
  AdError error, {
  bool retryOnNoFill = true,
  bool retryOnNetworkError = true,
}) {
  switch (error.code) {
    case BannerAdErrorCode.networkError:
      return retryOnNetworkError;
    case BannerAdErrorCode.noFill:
      return retryOnNoFill;
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
/// final adController = BannerAdController(
///   maxAttempts: 2,
///   retryOnNetworkError: true,
/// );
///
/// BannerAdView(
///   controller: adController,
///   adUnitId: 'ca-app-pub-…/…',
///   listener: BannerAdListener(
///     onAdFailedToLoad: (error) => debugPrint('Banner failed: $error'),
///   ),
/// )
///
/// // Later, force a fresh load:
/// await adController.reload();
/// ```
class BannerAdController {
  BannerAdController({
    this.maxAttempts = 2,
    this.delay = Duration.zero,
    this.retryOnNoFill = true,
    this.retryOnNetworkError = true,
  });

  /// Maximum reload attempts after a load failure before giving up.
  ///
  /// Does not count the initial load.
  final int maxAttempts;

  /// Wait time before each automatic reload after a failure.
  ///
  /// Manual [reload] calls are not delayed.
  final Duration delay;

  /// Whether to reload when the SDK reports no fill ([BannerAdErrorCode.noFill]).
  final bool retryOnNoFill;

  /// Whether to reload on network errors ([BannerAdErrorCode.networkError]).
  final bool retryOnNetworkError;

  MethodChannel? _viewChannel;
  void Function()? _markFailed;
  void Function()? _clearFailed;
  Timer? _retryTimer;
  int _failureReloadCount = 0;
  bool _disposed = false;
  _ActiveReloadSettings? _activeSettings;

  /// Whether this controller is bound to a mounted [BannerAdView] platform view.
  bool get isAttached => _viewChannel != null;

  _ActiveReloadSettings get _settings =>
      _activeSettings ??
      _ActiveReloadSettings(
        maxAttempts: maxAttempts,
        delay: delay,
        retryOnNoFill: retryOnNoFill,
        retryOnNetworkError: retryOnNetworkError,
      );

  /// Requests a new load on the attached banner view.
  ///
  /// Resets the automatic retry counter. Pass any retry field to override the
  /// controller defaults for subsequent automatic retries in this load cycle.
  ///
  /// Does nothing if the controller is not attached or has been [dispose]d.
  Future<void> reload({
    int? maxAttempts,
    Duration? delay,
    bool? retryOnNoFill,
    bool? retryOnNetworkError,
  }) async {
    if (_disposed) return;
    final channel = _viewChannel;
    if (channel == null) return;

    _failureReloadCount = 0;
    _activeSettings = _settings.copyWith(
      maxAttempts: maxAttempts,
      delay: delay,
      retryOnNoFill: retryOnNoFill,
      retryOnNetworkError: retryOnNetworkError,
    );
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
  }

  void _unbindView() {
    _retryTimer?.cancel();
    _markFailed = null;
    _clearFailed = null;
    _viewChannel = null;
    _failureReloadCount = 0;
    _activeSettings = null;
  }

  void _onAdLoaded() {
    _failureReloadCount = 0;
    _retryTimer?.cancel();
    _clearFailed?.call();
  }

  void _onAdFailedToLoad(AdError error) {
    if (_disposed) return;

    final settings = _settings;

    if (!isBannerErrorRetryable(
      error,
      retryOnNoFill: settings.retryOnNoFill,
      retryOnNetworkError: settings.retryOnNetworkError,
    )) {
      _markFailed?.call();
      return;
    }

    if (_failureReloadCount >= settings.maxAttempts) {
      _markFailed?.call();
      return;
    }

    _failureReloadCount++;
    _retryTimer?.cancel();

    if (settings.delay > Duration.zero) {
      _retryTimer = Timer(settings.delay, _invokeReload);
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

class _ActiveReloadSettings {
  const _ActiveReloadSettings({
    required this.maxAttempts,
    required this.delay,
    required this.retryOnNoFill,
    required this.retryOnNetworkError,
  });

  final int maxAttempts;
  final Duration delay;
  final bool retryOnNoFill;
  final bool retryOnNetworkError;

  _ActiveReloadSettings copyWith({
    int? maxAttempts,
    Duration? delay,
    bool? retryOnNoFill,
    bool? retryOnNetworkError,
  }) {
    return _ActiveReloadSettings(
      maxAttempts: maxAttempts ?? this.maxAttempts,
      delay: delay ?? this.delay,
      retryOnNoFill: retryOnNoFill ?? this.retryOnNoFill,
      retryOnNetworkError: retryOnNetworkError ?? this.retryOnNetworkError,
    );
  }
}
