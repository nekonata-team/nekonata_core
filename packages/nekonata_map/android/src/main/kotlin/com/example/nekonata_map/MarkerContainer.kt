package com.example.nekonata_map

import com.google.android.gms.maps.model.Marker

class MarkerContainer {
    private val markers = mutableMapOf<String, Marker>()
    private val animators = mutableMapOf<String, MarkerAnimator>()

    fun add(
        id: String,
        marker: Marker,
        animator: MarkerAnimator?,
    ) {
        markers[id] = marker
        animator?.let { animator ->
            animators[id] = animator
            animator.start()
        }
    }

    fun get(id: String): Marker? = markers[id]

    fun remove(id: String) {
        markers[id]?.remove()
        markers.remove(id)

        animators[id]?.stop()
        animators.remove(id)
    }

    fun clear() {
        markers.values.forEach { it.remove() }
        markers.clear()

        animators.values.forEach { it.stop() }
        animators.clear()
    }
}