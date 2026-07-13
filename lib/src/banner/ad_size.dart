/// Logical banner size sent across the platform channel.
///
/// Use one of the factory constructors:
///
/// * [AdSize.anchored] — anchored adaptive banner (recommended default)
/// * [AdSize.largeAnchored] — taller anchored adaptive banner
/// * [AdSize.inline] — inline adaptive banner with a max height
/// * [AdSize.mediumRectangle] — fixed IAB medium rectangle (custom width/height)
class AdSize {
  const AdSize._({required this.widthDp, required this.type, this.maxHeightDp});

  /// Width in density-independent pixels.
  final int widthDp;

  /// Internal wire-name routed to the native [AdSize] factory.
  final String type;

  /// For [AdSize.inline] only — upper bound on banner height. 0 = auto.
  final int? maxHeightDp;

  /// Anchored adaptive banner: SDK picks an appropriate height for [width].
  /// This is the recommended default for most placements.
  const AdSize.anchored({int width = 360})
    : this._(widthDp: width, type: 'anchored');

  /// Larger anchored adaptive banner — taller than [AdSize.anchored].
  /// Matches the example in Google's documentation.
  const AdSize.largeAnchored({int width = 360})
    : this._(widthDp: width, type: 'largeAnchored');

  /// Inline adaptive banner — height is chosen up to [maxHeight] (or unbounded
  /// when 0).
  const AdSize.inline({int width = 360, int maxHeight = 0})
    : this._(widthDp: width, type: 'inline', maxHeightDp: maxHeight);

  /// Fixed Interactive Advertising Bureau (IAB) medium rectangle banner.
  ///
  /// Defaults to the standard 300x250 dp size. Pass [width] and [height] to
  /// request a custom fixed banner size supported by the GMA Next-Gen SDK.
  ///
  /// Give [BannerAdView] a container at least as large as [height] (e.g.
  /// `height: 250`), otherwise the SDK logs "Not enough space to show ad"
  /// and renders nothing.
  const AdSize.mediumRectangle({int width = 300, int height = 250})
    : this._(widthDp: width, type: 'mediumRectangle', maxHeightDp: height);
}
