import 'package:latlong2/latlong.dart';
import 'package:nekonata_map/nekonata_map_controller.dart';

/// Utility extension for [NekonataMapController].
extension NekonataMapControllerX on NekonataMapController {
  /// Sets the region of the map from a list of [LatLng].
  /// Calculates min and max latitude and longitude from the list of [LatLng]
  Future<void> setRegionFromLatLngList(
    List<LatLng> latLngList, {
    int paddingPx = 0,
  }) async {
    assert(latLngList.isNotEmpty, 'latLngList must not be empty');

    var minLat = double.infinity;
    var maxLat = -double.infinity;
    var minLng = double.infinity;
    var maxLng = -double.infinity;

    for (final latLng in latLngList) {
      if (latLng.latitude < minLat) minLat = latLng.latitude;
      if (latLng.latitude > maxLat) maxLat = latLng.latitude;
      if (latLng.longitude < minLng) minLng = latLng.longitude;
      if (latLng.longitude > maxLng) maxLng = latLng.longitude;
    }

    await setRegion(
      min: LatLng(minLat, minLng),
      max: LatLng(maxLat, maxLng),
      paddingPx: paddingPx,
    );
  }
}
