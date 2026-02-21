import 'package:flutter/material.dart';
import '/constants/app_constants.dart';

class MonthHeader extends StatelessWidget {
  final int month;
  final int? count;
  
  const MonthHeader({
    Key? key,
    required this.month,
    this.count,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: AppConstants.monthColors[month] ?? Colors.grey.shade200,
      child: Row(
        children: [
          Text(
            AppConstants.monthNames[month - 1],
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          if (count != null) ...[
            SizedBox(width: 8),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.black12,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
          Spacer(),
          Icon(
            Icons.calendar_today,
            size: 16,
            color: Colors.black54,
          ),
        ],
      ),
    );
  }
}