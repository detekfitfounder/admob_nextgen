import 'collapsible_placement.dart';

/// Logical banner size sent across the platform channel.
///
/// **Adaptive** (recommended for phones — SDK picks height from demand):
///
/// * [AdSize.anchored] — bottom/top bar
/// * [AdSize.largeAnchored] — taller bottom/top bar
/// * [AdSize.inline] — inside scrollable content
/// * [AdSize.collapsible] — anchored adaptive + collapsible overlay request
///
/// **Fixed IAB standard sizes** (exact dp dimensions):
///
/// * [AdSize.banner] — 320×50
/// * [AdSize.largeBanner] — 320×100
/// * [AdSize.mediumRectangle] — 300×250 (MREC)
/// * [AdSize.fullBanner] — 468×60 (tablets)
/// * [AdSize.leaderboard] — 728×90 (tablets)
///
/// **Custom fixed** (non-standard — may reduce fill rate):
///
/// * [AdSize.fixed] — arbitrary width×height
class AdSize {
  const AdSize._({
    required this.widthDp,
    required this.type,
    this.maxHeightDp,
    this.collapsiblePlacement,
  });

  /// Width in density-independent pixels.
  final int widthDp;

  /// Internal wire-name routed to the native [AdSize] factory.
  final String type;

  /// Fixed height for IAB / [fixed] sizes, or max height for [inline]. Null for
  /// adaptive anchored sizes.
  final int? maxHeightDp;

  /// Set only for [AdSize.collapsible] — Google extras `top` / `bottom`.
  final CollapsiblePlacement? collapsiblePlacement;

  /// Recommended minimum [BannerAdView.height] for [AdSize.collapsible].
  ///
  /// Collapsible uses anchored adaptive sizing; AdMob picks the collapsed
  /// creative height. A Flutter slot below this value (e.g. `60`) often clips
  /// the collapsed bar. Expansion is an SDK overlay and is not controlled by
  /// this height.
  static const double collapsibleRecommendedMinHeightDp = 100;

  static const _fixedSizeTypes = <String>{
    'banner',
    'largeBanner',
    'mediumRectangle',
    'fullBanner',
    'leaderboard',
    'fixed',
  };

  /// Suggested [BannerAdView.height] for fixed-size banners.
  ///
  /// Only available for [banner], [largeBanner], [mediumRectangle],
  /// [fullBanner], [leaderboard], and [fixed]. Throws [StateError] for
  /// adaptive sizes ([anchored], [largeAnchored], [inline], [collapsible])
  /// where the SDK chooses height at runtime — for collapsible use
  /// [collapsibleRecommendedMinHeightDp].
  double get suggestedHeightDp {
    if (!_fixedSizeTypes.contains(type)) {
      throw StateError(
        'AdSize.suggestedHeightDp is only available for fixed banner sizes '
        '(banner, largeBanner, mediumRectangle, fullBanner, leaderboard, fixed). '
        'Got "$type". For adaptive/collapsible banners, set BannerAdView.height '
        'manually (use AdSize.collapsibleRecommendedMinHeightDp for collapsible).',
      );
    }
    final height = maxHeightDp;
    if (height == null || height <= 0) {
      throw StateError(
        'AdSize.suggestedHeightDp requires a positive height for type "$type".',
      );
    }
    return height.toDouble();
  }

  /// Anchored adaptive banner: SDK picks an appropriate height for [width].
  /// This is the recommended default for most placements.
  const AdSize.anchored({int width = 360})
    : this._(widthDp: width, type: 'anchored');

  /// Larger anchored adaptive banner — taller than [AdSize.anchored].
  const AdSize.largeAnchored({int width = 360})
    : this._(widthDp: width, type: 'largeAnchored');

  /// Inline adaptive banner — height is chosen up to [maxHeight] (or unbounded
  /// when 0).
  const AdSize.inline({int width = 360, int maxHeight = 0})
    : this._(widthDp: width, type: 'inline', maxHeightDp: maxHeight);

  /// Anchored adaptive banner that also requests a collapsible overlay.
  ///
  /// [placement] is required and maps to Google extras (`"top"` / `"bottom"`).
  /// Use for top/bottom screen slots only. Keep [BannerAdView.height] at the
  /// **collapsed** size — at least [collapsibleRecommendedMinHeightDp] (100).
  ///
  /// Requesting collapsible does not guarantee a collapsible creative; check
  /// [BannerAdListener.onIsCollapsible].
  ///
  /// ```dart
  /// BannerAdView(
  ///   adUnitId: '…',
  ///   size: const AdSize.collapsible(
  ///     placement: CollapsiblePlacement.bottom,
  ///   ),
  ///   height: AdSize.collapsibleRecommendedMinHeightDp,
  /// )
  /// ```
  const AdSize.collapsible({
    required CollapsiblePlacement placement,
    int width = 360,
  }) : this._(
         widthDp: width,
         type: 'collapsible',
         collapsiblePlacement: placement,
       );

  /// Standard IAB banner — 320×50 dp.
  const AdSize.banner()
    : this._(widthDp: 320, type: 'banner', maxHeightDp: 50);

  /// Standard IAB large banner — 320×100 dp.
  const AdSize.largeBanner()
    : this._(widthDp: 320, type: 'largeBanner', maxHeightDp: 100);

  /// Standard IAB medium rectangle (MREC) — 300×250 dp.
  ///
  /// Best for in-content placements with a reserved 300×250 slot. Set
  /// [BannerAdView.height] to `250` (or use [suggestedHeightDp]).
  const AdSize.mediumRectangle()
    : this._(widthDp: 300, type: 'mediumRectangle', maxHeightDp: 250);

  /// Standard IAB full-size banner — 468×60 dp (tablets).
  const AdSize.fullBanner()
    : this._(widthDp: 468, type: 'fullBanner', maxHeightDp: 60);

  /// Standard IAB leaderboard — 728×90 dp (tablets).
  const AdSize.leaderboard()
    : this._(widthDp: 728, type: 'leaderboard', maxHeightDp: 90);

  /// Custom fixed banner size via `AdSize(width, height)` on the native SDK.
  ///
  /// Prefer the named IAB factories when possible — non-standard dimensions
  /// often have lower fill rates because fewer creatives match the slot.
  const AdSize.fixed({required int width, required int height})
    : this._(widthDp: width, type: 'fixed', maxHeightDp: height);
}
