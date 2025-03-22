package com.example.nekonata_location_fetcher

import android.content.Context
import android.content.Intent
import io.flutter.Log
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result

/** NekonataLocationFetcherPlugin */
class NekonataLocationFetcherPlugin: FlutterPlugin, MethodCallHandler {
  /// The MethodChannel that will the communication between Flutter and native Android
  ///
  /// This local reference serves to register the plugin with the Flutter Engine and unregister it
  /// when the Flutter Engine is detached from the Activity
  private lateinit var channel : MethodChannel
  private lateinit var context: Context

  override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
    context = flutterPluginBinding.applicationContext
    // Original code. Init prefs
    Store.init(context)

    if (Store.isActivated) {
      start()
    }

    channel = MethodChannel(flutterPluginBinding.binaryMessenger, "nekonata_location_fetcher")
    channel.setMethodCallHandler(this)
  }

  override fun onMethodCall(call: MethodCall, result: Result) {
    when (call.method) {
      "setCallback" -> {
        try {
          setCallback(call)
          result.success(null)
        } catch (e: Exception) {
          result.error("error", e.localizedMessage, null)
        }
      }
      "configure" -> {
        try {
          configure(call)
          result.success(null)
        } catch (e: Exception) {
          result.error("error", e.localizedMessage, null)
        }
      }
      "start" -> {
        start()
        result.success(null)
      }
      "stop" -> {
        stop()
        result.success(null)
      }
      "isActivated" -> {
        result.success(Store.isActivated)
      }
      else -> {
        result.notImplemented()
      }
    }
  }

  override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
    channel.setMethodCallHandler(null)
  }

  private fun setCallback(call: MethodCall) {
    val dispatcherHandle = requireNotNull(call.argument<Long>(Store.KEY_DISPATCHER_RAW_HANDLE)) {
      "dispatcherRawHandle must not be null"
    }
    val handle = requireNotNull(call.argument<Long>(Store.KEY_RAW_HANDLE)) {
      "rawHandle must not be null"
    }

    Store.dispatcherRawHandle = dispatcherHandle
    Store.rawHandle = handle
  }

  private fun configure(call: MethodCall) {
    call.argument<String>(Store.KEY_NOTIFICATION_TITLE)?.let { Store.notificationTitle = it }
    call.argument<String>(Store.KEY_NOTIFICATION_TEXT)?.let { Store.notificationText = it }
    call.argument<Double>(Store.KEY_DISTANCE_FILTER)?.let { Store.distanceFilter = it.toFloat() }
    call.argument<Int>(Store.KEY_INTERVAL)?.let { Store.interval = it.toLong() }
  }

  private fun start() {
    if (Permission.hasLocationPermission(context)) {
      val intent = Intent(context, LocationForegroundService::class.java)
      context.startForegroundService(intent)
    } else {
      Log.w("NekonataLocationFetcherPlugin", "Location permission is not granted. Cannot start service.")
    }

    // Set activated to true even if the location permission is not granted
    // Due to on restarted, the service will be try restart
    Store.isActivated = true
  }

  private fun stop() {
    val intent = Intent(context, LocationForegroundService::class.java)
    context.stopService(intent)
    Store.isActivated = false
  }
}
