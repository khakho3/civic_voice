import 'package:flutter/material.dart';

/// Shared native map style follows the selected app theme, including previews.
/// Returning null restores Google's normal light map without moving its camera.
abstract final class AppMapStyle {
  static String? of(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? dark : null;

  static const String dark = r'''[
  {
    "elementType": "geometry",
    "stylers": [
      {
        "color": "#202622"
      }
    ]
  },
  {
    "elementType": "labels.text.fill",
    "stylers": [
      {
        "color": "#d5dbd2"
      }
    ]
  },
  {
    "elementType": "labels.text.stroke",
    "stylers": [
      {
        "color": "#202622"
      }
    ]
  },
  {
    "featureType": "road",
    "elementType": "geometry",
    "stylers": [
      {
        "color": "#424a43"
      }
    ]
  },
  {
    "featureType": "road",
    "elementType": "geometry.stroke",
    "stylers": [
      {
        "color": "#181d19"
      }
    ]
  },
  {
    "featureType": "road.highway",
    "elementType": "geometry",
    "stylers": [
      {
        "color": "#635b3e"
      }
    ]
  },
  {
    "featureType": "poi",
    "elementType": "geometry",
    "stylers": [
      {
        "color": "#29352b"
      }
    ]
  },
  {
    "featureType": "poi.park",
    "elementType": "geometry",
    "stylers": [
      {
        "color": "#233b2d"
      }
    ]
  },
  {
    "featureType": "water",
    "elementType": "geometry",
    "stylers": [
      {
        "color": "#152d3c"
      }
    ]
  },
  {
    "featureType": "water",
    "elementType": "labels.text.fill",
    "stylers": [
      {
        "color": "#9bbccc"
      }
    ]
  }
]''';
}
