// lib/utils/date_parser.dart

import '../models/person.dart';

class DateParser {
  // Month name to number mapping (comprehensive)
  static final Map<String, int> _monthMap = {
    // Full names
    'january': 1, 'february': 2, 'march': 3, 'april': 4, 'may': 5, 'june': 6,
    'july': 7, 'august': 8, 'september': 9, 'october': 10, 'november': 11, 'december': 12,
    
    // Common abbreviations
    'jan': 1, 'feb': 2, 'mar': 3, 'apr': 4, 'may': 5, 'jun': 6,
    'jul': 7, 'aug': 8, 'sep': 9, 'sept': 9, 'oct': 10, 'nov': 11, 'dec': 12,
    
    // With dots
    'jan.': 1, 'feb.': 2, 'mar.': 3, 'apr.': 4, 'may.': 5, 'jun.': 6,
    'jul.': 7, 'aug.': 8, 'sep.': 9, 'sept.': 9, 'oct.': 10, 'nov.': 11, 'dec.': 12,
    
    // Uppercase
    'JANUARY': 1, 'FEBRUARY': 2, 'MARCH': 3, 'APRIL': 4, 'MAY': 5, 'JUNE': 6,
    'JULY': 7, 'AUGUST': 8, 'SEPTEMBER': 9, 'OCTOBER': 10, 'NOVEMBER': 11, 'DECEMBER': 12,
    'JAN': 1, 'FEB': 2, 'MAR': 3, 'APR': 4, 'JUN': 6, 'JUL': 7, 'AUG': 8, 
    'SEP': 9, 'SEPT': 9, 'OCT': 10, 'NOV': 11, 'DEC': 12,
  };

  // Parse a single line from the text file
  static Person? parseLine(String line) {
    try {
      // Skip empty lines
      if (line.trim().isEmpty) return null;
      
      print('🔍 Parsing line: "$line"');
      
      // Check if it's an anniversary
      bool isAnniversary = line.toLowerCase().contains('anniversary') || 
                           line.toLowerCase().contains('wedding');
      
      // Clean up the line
      String cleanLine = line
          .replaceAll('...', ' ')
          .replaceAll('..', ' ')
          .replaceAll('-', ' ')
          .replaceAll('—', ' ')
          .replaceAll(',', ' ')
          .replaceAll('  ', ' ')
          .trim();
      
      // Remove trailing dots
      if (cleanLine.endsWith('.')) {
        cleanLine = cleanLine.substring(0, cleanLine.length - 1);
      }
      
      // PATTERN 1: "Month Day" (e.g., "Dec 17", "July 10th")
      RegExp monthFirstPattern = RegExp(
        r'([A-Za-z\.]+)\s+(\d{1,2})(?:st|nd|rd|th)?',
        caseSensitive: false,
      );
      
      // PATTERN 2: "Day Month" (e.g., "24 March", "5th April")
      RegExp dayFirstPattern = RegExp(
        r'(\d{1,2})(?:st|nd|rd|th)?\s*(?:of\s*)?([A-Za-z\.]+)',
        caseSensitive: false,
      );
      
      // PATTERN 3: "DAY MONTH" (e.g., "7TH SEPTEMBER")
      RegExp allCapsPattern = RegExp(
        r'(\d{1,2})(?:ST|ND|RD|TH)\s+([A-Z]+)',
        caseSensitive: false,
      );
      
      // Try each pattern
      Match? match;
      String monthStr = '';
      String dayStr = '';
      int nameEndIndex = 0;
      
      if (allCapsPattern.hasMatch(cleanLine)) {
        match = allCapsPattern.firstMatch(cleanLine);
        dayStr = match!.group(1)!;
        monthStr = match.group(2)!;
        nameEndIndex = match.start;
      } else if (monthFirstPattern.hasMatch(cleanLine)) {
        match = monthFirstPattern.firstMatch(cleanLine);
        monthStr = match!.group(1)!;
        dayStr = match.group(2)!;
        nameEndIndex = match.start;
      } else if (dayFirstPattern.hasMatch(cleanLine)) {
        match = dayFirstPattern.firstMatch(cleanLine);
        dayStr = match!.group(1)!;
        monthStr = match.group(2)!;
        nameEndIndex = match.start;
      } else {
        // Handle lines without dates (like "Sis. Miracle Ishaya")
        if (line.contains(RegExp(r'[A-Za-z]')) && !line.contains(RegExp(r'\d'))) {
          print('⚠️ Line has no date: "$line"');
        }
        return null;
      }
      
      // Parse month
      int? month = _parseMonth(monthStr.trim());
      if (month == null) {
        print('❌ Could not parse month: "$monthStr"');
        return null;
      }
      
      // Parse day
      int? day = int.tryParse(dayStr.trim());
      if (day == null || day < 1 || day > 31) {
        print('❌ Invalid day: "$dayStr"');
        return null;
      }
      
      // Extract name (everything before the date)
      String name = cleanLine.substring(0, nameEndIndex).trim();
      
      // Clean up name
      name = name.replaceAll(RegExp(r'[-\—]\s*$'), '').trim();
      
      // Handle special name formatting
      if (name.isNotEmpty) {
        // Check for Mr., Mrs., etc. and format properly
        name = _formatName(name);
      } else {
        name = 'Unknown';
      }
      
      // For anniversaries, try to extract couple names
      if (isAnniversary) {
        String anniversaryName = _extractCoupleName(name, line);
        print('💍 Anniversary for: $anniversaryName');
        
        return Person(
          name: anniversaryName,
          month: month,
          day: day,
          type: EventType.anniversary,
        );
      }
      
      print('✅ Parsed: $name - Month: $month, Day: $day');
      
      return Person(
        name: name,
        month: month,
        day: day,
        type: EventType.birthday,
      );
      
    } catch (e) {
      print('❌ Error parsing line "$line": $e');
      return null;
    }
  }
  
  // Extract couple name from anniversary entry
  static String _extractCoupleName(String name, String originalLine) {
    // Common patterns for couple names
    if (name.toLowerCase().contains('mr. & mrs.') || 
        name.toLowerCase().contains('mr & mrs') ||
        name.toLowerCase().contains('mr. and mrs.')) {
      return name; // Already formatted
    }
    
    // Try to extract from "Wedding Anniversary Mr. & Mrs. Smith"
    RegExp couplePattern = RegExp(
      r'(?:wedding|anniversary)\s*(?:\-+\s*)?(.*?)(?:\s+\d+|$)',
      caseSensitive: false,
    );
    
    var match = couplePattern.firstMatch(originalLine);
    if (match != null) {
      String couple = match.group(1)?.trim() ?? '';
      if (couple.isNotEmpty) {
        // Clean up the couple name
        couple = couple.replaceAll(RegExp(r'[-\—]$'), '').trim();
        if (couple.isNotEmpty) {
          return '💍 ' + _formatName(couple);
        }
      }
    }
    
    // If we can't extract, use a default
    return '💍 Wedding Anniversary';
  }
  
  // Format name with proper capitalization and titles
  static String _formatName(String name) {
    List<String> words = name.split(' ');
    List<String> formattedWords = [];
    
    for (String word in words) {
      if (word.isEmpty) continue;
      
      String lowerWord = word.toLowerCase();
      
      // Handle titles
      if (lowerWord == 'mr' || lowerWord == 'mr.' || lowerWord == 'mr') {
        formattedWords.add('Mr.');
      } else if (lowerWord == 'mrs' || lowerWord == 'mrs.' || lowerWord == 'mrs') {
        formattedWords.add('Mrs.');
      } else if (lowerWord == 'pst' || lowerWord == 'pst.' || lowerWord == 'pst') {
        formattedWords.add('Pst.');
      } else if (lowerWord == 'bro' || lowerWord == 'bro.' || lowerWord == 'bro') {
        formattedWords.add('Bro.');
      } else if (lowerWord == 'sis' || lowerWord == 'sis.' || lowerWord == 'sis') {
        formattedWords.add('Sis.');
      } else if (lowerWord == 'dr' || lowerWord == 'dr.' || lowerWord == 'dr') {
        formattedWords.add('Dr.');
      } else if (lowerWord == 'rev' || lowerWord == 'rev.' || lowerWord == 'rev') {
        formattedWords.add('Rev.');
      } else if (lowerWord == 'pastor' || lowerWord == 'pastor.') {
        formattedWords.add('Pastor');
      } else if (lowerWord == 'deaconess' || lowerWord == 'dns' || lowerWord == 'dns.') {
        formattedWords.add('Dns.');
      } else if (lowerWord == '&' || lowerWord == 'and') {
        formattedWords.add('&');
      } else {
        // Regular word - capitalize first letter
        if (word.length > 1) {
          formattedWords.add(word[0].toUpperCase() + word.substring(1).toLowerCase());
        } else {
          formattedWords.add(word.toUpperCase());
        }
      }
    }
    
    return formattedWords.join(' ');
  }
  
  // Parse month from string
  static int? _parseMonth(String monthStr) {
    String cleaned = monthStr.toLowerCase().trim().replaceAll('.', '');
    
    // Try exact match
    if (_monthMap.containsKey(cleaned)) {
      return _monthMap[cleaned];
    }
    
    // Try partial match
    for (var entry in _monthMap.entries) {
      if (cleaned.startsWith(entry.key.replaceAll('.', ''))) {
        return entry.value;
      }
    }
    
    return null;
  }
  
  // Parse file content
  static List<Person> parseFile(String content) {
    List<Person> allPeople = [];
    List<String> lines = content.split('\n');
    
    print('📄 Starting to parse ${lines.length} lines...');
    
    for (String line in lines) {
      line = line.trim();
      if (line.isEmpty) continue;
      
      // Handle lines with multiple entries
      if (line.contains(',') && !line.toLowerCase().contains('anniversary')) {
        List<String> entries = line.split(',').map((e) => e.trim()).toList();
        for (String entry in entries) {
          if (entry.isNotEmpty) {
            Person? person = parseLine(entry);
            if (person != null) {
              allPeople.add(person);
            }
          }
        }
      } else {
        Person? person = parseLine(line);
        if (person != null) {
          allPeople.add(person);
        }
      }
    }
    
    print('📊 Total parsed: ${allPeople.length} entries');
    
    // Count birthdays vs anniversaries
    int birthdays = allPeople.where((p) => p.isBirthday).length;
    int anniversaries = allPeople.where((p) => p.isAnniversary).length;
    print('🎂 Birthdays: $birthdays');
    print('💍 Anniversaries: $anniversaries');
    
    return allPeople;
  }
  
  // Sort people by month then day
  static List<Person> sortByDate(List<Person> people) {
    List<Person> sorted = List.from(people);
    sorted.sort((a, b) {
      if (a.month != b.month) return a.month.compareTo(b.month);
      return a.day.compareTo(b.day);
    });
    return sorted;
  }
  
  // Group people by month
  static Map<int, List<Person>> groupByMonth(List<Person> people) {
    Map<int, List<Person>> grouped = {};
    for (var person in people) {
      grouped.putIfAbsent(person.month, () => []).add(person);
    }
    
    // Sort each month's list by day
    grouped.forEach((month, monthPeople) {
      monthPeople.sort((a, b) => a.day.compareTo(b.day));
    });
    
    return grouped;
  }
}