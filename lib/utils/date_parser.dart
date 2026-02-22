// lib/utils/date_parser.dart

import '../models/person.dart';

class DateParser {
  // Comprehensive month mapping
  static final Map<String, int> _monthMap = {
    // Full names
    'january': 1, 'february': 2, 'march': 3, 'april': 4, 'may': 5, 'june': 6,
    'july': 7, 'august': 8, 'september': 9, 'october': 10, 'november': 11, 'december': 12,
    
    // 3-letter abbreviations
    'jan': 1, 'feb': 2, 'mar': 3, 'apr': 4, 'may': 5, 'jun': 6,
    'jul': 7, 'aug': 8, 'sep': 9, 'oct': 10, 'nov': 11, 'dec': 12,
    
    // With dots
    'jan.': 1, 'feb.': 2, 'mar.': 3, 'apr.': 4, 'may.': 5, 'jun.': 6,
    'jul.': 7, 'aug.': 8, 'sep.': 9, 'sept.': 9, 'oct.': 10, 'nov.': 11, 'dec.': 12,
    
    // Uppercase
    'JANUARY': 1, 'FEBRUARY': 2, 'MARCH': 3, 'APRIL': 4, 'MAY': 5, 'JUNE': 6,
    'JULY': 7, 'AUGUST': 8, 'SEPTEMBER': 9, 'OCTOBER': 10, 'NOVEMBER': 11, 'DECEMBER': 12,
    'JAN': 1, 'FEB': 2, 'MAR': 3, 'APR': 4, 'JUN': 6, 'JUL': 7, 'AUG': 8, 
    'SEP': 9, 'SEPT': 9, 'OCT': 10, 'NOV': 11, 'DEC': 12,
    
    // Variations
    'sept': 9, 'october': 10, 'november': 11, 'december': 12,
    'february': 2, 'febraury': 2, // Common misspelling
  };

  static List<Person> parseFile(String content) {
    List<Person> allPeople = [];
    List<String> lines = content.split('\n');
    
    print('📄 Starting to parse ${lines.length} lines...');
    
    for (String line in lines) {
      line = line.trim();
      if (line.isEmpty) continue;
      
      // Handle lines with multiple comma-separated entries
      if (line.contains(',') && !line.toLowerCase().contains('anniversary')) {
        List<String> entries = line.split(',').map((e) => e.trim()).toList();
        for (String entry in entries) {
          if (entry.isNotEmpty) {
            List<Person?> parsed = _parseLineWithMultipleFormats(entry);
            for (var person in parsed) {
              if (person != null) {
                allPeople.add(person);
                print('✅ Added: ${person.name} - ${person.month}/${person.day} (${person.type})');
              }
            }
          }
        }
      } else {
        List<Person?> parsed = _parseLineWithMultipleFormats(line);
        for (var person in parsed) {
          if (person != null) {
            allPeople.add(person);
            print('✅ Added: ${person.name} - ${person.month}/${person.day} (${person.type})');
          }
        }
      }
    }
    
    print('📊 Total parsed: ${allPeople.length} entries');
    return allPeople;
  }

  static List<Person?> _parseLineWithMultipleFormats(String line) {
    List<Person?> results = [];
    
    // Try different parsing strategies
    var person = _parseStandardFormat(line);
    if (person != null) {
      results.add(person);
      return results;
    }
    
    person = _parseWithOrdinals(line);
    if (person != null) {
      results.add(person);
      return results;
    }
    
    person = _parseAllCapsFormat(line);
    if (person != null) {
      results.add(person);
      return results;
    }
    
    person = _parseWithoutSeparator(line);
    if (person != null) {
      results.add(person);
      return results;
    }
    
    // If no date found but line has name, skip (don't add)
    return results;
  }

  static Person? _parseStandardFormat(String line) {
    try {
      bool isAnniversary = line.toLowerCase().contains('anniversary') || 
                           line.toLowerCase().contains('wedding');
      
      // Clean the line
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
      
      // Pattern: Month Day (Dec 17, July 10th)
      RegExp monthFirst = RegExp(
        r'([A-Za-z\.]+)\s+(\d{1,2})(?:st|nd|rd|th)?',
        caseSensitive: false,
      );
      
      // Pattern: Day Month (24 March, 5th April)
      RegExp dayFirst = RegExp(
        r'(\d{1,2})(?:st|nd|rd|th)?\s*(?:of\s*)?([A-Za-z\.]+)',
        caseSensitive: false,
      );
      
      Match? match;
      String monthStr = '';
      String dayStr = '';
      int nameEndIndex = 0;
      
      if (monthFirst.hasMatch(cleanLine)) {
        match = monthFirst.firstMatch(cleanLine);
        monthStr = match!.group(1)!;
        dayStr = match.group(2)!;
        nameEndIndex = match.start;
      } else if (dayFirst.hasMatch(cleanLine)) {
        match = dayFirst.firstMatch(cleanLine);
        dayStr = match!.group(1)!;
        monthStr = match.group(2)!;
        nameEndIndex = match.start;
      } else {
        return null;
      }
      
      int? month = _parseMonth(monthStr.trim());
      if (month == null) return null;
      
      int? day = int.tryParse(dayStr.trim());
      if (day == null || day < 1 || day > 31) return null;
      
      // Extract name
      String name = cleanLine.substring(0, nameEndIndex).trim();
      name = name.replaceAll(RegExp(r'[-\—]\s*$'), '').trim();
      
      // Handle special cases
      if (name.isEmpty) {
        // Try to extract from remaining text
        List<String> parts = cleanLine.split(' ');
        if (parts.length > 2) {
          name = parts.sublist(0, parts.length - 2).join(' ');
        } else {
          name = 'Unknown';
        }
      }
      
      // Format name
      name = _formatName(name);
      
      // Handle anniversaries
      if (isAnniversary) {
        String anniversaryName = _extractCoupleName(name, line);
        return Person(
          name: '💍 $anniversaryName',
          month: month,
          day: day,
          type: EventType.anniversary,
        );
      }
      
      return Person(
        name: '🎂 $name',
        month: month,
        day: day,
        type: EventType.birthday,
      );
      
    } catch (e) {
      return null;
    }
  }

  static Person? _parseWithOrdinals(String line) {
    try {
      bool isAnniversary = line.toLowerCase().contains('anniversary') || 
                           line.toLowerCase().contains('wedding');
      
      // Handle formats like "Sis. Peace Afogho - 1th", "Pst. Chima Elijah - 27"
      RegExp ordinalPattern = RegExp(
        r'(.+?)[-\s]+(\d{1,2})(?:st|nd|rd|th)?\s*$',
        caseSensitive: false,
      );
      
      var match = ordinalPattern.firstMatch(line);
      if (match == null) return null;
      
      String name = match.group(1)!.trim();
      String dayStr = match.group(2)!;
      
      // If there's no month, we can't determine the date
      // Check if month appears elsewhere in the line
      for (var monthName in _monthMap.keys) {
        if (line.toLowerCase().contains(monthName.toLowerCase())) {
          // Extract month
          int? month = _parseMonth(monthName);
          if (month != null) {
            int? day = int.tryParse(dayStr);
            if (day != null && day >= 1 && day <= 31) {
              name = _formatName(name);
              
              if (isAnniversary) {
                return Person(
                  name: '💍 ${_extractCoupleName(name, line)}',
                  month: month,
                  day: day,
                  type: EventType.anniversary,
                );
              }
              
              return Person(
                name: '🎂 $name',
                month: month,
                day: day,
                type: EventType.birthday,
              );
            }
          }
        }
      }
      
      return null;
      
    } catch (e) {
      return null;
    }
  }

  static Person? _parseAllCapsFormat(String line) {
    try {
      bool isAnniversary = line.toLowerCase().contains('anniversary') || 
                           line.toLowerCase().contains('wedding');
      
      // Handle "RACHEL OLOWOYEYE 7TH SEPTEMBER"
      RegExp allCapsPattern = RegExp(
        r'(.+?)\s+(\d{1,2})(?:ST|ND|RD|TH)\s+([A-Z]+)',
        caseSensitive: false,
      );
      
      var match = allCapsPattern.firstMatch(line);
      if (match != null) {
        String name = match.group(1)!.trim();
        String dayStr = match.group(2)!;
        String monthStr = match.group(3)!;
        
        int? month = _parseMonth(monthStr);
        int? day = int.tryParse(dayStr);
        
        if (month != null && day != null) {
          name = _formatName(name);
          
          if (isAnniversary) {
            return Person(
              name: '💍 ${_extractCoupleName(name, line)}',
              month: month,
              day: day,
              type: EventType.anniversary,
            );
          }
          
          return Person(
            name: '🎂 $name',
            month: month,
            day: day,
            type: EventType.birthday,
          );
        }
      }
      
      return null;
      
    } catch (e) {
      return null;
    }
  }

  static Person? _parseWithoutSeparator(String line) {
    try {
      bool isAnniversary = line.toLowerCase().contains('anniversary') || 
                           line.toLowerCase().contains('wedding');
      
      // Handle "Emmanuel Adebayo 31st" - assume current month? 
      // Better to skip if month not specified
      return null;
      
    } catch (e) {
      return null;
    }
  }

  static String _formatName(String name) {
    // Remove extra spaces
    name = name.replaceAll(RegExp(r'\s+'), ' ').trim();
    
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
      } else if (lowerWord == 'rev' || lowerWord == 'rev.' || lowerWord == 'rev' || lowerWord == 'Rev') {
        formattedWords.add('Rev.');
      } else if (lowerWord == 'pastor' || lowerWord == 'pastor.') {
        formattedWords.add('Pastor');
      } else if (lowerWord == 'deaconess' || lowerWord == 'dns' || lowerWord == 'dns.' || lowerWord == 'Dns' || lowerWord == 'Deaconess') {
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

  static String _extractCoupleName(String name, String originalLine) {
    // Look for patterns like "Mr. & Mrs. Smith" or "Pst. & Mrs. Jolayemi"
    RegExp couplePattern = RegExp(
      r'(Mr\.?\s*&\s*Mrs\.?|Pst\.?\s*&\s*Mrs\.?|Rev\.?\s*&\s*Mrs\.?|[A-Za-z\.]+\s*&\s*[A-Za-z\.]+).*',
      caseSensitive: false,
    );
    
    var match = couplePattern.firstMatch(originalLine);
    if (match != null) {
      return _formatName(match.group(0)!);
    }
    
    // If name already contains &, use it
    if (name.contains('&')) {
      return name;
    }
    
    // Default: use the extracted name
    return name.isEmpty ? 'Wedding Anniversary' : name;
  }

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

  static List<Person> sortByDate(List<Person> people) {
    List<Person> sorted = List.from(people);
    sorted.sort((a, b) {
      if (a.month != b.month) return a.month.compareTo(b.month);
      return a.day.compareTo(b.day);
    });
    return sorted;
  }

  static Map<int, List<Person>> groupByMonth(List<Person> people) {
    Map<int, List<Person>> grouped = {};
    for (var person in people) {
      grouped.putIfAbsent(person.month, () => []).add(person);
    }
    
    grouped.forEach((month, monthPeople) {
      monthPeople.sort((a, b) => a.day.compareTo(b.day));
    });
    
    return grouped;
  }
}