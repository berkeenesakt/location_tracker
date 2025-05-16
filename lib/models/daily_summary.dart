import 'package:hive/hive.dart';

part 'daily_summary.g.dart';

@HiveType(typeId: 3)
class DailySummary {
  @HiveField(0)
  final DateTime date;

  @HiveField(1)
  final Map<String, int> timePerLocation; // Location name -> time in milliseconds

  @HiveField(2)
  int travelingTime; // Time in milliseconds

  DailySummary({
    required this.date,
    Map<String, int>? timePerLocation,
    this.travelingTime = 0,
  }) : timePerLocation = timePerLocation ?? {};

  void addTimeToLocation(String locationName, int milliseconds) {
    timePerLocation[locationName] = (timePerLocation[locationName] ?? 0) + milliseconds;
  }

  void addTravelingTime(int milliseconds) {
    travelingTime += milliseconds;
  }

  String getFormattedTimeFor(String locationName) {
    final milliseconds = timePerLocation[locationName] ?? 0;
    return _formatDuration(Duration(milliseconds: milliseconds));
  }

  String getFormattedTravelingTime() {
    return _formatDuration(Duration(milliseconds: travelingTime));
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    return '${hours}h ${minutes}m';
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date.toIso8601String(),
      'timePerLocation': timePerLocation,
      'travelingTime': travelingTime,
    };
  }

  factory DailySummary.fromJson(Map<String, dynamic> json) {
    final timePerLocation = Map<String, int>.from(json['timePerLocation'] as Map);

    return DailySummary(
      date: DateTime.parse(json['date'] as String),
      timePerLocation: timePerLocation,
      travelingTime: json['travelingTime'] as int,
    );
  }
}
