import 'dart:async';

import 'package:flutter/material.dart';
import 'package:nekonata_map/nekonata_map.dart';

/// Gesture detector for zooming in and out using edge zones.
/// Shows a visual curved effect toward the touch point.
class EdgeZoomGesture extends StatefulWidget {
  /// Creates a new [EdgeZoomGesture] instance.
  const EdgeZoomGesture({
    required this.controller,
    this.effectColor = const Color.fromRGBO(128, 128, 128, 0.25),
    this.edgeZoneRatio = 0.2,
    this.zoomSensitivity = 40,
    super.key,
  });

  /// Map controller to control zoom.
  final NekonataMapController controller;

  /// The color of the visual zoom effect.
  final Color effectColor;

  /// The ratio of the edge zone width to the screen width.
  final double edgeZoneRatio;

  /// The sensitivity of the zoom effect.
  ///
  /// The higher the value, the less sensitive it is.
  final double zoomSensitivity;

  @override
  State<EdgeZoomGesture> createState() => _EdgeZoomGestureState();
}

@immutable
class _ZoomEffectData {
  const _ZoomEffectData({
    required this.tappingPosition,
    required this.isLeftSide,
  });

  final Offset tappingPosition;
  final bool isLeftSide;

  _ZoomEffectData copyWith({Offset? tappingPosition, bool? isLeftSide}) {
    return _ZoomEffectData(
      tappingPosition: tappingPosition ?? this.tappingPosition,
      isLeftSide: isLeftSide ?? this.isLeftSide,
    );
  }
}

class _EdgeZoomGestureState extends State<EdgeZoomGesture> {
  bool _isZooming = false;
  double? _initialZoom;
  double? _currentZoom;
  double? _startDragY;

  final ValueNotifier<_ZoomEffectData?> _zoomEffectNotifier = ValueNotifier(
    null,
  );

  @override
  void dispose() {
    _zoomEffectNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        _buildEdgeZoneAlignment(Alignment.centerLeft),
        _buildEdgeZoneAlignment(Alignment.centerRight),
        Positioned.fill(
          child: IgnorePointer(
            child: ValueListenableBuilder<_ZoomEffectData?>(
              valueListenable: _zoomEffectNotifier,
              builder: (context, zoomEffectData, child) {
                if (zoomEffectData == null) return const SizedBox.shrink();
                return CustomPaint(
                  painter: _EdgeZoomEffectPainter(
                    isLeftSide: zoomEffectData.isLeftSide,
                    tappingPosition: zoomEffectData.tappingPosition,
                    color: widget.effectColor,
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEdgeZoneAlignment(Alignment alignment) {
    final screenSize = MediaQuery.sizeOf(context);
    final edgeWidth = screenSize.width * widget.edgeZoneRatio;
    return Align(
      alignment: alignment,
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onVerticalDragStart: _onVerticalDragStart,
        onVerticalDragUpdate: _onVerticalDragUpdate,
        onVerticalDragEnd: _onVerticalDragEnd,
        onVerticalDragCancel: _onVerticalDragCancel,
        child: SizedBox(height: screenSize.height, width: edgeWidth),
      ),
    );
  }

  Future<void> _onVerticalDragStart(DragStartDetails details) async {
    final dx = details.localPosition.dx;
    if (_isInEdgeZone(dx)) {
      final renderBox = context.findRenderObject()! as RenderBox;
      final localPosition = renderBox.globalToLocal(details.globalPosition);

      _isZooming = true;
      _zoomEffectNotifier.value = _ZoomEffectData(
        tappingPosition: localPosition,
        isLeftSide: localPosition.dx < MediaQuery.sizeOf(context).width / 2,
      );
      _startDragY = details.localPosition.dy;
      _initialZoom = await widget.controller.zoom;
      _currentZoom = _initialZoom;
    }
  }

  void _onVerticalDragUpdate(DragUpdateDetails details) {
    if (_isZooming) {
      _updateZoom(details);
      final renderBox = context.findRenderObject()! as RenderBox;
      final localPosition = renderBox.globalToLocal(details.globalPosition);
      _zoomEffectNotifier.value = _zoomEffectNotifier.value?.copyWith(
        tappingPosition: localPosition,
      );
    }
  }

  void _updateZoom(DragUpdateDetails details) {
    if (_startDragY == null || _initialZoom == null) return;

    final dy = details.localPosition.dy;
    final deltaY = dy - _startDragY!;
    final zoomDelta = deltaY / widget.zoomSensitivity;
    _currentZoom = _initialZoom! + zoomDelta;
    widget.controller.moveCamera(zoom: _currentZoom, animated: false);
  }

  void _onVerticalDragEnd(DragEndDetails details) {
    _isZooming = false;
    _zoomEffectNotifier.value = null;
  }

  void _onVerticalDragCancel() {
    _isZooming = false;
    _zoomEffectNotifier.value = null;
  }

  bool _isInEdgeZone(double dx) {
    final width = MediaQuery.sizeOf(context).width;
    final edge = width * widget.edgeZoneRatio;
    return dx < edge || dx > width - edge;
  }
}

class _EdgeZoomEffectPainter extends CustomPainter {
  const _EdgeZoomEffectPainter({
    required this.tappingPosition,
    required this.color,
    required this.isLeftSide,
  });

  final Offset tappingPosition;
  final Color color;
  final bool isLeftSide;

  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = color
          ..style = PaintingStyle.fill;
    final edgeX = isLeftSide ? 0.0 : size.width;
    final top = Offset(edgeX, 0);
    final bottom = Offset(edgeX, size.height);
    final path =
        Path()
          ..moveTo(bottom.dx, bottom.dy)
          ..conicTo(tappingPosition.dx, tappingPosition.dy, top.dx, top.dy, 4)
          ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _EdgeZoomEffectPainter oldDelegate) {
    return oldDelegate.tappingPosition != tappingPosition ||
        oldDelegate.color != color ||
        oldDelegate.isLeftSide != isLeftSide;
  }
}
