# nekonata_map

Wrapper of `MKMapView` and `MapView` with `GoogleMap`.

This can integrate platform maps.

Any images can use as map marker. Also you can use platform specific marker.

This package depends on latlong2.

## Getting Started

This project is a starting point for a Flutter
[plug-in package](https://flutter.dev/to/develop-plugins),
a specialized package that includes platform-specific implementation code for
Android and/or iOS.

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## How to Use

Check example app.

Just use `NekonataMap`

```dart
Scaffold(
    appBar: AppBar(title: const Text('Nekonata Map')),
    body: NekonataMap(
        latLng: LatLng(35.681236, 139.767125),
        onControllerCreated: (controller) => _controller = controller,
    ),
)
```

## Setup

### iOS

Nothing to do.

### Android

Insert meta data for Google API Key.

Same as [google_maps_flutter | Flutter package](https://pub.dev/packages/google_maps_flutter)

```xml
<meta-data android:name="com.google.android.geo.API_KEY"
    android:value="GOOGLE_API_KEY"/>
```

## Limitation

- Only image can be use as markers
  - If you want to use `Widget` as a marker, you have to convert it to image for first.
