// ignore_for_file: unused_local_variable, unused_element, unnecessary_string_interpolations, unused_field

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State createState() => _HomePageState();
}

class _HomePageState extends State with WidgetsBindingObserver {
  Position? _position;
  Map<String, dynamic> _weatherMap = {};
  late Map<String, dynamic> _forecastMap;
  late String _locationName = '';
  late String _areaName = '';
  late final bool _nightTime = false;

  String getTimeOfDay(DateTime currentTime) {
    int hour = currentTime.hour;
    return (hour >= 6 && hour < 18) ? 'Day' : 'Night';
  }

  String getWeatherCondition(int temperature) {
    if (temperature < 10) {
      return 'Cloudy';
    } else if (temperature >= 10 && temperature < 25) {
      return 'Partly Cloudy';
    } else {
      return 'Sunny';
    }
  }

  bool isDayTime() {
    DateTime now = DateTime.now();
    int hour = now.hour;
    return hour >= 6 && hour < 18;
  }

  String getWeatherConditionText(int temperature, bool isNight) {
    String weatherCondition = getWeatherCondition(temperature);
    String timeOfDay = isNight ? 'Night' : 'Day';
    return '$timeOfDay';
  }

  bool isNight(DateTime time) {
    int hour = time.hour;
    return hour < 6 || hour > 18;
  }

  String getWeatherImage(String weatherCondition) {
    if (isDayTime()) {
      switch (weatherCondition) {
        case 'Rain':
          return 'assets/rainy.png';
        case 'Clouds':
          return 'assets/partly_cloud.png';
        case 'Thunder':
          return 'assets/day_thunder.png';
        case 'Moderate':
          return 'assets/moderate.png';
        default:
          return 'assets/sunny.png';
      }
    } else {
      switch (weatherCondition) {
        case 'Night fog':
          return 'assets/night-fog.png';
        case 'Rainy':
          return 'assets/rainy.png';
        default:
          return 'assets/night.png';
      }
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _determinePosition();
    DateTime currentTime = DateTime.now();
    String timeOfDay = getTimeOfDay(currentTime);
  }

  @override
  void dispose() {
    WidgetsBinding.instance!.removeObserver(this);
    super.dispose();
  }

  Future<void> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _showErrorDialog('Location services are disabled.');
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        _showErrorDialog('Location permissions are denied.');
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      _showErrorDialog(
          'Location permissions are permanently denied, we cannot request permissions.');
      return;
    }

    try {
      _position = await Geolocator.getCurrentPosition();
      await _getLocationName(_position!.latitude, _position!.longitude);
      await _getAreaName(_position!.latitude, _position!.longitude);
      _fetchWeatherData();
    } catch (e) {
      _showErrorDialog('Error fetching location: $e');
    }
  }

  Future<void> _fetchWeatherData() async {
    const String apiKey =
        'IwAR0vlebaouEmURClRdtuWEg7qeBOdbDxmQ5HM9JDJL_mj5uDS7xqy4kCGTQ';
    final double latitude = _position!.latitude;
    final double longitude = _position!.longitude;

    String weatherUrl =
        "https://api.openweathermap.org/data/2.5/weather?lat=$latitude&lon=$longitude&units=metric&appid=f92bf340ade13c087f6334ed434f9761&fbclid=IwAR0vlebaouEmURClRdtuWEg7qeBOdbDxmQ5HM9JDJL_mj5uDS7xqy4kCGTQ";
    String forecastUrl =
        "https://api.openweathermap.org/data/2.5/forecast?lat=$latitude&lon=$longitude&units=metric&appid=f92bf340ade13c087f6334ed434f9761&fbclid=IwAR0vlebaouEmURClRdtuWEg7qeBOdbDxmQ5HM9JDJL_mj5uDS7xqy4kCGTQ";

    try {
      final http.Response weatherResponse =
          await http.get(Uri.parse(weatherUrl));
      final http.Response forecastResponse =
          await http.get(Uri.parse(forecastUrl));

      _weatherMap = Map<String, dynamic>.from(jsonDecode(weatherResponse.body));
      _forecastMap =
          Map<String, dynamic>.from(jsonDecode(forecastResponse.body));

      setState(() {});
    } catch (e) {
      _showErrorDialog('Error fetching weather data: $e');
    }
  }

  Future<void> _getAreaName(double latitude, double longitude) async {
    try {
      List<Placemark> placemarks =
          await placemarkFromCoordinates(latitude, longitude);
      if (placemarks.isNotEmpty) {
        Placemark placemark = placemarks[0];
        String region = placemark.administrativeArea ?? placemark.country ?? '';
        setState(() {
          _areaName = region;
        });
      }
    } catch (e) {
      print('Error getting region name: $e');
    }
  }

  Future<void> _getLocationName(double latitude, double longitude) async {
    try {
      List<Placemark> placemarks =
          await placemarkFromCoordinates(latitude, longitude);
      if (placemarks.isNotEmpty) {
        Placemark placemark = placemarks[0];
        String city = placemark.locality ??
            placemark.subAdministrativeArea ??
            placemark.administrativeArea ??
            '';
        setState(() {
          _locationName = city.isNotEmpty ? city : _weatherMap['name'];
        });
      }
    } catch (e) {
      print('Error getting location name: $e');
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Flexible(
      child: Scaffold(
        backgroundColor: const Color(0xFF738BE3),
        body: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (_locationName.isNotEmpty)
                    Text(
                      _locationName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              if (_position != null)
                Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Stack(
                          alignment: Alignment.center,
                          children: [
                            Image.asset('assets/location.png'),
                            Image.asset('assets/dot.png'),
                          ],
                        ),
                        const SizedBox(width: 6),
                        if (_weatherMap != null &&
                            _weatherMap.containsKey('name'))
                          Text(
                            _weatherMap['name'],
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              const SizedBox(height: 25),

              // frame 2 er part eidik theke shuru
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Image asset
                  Container(
                    width: 100, // Adjust width as needed
                    height: 100, // Adjust height as needed
                    child: _weatherMap != null &&
                            _weatherMap['weather'] != null &&
                            _weatherMap['weather'].isNotEmpty
                        ? Image.asset(
                            getWeatherImage(_weatherMap['weather'][0]['main']),
                            fit: BoxFit.cover,
                          )
                        : SizedBox(), // Display an empty SizedBox if data is not available
                  ),
                  const SizedBox(
                    width: 20,
                  ), // Spacing between image and temperature
                  // Temperature
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _weatherMap != null &&
                                _weatherMap['main'] != null &&
                                _weatherMap['main']['temp'] != null
                            ? '${_weatherMap['main']['temp'].toInt()}°'
                            : 'N/A', // Display 'N/A' if temperature data is not available
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 80,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              Text(
                _weatherMap != null &&
                        _weatherMap.containsKey('main') &&
                        _weatherMap['main'] != null &&
                        _weatherMap['main']['temp'] != null &&
                        _weatherMap['main']['temp_max'] != null &&
                        _weatherMap['main']['temp_min'] != null
                    ? '${getWeatherConditionText(_weatherMap['main']['temp'].toInt(), _nightTime)} - H: ${_weatherMap['main']['temp_max'].toInt()}°, L: ${_weatherMap['main']['temp_min'].toInt()}°'
                    : 'Weather data not available',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _determinePosition();
    }
  }
}
