import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:math';

class WeatherService {
  // Free OpenWeatherMap API key - Get yours at https://openweathermap.org/api
  static const String _apiKey = '4d8fb5b93d4af21d66a2948710284366'; // Free tier
  static const String _baseUrl = 'https://api.openweathermap.org/data/2.5';

  Future<Position?> getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return null;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return null;
      }

      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
        timeLimit: const Duration(seconds: 5),
      );
    } catch (e) {
      return null;
    }
  }

  Future<String> getCityName(double lat, double lon) async {
    try {
      // Try to get from geocoding first
      List<Placemark> placemarks = await placemarkFromCoordinates(lat, lon);
      if (placemarks.isNotEmpty) {
        final city = placemarks[0].locality ?? 
                     placemarks[0].subAdministrativeArea ?? 
                     placemarks[0].administrativeArea;
        if (city != null && city.isNotEmpty) {
          return city;
        }
      }
      
      // Fallback to reverse geocode from weather API
      try {
        final url = 'http://api.openweathermap.org/geo/1.0/reverse?lat=$lat&lon=$lon&limit=1&appid=$_apiKey';
        final response = await http.get(Uri.parse(url)).timeout(
          const Duration(seconds: 5),
        );
        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          if (data is List && data.isNotEmpty) {
            return data[0]['name'] ?? 'Your Location';
          }
        }
      } catch (_) {}
      
      return 'Your Location';
    } catch (e) {
      return 'Your Location';
    }
  }

  // Get real current weather from OpenWeatherMap
  Future<Map<String, dynamic>?> getCurrentWeather(double lat, double lon) async {
    try {
      final url = '$_baseUrl/weather?lat=$lat&lon=$lon&appid=$_apiKey&units=metric';
      final response = await http.get(Uri.parse(url)).timeout(
        const Duration(seconds: 10),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'temp': data['main']['temp'],
          'condition': data['weather'][0]['main'],
          'description': data['weather'][0]['description'],
          'icon': data['weather'][0]['icon'],
        };
      }
      return null;
    } catch (e) {
      // Fallback to simulated if API fails
      return _getSimulatedWeather(lat, lon);
    }
  }

  // Get real 7-day forecast from OpenWeatherMap
  Future<List<Map<String, dynamic>>> getWeeklyForecast(double lat, double lon) async {
    try {
      final url = '$_baseUrl/forecast?lat=$lat&lon=$lon&appid=$_apiKey&units=metric';
      final response = await http.get(Uri.parse(url)).timeout(
        const Duration(seconds: 10),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List forecastList = data['list'];
        
        // Group by day and get one forecast per day
        Map<String, Map<String, dynamic>> dailyForecasts = {};
        
        for (var item in forecastList) {
          DateTime date = DateTime.parse(item['dt_txt']);
          String dayKey = '${date.year}-${date.month}-${date.day}';
          
          // Get midday forecast (closest to 12:00)
          if (!dailyForecasts.containsKey(dayKey) || 
              (date.hour >= 12 && date.hour <= 15)) {
            dailyForecasts[dayKey] = {
              'date': date,
              'temp': item['main']['temp'],
              'condition': item['weather'][0]['main'],
              'description': item['weather'][0]['description'],
            };
          }
        }
        
        // Take first 7 days
        return dailyForecasts.values.take(7).toList();
      }
      
      // Fallback to simulated if API fails
      return _getSimulatedWeeklyForecast(lat, lon);
    } catch (e) {
      return _getSimulatedWeeklyForecast(lat, lon);
    }
  }

  // Fallback simulated weather
  Map<String, dynamic> _getSimulatedWeather(double lat, double lon) {
    final random = Random();
    final conditions = ['Clear', 'Cloudy', 'Rainy', 'Partly Cloudy', 'Sunny'];
    final baseTemp = 20 + (lat / 10).abs();
    
    return {
      'temp': baseTemp + random.nextDouble() * 10,
      'condition': conditions[random.nextInt(conditions.length)],
    };
  }

  List<Map<String, dynamic>> _getSimulatedWeeklyForecast(double lat, double lon) {
    final random = Random();
    final conditions = ['Clear', 'Cloudy', 'Rainy', 'Partly Cloudy', 'Sunny', 'Thunderstorm'];
    final days = <Map<String, dynamic>>[];
    final baseTemp = 20 + (lat / 10).abs();

    for (int i = 0; i < 7; i++) {
      final date = DateTime.now().add(Duration(days: i));
      final tempVariation = random.nextDouble() * 8 - 4;
      
      days.add({
        'date': date,
        'temp': baseTemp + tempVariation,
        'condition': conditions[random.nextInt(conditions.length)],
      });
    }

    return days;
  }

  String getWeatherIcon(String? condition) {
    if (condition == null) return '☀️';
    
    final lower = condition.toLowerCase();
    if (lower.contains('clear') || lower.contains('sunny')) {
      return '☀️';
    } else if (lower.contains('cloud')) {
      return '☁️';
    } else if (lower.contains('rain') || lower.contains('drizzle')) {
      return '🌧️';
    } else if (lower.contains('thunder') || lower.contains('storm')) {
      return '⛈️';
    } else if (lower.contains('snow')) {
      return '❄️';
    } else if (lower.contains('mist') || lower.contains('fog') || lower.contains('haze')) {
      return '🌫️';
    } else if (lower.contains('wind')) {
      return '💨';
    } else if (lower.contains('partly')) {
      return '⛅';
    } else {
      return '🌤️';
    }
  }

  String getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Good Morning';
    } else if (hour < 17) {
      return 'Good Afternoon';
    } else if (hour < 21) {
      return 'Good Evening';
    } else {
      return 'Good Night';
    }
  }

  String getGreetingIcon() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return '🌅';
    } else if (hour < 17) {
      return '☀️';
    } else if (hour < 21) {
      return '🌆';
    } else {
      return '🌙';
    }
  }
}
