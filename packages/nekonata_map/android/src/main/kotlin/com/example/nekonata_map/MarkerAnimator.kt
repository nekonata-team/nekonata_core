package com.example.nekonata_map

import android.graphics.Bitmap
import android.os.Handler
import android.os.Looper
import com.google.android.gms.maps.model.BitmapDescriptor
import com.google.android.gms.maps.model.BitmapDescriptorFactory
import com.google.android.gms.maps.model.Marker

class MarkerAnimator(
    marker: Marker,
    private val frames: List<Bitmap>,
    private val frameDurations: List<Long>
) {
    private val handler = Handler(Looper.getMainLooper())
    private var index = 0
    private val descriptors: List<BitmapDescriptor> = frames.map {
        BitmapDescriptorFactory.fromBitmap(it)
    }

    private val runnable = object : Runnable {
        override fun run() {
            marker.setIcon(descriptors[index])
            val delay = frameDurations[index]
            index = (index + 1) % frames.size
            handler.postDelayed(this, delay)
        }
    }

    fun start() {
        handler.post(runnable)
    }

    fun stop() {
        handler.removeCallbacks(runnable)
    }
}