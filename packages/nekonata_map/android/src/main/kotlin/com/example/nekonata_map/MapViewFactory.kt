package com.example.nekonata_map

import android.content.Context
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.StandardMessageCodec
import io.flutter.plugin.platform.PlatformView
import io.flutter.plugin.platform.PlatformViewFactory

class MapViewFactory(
    private val messenger: BinaryMessenger,
    private val lifecycleProvider: LifecycleProvider
) :
    PlatformViewFactory(StandardMessageCodec.INSTANCE) {
    override fun create(context: Context, viewId: Int, args: Any?): PlatformView {
        val creationParams = args as Map<String?, Any?>?
        return NekonataMapView(context, viewId, creationParams, messenger, lifecycleProvider)
    }
}
