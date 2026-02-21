import 'package:flutter/material.dart';

class FilterChips extends StatelessWidget {
  final bool showBirthdays;
  final bool showAnniversaries;
  final Function(bool) onBirthdaysChanged;
  final Function(bool) onAnniversariesChanged;
  
  const FilterChips({
    Key? key,
    required this.showBirthdays,
    required this.showAnniversaries,
    required this.onBirthdaysChanged,
    required this.onAnniversariesChanged,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: FilterChip(
              label: Text('Birthdays'),
              selected: showBirthdays,
              onSelected: onBirthdaysChanged,
              backgroundColor: Colors.pink.shade50,
              selectedColor: Colors.pink.shade200,
              checkmarkColor: Colors.white,
              avatar: CircleAvatar(
                backgroundColor: showBirthdays ? Colors.white : Colors.pink.shade100,
                radius: 10,
                child: Icon(
                  Icons.cake,
                  size: 12,
                  color: showBirthdays ? Colors.pink : Colors.white,
                ),
              ),
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: FilterChip(
              label: Text('Anniversaries'),
              selected: showAnniversaries,
              onSelected: onAnniversariesChanged,
              backgroundColor: Colors.red.shade50,
              selectedColor: Colors.red.shade200,
              checkmarkColor: Colors.white,
              avatar: CircleAvatar(
                backgroundColor: showAnniversaries ? Colors.white : Colors.red.shade100,
                radius: 10,
                child: Icon(
                  Icons.favorite,
                  size: 12,
                  color: showAnniversaries ? Colors.red : Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}