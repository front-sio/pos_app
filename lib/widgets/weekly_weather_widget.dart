import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:sales_app/utils/weather_service.dart';
import 'package:intl/intl.dart';

class WeeklyWeatherWidget extends StatefulWidget {
  const WeeklyWeatherWidget({super.key});

  @override
  State<WeeklyWeatherWidget> createState() => _WeeklyWeatherWidgetState();
}

class _WeeklyWeatherWidgetState extends State<WeeklyWeatherWidget> {
  final WeatherService _weatherService = WeatherService();
  final ScrollController _scrollController = ScrollController();
  List<Map<String, dynamic>> _forecast = [];
  bool _loading = true;
  String _location = '';
  String _error = '';
  bool _canScrollLeft = false;
  bool _canScrollRight = false;

  @override
  void initState() {
    super.initState();
    _loadWeather();
    _scrollController.addListener(_updateScrollButtons);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_updateScrollButtons);
    _scrollController.dispose();
    super.dispose();
  }

  void _updateScrollButtons() {
    setState(() {
      _canScrollLeft = _scrollController.offset > 0;
      _canScrollRight = _scrollController.offset < _scrollController.position.maxScrollExtent;
    });
  }

  void _scrollLeft() {
    _scrollController.animateTo(
      _scrollController.offset - 200,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  void _scrollRight() {
    _scrollController.animateTo(
      _scrollController.offset + 200,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  Future<void> _loadWeather() async {
    try {
      final position = await _weatherService.getCurrentLocation();
      if (position != null) {
        final city = await _weatherService.getCityName(
          position.latitude,
          position.longitude,
        );
        final forecast = await _weatherService.getWeeklyForecast(
          position.latitude,
          position.longitude,
        );

        if (mounted) {
          setState(() {
            _location = city;
            _forecast = forecast;
            _loading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _error = 'Location permission denied';
            _loading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load weather';
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.wb_sunny,
                  color: Theme.of(context).primaryColor,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    'Weekly Weather',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (_location.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  Flexible(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _location,
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).primaryColor,
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                  ),
                ],
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.refresh, size: 20),
                  onPressed: () {
                    setState(() {
                      _loading = true;
                      _error = '';
                    });
                    _loadWeather();
                  },
                  tooltip: 'Refresh',
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_loading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(20.0),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (_error.isNotEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    children: [
                      Icon(Icons.error_outline, size: 48, color: Colors.grey[400]),
                      const SizedBox(height: 8),
                      Text(
                        _error,
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              )
            else if (_forecast.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Text(
                    'No weather data available',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ),
              )
            else
              Stack(
                alignment: Alignment.center,
                children: [
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 140),
                    child: ListView.builder(
                      controller: _scrollController,
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      itemCount: _forecast.length,
                      itemBuilder: (context, index) {
                        final weather = _forecast[index];
                        final date = weather['date'] as DateTime;
                        final dayName = DateFormat('EEE').format(date);
                        final temp = (weather['temp'] as double).toStringAsFixed(0);
                        final icon = _weatherService.getWeatherIcon(weather['condition'] as String);

                        final isToday = date.day == DateTime.now().day &&
                            date.month == DateTime.now().month;

                        // Responsive width
                        final screenWidth = MediaQuery.of(context).size.width;
                        final cardWidth = screenWidth < 600 ? 80.0 : 90.0;

                        return Container(
                          width: cardWidth,
                          margin: const EdgeInsets.only(right: 12),
                          decoration: BoxDecoration(
                            gradient: isToday
                                ? LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      Theme.of(context).primaryColor,
                                      Theme.of(context).primaryColor.withOpacity(0.7),
                                    ],
                              )
                            : null,
                        color: isToday ? null : Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isToday
                              ? Theme.of(context).primaryColor
                              : Colors.grey[300]!,
                          width: 1,
                        ),
                      ),
                      child: Padding(
                        padding: EdgeInsets.all(screenWidth < 600 ? 8.0 : 12.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              isToday ? 'Today' : dayName,
                              style: TextStyle(
                                fontSize: screenWidth < 600 ? 11 : 13,
                                fontWeight: isToday ? FontWeight.bold : FontWeight.w600,
                                color: isToday ? Colors.white : Colors.grey[700],
                              ),
                            ),
                            SizedBox(height: screenWidth < 600 ? 6 : 8),
                            Text(
                              icon,
                              style: TextStyle(fontSize: screenWidth < 600 ? 28 : 32),
                            ),
                            SizedBox(height: screenWidth < 600 ? 6 : 8),
                            Text(
                              '$temp°C',
                              style: TextStyle(
                                fontSize: screenWidth < 600 ? 14 : 16,
                                fontWeight: FontWeight.bold,
                                color: isToday ? Colors.white : Colors.grey[800],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              // Scroll arrows for web
              if (kIsWeb && _forecast.length > 4) ...[
                if (_canScrollLeft)
                  Positioned(
                    left: 0,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.9),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 4,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.chevron_left),
                        onPressed: _scrollLeft,
                        tooltip: 'Scroll left',
                      ),
                    ),
                  ),
                if (_canScrollRight)
                  Positioned(
                    right: 0,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.9),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 4,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.chevron_right),
                        onPressed: _scrollRight,
                        tooltip: 'Scroll right',
                      ),
                    ),
                  ),
              ],
            ],
          ),
          ],
        ),
      ),
    );
  }
}
