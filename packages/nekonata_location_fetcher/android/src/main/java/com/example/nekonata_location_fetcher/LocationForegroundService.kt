package com.example.nekonata_location_fetcher

import android.app.*
import android.content.Context
import android.content.Intent
import android.content.pm.ServiceInfo
import android.os.BatteryManager
import android.os.Build
import android.os.IBinder
import android.util.Log
import androidx.core.app.NotificationCompat
import com.google.android.gms.location.*
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.dart.DartExecutor
import io.flutter.embedding.engine.loader.FlutterLoader
import io.flutter.plugin.common.MethodChannel
import io.flutter.view.FlutterCallbackInformation

class LocationForegroundService : Service() {

    private lateinit var fusedLocationClient: FusedLocationProviderClient
    private lateinit var locationRequest: LocationRequest
    private lateinit var locationCallback: LocationCallback

    private lateinit var flutterEngine: FlutterEngine

    companion object {
        const val CHANNEL_ID = "location_service_channel"
    }


    override fun onCreate() {
        super.onCreate()

        createNotificationChannel()

        fusedLocationClient = LocationServices.getFusedLocationProviderClient(this)

        locationRequest = LocationRequest.Builder(Priority.PRIORITY_HIGH_ACCURACY, Store.intervalMillis)
            .setMinUpdateDistanceMeters(Store.distanceFilter)
            .build()

        val flutterLoader = FlutterLoader().apply {
            startInitialization(this@LocationForegroundService)
            ensureInitializationComplete(this@LocationForegroundService, null)
        }
        flutterEngine = FlutterEngine(this)

        val callbackInfo = FlutterCallbackInformation.lookupCallbackInformation(Store.dispatcherRawHandle)
        if (callbackInfo != null) {
            flutterEngine.dartExecutor.executeDartCallback(
                DartExecutor.DartCallback(
                    assets,
                    flutterLoader.findAppBundlePath(),
                    callbackInfo
                )
            )
        }

        val channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "nekonata_location_fetcher")
        locationCallback = object : LocationCallback() {
            override fun onLocationResult(locationResult: LocationResult) {
                val location = locationResult.lastLocation
                val battery = getBattery()

                if (location != null) {
                    channel.invokeMethod(
                        "callback", mapOf(
                            "rawHandle" to Store.rawHandle,
                            "latitude" to location.latitude,
                            "longitude" to location.longitude,
                            "speed" to location.speed,
                            "timestamp" to location.time.toDouble(),
                            "bearing" to location.bearing,
                            "battery" to battery,
                        )
                    )
                }
            }
        }
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            startForeground(1, createNotification(), ServiceInfo.FOREGROUND_SERVICE_TYPE_LOCATION) }
        else {
            startForeground(1, createNotification())
        }

        requestLocationUpdates()

        return START_STICKY
    }

    private fun requestLocationUpdates() {
        try {
            fusedLocationClient.requestLocationUpdates(locationRequest, locationCallback, mainLooper)
        } catch (e: SecurityException) {
            Log.e("LocationService", "Location permission not granted", e)
        }
    }

    private fun createNotificationChannel() {
        val channel = NotificationChannel(CHANNEL_ID, "Location Service", NotificationManager.IMPORTANCE_DEFAULT)
        val notificationManager = getSystemService(NotificationManager::class.java) as NotificationManager
        notificationManager.createNotificationChannel(channel)
    }

    private fun createNotification(): Notification {
        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle(Store.notificationTitle)
            .setContentText(Store.notificationText)
            .setSmallIcon(android.R.drawable.ic_menu_mylocation)
            .build()
    }

    private fun getBattery(): Int {
        val batteryManager = getSystemService(Context.BATTERY_SERVICE) as BatteryManager
        val batteryLevel = batteryManager.getIntProperty(BatteryManager.BATTERY_PROPERTY_CAPACITY)
        return batteryLevel
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onDestroy() {
        super.onDestroy()
        fusedLocationClient.removeLocationUpdates(locationCallback)
        flutterEngine.destroy()
    }
}