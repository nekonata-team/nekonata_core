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
import com.google.android.gms.maps.model.CameraPosition
import com.google.android.gms.maps.model.LatLng
import com.google.android.gms.maps.model.MarkerOptions
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.platform.PlatformView
import pl.droidsonroids.gif.GifDrawable

internal class NekonataMapView(
    private val context: Context,
    id: Int,
    private val creationParams: Map<String?, Any?>?,
    messenger: BinaryMessenger,
    private val lifecycleProvider: LifecycleProvider
) : PlatformView, OnMapReadyCallback, DefaultLifecycleObserver {
    private lateinit var googleMap: GoogleMap

    private val mapView = MapView(context)
    private var channel = MethodChannel(messenger, "nekonata_map_$id")
    private val container = MarkerContainer()


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

                "moveCamera" -> {
                    try {
                        moveCamera(call.arguments as Map<String, Any>)
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

        val image = args["image"] as? ByteArray
        val density = context.resources.displayMetrics.density
        val minWidth = (args["minWidth"] as? Number)?.toInt()
        val minHeight = (args["minHeight"] as? Number)?.toInt()
        var animator: MarkerAnimator? = null

        // [Platform-specific code | Flutter](https://docs.flutter.dev/platform-integration/platform-channels#codec)
        if (image != null) {
            val bitmap = BitmapFactory
                .decodeByteArray(image, 0, image.size)
                .resized(minWidth, minHeight, density)

            markerOptions.icon(BitmapDescriptorFactory.fromBitmap(bitmap))
        }

        val marker = googleMap.addMarker(markerOptions)!!
        marker.tag = id

        if (image != null) {
            if (isGifData(image)) {
                val (frames, durations) = decodeGif(image)
                animator = MarkerAnimator(
                    marker,
                    frames.map { it.resized(minWidth, minHeight, density) },
                    durations
                )
            }
        }

        container.add(id, marker, animator)

        // おそらくプラグイン側の問題でUIが更新されない
        // よって、ほんの少しだけzoomの値を書き換えて再描画する
        googleMap.moveCamera(CameraUpdateFactory.zoomBy(0.0001f))
    }

    private fun removeMarker(id: String) {
        container.remove(id)

        // addMarkerと同様、ほんの少しだけzoomの値を書き換えて再描画する
        googleMap.moveCamera(CameraUpdateFactory.zoomBy(0.0001f))
    }

    private fun updateMarker(args: Map<String, Any>) {
        val id = args["id"] as? String ?: throw Exception("id is required")
        val latitude = args["latitude"] as? Double ?: throw Exception("latitude is required")
        val longitude = args["longitude"] as? Double ?: throw Exception("longitude is required")

        val marker = container.get(id) ?: return
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

    private fun moveCamera(args: Map<String, Any>) {
        val latitude = args["latitude"] as? Double
        val longitude = args["longitude"] as? Double
        val heading = args["heading"] as? Double
        val zoom = args["zoom"] as? Double

        val current = googleMap.cameraPosition

        val coordinate =
            LatLng(latitude ?: current.target.latitude, longitude ?: current.target.longitude)
        val position = CameraPosition.Builder()
            .target(coordinate)
            .zoom((zoom?.toFloat() ?: current.zoom))
            .bearing(heading?.toFloat() ?: current.bearing)
            .build()
        googleMap.animateCamera(CameraUpdateFactory.newCameraPosition(position))
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
            channel.invokeMethod("onMarkerTapped", marker.tag as? String)
            true
        }
        map.setOnMapClickListener { latLng ->
            channel.invokeMethod(
                "onMapTapped",
                mapOf(
                    "latitude" to latLng.latitude,
                    "longitude" to latLng.longitude,
                ),
            )
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
        container.clear()
    }
}

private fun isGifData(data: ByteArray): Boolean {
    if (data.size < 6) return false
    val header = data.copyOfRange(0, 6).toString(Charsets.US_ASCII)
    return header == "GIF89a" || header == "GIF87a"
}

private fun decodeGif(data: ByteArray): Pair<List<Bitmap>, List<Long>> {
    val gifDrawable = GifDrawable(data)
    val frameCount = gifDrawable.numberOfFrames

    val frames = mutableListOf<Bitmap>()
    val durations = mutableListOf<Long>()

    for (i in 0 until frameCount) {
        // 指定したフレームにシーク
        gifDrawable.seekToFrame(i)
        // 現在のフレームを Bitmap として取得
        val frame = gifDrawable.currentFrame
        // Bitmap をコピーして保持（内部バッファが再利用されるため）
        frames.add(frame.copy(frame.config!!, true))

        // 各フレームの表示時間を取得（ミリ秒単位）
        var duration = gifDrawable.getFrameDuration(i).toLong()
        // 最小表示時間を 100ms に調整
        if (duration < 100L) {
            duration = 100L
        }
        durations.add(duration)
    }
    return Pair(frames, durations)
}