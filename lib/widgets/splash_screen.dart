import 'package:flutter/material.dart';
import 'dart:async';
import 'package:sales_app/utils/weather_service.dart';

class SplashScreen extends StatefulWidget {
  final VoidCallback onComplete;

  const SplashScreen({super.key, required this.onComplete});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<Offset> _slideAnimation;
  
  final WeatherService _weatherService = WeatherService();
  String _greeting = '';
  String _greetingIcon = '';
  String _weatherIcon = '🌤️';
  String _location = '';
  double? _temperature;
  bool _loadingWeather = true;

  @override
  void initState() {
    super.initState();
    
    _controller = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.0, 0.5, curve: Curves.easeIn)),
    );

    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.0, 0.5, curve: Curves.elasticOut)),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.3, 0.8, curve: Curves.easeOut)),
    );

    _controller.forward();
    _loadGreetingAndWeather();
    
    // Navigate after 4 seconds
    Timer(const Duration(seconds: 4), () {
      if (mounted) {
        widget.onComplete();
      }
    });
  }

  Future<void> _loadGreetingAndWeather() async {
    setState(() {
      _greeting = _weatherService.getGreeting();
      _greetingIcon = _weatherService.getGreetingIcon();
    });

    try {
      final position = await _weatherService.getCurrentLocation();
      if (position != null) {
        final city = await _weatherService.getCityName(position.latitude, position.longitude);
        final weather = await _weatherService.getCurrentWeather(position.latitude, position.longitude);
        
        if (mounted) {
          setState(() {
            _location = city;
            if (weather != null) {
              _temperature = weather['temp'] as double;
              _weatherIcon = _weatherService.getWeatherIcon(weather['condition'] as String);
            }
            _loadingWeather = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _location = 'Location unavailable';
            _loadingWeather = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _location = 'Weather unavailable';
          _loadingWeather = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          color: Color.fromARGB(255, 5, 49, 107), // Solid soft blue
        ),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(flex: 2),
              
              // Greeting with icon
              FadeTransition(
                opacity: _fadeAnimation,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _greetingIcon,
                      style: const TextStyle(fontSize: 32),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      _greeting,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 20),
              
              
              // App Title
              SlideTransition(
                position: _slideAnimation,
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: Column(
                    children: [
                      const SizedBox(height: 8),
                      Text(
                        'Your Business, Simplified',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w400,
                          color: Colors.white.withOpacity(0.95),
                          letterSpacing: 0.8,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 10),
              
              // Animated Loading Indicator
              FadeTransition(
                opacity: _fadeAnimation,
                child: Column(
                  children: [
                    SizedBox(
                      width: 50,
                      height: 50,
                      child: CircularProgressIndicator(
                        strokeWidth: 3,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Loading...',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 13,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
              ),
              
              const Spacer(flex: 2),
              
              // Weather Info at bottom
              FadeTransition(
                opacity: _fadeAnimation,
                child: Container(
                  margin: const EdgeInsets.only(bottom: 40),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: _loadingWeather
                      ? Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Getting weather...',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.9),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        )
                      : Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _weatherIcon,
                              style: const TextStyle(fontSize: 24),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  _location,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                if (_temperature != null)
                                  Text(
                                    '${_temperature!.toStringAsFixed(1)}°C',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.95),
                                      fontSize: 11,
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
