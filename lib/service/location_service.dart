import 'dart:developer';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service to handle user location detection and country preferences
/// Provides location-based news filtering capabilities
class LocationService extends ChangeNotifier {
  static final LocationService instance = LocationService._init();
  LocationService._init();

  Position? _currentPosition;
  String? _currentCountry;
  String? _currentCountryCode;
  List<String> _preferredCountries = [];
  bool _isLoading = false;
  String? _error;
  bool _locationPermissionGranted = false;

  // Getters
  Position? get currentPosition => _currentPosition;
  String? get currentCountry => _currentCountry;
  String? get currentCountryCode => _currentCountryCode;
  List<String> get preferredCountries => List.unmodifiable(_preferredCountries);
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get locationPermissionGranted => _locationPermissionGranted;
  bool get hasLocation => _currentCountry != null;

  /// Initialize location service and load preferences
  Future<void> initialize() async {
    await _loadPreferences();
    await _checkLocationPermission();
  }

  /// Load saved country preferences from local storage
  Future<void> _loadPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _preferredCountries = prefs.getStringList('preferred_countries') ?? [];
      _currentCountry = prefs.getString('current_country');
      _currentCountryCode = prefs.getString('current_country_code');
      notifyListeners();
      log('📍 Loaded location preferences: $_preferredCountries');
    } catch (e) {
      log('⚠️ Error loading location preferences: $e');
    }
  }

  /// Save country preferences to local storage
  Future<void> _savePreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('preferred_countries', _preferredCountries);
      if (_currentCountry != null) {
        await prefs.setString('current_country', _currentCountry!);
      }
      if (_currentCountryCode != null) {
        await prefs.setString('current_country_code', _currentCountryCode!);
      }
      log('💾 Saved location preferences');
    } catch (e) {
      log('⚠️ Error saving location preferences: $e');
    }
  }

  /// Check if location permission is granted
  Future<bool> _checkLocationPermission() async {
    try {
      final permission = await Geolocator.checkPermission();
      _locationPermissionGranted = permission == LocationPermission.always ||
          permission == LocationPermission.whileInUse;
      return _locationPermissionGranted;
    } catch (e) {
      log('⚠️ Error checking location permission: $e');
      return false;
    }
  }

  /// Request location permission from user
  Future<bool> requestLocationPermission() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _error = 'Location permission denied';
          _locationPermissionGranted = false;
          notifyListeners();
          log('⚠️ Location permission denied');
          return false;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _error = 'Location permission permanently denied. Please enable in settings.';
        _locationPermissionGranted = false;
        notifyListeners();
        log('⚠️ Location permission permanently denied');
        return false;
      }

      _locationPermissionGranted = true;
      _error = null;
      notifyListeners();
      log('✅ Location permission granted');
      return true;
    } catch (e) {
      _error = e.toString();
      _locationPermissionGranted = false;
      notifyListeners();
      log('⚠️ Error requesting location permission: $e');
      return false;
    }
  }

  /// Get current device location and detect country
  Future<bool> detectCurrentLocation() async {
    if (!_locationPermissionGranted) {
      final granted = await requestLocationPermission();
      if (!granted) return false;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      log('📍 Detecting current location...');

      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Location services are disabled. Please enable in settings.');
      }

      // Get current position
      _currentPosition = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 15),
        ),
      );

      log('✅ Location detected: ${_currentPosition!.latitude}, ${_currentPosition!.longitude}');

      // Reverse geocode to get country
      final placemarks = await placemarkFromCoordinates(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
      );

      if (placemarks.isNotEmpty) {
        final placemark = placemarks.first;
        _currentCountry = placemark.country;
        _currentCountryCode = placemark.isoCountryCode;

        // Automatically add detected country to preferences if not already there
        if (_currentCountry != null && !_preferredCountries.contains(_currentCountry!)) {
          _preferredCountries.insert(0, _currentCountry!);
          await _savePreferences();
        }

        log('✅ Country detected: $_currentCountry ($_currentCountryCode)');
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        throw Exception('Could not determine country from location');
      }
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      log('⚠️ Error detecting location: $e');
      return false;
    }
  }

  /// Add a country to preferred countries list
  Future<void> addPreferredCountry(String countryName) async {
    if (!_preferredCountries.contains(countryName)) {
      _preferredCountries.add(countryName);
      await _savePreferences();
      notifyListeners();
      log('➕ Added preferred country: $countryName');
    }
  }

  /// Remove a country from preferred countries list
  Future<void> removePreferredCountry(String countryName) async {
    if (_preferredCountries.contains(countryName)) {
      _preferredCountries.remove(countryName);
      await _savePreferences();
      notifyListeners();
      log('➖ Removed preferred country: $countryName');
    }
  }

  /// Set multiple preferred countries at once
  Future<void> setPreferredCountries(List<String> countries) async {
    _preferredCountries = List.from(countries);
    await _savePreferences();
    notifyListeners();
    log('📝 Updated preferred countries: $_preferredCountries');
  }

  /// Clear all location data and preferences
  Future<void> clearLocationData() async {
    _currentPosition = null;
    _currentCountry = null;
    _currentCountryCode = null;
    _preferredCountries.clear();
    _error = null;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('preferred_countries');
    await prefs.remove('current_country');
    await prefs.remove('current_country_code');

    notifyListeners();
    log('🧹 Cleared all location data');
  }

  /// Check if a country is in preferred list
  bool isCountryPreferred(String countryName) {
    return _preferredCountries.contains(countryName);
  }

  /// Open app settings for location permission
  Future<bool> openLocationSettings() async {
    try {
      return await Geolocator.openLocationSettings();
    } catch (e) {
      log('⚠️ Error opening location settings: $e');
      return false;
    }
  }

  /// Open app settings for permission
  Future<bool> openAppSettings() async {
    try {
      return await Geolocator.openAppSettings();
    } catch (e) {
      log('⚠️ Error opening app settings: $e');
      return false;
    }
  }
}
