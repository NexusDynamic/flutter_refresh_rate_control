package com.zeyus.flutter_refresh_rate_control

import androidx.annotation.NonNull
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
import android.view.SurfaceControl
import android.view.WindowManager
import android.content.Context
import androidx.annotation.RequiresApi
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
    private var activity: Activity? = null
    private var refreshRateManager: AndroidRefreshRateManager? = null

    override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, CHANNEL_NAME)
        channel.setMethodCallHandler(this)
    }

    override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {
        when (call.method) {
            "requestHighRefreshRate" -> {
                refreshRateManager?.requestHighRefreshRate(result) ?: result.error("NO_ACTIVITY", "Activity not available", null)
            }
            "stopHighRefreshRate" -> {
                refreshRateManager?.stopHighRefreshRate(result) ?: result.error("NO_ACTIVITY", "Activity not available", null)
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
        activity = binding.activity
        refreshRateManager = AndroidRefreshRateManager(activity!!)
    }

    override fun onDetachedFromActivityForConfigChanges() {
        // Activity is being recreated, keep the reference for now
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        activity = binding.activity
        refreshRateManager = AndroidRefreshRateManager(activity!!)
    }

    override fun onDetachedFromActivity() {
        activity = null
        refreshRateManager = null
    }
}

class AndroidRefreshRateManager(private val activity: Activity) {
    private var originalRefreshRate: Float? = null
    private var highRefreshRateEnabled = false
    private var surfaceControl: SurfaceControl? = null
    
    fun requestHighRefreshRate(result: MethodChannel.Result) {
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                val window = activity.window
                val display = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
                    activity.display
                } else {
                    @Suppress("DEPRECATION")
                    window.windowManager.defaultDisplay
                }
                
                if (display != null) {
                    if (originalRefreshRate == null) {
                        originalRefreshRate = display.refreshRate
                    }
                    
                    val supportedModes = display.supportedModes
                    val highestRefreshRate = supportedModes.maxByOrNull { it.refreshRate }
                    
                    if (highestRefreshRate != null) {
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                            val layoutParams = window.attributes
                            layoutParams.preferredDisplayModeId = highestRefreshRate.modeId
                            window.attributes = layoutParams
                        }
                        
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
                            val surface = activity.window.decorView.rootView.rootSurfaceControl
                            if (surface != null) {
                                try {
                                    if (surfaceControl == null) {
                                        surfaceControl = SurfaceControl.Builder()
                                            .setName("HighPrecisionSurface")
                                            .setBufferSize(1, 1)
                                            .build()
                                    }
                                    val transaction = SurfaceControl.Transaction()
                                    val framerateTransaction = transaction.setFrameRate(
                                        surfaceControl!!,
                                        highestRefreshRate.refreshRate,
                                        Surface.FRAME_RATE_COMPATIBILITY_FIXED_SOURCE
                                    )
                                    surface.applyTransactionOnDraw(framerateTransaction)
                                } catch (e: Exception) {
                                    // Surface frame rate API might not be available
                                }
                            }
                        }
                        
                        highRefreshRateEnabled = true
                        result.success(true)
                    } else {
                        result.error("NO_HIGH_REFRESH_RATE", "No high refresh rate modes available", null)
                    }
                } else {
                    result.error("NO_DISPLAY", "Could not access display", null)
                }
            } else {
                result.error("UNSUPPORTED", "High refresh rate requires Android M (API 23) or higher", null)
            }
        } catch (e: Exception) {
            result.error("ERROR", "Failed to set high refresh rate: ${e.message}", null)
        }
    }
    
    fun stopHighRefreshRate(result: MethodChannel.Result) {
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M && originalRefreshRate != null) {
                val window = activity.window
                val display = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
                    activity.display
                } else {
                    @Suppress("DEPRECATION")
                    window.windowManager.defaultDisplay
                }
                
                if (display != null) {
                    val supportedModes = display.supportedModes
                    val originalMode = supportedModes.minByOrNull { 
                        kotlin.math.abs(it.refreshRate - originalRefreshRate!!) 
                    }
                    
                    if (originalMode != null) {
                        val layoutParams = window.attributes
                        layoutParams.preferredDisplayModeId = originalMode.modeId
                        window.attributes = layoutParams
                        
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R && surfaceControl != null) {
                            val surface = activity.window.decorView.rootView.rootSurfaceControl
                            if (surface != null) {
                                try {
                                    val transaction = SurfaceControl.Transaction()
                                    val framerateTransaction = transaction.setFrameRate(
                                        surfaceControl!!,
                                        0f,
                                        Surface.FRAME_RATE_COMPATIBILITY_DEFAULT
                                    )
                                    surface.applyTransactionOnDraw(framerateTransaction)
                                } catch (e: Exception) {
                                    // Surface frame rate API might not be available
                                }
                            }
                        }
                    }
                }
                
                highRefreshRateEnabled = false
                result.success(true)
            } else {
                result.success(false)
            }
        } catch (e: Exception) {
            result.error("ERROR", "Failed to stop high refresh rate: ${e.message}", null)
        }
    }
    
    fun getRefreshRateInfo(result: MethodChannel.Result) {
        try {
            val info = mutableMapOf<String, Any>()
            
            val display = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
                activity.display
            } else {
                @Suppress("DEPRECATION")
                activity.windowManager.defaultDisplay
            }
            
            if (display != null) {
                info["currentRefreshRate"] = display.refreshRate
                
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                    val supportedModes = display.supportedModes
                    val modesList = mutableListOf<Map<String, Any>>()
                    
                    for (mode in supportedModes) {
                        val modeInfo = mapOf(
                            "modeId" to mode.modeId,
                            "width" to mode.physicalWidth,
                            "height" to mode.physicalHeight,
                            "refreshRate" to mode.refreshRate
                        )
                        modesList.add(modeInfo)
                    }
                    
                    info["supportedModes"] = modesList
                    
                    val maxRefreshRate = supportedModes.maxByOrNull { it.refreshRate }?.refreshRate ?: display.refreshRate
                    info["maximumFramesPerSecond"] = maxRefreshRate.roundToInt()
                    
                    val currentMode = supportedModes.find { it.modeId == display.mode?.modeId }
                    if (currentMode != null) {
                        info["currentMode"] = mapOf(
                            "modeId" to currentMode.modeId,
                            "width" to currentMode.physicalWidth,
                            "height" to currentMode.physicalHeight,
                            "refreshRate" to currentMode.refreshRate
                        )
                    }
                } else {
                    info["maximumFramesPerSecond"] = display.refreshRate.roundToInt()
                }
                
                info["highRefreshRateEnabled"] = highRefreshRateEnabled
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
}
