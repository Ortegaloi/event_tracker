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
  
  // Load from assets
  static Future<List<Person>> loadFromAssets(String assetPath) async {
    try {
      final String content = await rootBundle.loadString(assetPath);
      return _parseContent(content);
    } catch (e) {
      debugPrint('Error loading from assets: $e');
      return [];
    }
  }
  
  // Parse content from text file
  static List<Person> _parseContent(String content) {
    List<Person> people = [];
    List<String> lines = content.split('\n');
    
    for (String line in lines) {
      if (line.trim().isEmpty) continue;
      
      try {
        final person = DateParser.parseLine(line);
        if (person != null) {
          people.add(person);
        }
      } catch (e) {
        debugPrint('Error parsing line: $line');
      }
    }
    
    return DateParser.sortByDate(people);
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
        final type = person.isBirthday ? '🎂' : '❤️';
        final day = person.day.toString().padLeft(2);
        buffer.writeln('  $type  ${months[month - 1].substring(0, 3)} $day  │ ${person.name}');
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
    buffer.writeln('  ❤️ Anniversaries: $anniversaries');
    
    // Add month counts
    buffer.writeln();
    buffer.writeln('Monthly Distribution:');
    for (int month = 1; month <= 12; month++) {
      final count = grouped[month]?.length ?? 0;
      if (count > 0) {
        buffer.writeln('  ${months[month - 1]}: $count');
      }
    }
    
    buffer.writeln('=' * 50);
    
    return buffer.toString();
  }
  
  // Method 1: Download file (simplest for web)
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
  
  // Method 2: Share using Web Share API (if available)
  static Future<bool> shareViaWebShare(List<Person> people) async {
    try {
      final content = _generateExportContent(people);
      
      // Check if Web Share API is available
      if (html.window.navigator.share != null) {
        await html.window.navigator.share({
          'title': 'Birthday & Anniversary List',
          'text': content.substring(0, content.length > 500 ? 500 : content.length), // First 500 chars
        });
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error sharing via web share: $e');
      return false;
    }
  }
  
  // Method 3: Share using share_plus (modern way)
  static Future<void> shareUsingSharePlus(List<Person> people) async {
    try {
      final content = _generateExportContent(people);
      
      // Create a temporary file for sharing
      final bytes = utf8.encode(content);
      final blob = html.Blob([bytes], 'text/plain');
      final url = html.Url.createObjectUrlFromBlob(blob);
      
      // Use share_plus for web
      // ignore: deprecated_member_use
      await Share.shareXFiles(
        [XFile(url, name: 'event.txt', mimeType: 'text/plain')],
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
  
  // Method 4: Save using file_saver (user-friendly)
  static Future<void> saveWithFileSaver(List<Person> people) async {
    try {
      final content = _generateExportContent(people);
      final bytes = utf8.encode(content);
      
      // Fixed: Using correct FileSaver parameters
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
  
  // Comprehensive export method with options
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
            // Fallback to download
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