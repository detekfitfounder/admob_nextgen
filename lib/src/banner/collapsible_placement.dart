/// Where a collapsible banner overlay anchors relative to the collapsed slot.
///
/// Pass to [AdSize.collapsible] as the required [placement]. Intended for
/// **anchored** top/bottom placements — keep [BannerAdView.height] at the
/// collapsed size (at least [AdSize.collapsibleRecommendedMinHeightDp]);
/// expansion is an SDK overlay and does not resize the Flutter layout.
///
/// Requesting collapsible does not guarantee a collapsible creative. Use
/// [BannerAdListener.onIsCollapsible] after load to check.
enum CollapsiblePlacement {
  /// Expanded ad aligns to the top of the collapsed banner (top-of-screen slots).
  top,

  /// Expanded ad aligns to the bottom of the collapsed banner (bottom-of-screen
  /// slots).
  bottom,
}

extension CollapsiblePlacementWire on CollapsiblePlacement {
  /// Wire value sent to the native Google extras bundle (`"top"` / `"bottom"`).
  String get wireValue => name;
}
