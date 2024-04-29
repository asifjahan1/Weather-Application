// ignore_for_file: unused_local_variable, unused_element, unnecessary_string_interpolations, unused_field

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:weather_application/Model/weather_data.dart';
import 'package:intl/intl.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with WidgetsBindingObserver {
  Position? _position;
  WeatherData? _weatherData;
  Map<String, dynamic> _forecastMap = {};
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
      return 'Partly Cloud';
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
    WidgetsBinding.instance.removeObserver(this);
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
        "https://api.openweathermap.org/data/2.5/weather?lat=23.7069417&lon=90.4207752&units=metric&appid=f92bf340ade13c087f6334ed434f9761&fbclid=IwAR0vlebaouEmURClRdtuWEg7qeBOdbDxmQ5HM9JDJL_mj5uDS7xqy4kCGTQ";
    String forecastUrl =
        "https://api.openweathermap.org/data/2.5/forecast?lat=23.7069417&lon=90.4207752&units=metric&appid=f92bf340ade13c087f6334ed434f9761&fbclid=IwAR0vlebaouEmURClRdtuWEg7qeBOdbDxmQ5HM9JDJL_mj5uDS7xqy4kCGTQ";

    try {
      final http.Response weatherResponse =
          await http.get(Uri.parse(weatherUrl));
      final http.Response forecastResponse =
          await http.get(Uri.parse(forecastUrl));

      _weatherData = WeatherData.fromJson(jsonDecode(weatherResponse.body));
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
          _locationName = city.isNotEmpty ? city : _weatherData!.name;
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
        title: const Text('Error'),
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
              _buildLocationInfo(),
              const SizedBox(height: 8),
              _buildWeatherInfo(),
              const SizedBox(height: 25),

              // weather data fetching
              _buildWeatherFetching(),
              const SizedBox(height: 8),
              _buildWeatherCondition(),

              const SizedBox(height: 20),

              // 3rd part forecasting
              //
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  GestureDetector(
                    onTap: () {
                      // fetchDataFromForecastURL();
                    },
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        backgroundColor: Colors.white.withOpacity(0.135),
                        side: const BorderSide(color: Colors.transparent),
                      ),
                      onPressed: () {},
                      child: const Text(
                        'Today',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                  const SizedBox(width: 9),
                  OutlinedButton(
                    onPressed: () {},
                    style: OutlinedButton.styleFrom(
                      backgroundColor: const Color.fromARGB(255, 103, 128, 210),
                      side: const BorderSide(color: Colors.transparent),
                    ),
                    child: const Text(
                      'Next Days',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              _buildHourlyForecast(),

              // Sunrise and Sunset Part
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHourlyForecast() {
    return SizedBox(
      height: 150,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount:
              _forecastMap['list'] != null ? _forecastMap['list'].length : 0,
          itemBuilder: (BuildContext context, int index) {
            var forecast = _forecastMap['list'][index];
            return _buildHourlyForecastItem(forecast, index);
          },
        ),
      ),
    );
  }

  Widget _buildHourlyForecastItem(dynamic forecast, int index) {
    // Calculate the forecast time based on the current time and index
    DateTime currentTime = DateTime.now();
    DateTime forecastTime = currentTime.add(Duration(hours: index));
    // DateTime forecastTime =
    //     DateTime.fromMillisecondsSinceEpoch(forecast['dt'] * 1000);
    // bool isAM = forecastTime.hour < 12;
    // String time =
    //     '${forecastTime.hour % 12 == 0 ? 12 : forecastTime.hour % 12}${isAM ? 'AM' : 'PM'}';

    // Format the forecast time as desired (e.g., 1:00 AM, 2:00 AM, etc.)
    String formattedTime = DateFormat('ha').format(forecastTime);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            formattedTime, // Display the formatted forecast time
            style: const TextStyle(color: Colors.white),
          ),
          const SizedBox(height: 10),
          Image.asset(
            // Use appropriate weather icon based on forecast
            getWeatherImage(forecast['weather'][0]['main']),
            width: 40,
            height: 40,
          ),
          const SizedBox(height: 10),
          Text(
            '${forecast['main']['temp'].toInt()}°',
            style: const TextStyle(color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationInfo() {
    return Row(
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
    );
  }

  Widget _buildWeatherInfo() {
    return Column(
      children: [
        if (_position != null && _weatherData != null)
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
              if (_weatherData!.name.isNotEmpty)
                Text(
                  _weatherData!.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
            ],
          ),
      ],
    );
  }

  Widget _buildWeatherFetching() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          width: 100,
          height: 100,
          child: _weatherData != null && _weatherData!.weather.isNotEmpty
              ? Image.asset(
                  getWeatherImage(_weatherData!.weather[0].main),
                  fit: BoxFit.cover,
                )
              : const SizedBox(), // Display an empty SizedBox if data is not available
        ),
        const SizedBox(
          width: 5,
        ), // Spacing between image and temperature
        // Temperature
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                if (_weatherData != null)
                  Text(
                    '${_weatherData!.main.temp.toInt()}°',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 80,
                    ),
                  )
                else
                  const CircularProgressIndicator(color: Colors.white),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildWeatherCondition() {
    bool isNightTime = isNight(DateTime.now());

    return Text(
      _weatherData != null
          ? '${getWeatherConditionText(_weatherData!.main.temp.toInt(), isNightTime)} - H:${_weatherData!.main.tempMax.toInt()}° L:${_weatherData!.main.tempMin.toInt()}°'
          : 'Weather data not available',
      style: const TextStyle(
        color: Colors.white,
        fontSize: 17,
        fontWeight: FontWeight.bold,
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
