// =============================================================
// SafeStreet
// Zone UI Helper
//
// Pure, stateless helper functions used by any widget or screen
// that renders UnsafeZoneModel data.
//
// Modelled after alert_ui_helper.dart (Phase 11.1) and extracted
// here so that UnsafeZoneMapScreen and ReportUnsafeZoneSheet can
// share category labels without duplicating switch logic.
//
// Phase 12.4:
//   zoneCategoryLabel — human-readable chip / InfoWindow title.
//   zoneCategoryHue   — Google Maps marker hue angle (0–360).
//
// Architecture (Refinement 2, approved):
//   This file must NOT import google_maps_flutter.
//   It must NOT reference BitmapDescriptor in any form.
//   zoneCategoryHue returns a raw double; the caller is
//   responsible for passing it to
//   BitmapDescriptor.defaultMarkerWithHue(zoneCategoryHue(...)).
//
// All functions are top-level so they can be imported with a
// simple `import '../utils/zone_ui_helper.dart';`
// =============================================================

import '../models/unsafe_zone_model.dart';

// ---------------------------------------------------------------------------
// Category label
// ---------------------------------------------------------------------------

/// Returns a human-readable display label for [category].
///
/// Used as the chip label in [ReportUnsafeZoneSheet] and as the
/// [InfoWindow.title] on community zone markers in
/// [UnsafeZoneMapScreen].
///
/// Title-cased for UI display only. The enum value itself is passed
/// to [UnsafeZoneService] and stored in Firestore — no hardcoded
/// category strings appear in the write path.
String zoneCategoryLabel(UnsafeZoneCategory category) {
  switch (category) {
    case UnsafeZoneCategory.harassment:
      return 'Harassment';
    case UnsafeZoneCategory.theft:
      return 'Theft';
    case UnsafeZoneCategory.poorLighting:
      return 'Poor Lighting';
    case UnsafeZoneCategory.unsafePath:
      return 'Unsafe Path';
    case UnsafeZoneCategory.other:
      return 'Other';
  }
}

// ---------------------------------------------------------------------------
// Category hue
// ---------------------------------------------------------------------------

/// Returns the Google Maps marker hue angle for [category].
///
/// The returned [double] corresponds to the hue constants defined
/// in [BitmapDescriptor] (e.g. [BitmapDescriptor.hueRed] = 0.0).
/// This file deliberately does not import google_maps_flutter;
/// the caller constructs the descriptor:
///
/// ```dart
/// BitmapDescriptor.defaultMarkerWithHue(zoneCategoryHue(zone.category))
/// ```
///
/// Hue mapping:
///
/// | Category      | Hue (°) | Colour  |
/// |---------------|---------|---------|
/// | harassment    | 0.0     | Red     |
/// | theft         | 30.0    | Orange  |
/// | poorLighting  | 60.0    | Yellow  |
/// | unsafePath    | 210.0   | Azure   |
/// | other         | 270.0   | Violet  |
double zoneCategoryHue(UnsafeZoneCategory category) {
  switch (category) {
    case UnsafeZoneCategory.harassment:
      return 0.0; // BitmapDescriptor.hueRed
    case UnsafeZoneCategory.theft:
      return 30.0; // BitmapDescriptor.hueOrange
    case UnsafeZoneCategory.poorLighting:
      return 60.0; // BitmapDescriptor.hueYellow
    case UnsafeZoneCategory.unsafePath:
      return 210.0; // BitmapDescriptor.hueAzure
    case UnsafeZoneCategory.other:
      return 270.0; // BitmapDescriptor.hueViolet
  }
}
