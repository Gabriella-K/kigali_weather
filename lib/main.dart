
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'weather.dart';

void main() {
  runApp(const KigaliWeatherApp());
}

class KigaliWeatherApp extends StatelessWidget {
  const KigaliWeatherApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Kigali Weather',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
        ),
        useMaterial3: true,
      ),
      home: const WeatherScreen(),
    );
  }
}

class WeatherScreen extends StatefulWidget {
  const WeatherScreen({super.key});

  @override
  State<WeatherScreen> createState() => _WeatherScreenState();
}

class _WeatherScreenState extends State<WeatherScreen> {
  City city = cities.first;

  Weather? weather;
  bool loading = true;
  bool offline = false;
  String? error;

  @override
  void initState() {
    super.initState();
    start();
  }

  // Lab 7: Remember the selected city.
  Future<void> start() async {
    final prefs = await SharedPreferences.getInstance();
    final savedCityName = prefs.getString('city');

    if (savedCityName != null) {
      for (final savedCity in cities) {
        if (savedCity.name == savedCityName) {
          city = savedCity;
          break;
        }
      }
    }

    if (!mounted) return;

    setState(() {
      loading = true;
    });

    await load();
  }

  // Labs 6 and 8: Fetch live weather and save it.
  // If the request fails, show an error and Retry button.
  Future<void> load() async {
    try {
      final result = await fetchWeather(city);

      final prefs = await SharedPreferences.getInstance();

      // Save the latest weather for this city.
      await prefs.setString(
        'weather_${city.name}',
        jsonEncode(result.toJson()),
      );

      if (!mounted) return;

      setState(() {
        weather = result;
        loading = false;
        offline = false;
        error = null;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        loading = false;
        offline = false;
        error =
        'Could not load the weather. Check your internet connection.';
      });
    }
  }

  // Lab 6: Change city.
  // Lab 7: Save the selected city.
  Future<void> selectCity(City newCity) async {
    if (newCity.name == city.name) return;

    setState(() {
      city = newCity;
      loading = true;
      offline = false;
      error = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('city', newCity.name);
    } catch (e) {
      // Continue loading weather even if saving the preference fails.
    }

    await load();
  }

  // Try loading the weather again.
  void retry() {
    setState(() {
      loading = true;
      offline = false;
      error = null;
    });

    load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${city.name} Weather'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: load,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Text(
                'Choose a city',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),

              // Lab 6: Four city selection chips.
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: cities.map((newCity) {
                  return ChoiceChip(
                    label: Text(newCity.name),
                    selected: city.name == newCity.name,
                    onSelected: (_) {
                      selectCity(newCity);
                    },
                  );
                }).toList(),
              ),

              const SizedBox(height: 24),

              // Show a loading spinner.
              if (loading)
                const Padding(
                  padding: EdgeInsets.all(40),
                  child: Center(
                    child: CircularProgressIndicator(),
                  ),
                )

              // Show the error and Retry button.
              else if (error != null)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.cloud_off,
                          size: 48,
                          color: Colors.red,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          error!,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: retry,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                )

              // Show the weather when loading succeeds.
              else if (weather != null)
                  WeatherCard(weather: weather!),
            ],
          ),
        ),
      ),
    );
  }
}

class WeatherCard extends StatelessWidget {
  const WeatherCard({
    super.key,
    required this.weather,
  });

  final Weather weather;

  IconData iconFor(int code) {
    if (code == 0) return Icons.wb_sunny;
    if (code <= 2) return Icons.cloud_queue;
    if (code == 3) return Icons.cloud;

    if (code == 45 || code == 48) {
      return Icons.foggy;
    }

    if (code >= 51 && code <= 67) {
      return Icons.water_drop;
    }

    if (code >= 80 && code <= 82) {
      return Icons.umbrella;
    }

    if (code >= 95) {
      return Icons.thunderstorm;
    }

    return Icons.cloud;
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(
              iconFor(weather.code),
              size: 80,
              color: Colors.blue,
            ),
            const SizedBox(height: 12),
            Text(
              '${weather.temperature.round()}°C',
              style: const TextStyle(
                fontSize: 42,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              describe(weather.code),
              style: const TextStyle(fontSize: 20),
            ),
            const Divider(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Column(
                  children: [
                    const Icon(Icons.water_drop),
                    const SizedBox(height: 6),
                    Text('${weather.humidity}%'),
                    const Text('Humidity'),
                  ],
                ),
                Column(
                  children: [
                    const Icon(Icons.air),
                    const SizedBox(height: 6),
                    Text('${weather.wind} km/h'),
                    const Text('Wind'),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              'Weather time: ${weather.time}',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey.shade700,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
