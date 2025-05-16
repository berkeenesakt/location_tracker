import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/daily_summary.dart';
import '../providers/location_provider.dart';
import '../util/extensions/datetime_extensions.dart';

class SummaryScreen extends StatelessWidget {
  const SummaryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final locationProvider = Provider.of<LocationProvider>(context);

    return SafeArea(
      child: Column(
        children: [
          // Today's summary card
          _buildTodaySummaryCard(context, locationProvider),

          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Divider(),
          ),

          const Text(
            'Past Tracking History',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),

          // Previous sessions list
          Expanded(
            child: ValueListenableBuilder<Box<DailySummary>>(
              valueListenable: Hive.box<DailySummary>('daily_summary').listenable(),
              builder: (context, summaryBox, _) {
                if (summaryBox.isEmpty) {
                  return Center(
                    child: Text(
                      'No previous tracking data',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.white),
                    ),
                  );
                }

                final dates = summaryBox.keys.toList();
                dates.sort((a, b) => b.toString().compareTo(a.toString())); // Most recent first

                return ListView.builder(
                  itemCount: dates.length,
                  itemBuilder: (context, index) {
                    final dateKey = dates[index];
                    final summary = summaryBox.get(dateKey);
                    if (summary == null) return const SizedBox.shrink();

                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              summary.date.shortDate,
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            const SizedBox(height: 8),
                            ...locationProvider.geofences.map((fence) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 4.0),
                                child: Text(
                                  '${fence.name}: ${summary.getFormattedTimeFor(fence.name)}',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                              );
                            }).toList(),
                            Padding(
                              padding: const EdgeInsets.only(bottom: 4.0, top: 4.0),
                              child: Text(
                                'Traveling: ${summary.getFormattedTravelingTime()}',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTodaySummaryCard(BuildContext context, LocationProvider provider) {
    final today = DateTime.now();
    final summary = provider.currentDaySummary;

    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Today (${today.shortDateNoYear})',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (summary != null) ...[
              ...provider.geofences.map((fence) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        fence.name,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(summary.getFormattedTimeFor(fence.name)),
                    ],
                  ),
                );
              }).toList(),
              const Divider(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Traveling',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(summary.getFormattedTravelingTime()),
                ],
              ),
            ] else ...[
              const Center(
                child: Text('No data for today yet'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
