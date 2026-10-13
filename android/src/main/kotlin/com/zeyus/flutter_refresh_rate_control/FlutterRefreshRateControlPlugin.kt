package com.zeyus.flutter_refresh_rate_control

import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterSurfaceView
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import android.app.Activity
import android.os.Build
import android.view.Display
import android.view.Surface
import android.view.SurfaceHolder
import android.view.SurfaceView
import android.view.View
import android.view.ViewGroup
import kotlin.math.roundToInt

/** FlutterRefreshRateControlPlugin */
class FlutterRefreshRateControlPlugin :
    FlutterPlugin,
    MethodCallHandler,
    ActivityAware {

    companion object {
        private const val CHANNEL_NAME = "com.zeyus.flutter_refresh_rate_control/manage"
    }

    private lateinit var channel: MethodChannel
    private var refreshRateManager: AndroidRefreshRateManager? = null
    private var reapplyOnReattach = false

    override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, CHANNEL_NAME)
        channel.setMethodCallHandler(this)
    }

    override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {
        when (call.method) {
            "getPlatformVersion" -> {
                result.success("Android ${Build.VERSION.RELEASE}")
            }
            "requestHighRefreshRate" -> {
                refreshRateManager?.requestHighRefreshRate(result) ?: result.error("NO_ACTIVITY", "Activity not available", null)
            }
            "stopHighRefreshRate" -> {
                val force = call.argument<Boolean>("force") ?: false
                refreshRateManager?.stopHighRefreshRate(result, force) ?: result.error("NO_ACTIVITY", "Activity not available", null)
            }
            "getRefreshRateInfo" -> {
                refreshRateManager?.getRefreshRateInfo(result) ?: result.error("NO_ACTIVITY", "Activity not available", null)
            }
            else -> {
                result.notImplemented()
            }
        }
    }

    override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        refreshRateManager = AndroidRefreshRateManager(binding.activity)
    }

    override fun onDetachedFromActivityForConfigChanges() {
        // The recreated activity gets a new window without our preference,
        // so remember whether it has to be requested again.
        reapplyOnReattach = refreshRateManager?.highRefreshRateEnabled ?: false
        refreshRateManager = null
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        val manager = AndroidRefreshRateManager(binding.activity)
        refreshRateManager = manager
        if (reapplyOnReattach) {
            reapplyOnReattach = false
            try {
                manager.applyHighRefreshRate()
            } catch (e: Exception) {
                // Nothing to report to; the next call from Dart will surface it
            }
        }
    }

    override fun onDetachedFromActivity() {
        reapplyOnReattach = false
        refreshRateManager = null
    }
}

class AndroidRefreshRateManager(private val activity: Activity) {
    var highRefreshRateEnabled = false
        private set

    // Save the original value to restore it on stop
    private var originalDisplayModeId = 0
    private var requestedDisplayModeId = 0
    private var originalPowerSavingsBalanced: Boolean? = null

    // The flutter surface
    private var flutterSurfaceView: SurfaceView? = null
    private var surfaceFrameRate = 0f

    // New surfaces start without a frame rate set
    private val surfaceCallback = object : SurfaceHolder.Callback {
        override fun surfaceCreated(holder: SurfaceHolder) {
            setSurfaceFrameRate(holder.surface, surfaceFrameRate)
        }

        override fun surfaceChanged(holder: SurfaceHolder, format: Int, width: Int, height: Int) {
            setSurfaceFrameRate(holder.surface, surfaceFrameRate)
        }

        override fun surfaceDestroyed(holder: SurfaceHolder) {}
    }

    // We don't want to change other surfaces (e.g. a video player)
    private fun findFlutterSurfaceView(view: View): SurfaceView? {
        if (view is FlutterSurfaceView) return view
        if (view is ViewGroup) {
            for (i in 0 until view.childCount) {
                findFlutterSurfaceView(view.getChildAt(i))?.let { return it }
            }
        }
        return null
    }

    private fun setSurfaceFrameRate(surface: Surface?, frameRate: Float) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.R || surface == null || !surface.isValid) return
        try {
            surface.setFrameRate(frameRate, Surface.FRAME_RATE_COMPATIBILITY_DEFAULT)
        } catch (e: Exception) {
            // The surface can be released between the check and the call
        }
    }

    /**
     * Tells the compositor which frame rate Flutter's surface wants. The
     * display mode preference of the window only picks the default mode,
     * this is the request that the choice of refresh rate is based on.
     * A frame rate of 0 removes the request.
     */
    private fun requestSurfaceFrameRate(frameRate: Float) {
        surfaceFrameRate = frameRate
        // There is no SurfaceView when Flutter renders into a TextureView
        val surfaceView = if (frameRate > 0f) findFlutterSurfaceView(activity.window.decorView) else null
        if (flutterSurfaceView !== surfaceView) {
            flutterSurfaceView?.let {
                it.holder.removeCallback(surfaceCallback)
                setSurfaceFrameRate(it.holder.surface, 0f)
            }
            surfaceView?.holder?.addCallback(surfaceCallback)
            flutterSurfaceView = surfaceView
        }
        surfaceView?.let { setSurfaceFrameRate(it.holder.surface, frameRate) }
    }

    private fun currentDisplay(): Display? =
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            activity.display
        } else {
            @Suppress("DEPRECATION")
            activity.windowManager.defaultDisplay
        }

    /**
     * Asks the system for the fastest display mode at the current resolution.
     * Returns an error code, or null if the request was made.
     */
    fun applyHighRefreshRate(): String? {
        val display = currentDisplay() ?: return "NO_DISPLAY"
        val currentMode = display.mode

        // Only consider modes at the current resolution, otherwise the
        // request could also change the display resolution.
        val highestRefreshRate = display.supportedModes
            .filter {
                it.physicalWidth == currentMode.physicalWidth &&
                    it.physicalHeight == currentMode.physicalHeight
            }
            .maxByOrNull { it.refreshRate }
            ?: return "NO_HIGH_REFRESH_RATE"

        val window = activity.window
        val layoutParams = window.attributes
        if (!highRefreshRateEnabled) {
            originalDisplayModeId = layoutParams.preferredDisplayModeId
        }
        requestedDisplayModeId = highestRefreshRate.modeId
        layoutParams.preferredDisplayModeId = requestedDisplayModeId
        window.attributes = layoutParams

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.VANILLA_ICE_CREAM) {
            // Opt the window out of Adaptive Refresh Rate
            if (!highRefreshRateEnabled) {
                originalPowerSavingsBalanced = window.isFrameRatePowerSavingsBalanced
            }
            window.isFrameRatePowerSavingsBalanced = false
        }

        requestSurfaceFrameRate(highestRefreshRate.refreshRate)

        highRefreshRateEnabled = true
        return null
    }

    fun requestHighRefreshRate(result: MethodChannel.Result) {
        try {
            when (applyHighRefreshRate()) {
                null -> result.success(true)
                "NO_DISPLAY" -> result.error("NO_DISPLAY", "Could not access display", null)
                else -> result.error("NO_HIGH_REFRESH_RATE", "No high refresh rate modes available", null)
            }
        } catch (e: Exception) {
            result.error("ERROR", "Failed to set high refresh rate: ${e.message}", null)
        }
    }

    /**
     * Puts the window back to how it was before the request. A setting that
     * no longer has the value this plugin gave it was changed by someone
     * else in the meantime, and is left alone unless [force] is set.
     */
    fun stopHighRefreshRate(result: MethodChannel.Result, force: Boolean = false) {
        try {
            if (!highRefreshRateEnabled) {
                result.success(false)
                return
            }

            val window = activity.window
            val layoutParams = window.attributes
            if (force || layoutParams.preferredDisplayModeId == requestedDisplayModeId) {
                // Usually 0: no preference which lets the system decide
                layoutParams.preferredDisplayModeId = originalDisplayModeId
                window.attributes = layoutParams
            }

            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.VANILLA_ICE_CREAM) {
                val original = originalPowerSavingsBalanced
                if (original != null && (force || !window.isFrameRatePowerSavingsBalanced)) {
                    window.isFrameRatePowerSavingsBalanced = original
                }
                originalPowerSavingsBalanced = null
            }

            // Reset the surface to 0 (system decides)
            requestSurfaceFrameRate(0f)

            highRefreshRateEnabled = false
            result.success(true)
        } catch (e: Exception) {
            result.error("ERROR", "Failed to stop high refresh rate: ${e.message}", null)
        }
    }

    fun getRefreshRateInfo(result: MethodChannel.Result) {
        try {
            val info = mutableMapOf<String, Any>()
            val display = currentDisplay()

            if (display != null) {
                info["currentRefreshRate"] = display.refreshRate

                val supportedModes = display.supportedModes
                info["supportedModes"] = supportedModes.map { modeToMap(it) }

                val maxRefreshRate = supportedModes.maxByOrNull { it.refreshRate }?.refreshRate ?: display.refreshRate
                info["maximumFramesPerSecond"] = maxRefreshRate.roundToInt()

                display.mode?.let { info["currentMode"] = modeToMap(it) }

                info["highRefreshRateEnabled"] = highRefreshRateEnabled
                info["surfaceFrameRateRequested"] = flutterSurfaceView != null
                info["androidVersion"] = Build.VERSION.SDK_INT
                info["deviceModel"] = "${Build.MANUFACTURER} ${Build.MODEL}"

                result.success(info)
            } else {
                result.error("NO_DISPLAY", "Could not access display information", null)
            }
        } catch (e: Exception) {
            result.error("ERROR", "Failed to get refresh rate info: ${e.message}", null)
        }
    }

    private fun modeToMap(mode: Display.Mode): Map<String, Any> = mapOf(
        "modeId" to mode.modeId,
        "width" to mode.physicalWidth,
        "height" to mode.physicalHeight,
        "refreshRate" to mode.refreshRate
    )
}
