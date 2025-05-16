import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/location_provider.dart';
import '../util/extensions/datetime_extensions.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final locationProvider = Provider.of<LocationProvider>(context, listen: false);

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Tracking Status Indicator
          ValueListenableBuilder<bool>(
            valueListenable: locationProvider.trackingStatus,
            builder: (context, isTracking, child) {
              return Container(
                padding: const EdgeInsets.all(8.0),
                decoration: BoxDecoration(
                  color: isTracking ? Colors.green.withAlpha(100) : Colors.grey.withAlpha(50),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      isTracking ? Icons.location_on : Icons.location_off,
                      color: isTracking ? Colors.green : Colors.grey,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      isTracking ? 'Tracking Active' : 'Tracking Inactive',
                      style: TextStyle(
                        color: isTracking ? Colors.green : Colors.grey,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 24),
          // Location Card
          Consumer<LocationProvider>(
            builder: (context, provider, child) {
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Text(
                        'Current Location',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        provider.currentLocation?.displayName ?? 'Unknown Location',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      if (provider.currentLocation != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          'Lat: ${provider.currentLocation!.latitude.toStringAsFixed(4)}\nLong: ${provider.currentLocation!.longitude.toStringAsFixed(4)}',
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: () => _showAddGeofenceDialog(context, provider),
                          icon: const Icon(Icons.add_location, color: Colors.black),
                          label: const Text('Save as Geo-fence', style: TextStyle(fontSize: 12, color: Colors.black)),
                        ),
                      ],
                      if (provider.clockInTime != null) ...[
                        const SizedBox(height: 16),
                        Text(
                          'Tracking since: ${provider.clockInTime!.time}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 32),
          // Clock In/Out Buttons
          ValueListenableBuilder<bool>(
            valueListenable: locationProvider.trackingStatus,
            builder: (context, isTracking, child) {
              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: isTracking ? null : () => locationProvider.clockIn(),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    ),
                    child: Text(
                      'Clock In',
                      style: TextStyle(
                        color: isTracking ? Colors.grey : Colors.black,
                      ),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: isTracking ? () => locationProvider.clockOut() : null,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    ),
                    child: Text(
                      'Clock Out',
                      style: TextStyle(
                        color: isTracking ? Colors.black : Colors.grey,
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
          // Display Current Geofences
          const SizedBox(height: 24),
          Consumer<LocationProvider>(
            builder: (context, provider, child) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Saved Geo-fences:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  if (provider.geofences.isEmpty)
                    const Text('No geo-fences added yet')
                  else
                    SizedBox(
                      height: 100,
                      child: ListView.builder(
                        itemCount: provider.geofences.length,
                        itemBuilder: (context, index) {
                          final fence = provider.geofences[index];
                          return ListTile(
                            dense: true,
                            title: Text(fence.name),
                            subtitle: Text(
                              'Lat: ${fence.latitude.toStringAsFixed(4)}, Long: ${fence.longitude.toStringAsFixed(4)}',
                            ),
                            leading: const Icon(Icons.location_on),
                          );
                        },
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  void _showAddGeofenceDialog(BuildContext context, LocationProvider provider) {
    final nameController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Save Location as Geo-fence'),
          content: TextField(
            controller: nameController,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              labelText: 'Location Name',
              hintText: 'e.g., Home, Office, Gym',
            ),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                final name = nameController.text.trim();

                if (provider.currentLocation != null) {
                  final String? errorMessage = provider.addGeofence(
                    name,
                    provider.currentLocation!.latitude,
                    provider.currentLocation!.longitude,
                  );
                  Navigator.pop(context);

                  if (errorMessage != null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(errorMessage)),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Geo-fence "$name" added successfully!')),
                    );
                  }
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }
}
