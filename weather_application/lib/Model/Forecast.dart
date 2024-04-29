import 'package:weather_application/Model/main_data.dart';
import 'package:weather_application/Model/weather.dart';

class Forecast {
  final DateTime dtTxt;
  final Main main;
  final List<Weather> weather;

  Forecast({
    required this.dtTxt,
    required this.main,
    required this.weather,
  });

  factory Forecast.fromJson(Map<String, dynamic> json) {
    return Forecast(
      dtTxt: DateTime.parse(json['dt_txt']),
      main: Main.fromJson(json['main']),
      weather: (json['weather'] as List)
          .map((item) => Weather.fromJson(item))
          .toList(),
    );
  }
}
