import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

const _licenseAssets = {
  'Schibsted Grotesk': 'assets/fonts/schibsted_grotesk/OFL.txt',
  'Literata': 'assets/fonts/literata/OFL.txt',
  'IBM Plex Mono': 'assets/fonts/ibm_plex_mono/OFL.txt',
};

/// Registers the OFL license of each bundled font family.
void registerFontLicenses() {
  LicenseRegistry.addLicense(() async* {
    for (final MapEntry(key: family, value: asset) in _licenseAssets.entries) {
      yield LicenseEntryWithLineBreaks([
        family,
      ], await rootBundle.loadString(asset));
    }
  });
}
