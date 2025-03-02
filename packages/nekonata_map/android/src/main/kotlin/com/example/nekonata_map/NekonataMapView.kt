package com.example.nekonata_map

import android.animation.ValueAnimator
import android.content.Context
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.view.View
import androidx.lifecycle.DefaultLifecycleObserver
import androidx.lifecycle.LifecycleOwner
import com.google.android.gms.maps.CameraUpdateFactory
import com.google.android.gms.maps.GoogleMap
import com.google.android.gms.maps.MapView
import com.google.android.gms.maps.OnMapReadyCallback
import com.google.android.gms.maps.model.BitmapDescriptorFactory
import com.google.android.gms.maps.model.LatLng
import com.google.android.gms.maps.model.Marker
import com.google.android.gms.maps.model.MarkerOptions
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.platform.PlatformView
import kotlin.math.max

internal class NekonataMapView(
    private val context: Context,
    id: Int,
    private val creationParams: Map<String?, Any?>?,
    messenger: BinaryMessenger,
    private val lifecycleProvider: LifecycleProvider
) : PlatformView, OnMapReadyCallback, DefaultLifecycleObserver {
    private val mapView = MapView(context)
    private lateinit var googleMap: GoogleMap
    private var channel = MethodChannel(messenger, "nekonata_map_$id")
    private val markers = mutableMapOf<String, Marker>()


    init {
        lifecycleProvider.getLifecycle()?.addObserver(this)
        mapView.onCreate(null)
        mapView.getMapAsync(this)

        channel.setMethodCallHandler { call, result ->
            when (call.method) {
                "addMarker" -> {
                    try {
                        addMarker(call.arguments as Map<String, Any>)
                        result.success(null)
                    } catch (e: Exception) {
                        result.error("Error", e.message, null)
                    }
                }

                "removeMarker" -> {
                    try {
                        removeMarker(call.arguments as String)
                        result.success(null)
                    } catch (e: Exception) {
                        result.error("Error", e.message, null)
                    }
                }

                "updateMarker" -> {
                    try {
                        updateMarker(call.arguments as Map<String, Any>)
                        result.success(null)
                    } catch (e: Exception) {
                        result.error("Error", e.message, null)
                    }
                }

                else -> result.notImplemented()
            }
        }
    }


    override fun getView(): View {
        return mapView
    }

    override fun dispose() {
        lifecycleProvider.getLifecycle()?.removeObserver(this)
        mapView.onDestroy()
    }

    private fun addMarker(args: Map<String, Any>) {
        val id = args["id"] as? String ?: throw Exception("id is required")
        val latitude = args["latitude"] as? Double ?: throw Exception("latitude is required")
        val longitude = args["longitude"] as? Double ?: throw Exception("longitude is required")
        val coordinate = LatLng(latitude, longitude)
        val markerOptions = MarkerOptions().position(coordinate)

        // [Platform-specific code | Flutter](https://docs.flutter.dev/platform-integration/platform-channels#codec)
        if (args["image"] != null) {
            val imageData = args["image"] as ByteArray
            var bitmap = BitmapFactory.decodeByteArray(imageData, 0, imageData.size)

            val density = context.resources.displayMetrics.density
            val minWidth = (args["minWidth"] as? Number)?.toInt()
            val minHeight = (args["minHeight"] as? Number)?.toInt()

            bitmap = bitmap.resized(minWidth, minHeight, density)

            markerOptions.icon(BitmapDescriptorFactory.fromBitmap(bitmap))
        }

        val marker = googleMap.addMarker(markerOptions)
        marker?.tag = id
        if (marker != null) {
            markers[id] = marker
        }
        // おそらくプラグイン側の問題でUIが更新されない
        // よって、ほんの少しだけzoomの値を書き換えて再描画する
        googleMap.moveCamera(CameraUpdateFactory.zoomBy(0.0001f))
    }

    private fun removeMarker(id: String) {
        markers[id]?.remove()
        markers.remove(id)
        // addMarkerと同様、ほんの少しだけzoomの値を書き換えて再描画する
        googleMap.moveCamera(CameraUpdateFactory.zoomBy(0.0001f))
    }

    private fun updateMarker(args: Map<String, Any>) {
        val id = args["id"] as? String ?: throw Exception("id is required")
        val latitude = args["latitude"] as? Double ?: throw Exception("latitude is required")
        val longitude = args["longitude"] as? Double ?: throw Exception("longitude is required")

        val marker = markers[id] ?: return
        val start = marker.position
        val end = LatLng(latitude, longitude)

        val valueAnimator = ValueAnimator.ofFloat(0f, 1f)
        valueAnimator.duration = 250L
        valueAnimator.addUpdateListener { animation ->
            val fraction = animation.animatedFraction
            val lat = (end.latitude - start.latitude) * fraction + start.latitude
            val lng = (end.longitude - start.longitude) * fraction + start.longitude
            marker.position = LatLng(lat, lng)
        }
        valueAnimator.start()
    }


    override fun onMapReady(map: GoogleMap) {
        googleMap = map

        creationParams.let { args ->
            val lat = args?.get("latitude") as Double
            val lng = args["longitude"] as Double
            val coordinate = LatLng(lat, lng)
            map.moveCamera(CameraUpdateFactory.newLatLngZoom(coordinate, 15f))
        }

        map.setOnMarkerClickListener { marker ->
            channel.invokeMethod("onSelected", marker.tag as? String)
            true
        }
    }

    override fun onResume(owner: LifecycleOwner) {
        mapView.onResume()
    }

    override fun onPause(owner: LifecycleOwner) {
        mapView.onPause()
    }

    override fun onDestroy(owner: LifecycleOwner) {
        mapView.onDestroy()
    }
}

fun Bitmap.resized(minWidth: Int? = null, minHeight: Int? = null, density: Float): Bitmap {
    // 両方が指定されていなければそのまま返す
    if (minWidth == null && minHeight == null) return this

    val widthScale: Double = if (minWidth != null) minWidth.toDouble() / this.width else 0.0
    val heightScale: Double = if (minHeight != null) minHeight.toDouble() / this.height else 0.0

    // 両方指定の場合は、どちらか大きい方のスケールで調整
    val scaleFactor = when {
        minWidth != null && minHeight != null -> max(widthScale, heightScale)
        minWidth != null -> widthScale
        else -> heightScale
    } * density  // dpからpxに直す。これによって、iOSと同様のサイズ感に近づけることができる

    val newWidth = (this.width * scaleFactor).toInt()
    val newHeight = (this.height * scaleFactor).toInt()

    return Bitmap.createScaledBitmap(this, newWidth, newHeight, false)
}