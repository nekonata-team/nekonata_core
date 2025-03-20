package com.example.nekonata_location_fetcher

import android.content.Context
import android.content.SharedPreferences
import androidx.core.content.edit

object Store {
    private const val PREFS_NAME = "store_prefs"
    private const val KEY_RAW_HANDLE = "rawHandle"
    private const val KEY_DISPATCHER_RAW_HANDLE = "dispatcherRawHandle"
    private const val KEY_IS_ACTIVATED = "isActivated"
    private const val KEY_NOTIFICATION_TITLE = "notificationTitle"
    private const val KEY_NOTIFICATION_TEXT = "notificationText"

    private lateinit var preferences: SharedPreferences

    fun init(context: Context) {
        preferences = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
    }

    var rawHandle: Long
        get() = preferences.getLong(KEY_RAW_HANDLE, 0)
        set(value) = preferences.edit { putLong(KEY_RAW_HANDLE, value) }

    var dispatcherRawHandle: Long
        get() = preferences.getLong(KEY_DISPATCHER_RAW_HANDLE, 0)
        set(value) = preferences.edit { putLong(KEY_DISPATCHER_RAW_HANDLE, value) }

    var isActivated: Boolean
        get() = preferences.getBoolean(KEY_IS_ACTIVATED, false)
        set(value) = preferences.edit { putBoolean(KEY_IS_ACTIVATED, value) }

    var notificationTitle: String
        get() = preferences.getString(KEY_NOTIFICATION_TITLE, "Location Tracking")!!
        set(value) = preferences.edit { putString(KEY_NOTIFICATION_TITLE, value) }

    var notificationText: String
        get() = preferences.getString(KEY_NOTIFICATION_TEXT, "Getting location updates...")!!
        set(value) = preferences.edit { putString(KEY_NOTIFICATION_TEXT, value) }
}