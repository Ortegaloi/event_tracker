// In lib/services/file_service.dart

import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path_provider/path_provider.dart';
import '../models/person.dart';
import '../utils/date_parser.dart';

class FileService {
  static const String _assetFilePath = 'assets/data/event.txt';
  static const String _localFileName = 'birthdays.json';
  
  // Load from assets
  static Future<List<Person>> loadFromAssets() async {
    try {
      final String content = await rootBundle.loadString(_assetFilePath);
      // Use parseFile instead of parseLine
      return DateParser.parseFile(content);
    } catch (e) {
      debugPrint('Error loading from assets: $e');
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
      debugPrint('Error loading from local: $e');
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
      debugPrint('Error saving to local: $e');
    }
  }
  
  // Export to text file
  static Future<String?> exportToText(List<Person> people) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/exported_birthdays.txt');
      
      final buffer = StringBuffer();
      buffer.writeln('BIRTHDAY & ANNIVERSARY LIST');
      buffer.writeln('=' * 30);
      
      for (var person in DateParser.sortByDate(people)) {
        buffer.writeln('${person.name}: ${person.month}/${person.day}');
      }
      
      await file.writeAsString(buffer.toString());
      return file.path;
    } catch (e) {
      debugPrint('Error exporting: $e');
      return null;
    }
  }
}