package com.example.nekonata_location_fetcher

import android.content.Context
import android.content.Intent
import io.flutter.Log
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.cancel
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.launch

const val TAG = "NekonataLocationFetcherPlugin"

/** NekonataLocationFetcherPlugin */
class NekonataLocationFetcherPlugin : FlutterPlugin, MethodCallHandler {
    /// The MethodChannel that will the communication between Flutter and native Android
    ///
    /// This local reference serves to register the plugin with the Flutter Engine and unregister it
    /// when the Flutter Engine is detached from the Activity
    private lateinit var channel: MethodChannel
    private lateinit var context: Context

    private val scope = CoroutineScope(Dispatchers.Main)

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        context = flutterPluginBinding.applicationContext

        scope.launch {
            if (Store.getIsActive(context).first()) {
                start()
            }
        }

        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "nekonata_location_fetcher")
        channel.setMethodCallHandler(this)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        scope.cancel()
        channel.setMethodCallHandler(null)
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "setCallback" -> {
                scope.launch {
                    try {
                        setCallback(call)
                        result.success(null)
                    } catch (e: Exception) {
                        result.error("error", e.localizedMessage, null)
                    }
                }
            }

            "configure" -> {
                scope.launch {
                    try {
                        configure(call)
                        result.success(null)
                    } catch (e: Exception) {
                        result.error("error", e.localizedMessage, null)
                    }
                }
            }

            "start" -> {
                scope.launch {
                    start()
                    result.success(null)
                }
            }

            "stop" -> {
                scope.launch {
                    stop()
                    result.success(null)
                }
            }

            KEY_IS_ACTIVATED.name -> {
                scope.launch {
                    result.success(Store.getIsActive(context).first())
                }
            }

            "configuration" -> {
                scope.launch {
                    result.success(
                        mapOf(
                            KEY_NOTIFICATION_TITLE.name to Store.getNotificationTitle(context)
                                .first(),
                            KEY_NOTIFICATION_TEXT.name to Store.getNotificationText(context)
                                .first(),
                            KEY_DISTANCE_FILTER.name to Store.getDistanceFilter(context).first(),
                            KEY_INTERVAL.name to Store.getInterval(context).first(),
                        )
                    )
                }
            }

            else -> {
                result.notImplemented()
            }
        }
    }

    private suspend fun setCallback(call: MethodCall) {
        val dispatcherHandle = requireNotNull(call.argument<Long>(KEY_DISPATCHER_RAW_HANDLE.name)) {
            "dispatcherRawHandle must not be null"
        }
        val handle = requireNotNull(call.argument<Long>(KEY_RAW_HANDLE.name)) {
            "rawHandle must not be null"
        }

        Store.setValue(context, KEY_DISPATCHER_RAW_HANDLE, dispatcherHandle)
        Store.setValue(context, KEY_RAW_HANDLE, handle)

    }

    private suspend fun configure(call: MethodCall) {
        call.argument<String>(KEY_NOTIFICATION_TITLE.name)
            ?.let { Store.setValue(context, KEY_NOTIFICATION_TITLE, it) }
        call.argument<String>(KEY_NOTIFICATION_TEXT.name)
            ?.let { Store.setValue(context, KEY_NOTIFICATION_TEXT, it) }
        call.argument<Double>(KEY_DISTANCE_FILTER.name)
            ?.let { Store.setValue(context, KEY_DISTANCE_FILTER, it.toFloat()) }
        call.argument<Int>(KEY_INTERVAL.name)
            ?.let { Store.setValue(context, KEY_INTERVAL, it.toLong()) }
    }

    private suspend fun start() {
        if (Permission.hasLocationPermission(context)) {
            val intent = Intent(context, LocationForegroundService::class.java)
            context.startForegroundService(intent)
        } else {
            Log.w(
                TAG,
                "Location permission is not granted. Cannot start service."
            )
        }

        // Set activated to true even if the location permission is not granted
        // Due to on restarted, the service will be try restart
        Store.setValue(context, KEY_IS_ACTIVATED, true)
    }

    private suspend fun stop() {
        val intent = Intent(context, LocationForegroundService::class.java)
        context.stopService(intent)
        Store.setValue(context, KEY_IS_ACTIVATED, false)
    }
}
