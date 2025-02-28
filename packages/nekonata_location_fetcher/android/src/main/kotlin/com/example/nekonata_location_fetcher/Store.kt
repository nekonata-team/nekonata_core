package com.example.nekonata_location_fetcher

import android.content.Context
import android.content.SharedPreferences

object Store {
    private const val PREFS_NAME = "store_prefs"
    private const val KEY_RAW_HANDLE = "rawHandle"
    private const val KEY_DISPATCHER_RAW_HANDLE = "dispatcherRawHandle"
    private const val KEY_IS_ACTIVATED = "isActivated"

    private lateinit var preferences: SharedPreferences

    fun init(context: Context) {
        preferences = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
    }

    var rawHandle: Long
        get() = preferences.getLong(KEY_RAW_HANDLE, 0)
        set(value) = preferences.edit().putLong(KEY_RAW_HANDLE, value).apply()

    var dispatcherRawHandle: Long
        get() = preferences.getLong(KEY_DISPATCHER_RAW_HANDLE, 0)
        set(value) = preferences.edit().putLong(KEY_DISPATCHER_RAW_HANDLE, value).apply()

    var isActivated: Boolean
        get() = preferences.getBoolean(KEY_IS_ACTIVATED, false)
        set(value) = preferences.edit().putBoolean(KEY_IS_ACTIVATED, value).apply()
}