// lib/widgets/person_list_tile.dart (updated)

import 'package:flutter/material.dart';
import '../models/person.dart';
import '../constants/app_constants.dart';

class PersonListTile extends StatelessWidget {
  final Person person;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;
  final bool showTypeIcon;
  
  const PersonListTile({
    Key? key,
    required this.person,
    this.onTap,
    this.onDelete,
    this.showTypeIcon = true,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    // Determine icon and color based on type
    IconData icon = person.isBirthday ? Icons.cake : Icons.favorite;
    Color iconColor = person.isBirthday 
        ? AppConstants.birthdayColor 
        : AppConstants.anniversaryColor;
    Color bgColor = person.isBirthday 
        ? AppConstants.birthdayLightColor 
        : AppConstants.anniversaryLightColor;
    
    // For anniversaries, show couple name prominently
    String displayName = person.displayName;
    String subtitle = '${AppConstants.monthNames[person.month - 1]} ${person.day}${_getDaySuffix(person.day)}';
    
    return ListTile(
      onTap: onTap,
      leading: showTypeIcon ? CircleAvatar(
        backgroundColor: bgColor,
        child: Icon(
          icon,
          color: iconColor,
          size: 20,
        ),
      ) : null,
      title: Text(
        displayName,
        style: TextStyle(
          fontWeight: person.isAnniversary ? FontWeight.bold : FontWeight.normal,
          color: person.isAnniversary ? AppConstants.anniversaryColor : null,
        ),
      ),
      subtitle: Text(subtitle),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: iconColor.withOpacity(0.3)),
            ),
            child: Text(
              '${person.day}',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: iconColor,
              ),
            ),
          ),
          if (onDelete != null) ...[
            SizedBox(width: 8),
            IconButton(
              icon: Icon(Icons.delete, color: Colors.grey, size: 20),
              onPressed: onDelete,
            ),
          ],
        ],
      ),
    );
  }
  
  String _getDaySuffix(int day) {
    if (day >= 11 && day <= 13) return 'th';
    switch (day % 10) {
      case 1: return 'st';
      case 2: return 'nd';
      case 3: return 'rd';
      default: return 'th';
    }
  }
}