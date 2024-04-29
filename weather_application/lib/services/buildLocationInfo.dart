// ignore_for_file: no_leading_underscores_for_local_identifiers, unused_element, unnecessary_null_comparison

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

Widget _buildLocationInfo() {
  late String _locationName = '';
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
  Position? _position;
  Map<String, dynamic> _weatherMap = {};
  return Column(
    children: [
      if (_position != null && _weatherMap.isNotEmpty)
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
            if (_weatherMap.containsKey('name'))
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
  );
}
