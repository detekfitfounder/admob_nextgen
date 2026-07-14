import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/ad_error.dart';
import '../core/ad_request.dart';
import 'ad_size.dart';
import 'collapsible_placement.dart';

part 'banner_controller.dart';

/// Lifecycle callbacks fired by a [BannerAdView].
class BannerAdListener {
  const BannerAdListener({
    this.onAdLoaded,
    this.onIsCollapsible,
    this.onAdFailedToLoad,
    this.onAdImpression,
    this.onAdClicked,
    this.onAdShowedFullScreenContent,
    this.onAdDismissedFullScreenContent,
    this.onAdFailedToShowFullScreenContent,
    this.onAdRefreshed,
    this.onAdFailedToRefresh,
  });

  final VoidCallback? onAdLoaded;

  /// Whether the loaded creative is a collapsible banner.
  ///
  /// Fires after [onAdLoaded]. Collapsible requests may still receive a
  /// normal banner; use this to record what the SDK actually returned.
  final void Function(bool isCollapsible)? onIsCollapsible;

  final void Function(AdError error)? onAdFailedToLoad;
  final VoidCallback? onAdImpression;
  final VoidCallback? onAdClicked;
  final VoidCallback? onAdShowedFullScreenContent;
  final VoidCallback? onAdDismissedFullScreenContent;
  final void Function(AdError error)? onAdFailedToShowFullScreenContent;

  /// Fires each time the SDK rotates to a new ad creative.
  ///
  /// Auto-refresh is controlled via the **AdMob console** for the ad unit
  /// (not from this plugin). When enabled, the SDK swaps in a new ad while
  /// the banner is visible and invokes this callback for each refresh.
  ///
  /// After a collapsible load, AdMob auto-refresh serves non-collapsible ads
  /// for subsequent refreshes. Call [BannerAdController.reload] to request
  /// collapsible again.
  final VoidCallback? onAdRefreshed;

  /// Fires when an auto-refresh attempt fails (e.g. no fill).
  final void Function(AdError error)? onAdFailedToRefresh;
}

/// Widget that hosts a GMA Next-Gen banner ad inside the Flutter view tree.
///
/// **Sizing.** [BannerAdView] expects to be given an explicit size by its
/// parent (Flutter PlatformViews need bounded constraints to be created).
/// Wrap it in a `SizedBox`, place it inside a `Column` with a `SizedBox`
/// sibling, or pass an explicit [height] — otherwise the ad will silently
/// fail to render. Suggested heights: 50–100 dp for [AdSize.anchored],
/// 100–130 dp for [AdSize.largeAnchored], at least
/// [AdSize.collapsibleRecommendedMinHeightDp] (100) for [AdSize.collapsible].
/// For fixed IAB sizes use [AdSize.suggestedHeightDp].
///
/// **Initialization.** `MobileAds.initialize()` must complete before this
/// widget mounts.
///
/// **Cross-platform.** On non-Android platforms the widget collapses to
/// [SizedBox.shrink] (or the supplied [placeholder]).
///
/// ```dart
/// BannerAdView(
///   adUnitId: 'ca-app-pub-…/…',
///   size: const AdSize.collapsible(
///     placement: CollapsiblePlacement.bottom,
///   ),
///   height: AdSize.collapsibleRecommendedMinHeightDp,
/// )
/// ```
class BannerAdView extends StatefulWidget {
  const BannerAdView({
    super.key,
    required this.adUnitId,
    this.size = const AdSize.anchored(),
    this.controller,
    this.listener,
    this.placeholder,
    this.height,
    this.request,
  });

  /// AdMob ad unit ID. For testing use
  /// `ca-app-pub-3940256099942544/9214589741`.
  final String adUnitId;

  /// Logical size hint passed to the native banner.
  ///
  /// Use [AdSize.collapsible] to request a collapsible overlay on an anchored
  /// adaptive slot.
  final AdSize size;

  /// Optional controller for [reload] and automatic retry on load failure.
  ///
  /// When set, the banner stays mounted while retries are in progress instead
  /// of collapsing to [placeholder] immediately.
  final BannerAdController? controller;

  /// Optional callbacks for ad lifecycle events.
  final BannerAdListener? listener;

  /// Optional widget shown on non-Android platforms, or after the ad fails
  /// to load. Pass nothing to collapse the space entirely in those cases.
  ///
  /// When [height] is set, the placeholder is constrained to the same height
  /// as the banner ad view.
  final Widget? placeholder;

  /// Convenience shortcut for the common case of "wrap me in a SizedBox of
  /// this height". If omitted, [BannerAdView] uses whatever size its parent
  /// supplies via [Container] / [SizedBox] / [Expanded] etc.
  ///
  /// For [AdSize.collapsible], keep this at the **collapsed** size — at least
  /// [AdSize.collapsibleRecommendedMinHeightDp]. Expansion is an SDK overlay
  /// and does not resize the Flutter layout. Values like `60` often clip the
  /// adaptive collapsed bar.
  final double? height;

  /// Optional targeting hints for this banner request.
  final AdRequest? request;

  @override
  State<BannerAdView> createState() => _BannerAdViewState();
}

class _BannerAdViewState extends State<BannerAdView> {
  MethodChannel? _viewChannel;
  bool _adFailed = false;

  void _onPlatformViewCreated(int id) {
    final channel = MethodChannel('next_gen_sdk/banner_ad_$id');
    _viewChannel = channel;
    channel.setMethodCallHandler(_handleEvent);
    widget.controller?._bindView(
      channel: channel,
      markFailed: _markFailed,
      clearFailed: _clearFailed,
    );
  }

  void _markFailed() {
    if (mounted) setState(() => _adFailed = true);
  }

  void _clearFailed() {
    if (mounted) setState(() => _adFailed = false);
  }

  @override
  void didUpdateWidget(covariant BannerAdView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller?._unbindView();
      if (_viewChannel != null) {
        widget.controller?._bindView(
          channel: _viewChannel!,
          markFailed: _markFailed,
          clearFailed: _clearFailed,
        );
      }
    }
    final adUnitChanged = oldWidget.adUnitId != widget.adUnitId;
    final sizeChanged =
        oldWidget.size.widthDp != widget.size.widthDp ||
        oldWidget.size.type != widget.size.type ||
        oldWidget.size.maxHeightDp != widget.size.maxHeightDp ||
        oldWidget.size.collapsiblePlacement !=
            widget.size.collapsiblePlacement;
    final requestChanged = !mapEquals(
      oldWidget.request?.toMap(),
      widget.request?.toMap(),
    );
    if (adUnitChanged || sizeChanged || requestChanged) {
      debugPrint(
        '[flutter_next_gen_ads] BannerAdView props changed but the '
        'PlatformView is reused. Pass a `key: ValueKey(adUnitId)` from the '
        'parent to force recreation.',
      );
    }
  }

  Future<dynamic> _handleEvent(MethodCall call) async {
    final args = call.arguments;
    final map = (args is Map) ? args : const {};
    switch (call.method) {
      case 'onAdLoaded':
        widget.controller?._onAdLoaded();
        widget.listener?.onAdLoaded?.call();
        final isCollapsible = map['isCollapsible'];
        if (isCollapsible is bool) {
          widget.listener?.onIsCollapsible?.call(isCollapsible);
        }
        break;
      case 'onAdFailedToLoad':
        final error = AdError.fromMap(map);
        widget.listener?.onAdFailedToLoad?.call(error);
        if (widget.controller != null) {
          widget.controller!._onAdFailedToLoad(error);
        } else if (mounted) {
          setState(() => _adFailed = true);
        }
        break;
      case 'onAdImpression':
        widget.listener?.onAdImpression?.call();
        break;
      case 'onAdClicked':
        widget.listener?.onAdClicked?.call();
        break;
      case 'onAdShowedFullScreenContent':
        widget.listener?.onAdShowedFullScreenContent?.call();
        break;
      case 'onAdDismissedFullScreenContent':
        widget.listener?.onAdDismissedFullScreenContent?.call();
        break;
      case 'onAdFailedToShowFullScreenContent':
        widget.listener?.onAdFailedToShowFullScreenContent?.call(
          AdError.fromMap(map),
        );
        break;
      case 'onAdRefreshed':
        widget.listener?.onAdRefreshed?.call();
        break;
      case 'onAdFailedToRefresh':
        widget.listener?.onAdFailedToRefresh?.call(AdError.fromMap(map));
        break;
    }
  }

  @override
  void dispose() {
    widget.controller?._unbindView();
    _viewChannel?.setMethodCallHandler(null);
    _viewChannel = null;
    super.dispose();
  }

  Widget _constrainHeight(Widget child) {
    final height = widget.height;
    if (height != null) {
      return SizedBox(height: height, child: child);
    }
    return child;
  }

  @override
  Widget build(BuildContext context) {
    if (kIsWeb || !Platform.isAndroid) {
      return _constrainHeight(widget.placeholder ?? const SizedBox.shrink());
    }

    if (_adFailed) {
      return _constrainHeight(widget.placeholder ?? const SizedBox.shrink());
    }

    final params = <String, dynamic>{
      'adUnitId': widget.adUnitId,
      'widthDp': widget.size.widthDp,
      'sizeType': widget.size.type,
      if (widget.size.maxHeightDp != null)
        'maxHeightDp': widget.size.maxHeightDp,
      if (widget.request != null) 'request': widget.request!.toMap(),
      if (widget.size.collapsiblePlacement != null)
        'collapsible': widget.size.collapsiblePlacement!.wireValue,
    };

    final adView = AndroidView(
      viewType: 'next_gen_sdk/banner_ad',
      onPlatformViewCreated: _onPlatformViewCreated,
      creationParams: params,
      creationParamsCodec: const StandardMessageCodec(),
    );

    return _constrainHeight(adView);
  }
}
