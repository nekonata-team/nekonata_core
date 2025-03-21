package com.example.nekonata_location_fetcher

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import io.flutter.Log

class BootReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        Log.d("BootReceiver", "Received intent: ${intent.action}")
        if (intent.action == Intent.ACTION_BOOT_COMPLETED) {
            Store.init(context)
            if (Permission.hasLocationPermission(context) && Store.isActivated) {
                val serviceIntent = Intent(context, LocationForegroundService::class.java)
                context.startForegroundService(serviceIntent)
            } else {
                Log.w("LocationService", "Location permission not granted")
            }
        }
    }
}