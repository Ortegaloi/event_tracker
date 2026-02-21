import 'package:flutter/material.dart';
import '/models/person.dart';
import '/constants/app_constants.dart';

class StatisticsCard extends StatelessWidget {
  final Map<String, dynamic> stats;
  
  const StatisticsCard({Key? key, required this.stats}) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.all(16),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Statistics',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(
                  'Total',
                  stats['total'].toString(),
                  Icons.people,
                  Colors.blue,
                ),
                _buildStatItem(
                  'Birthdays',
                  stats['birthdays'].toString(),
                  Icons.cake,
                  AppConstants.birthdayColor,
                ),
                _buildStatItem(
                  'Anniversaries',
                  stats['anniversaries'].toString(),
                  Icons.favorite,
                  AppConstants.anniversaryColor,
                ),
              ],
            ),
            SizedBox(height: 20),
            Text(
              'Upcoming Events (Next 30 Days)',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 10),
            if ((stats['upcomingEvents'] as List).isEmpty)
              Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Center(
                  child: Text(
                    'No upcoming events',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              )
            else
              ...(stats['upcomingEvents'] as List<Person>).take(3).map((person) {
                return Padding(
                  padding: EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Icon(
                        person.isBirthday ? Icons.cake : Icons.favorite,
                        size: 16,
                        color: person.isBirthday 
                            ? AppConstants.birthdayColor 
                            : AppConstants.anniversaryColor,
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          person.name,
                          style: TextStyle(fontSize: 14),
                        ),
                      ),
                      Text(
                        '${AppConstants.shortMonthNames[person.month - 1]} ${person.day}',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
  
  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }
}