
import 'nekonata_map_platform_interface.dart';

class NekonataMap {
  Future<String?> getPlatformVersion() {
    return NekonataMapPlatform.instance.getPlatformVersion();
  }
}
