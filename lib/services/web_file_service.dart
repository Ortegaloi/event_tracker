// In lib/services/web_file_service.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:cross_file/cross_file.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:universal_html/html.dart' as html;
import 'package:file_saver/file_saver.dart';
import '../models/person.dart';
import '../utils/date_parser.dart';

// Export method enum
enum ExportMethod {
  download,
  webShare,
  sharePlus,
  fileSaver,
}

// Extension methods for ExportMethod
extension ExportMethodExtension on ExportMethod {
  String get displayName {
    switch (this) {
      case ExportMethod.download:
        return 'Download as .txt';
      case ExportMethod.webShare:
        return 'Share via Web';
      case ExportMethod.sharePlus:
        return 'Share via SharePlus';
      case ExportMethod.fileSaver:
        return 'Save with FileSaver';
    }
  }
  
  IconData get icon {
    switch (this) {
      case ExportMethod.download:
        return Icons.download;
      case ExportMethod.webShare:
        return Icons.share;
      case ExportMethod.sharePlus:
        return Icons.ios_share;
      case ExportMethod.fileSaver:
        return Icons.save;
    }
  }
}

class WebFileService {
  static const String _storageKey = 'saved_birthdays';
  static const String _assetPath = 'assets/data/event.txt';
  
  // Save to local storage (SharedPreferences for web)
  static Future<void> saveToLocal(List<Person> people) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = people.map((p) => p.toJson()).toList();
      final success = await prefs.setString(_storageKey, json.encode(jsonList));
      
      if (success) {
        debugPrint('✅ Data saved to local storage');
      } else {
        debugPrint('❌ Failed to save data');
      }
    } catch (e) {
      debugPrint('Error saving to local: $e');
    }
  }
  
  // Load from local storage
  static Future<List<Person>> loadFromLocal() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? data = prefs.getString(_storageKey);
      
      if (data != null && data.isNotEmpty) {
        final List<dynamic> jsonList = json.decode(data);
        return jsonList.map((json) => Person.fromJson(json)).toList();
      }
    } catch (e) {
      debugPrint('Error loading from local: $e');
    }
    return [];
  }
  
 static Future<List<Person>> loadFromAssets([String? assetPath]) async {
  try {
    // Use provided path or default
    final path = assetPath ?? _assetPath;
    debugPrint('Attempting to load from assets: $path');
    
    final String content = await rootBundle.loadString(path);
    
    if (content.isEmpty) {
      debugPrint('Asset file is empty');
      return [];
    }
    
    debugPrint('✅ Successfully loaded asset: $path');
    debugPrint('Content length: ${content.length} characters');
    
    // Use parseFile instead of parseLine
    final people = DateParser.parseFile(content);
    debugPrint('✅ Parsed ${people.length} people from file');
    
    return people;
    
  } catch (e) {
    debugPrint('❌ Error loading from assets: $e');
    return [];
  }
}
  
  // Generate export content
  static String _generateExportContent(List<Person> people) {
    final buffer = StringBuffer();
    
    // Add header
    buffer.writeln('=' * 50);
    buffer.writeln('BIRTHDAY & ANNIVERSARY LIST');
    buffer.writeln('Generated: ${DateTime.now().toString().substring(0, 19)}');
    buffer.writeln('=' * 50);
    buffer.writeln('');
    
    // Group by month
    final grouped = DateParser.groupByMonth(people);
    
    const months = [
      'JANUARY', 'FEBRUARY', 'MARCH', 'APRIL', 'MAY', 'JUNE',
      'JULY', 'AUGUST', 'SEPTEMBER', 'OCTOBER', 'NOVEMBER', 'DECEMBER'
    ];
    
    for (int month = 1; month <= 12; month++) {
      final monthPeople = grouped[month] ?? [];
      if (monthPeople.isEmpty) continue;
      
      buffer.writeln('\n📅 ${months[month - 1]} (${monthPeople.length})');
      buffer.writeln('─' * 40);
      
      // Sort by day
      monthPeople.sort((a, b) => a.day.compareTo(b.day));
      
      for (var person in monthPeople) {
        buffer.writeln('  ${person.name}');
      }
    }
    
    // Add summary
    buffer.writeln();
    buffer.writeln('=' * 50);
    buffer.writeln('SUMMARY');
    buffer.writeln('=' * 50);
    
    final birthdays = people.where((p) => p.isBirthday).length;
    final anniversaries = people.where((p) => p.isAnniversary).length;
    
    buffer.writeln('Total Events: ${people.length}');
    buffer.writeln('  🎂 Birthdays: $birthdays');
    buffer.writeln('  💍 Anniversaries: $anniversaries');
    buffer.writeln('=' * 50);
    
    return buffer.toString();
  }
  
  // Method 1: Download file
  static Future<void> downloadFile(List<Person> people) async {
    try {
      final content = _generateExportContent(people);
      final bytes = utf8.encode(content);
      final blob = html.Blob([bytes], 'text/plain');
      final url = html.Url.createObjectUrlFromBlob(blob);
      
      final anchor = html.AnchorElement(href: url)
        ..target = 'blank'
        ..download = 'birthday_list_${DateTime.now().millisecondsSinceEpoch}.txt'
        ..click();
      
      html.Url.revokeObjectUrl(url);
      
      debugPrint('✅ File download initiated');
    } catch (e) {
      debugPrint('Error downloading file: $e');
      rethrow;
    }
  }
  
  // Method 2: Share using Web Share API
  static Future<bool> shareViaWebShare(List<Person> people) async {
    try {
      final content = _generateExportContent(people);
      
      if (html.window.navigator.share != null) {
        await html.window.navigator.share({
          'title': 'Birthday & Anniversary List',
          'text': content.substring(0, content.length > 500 ? 500 : content.length),
        });
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error sharing via web share: $e');
      return false;
    }
  }
  
  // Method 3: Share using share_plus
  static Future<void> shareUsingSharePlus(List<Person> people) async {
    try {
      final content = _generateExportContent(people);
      
      final bytes = utf8.encode(content);
      final blob = html.Blob([bytes], 'text/plain');
      final url = html.Url.createObjectUrlFromBlob(blob);
      
      await Share.shareXFiles(
        [XFile(url, name: 'Birthday_WeddingAni_tracker.txt', mimeType: 'text/plain')],
        text: 'Birthday & Anniversary List',
        subject: 'My Birthday & Anniversary Events',
      );
      
      html.Url.revokeObjectUrl(url);
      
      debugPrint('✅ Shared via share_plus');
    } catch (e) {
      debugPrint('Error sharing via share_plus: $e');
      rethrow;
    }
  }
  
  // Method 4: Save using file_saver
  static Future<void> saveWithFileSaver(List<Person> people) async {
    try {
      final content = _generateExportContent(people);
      final bytes = utf8.encode(content);
      
      await FileSaver.instance.saveFile(
        name: 'birthday_list_${DateTime.now().millisecondsSinceEpoch}',
        bytes: bytes,
        fileExtension: 'txt',
        mimeType: MimeType.text,
      );
      
      debugPrint('✅ File saved with FileSaver');
    } catch (e) {
      debugPrint('Error saving with FileSaver: $e');
      rethrow;
    }
  }
  
  // Comprehensive export method
  static Future<void> exportData(
    List<Person> people, {
    required BuildContext context,
    required ExportMethod method,
  }) async {
    try {
      switch (method) {
        case ExportMethod.download:
          await downloadFile(people);
          _showSnackBar(context, '✅ File downloaded successfully');
          break;
          
        case ExportMethod.webShare:
          final shared = await shareViaWebShare(people);
          if (shared) {
            _showSnackBar(context, '✅ Shared successfully');
          } else {
            await downloadFile(people);
            _showSnackBar(context, '✅ Web Share not available - file downloaded instead');
          }
          break;
          
        case ExportMethod.sharePlus:
          await shareUsingSharePlus(people);
          _showSnackBar(context, '✅ Ready to share');
          break;
          
        case ExportMethod.fileSaver:
          await saveWithFileSaver(people);
          _showSnackBar(context, '✅ File saved successfully');
          break;
      }
    } catch (e) {
      _showSnackBar(context, '❌ Error: $e', isError: true);
    }
  }
  
  static void _showSnackBar(BuildContext context, String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        duration: Duration(seconds: 2),
      ),
    );
  }
}