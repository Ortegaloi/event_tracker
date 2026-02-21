import 'package:flutter/material.dart';
import '../services/data_service.dart';
import '../widgets/statistics_card.dart';
import '../widgets/person_list_tile.dart';
import '../constants/app_constants.dart';

class StatisticsScreen extends StatelessWidget {
  const StatisticsScreen({super.key});
  
  @override
  Widget build(BuildContext context) {
    final dataService = DataService();
    final stats = dataService.getStatistics();
    final upcomingEvents = stats['upcomingEvents'] as List;
    final total = stats['total'] as int;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Statistics'),
      ),
      body: ListView(
        children: [
          StatisticsCard(stats: stats),
          
          if (upcomingEvents.isNotEmpty) ...[
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'All Upcoming Events',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            ...upcomingEvents.map((person) => PersonListTile(
              person: person,
              showTypeIcon: true,
            )),
          ],
          
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Monthly Distribution',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          
          // Monthly Distribution Bars - MOST ROBUST
          ...List.generate(12, (index) {
            int month = index + 1;
            int count = (stats['monthCount'] as Map)[month] ?? 0;
            
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  // Month name
                  SizedBox(
                    width: 100,
                    child: Text(
                      AppConstants.monthNames[index],
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  
                  // Bar container
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Percentage bar
                        Container(
                          height: 24,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: total > 0 && count > 0
                              ? FractionallySizedBox(
                                  widthFactor: count / total,
                                  alignment: Alignment.centerLeft,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: AppConstants.monthColors[month] ?? Colors.blue.shade300,
                                      borderRadius: BorderRadius.circular(12),
                                      gradient: LinearGradient(
                                        colors: [
                                          (AppConstants.monthColors[month] ?? Colors.blue.shade300),
                                          (AppConstants.monthColors[month] ?? Colors.blue.shade300)
                                              .withValues(alpha: 0.8),
                                        ],
                                      ),
                                    ),
                                  ),
                                )
                              : null,
                        ),
                        
                        // Percentage text
                        if (total > 0)
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text(
                              '${((count / total) * 100).toStringAsFixed(1)}%',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  
                  // Count
                  Container(
                    width: 40,
                    alignment: Alignment.centerRight,
                    child: Text(
                      '$count',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
          
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}