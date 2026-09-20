import 'package:flutter/material.dart';
import '../services/weather_service.dart';

class StadiumWeatherCard extends StatelessWidget {
  final String venueName;

  const StadiumWeatherCard({super.key, required this.venueName});

  @override
  Widget build(BuildContext context) {
    if (venueName.isEmpty) return const SizedBox.shrink();

    return FutureBuilder<LiveWeatherData>(
      future: WeatherService.getLiveWeather(venueName),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();

        final data = snapshot.data!;
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                const Icon(Icons.stadium_outlined, color: Colors.blueGrey),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        venueName,
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'Canlı Hava Durumu: ${data.temperature.toStringAsFixed(1)}°C | ${data.toWeatherCondition.label}',
                        style: const TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                Text(
                  data.emoji,
                  style: const TextStyle(fontSize: 24),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
