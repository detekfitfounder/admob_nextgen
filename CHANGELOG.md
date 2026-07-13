## 0.1.1

- Added `BannerAdController` with native `reload()` support for `BannerAdView`.
- Optional retry tuning on `BannerAdController`: `maxAttempts`, `delay`,
  `retryOnNoFill`, and `retryOnNetworkError` (no wrapper object required).
- Automatic banner reload retries no-fill and network errors only when the
  controller sets `retryOnNoFill` and/or `retryOnNetworkError` to `true`.
- Default controller settings do not auto-retry; invalid requests and internal
  SDK errors are never retried.
- Default retry limits when enabled: up to 2 reload attempts, no delay.
- Updated the example app bottom banner with reload controls and failure
  simulation for manual testing.
- Added unit tests for banner reload retry decisions.

## 0.1.0

- Marked the package stable.
- Added README guidance to wrap startup consent calls in `try/catch` so an
  offline consent failure cannot leave the app stuck on the splash screen.
- Documented that Google Mobile Ads Next-Gen SDK mediation adapters are not
  currently supported and can cause duplicate GMS class errors.

## 0.1.0-beta.5

- Added Google-compatible `AppStateEventNotifier` foreground/background
  notifications for App Open ad flows using Android's process lifecycle.
- Updated the example App Open flow to start, subscribe to, cancel, and stop
  `AppStateEventNotifier` instead of relying on Flutter activity lifecycle
  events.
- Hardened App Open and Interstitial lifecycle routing so terminal events
  always consume and release ads, including when no listener is attached or a
  listener throws.
- Prevented duplicate show requests for the same App Open or Interstitial ad.
- Detached native full-screen event callbacks whenever App Open or
  Interstitial ads are removed.
- Added migration documentation for moving from `google_mobile_ads` load and
  full-screen callbacks to Future-first loading and instance listeners.
- Added Dart and Android regression tests for app-state notifications and
  fullscreen ad lifecycle behavior.

## 0.1.0-beta.4

- Fixed Native Validator errors for banner and small native ad templates by
  registering them without hidden undersized media views.
- Fixed false Native Validator media-size errors for large native ads by
  registering the media view after Android completes its first layout pass.
- Prevented delayed large native ad registration after the platform view has
  been disposed.

## 0.1.0-beta.3

- Fixed Linux/pub.dev analysis failures caused by case-sensitive Dart source paths.
- Renamed interstitial and rewarded interstitial source directories to lowercase Dart file convention paths.
- Updated package exports and imports for the normalized paths.
- Improved pub.dev README preview with banner and native ad screenshots.
- Consolidated the example app into `example/lib/main.dart` so pub.dev shows the full example code.
- Excluded generated dartdoc output from publish archives.

## 0.1.0-beta.2

- Updated README.
- Added screenshots for pub.dev package page.

## 0.1.0-beta.1

Initial beta release.

- Android Google Mobile Ads Next-Gen SDK initialization.
- UMP consent helpers.
- Banner, interstitial, rewarded, rewarded interstitial, and app open ads.
- Interstitial and rewarded interstitial preloaders.
- Standard native ads with three prebuilt templates: banner, small, and large.
- Optional native template styling for card color, CTA button, title, description, and ad badge.
