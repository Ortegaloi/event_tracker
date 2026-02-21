import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path_provider/path_provider.dart';
import '/models/person.dart';
import '/utils/date_parser.dart';

class FileService {
  static const String _assetFilePath = 'assets/data/event.txt';
  static const String _localFileName = 'birthdays.json';
  
  // Load from assets (initial data)
  static Future<List<Person>> loadFromAssets() async {
    try {
      final String content = await rootBundle.loadString(_assetFilePath);
      return _parseContent(content);
    } catch (e) {
      print('Error loading from assets: $e');
      return [];
    }
  }
  
  // Load from local storage
  static Future<List<Person>> loadFromLocal() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/$_localFileName');
      
      if (await file.exists()) {
        final String content = await file.readAsString();
        final List<dynamic> jsonList = json.decode(content);
        return jsonList.map((json) => Person.fromJson(json)).toList();
      }
    } catch (e) {
      print('Error loading from local: $e');
    }
    return [];
  }
  
  // Save to local storage
  static Future<void> saveToLocal(List<Person> people) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/$_localFileName');
      
      final jsonList = people.map((p) => p.toJson()).toList();
      await file.writeAsString(json.encode(jsonList));
    } catch (e) {
      print('Error saving to local: $e');
    }
  }
  
  // Parse content from text file
  static List<Person> _parseContent(String content) {
    List<Person> people = [];
    List<String> lines = content.split('\n');
    
    for (String line in lines) {
      try {
        // Handle multiple entries on same line (comma-separated)
        if (line.contains(',') && !line.contains(',')) {
          List<String> entries = line.split(',').map((e) => e.trim()).toList();
          for (var entry in entries) {
            final person = DateParser.parseLine(entry);
            if (person != null) people.add(person);
          }
        } else {
          final person = DateParser.parseLine(line);
          if (person != null) people.add(person);
        }
      } catch (e) {
        print('Error parsing line: $line');
      }
    }
    
    return DateParser.sortByDate(people);
  }
  
  // Export to text file
// In lib/services/file_service.dart - make sure exportToText returns a valid path

static Future<String?> exportToText(List<Person> people) async {
  try {
    final directory = await getApplicationDocumentsDirectory();
    final fileName = 'birthday_export_${DateTime.now().millisecondsSinceEpoch}.txt';
    final file = File('${directory.path}/$fileName');
    
    final buffer = StringBuffer();
    
    // Add header
    buffer.writeln('=' * 50);
    buffer.writeln('BIRTHDAY & ANNIVERSARY LIST');
    buffer.writeln('Generated: ${DateTime.now().toString().substring(0, 19)}');
    buffer.writeln('=' * 50);
    buffer.writeln();
    
    // Group by month
    Map<int, List<Person>> grouped = {};
    for (var person in people) {
      grouped.putIfAbsent(person.month, () => []).add(person);
    }
    
    const months = [
      'JANUARY', 'FEBRUARY', 'MARCH', 'APRIL', 'MAY', 'JUNE',
      'JULY', 'AUGUST', 'SEPTEMBER', 'OCTOBER', 'NOVEMBER', 'DECEMBER'
    ];
    
    for (int month = 1; month <= 12; month++) {
      final monthPeople = grouped[month] ?? [];
      if (monthPeople.isEmpty) continue;
      
      buffer.writeln('\n📅 ${months[month - 1]}');
      buffer.writeln('─' * 30);
      
      for (var person in monthPeople) {
        String type = person.isBirthday ? '🎂' : '❤️';
        buffer.writeln('  $type ${person.name}: ${months[month - 1].substring(0, 3)} ${person.day}');
      }
    }
    
    // Add summary
    buffer.writeln();
    buffer.writeln('=' * 50);
    buffer.writeln('SUMMARY');
    buffer.writeln('=' * 50);
    
    int birthdays = people.where((p) => p.isBirthday).length;
    int anniversaries = people.where((p) => p.isAnniversary).length;
    
    buffer.writeln('Total Events: ${people.length}');
    buffer.writeln('  🎂 Birthdays: $birthdays');
    buffer.writeln('  ❤️ Anniversaries: $anniversaries');
    buffer.writeln('=' * 50);
    
    await file.writeAsString(buffer.toString());
    return file.path;
    
  } catch (e) {
    print('Error exporting to text: $e');
    return null;
  }
}
}