// lib/constants/app_constants.dart

import 'package:flutter/material.dart';

class AppConstants {
  // Month names
  static const List<String> monthNames = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December'
  ];
  
  static const List<String> shortMonthNames = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ];
  
  // Month colors for headers
  static const Map<int, Color> monthColors = {
    1: Color(0xFFE3F2FD), // Blue 50
    2: Color(0xFFFCE4EC), // Pink 50
    3: Color(0xFFE8F5E9), // Green 50
    4: Color(0xFFFFF3E0), // Orange 50
    5: Color(0xFFF3E5F5), // Purple 50
    6: Color(0xFFFFEBEE), // Red 50
    7: Color(0xFFE0F2F1), // Teal 50
    8: Color(0xFFEFEBE9), // Brown 50
    9: Color(0xFFFFFDE7), // Yellow 50
    10: Color(0xFFE0F7FA), // Cyan 50
    11: Color(0xFFEDE7F6), // Indigo 50
    12: Color(0xFFF1F8E9), // Light Green 50
  };
  
  // Event colors
  static const Color birthdayColor = Color(0xFFE91E63); // Pink
  static const Color anniversaryColor = Color(0xFFF44336); // Red
  static const Color birthdayLightColor = Color(0xFFFCE4EC); // Pink 50
  static const Color anniversaryLightColor = Color(0xFFFFEBEE); // Red 50
}