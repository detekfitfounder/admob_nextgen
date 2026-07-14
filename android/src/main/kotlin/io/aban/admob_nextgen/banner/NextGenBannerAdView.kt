package io.aban.admob_nextgen.banner

import android.app.Activity
import android.content.Context
import android.os.Handler
import android.os.Looper
import android.util.Log
import android.view.View
import android.widget.FrameLayout
import com.google.android.libraries.ads.mobile.sdk.banner.AdSize
import com.google.android.libraries.ads.mobile.sdk.banner.AdView
import com.google.android.libraries.ads.mobile.sdk.banner.BannerAd
import com.google.android.libraries.ads.mobile.sdk.banner.BannerAdEventCallback
import com.google.android.libraries.ads.mobile.sdk.banner.BannerAdRefreshCallback
import com.google.android.libraries.ads.mobile.sdk.common.AdLoadCallback
import com.google.android.libraries.ads.mobile.sdk.common.FullScreenContentError
import com.google.android.libraries.ads.mobile.sdk.common.LoadAdError
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.platform.PlatformView
import io.aban.admob_nextgen.AdmobNextgenPlugin
import io.aban.admob_nextgen.core.buildBannerAdRequest
import io.aban.admob_nextgen.core.toFlutterMap

class NextGenBannerAdView(
    private val hostContext: Context,
    private val activity: Activity?,
    viewId: Int,
    messenger: BinaryMessenger,
    creationParams: Map<String, Any?>,
) : PlatformView {

    companion object {
        private const val TAG = "NextGenBannerAdView"
    }

    private val container: FrameLayout = FrameLayout(hostContext)
    private var adView: AdView? = null
    private val eventChannel = MethodChannel(messenger, "next_gen_sdk/banner_ad_$viewId")
    private var storedAdUnitId: String? = null
    private var storedWidthDp: Int = 360
    private var storedSizeType: String = "anchored"
    private var storedMaxHeightDp: Int = 0
    private var storedRequestParams: Map<String, Any?>? = null
    private var isLoading = false

    init {
        val adUnitId = creationParams["adUnitId"] as? String
        val widthDp = (creationParams["widthDp"] as? Number)?.toInt() ?: 360
        val sizeType = creationParams["sizeType"] as? String ?: "anchored"
        val maxHeightDp = (creationParams["maxHeightDp"] as? Number)?.toInt() ?: 0
        @Suppress("UNCHECKED_CAST")
        val requestParams = creationParams["request"] as? Map<String, Any?>

        eventChannel.setMethodCallHandler { call, result ->
            when (call.method) {
                "reload" -> {
                    val act = activity
                    if (act == null) {
                        result.error(
                            "NO_ACTIVITY",
                            "Banner reload requires an Activity.",
                            null,
                        )
                        return@setMethodCallHandler
                    }
                    val unitId = storedAdUnitId
                    if (unitId.isNullOrBlank()) {
                        result.error(
                            "NOT_CONFIGURED",
                            "Banner has no ad unit to reload.",
                            null,
                        )
                        return@setMethodCallHandler
                    }
                    reloadAd(act)
                    result.success(null)
                }

                else -> result.notImplemented()
            }
        }

        when {
            adUnitId.isNullOrBlank() -> Log.e(TAG, "adUnitId is required.")
            activity == null -> Log.e(
                TAG,
                "BannerAdView requires an Activity. Make sure the plugin is " +
                    "attached to the host Activity before mounting the widget.",
            )

            else -> {
                if (!AdmobNextgenPlugin.isInitialized) {
                    Log.w(
                        TAG,
                        "MobileAds is not initialized. Call MobileAds.initialize() " +
                            "before creating a BannerAdView.",
                    )
                }
                storeLoadParams(adUnitId, widthDp, sizeType, maxHeightDp, requestParams)
                loadAd(activity)
            }
        }
    }

    private fun storeLoadParams(
        adUnitId: String,
        widthDp: Int,
        sizeType: String,
        maxHeightDp: Int,
        requestParams: Map<String, Any?>?,
    ) {
        storedAdUnitId = adUnitId
        storedWidthDp = widthDp
        storedSizeType = sizeType
        storedMaxHeightDp = maxHeightDp
        storedRequestParams = requestParams
    }

    private fun reloadAd(activity: Activity) {
        if (isLoading) {
            Log.d(TAG, "Reload skipped — banner load already in progress.")
            return
        }
        tearDownAdView()
        loadAd(activity)
    }

    private fun tearDownAdView() {
        adView?.let { view ->
            container.removeView(view)
            view.destroy()
        }
        adView = null
    }

    private fun loadAd(activity: Activity) {
        val adUnitId = storedAdUnitId ?: return
        isLoading = true

        val adSize = resolveAdSize(activity, storedSizeType, storedWidthDp, storedMaxHeightDp)
        val request = buildBannerAdRequest(adUnitId, adSize, storedRequestParams)
        val newAdView = AdView(activity)
        adView = newAdView
        container.addView(
            newAdView,
            FrameLayout.LayoutParams(
                FrameLayout.LayoutParams.MATCH_PARENT,
                FrameLayout.LayoutParams.WRAP_CONTENT,
            ),
        )

        newAdView.loadAd(
            request,
            object : AdLoadCallback<BannerAd> {
                override fun onAdLoaded(ad: BannerAd) {
                    isLoading = false
                    val collapsible = ad.isCollapsible()
                    Log.d(TAG, "Banner ad loaded (isCollapsible=$collapsible).")
                    invokeOnMain(
                        "onAdLoaded",
                        mapOf("isCollapsible" to collapsible),
                    )
                    ad.adEventCallback = object : BannerAdEventCallback {
                        override fun onAdImpression() {
                            invokeOnMain("onAdImpression", null)
                        }

                        override fun onAdClicked() {
                            invokeOnMain("onAdClicked", null)
                        }

                        override fun onAdShowedFullScreenContent() {
                            invokeOnMain("onAdShowedFullScreenContent", null)
                        }

                        override fun onAdDismissedFullScreenContent() {
                            invokeOnMain("onAdDismissedFullScreenContent", null)
                        }

                        override fun onAdFailedToShowFullScreenContent(
                            fullScreenContentError: FullScreenContentError,
                        ) {
                            Log.w(TAG, "Banner ad failed to show: $fullScreenContentError")
                            invokeOnMain(
                                "onAdFailedToShowFullScreenContent",
                                fullScreenContentError.toFlutterMap(),
                            )
                        }
                    }
                    ad.bannerAdRefreshCallback = object : BannerAdRefreshCallback {
                        override fun onAdRefreshed() {
                            invokeOnMain("onAdRefreshed", null)
                        }

                        override fun onAdFailedToRefresh(loadAdError: LoadAdError) {
                            Log.w(TAG, "Banner ad failed to refresh: $loadAdError")
                            invokeOnMain(
                                "onAdFailedToRefresh",
                                loadAdError.toFlutterMap(),
                            )
                        }
                    }
                }

                override fun onAdFailedToLoad(adError: LoadAdError) {
                    isLoading = false
                    Log.w(TAG, "Banner ad failed to load: $adError")
                    invokeOnMain(
                        "onAdFailedToLoad",
                        adError.toFlutterMap(),
                    )
                }
            },
        )
    }

    private fun resolveAdSize(
        activity: Activity,
        sizeType: String,
        widthDp: Int,
        maxHeightDp: Int,
    ): AdSize {
        return when (sizeType) {
            "largeAnchored" -> AdSize.getLargeAnchoredAdaptiveBannerAdSize(activity, widthDp)
            "inline" -> AdSize.getInlineAdaptiveBannerAdSize(widthDp, maxHeightDp)
            "banner" -> AdSize.BANNER
            "largeBanner" -> AdSize.LARGE_BANNER
            "mediumRectangle" -> AdSize.MEDIUM_RECTANGLE
            "fullBanner" -> AdSize.FULL_BANNER
            "leaderboard" -> AdSize.LEADERBOARD
            "fixed" -> AdSize(widthDp, maxHeightDp)
            else -> AdSize.getCurrentOrientationAnchoredAdaptiveBannerAdSize(activity, widthDp)
        }
    }

    private fun invokeOnMain(method: String, args: Any?) {
        Handler(Looper.getMainLooper()).post {
            eventChannel.invokeMethod(method, args)
        }
    }

    override fun getView(): View = container

    override fun dispose() {
        isLoading = false
        tearDownAdView()
        eventChannel.setMethodCallHandler(null)
    }
}
