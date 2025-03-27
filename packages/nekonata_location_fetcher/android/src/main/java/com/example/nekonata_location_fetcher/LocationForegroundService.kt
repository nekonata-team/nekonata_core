package com.example.nekonata_location_fetcher

import android.app.ForegroundServiceStartNotAllowedException
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.pm.ServiceInfo
import android.os.BatteryManager
import android.os.Build
import android.os.IBinder
import androidx.core.app.NotificationCompat
import com.google.android.gms.location.FusedLocationProviderClient
import com.google.android.gms.location.LocationCallback
import com.google.android.gms.location.LocationRequest
import com.google.android.gms.location.LocationResult
import com.google.android.gms.location.LocationServices
import com.google.android.gms.location.Priority
import io.flutter.Log
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.dart.DartExecutor
import io.flutter.embedding.engine.loader.FlutterLoader
import io.flutter.plugin.common.MethodChannel
import io.flutter.view.FlutterCallbackInformation
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.runBlocking

class LocationForegroundService : Service() {

    private lateinit var fusedLocationClient: FusedLocationProviderClient
    private lateinit var locationCallback: LocationCallback

    private lateinit var flutterEngine: FlutterEngine
    private lateinit var channel: MethodChannel

    private var isDispatched = false

    companion object {
        const val CHANNEL_ID = "nekonata_location_fetcher_channel"
        const val NOTIFICATION_ID = 100
    }


    override fun onCreate() {
        super.onCreate()
        fusedLocationClient = LocationServices.getFusedLocationProviderClient(this)
        flutterEngine = FlutterEngine(this)
        channel =
            MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "nekonata_location_fetcher")
        locationCallback = object : LocationCallback() {
            override fun onLocationResult(locationResult: LocationResult) {
                val location = locationResult.lastLocation
                val battery = getBattery()

                if (location != null) {
                    channel.invokeMethod(
                        "callback", mapOf(
                            "rawHandle" to runBlocking { Store.getRawHandle(this@LocationForegroundService).first() },
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

        dispatch()
        createNotificationChannel()

        val notification = NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("Starting service...")
            .setContentText("Initializing...")
            .setSmallIcon(android.R.drawable.ic_menu_mylocation)
            .build()

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            startForeground(NOTIFICATION_ID, notification, ServiceInfo.FOREGROUND_SERVICE_TYPE_LOCATION)
        } else {
            startForeground(NOTIFICATION_ID, notification)
        }

        // 非同期で通知を更新
        runBlocking {
            val updatedNotification = createNotification()
            val notificationManager = getSystemService(NotificationManager::class.java) as NotificationManager
            notificationManager.notify(NOTIFICATION_ID, updatedNotification)
            Log.d(TAG, "Notification updated")
        }

        runBlocking {
            requestLocationUpdates()
            Log.d(TAG, "Location updates requested")
        }

        return START_STICKY
    }

    private fun dispatch() {
        if (isDispatched) return

        val dispatcherRawHandle =
            runBlocking { Store.getDispatcherRawHandle(this@LocationForegroundService).first() }

        val callbackInfo =
            FlutterCallbackInformation.lookupCallbackInformation(dispatcherRawHandle)
        if (callbackInfo != null) {
            val flutterLoader = FlutterLoader().apply {
                startInitialization(this@LocationForegroundService)
                ensureInitializationComplete(this@LocationForegroundService, null)
            }
            flutterEngine.dartExecutor.executeDartCallback(
                DartExecutor.DartCallback(
                    assets,
                    flutterLoader.findAppBundlePath(),
                    callbackInfo
                )
            )
            isDispatched = true
            Log.d(TAG, "Flutter engine dispatched")
        } else {
            Log.e(TAG, "Dispatcher raw handle not found")
        }
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
            Log.e(TAG, "Location permission not granted", e)
        }
    }

    private fun createNotificationChannel() {
        val channel = NotificationChannel(
            CHANNEL_ID,
            "Nekonata Location Fetcher",
            NotificationManager.IMPORTANCE_DEFAULT
        )
        val notificationManager =
            getSystemService(NotificationManager::class.java) as NotificationManager
        notificationManager.createNotificationChannel(channel)

        Log.d(TAG, "Notification channel created")
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

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onDestroy() {
        super.onDestroy()
        fusedLocationClient.removeLocationUpdates(locationCallback)
        flutterEngine.destroy()
        Log.d(TAG, "LocationForegroundService was destroyed")
    }
}