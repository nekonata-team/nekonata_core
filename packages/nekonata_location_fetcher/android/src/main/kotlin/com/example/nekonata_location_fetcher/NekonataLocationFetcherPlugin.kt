package com.example.nekonata_location_fetcher

import android.content.Context
import android.content.Intent
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
          result.error("error", e.message, null)
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
      else -> {
        result.notImplemented()
      }
    }
  }

  override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
    channel.setMethodCallHandler(null)
  }

  private fun setCallback(call: MethodCall) {
    val dispatcherHandle = call.argument<Long>("dispatcherRawHandle")
    val handle = call.argument<Long>("rawHandle")

    // null check and throw
    if (dispatcherHandle == null || handle == null) {
      throw Exception("dispatcherHandle and handle must not be null. dispatcherHandle: $dispatcherHandle, handle: $handle")
    }

    Store.dispatcherRawHandle = dispatcherHandle
    Store.rawHandle = handle
  }

  private fun start() {
    val intent = Intent(context, LocationForegroundService::class.java)
    context.startForegroundService(intent)
    Store.isActivated = true
  }

  private fun stop() {
    val intent = Intent(context, LocationForegroundService::class.java)
    context.stopService(intent)
    Store.isActivated = false
  }
}
