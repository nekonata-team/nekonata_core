package com.example.nekonata_location_fetcher

import android.content.Context
import android.content.SharedPreferences
import androidx.core.content.edit

object Store {
    private const val PREFS_NAME = "store_prefs"

    // プラットフォーム間のKeyとして扱っているので、変更する際は十分に注意すること
    // 便宜上、prefsに保存する際のKeyと同名にしている
    private const val KEY_IS_ACTIVATED = "isActivated"
    const val KEY_RAW_HANDLE = "rawHandle"
    const val KEY_DISPATCHER_RAW_HANDLE = "dispatcherRawHandle"
    const val KEY_NOTIFICATION_TITLE = "notificationTitle"
    const val KEY_NOTIFICATION_TEXT = "notificationText"
    const val KEY_DISTANCE_FILTER = "distanceFilter"
    const val KEY_INTERVAL = "interval"

    private lateinit var prefs: SharedPreferences

    fun init(context: Context) {
        prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
    }

    var rawHandle: Long
        get() = prefs.getLong(KEY_RAW_HANDLE, 0)
        set(value) = prefs.edit { putLong(KEY_RAW_HANDLE, value) }

    var dispatcherRawHandle: Long
        get() = prefs.getLong(KEY_DISPATCHER_RAW_HANDLE, 0)
        set(value) = prefs.edit { putLong(KEY_DISPATCHER_RAW_HANDLE, value) }

    var isActivated: Boolean
        get() = prefs.getBoolean(KEY_IS_ACTIVATED, false)
        set(value) = prefs.edit { putBoolean(KEY_IS_ACTIVATED, value) }

    var notificationTitle: String
        get() = prefs.getString(KEY_NOTIFICATION_TITLE, "Location Tracking")!!
        set(value) = prefs.edit { putString(KEY_NOTIFICATION_TITLE, value) }

    var notificationText: String
        get() = prefs.getString(KEY_NOTIFICATION_TEXT, "Getting location updates...")!!
        set(value) = prefs.edit { putString(KEY_NOTIFICATION_TEXT, value) }

    var distanceFilter: Float
        get() = prefs.getFloat(KEY_DISTANCE_FILTER, 10f)
        set(value) = prefs.edit { putFloat(KEY_DISTANCE_FILTER, value) }

    var interval: Long
        get() = prefs.getLong(KEY_INTERVAL, 5)
        set(value) = prefs.edit { putLong(KEY_INTERVAL, value) }

    val intervalMillis: Long get() = interval * 1000
}