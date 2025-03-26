package com.example.nekonata_location_fetcher

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.Context
import android.content.Intent
import android.content.pm.ServiceInfo
import android.os.BatteryManager
import android.os.Build
import android.util.Log
import androidx.core.app.NotificationCompat
import androidx.lifecycle.LifecycleService
import androidx.lifecycle.lifecycleScope
import com.google.android.gms.location.FusedLocationProviderClient
import com.google.android.gms.location.LocationCallback
import com.google.android.gms.location.LocationRequest
import com.google.android.gms.location.LocationResult
import com.google.android.gms.location.LocationServices
import com.google.android.gms.location.Priority
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.dart.DartExecutor
import io.flutter.embedding.engine.loader.FlutterLoader
import io.flutter.plugin.common.MethodChannel
import io.flutter.view.FlutterCallbackInformation
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.launch
import kotlinx.coroutines.runBlocking

class LocationForegroundService : LifecycleService() {

    private lateinit var fusedLocationClient: FusedLocationProviderClient
    private lateinit var flutterEngine: FlutterEngine
    private lateinit var locationCallback: LocationCallback

    companion object {
        const val CHANNEL_ID = "location_service_channel"
    }


    override fun onCreate() {
        super.onCreate()

        createNotificationChannel()

        fusedLocationClient = LocationServices.getFusedLocationProviderClient(this)

        val flutterLoader = FlutterLoader().apply {
            startInitialization(this@LocationForegroundService)
            ensureInitializationComplete(this@LocationForegroundService, null)
        }
        flutterEngine = FlutterEngine(this)

        val dispatcherRawHandle =
            runBlocking { Store.getDispatcherRawHandle(this@LocationForegroundService).first() }

        val callbackInfo =
            FlutterCallbackInformation.lookupCallbackInformation(dispatcherRawHandle)
        if (callbackInfo != null) {
            flutterEngine.dartExecutor.executeDartCallback(
                DartExecutor.DartCallback(
                    assets,
                    flutterLoader.findAppBundlePath(),
                    callbackInfo
                )
            )
        }


        val channel =
            MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "nekonata_location_fetcher")
        val rawHandle = runBlocking { Store.getRawHandle(this@LocationForegroundService).first() }

        locationCallback = object : LocationCallback() {
            override fun onLocationResult(locationResult: LocationResult) {
                val location = locationResult.lastLocation
                val battery = getBattery()

                if (location != null) {
                    channel.invokeMethod(
                        "callback", mapOf(
                            "rawHandle" to rawHandle,
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
        super.onStartCommand(intent, flags, startId)
        val notification = runBlocking { createNotification() }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            startForeground(
                1,
                notification,
                ServiceInfo.FOREGROUND_SERVICE_TYPE_LOCATION
            )
        } else {
            startForeground(1, notification)
        }

        lifecycleScope.launch {
            requestLocationUpdates()
        }

        return START_STICKY
    }

    private suspend fun requestLocationUpdates() {
        try {
            val intervalMills = Store.getIntervalMillis(this@LocationForegroundService).first()
            val distanceFilter = Store.getDistanceFilter(this@LocationForegroundService).first()

            val locationRequest =
                LocationRequest.Builder(Priority.PRIORITY_HIGH_ACCURACY, intervalMills)
                    .setMinUpdateDistanceMeters(distanceFilter)
                    .build()

            fusedLocationClient.requestLocationUpdates(
                locationRequest,
                locationCallback,
                mainLooper
            )
        } catch (e: SecurityException) {
            Log.e("LocationService", "Location permission not granted", e)
        }
    }

    private fun createNotificationChannel() {
        val channel = NotificationChannel(
            CHANNEL_ID,
            "Location Service",
            NotificationManager.IMPORTANCE_DEFAULT
        )
        val notificationManager =
            getSystemService(NotificationManager::class.java) as NotificationManager
        notificationManager.createNotificationChannel(channel)
    }

    private suspend fun createNotification(): Notification {
        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle(Store.getNotificationTitle(this@LocationForegroundService).first())
            .setContentText(Store.getNotificationText(this@LocationForegroundService).first())
            .setSmallIcon(android.R.drawable.ic_menu_mylocation)
            .build()
    }

    private fun getBattery(): Int {
        val batteryManager = getSystemService(Context.BATTERY_SERVICE) as BatteryManager
        val batteryLevel = batteryManager.getIntProperty(BatteryManager.BATTERY_PROPERTY_CAPACITY)
        return batteryLevel
    }

    override fun onDestroy() {
        super.onDestroy()
        fusedLocationClient.removeLocationUpdates(locationCallback)
        flutterEngine.destroy()
    }
}