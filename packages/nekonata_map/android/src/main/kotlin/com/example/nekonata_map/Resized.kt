package com.example.nekonata_map

import android.graphics.Bitmap
import kotlin.math.max

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