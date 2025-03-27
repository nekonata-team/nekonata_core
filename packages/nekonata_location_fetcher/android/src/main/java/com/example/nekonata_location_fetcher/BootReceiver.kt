package com.example.nekonata_location_fetcher

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import io.flutter.Log
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.runBlocking


class BootReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        Log.d(TAG, "Received BootReceiver intent: ${intent.action}")
        if (intent.action == Intent.ACTION_BOOT_COMPLETED) {
            val isActive = runBlocking { Store.getIsActive(context).first() }
            Log.d(TAG, "isActive: $isActive")
            if (Permission.hasLocationPermission(context) && isActive) {
                val serviceIntent = Intent(context, LocationForegroundService::class.java)
                context.startForegroundService(serviceIntent)
            } else {
                Log.w(TAG, "Location permission not granted")
            }
        }
    }
}