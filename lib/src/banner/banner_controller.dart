part of 'banner_ad.dart';

/// Controls manual reloads for an attached [BannerAdView].
///
/// Create one controller per banner placement, pass it to [BannerAdView], and
/// call [dispose] when the placement is removed.
///
/// ```dart
/// final adController = BannerAdController();
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
  BannerAdController();

  MethodChannel? _viewChannel;
  void Function()? _markFailed;
  void Function()? _clearFailed;
  bool _disposed = false;

  /// Whether this controller is bound to a mounted [BannerAdView] platform view.
  bool get isAttached => _viewChannel != null;

  /// Requests a new load on the attached banner view.
  ///
  /// Does nothing if the controller is not attached or has been [dispose]d.
  Future<void> reload() async {
    if (_disposed) return;
    final channel = _viewChannel;
    if (channel == null) return;

    _clearFailed?.call();

    try {
      await channel.invokeMethod<void>('reload');
    } on PlatformException catch (e, st) {
      debugPrint('[admob_nextgen] BannerAdController.reload failed: $e\n$st');
      _markFailed?.call();
    }
  }

  /// Detaches this controller from its banner placement.
  void dispose() {
    if (_disposed) return;
    _disposed = true;
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
    _markFailed = null;
    _clearFailed = null;
    _viewChannel = null;
  }

  void _onAdLoaded() {
    _clearFailed?.call();
  }
}
