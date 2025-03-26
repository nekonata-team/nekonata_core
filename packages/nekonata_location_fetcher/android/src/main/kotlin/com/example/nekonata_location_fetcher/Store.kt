package com.example.nekonata_location_fetcher

import android.content.Context
import androidx.datastore.preferences.core.*
import androidx.datastore.preferences.preferencesDataStore
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.map

private val Context.dataStore by preferencesDataStore(name = "nekonata_location_fetcher_data_store")

val KEY_IS_ACTIVATED = booleanPreferencesKey("isActivated")
val KEY_RAW_HANDLE = longPreferencesKey("rawHandle")
val KEY_DISPATCHER_RAW_HANDLE = longPreferencesKey("dispatcherRawHandle")
val KEY_NOTIFICATION_TITLE = stringPreferencesKey("notificationTitle")
val KEY_NOTIFICATION_TEXT = stringPreferencesKey("notificationText")
val KEY_DISTANCE_FILTER = floatPreferencesKey("distanceFilter")
val KEY_INTERVAL = longPreferencesKey("interval")

object Store {

    suspend fun setValue(context: Context, key: Preferences.Key<*>, value: Any) {
        context.dataStore.edit { settings ->
            when (value) {
                is Long -> settings[key as Preferences.Key<Long>] = value
                is Boolean -> settings[key as Preferences.Key<Boolean>] = value
                is String -> settings[key as Preferences.Key<String>] = value
                is Float -> settings[key as Preferences.Key<Float>] = value
            }
        }
    }

    fun <T> getValue(context: Context, key: Preferences.Key<T>, defaultValue: T): Flow<T> {
        return context.dataStore.data.map { preferences ->
            preferences[key] ?: defaultValue
        }
    }

    fun getIsActive(context: Context): Flow<Boolean> {
        return getValue(context, KEY_IS_ACTIVATED, false)
    }

    fun getRawHandle(context: Context): Flow<Long> {
        return getValue(context, KEY_RAW_HANDLE, 0)
    }

    fun getDispatcherRawHandle(context: Context): Flow<Long> {
        return getValue(context, KEY_DISPATCHER_RAW_HANDLE, 0)
    }

    fun getNotificationTitle(context: Context): Flow<String> {
        return getValue(context, KEY_NOTIFICATION_TITLE, "Location Service")
    }

    fun getNotificationText(context: Context): Flow<String> {
        return getValue(context, KEY_NOTIFICATION_TEXT, "Tracking location")
    }

    fun getDistanceFilter(context: Context): Flow<Float> {
        return getValue(context, KEY_DISTANCE_FILTER, 10f)
    }

    fun getInterval(context: Context): Flow<Long> {
        return getValue(context, KEY_INTERVAL, 5)
    }

    fun getIntervalMillis(context: Context): Flow<Long> {
        return getInterval(context).map { it * 1000 }
    }
}
