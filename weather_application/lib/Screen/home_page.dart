// ignore_for_file: unused_local_variable, unused_element, unnecessary_string_interpolations, unused_field

import 'dart:async';
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
  late Timer _timer;

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

  String getWeatherImage(String weatherCondition, bool isNight) {
    if (!isNight) {
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
          return 'assets/night-fog.png';
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(minutes: 1), (timer) {
      // Call a function to fetch updated data here
      // For example, _fetchWeatherData();
      setState(() {
        // Update any state variables here if needed
      });
    });
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
            children: [
              Container(
                color: const Color(0xFF738BE3),
                child: Column(
                  children: [
                    _buildLocationInfo(),
                    const SizedBox(height: 8),
                    _buildWeatherInfo(),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  child: SafeArea(
                    child: Column(
                      children: [
                        const SizedBox(height: 10),

                        // weather data fetching
                        _buildWeatherFetching(),

                        const SizedBox(height: 8),
                        _buildWeatherCondition(),
                        //wind speed & humidity part
                        const SizedBox(height: 10),
                        _buildHumidityAndWindSpeed(),
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
                                  backgroundColor:
                                      Colors.white.withOpacity(0.135),
                                  side: const BorderSide(
                                      color: Colors.transparent),
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
                                backgroundColor:
                                    const Color.fromARGB(255, 103, 128, 210),
                                side:
                                    const BorderSide(color: Colors.transparent),
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
                        const SizedBox(height: 25),
                        Container(
                          width: MediaQuery.of(context).size.width * 1,
                          height: 300,
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.white,
                                Color.fromARGB(255, 0, 140, 255), // End color
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.elliptical(200, 100),
                              topRight: Radius.elliptical(200, 100),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHumidityAndWindSpeed() {
    if (_weatherData != null) {
      return Center(
        child: IntrinsicWidth(
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            padding: const EdgeInsets.all(10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Feels like',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 10),
                    Text(
                      'Humidity',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 10),
                    Text(
                      'Wind Speed',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 10),
                    Text(
                      'Pressure',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${_weatherData!.main.feelsLike.toInt()}°C',
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      '${_weatherData!.main.humidity.toInt()}%',
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      '${_weatherData!.wind.speed.toStringAsFixed(2)}Km/h',
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      '${(_weatherData!.main.pressure * 0.75006).toInt()} mmHg',
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    } else {
      return Container();
    }
  }

  Widget _buildHourlyForecast() {
    return SizedBox(
      height: 155,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _forecastMap['list'] != null
            ? _forecastMap['list'].length > 12
                ? 12
                : _forecastMap['list'].length
            : 0,
        itemBuilder: (BuildContext context, int index) {
          var forecast = _forecastMap['list'][index];
          return _buildHourlyForecastItem(forecast, index);
        },
      ),
    );
  }

  // new updated with image file
  //
  // Widget _buildHourlyForecast() {
  //   return SizedBox(
  //     height: 155,
  //     child: ListView.builder(
  //       scrollDirection: Axis.horizontal,
  //       itemCount: _forecastMap['list'] != null
  //           ? _forecastMap['list'].length > 12
  //               ? 12
  //               : _forecastMap['list'].length
  //           : 0,
  //       itemBuilder: (BuildContext context, int index) {
  //         if (index == 0) {
  //           return Column(
  //             children: [
  //               _buildHourlyForecastItem(_forecastMap['list'][index], index),
  //               const SizedBox(height: 3),
  //               _buildFirstItemContainer(),
  //             ],
  //           );
  //         } else {
  //           // Show hourly forecast item for other indices
  //           return _buildHourlyForecastItem(_forecastMap['list'][index], index);
  //         }
  //       },
  //     ),
  //   );
  // }

  // Widget _buildFirstItemContainer() {
  //   return Image.asset(
  //     'assets/Ellipse 1.png',
  //   );
  // }

  Widget _buildHourlyForecastItem(dynamic forecast, int index) {
    DateTime currentTime = DateTime.now();
    DateTime forecastTime = currentTime.add(Duration(hours: index));
    String formattedTime = DateFormat('ha').format(forecastTime);

    bool isNightTime = isNight(forecastTime);
    String weatherCondition = forecast['weather'][0]['main'];

    return ClipRRect(
      child: Container(
        width: 80,
        margin: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.125),
          borderRadius: BorderRadius.circular(50),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.all(15),
              child: Text(
                index == 0 ? 'Now' : formattedTime,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 5),
            Image.asset(
              getWeatherImage(weatherCondition, isNightTime),
              fit: BoxFit.cover,
              width: 55,
              height: 55,
            ),
            const SizedBox(height: 10),
            Text(
              '${forecast['main']['temp'].toInt()}°',
              style: TextStyle(
                color: isNightTime ? Colors.white : Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
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
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 100,
              height: 100,
              child: _weatherData != null && _weatherData!.weather.isNotEmpty
                  ? Image.asset(
                      getWeatherImage(
                        _weatherData!.weather[0].main,
                        isNight(DateTime.now()), // Pass day or night
                      ),
                      fit: BoxFit.cover,
                    )
                  : const SizedBox(),
            ),
            const SizedBox(
              width: 5,
            ),
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
        ),
      ],
    );
  }

  Widget _buildWeatherCondition() {
    bool isNightTime = isNight(DateTime.now());

    return Text(
      _weatherData != null
          ? '${_weatherData!.weather[0].main} - H:${_weatherData!.main.tempMax.toInt()}° L:${_weatherData!.main.tempMin.toInt()}°'
          : '',
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
