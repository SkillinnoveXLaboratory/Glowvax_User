import 'package:geolocator/geolocator.dart';

import '../logging/app_logger.dart';

class LocationService {
  LocationService._();

  static const List<String> supportedCities = [
    'Mumbai',
    'Hyderabad',
    'Bangalore',
    'Delhi',
    'Chennai',
    'Pune',
    'Kolkata',
  ];

  static Future<Position?> getCurrentPosition() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        AppLogger.warning('Location services are disabled.');
        return null;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          AppLogger.warning('Location permissions are denied');
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        AppLogger.warning('Location permissions are permanently denied');
        return null;
      }

      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 8),
        ),
      );
    } catch (e) {
      AppLogger.warning('Error fetching location: $e');
      return null;
    }
  }

  static String estimateCityFromCoords(double lat, double lng) {
    if (lat >= 18.8 && lat <= 19.3 && lng >= 72.7 && lng <= 73.1)
      return 'Mumbai';
    if (lat >= 17.2 && lat <= 17.6 && lng >= 78.2 && lng <= 78.7)
      return 'Hyderabad';
    if (lat >= 12.8 && lat <= 13.2 && lng >= 77.4 && lng <= 77.8)
      return 'Bangalore';
    if (lat >= 28.4 && lat <= 28.9 && lng >= 76.9 && lng <= 77.4)
      return 'Delhi';
    if (lat >= 12.9 && lat <= 13.2 && lng >= 80.1 && lng <= 80.4)
      return 'Chennai';
    if (lat >= 18.4 && lat <= 18.7 && lng >= 73.7 && lng <= 74.0) return 'Pune';
    if (lat >= 22.4 && lat <= 22.7 && lng >= 88.2 && lng <= 88.5)
      return 'Kolkata';
    return 'Mumbai';
  }
}
